## FW

create_public_ip_mgmt = true # Change to true first time. After FW successful boot, modify it to false

### VPC
cidr           = "10.10.0.0/16"

### XSIAM Components

broker_vm        = false
broker_vm_key    = "broker-vm-30.0.63.vmdk"
broker_vm_subnet = "vlan1" # allowed values vlan1, vlan2. vlan1 by default

engine_vm        = false
engine_vm_subnet = "vlan1" # allowed values vlan1, vlan2. vlan1 by default

### Deploy VMs

linux_deploy          = true
windows_server_deploy = true
kali_deploy           = true