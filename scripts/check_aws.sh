#!/bin/bash
aws sts get-caller-identity >/dev/null 2>&1 || {
  echo "ERROR: AWS credentials not configured!"
  echo "=> Run: aws configure"
  exit 1
}
echo "AWS credentials verified."
