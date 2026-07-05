terraform {
  # Standard remote backend config using S3 and DynamoDB for state locking
  # This block is parameterized for the user's infrastructure bucket and lock table.
  # Replace placeholders with your own bucket/table names in production.

  # backend "s3" {
  #   bucket         = "platform-engineering-tfstate-bucket"
  #   key            = "environments/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "platform-engineering-tflocks"
  #   encrypt        = true
  # }

  # Fallback to local backend for testing/local run without AWS credentials
  backend "local" {
    path = "terraform.tfstate"
  }
}
