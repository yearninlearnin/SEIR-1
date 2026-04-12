resource "google_compute_router" "router" {
  name    = var.router_name
  region  = var.region
  network = var.network

  bgp {
    asn = var.local_bgp_asn
  }
}

resource "google_compute_ha_vpn_gateway" "gcp" {
  name    = "${var.name}-ha-vpn"
  region  = var.region
  network = var.network
}

resource "google_compute_external_vpn_gateway" "peer" {
  name            = "${var.name}-peer"
  redundancy_type = var.peer_gateway_redundancy_type

  interface {
    id         = 0
    ip_address = var.peer_interface_0_ip
  }

  interface {
    id         = 1
    ip_address = var.peer_interface_1_ip
  }
}

resource "google_compute_vpn_tunnel" "tunnel0" {
  name                            = "${var.name}-tunnel-0"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.peer.id
  peer_external_gateway_interface = 0
  shared_secret                   = var.shared_secret_0
  router                          = google_compute_router.router.id
}

resource "google_compute_vpn_tunnel" "tunnel1" {
  name                            = "${var.name}-tunnel-1"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.peer.id
  peer_external_gateway_interface = 1
  shared_secret                   = var.shared_secret_1
  router                          = google_compute_router.router.id
}

resource "google_compute_router_interface" "if0" {
  name       = "${var.name}-if-0"
  router     = google_compute_router.router.name
  region     = var.region
  ip_range   = var.bgp_ip_range_0
  vpn_tunnel = google_compute_vpn_tunnel.tunnel0.name
}

resource "google_compute_router_peer" "peer0" {
  name            = "${var.name}-peer-0"
  router          = google_compute_router.router.name
  region          = var.region
  interface       = google_compute_router_interface.if0.name
  peer_ip_address = var.bgp_peer_ip_0
  peer_asn        = var.peer_bgp_asn
}

resource "google_compute_router_interface" "if1" {
  name       = "${var.name}-if-1"
  router     = google_compute_router.router.name
  region     = var.region
  ip_range   = var.bgp_ip_range_1
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1.name
}

resource "google_compute_router_peer" "peer1" {
  name            = "${var.name}-peer-1"
  router          = google_compute_router.router.name
  region          = var.region
  interface       = google_compute_router_interface.if1.name
  peer_ip_address = var.bgp_peer_ip_1
  peer_asn        = var.peer_bgp_asn
}
