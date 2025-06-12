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

#api gateway rest api
resource "aws_apigatewayv2" "go_api" {
  name          = "go-api-gateway"
  protocol_type = "HTTP"
}

#api gateway stage 
resource "aws_apigatewayv2_stage" "go_api" {
  api_id      = aws_apigatewayv2_api.go_api.id
  name        = "dev"
  auto_deploy = true
}

#api gateway route
resource "aws_apigatewayv2_route" "go_api" {
  api_id    = aws_apigatewayv2_api.go_api.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.go_api.id}"
}

#api gateway lambda integration
resource "aws_apigatewayv2_integration" "go_api" {
  api_id                 = aws_apigatewayv2_api.go_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "aws_lambda_function.go_api.invoke_arn"
  payload_format_version = "2.0"
  integration_method     = "POST"
}

#permissions
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.go_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.go_api.execution_arn}/*/*"

}

output "api_url" {
  value = "${aws_apigatewayv2_stage.go_api.invoke_url}/api/"
}

