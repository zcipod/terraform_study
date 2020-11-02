terraform {
  backend "remote" {
    organization = "kubernetes-the-hard-way"

    workspaces {
      name = "gh-actions"
    }
  }

  backend "gcs" {
    bucket  = "tf-state-zcipod"
    prefix  = "terraform/state"
  }
}

data "terraform_remote_state" "gcs-bucket" {
  backend = "gcs"
  config = {
    bucket  = "terraform-state"
    prefix  = "prod"
  }
}

resource "template_file" "template" {
  template = data.terraform_remote_state.gcs-bucket.greeting
}