locals {
  # This script help install the symmetricds software
  user_data = templatefile("${path.module}/user_data/bootstrap.sh", {
    src_db_url    = "jdbc:oracle:thin:@${aws_db_instance.src_replica.endpoint}:${var.db_name}"
    dst_db_url    = "jdbc:oracle:thin:@${aws_db_instance.dst_replica.endpoint}:${var.db_name}"
    db_username   = "${var.db_username}"
    db_password   = "${var.db_password}"
    sync_hostname = "127.0.0.1"
  })
}
