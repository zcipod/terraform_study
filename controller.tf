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
    "cat > ~/service-account.pem <<EOF \n${tls_locally_signed_cert.service-account.cert_pem}EOF\n",
    "cat > ~/service-account-key.pem <<EOF \n${tls_private_key.service-account.private_key_pem}EOF\n",
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

    // Bootstrapping the Kubernetes Control Plane
    "mkdir -p /etc/kubernetes/config\n",

    // install kubernetes controller binaries
    "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kube-apiserver\n",
    "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kube-controller-manager\n",
    "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kube-scheduler\n",
    "wget -q --show-progress --https-only --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl\n",
    "chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl\n",
    "mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/\n",

    // configure kubernetes API Server
    "mkdir -p /var/lib/kubernetes/\n",
    "mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem service-account-key.pem service-account.pem encryption-config.yaml /var/lib/kubernetes/\n",

    "cat <<EOF | tee /etc/systemd/system/kube-apiserver.service\n",
    "[Unit]\n",
    "Description=Kubernetes API Server\n",
    "Documentation=https://github.com/kubernetes/kubernetes\n\n",
    "[Service]\n",
    "ExecStart=/usr/local/bin/kube-apiserver \\\n",
    "  --advertise-address=10.240.0.1${count.index} \\\n",
    "  --allow-privileged=true \\\n",
    "  --apiserver-count=${var.CONTROLLER_NUM} \\\n",
    "  --audit-log-maxage=30 \\\n",
    "  --audit-log-maxbackup=3 \\\n",
    "  --audit-log-maxsize=100 \\\n",
    " --audit-log-path=/var/log/audit.log \\\n",
    "--authorization-mode=Node,RBAC \\\n",
    "--bind-address=0.0.0.0 \\\n",
    "--client-ca-file=/var/lib/kubernetes/ca.pem \\\n",
    "--enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\\n",
    "--etcd-cafile=/var/lib/kubernetes/ca.pem \\\n",
    "--etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\\n",
    "--etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\\n",
    "--etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\\n",
    "--event-ttl=1h \\\n",
    "--encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\\n",
    "--kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\\n",
    "--kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\\n",
    "--kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\\n",
    "--kubelet-https=true \\\n",
    "--runtime-config='api/all=true' \\\n",
    "--service-account-key-file=/var/lib/kubernetes/service-account.pem \\\n",
    "--service-cluster-ip-range=10.32.0.0/24 \\\n",
    "--service-node-port-range=30000-32767 \\\n",
    "--tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\\n",
    "--tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\\n",
    "--v=2\n",
    "Restart=on-failure\n",
    "RestartSec=5\n\n",
    "[Install]\n",
    "WantedBy=multi-user.target\n",
    "EOF\n",

    // configure kubernetes controller manager
    "mv kube-controller-manager.kubeconfig /var/lib/kubernetes/\n",
    "cat <<EOF | tee /etc/systemd/system/kube-controller-manager.service\n",
    "[Unit]\n",
    "Description=Kubernetes Controller Manager\n",
    "Documentation=https://github.com/kubernetes/kubernetes\n",
    "[Service]\n",
    "ExecStart=/usr/local/bin/kube-controller-manager \\\n",
    "--bind-address=0.0.0.0 \\\n",
    "--cluster-cidr=10.200.0.0/16 \\\n",
    "--cluster-name=kubernetes \\\n",
    "--cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\\n",
    "--cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\\n",
    "--kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\\n",
    "--leader-elect=true \\\n",
    "--root-ca-file=/var/lib/kubernetes/ca.pem \\\n",
    "--service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\\n",
    "--service-cluster-ip-range=10.32.0.0/24 \\\n",
    "--use-service-account-credentials=true \\\n",
    "--v=2\n",
    "Restart=on-failure\n",
    "RestartSec=5\n",
    "[Install]\n",
    "WantedBy=multi-user.target\n",
    "EOF\n",

    // configure kubernetes scheduler
    "mv kube-scheduler.kubeconfig /var/lib/kubernetes/\n",
    "cat <<EOF | tee /etc/kubernetes/config/kube-scheduler.yaml\n",
    "apiVersion: kubescheduler.config.k8s.io/v1alpha1\n",
    "kind: KubeSchedulerConfiguration\n",
    "clientConnection:\n",
    "  kubeconfig: \"/var/lib/kubernetes/kube-scheduler.kubeconfig\"\n",
    "leaderElection:\n",
    "  leaderElect: true\n",
    "EOF\n",

    "cat <<EOF | tee /etc/systemd/system/kube-scheduler.service\n",
    "[Unit]\n",
    "Description=Kubernetes Scheduler\n",
    "Documentation=https://github.com/kubernetes/kubernetes\n\n",
    "[Service]\n",
    "ExecStart=/usr/local/bin/kube-scheduler \\\n",
    "--config=/etc/kubernetes/config/kube-scheduler.yaml \\\n",
    "--v=2\n",
    "Restart=on-failure\n",
    "RestartSec=5\n\n",
    "[Install]\n",
    "WantedBy=multi-user.target\n",
    "EOF\n",

    // start controller services
    "systemctl daemon-reload\n",
    "systemctl enable kube-apiserver kube-controller-manager kube-scheduler\n",
    "systemctl start kube-apiserver kube-controller-manager kube-scheduler\n",

    // enable HTTP health checkes
    "apt-get update\n",
    "apt-get install -y nginx\n",
    "cat > kubernetes.default.svc.cluster.local <<EOF\n",
    "server {\n",
    "listen      80;\n",
    "server_name kubernetes.default.svc.cluster.local;\n",
    "location /healthz {\n",
    "proxy_pass                    https://127.0.0.1:6443/healthz;\n",
    "proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;\n",
    " }\n",
    "}\n",
    "EOF\n",

    "mv kubernetes.default.svc.cluster.local /etc/nginx/sites-available/kubernetes.default.svc.cluster.local\n",
    "ln /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/\n",

    "systemctl restart nginx\n",
    "systemctl restart nginx\n",

    // RBAC for kubelet authorization
    "if [${count.index}=0]; then\n",
    "cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -\n",
    "apiVersion: rbac.authorization.k8s.io/v1beta1\n",
    "kind: ClusterRole\n",
    "metadata:\n",
    "  annotations:\n",
    "   rbac.authorization.kubernetes.io/autoupdate: \"true\"\n",
    " labels:\n",
    "   kubernetes.io/bootstrapping: rbac-defaults\n",
    " name: system:kube-apiserver-to-kubelet\n",
    "rules:\n",
    " - apiGroups:\n",
    "     - \"\"\n",
    "   resources:\n",
    "     - nodes/proxy\n",
    "     - nodes/stats\n",
    "     - nodes/log\n",
    "     - nodes/spec\n",
    "     - nodes/metrics\n",
    "   verbs:\n",
    "     - \"*\"\n",
    "EOF\n",

    "cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -\n",
    "apiVersion: rbac.authorization.k8s.io/v1beta1\n",
    "kind: ClusterRoleBinding\n",
    "metadata:\n",
    " name: system:kube-apiserver\n",
    " namespace: \"\"\n",
    "roleRef:\n",
    " apiGroup: rbac.authorization.k8s.io\n",
    " kind: ClusterRole\n",
    " name: system:kube-apiserver-to-kubelet\n",
    "subjects:\n",
    " - apiGroup: rbac.authorization.k8s.io\n",
    "   kind: User\n",
    "   name: kubernetes\n",
    "EOF\n",
    "fi\n",

  ])




  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  tags = ["kubernetes-the-hard-way", "controller"]
}