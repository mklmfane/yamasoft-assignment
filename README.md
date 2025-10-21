# DevOps Exercises

Please pick just **2** of the exercises below and complete them. Once you have finished, place your submission in a GitHub repository and share it. We’ll schedule a time to review your solution after an internal review.

---

## AWS VPC Exercise

You have been assigned a project to create a new Terraform module for creating a **staging VPC** in AWS.

### Requirements

* Network supernet **172.16.0.0/16**
* **Internal endpoint for AWS Systems Manager (SSM)**
* **Internal endpoint for S3**
* **Two availability zones**, with **two private subnets** and **two public subnets** for **each** availability zone
* **Appropriate routing tables**
* **Appropriate NAT gateways** and an **internet gateway**

Create module code to fulfill this request using **Terragrunt/Terraform**. Show how you would use this module to bring up the architecture.

**Resolution location**
The resolution for this exercise is in the repository root, containing the Terraform source code in `.tf` files.

---

### Interpretation of the Requirements

* Staging VPC CIDR: `172.16.0.0/16`
* Two AZs; **2 private + 2 public** subnets per AZ (→ **4 private + 4 public** total)
* Routing tables, Internet Gateway (IGW), and **NAT Gateway per AZ**
* Private endpoints: **SSM (interface)** and **S3 (gateway)**
* Provide module code and usage (optionally via Terragrunt); show plan for VPC resources

### Monorepo Structure (example)

1. **`modules/vpc`**

   * Creates the VPC (CIDR `172.16.0.0/16`) across two AZs
   * 4 private + 4 public subnets (explicit CIDRs provided as inputs)
   * IGW for public subnets
   * NAT Gateways per AZ; private route tables default route via NAT
   * **VPC endpoints** submodule:

     * S3 **gateway** endpoint associated to route tables (internal S3)
     * SSM **interface** endpoint in subnets with private DNS (internal SSM)

2. **`modules/s3_bucket_state`**

   * Bootstraps the remote **S3 state bucket** and **DynamoDB lock table**
   * Creation toggles: `create_bucket`, `create_lock_table`
   * On later runs, set toggles to `false` and pass existing names

3. **`modules/iam_tf_policies`**

   * IAM policies for CI/CD:

     * RW to the state bucket + lock table
     * Minimal VPC “apply” permissions (Describe, CreateVpc, CreateTags, etc.)
   * Skips creation if an existing policy ARN is supplied

4. **`modules/github_oidc`**

   * Uses an existing GitHub OIDC provider ARN (or can create one)
   * Creates an assumable role for the workflow and **attaches policies** from (3)

### Root Usage (`main.tf`)

```hcl
module "vpc" {                         # VPC with subnets, NAT, routes, endpoints
  source = "./modules/vpc"
  name   = var.vpc_name
  cidr   = "172.16.0.0/16"
  azs    = ["eu-west-1a", "eu-west-1b"]

  private_subnets = [
    "172.16.0.0/20",  "172.16.16.0/20",
    "172.16.32.0/20", "172.16.48.0/20"
  ]
  public_subnets = [
    "172.16.64.0/20",  "172.16.80.0/20",
    "172.16.96.0/20",  "172.16.112.0/20"
  ]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  single_nat_gateway     = false
}

module "s3_bucket_state_oidc" {        # State bucket + lock table (bootstrap only)
  source               = "./modules/s3_bucket_state"
  bucket_prefix_name   = var.bucket_prefix_name
  lock_table           = var.lock_table
  create_bucket        = var.create_bucket
  create_lock_table    = var.create_lock_table
  state_key            = "envs/${var.environment}/terraform.tfstate"
  existing_bucket_name = var.existing_bucket_name
  existing_lock_table  = var.existing_lock_table
}

module "iam_tf_policies" {             # Policies used by the OIDC role
  source          = "./modules/iam_tf_policies"
  bucket_name     = module.s3_bucket_state_oidc.s3_bucket_id
  lock_table_name = module.s3_bucket_state_oidc.lock_table_name
  region          = var.region
  depends_on      = [module.s3_bucket_state_oidc]
}

module "github_oidc" {                 # OIDC role attaching the above policies
  source               = "./modules/github_oidc"
  create_oidc_provider = false
  oidc_provider_arn    = local.existing_provider_arn
  create_oidc_role     = true
  repositories         = var.repository_list
  oidc_role_attach_policies = [
    module.iam_tf_policies.tf_backend_rw_policy_arn,
    module.iam_tf_policies.tf_vpc_apply_policy_arn
  ]
  depends_on = [module.iam_tf_policies]
}
```

