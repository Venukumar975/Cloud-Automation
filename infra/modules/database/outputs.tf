output "db_endpoint" {
  value = aws_db_instance.db.endpoint
}

output "db_port" {
  value = aws_db_instance.db.port
}

output "db_sg_id" {
  value = aws_security_group.db_sg.id
}
