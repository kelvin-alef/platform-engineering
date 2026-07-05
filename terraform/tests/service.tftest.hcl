# Native Terraform 1.6+ Test Suite for ECS Fargate Service Module

variables {
  project_name    = "test-app"
  environment     = "dev"
  vpc_id          = "vpc-0123456789abcdef0"
  subnet_ids      = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  container_image = "nginx:latest"
  container_port  = 8080
  desired_count   = 2
  cpu             = "256"
  memory          = "512"

  app_variables = {
    "ENV_VAR_TEST" = "value-test"
  }

  app_secrets = {
    "SECRET_TEST" = "arn:aws:secretsmanager:us-east-1:123456789012:secret:test-abc"
  }

  tags = {
    Testing = "true"
  }
}

# Run execution validation plan (no actual resources are applied in AWS)
run "validate_ecs_service_module" {
  command = plan

  assert {
    condition     = aws_ecs_cluster.this.name == "test-app-dev-cluster"
    error_message = "ECS cluster name naming convention failed."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.retention_in_days == 30
    error_message = "Log retention did not default to 30 days."
  }

  assert {
    condition     = aws_ecs_task_definition.this.cpu == "256"
    error_message = "CPU allocation mismatch."
  }

  assert {
    condition     = aws_ecs_task_definition.this.memory == "512"
    error_message = "Memory allocation mismatch."
  }

  assert {
    condition     = aws_security_group.ecs.ingress[0].from_port == 8080
    error_message = "ECS Task Security Group port mapping mismatch."
  }

  assert {
    condition     = aws_ecs_service.this.desired_count == 2
    error_message = "ECS Service desired task count did not match."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.ecs_execution_secrets) == 1
    error_message = "Secrets access IAM policy attachment should be created."
  }
}
