terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Service     = var.service
      Terraform   = path.cwd
    }
  }
}

output "cloudwatch_data_task_lambda_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for the data Lambda function"
  value       = aws_cloudwatch_log_group.data_task_lambda_log_group.arn
}

output "cloudwatch_sqs_to_dwh_loader_lambda_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for the DWH loader Lambda function"
  value       = aws_cloudwatch_log_group.sqs_to_dwh_loader_lambda_log_group.arn
}

output "cloudwatch_live_tail" {
  description = "The command to live tail the api gateway logs."
  value       = "aws logs start-live-tail --log-group-identifiers ${aws_cloudwatch_log_group.data_task_lambda_log_group.arn} ${aws_cloudwatch_log_group.sqs_to_dwh_loader_lambda_log_group.arn}"
}
