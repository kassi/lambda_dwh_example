variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "service" {
  type = string
}


variable "secret_name" {
  type = string
}
