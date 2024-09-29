terraform {
    backend "s3" {
      bucket = "tech-challenge-tf"
      key = "fiap/terraform.tfstate"
      region = "us-east-1"
    }
}