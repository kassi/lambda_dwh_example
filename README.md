# Terraform Lambda Data Extractor and SQS Loader Example

## Pre-Requisites

### AWS CLI

Pre-Requisites for the AWS CLI to work
- You have access to an AWS account
- In the IAM Identity Center an SSO URL is shown. This is needed in the configuration step.

```console
$ brew install awscli
$ aws sso configure
```

### Terraform

```console
$ brew tap hashicorp/tap
$ brew install hashicorp/tap/terraform
$ terraform -install-autocomplete
```

### 1Password Integration (optional)

In order to use smooth shell integration for credentials managed by
1Password, install the 1Password CLI.
Use the beta version to get the terraform plugin as well.

First, create 1Password entries for your AWS account

```console
$ brew install 1password-cli@beta
$ op plugin add aws
$ op plugin add terraform
```

### Shell Aliases

```
$ alias tf='terraform'
```

### AWS Security Manager

You need to store the required secret values into AWS Security Manager.
The name can be retrieved from the `terraform.tfvars`.
- account
- username
- password
- warehouse
- database
- schema

## Installation

```console
$ terraform init
$ terraform apply
```

## Deinstallation

Should only be used while testing to destroy the aws stack.

```console
$ terraform destroy
```

## Testing

To watch the logs, see output of `terraform apply`.

To test the data task lambda:

```console
$ aws lambda invoke --function-name data_task_lambda --cli-binary-format raw-in-base64-out test/data_task_response.json
```

To test the SQS loader lambda, first save a meaningful `sqs.json`, then:

```console
$ aws lambda invoke --function-name sqs_to_dwh_loader_lambda --cli-binary-format raw-in-base64-out --payload file://test/sqs.json test/sqs_response.json
```
