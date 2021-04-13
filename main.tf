# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 0.14.x.
  required_version = ">= 0.14.0"
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH EVENT RULE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "cron" {
  name                = var.name
  schedule_expression = "cron(${var.cron})"
}

resource "aws_cloudwatch_event_target" "event_target" {
  arn      = data.aws_ecs_cluster.selected.arn
  rule     = aws_cloudwatch_event_rule.cron.name
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsEventsRole"
  ecs_target {
    launch_type         = "FARGATE"
    task_definition_arn = aws_ecs_task_definition.task.arn
    network_configuration {
      subnets = var.subnets
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# TASK DEFINITION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "task" {
  family = var.name
  cpu    = var.cpu
  memory = var.mem

  execution_role_arn = aws_iam_role.task_execution_role.arn

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name         = var.name
      image        = "${aws_ecr_repository.ecr.repository_url}:${var.image_tag}"
      essential    = true
      portMappings = []
      cpu          = 0
      mountPoints  = []
      volumesFrom  = []
      environment  = [for k, v in var.environment : { name : k, value : v }]
      secrets      = [for k, v in local.secret_arns : { name : k, valueFrom : v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = data.aws_region.current.name
          awslogs-group         = aws_cloudwatch_log_group.cw_lg.name
          awslogs-stream-prefix = "${var.name}-task"
        }
      }
    }
  ])
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cw_lg" {
  name = "/${var.cluster_name}/${var.name}"
}

# ---------------------------------------------------------------------------------------------------------------------
# TASK EXECUTION ROLE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "task_execution_role" {
  name                = "${var.name}TaskExecutionRole"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]

  assume_role_policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Action : "sts:AssumeRole"
          Effect : "Allow",
          Sid : "",
          Principal : {
            Service : "ecs-tasks.amazonaws.com"
          }
        }
      ]
  })

  dynamic "inline_policy" {
    for_each = length(local.secret_arns) > 0 ? [1] : []
    content {
      name = "AllowGetParameters"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = ["ssm:GetParameters", "kms:Decrypt"]
          Resource = [for k, v in local.secret_arns : v]
        }]
      })
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A DOCKER REPOSITORY
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecr_repository" "ecr" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A LIFECYCLE POLICY FOR THE DOCKER REPOSITORY
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecr_lifecycle_policy" "policy" {
  repository = aws_ecr_repository.ecr.name
  policy = jsonencode({
    rules : [{
      rulePriority : 1,
      description : "Keep only the early 5 images",
      selection : {
        tagStatus : "any",
        countType : "imageCountMoreThan",
        countNumber : 5
      },
      action : {
        type : "expire"
      }
    }]
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ecs_cluster" "selected" {
  cluster_name = var.cluster_name
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  secret_arns = { for k, v in var.secrets : k =>
    "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.name}/${v}"
  }
}
