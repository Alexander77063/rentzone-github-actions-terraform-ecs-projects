# REPLACE your existing outputs section with this cleaned-up version

### outputs needed to create ecr repository
output "image_name" {
  value = var.image_name
}

### outputs needed to build docker image
# domain name - use the actual domain from Route53 record
output "domain_name" {
  value = join("", [var.record_name, ".", var.domain_name])
}

# rds endpoint
output "rds_endpoint" {
  value = aws_db_instance.database_instance.endpoint
}

# export the image tag
output "image_tag" {
  value = var.image_tag
}

### outputs needed for self-hosted runner (if needed)
# private data subnet az1 id
output "private_data_subnet_az1_id" {
  value = aws_subnet.private_data_subnet_az1.id
}

# runner security group id
output "runner_security_group_id" {
  value = aws_security_group.runner_security_group.id
}

### outputs needed to create a new revision for the ecs task definition
# task definition name
output "task_definition_name" {
  value = aws_ecs_task_definition.ecs_task_definition.family
}

### outputs needed to restart the ecs service
# ecs cluster name
output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}

# ecs service name
output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name
}

### outputs needed to build environment file
# environment file name
output "environment_file_name" {
  value = var.env_file_name
}

# s3 bucket name - FIXED: use the correct bucket
output "env_file_bucket_name" {
  value = aws_s3_bucket.env_file_bucket_1.id
}

# website url
output "website_url" {
  value = join("", ["https://", var.record_name, ".", var.domain_name])
}