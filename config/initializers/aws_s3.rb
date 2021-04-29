require 'aws-sdk-core'

aws_access_key = ENV['CIVIC_AWS_ACCESS_KEY'] || Rails.application.secrets.aws_access_key
aws_secret_key = ENV['CIVIC_AWS_SECRET_KEY'] || Rails.application.secrets.aws_secret_key

Aws.config.update(
  region: 'us-west-2',
  credentials: Aws::Credentials.new(aws_access_key, aws_secret_key)
)
