import os
import boto3
import logging
import datetime

# Initialize logger
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Create AWS clients
client_dynamodb = boto3.client('dynamodb')


def lambda_handler(event, context):
    logger.debug(f"Event {event}")
    logger.debug(f"Context {context}")

    s3_bucket_name = os.environ['S3_BUCKET_NAME']
    dynamodb_table_arns = os.environ['DYNAMODB_TABLE_ARNS']

    logger.debug(f"S3_BUCKET_NAME: {s3_bucket_name}")
    logger.debug(f"DYNAMODB_TABLE_ARNS: {dynamodb_table_arns}")

    for dynamodb_table_arn in dynamodb_table_arns.split(","):
        # build prefix like: table_name/2022-08-11
        s3_prefix = f'{dynamodb_table_arn.split("/")[-1]}/{datetime.datetime.now().strftime("%Y-%m-%d")}'

        logger.info(f"Triggering export of table {dynamodb_table_arn} to bucket {s3_bucket_name}/{s3_prefix}")
        response = client_dynamodb.export_table_to_point_in_time(
            TableArn=dynamodb_table_arn,
            S3Bucket=s3_bucket_name,
            S3Prefix=s3_prefix,
            ExportFormat='DYNAMODB_JSON'
        )
        logger.info(f"DynamoDB export response: {response}")
    logger.info(f"Exports done.")
