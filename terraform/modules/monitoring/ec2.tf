# EC2 인스턴스 (모니터링 서버)
resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  iam_instance_profile   = var.iam_instance_profile_name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
    encrypted             = true
  }

  # user_data를 gzip으로 압축하여 16KB 제한 우회
  user_data_base64 = base64gzip(
    templatefile("${path.module}/scripts/monitoring_user_data.sh", {
      monitoring_domain      = var.monitoring_domain
      environment            = var.environment
      grafana_admin_password = var.grafana_admin_password
      prometheus_retention   = var.prometheus_retention
      server_label           = var.server_label
      target_dev_ip          = var.target_dev_ip
      target_staging_ip      = var.target_staging_ip
      target_prod_ip         = var.target_prod_ip
    })
  )

  tags = merge(
    var.common_tags,
    {
      Name = var.instance_name
      Type = "Monitoring"
    }
  )
}
