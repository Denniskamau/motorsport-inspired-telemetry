# Terraform Infrastructure

Infrastructure as Code for F1 Telemetry Platform using Terraform.

## Architecture

The infrastructure consists of the following components:

- **VPC Module**: Private VPC with public/private subnets across 3 AZs, NAT Gateways, and VPC Flow Logs
- **EKS Module**: Managed Kubernetes cluster with node groups, OIDC provider for IRSA, and essential add-ons
- **S3 Module**: Three S3 buckets (raw telemetry, processed telemetry, Athena results) with lifecycle policies
- **IAM Module**: IRSA roles for service accounts, Glue and Athena roles with least-privilege access

## Prerequisites

- Terraform >= 1.6.0
- AWS CLI configured with appropriate credentials
- kubectl (for EKS cluster access)

## Directory Structure

```
terraform/
├── main.tf                 # Root module
├── variables.tf           # Input variables
├── outputs.tf            # Output values
├── modules/              # Reusable modules
│   ├── vpc/             # VPC infrastructure
│   ├── eks/             # EKS cluster
│   ├── s3/              # S3 buckets
│   └── iam/             # IAM roles and policies
└── environments/        # Environment-specific configs
    ├── dev/
    │   └── terraform.tfvars
    └── prod/
        └── terraform.tfvars
```

## Usage

### Initial Setup

1. **Configure Backend** (Optional but recommended):

Edit the backend configuration in [main.tf](main.tf):

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

2. **Initialize Terraform**:

```bash
cd terraform
terraform init
```

### Deploy Development Environment

```bash
# Plan
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply
terraform apply -var-file=environments/dev/terraform.tfvars
```

### Deploy Production Environment

```bash
# Plan
terraform plan -var-file=environments/prod/terraform.tfvars

# Apply
terraform apply -var-file=environments/prod/terraform.tfvars
```

### Configure kubectl

After deployment, configure kubectl to access the EKS cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name f1-telemetry-dev
```

## Outputs

Important outputs after deployment:

- `eks_cluster_name`: EKS cluster name
- `eks_cluster_endpoint`: EKS API endpoint
- `s3_raw_telemetry_bucket`: S3 bucket for raw data
- `s3_processed_telemetry_bucket`: S3 bucket for processed data
- `ingestion_service_role_arn`: IAM role ARN for ingestion service (IRSA)

View outputs:

```bash
terraform output
```

## Security Features

### Network Security
- Private subnets for EKS nodes
- NAT Gateways for outbound traffic
- Security groups with least-privilege rules
- VPC Flow Logs enabled

### IAM Security
- IRSA (IAM Roles for Service Accounts) - no static credentials
- Least-privilege IAM policies
- Separation of concerns (different roles for different services)

### Data Security
- S3 bucket encryption at rest (AES256)
- S3 versioning enabled
- Public access blocked on all buckets
- Lifecycle policies for cost optimization

## Cost Optimization

- **Development**: Uses t3.medium instances, minimal node count
- **Production**: Uses t3.large instances, auto-scaling enabled
- **S3 Lifecycle**: Automatic transition to IA and Glacier
- **Athena Results**: Auto-deletion after 7 days

## Terraform State Management

Best practices for state management:

1. Store state in S3 with encryption
2. Use DynamoDB for state locking
3. Never commit state files to git
4. Use workspaces for multiple environments (alternative approach)

## Clean Up

To destroy all resources:

```bash
# Development
terraform destroy -var-file=environments/dev/terraform.tfvars

# Production (use with caution!)
terraform destroy -var-file=environments/prod/terraform.tfvars
```

## Troubleshooting

### EKS Access Issues

```bash
# Verify IAM identity
aws sts get-caller-identity

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name f1-telemetry-dev

# Test access
kubectl get nodes
```

### IRSA Issues

Verify OIDC provider is created:

```bash
aws eks describe-cluster --name f1-telemetry-dev --query "cluster.identity.oidc.issuer"
```

## Module Documentation

### VPC Module
- Creates VPC with configurable CIDR
- Public and private subnets across 3 AZs
- Internet Gateway and NAT Gateways
- Route tables and associations
- VPC Flow Logs to CloudWatch

### EKS Module
- Managed Kubernetes cluster
- Node groups with auto-scaling
- OIDC provider for IRSA
- Essential add-ons (vpc-cni, coredns, kube-proxy)
- CloudWatch logging enabled

### S3 Module
- Raw telemetry bucket with partitioning
- Processed telemetry bucket
- Athena results bucket
- Encryption, versioning, lifecycle policies

### IAM Module
- IRSA role for ingestion service
- Glue service role
- Athena service role
- Least-privilege policies