### Summary & Dependencies

* `modules/vpc` — VPC, subnets, NAT, routes, endpoints
* `modules/iam_tf_policies` — IAM policies for backend and VPC apply
* `modules/github_oidc` — OIDC role that **attaches** policies from the IAM module

**Dependency order**

1. `iam_tf_policies` **depends on** `s3_bucket_state_oidc`
2. `github_oidc` **depends on** `iam_tf_policies`

### CI/CD Flow (example)

* **Bootstrap job** (one-time with long-lived keys)

  1. `terraform init` locally (backend disabled)
  2. Create state S3 + DDB, policies, OIDC role (module targets)
  3. Export bucket/table/role outputs
* **Deploy job** (assume OIDC role)

  1. Set `create_bucket=false`, `create_lock_table=false`
  2. Migrate TF backend to S3 + DDB
  3. `plan`/`apply` the stack

### Planning Approaches

* **Simple (demo)** — target the VPC module:

  ```bash
  terraform plan -target=module.vpc -input=false -no-color
  ```

  > Good for showcasing; avoid `-target` for full lifecycles (used here for cost reasons).

* **Clean separation (Terragrunt)** — run VPC as its own stack:
  `live/staging/vpc/terragrunt.hcl → source = "../../../modules/vpc"`

  ```bash
  cd live/staging/vpc
  terragrunt plan
  ```

* **Inputs-only control** — disable non-VPC creations (e.g., `create_bucket=false`, `create_lock_table=false`) and run a standard `terraform plan`.

### How the Requirements Are Met

* CIDR and subnet layout match `172.16.0.0/16` with 2 AZs × (2 private + 2 public)
* IGW for public subnets
* NAT Gateway **per AZ** for private egress
* Route tables created and associated for public/private subnets
* Endpoints:

  * **S3**: Gateway endpoint for internal S3 access
  * **SSM**: Interface endpoint with private DNS for internal SSM

---

## Deploying an Application

### Helm

* Create a simple **templated Helm chart** that deploys an **NGINX** server and an appropriate **Ingress** (assume either an NGINX or ALB controller).
* Create a **values.yml** that fulfills the chart’s values.
* Show a **command that dumps the rendered templates**.

**Resolution location**
`exercise3/yamosoft-assignment/README.md`

### Prerequisites

