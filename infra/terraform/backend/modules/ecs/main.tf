resource "aws_ecs_cluster" "this" {
  name = var.name_cluster
  tags = { Name = var.name_cluster }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ---------------------------------------------------------------------------
# API task definition
# ---------------------------------------------------------------------------
resource "aws_ecs_task_definition" "api" {
  family                   = var.name_task_def_api
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  tags                     = { Name = var.name_task_def_api }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  container_definitions = jsonencode([{
    name      = var.container_name_api
    image     = var.image_uri_api
    essential = true

    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
    }]

    environment = var.container_environment
    secrets     = var.container_secrets

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_api_name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "api"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "wget -q -O - http://127.0.0.1:${var.container_port}/health/live >/dev/null 2>&1 || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }
  }])
}

# ---------------------------------------------------------------------------
# Flyway one-off migration task definition
# ---------------------------------------------------------------------------
resource "aws_ecs_task_definition" "db_migrations" {
  family                   = var.name_task_def_db
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.db_migrations_task_cpu
  memory                   = var.db_migrations_task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  tags                     = { Name = var.name_task_def_db }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = "flyway"
    image     = var.image_uri_db
    essential = true
    command   = ["migrate"]

    environment = var.flyway_environment
    secrets     = var.flyway_secrets

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_db_migrations_name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "flyway"
      }
    }
  }])
}

# ---------------------------------------------------------------------------
# ECS Service
# ---------------------------------------------------------------------------
resource "aws_ecs_service" "this" {
  name                   = var.name_service
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.api.arn
  desired_count          = var.desired_count
  launch_type            = "FARGATE"
  enable_execute_command = var.enable_execute_command
  propagate_tags         = "TASK_DEFINITION"
  tags                   = { Name = var.name_service }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  network_configuration {
    assign_public_ip = var.assign_public_ip
    security_groups  = [var.service_security_group_id]
    subnets          = var.private_subnet_ids
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name_api
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Application release pipelines update the task definition outside Terraform.
  # Ignoring changes here prevents Terraform from reverting a deployed image.
  lifecycle {
    ignore_changes = [task_definition]
  }
}

# ---------------------------------------------------------------------------
# Auto Scaling
# ---------------------------------------------------------------------------
resource "aws_appautoscaling_target" "this" {
  count = var.autoscaling_enabled ? 1 : 0

  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count = var.autoscaling_enabled ? 1 : 0

  name               = var.name_autoscaling_cpu
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.cpu_target_value

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
