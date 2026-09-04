### Classic (policy-based) VPN — used for legacy on-prem sites that
### don't support dynamic BGP routing ###

resource "google_compute_vpn_gateway" "classic_gw" {
  project = var.project_id
  region  = var.region
  name    = "classic-vpn-gw"
  network = var.network_id
}

resource "google_compute_address" "classic_vpn_ip" {
  project = var.project_id
  region  = var.region
  name    = "classic-vpn-static-ip"
}

resource "google_compute_forwarding_rule" "fr_esp" {
  project     = var.project_id
  region      = var.region
  name        = "fr-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.classic_vpn_ip.address
  target      = google_compute_vpn_gateway.classic_gw.id
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  project     = var.project_id
  region      = var.region
  name        = "fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.classic_vpn_ip.address
  target      = google_compute_vpn_gateway.classic_gw.id
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  project     = var.project_id
  region      = var.region
  name        = "fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.classic_vpn_ip.address
  target      = google_compute_vpn_gateway.classic_gw.id
}

resource "google_compute_vpn_tunnel" "classic_tunnel" {
  project                 = var.project_id
  region                  = var.region
  name                    = "classic-tunnel-site-a"
  peer_ip                 = var.onprem_gateway_ip
  shared_secret           = var.shared_secret
  target_vpn_gateway      = google_compute_vpn_gateway.classic_gw.id
  local_traffic_selector  = ["10.30.0.0/16"]
  remote_traffic_selector = ["192.168.0.0/16"]

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

resource "google_compute_route" "classic_route" {
  project    = var.project_id
  name       = "route-onprem-classic"
  network    = var.network_id
  dest_range = "192.168.0.0/16"
  priority   = 1000
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.classic_tunnel.id
}
