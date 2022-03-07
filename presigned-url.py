from sys import argv
import boto3

# unfortunately the AWS CLI cannot generate presigned S3 URLs for PutObject requests,
# so we have to do it with a proper AWS SDK

url = boto3.client('s3').generate_presigned_url(
    ClientMethod='put_object',
    Params={'Bucket': argv[1], 'Key': argv[2]},
    ExpiresIn=3600
)

print(url)
