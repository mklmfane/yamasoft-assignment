
# DOCUMENTATION

## Overview

This stack provisions a staging **AWS VPC** with two Availability Zones and the required networking primitives (subnets, routing, NAT/IGW) plus **private connectivity to AWS Systems Manager (SSM)** via **Interface** VPC endpoints and **S3** via a **Gateway** VPC endpoint.
It also includes IAM artifacts for **Terraform state access**, and a **GitHub OIDC** integration to assume an AWS role from GitHub Actions.

> Region: **eu-west-1**
> Supernet: **172.16.0.0/16**
> AZs: **eu-west-1a**, **eu-west-1b**

---

## Architecture (high-level)

```
VPC 172.16.0.0/16
├─ Public subnets (/20)       ──> IGW ──> Internet
│   ├─ 172.16.64.0/20 (1a)
│   └─ 172.16.80.0/20 (1b)
│   ├─ 172.16.96.0/20 (1a)
│   └─ 172.16.112.0/20 (1b)
│       └─ NAT GW in each AZ  (EIP)
│
└─ Private subnets (/20)
    ├─ 172.16.0.0/20 (1a)
    └─ 172.16.16.0/20 (1b)
    ├─ 172.16.32.0/20 (1a)
    └─ 172.16.48.0/20 (1b)
        ├─ Default NACL/SG hardened
        ├─ Route to NAT GW for egress
        ├─ **Interface** VPC endpoints: SSM, SSMMessages, EC2Messages (1 subnet per AZ)
        └─ **Gateway** VPC endpoint: S3 (attached to private route tables)
```

---

## Modules

### `module.vpc`

Creates all VPC networking resources and VPC Endpoints.

### `module.github-oidc`

Configures GitHub’s OIDC IdP in AWS and an IAM Role for GitHub Actions to assume.

---

## Data Sources

| Data Source                                                                 | Purpose                                              |
| --------------------------------------------------------------------------- | ---------------------------------------------------- |
| `data.aws_caller_identity.current`                                          | Determines current AWS account for ARNs in policies. |
| `module.vpc.module.vpc_endpoints.data.aws_vpc_endpoint_service.this["ssm"]` | Resolves SSM endpoint service name/metadata.         |
| `module.vpc.module.vpc_endpoints.data.aws_vpc_endpoint_service.this["s3"]`  | Resolves S3 endpoint service name/metadata.          |

---

## Resources (by category)

### IAM (Terraform state + least-privileged apply)

#### `aws_iam_policy.tf_backend_rw`

Policy granting **S3** read/write to the Terraform state bucket and **DynamoDB** table access for state locking.

* **S3**: `ListBucket`, `GetObject`, `PutObject`, `DeleteObject` on:

  * `arn:aws:s3:::my-tf-state-bucket--xxxxxx`
  * `arn:aws:s3:::my-tf-state-bucket--xxxxxx/*`
* **DynamoDB**: `DescribeTable`, `GetItem`, `PutItem`, `DeleteItem` on:

  * `arn:aws:dynamodb:eu-west-1:<account_id>:table/tf-locks`

#### `aws_iam_policy.tf_vpc_apply`

Least-privilege policy to **create/modify** VPC, subnets, RTs, IGW, NAT (EIP), default SG/NACL rules, and **VPC endpoints**.
Also includes read permissions for ELB and SSM describe operations.

---

### GitHub OIDC (federation for CI/CD)

#### `module.github-oidc.data.aws_iam_policy_document.this[0]`

Trust policy for **`sts:AssumeRoleWithWebIdentity`** from GitHub’s OIDC provider, restricted to the repository subject:

* `token.actions.githubusercontent.com:sub` like `repo:mklmfane/yamasoft-assignment:*`

#### `module.github-oidc.aws_iam_openid_connect_provider.this[0]`

Registers **GitHub OIDC** as a federated identity provider.

* URL: `https://token.actions.githubusercontent.com`
* Client IDs: `sts.amazonaws.com`
* Thumbprint: `6938fd4d98bab03faadb97b34396831e3780aea1` (GitHub IdP root)

#### `module.github-oidc.aws_iam_role.this[0]`

IAM role **`github-oidc-provider-aws`** assumed by GitHub Actions via OIDC.

