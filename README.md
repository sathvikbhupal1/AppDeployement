# AppDeployement

**Infrastructure and CI/CD Pipeline Setup**


This repository contains Terraform scripts for provisioning resources on AWS and setting up a CI/CD pipeline using Jenkins for deploying a Java application packaged into Docker containers onto the provisioned infrastructure.

**Infrastructure Setup**


*Terraform Scripts*
The Terraform scripts in this repository automate the provisioning of the following resources on AWS:


1.Custom VPC with public and private subnets across multiple availability zones for high availability.


2.Auto Scaling Group (ASG) configured to launch Docker hosts (EC2 instances) within the private subnets.


3.Load Balancer (ALB) to distribute traffic across the Docker hosts.


4.Proper security group configurations to allow necessary traffic.


5.AWS IAM roles with appropriate permissions for EC2 instances and Auto Scaling Group.


*Files*:
1.main.tf: Contains the main Terraform configuration defining the resources to be provisioned.


2.providers.tf: Defines the AWS provider and its configuration.


3.variables.tf: Declares the input variables used in the Terraform scripts.


4.outputs.tf: Defines the output variables to be displayed after Terraform execution.

**Additional Considerations**


Docker hosts are provisioned in a highly available manner across multiple availability zones.
Proper monitoring and scaling configurations are implemented for the Docker hosts.(Prometheus and grafana)
Security best practices are followed, including encryption, and secure communication between components.


*CI/CD Pipeline Setup*
Jenkins Configuration
Jenkins is used as the CI/CD tool to automate the build and deployment process of the Java application.

*Pipeline Scripts*:
pipeline_for_AppDeploy.groovy: Defines the pipeline to build the Java application and package it into a Docker container.
(optional)pipeline_for_terraform.groovy: Optional pipeline script for automating Terraform infrastructure provisioning.


*Integration and Deployment*:
Jenkins is configured to fetch the Java application source code from the GitHub repository.
The pipeline is set up to build the Java application and package it into a Docker container.
Hardcode the terraform output values to deploy the Docker container onto the provisioned infrastructure.
Continuous deployment is implemented by triggering the pipeline automatically upon changes to the GitHub repository.


**Additional Notes**


Webhooks have been added to Jenkins to trigger the pipeline automatically upon changes in the code repository.


**Refer to the Project Documentation for the Architecture info and detailed step by step process for acheiving the project ouput**
