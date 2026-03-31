locals {
  vmseries_instances = flatten([for kv, vv in local.vmseries : [for ki, vi in vv.instances : { group = kv, instance = ki, az = vi.az, common = vv }]])
}

### BOOTSTRAP PACKAGE
module "bootstrap" {
  source = "./modules/bootstrap"

  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }

  iam_role_name             = "${var.name_prefix}vmseries${each.value.instance}"
  iam_instance_profile_name = "${var.name_prefix}vmseries_instance_profile${each.value.instance}"

  prefix      = var.name_prefix
  global_tags = var.global_tags

  bootstrap_options     = merge({ for k, v in each.value.common.bootstrap_options : k => v if v != null }, { hostname = "${var.name_prefix}${each.key}" })
  source_root_directory = "files"
}

### VM-Series INSTANCES

module "vmseries" {
  source = "./modules/vmseries"

  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }

  name              = "${var.name_prefix}-${each.key}"
  vmseries_version  = each.value.common.panos_version
  ebs_kms_key_alias = each.value.common.ebs_kms_id

  interfaces = {
    for k, v in each.value.common.interfaces : k => {
      device_index       = v.device_index
      private_ips        = [v.private_ip[each.value.instance]]
      security_group_ids = try([module.vpc[each.value.common.vpc].security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = module.subnet_sets["${v.vpc}-${v.subnet_group}"].subnets[each.value.az].id
      create_public_ip   = try(v.create_public_ip, false)
      eip_allocation_id  = try(v.eip_allocation_id[each.value.instance], null)
      ipv6_address_count = try(v.ipv6_address_count, null)
    }
  }

  bootstrap_options = join(";", compact(concat(
    ["vmseries-bootstrap-aws-s3bucket=${module.bootstrap[each.key].bucket_name}"],
    ["mgmt-interface-swap=${each.value.common.bootstrap_options["mgmt-interface-swap"]}"],
  )))

  iam_instance_profile = module.bootstrap[each.key].instance_profile_name
  ssh_key_name         = var.ssh_key_name
  tags                 = var.global_tags
}

### IAM ROLES AND POLICIES ###

data "aws_caller_identity" "this" {}

data "aws_partition" "this" {}

resource "aws_iam_role_policy" "this" {
  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }
  role     = module.bootstrap[each.key].iam_role_name
  policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricData",
        "cloudwatch:ListMetrics"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DescribeAlarms"
      ],
      "Resource": [
        "arn:${data.aws_partition.this.partition}:cloudwatch:${var.region}:${data.aws_caller_identity.this.account_id}:alarm:*"
      ],
      "Effect": "Allow"
    }
  ]
}

EOF
}

### ROUTES ###

# locals {
#   vpc_routes_with_next_hop_map = flatten(concat([
#     for vk, vv in local.vpcs : [
#       for rk, rv in vv.routes : {
#         vpc              = rv.vpc
#         subnet           = rv.subnet_group
#         to_cidr          = rv.to_cidr
#         destination_type = rv.destination_type
#         next_hop_type    = rv.next_hop_type
#         next_hop_map = {
#           "internet_gateway" = try(module.vpc[rv.next_hop_key].igw_as_next_hop_set, null)
#         }
#       }
#   ]]))
#   vpc_routes = {
#     for route in local.vpc_routes_with_next_hop_map : "${route.vpc}-${route.subnet}-${route.to_cidr}" => {
#       vpc              = route.vpc
#       subnet           = route.subnet
#       to_cidr          = route.to_cidr
#       destination_type = route.destination_type
#       next_hop_set     = lookup(route.next_hop_map, route.next_hop_type, null)
#     }
#   }
# }

# module "vpc_routes" {
#   source = "./modules/vpc_route"

#   for_each = local.vpc_routes

#   route_table_ids  = module.subnet_sets["${each.value.vpc}-${each.value.subnet}"].unique_route_table_ids
#   to_cidr          = each.value.to_cidr
#   destination_type = each.value.destination_type
#   next_hop_set     = each.value.next_hop_set
# }