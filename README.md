# RentZone: Dynamic Application Deployment on AWS with CI/CD, Terraform, and ECS

This project demonstrates the deployment of a dynamic application on AWS using a CI/CD pipeline with GitHub Actions, Infrastructure as Code (IaC) using Terraform, and containerization with Docker. The application is deployed on Amazon ECS (Elastic Container Service) with other core AWS services.

## Table of Contents
1. [Project Overview](#project-overview)
2. [AWS Services Used](#aws-services-used)
3. [Infrastructure Diagram](#infrastructure-diagram)
4. [Prerequisites](#prerequisites)
5. [Step-by-Step Deployment Guide](#step-by-step-deployment-guide)
6. [CI/CD Pipeline with GitHub Actions](#cicd-pipeline-with-github-actions)
7. [Terraform Infrastructure as Code](#terraform-infrastructure-as-code)
8. [Running the Application](#running-the-application)
9. [Cleaning Up](#cleaning-up)

---

## Project Overview
This project deploys a dynamic application (RentZone) on AWS using the following key components:
- **CI/CD Pipeline**: GitHub Actions automates the build, test, and deployment process.
- **Containerization**: The application is containerized using Docker and pushed to Amazon ECR (Elastic Container Registry).
- **Infrastructure as Code (IaC)**: Terraform is used to provision and manage AWS infrastructure.
- **Orchestration**: Amazon ECS is used to deploy and manage the application containers.

---

## AWS Services Used
- **Amazon ECS**: Container orchestration service.
- **Amazon ECR**: Docker container registry.
- **Amazon RDS**: Managed relational database service.
- **Amazon S3**: Object storage for static assets.
- **AWS IAM**: Identity and Access Management for permissions.
- **AWS VPC**: Virtual Private Cloud for network isolation.
- **AWS ALB**: Application Load Balancer for traffic distribution.
- **AWS CloudWatch**: Monitoring and logging.
- **AWS Secrets Manager**: Secure storage for sensitive information.
- **AWS Route 53**: DNS management (optional).

---

## Infrastructure Diagram
Below is a high-level architecture diagram of the infrastructure:

![AWS Infrastructure Diagram](./aws-diagram.png)

### Diagram Description
1. **GitHub Actions**: Triggers the CI/CD pipeline on code changes.
2. **Amazon ECR**: Stores the Docker image for the application.
3. **Amazon ECS**: Runs the application in a cluster with Fargate launch type.
4. **Amazon RDS**: Hosts the application database.
5. **Amazon S3**: Stores static assets (e.g., images, CSS, JS).
6. **AWS ALB**: Distributes incoming traffic to ECS tasks.
7. **AWS VPC**: Provides network isolation and security.
8. **AWS CloudWatch**: Monitors application and infrastructure logs.

---

## Prerequisites
Before starting, ensure you have the following:
1. **AWS Account**: With necessary permissions to create resources.
2. **GitHub Repository**: Fork or clone this repository.
3. **Terraform Installed**: Install Terraform on your local machine.
4. **Docker Installed**: For building and testing the container locally.
5. **AWS CLI**: Configured with your AWS credentials.
6. **GitHub Secrets**: Store AWS credentials and other sensitive information in GitHub Secrets.

---

## Step-by-Step Deployment Guide

### 1. Clone the Repository
```bash
git clone https://github.com/Alexander77063/rentzone-github-actions-terraform-ecs-projects.git
cd rentzone-github-actions-terraform-ecs-projects
2. Set Up GitHub Secrets
Add the following secrets to your GitHub repository:

AWS_ACCESS_KEY_ID: Your AWS access key.

AWS_SECRET_ACCESS_KEY: Your AWS secret key.

AWS_REGION: AWS region (e.g., us-east-1).

RDS_DB_NAME: Database name.

RDS_DB_USERNAME: Database username.

RDS_DB_PASSWORD: Database password.

3. Build and Push Docker Image to ECR
The GitHub Actions workflow will automatically build the Docker image and push it to Amazon ECR.

4. Provision Infrastructure with Terraform
2. Set Up GitHub Secrets
Add the following secrets to your GitHub repository:

AWS_ACCESS_KEY_ID: Your AWS access key.

AWS_SECRET_ACCESS_KEY: Your AWS secret key.

AWS_REGION: AWS region (e.g., us-east-1).

RDS_DB_NAME: Database name.

RDS_DB_USERNAME: Database username.

RDS_DB_PASSWORD: Database password.

3. Build and Push Docker Image to ECR
The GitHub Actions workflow will automatically build the Docker image and push it to Amazon ECR.

4. Provision Infrastructure with Terraform