* Install **VirtualBox**: [https://www.virtualbox.org/wiki/Download_Old_Builds_7_1](https://www.virtualbox.org/wiki/Download_Old_Builds_7_1)
* Install **Vagrant**: [https://developer.hashicorp.com/vagrant/docs/installation](https://developer.hashicorp.com/vagrant/docs/installation)

### Steps

1. Navigate to `exercise3/yamosoft-assignment`.
2. Bring up the environment:

   ```bash
   vagrant up
   ```

   Wait for provisioning to complete.
3. Connect to the control plane:

   ```bash
   vagrant ssh controlplane
   ```
4. Copy and run the tested script:

   ```bash
   cp exercise3/yamosoft-assignment/script_tested_solution.sh exercise4.sh
   chmod +x exercise4.sh
   ./exercise4.sh
   ```

---

## Helm Chart: `charts/nginx`

```
charts/nginx/
├─ Chart.yaml
├─ values.yaml
└─ templates/
   ├─ deployment.yaml
   ├─ service.yaml
   └─ ingress.yaml
```

### `Chart.yaml`

```yaml
apiVersion: v2
name: nginx
description: Simple NGINX app with Ingress
type: application
version: 0.1.0
appVersion: "1.25"
```

### `values.yaml` (aka `values.yml`)

```yaml
replicaCount: 1

image:
  repository: nginx
  tag: "1.25-alpine"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx         # for NGINX Ingress Controller; use "alb" if targeting AWS ALB
  hosts:
    - host: nginx.localtest.me
      paths:
        - path: /
          pathType: Prefix
  tls: []                  # e.g., [{ secretName: nginx-tls, hosts: [nginx.localtest.me] }]

resources: {}
nodeSelector: {}
tolerations: []
affinity: {}
```

### `templates/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "nginx.fullname" . }}
  labels: {{- include "nginx.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels: {{- include "nginx.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels: {{- include "nginx.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: nginx
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: 80
```

### `templates/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "nginx.fullname" . }}
  labels: {{- include "nginx.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
      protocol: TCP
      name: http
  selector: {{- include "nginx.selectorLabels" . | nindent 4 }}
```

### `templates/ingress.yaml`

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "nginx.fullname" . }}
  labels: {{- include "nginx.labels" . | nindent 4 }}
  {{- if .Values.ingress.className }}
  annotations:
    kubernetes.io/ingress.class: {{ .Values.ingress.className | quote }}
  {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "nginx.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- toYaml .Values.ingress.tls | nindent 4 }}
  {{- end }}
{{- end }}
```

---

## Rendering and Installing

**Render without installing**

```bash
helm template my-nginx ./charts/nginx -f charts/nginx/values.yaml --namespace web
```

**Install**

```bash
helm upgrade --install my-nginx ./charts/nginx -n web --create-namespace -f charts/nginx/values.yaml
```

---

## Local Cluster Notes (Vagrant + MetalLB + ingress-nginx)

If you are running a local cluster (e.g., Vagrant VMs), use **MetalLB** to provide a LoadBalancer IP and deploy **ingress-nginx** via Helm.

1. **Add repos & pull chart locally**

   ```bash
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo add metallb https://metallb.github.io/metallb
   helm repo update
   helm pull ingress-nginx/ingress-nginx --untar
   ```

2. **Install MetalLB (CRDs + controllers)**

   ```bash
   kubectl create ns metallb-system
   helm upgrade --install metallb metallb/metallb \
     -n metallb-system --create-namespace --wait --timeout 3m
   ```

3. **Configure an address pool**

   ```yaml
   # metallb-pool.yaml
   apiVersion: metallb.io/v1beta1
   kind: IPAddressPool
   metadata:
     name: vagrant-pool
     namespace: metallb-system
   spec:
     addresses:
       - 192.168.56.240-192.168.56.250
   ---
   apiVersion: metallb.io/v1beta1
   kind: L2Advertisement
   metadata:
     name: vagrant-l2
     namespace: metallb-system
   spec:
     ipAddressPools:
       - vagrant-pool
   ```

   ```bash
   kubectl apply -f metallb-pool.yaml
   ```

4. **Install ingress-nginx using the local chart**

   ```bash
   cd ./ingress-nginx
   helm upgrade --install my-ingress . \
     -n ingress-nginx --create-namespace -f values.yaml --wait
   kubectl -n ingress-nginx get svc my-ingress-ingress-nginx-controller --watch
   ```

   Expect `TYPE=LoadBalancer` and an `EXTERNAL-IP` like `192.168.56.240`.

5. **ingress-nginx values (MetalLB-friendly)**

   ```yaml
   # ingress-nginx values.yaml (excerpt)
   controller:
     ingressClassResource:
       name: nginx
       default: true
     service:
       type: LoadBalancer
       annotations:
         metallb.universe.tf/address-pool: vagrant-pool
       externalTrafficPolicy: Local
     config:
       proxy-body-size: "64m"
       enable-brotli: "true"
   ```

6. **Smoke test**

   ```yaml
   # echo-app.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: echo
     namespace: default
   spec:
     replicas: 1
     selector:
       matchLabels: { app: echo }
     template:
       metadata: { labels: { app: echo } }
       spec:
         containers:
           - name: echo
             image: hashicorp/http-echo
             args: ["-text=hello from ingress"]
             ports: [{ containerPort: 5678 }]
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: echo
     namespace: default
   spec:
     selector: { app: echo }
     ports: [{ port: 80, targetPort: 5678 }]
   ---
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: echo
     namespace: default
   spec:
     ingressClassName: nginx
     rules:
       - host: echo.localtest.me
         http:
           paths:
             - path: /
               pathType: Prefix
               backend:
                 service:
                   name: echo
                   port:
                     number: 80
   ```

   ```bash
   kubectl apply -f echo-app.yaml
   # If needed, map host: 192.168.56.240  echo.localtest.me
   curl -H "Host: echo.localtest.me" http://192.168.56.240/
   ```

   Expected output: `hello from ingress`.

---

## Notes

* For AWS with the **ALB Ingress Controller**, set `ingress.className: alb` and add the required ALB annotations on the Ingress resource. The application chart remains the same; only the class/annotations differ.
* On local clusters, **MetalLB** provides LoadBalancer IPs; in cloud environments, the cloud controller manager does. Using `--wait` during Helm installs helps ensure CRDs and webhooks are ready before applying dependent resources.

---