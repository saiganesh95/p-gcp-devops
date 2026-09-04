terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
  }

  backend "gcs" {
    bucket = "REPLACE_WITH_TF_STATE_BUCKET"
    prefix = "landing-zone/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
