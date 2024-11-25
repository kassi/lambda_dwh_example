# Data Task Queue
resource "aws_sqs_queue" "data_task_queue" {
  name = "data-task-queue"
}

# Dead-Letter-Queue
resource "aws_sqs_queue" "data_task_dead_letter_queue" {
  name = "dead-letter-queue"
}

# Dead-Letter-Queue-Konfiguration
resource "aws_sqs_queue_policy" "data_task_queue_policy" {
  queue_url = aws_sqs_queue.data_task_queue.url
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "SQS:SendMessage"
        Resource  = aws_sqs_queue.data_task_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_lambda_function.data_task_lambda.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_redrive_policy" "data_task_queue_redrive" {
  queue_url = aws_sqs_queue.data_task_queue.url
  redrive_policy = jsonencode({
    maxReceiveCount     = 5
    deadLetterTargetArn = aws_sqs_queue.data_task_dead_letter_queue.arn
  })
}
