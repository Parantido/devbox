## Mydly Terraform

Variables and Outputs 
- Input Variables
- Local Values
- Output Values

Terraform Data Types
- Primiive (String, Number, Boolean)
- Collection (List, Set, Map)
- Structural (Tuple, Object)


## AWS Resources

### Basic Terraforming

```console
- ✅ Store Terraform State in S3
- ✅ Acquire Terraform State Lock to a DynamoDB Table
- ✅ VPC
- ✅ Internet Gateway
- ✅ Network Subnets
- ✅ Outbound NAT Gateway
- ✅ Network Routes
- ✅ EKS
- ✅ Nodes & Node Pools
- ✅ IAM (OiDC) EKS Roles
- ✅ ECR
- ✅ IAM (OiDC) ECR Roles (Pull)
- ❌ Route53
- ✅ Network Load Balancer
- ✅ NGINX Ingress Controller
- ✅ Parametrized Ingress Services
- ✅ Cert Manager Integration
- ✅ Let's Encrypt Cert Retrieval
- ❌ Store Certificates to ACM 
- ✅ Parametrize everything
- ✅ RDS
```

## HOW TO USE

N.B.: first time both bucket and, if needed to track locking state, dynamodb table must be created or terraform will fail with the error reported below:

```
Initializing the backend...
Error loading state: NoSuchBucket: The specified bucket does not exist
        status code: 404, request id: 542A0B8F18D21884, host id: glZaVv4mnpq2t3lo7toVrSHxsCCBqykk7f4Wp6zhu8GxeTZgsfsJdGd+dykNH0TexNVYosOgO78=
```

```console
$ cd terraform
$ aws configure

$ terraform init
$ terraform plan
$ terraform apply

$ terraform state list 
$ terraform state show -- 
$ terraform show
```

Updating local kube config

```console
$ aws eks update-kubeconfig --region <deployment region> --name <eks cluster name>
```


#### Infrastructure Lifecycle
- Reliability 
- Manageability 
- Accountability

#### Terraform Lifecycle
- code, init, plan, validate, apply, destroy
