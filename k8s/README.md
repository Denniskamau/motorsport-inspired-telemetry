# Kubernetes Manifests

Kubernetes configuration for deploying F1 telemetry platform components to EKS.

## Directory Structure

```
k8s/
├── ingestion-service/
│   ├── deployment.yaml     # Deployment and Service
│   ├── hpa.yaml           # HorizontalPodAutoscaler
│   ├── pdb.yaml           # PodDisruptionBudget
│   └── ingress.yaml       # ALB Ingress
├── edge-simulator/
│   └── deployment.yaml    # Edge simulator deployment
└── grafana/
    └── ...               # Grafana dashboards
```

## Prerequisites

1. EKS cluster deployed via Terraform
2. kubectl configured with cluster access
3. AWS Load Balancer Controller installed
4. Metrics Server installed

## Setup

### 1. Install AWS Load Balancer Controller

```bash
# Add Helm repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=f1-telemetry-dev \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 2. Install Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### 3. Build and Push Docker Images

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Create ECR repositories
aws ecr create-repository --repository-name f1-ingestion-service --region us-east-1
aws ecr create-repository --repository-name f1-edge-simulator --region us-east-1

# Build and push ingestion service
cd ingestion-service
docker build -t f1-ingestion-service:latest .
docker tag f1-ingestion-service:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/f1-ingestion-service:latest
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/f1-ingestion-service:latest

# Build and push edge simulator
cd ../edge-simulator
docker build -t f1-edge-simulator:latest .
docker tag f1-edge-simulator:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/f1-edge-simulator:latest
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/f1-edge-simulator:latest
```

### 4. Update Manifests

Before deploying, replace placeholders in the manifests:

- `<AWS_ACCOUNT_ID>`: Your AWS account ID
- `<AWS_REGION>`: Your AWS region (e.g., us-east-1)
- `<ENVIRONMENT>`: Your environment (dev/prod)

You can use `sed` or manually edit the files:

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1
export ENVIRONMENT=dev

# Update ingestion service manifests
sed -i "s/<AWS_ACCOUNT_ID>/$AWS_ACCOUNT_ID/g" k8s/ingestion-service/*.yaml
sed -i "s/<AWS_REGION>/$AWS_REGION/g" k8s/ingestion-service/*.yaml
sed -i "s/<ENVIRONMENT>/$ENVIRONMENT/g" k8s/ingestion-service/*.yaml

# Update edge simulator manifests
sed -i "s/<AWS_ACCOUNT_ID>/$AWS_ACCOUNT_ID/g" k8s/edge-simulator/*.yaml
sed -i "s/<AWS_REGION>/$AWS_REGION/g" k8s/edge-simulator/*.yaml
```

### 5. Deploy Applications

```bash
# Deploy ingestion service
kubectl apply -f k8s/ingestion-service/

# Deploy edge simulator (choose one)
kubectl apply -f k8s/edge-simulator/deployment.yaml

# Verify deployments
kubectl get pods
kubectl get svc
kubectl get ingress
```

## Components

### Ingestion Service

**Deployment Features:**
- 2 replica pods (minimum)
- Resource requests and limits
- Liveness and readiness probes
- ServiceAccount with IRSA annotation
- ConfigMap for environment configuration

**HorizontalPodAutoscaler:**
- Scales based on CPU (70%) and Memory (80%)
- Min 2, Max 10 replicas
- Conservative scale-down, aggressive scale-up

**PodDisruptionBudget:**
- Ensures at least 1 pod is always available
- Protects against voluntary disruptions

**Ingress:**
- AWS ALB (Application Load Balancer)
- Internet-facing with health checks
- Automatic DNS provisioning

### Edge Simulator

Two deployment options:

**Option 1: Deployment** (Standard)
- Single replica for testing
- Simulates one edge device

**Option 2: DaemonSet** (Production-like)
- Runs one pod per node
- Simulates multiple edge locations
- More realistic race weekend scenario

## Race Weekend Mode

During race weekends, follow this workflow:

### Pre-Race (Infrastructure Freeze)

```bash
# Scale up ingestion service
kubectl scale deployment ingestion-service --replicas=5

# Verify all pods are ready
kubectl get pods -l app=ingestion-service

# Check HPA metrics
kubectl get hpa

# Disable HPA to prevent auto-scaling during race
kubectl patch hpa ingestion-service-hpa -p '{"spec":{"minReplicas":5,"maxReplicas":5}}'
```

### During Race (Monitoring)

```bash
# Monitor pod status
watch kubectl get pods

# Check logs
kubectl logs -f deployment/ingestion-service

# Monitor metrics
kubectl top pods

# Check ingress
kubectl describe ingress ingestion-service
```

### Post-Race (Scale Down)

```bash
# Re-enable HPA
kubectl patch hpa ingestion-service-hpa -p '{"spec":{"minReplicas":2,"maxReplicas":10}}'

# Scale down edge simulator if needed
kubectl scale deployment edge-simulator --replicas=1
```

## Monitoring

### Check Application Health

```bash
# Ingestion service health
kubectl port-forward svc/ingestion-service 8000:80
curl http://localhost:8000/health

# Metrics
curl http://localhost:8000/metrics
```

### Check Logs

```bash
# All ingestion service logs
kubectl logs -l app=ingestion-service

# Follow logs
kubectl logs -f deployment/ingestion-service

# Edge simulator logs
kubectl logs -l app=edge-simulator
```

### Resource Usage

```bash
# Pod resources
kubectl top pods

# Node resources
kubectl top nodes

# HPA status
kubectl get hpa -w
```

## Troubleshooting

### Pods Not Starting

```bash
# Describe pod
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check service account
kubectl get sa ingestion-service -o yaml
```

### IRSA Issues

```bash
# Verify ServiceAccount annotation
kubectl get sa ingestion-service -o jsonpath='{.metadata.annotations}'

# Check IAM role trust policy
aws iam get-role --role-name f1-telemetry-dev-ingestion-service

# Test S3 access from pod
kubectl exec -it <pod-name> -- aws s3 ls
```

### Ingress Not Working

```bash
# Check ALB creation
kubectl describe ingress ingestion-service

# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify security groups
aws ec2 describe-security-groups --filters "Name=tag:kubernetes.io/cluster/f1-telemetry-dev,Values=owned"
```

### HPA Not Scaling

```bash
# Check metrics server
kubectl get apiservice v1beta1.metrics.k8s.io

# Verify metrics
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods

# Check HPA conditions
kubectl describe hpa ingestion-service-hpa
```

## Security Best Practices

1. **IRSA**: No static AWS credentials in pods
2. **Resource Limits**: All pods have resource limits
3. **PDB**: Ensures availability during disruptions
4. **Network Policies**: (Optional) Add network policies for pod-to-pod communication
5. **Pod Security Standards**: (Optional) Enforce pod security standards

## Performance Tuning

### For High Throughput

```yaml
# Increase replicas
spec:
  replicas: 10

# Increase resources
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

### For Cost Optimization

```yaml
# Use spot instances with node affinity
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: eks.amazonaws.com/capacityType
            operator: In
            values:
            - SPOT
```
