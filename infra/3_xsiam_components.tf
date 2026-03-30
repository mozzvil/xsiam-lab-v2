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

# locals {
#   xsiam_components = {
#     "${var.name_prefix}-broker_vm" = {
#       deploy = var.broker_vm
#       ami    = local.broker_ami_id
#       type   = "t3.medium"
#       user   = "ubuntu"
#       subnet = "windows"
#     }
#     "${var.name_prefix}-engine" = {
#       deploy = var.engine_vm
#       ami    = local.engine_ami_id
#       type   = "t3.medium"
#       user   = "ubuntu"
#       subnet = "linux"
#     }
#   }
# }


# resource "aws_instance" "xsiam_components" {
#   for_each = {
#     for k, v in local.xsiam_components :
#     k => v if v.deploy
#   }

#   ami                    = each.value.ami
#   instance_type          = each.value.type
#   key_name               = var.ssh_key_name
#   vpc_security_group_ids = [data.aws_security_group.vm_series.id]
#   ebs_optimized          = true
#   subnet_id              = each.value.subnet == "windows" ? data.aws_subnets.subnet_windows.ids[0] : data.aws_subnets.subnet_linux.ids[0]

#   metadata_options {
#     http_endpoint = "enabled"
#     http_tokens   = "required"
#   }

#   root_block_device {
#     volume_type           = "gp3"
#     volume_size           = 30
#     delete_on_termination = true
#     encrypted             = true
#   }

#   tags = merge(
#     var.global_tags,
#     {
#       Name = each.key
#     }
#   )
# }