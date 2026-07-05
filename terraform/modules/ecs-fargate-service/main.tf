resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-cluster"
      Environment = var.environment
    }
  )
}

# CloudWatch Logs with parameterized retention
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_in_days

  tags = merge(
    var.tags,
    {
      Name        = "/ecs/${var.project_name}-${var.environment}"
      Environment = var.environment
    }
  )
}

# Least-Privilege IAM Execution Role (Fargate agent)
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Conditional Secrets Access Policy for Task Execution Role
resource "aws_iam_policy" "ecs_execution_secrets" {
  count       = length(var.app_secrets) > 0 ? 1 : 0
  name        = "${var.project_name}-${var.environment}-ecs-secrets-policy"
  description = "Allows ECS agent to retrieve specific Secrets and SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters"
        ]
        Resource = values(var.app_secrets)
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_secrets" {
  count      = length(var.app_secrets) > 0 ? 1 : 0
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_secrets[0].arn
}

# Separate Least-Privilege IAM Task Role (Application code scope)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# Security Group for Fargate Tasks
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Security group for ${var.project_name} Fargate tasks"
  vpc_id      = var.vpc_id

  # Ingress: Allow traffic on container port from within VPC
  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In a production environment, restrict to Load Balancer SG or specific subnets
  }

  # Egress: Allow all outbound traffic (to fetch updates, talk to PG/Redis/SSM etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-ecs-sg"
      Environment = var.environment
    }
  )
}

# ECS Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.project_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]

      environment = [
        for k, v in var.app_variables : {
          name  = k
          value = v
        }
      ]

      secrets = [
        for k, v in var.app_secrets : {
          name      = k
          valueFrom = v
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false # Run securely in private subnets
  }

  # Dynamic load balancer block if ALB ARN is provided
  dynamic "load_balancer" {
    for_each = var.alb_target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.alb_target_group_arn
      container_name   = var.project_name
      container_port   = var.container_port
    }
  }

  lifecycle {
    ignore_changes = [desired_count] # Allow autoscaling to manage instance count without TF drift
  }

  tags = var.tags
}

# Target Tracking Auto-Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.project_name}-${var.environment}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.cpu_threshold
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.project_name}-${var.environment}-mem-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.memory_threshold
  }
}

# Outputs sync: Register Service endpoints/identifiers to SSM Parameter Store for cross-team/cross-env sync
resource "aws_ssm_parameter" "cluster_name" {
  name        = "/${var.environment}/${var.project_name}/ecs_cluster_name"
  type        = "String"
  value       = aws_ecs_cluster.this.name
  description = "ECS Cluster Name for ${var.project_name}"
  tags        = var.tags
}

resource "aws_ssm_parameter" "service_name" {
  name        = "/${var.environment}/${var.project_name}/ecs_service_name"
  type        = "String"
  value       = aws_ecs_service.this.name
  description = "ECS Service Name for ${var.project_name}"
  tags        = var.tags
}

resource "aws_ssm_parameter" "service_sg_id" {
  name        = "/${var.environment}/${var.project_name}/ecs_security_group_id"
  type        = "String"
  value       = aws_security_group.ecs.id
  description = "Security Group ID for ${var.project_name} ECS tasks"
  tags        = var.tags
}
