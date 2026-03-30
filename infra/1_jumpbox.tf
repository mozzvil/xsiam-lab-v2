# Windows Server 2022
data "aws_ami" "jumpbox" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
  owners = ["801119661308"] # Canonical
}

locals {
  jumpbox = {
    "${var.name_prefix}-jumpbox" = {
      ami    = data.aws_ami.jumpbox.id
      type   = "t3.medium"
      user   = "Administrator"
      subnet = "mgmt"
    }
  }
}

data "aws_subnets" "mgmt" {
  filter {
    name   = "tag:Name"
    values = ["mgmt"]
  }
}

resource "aws_instance" "jumpbox" {
  for_each = local.jumpbox

  ami                    = each.value.ami
  instance_type          = each.value.type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = try([module.vpc[var.vpc_name].security_group_ids["vmseries_mgmt"].id], [])
  ebs_optimized          = true
  subnet_id              = values(module.subnet_sets["security_vpc-mgmt"].subnets)[0].id
  lifecycle {
    ignore_changes = [ami]
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(
    var.global_tags,
    {
      Name = each.key
    }
  )
}