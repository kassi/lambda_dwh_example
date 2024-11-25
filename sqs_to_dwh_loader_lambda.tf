resource "aws_iam_role" "sqs_to_dwh_loader_lambda_exec_role" {
  name = "sqs_to_dwh_loader_lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "sqs_to_dwh_loader_lambda_policy" {
  name = "sqs_to_dwh_loader_lambda_policy"
  role = aws_iam_role.sqs_to_dwh_loader_lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.secret_name}-9kRapp"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

# Provisioner to build the Lambda package
resource "null_resource" "sqs_to_dwh_loader_lambda_archive" {
  provisioner "local-exec" {
    command = "./sqs_to_dwh_loader_lambda_builder.sh"
  }

  triggers = {
    # Dieser Trigger sorgt dafür, dass das Skript bei Änderungen an den Quell-Dateien erneut ausgeführt wird.
    build_script  = "${file("${path.module}/sqs_to_dwh_loader_lambda_builder.sh")}"
    lambda_source = "${file("${path.module}/src/sqs_to_dwh_loader_lambda/sqs_to_dwh_loader_lambda.py")}"
    requirements  = "${file("${path.module}/src/sqs_to_dwh_loader_lambda/requirements.txt")}"
  }
}

data "archive_file" "sqs_to_dwh_loader_lambda" {
  type        = "zip"
  source_dir  = "build/sqs_to_dwh_loader_lambda"
  output_path = "dist/sqs_to_dwh_loader_lambda.zip"

  depends_on = [null_resource.sqs_to_dwh_loader_lambda_archive]
}

resource "aws_lambda_function" "sqs_to_dwh_loader_lambda" {
  function_name    = "sqs_to_dwh_loader_lambda"
  filename         = data.archive_file.sqs_to_dwh_loader_lambda.output_path
  source_code_hash = data.archive_file.sqs_to_dwh_loader_lambda.output_base64sha256

  handler = "sqs_to_dwh_loader_lambda.sqs_to_dwh_loader_lambda_handler"
  runtime = "python3.12"

  role = aws_iam_role.sqs_to_dwh_loader_lambda_exec_role.arn

  timeout = 15

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      SECRET_NAME = var.secret_name
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_to_dwh_loader_sqs_trigger" {
  event_source_arn = aws_sqs_queue.data_task_queue.arn
  function_name    = aws_lambda_function.sqs_to_dwh_loader_lambda.arn
  enabled          = true
}

resource "aws_cloudwatch_log_group" "sqs_to_dwh_loader_lambda_log_group" {
  name = "/aws/lambda/${aws_lambda_function.sqs_to_dwh_loader_lambda.function_name}"

  retention_in_days = 7
}
