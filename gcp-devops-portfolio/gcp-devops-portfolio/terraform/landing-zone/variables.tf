variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "billing_account" {
  description = "Billing account ID linked to the organization"
  type        = string
}

variable "project_id" {
  description = "Project ID for the landing zone host project"
  type        = string
}

variable "region" {
  description = "Default region for regional resources"
  type        = string
  default     = "asia-south1"
}

variable "admin_group_email" {
  description = "Google Group used for org-level admin IAM binding"
  type        = string
}

variable "allowed_domains" {
  description = "Domains allowed to be added as IAM principals (org policy constraint)"
  type        = list(string)
}
