# DynamoDb Table
resource "aws_dynamodb_table" "movies-table" {
  name           = var.dynamo_db_table_name
  billing_mode   = var.dynamo_db_billing_mode
  read_capacity  = var.dynamo_db_read_capacity
  write_capacity = var.dynamo_db_write_capacity
  hash_key       = var.dynamo_db_hash_key

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "releaseYear"
    type = "S"
  }

  attribute {
    name = "title"
    type = "S"
  }

  global_secondary_index {
    name            = "releaseYear-index"
    hash_key        = "releaseYear"
    projection_type = "ALL"
    read_capacity   = 5
    write_capacity  = 5
  }

  global_secondary_index {
    name            = "title-index"
    hash_key        = "title"
    projection_type = "ALL"
    read_capacity   = 5
    write_capacity  = 5
  }

  tags = {
    Name        = var.dynamo_db_table_name
    Environment = "dev"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "My bucket"
    Environment = "dev"
  }
}

# Lambda Function

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach Cloudwatch Logs and DynamoDB policies to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = var.lambda_basic_policy
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_db" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = var.lambda_dynamodb_read_policy
}

# Lambda Function for getMovies

data "archive_file" "get_movies_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/getMovies"
  output_path = "${path.module}/getMovies/get-movies.zip"
}

resource "aws_lambda_function" "get_movies" {
  filename      = "${path.module}/getMovies/get-movies.zip"
  function_name = "getMovies"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"

  source_code_hash = data.archive_file.get_movies_lambda.output_base64sha256

  runtime = var.lambda_runtime
}

# Lambda Function for getMoviesByYear

data "archive_file" "get_movies_by_year_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/getMoviesByYear"
  output_path = "${path.module}/getMoviesByYear/get-movies-by-year.zip"
}

resource "aws_lambda_function" "get_movies_by_year" {
  filename      = "${path.module}/getMoviesByYear/get-movies-by-year.zip"
  function_name = "getMoviesByYear"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"

  source_code_hash = data.archive_file.get_movies_by_year_lambda.output_base64sha256

  runtime = var.lambda_runtime
}

# Lambda Function for generateMovieSummary

data "archive_file" "generate_movie_summary_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/aiGeneratedSummary"
  output_path = "${path.module}/aiGeneratedSummary/gen-movie-summary.zip"
}

resource "aws_lambda_function" "generate_movie_summary" {
  filename      = "${path.module}/aiGeneratedSummary/gen-movie-summary.zip"
  function_name = "genMovieSummary"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  timeout       = var.lambda_timeout

  source_code_hash = data.archive_file.generate_movie_summary_lambda.output_base64sha256

  runtime = var.lambda_runtime

  environment {
    variables = {
      API_KEY = var.API_KEY
    }
  }
}








