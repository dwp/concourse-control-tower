#!/bin/bash

set -e

# Install concourse
curl -s -L -f -o ./concourse.tgz https://github.com/concourse/concourse/releases/download/v${concourse_version}/concourse-${concourse_version}-linux-amd64.tgz
tar -xzf ./concourse.tgz -C /usr/local

# Download concourse keys
export AWS_DEFAULT_REGION=${aws_default_region}

mkdir /etc/concourse
aws s3 cp s3://${keys_bucket_id}/tsa_host_key.pub /etc/concourse/
aws s3 cp s3://${keys_bucket_id}/worker_key /etc/concourse/

# Enable & start concourse_web service
systemctl enable concourse_worker.service
systemctl start concourse_worker.service
