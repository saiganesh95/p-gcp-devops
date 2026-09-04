# GCP Cloud/DevOps Engineer — Portfolio


This repo contains sanitized, working examples of GCP infrastructure and
CI/CD work. Client names/IPs/secrets are removed or replaced with
placeholders — the patterns and code are real.

## Contents

| Folder | What it shows |
|---|---|
| [`terraform/landing-zone`](terraform/landing-zone) | GCP org policy, IAM baseline, hub VPC, Cloud DNS |
| [`terraform/hybrid-vpn`](terraform/hybrid-vpn) | HA VPN + Classic VPN, on-prem↔GCP tunnels |
| [`terraform/gke-cluster`](terraform/gke-cluster) | Private GKE cluster with Workload Identity |
| [`cicd/cloud-functions-gen2-pipeline`](cicd/cloud-functions-gen2-pipeline) | Cloud Build pipeline deploying Cloud Functions from a config-driven `deploy.py` |
| [`scripts/gcs-dual-region-migration`](scripts/gcs-dual-region-migration) | Zero-data-loss single-region → dual-region GCS bucket migration via Storage Transfer Service |
| [`scripts/dms-migration`](scripts/dms-migration) | Database Migration Service setup for AWS → Cloud SQL, with cutover checklist |
| [`.github/workflows`](.github/workflows) | GitHub Actions mirror of the Cloud Build pipeline (for portfolio visibility) |

## Core skills demonstrated
GKE · Compute Engine · Cloud Storage · Cloud Functions · Cloud Build ·
Terraform · HA/Classic VPN · VPC Peering · Cloud NAT · Private Service
Connect · Cloud DNS · VLAN Interconnect · IAM & Org Policy · Cloud Identity
SSO · Storage Transfer Service · Database Migration Service · CMEK/KMS

## Certifications
- Google Cloud Certified: Professional Cloud DevOps Engineer
