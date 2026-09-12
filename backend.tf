terraform {
  backend "s3" {
    bucket         = "wellnesshub-terraform-state"
    key            = "wellnesshub/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "wellnesshub-terraform-lock"
    encrypt        = true
  }
}