
# Data source for availability zones
data "aws_availability_zones" "available" {}

# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MyVPC"
  }
}

# Create public subnets in multiple availability zones
resource "aws_subnet" "PublicSubnet" {
  count                   = 2
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = element(["10.0.1.0/24", "10.0.3.0/24"], count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet-${count.index}"
  }
}

# Create private subnets in multiple availability zones
resource "aws_subnet" "PrivSubnet" {
  count             = 2
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = element(["10.0.2.0/24", "10.0.4.0/24"], count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "PrivSubnet-${count.index}"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "myIgw" {
  vpc_id = aws_vpc.myvpc.id
}

# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  count = 2
  domain   = "vpc"
}


# Create a NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  count        = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.PublicSubnet[count.index].id

  tags = {
    Name = "NATGateway-${count.index}"
  }
}

# Route Tables for public subnets
resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIgw.id
  }
}

# Route table association for public subnets
resource "aws_route_table_association" "PublicRTAssociation" {
  count          = 2
  subnet_id      = element(aws_subnet.PublicSubnet.*.id, count.index)
  route_table_id = aws_route_table.PublicRT.id
}

# Route Tables for private subnets
resource "aws_route_table" "PrivateRT" {
  count  = 2
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    Name = "PrivateRT-${count.index}"
  }
}

# Route table association for private subnets
resource "aws_route_table_association" "PrivateRTAssociation" {
  count          = 2
  subnet_id      = aws_subnet.PrivSubnet[count.index].id
  route_table_id = aws_route_table.PrivateRT[count.index].id
}

resource "aws_security_group_rule" "allow_http_to_alb" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elb_sg.id
}

# Allow HTTP traffic from the ALB to private instances
resource "aws_security_group_rule" "allow_http_from_alb" {
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  security_group_id        = aws_security_group.instance_sg.id
  source_security_group_id = aws_security_group.elb_sg.id
}

# Allow HTTP traffic from private instances to the ALB
resource "aws_security_group_rule" "allow_http_to_alb_from_instances" {
  type                     = "egress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  security_group_id        = aws_security_group.instance_sg.id
  source_security_group_id = aws_security_group.elb_sg.id
}

# Allow the ALB to send traffic to the private instances
resource "aws_security_group_rule" "allow_http_from_alb_to_instances" {
  type                     = "egress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elb_sg.id
  source_security_group_id = aws_security_group.instance_sg.id
}

resource "aws_security_group_rule" "allow_existing_to_terraform_instances" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.private_ssh_access.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "allow_all_traffic_out_from_private" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.instance_sg.id
}

# Security group for Load Balancer
resource "aws_security_group" "elb_sg" {
  vpc_id = aws_vpc.myvpc.id

  
  tags = {
    Name = "elb-sg"
  }
}

resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict this to the existing instance's IP or subnet if possible
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_security_group" "private_ssh_access" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "private-ssh-access"
  }
}


# Security group for EC2 instances
resource "aws_security_group" "instance_sg" {
  vpc_id = aws_vpc.myvpc.id

 
  tags = {
    Name = "instance-sg"
  }
}

resource "tls_private_key" "my_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_sensitive_file" "private_key" {
  content  = tls_private_key.my_key_pair.private_key_pem
  filename = "${path.module}/keys/my_terraform_key.pem"
}

resource "local_sensitive_file" "public_key" {
  content  = tls_private_key.my_key_pair.public_key_openssh
  filename = "${path.module}/keys/my_terraform_key.pub"
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "test2"
  public_key = tls_private_key.my_key_pair.public_key_openssh
}


# Launch a bastion host in the public subnet
resource "aws_instance" "bastion" {
  ami           = "ami-0ac67a26390dc374d"  # Example AMI ID, choose your own
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key_pair.key_name
  subnet_id     = aws_subnet.PublicSubnet[0].id

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "bastion-host"
  }
}



resource "aws_launch_template" "private_lt" {
  name_prefix          = "private-lt-"
  image_id             = "ami-0ac67a26390dc374d" # Specify the desired AMI ID
  instance_type        = "t2.micro"
  key_name             = aws_key_pair.my_key_pair.key_name

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "docker-host-private"
    }
  }

  vpc_security_group_ids = [
    aws_security_group.instance_sg.id,
    aws_security_group.private_ssh_access.id,
  ]

  user_data = filebase64("${path.module}/userdata/private_user_data.sh")
}


resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_sg.id]

  subnet_mapping {
    subnet_id = aws_subnet.PublicSubnet[0].id
  }

  subnet_mapping {
    subnet_id = aws_subnet.PublicSubnet[1].id
  }

  enable_deletion_protection = false

  tags = {
    Name = "main-alb"
  }
}


resource "aws_autoscaling_group" "private_asg" {
  desired_capacity        = 2
  max_size                = 3
  min_size                = 1
  launch_template {
    id      = aws_launch_template.private_lt.id
    version = "$Latest"
  }
  vpc_zone_identifier     = aws_subnet.PrivSubnet.*.id

  tag {
    key                 = "Name"
    value               = "docker-host-private"
    propagate_at_launch = true
  }
}



resource "aws_autoscaling_attachment" "private_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.private_asg.id
  lb_target_group_arn   = aws_lb_target_group.main.arn
}


resource "aws_lb_target_group" "main" {
  name        = "main-target-group"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.myvpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "main-target-group"
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 8081
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
