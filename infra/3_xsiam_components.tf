module "broker_vm" {
  count  = var.broker_vm ? 1 : 0
  source = "./modules/broker_vm"
  name_prefix = var.name_prefix
  global_tags = var.global_tags
}

data "aws_ami_ids" "broker" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["*broker*"]
  }
}

locals {
  broker_ami_id = length(data.aws_ami_ids.broker.ids) > 0 ? data.aws_ami_ids.broker.ids[0] : null
  engine_ami_id = try(data.aws_ami.ubuntu2204.id, null)
}

# Ubuntu 22.04 oficial de Canonical
data "aws_ami" "ubuntu2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

locals {
  xsiam_components = {
    "${var.name_prefix}-broker_vm" = {
      deploy = var.broker_vm
      ami    = local.broker_ami_id
      type   = "t3.medium"
      user   = "ubuntu"
      network = { subnet = var.broker_vm_subnet, public_ip = false} # Always Public IP is FALSE
    }
    "${var.name_prefix}-engine" = {
      deploy = var.engine_vm
      ami    = local.engine_ami_id
      type   = "t3.medium"
      user   = "ubuntu"
      network = { subnet = var.engine_vm_subnet, public_ip = false} # Always Public IP is FALSE
    }
  }
}


resource "aws_instance" "xsiam_components" {
  for_each = {
    for k, v in local.xsiam_components :
    k => v if v.deploy && v.ami != null
  }

  ami                    = each.value.ami
  instance_type          = each.value.type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = try([module.vpc[var.vpc_name].security_group_ids["vmseries_traffic"]], [])
  ebs_optimized          = true
  subnet_id              = values(module.subnet_sets["${var.vpc_name}-${var.name_prefix}-${each.value.network.subnet}"].subnets)[0].id

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 40
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