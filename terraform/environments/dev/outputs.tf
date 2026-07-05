output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the provisioned VPC"
}

output "ecs_cluster_name" {
  value       = module.ecs_service.cluster_name
  description = "Name of the ECS cluster"
}

output "ecs_service_name" {
  value       = module.ecs_service.service_name
  description = "Name of the ECS service"
}

output "ecs_security_group_id" {
  value       = module.ecs_service.security_group_id
  description = "Security group ID of the ECS tasks"
}
