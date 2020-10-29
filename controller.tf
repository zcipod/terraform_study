locals {
  cluster = join(",",[for i in range(var.WORKER_NUM): "${var.CONTROLLER_NAME}-${i}=https://10.240.0.1${i}:2380"])
}

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
    "cat > ~/kube-controller-namager.pem <<EOF \n${tls_locally_signed_cert.controller.cert_pem}EOF\n",
    "cat > ~/kube-controller-namager-key.pem <<EOF \n${tls_private_key.controller.private_key_pem}EOF\n",
    "cat > ~/kube-scheduler.pem <<EOF \n${tls_locally_signed_cert.scheduler.cert_pem}EOF\n",
    "cat > ~/kube-scheduler-key.pem <<EOF \n${tls_private_key.scheduler.private_key_pem}EOF\n",
    "cat > ~/admin.pem <<EOF \n${tls_locally_signed_cert.admin.cert_pem}EOF\n",
    "cat > ~/admin-key.pem <<EOF \n${tls_private_key.admin.private_key_pem}EOF\n",


    // install kubectl
    "cd ~\n",
    "wget https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl\n",
    "chmod +x kubectl\n",
    "mv kubectl /usr/local/bin/\n",

    // kube-controller-namager configuration file
    "kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig=kube-controller-manager.kubeconfig\n",
    "kubectl config set-credentials system:kube-controller-manager --client-certificate=kube-controller-namager.pem --client-key=kube-controller-namager-key.pem --embed-certs=true --kubeconfig=kube-controller-manager.kubeconfig\n",
    "kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig\n",
    "kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig\n",

    // kube-scheduler configuration file
    "kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig=kube-scheduler.kubeconfig\n",
    "kubectl config set-credentials system:kube-scheduler --client-certificate=kube-scheduler.pem --client-key=kube-scheduler-key.pem --embed-certs=true --kubeconfig=kube-scheduler.kubeconfig\n",
    "kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig\n",
    "kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig\n",

    // Admin configuration file
    "kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig=admin.kubeconfig\n",
    "kubectl config set-credentials admin --client-certificate=admin.pem --client-key=admin-key.pem --embed-certs=true --kubeconfig=admin.kubeconfig\n",
    "kubectl config set-context default --cluster=kubernetes-the-hard-way --user=admin --kubeconfig=admin.kubeconfig\n",
    "kubectl config use-context default --kubeconfig=admin.kubeconfig\n",

    // encryption-config.yaml
    "cat > encryption-config.yaml <<EOF\nkind: EncryptionConfig\napiVersion: v1\nresources:\n  - resources:\n      - secrets\n    providers:\n      - aescbc:\n          keys:\n            - name: key1\n              secret: $(head -c 32 /dev/urandom | base64)\n      - identity: {}\n",
    "EOF\n",

    // Bootstrapping the etcd Cluster
    "wget -q --show-progress --https-only --timestamping https://github.com/etcd-io/etcd/releases/download/v3.4.10/etcd-v3.4.10-linux-amd64.tar.gz\n",
    "tar -xvf etcd-v3.4.10-linux-amd64.tar.gz\n",
    "mv etcd-v3.4.10-linux-amd64/etcd* /usr/local/bin/\n",
    "mkdir -p /etc/etcd /var/lib/etcd\n",
    "chmod 700 /var/lib/etcd\n",
    "cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/\n",

    // Create etcd.service
    "cat <<EOF | tee /etc/systemd/system/etcd.service\n",
    "Unit\n",
    "Description=etcd\n",
    "Documentation=https://github.com/coreos\n\n",
    "[Service]\n",
    "Type=notify\n",
    "ExecStart=/usr/local/bin/etcd \\\n",
    "  --name ${var.CONTROLLER_NAME}-${count.index} \\\n",
    "  --cert-file=/etc/etcd/kubernetes.pem \\\n",
    "  --key-file=/etc/etcd/kubernetes-key.pem \\\n",
    "  --peer-cert-file=/etc/etcd/kubernetes.pem \\\n",
    "  --peer-key-file=/etc/etcd/kubernetes-key.pem \\\n",
    "  --trusted-ca-file=/etc/etcd/ca.pem \\\n",
    "  --peer-trusted-ca-file=/etc/etcd/ca.pem \\\n",
    "  --peer-client-cert-auth \\\n",
    "  --client-cert-auth \\\n",
    "  --initial-advertise-peer-urls https://10.240.0.1${count.index}:2380 \\\n",
    "  --listen-peer-urls https://10.240.0.1${count.index}:2380 \\\n",
    "  --listen-client-urls https://10.240.0.1${count.index}:2379,https://127.0.0.1:2379 \\\n",
    "  --advertise-client-urls https://10.240.0.1${count.index}:2379 \\\n",
    "  --initial-cluster-token etcd-cluster-0 \\\n",
    "  --initial-cluster ${local.cluster} \\\n",
    "  --initial-cluster-state new \\\n",
    "  --data-dir=/var/lib/etcd\n",
    "Restart=on-failure\n",
    "RestartSec=5\n\n",
    "[Install]\n",
    "WantedBy=multi-user.target\n",
    "EOF\n",

    // start etcd server
    "systemctl daemon-reload\n",
    "systemctl enable etcd\n",
    "systemctl start etcd\n",
    ])




  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  tags = ["kubernetes-the-hard-way", "controller"]
}