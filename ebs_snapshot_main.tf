provider "aws" {
  region = "ap-south-1"
}

resource "aws_iam_role" "lambda_snapshot_role" {
  name = "lambda_snapshot_role"

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

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_snapshot_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ebs_fullaccess" {
  role       = aws_iam_role.lambda_snapshot_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_lambda_function" "create_snapshot" {
  function_name = "create_ebs_snapshot"
  filename      = "create_snapshot.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_snapshot_role.arn
  source_code_hash = filebase64sha256("create_snapshot.zip")
}

resource "aws_lambda_function" "delete_snapshot" {
  function_name = "delete_old_snapshots"
  filename      = "delete_snapshot.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_snapshot_role.arn
  source_code_hash = filebase64sha256("delete_snapshot.zip")
}
