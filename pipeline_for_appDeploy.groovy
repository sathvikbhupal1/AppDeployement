pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "sathvikbhupal1/sample:latest"
        DOCKERHUB_CREDENTIALS_ID = "dockerhub-credentials" // Jenkins ID for Docker Hub credentials
        BASTION_PUBLIC_IP = "enter your public ip here"
        BASTION_USER = "ec2-user"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url:enter your repo url here ]])
            }
        }

        stage('mvn clean') {
            steps {
                sh 'mvn clean package -DskipTests -Dcheckstyle.skip'
            }
        }

        stage('Docker Build and Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "$DOCKERHUB_CREDENTIALS_ID", passwordVariable: 'DOCKERHUB_PASSWORD', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                        sh "docker build -t ${DOCKER_IMAGE} ."
                        sh "echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }

        stage('Ensure nc is installed on Bastion') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'your-credential-id', keyFileVariable: 'SSH_KEY')]) {
                        sh '''
                            echo "
                            Host bastion
                                HostName ${BASTION_PUBLIC_IP}
                                User ${BASTION_USER}
                                IdentityFile ${SSH_KEY}
                                StrictHostKeyChecking no
                            " > ssh_config

                            ssh -F ssh_config bastion <<EOF
                                sudo yum install -y nc || sudo apt-get install -y netcat
EOF
                        '''
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'your-credential-id', keyFileVariable: 'SSH_KEY')]) {
                        def privateInstances = [
                            [ip: '10.0.4.174', user: 'ec2-user'],
                            [ip: '10.0.2.14', user: 'ec2-user']  // Add the IP and user for the second private instance
                        ]
                            
                            for (instance in privateInstances) {
                                sh """
                                    echo "
                                    Host bastion
                                        HostName ${BASTION_PUBLIC_IP}
                                        User ${BASTION_USER}
                                        IdentityFile ${SSH_KEY}
                                        StrictHostKeyChecking no

                                    Host private-instance
                                        HostName ${instance.ip}
                                        User ${instance.user}
                                        IdentityFile ${SSH_KEY}
                                        StrictHostKeyChecking no
                                        ProxyCommand ssh -F ssh_config bastion nc %h %p
                                    " > ssh_config

                                    ssh -t -F ssh_config private-instance <<EOF
                                        # Stop and remove existing containers if they exist
                                        docker stop sample-app || true
                                        docker rm sample-app || true
                                        docker stop prometheus || true
                                        docker rm prometheus || true
                                        docker stop grafana || true
                                        docker rm grafana || true

                                        # Run the Spring Petclinic application
                                        docker run -d --name sample-app -p 8081:8080 ${DOCKER_IMAGE}

                                        # Run Prometheus container
                                        docker run -d --name prometheus -p 9090:9090 \\
                                        -v \$(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \\
                                        prom/prometheus --config.file=/etc/prometheus/prometheus.yml

                                        # Run Grafana container
                                        docker run -d --name grafana -p 3000:3000 \\
                                        -v grafana-storage:/var/lib/grafana \\
                                        grafana/grafana
EOF
                    """
               }
           }
       }
   }
}
   }
}
