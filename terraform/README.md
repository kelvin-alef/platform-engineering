# Terraform Infrastructure Modules

This directory contains the Infrastructure as Code (IaC) configuration for the Platform, structured using standard software engineering principles for reusability, testing, and security.

---

## Directory Structure

* **`modules/networking`**: A reusable module provisioning a secure VPC layout including public and private subnets, routing tables, and a cost-optimized, configurable NAT Gateway.
* **`modules/ecs-fargate-service`**: A reusable module for deploying containerized applications onto AWS ECS Fargate. It incorporates least-privilege IAM roles, security groups, auto-scaling policy configurations, logging group setups, and tags governance.
* **`environments/dev`**: Standard dev environment orchestration, referencing the networking and ECS service submodules.
* **`tests`**: Integration tests written in the native **Terraform 1.6+ testing framework**.

---

## Key Patterns Enforced

### 1. Configuration Synchronization (Problem 2)
The ECS module automatically writes its critical output values (Cluster Name, Service Name, Security Group ID) directly to the **AWS SSM Parameter Store**:
* `/{environment}/{project_name}/ecs_cluster_name`
* `/{environment}/{project_name}/ecs_service_name`
* `/{environment}/{project_name}/ecs_security_group_id`

This establishes a decoupled reference mechanism. Other modules (e.g., databases, API gateways) or application deployment pipelines can look up these parameters dynamically instead of hardcoding resource references.

### 2. Least Privilege IAM Architecture (Problem 3)
The module separates roles:
* **Task Execution Role:** Used by the AWS ECS agent. Granted access to decrypt specified AWS Secrets Manager secrets or fetch AWS SSM parameters, and publish logs.
* **Task Role:** Assigned to the application running inside the container. It contains zero permissions by default and is meant to be extended per-application.

---

## Verifying Configurations Locally

### 1. Style & Linting
Validate formatting and structure:
```bash
terraform fmt -recursive
```

### 2. Validation
Check syntactical validity of the dev configuration:
```bash
cd environments/dev
terraform init
terraform validate
```

### 3. Execution Tests (Terraform Native Testing)
We use the native `terraform test` command to run static plan-assertion unit tests defined in `tests/service.tftest.hcl`. This does not spin up real AWS resources:
```bash
# Run tests from this directory
terraform test
```
