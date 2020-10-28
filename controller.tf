resource "google_compute_instance" "controller" {
  count = var.CONTROLLER_NUM

  name         = "${var.CONTROLLER_NAME}-${count.index}"
  machine_type = var.CONTROLLER_TYPE
  zone         = var.ZONE

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size = 200
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link

    network_ip = "10.240.0.1${count.index}"

    access_config {
      // Ephemeral IP
    }
  }

  can_ip_forward = true

  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  tags = ["kubernetes-the-hard-way", "controller"]
}