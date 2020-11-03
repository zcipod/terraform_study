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

5. Add a Pull Request in your GitHub repo, it will trigger a ```terraform plan``` action in your terraform cloud(currently unavailable)

6. Merge a Pull Request or Push to the main branch of the repo, it will trigger a ```terraform apply``` action in your terraform cloud. If there is no error, your can conform the apply in your Terraform cloud, then all the changes will be deployed to  your GCP.

### Note

#### Auto generated certificates/pem

All the certificates are sensitive, please keep them save

All the pem files will not output by default. If you want to use them anywhere else, uncomment the ```resource "local_file"``` section in the cert_xxx.tf files. Then the selected certificate files will output in /certs/

#### tfstate file

The tfstate file is sensitive. If you run this project locally, please keep it save.

If you run this project on terraform cloud, the state will be saved in the cloud.

