data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------
# Task Execution role — pulled by ECS control plane to start the task
# ---------------------------------------------------------------------------
resource "aws_iam_role" "execution" {
  name               = var.name_execution_role
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags               = { Name = var.name_execution_role }
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = length(var.secret_arns) > 0 ? 1 : 0

  name = var.name_secrets_policy
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "ssm:GetParameter", "ssm:GetParameters"]
        Resource = var.secret_arns
      }],
      length(var.kms_key_arns) > 0 ? [{
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.kms_key_arns
      }] : []
    )
  })
}

# ---------------------------------------------------------------------------
# Task role — assumed by the running container for AWS API calls
# ---------------------------------------------------------------------------
resource "aws_iam_role" "task" {
  name               = var.name_task_role
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags               = { Name = var.name_task_role }
}

resource "aws_iam_role_policy" "task_custom" {
  count = var.task_role_policy_json != "" ? 1 : 0

  name   = var.name_custom_policy
  role   = aws_iam_role.task.id
  policy = var.task_role_policy_json
}

resource "aws_iam_role_policy" "task_ecs_exec" {
  count = var.enable_execute_command ? 1 : 0

  name = var.name_exec_policy
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
      ]
      Resource = "*"
    }]
  })
}
