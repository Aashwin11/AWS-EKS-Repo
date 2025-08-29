# Project: AWS EKS Cluster with Terraform

**Provisioning and Managing an Amazon EKS Cluster using Terraform**

---

> **NOTE:**  
> Please **fork this repository** for your own use.  
> Make sure you have **AWS credentials configured** in your CLI (`aws configure`) or in your environment variables before running Terraform.  
> The cluster is provisioned with **private worker nodes** for security, while public subnets are used only for NAT Gateway and Load Balancers.

---

## Overview

This project provisions an **Amazon Elastic Kubernetes Service (EKS) cluster** using **Terraform**.  
It sets up all required AWS infrastructure components, including:

- **VPC, Subnets (public + private), NAT Gateway, Internet Gateway, Route Tables**
- **IAM Roles and Policies** for EKS Control Plane and Worker Nodes
- **EKS Cluster & Managed Node Group** (EC2 instances as worker nodes)
- **Networking configuration** so pods get IPs from the VPC (via CNI plugin)

Once created, you can easily connect to the cluster using `kubectl` and deploy your workloads.

---

## ⚠️NAT GATEWAY USAGE concept [Please refer to the below content]
## Architecture

- **VPC Setup**

  - 2 Public Subnets → for NAT Gateway + Load Balancers
  - 2 Private Subnets → for Worker Nodes & Pods
  - Internet Gateway, NAT Gateway, and Route Tables

- **EKS Cluster**

  - Control Plane managed by AWS
  - API Server:
    - **Public Access:** Enabled (can connect from your laptop)
    - **Private Access:** Disabled (for this setup)

- **EKS Node Group**

  - Worker Nodes (EC2 instances) in **private subnets**
  - On-Demand `t2.medium` instances (configurable)
  - Autoscaling between **1–5 nodes**

- **IAM Roles**
  - Control Plane Role (to manage the cluster)
  - Worker Node Role (with EKS, CNI, and ECR policies)

---

## Repository Structure

.
├── main.tf # Main Terraform configuration
├── variables.tf # Input variables
├── outputs.tf # Terraform outputs
├── vpc.tf # VPC, subnets, route tables, gateways
├── eks-cluster.tf # EKS cluster resource
├── eks-node-group.tf # Managed node group resource
├── iam.tf # IAM roles and policy attachments
├── provider.tf # AWS provider config
└── README.md # Project documentation

## Steps to Deploy

1. Initialize Terraform

Initialize the working directory containing your Terraform configuration:

```bash
terraform init
```

2. Validate the Code

Check whether the Terraform configuration is syntactically valid:

```bash
terraform validate
```

3. See the Execution Plan

Preview the changes Terraform will make before applying them:

```bash
terraform plan
```

4. Apply the Infrastructure

Apply the configuration and create the infrastructure:

```bash
terraform apply -auto-approve
```

This will create the full VPC, EKS cluster, IAM roles, and node group.

5. Update kubeconfig

Configure your local kubeconfig to connect with the newly created EKS cluster:

```bash
aws eks update-kubeconfig --region <aws-region> --name <eks-cluster-name>
```

Example:

```bash
aws eks update-kubeconfig --region us-east-2 --name staging-eks-demo
```

6. Verify Connection

Confirm that your Kubernetes cluster is accessible and the worker nodes are ready:

```bash
kubectl get nodes
```

You should see the worker nodes listed as Ready.

7. Cleanup

To destroy all resources created by Terraform and avoid ongoing costs:

```bash
terraform destroy -auto-approve
```

## NAT GATEWAY USAGE:

### Worker Nodes are in Private Subnets
Following security best practices, this configuration deploys all EKS worker nodes into private subnets (private_zone_1 and private_zone_2). As a result, these nodes are not assigned public IP addresses and are isolated from direct inbound traffic from the internet, which is crucial for protecting your workloads.

### The Critical Role of the NAT Gateway
While secure, nodes in a private subnet are completely cut off from the internet. This presents a problem during their initial creation, as they must perform a "bootstrap" process. A brand new EC2 instance needs to connect to the EKS control plane's public API endpoint to receive instructions, download necessary components (like the VPC CNI plugin), and officially register itself as a part of the cluster.

Without a path to the internet, this registration fails. This is where the NAT Gateway is essential. By placing the NAT Gateway in a public subnet (public_zone_1) and creating a route for all outbound traffic (0.0.0.0/0) from the private subnets to it, we create a secure, one-way bridge. The private nodes can now initiate outbound connections to the EKS API and public container registries, but the internet cannot initiate connections back to them.

### kubectl and Node Registration
The kubectl get nodes command works by communicating with the EKS control plane's API, not by connecting directly to the worker nodes. The control plane maintains a list of all nodes that have successfully registered with it. If a node cannot complete its registration because it has no internet path, the control plane will never know it exists, and it will not appear in the kubectl output.

When you run kubectl get nodes, the name you see is often the Private IP DNS name of the EC2 instance. This is because all communication between the control plane and the nodes happens over your private VPC network. The NAT Gateway's only job is to enable that initial registration and allow for outbound tasks like pulling public images.

### The Public Subnet Alternative
As you noted, if we were to place the worker nodes in the public subnets, they would each receive a public IP address and could connect to the internet directly via the Internet Gateway. In that scenario, a NAT Gateway would not be required. However, this configuration is less secure as it exposes every worker node directly to the public internet.
