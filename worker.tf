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

  metadata_startup_script = join("", [
    "cat > ~/ca.pem <<EOF \n${tls_self_signed_cert.ca.cert_pem}EOF\n",
    "cat > ~/${var.WORKER_NAME}-${count.index}.pem <<EOF \n${tls_locally_signed_cert.kubelet[count.index].cert_pem}EOF\n",
    "cat > ~/${var.WORKER_NAME}-${count.index}-key.pem <<EOF \n${tls_private_key.kubelet[count.index].private_key_pem}EOF\n"
  ])

  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  tags = ["kubernetes-the-hard-way", "worker"]
}