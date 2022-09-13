resource "aws_s3_bucket" "dynamodb_s3export" {
  bucket = "dynamodb-exports-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.dynamodb_s3export.id

  rule {
    id     = "data-retention"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

resource "aws_cloudwatch_event_rule" "dynamodb_s3export" {
  name                = "${var.name}-dynamodb-s3export-scheduler"
  description         = "This CloudWatch event fires every day at noon and schedules DynamoDB exports to S3."
  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "dynamodb_s3export" {
  rule = aws_cloudwatch_event_rule.dynamodb_s3export.name
  arn  = aws_lambda_function.dynamodb_s3export.arn
}

resource "aws_iam_policy" "dynamodb_s3export" {
  name        = "${var.name}-iam-policy-dynamodb-s3export"
  description = "Allows to trigger dynamodb export to point in time and to access S3."
  policy      = data.aws_iam_policy_document.dynamodb_s3export.json
}

# From here: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DataExport.Requesting.html#DataExport.Requesting.Permissions
data "aws_iam_policy_document" "dynamodb_s3export" {
  version = "2012-10-17"

  statement {
    sid       = "AllowDynamoDBExportAction"
    effect    = "Allow"
    actions   = ["dynamodb:ExportTableToPointInTime"]
    resources = [
      aws_dynamodb_table.main.arn,
      aws_dynamodb_table.ipns.arn
    ]
  }

  statement {
    sid     = "AllowWriteToDestinationBucket"
    effect  = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["${aws_s3_bucket.dynamodb_s3export.arn}/*"]
  }
}

resource "aws_iam_role_policy_attachment" "name" {
  role       = aws_iam_role.dynamodb_s3export_lambda.name
  policy_arn = aws_iam_policy.dynamodb_s3export.arn
}

resource "aws_iam_role" "dynamodb_s3export_lambda" {
  name               = "${var.name}-dynamodb-s3export-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_lambda_function" "dynamodb_s3export" {
  filename         = data.archive_file.dynamodb_s3export_lambda.output_path
  function_name    = "${var.name}-dynamodb-s3export"
  role             = aws_iam_role.dynamodb_s3export_lambda.arn
  handler          = "dynamodb-s3export.lambda_handler"
  source_code_hash = data.archive_file.dynamodb_s3export_lambda.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      "S3_BUCKET_ARN"       = aws_s3_bucket.dynamodb_s3export.arn
      "DYNAMODB_TABLE_ARNS" = join(",", [aws_dynamodb_table.main.arn, aws_dynamodb_table.ipns.arn])
    }
  }
}

data "archive_file" "dynamodb_s3export_lambda" {
  type        = "zip"
  source_file = "${path.module}/dynamodb-s3export.py"
  output_path = "${path.module}/dynamodb-s3export.zip"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dynamodb_s3export.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dynamodb_s3export.arn
}
