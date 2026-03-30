## VMs

# output "ssh_file_entries" {
#   value = join("\n\n", [
#     for name, instance in local.instances : <<-EOT
#       Host ${name}
#         HostName ${aws_instance.vm[name].private_ip}
#         User ${instance.user}
#         IdentityFile ~/Documents/${var.ssh_key_name}.pem
#         IdentitiesOnly yes
#     EOT
#     if contains(["xsiam-ubuntu-engine", "centos9", "kali"], name) # Solo Linux
#   ])
#   description = "modify vim ~/.ssh/config"
# }

# output "private_ips" {
#   description = "Private IPs de todas las instancias"
#   value = {
#     for name, inst in aws_instance.vm :
#     name => inst.private_ip
#   }
# }

# # FWS

# output "vmseries_public_ips" {
#   description = "Map of public IPs created within `vmseries` module instances."
#   value       = { for k, v in module.vmseries : k => v.public_ips }
# }

# output "subnet_mgt" {
#   value = values(module.subnet_sets["${}"].subnets)[0].id # security_vpc-davila-xsiam-lab-mgmt
# }
