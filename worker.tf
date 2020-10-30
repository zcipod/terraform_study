resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
}

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
    pod-cidr = "10.200.${count.index}.0/24",
    sshKeys = "root:${tls_private_key.ssh-key.public_key_openssh}"
  }

  connection {
    type = "ssh"
    user = "root"
    private_key = tls_private_key.ssh-key.private_key_pem
    host = self.network_interface[0].access_config[0].nat_ip
  }

  metadata_startup_script = "echo test"
//  metadata_startup_script = join("", [
//    "cat > ~/ca.pem <<EOF \n${tls_self_signed_cert.ca.cert_pem}EOF\n",
//    "cat > ~/ca-key.pem <<EOF \n${tls_private_key.ca.private_key_pem}EOF\n",
//    "wget https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl\n",
//    "wget https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson\n",
//    "chmod +x cfssl cfssljson\n",
//    "mv cfssl cfssljson /usr/local/bin/\n",
//    "cat > ca-config.json <<EOF \n",
//    "{\"signing\": {\"default\": {\"expiry\": \"8760h\"},\"profiles\": {\"kubernetes\": {\"usages\": [\"signing\", \"key encipherment\", \"server auth\", \"client auth\"],\"expiry\": \"8760h\"}}}} \n",
//    "EOF\n",
//    "cat > ${var.WORKER_NAME}-${count.index}-csr.json <<EOF \n",
//    "{\"CN\": \"system:node:${var.WORKER_NAME}-${count.index}\",\"key\": {\"algo\": \"rsa\",\"size\": 2048},\"names\": [{\"C\": \"AU\",\"L\": \"Sydney\",\"O\": \"system:nodes\",\"OU\": \"Kubernetes The Hard Way\",\"ST\": \"NSW\"}]} \n",
//    "EOF\n",
//    "EOF\n",
//    "cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=${var.WORKER_NAME}-${count.index},$(curl -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip),10.240.0.2${count.index} -profile=kubernetes ${var.WORKER_NAME}-${count.index}-csr.json | cfssljson -bare ${var.WORKER_NAME}-${count.index}\n",
//    "EOF\n",
//
//    "rm ca-key.pem"
    //    "cat > ~/ca.pem <<EOF \n${tls_self_signed_cert.ca.cert_pem}EOF\n",
//    "cat > ~/${var.WORKER_NAME}-${count.index}.pem <<EOF \n${tls_locally_signed_cert.kubelet[count.index].cert_pem}EOF\n",
//    "cat > ~/${var.WORKER_NAME}-${count.index}-key.pem <<EOF \n${tls_private_key.kubelet[count.index].private_key_pem}EOF\n",
//    "wget https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl\n",
//    "chmod +x kubectl\n",
//    "mv kubectl /usr/local/bin/\n",
//
//    // kubelet configuration file
//    "kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://${google_compute_address.public_address.address}:6443 --kubeconfig=${var.CONTROLLER_NAME}-${count.index}.kubeconfig\n",
//    "kubectl config set-credentials system:node:${var.WORK_NAME}-${count.index} --client-certificate=${var.WORK_NAME}-${count.index}.pem --client-key=${var.WORK_NAME}-${count.index}-key.pem --embed-certs=true --kubeconfig=${var.WORK_NAME}-${count.index}.kubeconfig\n",
//    "kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:node:${var.WORK_NAME}-${count.index} --kubeconfig=${var.CONTROLLER_NAME}-${count.index}.kubeconfig\n",
//    "kubectl config use-context default --kubeconfig=${var.CONTROLLER_NAME}-${count.index}.kubeconfig\n",
//
//    // kube-proxy configuration file
//    "kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://${google_compute_address.public_address.address}:6443 --kubeconfig=kube-proxy.kubeconfig\n",
//    "kubectl config set-credentials system:kube-proxy --client-certificate=kube-proxy.pem --client-key=kube-proxy-key.pem --embed-certs=true --kubeconfig=kube-proxy.kubeconfig\n",
//    "kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:kube-proxy --kubeconfig=kube-proxy.kubeconfig\n",
//    "kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig\n",
//  ])

  provisioner "file" {
    content     = tls_self_signed_cert.ca.cert_pem
    destination = "~/ca.pem"
  }
  provisioner "file" {
    content     = tls_private_key.ca.private_key_pem
    destination = "~/ca-key.pem"
  }
  provisioner "file" {
    content     = tls_locally_signed_cert.proxy.cert_pem
    destination = "~/kube-proxy.pem"
  }
  provisioner "file" {
    content     = tls_private_key.proxy.private_key_pem
    destination = "~/kube-proxy-key.pem"
  }
  provisioner "file" {
    source     = "script/cfssl"
    destination = "~/cfssl"
  }
  provisioner "file" {
    source     = "script/cfssljson"
    destination = "~/cfssljson"
  }
  provisioner "file" {
    source     = "script/ca-config.json"
    destination = "~/ca-config.json"
  }
  provisioner "file" {
    content     = "{\"CN\": \"system:node:${self.name}\",\"key\": {\"algo\": \"rsa\",\"size\": 2048},\"names\": [{\"C\": \"AU\",\"L\": \"Sydney\",\"O\": \"system:nodes\",\"OU\": \"Kubernetes The Hard Way\",\"ST\": \"NSW\"}]}"
    destination = "~/${self.name}-csr.json"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x cfssl cfssljson",
      "mv cfssl cfssljson /usr/local/bin/",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=${self.name},${self.network_interface[0].access_config[0].nat_ip},${self.network_interface[0].network_ip} -profile=kubernetes ${self.name}-csr.json | cfssljson -bare ${self.name}",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      // install kubectl
      "wget https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl",
      "chmod +x kubectl",
      "mv kubectl /usr/local/bin/",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      // kubelet configuration file
      "kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://${google_compute_address.public_address.address}:6443 --kubeconfig=${self.name}.kubeconfig",
      "kubectl config set-credentials system:node:${self.name} --client-certificate=${self.name}.pem --client-key=${self.name}-key.pem --embed-certs=true --kubeconfig=${self.name}.kubeconfig",
      "kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:node:${self.name} --kubeconfig=${self.name}.kubeconfig",
      "kubectl config use-context default --kubeconfig=${self.name}.kubeconfig",
    ]
  }


  provisioner "remote-exec" {
    inline = [
      // kube-proxy configuration file
      "kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://${google_compute_address.public_address.address}:6443 --kubeconfig=kube-proxy.kubeconfig",
      "kubectl config set-credentials system:kube-proxy --client-certificate=kube-proxy.pem --client-key=kube-proxy-key.pem --embed-certs=true --kubeconfig=kube-proxy.kubeconfig",
      "kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:kube-proxy --kubeconfig=kube-proxy.kubeconfig",
      "kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig",
      "rm ca-key.pem"
    ]
  }

  provisioner "remote-exec" {
    script = "script/bootstrapping_kubernetes_workers.sh"
  }

  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  tags = ["kubernetes-the-hard-way", "worker"]
}