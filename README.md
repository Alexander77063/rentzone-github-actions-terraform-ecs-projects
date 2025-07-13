# RentZone - Cloud-Native Laravel Application

A full-stack rental management application built with Laravel and deployed on AWS using modern DevOps practices.

## 🏗️ Architecture Overview

This project demonstrates a complete cloud-native application deployment using:

- **Frontend**: Laravel PHP Framework
- **Backend**: MySQL Database (AWS RDS)
- **Infrastructure**: AWS ECS Fargate with Application Load Balancer
- **CI/CD**: GitHub Actions with Terraform
- **Container**: Docker with Ubuntu base image
- **Domain**: Custom domain with SSL/TLS termination

## 🚀 Live Application

**URL**: [https://www.alexander77063.co.uk](https://www.alexander77063.co.uk)

## 📋 Features

- ✅ **Fully Containerized** - Docker-based Laravel application
- ✅ **Auto-Scaling** - ECS Fargate with auto-scaling capabilities
- ✅ **Load Balanced** - Application Load Balancer with health checks
- ✅ **Secure** - Private subnets, security groups, and SSL termination
- ✅ **Database** - AWS RDS MySQL with automated migrations
- ✅ **CI/CD Pipeline** - Automated deployment with GitHub Actions
- ✅ **Infrastructure as Code** - Complete Terraform configuration
- ✅ **Custom Domain** - Route 53 DNS with ACM SSL certificates
- ✅ **Monitoring** - CloudWatch logs and ECS service monitoring

## 🛠️ Technology Stack

### Application
- **Framework**: Laravel (PHP)
- **Database**: MySQL 8.4
- **Web Server**: Apache 2.4
- **Container**: Docker (Ubuntu 22.04 base)

### AWS Services
- **Compute**: ECS Fargate
- **Load Balancing**: Application Load Balancer (ALB)
- **Database**: RDS MySQL
- **Networking**: VPC with public/private subnets
- **Storage**: ECR for container images, S3 for assets
- **DNS**: Route 53 with custom domain
- **Security**: ACM SSL certificates, Security Groups
- **Monitoring**: CloudWatch Logs

### DevOps Tools
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **Container Registry**: Amazon ECR
- **Version Control**: Git/GitHub

## 🏛️ Infrastructure Architecture

```
Internet Gateway
       |
   Public Subnets (AZ1, AZ2)
       |
Application Load Balancer
       |
   Private Subnets (AZ1, AZ2)
       |
    ECS Fargate Tasks
       |
   Private Data Subnets
       |
    RDS MySQL Database
```

### Network Design
- **VPC**: 10.0.0.0/16
- **Public Subnets**: 10.0.0.0/24, 10.0.1.0/24
- **Private App Subnets**: 10.0.2.0/24, 10.0.3.0/24
- **Private Data Subnets**: 10.0.4.0/24, 10.0.5.0/24

## 🚀 Deployment

### Prerequisites
- AWS Account with appropriate permissions
- GitHub repository with required secrets
- Terraform installed (for local development)
- Custom domain configured in Route 53

### GitHub Secrets Required
```bash
AWS_ACCESS_KEY_ID          # AWS access key
AWS_SECRET_ACCESS_KEY      # AWS secret key
ECR_REGISTRY              # ECR registry URL
PERSONAL_ACCESS_TOKEN     # GitHub PAT for repository access
RDS_DB_NAME              # Database name
RDS_DB_USERNAME          # Database username
RDS_DB_PASSWORD          # Database password
```

### Deployment Methods

#### 1. Automatic Deployment (Recommended)
- Push to `main` branch triggers automatic deployment
- GitHub Actions handles the complete CI/CD pipeline

#### 2. Manual Deployment
- Go to GitHub Actions → "Deploy Pipeline"
- Click "Run workflow"
- Select `apply` or `destroy` action
- Click "Run workflow"

### Deployment Process
1. **Infrastructure Setup** - Terraform provisions AWS resources
2. **Container Build** - Docker image built and pushed to ECR
3. **Database Migration** - Flyway handles database schema updates
4. **Service Deployment** - ECS service updated with new container
5. **Health Verification** - Load balancer health checks confirm deployment

## 📁 Project Structure

```
├── iac/                     # Terraform infrastructure code
│   ├── main.tf             # Main Terraform configuration
│   ├── variables.tf        # Variable definitions
│   ├── outputs.tf          # Output values
│   ├── vpc.tf             # VPC and networking
│   ├── security-groups.tf  # Security group definitions
│   ├── alb.tf             # Application Load Balancer
│   ├── ecs.tf             # ECS cluster and service
│   ├── database.tf        # RDS configuration
│   └── route53.tf         # DNS and SSL configuration
├── sql/                    # Database migration scripts
├── .github/workflows/      # GitHub Actions workflows
│   └── deploy.yml         # Main deployment pipeline
├── Dockerfile             # Container configuration
├── AppServiceProvider.php # Laravel service provider
└── README.md              # This file
```

## ⚙️ Configuration

### Environment Variables
The application uses the following environment variables:
- `APP_URL` - Application URL
- `DB_HOST` - Database hostname
- `DB_DATABASE` - Database name
- `DB_USERNAME` - Database username
- `DB_PASSWORD` - Database password

### Terraform Variables
Key Terraform variables in `terraform.tfvars`:
```hcl
region       = "us-east-1"
project_name = "rentzone"
environment  = "dev"
domain_name  = "alexander77063.co.uk"
```

## 🔧 Local Development

### Prerequisites
- Docker
- PHP 8.1+
- Composer
- MySQL

### Setup
```bash
# Clone the repository
git clone https://github.com/Alexander77063/application-codes.git
cd application-codes

# Install dependencies
composer install

# Configure environment
cp .env.example .env
php artisan key:generate

# Run migrations
php artisan migrate

# Start development server
php artisan serve
```

## 📊 Monitoring and Logs

### CloudWatch Logs
- **Log Group**: `/ecs/rentzone-dev-td`
- **Access**: AWS Console → CloudWatch → Log Groups

### ECS Service Monitoring
- **Service**: `rentzone-dev-service`
- **Cluster**: `rentzone-dev-cluster`
- **Access**: AWS Console → ECS → Clusters

### Application Load Balancer
- **Target Groups**: Health check status
- **Access**: AWS Console → EC2 → Load Balancers

## 🔒 Security Features

- **Private Subnets**: Application and database in private subnets
- **Security Groups**: Restrictive inbound/outbound rules
- **SSL/TLS**: ACM certificates with automatic renewal
- **IAM Roles**: Least privilege access for ECS tasks
- **VPC**: Network isolation and segmentation

## 🛡️ High Availability

- **Multi-AZ Deployment**: Resources across multiple availability zones
- **Auto Scaling**: ECS service automatically scales based on demand
- **Load Balancing**: Traffic distributed across healthy instances
- **Health Checks**: Automatic replacement of unhealthy containers
- **Database**: RDS with automated backups and maintenance

## 🚨 Troubleshooting

### Common Issues

#### Containers Not Starting
1. Check CloudWatch logs: `/ecs/rentzone-dev-td`
2. Verify ECS service events in AWS Console
3. Check task definition configuration

#### Database Connection Issues
1. Verify RDS security group allows ECS access
2. Check database credentials in secrets
3. Ensure RDS is in correct subnets

#### Load Balancer Health Checks Failing
1. Verify application listens on port 80
2. Check target group health in AWS Console
3. Verify security group rules

### Debug Commands
```bash
# Check ECS service status
aws ecs describe-services --cluster rentzone-dev-cluster --services rentzone-dev-service

# View recent task failures
aws ecs list-tasks --cluster rentzone-dev-cluster --service rentzone-dev-service --desired-status STOPPED

# Check load balancer target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## 📈 Performance Optimization

- **Container Resources**: 2 vCPU, 4GB RAM per task
- **Auto Scaling**: Scale 1-4 tasks based on CPU utilization
- **Health Checks**: 30-second intervals with 5 healthy threshold
- **Database**: RDS instance optimized for workload

## 🔄 CI/CD Pipeline

### Pipeline Stages
1. **Setup Infrastructure** - Terraform apply
2. **Build Application** - Docker build and ECR push
3. **Database Migration** - Schema updates with Flyway
4. **Service Deployment** - ECS service update
5. **Health Verification** - Wait for service stability

### Pipeline Features
- **Automatic Triggers**: Push to main branch
- **Manual Triggers**: GitHub Actions UI
- **Rollback Support**: Terraform destroy option
- **Environment Management**: Separate dev/prod configurations.
