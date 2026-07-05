#!/bin/sh
echo "=== Initializing LocalStack Resources ==="

# Create S3 Bucket
awslocal s3 mb s3://sample-app-bucket

# Upload a test file to S3
echo "Platform local development is active!" > /tmp/hello-platform.txt
awslocal s3 cp /tmp/hello-platform.txt s3://sample-app-bucket/hello-platform.txt

# Create SSM Parameter Store entries
awslocal ssm put-parameter \
    --name "/dev/sample-app/ecs_cluster_name" \
    --type "String" \
    --value "sample-app-dev-cluster" \
    --overwrite

echo "=== LocalStack Initialization Completed ==="
