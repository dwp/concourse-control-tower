#!/bin/bash

set -e

# Install concourse
curl -s -L -f -o ./concourse.tgz https://github.com/concourse/concourse/releases/download/v${concourse_version}/concourse-${concourse_version}-linux-amd64.tgz
tar -xzf ./concourse.tgz -C /usr/local

# Download concourse keys
export AWS_DEFAULT_REGION=${aws_default_region}

mkdir /etc/concourse
aws s3 cp s3://${keys_bucket_id}/session_signing_key /etc/concourse/session_signing_key
aws s3 cp s3://${keys_bucket_id}/tsa_host_key /etc/concourse/host_key
aws s3 cp s3://${keys_bucket_id}/authorized_worker_keys /etc/concourse/authorized_worker_keys

# Enable & start concourse_web service
systemctl enable concourse_web.service
systemctl start concourse_web.service
