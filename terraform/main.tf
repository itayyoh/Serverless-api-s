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


# attach lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "go_api" {
  filename      = "go_api.zip" # packaged go app
  function_name = "go_api_handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main"

  #limits for free tier***
  memory_size = 128
  timeout     = 10

  #runtime
  runtime = "go1.x"

  reserved_concurrent_executions = 10
}