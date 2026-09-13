# WellnessHub — Infrastructure AWS avec Terraform

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=flat&logo=amazon-aws&logoColor=white)
![OpenAI](https://img.shields.io/badge/OpenAI_GPT--4o-412991?style=flat&logo=openai&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)

> Infrastructure Cloud AWS provisionnée en **Infrastructure as Code** avec Terraform pour l'application **WellnessHub** — plateforme de bien-être au travail (workplace wellness).

---

## Architecture AWS provisionnée

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS us-east-1                            │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    module/network                        │   │
│  │  VPC + Subnets publics/privés + Route Tables            │   │
│  │  Security Groups + NACLs + Internet Gateway             │   │
│  └──────────────────────────┬──────────────────────────────┘   │
│                             │                                    │
│         ┌───────────────────┼───────────────────┐              │
│         ▼                   ▼                   ▼              │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────────────┐   │
│  │ module/alb  │   │module/compute│   │ module/database  │   │
│  │             │   │              │   │                  │   │
│  │ Application │   │ EC2 Instance │   │ RDS PostgreSQL   │   │
│  │ Load        │   │ Docker       │   │ (Multi-AZ)       │   │
│  │ Balancer    │   │ Compose      │   │                  │   │
│  └─────────────┘   └──────────────┘   └──────────────────┘   │
│                                                                  │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────────────┐   │
│  │module/      │   │module/       │   │ module/          │   │
│  │registry     │   │security      │   │ monitoring       │   │
│  │             │   │              │   │                  │   │
│  │ ECR         │   │ IAM Roles    │   │ CloudWatch       │   │
│  │ (images     │   │ & Policies   │   │ Logs, Metrics    │   │
│  │  Docker)    │   │ SSM Param    │   │ Alarms + SNS     │   │
│  └─────────────┘   └──────────────┘   └──────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  module/monitoring_ai                    │   │
│  │                                                          │   │
│  │  Lambda Function (Python)                                │   │
│  │  ┌────────────────────────────────────────────────┐    │   │
│  │  │ CloudWatch Alarm → SNS → Lambda                │    │   │
│  │  │                    ↓                            │    │   │
│  │  │            OpenAI GPT-4o-mini                  │    │   │
│  │  │                    ↓                            │    │   │
│  │  │      Diagnostic IA → Email notification        │    │   │
│  │  └────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Structure du projet

```
aws-infra-terraform/
│
├── main.tf                     ← Orchestration des modules
├── variables.tf                ← Déclaration des variables
├── outputs.tf                  ← Outputs (IPs, ARNs, endpoints)
├── providers.tf                ← Provider AWS + version Terraform
├── backend.tf                  ← State S3 + DynamoDB lock
├── terraform.tfvars.example    ← Template variables (sans secrets)
├── .terraform.lock.hcl         ← Lock des providers
├── .gitignore
├── README.md
│
└── modules/
    ├── alb/                    ← Application Load Balancer
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── compute/                ← EC2 + User Data (docker-compose)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── database/               ← RDS PostgreSQL managé
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── monitoring/             ← CloudWatch Logs, Métriques, Alarmes, SNS
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── monitoring_ai/          ← Diagnostic IA via Lambda + GPT-4o-mini
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── lambda/             ← Code Python de la Lambda
    │       ├── main.tf
    │       ├── variables.tf
    │       └── outputs.tf
    │
    ├── network/                ← VPC, Subnets, SG, NACLs, IGW
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── registry/               ← AWS ECR (images Docker)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── security/               ← IAM Roles, Policies, SSM Parameter Store
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Modules — Description détaillée

### `modules/network` — Réseau

| Ressource | Description |
|-----------|-------------|
| VPC | Virtual Private Cloud dédié WellnessHub |
| Subnets publics | EC2, ALB — accessibles depuis Internet |
| Subnets privés | RDS — isolés du trafic Internet |
| Internet Gateway | Accès Internet pour les subnets publics |
| Route Tables | Routage public/privé séparé |
| Security Groups | Règles firewall par service |
| NACLs | Contrôle d'accès réseau au niveau subnet |

### `modules/compute` — Calcul

| Ressource | Description |
|-----------|-------------|
| EC2 Instance | Hébergement de l'application containerisée |
| User Data | Script de démarrage (installation Docker + docker-compose up) |
| Key Pair | Accès SSH sécurisé |
| IAM Instance Profile | Permissions EC2 → ECR, SSM, CloudWatch |

### `modules/database` — Base de données

| Ressource | Description |
|-----------|-------------|
| RDS PostgreSQL | Base de données managée, chiffrée |
| Parameter Group | Configuration PostgreSQL optimisée |
| Subnet Group | Déploiement en subnets privés |
| Credentials | Stockés dans AWS SSM Parameter Store |

### `modules/registry` — Registry Docker

| Ressource | Description |
|-----------|-------------|
| ECR Repositories | Registry privée pour eureka, gateway, expertms, front |
| Lifecycle Policy | Nettoyage automatique des anciennes images |
| Repository Policy | Accès restreint au compte AWS |

### `modules/security` — Sécurité

| Ressource | Description |
|-----------|-------------|
| IAM Role EC2 | Permissions minimales (principe du moindre privilège) |
| IAM Policy | ECR pull, SSM read, CloudWatch write |
| SSM Parameters | Stockage sécurisé DB endpoint, username, password |
| Secrets Manager | Secrets applicatifs (JWT, API keys) |

### `modules/monitoring` — Supervision

| Ressource | Description |
|-----------|-------------|
| CloudWatch Log Groups | Logs centralisés par service (/wellnesshub/application) |
| CloudWatch Metrics | CPU, mémoire, réseau EC2 + RDS |
| CloudWatch Alarms | Seuils d'alerte configurables |
| SNS Topic | Notifications d'alarmes |
| Dashboard | Visualisation temps réel |

### `modules/monitoring_ai` — Diagnostic IA ✨

Module innovant combinant **CloudWatch** et **OpenAI GPT-4o-mini** pour un diagnostic automatique des incidents :

```
CloudWatch Alarm déclenché
        ↓
SNS Topic → Lambda Function (Python)
        ↓
Récupération des logs CloudWatch
        ↓
Analyse GPT-4o-mini
        ↓
Rapport structuré :
  🔴 Cause racine
  🔍 Analyse détaillée
  ✅ Actions correctives
  ⚡ Niveau de criticité
  💡 Conseil préventif
        ↓
Email de notification enrichi
```

---

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- AWS CLI configuré (`aws configure`)
- Un bucket S3 existant pour le backend Terraform (voir `backend.tf`)
- Une clé API OpenAI (pour `monitoring_ai`)
- Docker + docker-compose (sur l'EC2, installé via User Data)

---

## Utilisation

### 1. Cloner et configurer

```bash
git clone https://github.com/belkhirianourelimen/aws-infra-terraform.git
cd aws-infra-terraform

# Copier le template des variables
cp terraform.tfvars.example terraform.tfvars

# Remplir terraform.tfvars avec vos propres valeurs
nano terraform.tfvars
```

### 2. Initialiser Terraform

```bash
terraform init
```

### 3. Vérifier le plan

```bash
terraform plan
```

### 4. Déployer l'infrastructure

```bash
terraform apply
```

### 5. Détruire l'infrastructure

```bash
terraform destroy
```

---

## Variables principales

| Variable | Description | Sensible | Défaut |
|----------|-------------|----------|--------|
| `aws_region` | Région AWS | Non | `us-east-1` |
| `project_name` | Nom du projet | Non | `wellnesshub` |
| `environment` | Environnement | Non | `prod` |
| `db_password` | Mot de passe RDS | **Oui** | — |
| `openai_api_key` | Clé API OpenAI | **Oui** | — |
| `alarm_email` | Email notifications SNS | Non | — |

> ⚠️ Les variables **sensibles** ne doivent jamais être codées en dur.
> Fournissez-les via `terraform.tfvars` (non versionné) ou AWS Secrets Manager / SSM Parameter Store.

---

## Backend Terraform

Le state Terraform est stocké de façon sécurisée sur AWS :

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "YOUR_S3_BUCKET_NAME"
    key            = "wellnesshub/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

| Ressource | Rôle |
|-----------|------|
| S3 Bucket | Stockage du fichier `terraform.tfstate` |
| DynamoDB Table | Verrouillage du state (évite les conflits concurrents) |
| Chiffrement S3 | State chiffré au repos |

---

## Sécurité

```
✅ Aucune valeur sensible dans le repo (passwords, clés API, IDs)
✅ terraform.tfvars exclu via .gitignore
✅ terraform.tfvars.example fourni comme template
✅ Secrets DB stockés dans AWS SSM Parameter Store
✅ IAM selon le principe du moindre privilège
✅ RDS en subnet privé (non exposé à Internet)
✅ State Terraform chiffré sur S3
```

---

## Liens utiles

- 📦 [k8s-manifests](https://github.com/belkhirianourelimen/k8s-manifests) — Orchestration Kubernetes
- 🔄 [ci-cd](https://github.com/belkhirianourelimen/ci-cd.git) — Pipelines Jenkins CI/CD

---

*Nour El Imen Belkhiria — 2026*
