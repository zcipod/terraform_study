terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
  backend "gcs" {
    bucket  = "kubernetes-study"
    prefix  = "terraform/state"
    access_token = "Ex6w9t+riJE38ha7Tuf0plUr+JOmU3Au6d7M78xY"
  }
}

provider "google" {
  version = "3.5.0"

//  credentials = file("Kube-terraform-2f633e51bc7c.json")

  project = var.PROJECT_ID
  region  = var.REGION
  zone    = var.ZONE
}




