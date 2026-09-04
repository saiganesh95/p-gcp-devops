# --- Hub VPC for shared connectivity (hub-and-spoke pattern) -----------

resource "google_compute_network" "hub_vpc" {
  project                 = var.project_id
  name                     = "vpc-hub-common-connectivity"
  auto_create_subnetworks  = false
  routing_mode             = "GLOBAL"
}

resource "google_compute_subnetwork" "hub_subnet" {
  project       = var.project_id
  name          = "subnet-hub-${var.region}"
  ip_cidr_range = "10.30.0.0/22"
  region        = var.region
  network       = google_compute_network.hub_vpc.id

  log_config {
    aggregation_interval = "INTERVAL_5_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_internal" {
  project = var.project_id
  name    = "fw-allow-internal"
  network = google_compute_network.hub_vpc.name

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]
}

resource "google_compute_firewall" "deny_all_ingress" {
  project   = var.project_id
  name      = "fw-deny-all-ingress"
  network   = google_compute_network.hub_vpc.name
  priority  = 65534
  direction = "INGRESS"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_router" "hub_router" {
  project = var.project_id
  name    = "router-hub-${var.region}"
  region  = var.region
  network = google_compute_network.hub_vpc.id

  bgp {
    asn = 64512
  }
}
