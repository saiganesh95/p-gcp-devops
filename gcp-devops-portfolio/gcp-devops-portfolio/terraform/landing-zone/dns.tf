# --- Cloud DNS <-> on-prem DNS unified resolution ----------------------

resource "google_dns_policy" "outbound_forwarding" {
  project                   = var.project_id
  name                      = "policy-onprem-forwarding"
  enable_inbound_forwarding = true
  enable_logging            = true

  networks {
    network_url = google_compute_network.hub_vpc.id
  }
}

resource "google_dns_managed_zone" "onprem_forward_zone" {
  project    = var.project_id
  name       = "onprem-corp-zone"
  dns_name   = "corp.internal."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.hub_vpc.id
    }
  }

  forwarding_config {
    target_name_servers {
      ipv4_address = "10.30.0.53" # on-prem DNS resolver
    }
    target_name_servers {
      ipv4_address = "10.30.0.54"
    }
  }
}
