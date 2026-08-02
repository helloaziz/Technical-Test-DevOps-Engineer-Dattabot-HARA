# infra-test

Infrastructure Engineer Technical Test — LocalStack-based solution.

## tasks

| # | topic | file |
|---|---|---|
| 1 | Linux admin commands | linux-commands.md |
| 2 | Terraform IaC (AWS VPC, EC2, SG) | terraform/ |
| 3 | CI/CD pipeline | .github/workflows/pipeline.yml |
| 4 | ALB 502 incident triage | triage.md |

## running task 2 locally

Requires Docker + LocalStack Pro.

```bash
pip install localstack awscli-local terraform-local
export LOCALSTACK_AUTH_TOKEN=<token>
localstack start -d

awslocal s3 mb s3://tfstate-infra-test --region ap-southeast-1
awslocal dynamodb create-table \
  --table-name tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

cd terraform
tflocal init
tflocal apply -var="my_ip=$(curl -s ifconfig.me)/32" -auto-approve
```

## architecture — task 2

```
ap-southeast-1
└── VPC 172.16.0.0/20
    ├── subnet pub-a (172.16.0.0/22, AZ-a)
    │   └── EC2 t3.micro + 33GB gp3
    ├── subnet pub-b (172.16.4.0/22, AZ-b)
    └── IGW → route table → both subnets
```

## evidence

| # | file | description |
|---|---|---|
| 1 | [screenshots/01-localstack-health.txt](screenshots/01-localstack-health.txt) | LocalStack health endpoint — S3, DynamoDB, EC2 services running |
| 2 | [screenshots/02-tfplan.txt](screenshots/02-tfplan.txt) | `tflocal plan` output — 9 resources to add |
| 3 | [screenshots/03-tfapply.txt](screenshots/03-tfapply.txt) | `tflocal apply` output — apply complete, all resources created |
| 4 | [screenshots/04-describe-vpcs.txt](screenshots/04-describe-vpcs.txt) | `describe-vpcs` — VPC 172.16.0.0/20 confirmed |
| 5 | [screenshots/05-describe-instances.txt](screenshots/05-describe-instances.txt) | `describe-instances` — EC2 t3.micro running in pub-a subnet |
