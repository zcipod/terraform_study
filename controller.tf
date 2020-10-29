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

  metadata_startup_script = join("", [
    "cat > ~/ca.pem <<EOF \n${tls_self_signed_cert.ca.cert_pem}EOF\n",
    "cat > ~/ca-key.pem <<EOF \n${tls_private_key.ca.private_key_pem}EOF\n",
    "cat > ~/kubernetes.pem <<EOF \n${tls_locally_signed_cert.api-server.cert_pem}EOF\n",
    "cat > ~/kubernetes-key.pem <<EOF \n${tls_private_key.api-server.private_key_pem}EOF\n",
    "cat > ~/kubernetes.pem <<EOF \n${tls_locally_signed_cert.service-account.cert_pem}EOF\n",
    "cat > ~/kubernetes-key.pem <<EOF \n${tls_private_key.service-account.private_key_pem}EOF\n"
    ])

  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  tags = ["kubernetes-the-hard-way", "controller"]
}