* `max_session_duration = 3600`
* Inline/managed policies attached via:

#### `module.github-oidc.aws_iam_role_policy_attachment.attach[0..1]`

Attaches policies (e.g., `tf_backend_rw`, `tf_vpc_apply`) to the OIDC role.

---

### Core Networking (VPC & Defaults)

#### `module.vpc.aws_vpc.this[0]`

Creates VPC:

* `cidr_block = 172.16.0.0/16`
* DNS hostnames/support enabled
* Tagged `Name = test-vpc-assignment-tf`

#### `module.vpc.aws_internet_gateway.this[0]`

Internet connectivity for public subnets; attached to the VPC.

#### `module.vpc.aws_default_network_acl.this[0]`

Manages the **default NACL** (explicit allow egress/ingress shown in plan). Tagging aligns with environment naming.

#### `module.vpc.aws_default_security_group.this[0]`

Manages the **default SG** (rules managed explicitly by module). Keeps consistent tagging.

#### `module.vpc.aws_default_route_table.default[0]`

Manages the **default route table** (module config ensures desired routes/tags/timeouts).

---

### Subnets

> **Eight subnets total**: **4 Private** + **4 Public**, split evenly across **eu-west-1a** and **eu-west-1b**, all /20 within `172.16.0.0/16`.

#### Private

* `module.vpc.aws_subnet.private[0]` → `172.16.0.0/20` (1a)
* `module.vpc.aws_subnet.private[1]` → `172.16.16.0/20` (1b)
* `module.vpc.aws_subnet.private[2]` → `172.16.32.0/20` (1a)
* `module.vpc.aws_subnet.private[3]` → `172.16.48.0/20` (1b)

#### Public

* `module.vpc.aws_subnet.public[0]` → `172.16.64.0/20` (1a)
* `module.vpc.aws_subnet.public[1]` → `172.16.80.0/20` (1b)
* `module.vpc.aws_subnet.public[2]` → `172.16.96.0/20` (1a)
* `module.vpc.aws_subnet.public[3]` → `172.16.112.0/20` (1b)

All subnets:

* `map_public_ip_on_launch = false` (module handles public behavior via RTs/IGW)
* Tagged per subnet role/AZ.

---

### NAT + EIP

#### `module.vpc.aws_eip.nat[0..1]`

Two Elastic IPs (one per AZ) to back NAT Gateways.

#### `module.vpc.aws_nat_gateway.this[0..1]`

NAT in each public subnet/AZ for private egress.

---

### Route Tables & Associations

#### Private Route Tables

* `module.vpc.aws_route_table.private[0]` (`eu-west-1a`)
* `module.vpc.aws_route_table.private[1]` (`eu-west-1b`)

**Routes**

* `module.vpc.aws_route.private_nat_gateway[0..1]`
  `0.0.0.0/0` → NAT GW (per-AZ)

**Associations**

* `module.vpc.aws_route_table_association.private[0..3]`
  Associates the four private subnets to the per-AZ private RTs.

#### Public Route Table

* `module.vpc.aws_route_table.public[0]`

**Routes**

* `module.vpc.aws_route.public_internet_gateway[0]`
  `0.0.0.0/0` → IGW

**Associations**

* `module.vpc.aws_route_table_association.public[0..3]`
  Associates the four public subnets to the public RT.

---

### VPC Endpoints

> **Design**:
>
> * **SSM**: Interface endpoint (private DNS enabled).
> * **S3**: **Gateway** endpoint attached to **private** route tables.
> * Interface endpoints require **one subnet per AZ** (the module ensures no duplicate AZs).

#### `module.vpc.module.vpc_endpoints.aws_vpc_endpoint.this["ssm"]`

* `vpc_endpoint_type = "Interface"`
* `service_name = com.amazonaws.eu-west-1.ssm`
* `private_dns_enabled = true`
* `subnet_ids`: one private subnet per AZ
* `security_group_ids`: as provided/merged by module logic

#### `module.vpc.module.vpc_endpoints.aws_vpc_endpoint.this["s3"]`

