output "src_replica_endpoint" {
  value = aws_db_instance.src_replica.endpoint
}

output "dst_replica_endpoint" {
  value = aws_db_instance.dst_replica.endpoint
}

output "symmetricds_instance_id" {
  value = aws_instance.symmetricds_instance.id
}

output "symmetricds_instance_public_ip" {
  value = aws_instance.symmetricds_instance.public_ip
}

