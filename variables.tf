variable "REGION" {
  default = "australia-southeast1"
}

variable "ZONE" {
  default = "australia-southeast1-a"
}

variable "VPC_NAME" {
  default = "kubernetes-the-hard-way"
}

variable "SUBNET_NAME" {
  default = "kubernetes-subnet"
}

variable "CONTROLLER_NAME" {
  default = "controller"
}

variable "CONTROLLER_NUM" {
  default = 3
}

variable "CONTROLLER_TYPE" {
  default = "e2-micro"
}

variable "WORKER_NAME" {
  default = "worker"
}

variable "WORKER_NUM" {
  default = 3
}

variable "WORKER_TYPE" {
  default = "e2-micro"
}

variable "PROJECT_ID" {
  default = "kube-293902"
}

variable "PUBLIC_ADDRESS_NAME" {
  default = "kubernetes-the-hard-way"
}

//variable "SSH_KEY_NAME" {
//  default = "kubernetes-key"
//}

//variable "ORGANIZATION_NAME" {
//  default = "Kubernetes"
//}
//
//variable "COMMON_NAME" {
//  default = "Kubernetes-the-hard-way"
//}
//
//variable "STATE" {
//  default = "NSW"
//}
//
//variable "CITY" {
//  default = "Sydney"
//}

//locals {
//  controller_cert = ""
//}