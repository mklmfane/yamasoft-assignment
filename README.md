# DevOps Exercises

Please pick just **2** of the exercises below and complete them. Once you have completed your submission, place it in a GitHub repo that you share. We will schedule a time to review your solution with you after we have had a chance to review it internally.

---

## AWS VPC Exercise

You have been assigned a project to create a new Terraform module for creating a **staging VPC** in AWS. Requirements:

* The network supernet of **172.16.0.0/16**.
* The VPC should provide an **internal endpoint for AWS Systems Manager (SSM)**.
* The VPC should provide an **internal endpoint for S3**.
* The VPC should have **two different availability zones**, with **two private subnets** and **two public subnets** for each availability zone.
* The VPC should contain **appropriate routing tables**.
* The VPC should include **appropriate NAT gateways** and an **internet gateway**.

Create module code to fulfill this request utilizing **Terragrunt/Terraform**. Show how you would use this module code to bring up the given architecture.

---

## A Small EC2 App

Using the following technologies: **Packer**, **Ansible**, **Terraform/Terragrunt**.

* Using a **pack/fry idiom** in Ansible, create an **AMI** which runs a small **NGINX** webserver (a static page is fine). Base it on the latest **Amazon Linux 2023** AMI. Ensure there are both **pack** and **fry** roles and that variables needed for the AMI are injectable via **user data** in the frying role (if applicable).
* Create a Terraform stack which creates:

  * An **Auto Scaling Group of two EC2 instances**.
  * A **Launch Template**.
  * An **instance profile role** with a manageable policy attached to the EC2 instances.
* An **Application Load Balancer (ALB)**.
* A **Target Group** for the EC2 instances.
* **Security groups** for the ALB and EC2 instances with proper rules to ensure **SSH access** and **communication** between instances and the load balancer.
* Place the Auto Scaling Group on a **private subnet**.
* **Bonus**: Add TLS via an SSL cert through **AWS Certificate Manager (ACM)** (optional).

References:

* [https://developer.hashicorp.com/packer](https://developer.hashicorp.com/packer)
* [https://github.com/ansible](https://github.com/ansible)

---

## Deploying an Application

### Helm

* Create a simple **templated Helm chart** that deploys an **NGINX** server and an appropriate **Ingress** (assume either an NGINX or ALB controller).
* Create a **values.yml** that fulfills the chart’s values.
* Show a **command that dumps the rendered templates**.

### GitHub Actions

* Create an example **GitHub Action** that uses **GitHub’s OpenID Connect (OIDC)** provider as a **trusted AWS identity** to deploy the above Helm chart into a **staging EKS cluster**.
