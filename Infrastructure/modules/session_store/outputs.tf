output "session_encryption_key_arn" {
  description = "The ARN of the Secret to use when encrypting the session data"
  value       = aws_secretsmanager_secret.session_encryption_key.arn
}

output "session_store_password" {
  description = "The password to access the REDIS Session Store"
  value       = random_string.random_password.result
}

output "session_store_address" {
  description = "The address of the REDIS Session Store"
  value       = aws_elasticache_cluster.sessions_cluster.cache_nodes[0].address
}

output "session_store_port" {
  description = "The port of the REDIS Session Store"
  value       = aws_elasticache_cluster.sessions_cluster.cache_nodes[0].port
}
