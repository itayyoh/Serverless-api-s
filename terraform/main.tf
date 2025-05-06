provider "aws" {
    region = "us-east-1"
}

resource "aws-iam-role" "lambda-role" {
    name = "go_api_lambda_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}