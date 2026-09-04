# --- Baseline IAM: admin group + custom least-privilege role -----------

resource "google_organization_iam_member" "org_admins" {
  org_id = var.org_id
  role   = "roles/resourcemanager.organizationAdmin"
  member = "group:${var.admin_group_email}"
}

resource "google_organization_iam_member" "billing_admin" {
  org_id = var.org_id
  role   = "roles/billing.admin"
  member = "group:${var.admin_group_email}"
}

# Custom role used instead of broad Editor/Owner grants on workload projects
resource "google_organization_iam_custom_role" "cloud_engineer" {
  org_id      = var.org_id
  role_id     = "cloudEngineerRestricted"
  title       = "Cloud Engineer (Restricted)"
  description = "Deploy/operate compute, storage, networking without IAM or billing changes"

  permissions = [
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.update",
    "storage.buckets.create",
    "storage.buckets.get",
    "storage.objects.create",
    "storage.objects.get",
    "cloudfunctions.functions.create",
    "cloudfunctions.functions.get",
    "cloudfunctions.functions.update",
    "cloudscheduler.jobs.create",
    "cloudscheduler.jobs.update",
    "cloudbuild.builds.create",
    "cloudbuild.builds.get",
  ]
}

resource "google_project_iam_member" "sso_admin_group" {
  project = var.project_id
  role    = google_organization_iam_custom_role.cloud_engineer.id
  member  = "group:${var.admin_group_email}"
}
