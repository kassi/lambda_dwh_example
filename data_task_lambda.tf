resource "aws_iam_role" "data_task_lambda_exec_role" {
  name = "data_task_lambda_exec_role"
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

resource "aws_iam_role_policy" "data_task_lambda_policy" {
  name = "data_task_lambda_policy"
  role = aws_iam_role.data_task_lambda_exec_role.id

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
          "sqs:SendMessage",
        ]
        Resource = "*"
      },
    ]
  })
}

data "archive_file" "data_task_lambda" {
  type        = "zip"
  source_dir  = "src/data_task_lambda"
  output_path = "dist/data_task_lambda.zip"
}

resource "aws_lambda_function" "data_task_lambda" {
  function_name    = "data_task_lambda"
  filename         = data.archive_file.data_task_lambda.output_path
  source_code_hash = data.archive_file.data_task_lambda.output_base64sha256

  handler = "data_task_lambda.data_task_lambda_handler"
  runtime = "python3.12"

  role = aws_iam_role.data_task_lambda_exec_role.arn

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.data_task_queue.url
    }
  }
}

resource "aws_cloudwatch_log_group" "data_task_lambda_log_group" {
  name = "/aws/lambda/${aws_lambda_function.data_task_lambda.function_name}"

  retention_in_days = 7
}
