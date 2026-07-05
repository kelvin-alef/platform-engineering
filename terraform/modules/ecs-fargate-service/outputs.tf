output "cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "The name of the ECS cluster"
}

output "service_name" {
  value       = aws_ecs_service.this.name
  description = "The name of the ECS service"
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.this.arn
  description = "The ARN of the task definition"
}

output "security_group_id" {
  value       = aws_security_group.ecs.id
  description = "The security group ID of the ECS service tasks"
}

output "task_execution_role_arn" {
  value       = aws_iam_role.ecs_execution_role.arn
  description = "The ARN of the ECS task execution role"
}

output "task_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
  description = "The ARN of the ECS task role"
}
