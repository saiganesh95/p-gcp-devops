# --- Governance guardrails applied at org/folder level -----------------

resource "google_org_policy_policy" "domain_restricted_sharing" {
  name   = "organizations/${var.org_id}/policies/iam.allowedPolicyMemberDomains"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      values {
        allowed_values = [for d in var.allowed_domains : "domains/${d}"]
      }
    }
  }
}

resource "google_org_policy_policy" "restrict_vpc_peering" {
  name   = "organizations/${var.org_id}/policies/compute.restrictVpcPeering"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "require_os_login" {
  name   = "organizations/${var.org_id}/policies/compute.requireOsLogin"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "disable_sa_key_creation" {
  name   = "organizations/${var.org_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "resource_locations" {
  name   = "organizations/${var.org_id}/policies/gcp.resourceLocations"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      values {
        allowed_values = ["in:asia-south1-locations", "in:asia-southeast1-locations"]
      }
    }
  }
}
