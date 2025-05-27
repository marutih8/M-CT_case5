provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "demo_ec2" {
  ami           = "ami-0e35ddab05955cf57" # Ubuntu AMI in ap-south-1
  instance_type = "t2.micro"
  key_name      = "key2025" # Replace with your key

  tags = {
    Name = "AutoStartStopEC2"
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_ec2_control_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_ec2_policy" {
  name = "lambda-ec2-control-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
}

resource "aws_lambda_function" "start_lambda" {
  filename         = "${path.module}/start_ec2.zip"
  function_name    = "StartEC2Instance"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "start.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/start_ec2.zip")
  runtime          = "python3.9"
  timeout          = 10

  environment {
    variables = {
      INSTANCE_ID = aws_instance.demo_ec2.id
    }
  }
}

resource "aws_lambda_function" "stop_lambda" {
  filename         = "${path.module}/stop_ec2.zip"
  function_name    = "StopEC2Instance"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "stop.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/stop_ec2.zip")
  runtime          = "python3.9"
  timeout          = 10

  environment {
    variables = {
      INSTANCE_ID = aws_instance.demo_ec2.id
    }
  }
}

resource "aws_cloudwatch_event_rule" "start_rule" {
  name                = "ec2-start-schedule"
  schedule_expression = "cron(42 16 * * ? *)" # every day at 6:00 AM IST
}

resource "aws_cloudwatch_event_rule" "stop_rule" {
  name                = "ec2-stop-schedule"
  schedule_expression = "cron(40 16 * * ? *)" # every day at 10:00 PM IST
}

resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_rule.name
  target_id = "start-lambda"
  arn       = aws_lambda_function.start_lambda.arn
}

resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_rule.name
  target_id = "stop-lambda"
  arn       = aws_lambda_function.stop_lambda.arn
}

resource "aws_lambda_permission" "allow_start" {
  statement_id  = "AllowExecutionFromCWStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_rule.arn
}

resource "aws_lambda_permission" "allow_stop" {
  statement_id  = "AllowExecutionFromCWStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_rule.arn
}

