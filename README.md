# XSIAM-LAB-V2

Infrastructure as Code to deploy an XSIAM lab using **Terraform** and **GitHub Actions**.

---

## Description

This repository defines a complete lab environment including:

- Network (VPC, subnets, routing)
- Jumpbox (the only one with Public IP)
- Palo Alto VM-Series Firewall - BYOL - 4 vCPU
- XSIAM components (optional)
  - Broker VM  
  - Engine 
- Virtual machines
  - Windows Server 2022
  - Linux Ubuntu 22.04
  - Kali Linux

The deployment is fully automated and reproducible using Terraform.

---

## Architecture Diagram

![Architecture Diagram](xsiam-lab.png)

## Prerequisites

### AWS

An AWS account with permissions to create:

- EC2
- VPC
- Subnets
- Security Groups
- Route Tables
- Internet Gateway
- Elastic IP
- S3 (for backend)

Once you have the AWS account, you must manually create and configure:

- EC2 Key Pair (download the private key)
- S3 Bucket for Terraform Backend (`S3_BACKEND`)
- AWS Access Key / AWS Secret Access Key
- Configure AWS CLI (optional)

You will also need a GitHub account and fork this repository.

Then go to:

**Settings → Secrets and Variables → Actions**

Create the following:

**Secrets**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `CORTEX_API_KEY`
- `CORTEX_API_KEY_ID`

**Variables**
- `AWS_REGION`
- `S3_BACKEND`

### Palo Alto VM-Series

### Palo Alto VM-Series

You will need an **AuthCode** for VM-Series on your CSP.

Navigate to [`infra/files/license/authcodes`](https://github.com/davidaavilar/xsiam-lab-v2/blob/main/infra/files/license/authcodes)

Paste your AuthCode in that location before deployment.

---

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── xsiam-lab.yaml
├── infra/
│   ├── files/
│   ├── modules/
│   ├── 0_network.tf
│   ├── 1_jumpbox.tf
│   ├── 2_fw.tf
│   ├── 3_xsiam_components.tf
│   ├── 4_vms.tf
│   ├── backend.tf
│   ├── configuration.json
│   ├── data_sources.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   ├── variables.tf
│   └── versions.tf
├── .gitignore
└── README.md
```

## Variables

Defined in **infra/terraform.tfvars**, you need to update the following values:

| Variable | Description | Example / Allowed Values |
|----------|-------------|--------------------------|
| `region` | AWS region where resources will be deployed | `us-east-2` |
| `name_prefix` | Prefix used for naming all resources | `davila-xsiam-lab` |
| `global_tags.ManagedBy` | Resource tag indicating management tool | `terraform` |
| `global_tags.Application` | Resource tag for application name | `XSIAM Lab` |
| `global_tags.Owner` | Resource tag for owner | `David Avila` |
| `ssh_key_name` | SSH key pair name for EC2 access | `xsiam-lab-v2` |
| `cidr` | CIDR block for the VPC | `10.10.0.0/16` |
| `mgt_public_ips` | Allowed public IPs for management access | `["YOUR PUBLIC IP ADDRESS"]` |
| `broker_vm` | Deploy Broker VM | `true / false` |
| `broker_vm_key` | VMDK file name for Broker VM | `"file.vmdk"` |
| `broker_vm_subnet` | Subnet for Broker VM | `vlan1 / vlan2` |
| `engine_vm` | Deploy Engine VM | `true / false` |
| `engine_vm_subnet` | Subnet for Engine VM | `vlan1 / vlan2` |
| `linux_deploy` | Deploy Linux VM | `true / false` |
| `windows_server_deploy` | Deploy Windows Server VM | `true / false` |
| `kali_deploy` | Deploy Kali Linux VM | `true / false` |

---

## Broker VM Deployment (VMDK → AMI)

Follow these steps to deploy the Broker VM:

### Step 1 — Download VMDK

Download the Broker VM `.vmdk` file from your XSIAM tenant.

Place the file inside the `infra/` directory.

---

### Step 2 — Update Variables

Edit `infra/terraform.tfvars`:

```hcl
broker_vm     = true
broker_vm_key = "your-vmdk-file-name.vmdk"
```

### Step 3 — Execute de Github Actions (terraform apply)

Terraform will:

- Create required resources (S3, IAM roles, etc.)
- Prepare the environment for VM import
- Generate required AWS CLI commands

### Step 4 — Import VMDK to AMI

After execution, Terraform outputs will include AWS CLI commands. Run them locally to:

Upload the VMDK
Import it as an AMI

### Step 5 — Verify AMI
Go to EC2 → AMIs
Validate the image is available

### Broker VM Documentation

[Set up Broker VM on AWS (XSIAM Documentation)](https://docs-cortex.paloaltonetworks.com/r/Cortex-XSIAM/Cortex-XSIAM-Documentation/Set-up-Broker-VM-on-Amazon-Web-Services)

## Security

Do not commit .pem files
Do not hardcode credentials
Prefer IAM roles over static keys
Rotate credentials regularly