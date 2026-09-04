### HA VPN: GCP <-> on-prem, 2 tunnels for 99.99% SLA ###

variable "project_id" { type = string }
variable "region" {
  type    = string
  default = "asia-south1"
}
variable "network_id" { type = string }        # self_link of existing VPC
variable "onprem_gateway_ip" { type = string }  # on-prem VPN peer IP
variable "shared_secret" {
  type      = string
  sensitive = true
}

resource "google_compute_ha_vpn_gateway" "gcp_gw" {
  project = var.project_id
  region  = var.region
  name    = "ha-vpn-gw-onprem"
  network = var.network_id
}

resource "google_compute_external_vpn_gateway" "onprem_gw" {
  project         = var.project_id
  name            = "onprem-external-gw"
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"

  interface {
    id         = 0
    ip_address = var.onprem_gateway_ip
  }
}

resource "google_compute_router" "vpn_router" {
  project = var.project_id
  region  = var.region
  name    = "router-ha-vpn"
  network = var.network_id

  bgp {
    asn = 64512
  }
}

resource "google_compute_vpn_tunnel" "tunnel1" {
  project                         = var.project_id
  region                          = var.region
  name                            = "ha-vpn-tunnel-1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_gw.id
  peer_external_gateway           = google_compute_external_vpn_gateway.onprem_gw.id
  peer_external_gateway_interface = 0
  shared_secret                   = var.shared_secret
  router                          = google_compute_router.vpn_router.id
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "tunnel2" {
  project                         = var.project_id
  region                          = var.region
  name                            = "ha-vpn-tunnel-2"
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_gw.id
  peer_external_gateway           = google_compute_external_vpn_gateway.onprem_gw.id
  peer_external_gateway_interface = 0
  shared_secret                   = var.shared_secret
  router                          = google_compute_router.vpn_router.id
  vpn_gateway_interface           = 1
}

resource "google_compute_router_interface" "int1" {
  project    = var.project_id
  region     = var.region
  router     = google_compute_router.vpn_router.name
  name       = "if-tunnel-1"
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1.name
}

resource "google_compute_router_peer" "peer1" {
  project                   = var.project_id
  region                    = var.region
  router                    = google_compute_router.vpn_router.name
  name                      = "bgp-peer-1"
  interface                 = google_compute_router_interface.int1.name
  peer_ip_address           = "169.254.0.2"
  peer_asn                  = 65001
  advertised_route_priority = 100
}

resource "google_compute_router_interface" "int2" {
  project    = var.project_id
  region     = var.region
  router     = google_compute_router.vpn_router.name
  name       = "if-tunnel-2"
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2.name
}

resource "google_compute_router_peer" "peer2" {
  project                   = var.project_id
  region                    = var.region
  router                    = google_compute_router.vpn_router.name
  name                      = "bgp-peer-2"
  interface                 = google_compute_router_interface.int2.name
  peer_ip_address           = "169.254.1.2"
  peer_asn                  = 65001
  advertised_route_priority = 100
}
