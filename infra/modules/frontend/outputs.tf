output "bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
