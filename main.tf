terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "google" {
  version = "3.5.0"

  credentials = file("Kube-terraform-2f633e51bc7c.json")

  project = var.PROJECT_ID
  region  = var.REGION
  zone    = var.ZONE
}



