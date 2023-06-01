![RestorePoint.RestorePoint_ai_Logo](https://img1.wsimg.com/isteam/ip/8fbe3f85-1ed1-43b5-b7e5-a0869eeee822/RestorePoint_ai_Logo%20Horizontal_net_Full%20Color.png/:/rs=w:258,h:38,cg:true,m/cr=w:258,h:38/qt=q:100/ll)

# RestorePoint Demo
Provision an AKS cluster and deploy a simple Nginx deployment

- `Manifest/nginx.yaml:` Kubernetes YAML file that describes a deployment that runs Nginx
- `Pipeline/main.yaml:` Pipeline YAML file with steps to provision an AKS cluster using Terraform and deploy an Nginx pod using Kubectl 
- `Terraform/main.tf:` HCL defined resource blocks to provision Azure resources

# Variables

- Set the `terraformDestroy` pipeline variable to `true` in order to destroy existing Azure resources
- Variable group `RestorePoint-Demo` is used in the pipeline