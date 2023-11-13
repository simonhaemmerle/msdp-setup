terraform {
  # https://docs.ionos.com/terraform-provider/api/data-platform
  # https://registry.terraform.io/providers/ionos-cloud/ionoscloud/latest
  required_providers {
    ionoscloud = {
      source = "ionos-cloud/ionoscloud"
      version = "6.4.10"
    }
  }
}

# We use token authentication or use TF_VAR_ionos_username + TF_VAR_ionos_password
# Generate an [Authentication](https://api.ionos.com/docs/authentication/#authentication) token here or use ionosctl (https://docs.ionos.com/cli-ionosctl/subcommands/authentication/token/generate)
variable "ionos_token" {
  description = "Token to be used with the IONOS Cloud Provider - set using environment variable TF_VAR_ionos_token"
  type        = string
  sensitive   = true
}

variable "cluster_description" {
  description = "Name of the cluster description file - set using environment variable TF_VAR_cluster_description"
  type        = string
}

# https://registry.terraform.io/providers/ionos-cloud/ionoscloud/latest/docs
provider "ionoscloud" {
  token = var.ionos_token
}

# https://registry.terraform.io/providers/ionos-cloud/ionoscloud/latest/docs/resources/datacenter
resource "ionoscloud_datacenter" "datacenter" {
  name = yamldecode(file("${var.cluster_description}"))["spec"]["name"]
  location = yamldecode(file("${var.cluster_description}"))["spec"]["location"]
  description = "Datacenter containing nodes for cluster ${yamldecode(file("${var.cluster_description}"))["spec"]["name"]}"
}

# https://registry.terraform.io/providers/ionos-cloud/ionoscloud/latest/docs/resources/dataplatform_cluster
resource "ionoscloud_dataplatform_cluster" "cluster" {
  datacenter_id          =  ionoscloud_datacenter.datacenter.id
  name                   = yamldecode(file("${var.cluster_description}"))["spec"]["name"]
  maintenance_window {
    day_of_the_week      = "Sunday"
    time                 = "09:00:00"
  }
  version = yamldecode(file("${var.cluster_description}"))["spec"]["stackable_version"]
}

# https://registry.terraform.io/providers/ionos-cloud/ionoscloud/latest/docs/resources/dataplatform_node_pool
resource "ionoscloud_dataplatform_node_pool" "nodepool" {
  cluster_id        = ionoscloud_dataplatform_cluster.cluster.id
  name              = yamldecode(file("${var.cluster_description}"))["spec"]["name"]
  node_count        = yamldecode(file("${var.cluster_description}"))["spec"]["node_count"]
  cpu_family        = yamldecode(file("${var.cluster_description}"))["spec"]["cpu_family"]
  cores_count       = 4
  ram_size          = 8192
  availability_zone = "AUTO"
  storage_type      = "SSD"
  storage_size      = 100
  maintenance_window {
    day_of_the_week = "Monday"
    time            = "09:00:00"
  }
}

data "ionoscloud_dataplatform_cluster" "cluster" {
  id = ionoscloud_dataplatform_cluster.cluster.id
}

# https://registry.terraform.io/providers/ionos-cloud/ionoscloud/latest/docs/data-sources/dataplatform_cluster#example-of-dumping-the-kube_config-raw-data-into-a-yaml-file
resource "local_sensitive_file" "kubeconfig" {
    content       = yamlencode(jsondecode(data.ionoscloud_dataplatform_cluster.cluster.kube_config))
    filename      = "kubeconfig.yaml"
}