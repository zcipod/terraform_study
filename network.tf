resource "google_compute_network" "vpc_network" {
  name = var.VPC_NAME
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.SUBNET_NAME
  ip_cidr_range = "10.240.0.0/24"
  region        = var.REGION
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "firewall-allow-internal" {
  name    = "kubernetes-the-hard-way-allow-internal"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  source_ranges = ["10.240.0.0/24", "10.200.0.0/16"]
}

resource "google_compute_firewall" "firewall-allow-external" {
  name    = "kubernetes-the-hard-way-allow-external"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "firewall-allow-health-check" {
  name    = "kubernetes-the-hard-way-allow-health-check"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "209.85.152.0/22",
    "209.85.204.0/22",
    "35.191.0.0/16"
  ]
}

resource "google_compute_firewall" "firewall-allow-worker-0-nodeport" {
  name    = "kubernetes-the-hard-way-allow-nginx-service"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = 30201
  }
}

resource "google_compute_address" "public_address" {
  name = var.PUBLIC_ADDRESS_NAME
  region = var.REGION
}