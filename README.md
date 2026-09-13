
## ⚙️ Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.x
- Un compte AWS avec les credentials configurés (`aws configure`)
- Un bucket S3 existant pour le backend Terraform (voir `backend.tf`)
- Une clé API OpenAI (pour le module `monitoring_ai`)

## 🚀 Utilisation

```bash
cp terraform.tfvars.example terraform.tfvars
# Renseigne tes propres valeurs dans terraform.tfvars

terraform init
terraform plan
terraform apply
```

## 📝 Variables principales

| Variable | Description | Sensible | Valeur par défaut |
|---|---|---|---|
| `aws_region` | Région AWS utilisée pour toutes les ressources | Non | `us-east-1` |
| `project_name` | Nom du projet, utilisé pour le nommage des ressources | Non | `wellnesshub` |
| `environment` | Environnement de déploiement | Non | `prod` |
| `db_password` | Mot de passe maître de la base de données | **Oui** | — (à fournir) |
| `openai_api_key` | Clé API OpenAI pour le diagnostic IA (module `monitoring_ai`) | **Oui** | — (à fournir) |
| `alarm_email` | Adresse email pour les alarmes CloudWatch / notifications SNS | Non | — (à fournir) |

⚠️ Les variables marquées **sensibles** ne doivent jamais être codées en dur. Fournissez-les via `terraform.tfvars` (non versionné) ou un gestionnaire de secrets (AWS Secrets Manager, SSM Parameter Store).

## 📚 Contexte du projet

Ce repo fait partie d'un ensemble de projets réalisés dans le cadre d'un PFE (Cloud Computing & DevOps) :

- `aws-infra-terraform` — ce repo (Infrastructure as Code)
- `k8s-manifests` — orchestration Kubernetes (environnement de validation)
- `ci-cd` — pipeline CI/CD Jenkins (build, scan, déploiement)

## ⚠️ Note sécurité

Aucune valeur sensible (mots de passe, clés API, endpoints réels, IDs de compte AWS) n'est incluse dans ce repo. Utilisez votre propre fichier `terraform.tfvars` (non versionné, voir `.gitignore`) basé sur `terraform.tfvars.example`.