* `vpc_endpoint_type = "Gateway"`
* `service_name = com.amazonaws.eu-west-1.s3`
* **No** subnets/SGs
* `route_table_ids`: private route tables so private subnets reach S3 without public internet/NAT

---

## Inputs (representative)

> Exact variables/values depend on your `variables.tf` and environment, but the plan implies:

| Name                 | Type         | Example                                 | Description                                       |
| -------------------- | ------------ | --------------------------------------- | ------------------------------------------------- |
| `region`             | string       | `eu-west-1`                             | Deployment region.                                |
| `name`               | string       | `test-vpc-assignment-tf`                | Base name for VPC resources/tags.                 |
| `cidr`               | string       | `172.16.0.0/16`                         | VPC CIDR.                                         |
| `azs`                | list(string) | `["eu-west-1a","eu-west-1b"]`           | Availability Zones.                               |
| `private_subnets`    | list(string) | 4 × `/20`                               | Private subnet CIDRs (two per AZ).                |
| `public_subnets`     | list(string) | 4 × `/20`                               | Public subnet CIDRs (two per AZ).                 |
| `enable_nat_gateway` | bool         | `true`                                  | Create NAT GW per AZ.                             |
| `enable_vpn_gateway` | bool         | `false/true`                            | (Not shown in plan if false).                     |
| `endpoints`          | map(any)     | see module input                        | VPC endpoints config (SSM Interface, S3 Gateway). |
| `tags`               | map(string)  | `{Environment="dev", Terraform="true"}` | Common tags.                                      |

---

## Outputs (representative)

Depending on your module, typical outputs are:

| Output                    | Description                                    |
| ------------------------- | ---------------------------------------------- |
| `vpc_id`                  | The VPC ID.                                    |
| `private_subnet_ids`      | IDs of private subnets.                        |
| `public_subnet_ids`       | IDs of public subnets.                         |
| `private_route_table_ids` | Private RT IDs (used for S3 gateway endpoint). |
| `internet_gateway_id`     | IGW ID.                                        |
| `nat_gateway_ids`         | NAT Gateway IDs.                               |
| `vpc_endpoint_ids`        | Map of created endpoint IDs keyed by service.  |

(Adjust to match your module’s `outputs.tf`.)

---

## How to Use

```bash
# Initialize providers and modules
terraform init

# (Optional) Validate
terraform validate

# Plan changes
terraform plan -out tfplan

# Apply
terraform apply tfplan

# Destroy
terraform destroy
```

---

## Security & Operational Notes

* **S3 Gateway Endpoint** is attached to **private** route tables to keep private subnets off the internet for S3 access.
* **Interface Endpoints** (SSM) use only **one subnet per AZ** by design (required by AWS).
* Default SG/NACL are managed explicitly for idempotency and visibility.
* **GitHub OIDC** role enables keyless CI by exchanging OIDC token for a temporary AWS role session.
* NAT per AZ avoids cross-AZ data charges and provides resilience.

---

## Regenerating Docs with `terraform-docs` (optional)

If you keep variables/outputs up to date, you can generate module input/output tables automatically:

```bash
# Install terraform-docs (if needed)
# macOS: brew install terraform-docs
# Linux:  curl -sSLo /usr/local/bin/terraform-docs \
#         https://github.com/terraform-docs/terraform-docs/releases/download/v0.17.0/terraform-docs-v0.17.0-$(uname)-amd64
#         && chmod +x /usr/local/bin/terraform-docs

# Generate docs for the root module into DOCUMENTATION.md
terraform-docs markdown table . > DOCUMENTATION.md

# Or generate docs for a submodule:
terraform-docs markdown table modules/vpc > modules/vpc/README.md
```

> This `DOCUMENTATION.md` includes hand-written explanations of resources reflected in your current **plan**. If you later add/change variables/outputs, consider re-running `terraform-docs` and merging the auto-generated tables with these narrative sections.

---

## Change Log

* Current plan summary: **39 to add**, **0** to change, **0** to destroy.
* Key corrections made:

  * VPC CIDR set to **172.16.0.0/16**
  * Subnets aligned to the supernet and sized `/20`
  * **S3** endpoint switched to **Gateway** type and attached to **private** route tables
  * Interface endpoints limited to **one subnet per AZ** to satisfy AWS constraints

---
