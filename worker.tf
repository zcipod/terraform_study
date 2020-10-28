resource "google_compute_instance" "worker" {
  count = var.WORKER_NUM

  name         = "${var.WORKER_NAME}-${count.index}"
  machine_type = var.WORKER_TYPE
  zone         = var.ZONE

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size = 200
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link

    network_ip = "10.240.0.2${count.index}"

    access_config {
      // Ephemeral IP
    }
  }

  can_ip_forward = true

  metadata = {
    pod-cidr = "10.200.${count.index}.0/24"
  }

  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  tags = ["kubernetes-the-hard-way", "worker"]
}