# terraform_study

This project is followed by [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way/).

Terraform is used to automate the whole process to build the infrastructures, create a Kubernetes cluster and deploy a nginx pod into the cluster, all from scratch.

All the deployment is based on GCP.

### How to use

#### Operate locally

1. Assign your GCP credential json file in main.tf/provider "google"

2. Set up your project_id in your GCP, at variables.tf/variable "PROJECT_ID"
3. Choice your own settings like controller&worker instance type, number in variables.tf
4. Execute ```terraform plan``` in the terminal to see the details of the changes
5. Execute ```terraform apply``` in the terminal to apply all the changes
6. Destory all the infrastructures by executing ```terraform destory```

#### Trigger by Github Actions

1. Fork the repo to your own 

2. Set up a workspace in your terraform cloud account, and assign it to your GitHub repo

3. Set an Environment Variables in terraform cloud: 

   ​	GOOGLE_CREDENTIALS - save the GCP credential json file.

   ​		**Note: you may need to write the whole context into one single line**

4. Set a secret in your Github:

   ​	TF_API_TOKEN - save the credential token of your terraform cloud(generated in terraform cloud)

5. Add a Pull Request in your GitHub repo, it will trigger a ```terraform plan``` action in your terraform cloud. The main modifications will be posted on the GitHub comments.

6. Merge a Pull Request or Push to the main branch of the repo, it will trigger a ```terraform apply``` action in your terraform cloud. If there is no error, your can conform the apply in your Terraform cloud, then all the changes will be deployed to  your GCP.

### Auto comment by GitHub Actions

The whole output of the Plan operation is too long and includes some sensitive information, so it should be filtered before commented on GitHub.

In this project, "#" is used to identify the important information which indicates the name of infrastructures that should be modified. 

```javascript
process.env.PLAN.match(/\# (.+\n)/g).join("")
```

### Note

#### Auto generated certificates/pem

All the certificates are sensitive, please keep them save

All the pem files will not output by default. If you want to use them anywhere else, uncomment the ```resource "local_file"``` section in the cert_xxx.tf files. Then the selected certificate files will output in /certs/

#### Backend

The tfstate file is sensitive. If you run this project locally, please keep it save.

Backend is used to store the tfstate file, including "aws/s3", "gcp/gcs", "azurerm", "terraform cloud" and so on.

1. Terraform Cloud

```HCL2
backend "remote" {
  organization = "kubernetes-the-hard-way"

  workspaces {
    name = "terraform_study"
  }
}
```

Make sure:

The organization and workspaces are exactly the same as those in your Terraform Cloud.

2. GCS

```HCL2
backend "gcs" {
  bucket  = "kubernetes-study"
  prefix  = "terraform/state"
}
```

Make sure you have already create the bucket in your gcs with the same name. The prefix is the path where the tfstate file save 