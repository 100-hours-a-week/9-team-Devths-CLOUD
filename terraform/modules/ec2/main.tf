# ==============================================================================
# Ubuntu 22.04 AMI
# ==============================================================================

data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==============================================================================
# EC2 인스턴스
# ==============================================================================

resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu_22_04.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.iam_instance_profile_name
  associate_public_ip_address = var.associate_public_ip_address
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    iops                  = var.root_volume_type == "gp3" ? var.root_volume_iops : null
    throughput            = var.root_volume_type == "gp3" ? var.root_volume_throughput : null
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data_base64 = base64gzip(
    templatefile(var.user_data_template_path, {
      cluster_name       = var.cluster_name
      kubernetes_version = var.kubernetes_version
      node_name          = var.instance_name
      pod_cidr           = var.pod_cidr
      service_cidr       = var.service_cidr
      timezone           = var.timezone
    })
  )

  tags = merge(
    var.tags,
    {
      Name                                 = var.instance_name
      Cluster                              = var.cluster_name
      Role                                 = "control-plane"
      Type                                 = "k8s-master"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
}
