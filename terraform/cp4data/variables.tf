variable "region" {
  default     = "us-south"
  description = "Region to provision the Openshift cluster. List all available regions with: ibmcloud regions"
}
variable "project_name" {
  description = "The project_name is combined with environment to name the cluster. The cluster name will be '{project_name}-{environment}-cluster' and all the resources will be tagged with 'project:{project_name}'"
}
variable "owner" {
  description = "Use your user name or team name. The owner is used to label the cluster and other resources with the tag 'owner:{owner}'"
}
variable "environment" {
  default     = "dev"
  description = "The environment is combined with project_name to name the cluster. The cluster name will be '{project_name}-{environment}-cluster' and all the resources will be tagged with 'env:{environment}'"
}
variable "resource_group" {
  default     = "cloud-pak-sandbox"
  description = "Resource Group in your account to host the cluster. List all available resource groups with: ibmcloud resource groups"
}
variable "cluster_id" {
  default     = ""
  description = "If you have an existing cluster to install the Cloud Pak, use the cluster ID or name. If left blank, a new Openshift cluster will be provisioned"
}
variable "datacenter" {
  default     = "dal10"
  description = "Datacenter or Zone in the IBM Cloud Classic region to provision the cluster. List all available zones with: ibmcloud ks zone ls --provider classic"
}

// VLAN's numbers variables on the datacenter, they are here until the
// permissions issues is fixed on Humio account
variable "private_vlan_number" {
  default     = ""
  description = "Private VLAN assigned to your zone. List available VLANs in the zone: ibmcloud ks vlan ls --zone, make sure the the VLAN type is private and the router begins with bc. Use the ID or Number"
}
variable "public_vlan_number" {
  default     = ""
  description = "Public VLAN assigned to your zone. List available VLANs in the zone: ibmcloud ks vlan ls --zone, make sure the the VLAN type is public and the router begins with fc. Use the ID or Number"
}

// CP4DATA Module Variables

// TODO: Include this variable in a future release to install/uninstall cp4data
// variable "cp4data_installer_comand" {
//   default     = "install"
//   description = "Command to execute by the cp4data installer, the most common are: install, uninstall, check, upgrade"
// }

variable "storage_class_name" {
  default     = "ibmc-file-custom-gold-gid"
  description = "Storage Class name to use. Supported Storage Classes: ibmc-file-custom-gold-gid, portworx-shared-gp3"
}

variable "entitled_registry_key" {
  default     = ""
  description = "Cloud Pak Entitlement Key. Get the entitlement key from: https://myibm.ibm.com/products-services/containerlibrary, copy and paste the key to this variable"
}
variable "entitled_registry_user_email" {
  description = "Email address of the user owner of the Entitled Registry Key"
}

// Modules available to install
variable "empty_module_list" {
  default     = true
  type        = bool
  description = "Determine if any modules need to be installed for CP4D"
}
variable "install_watson_knowledge_catalog" {
  default     = false
  type        = bool
  description = "Install Watson Knowledge Catalog module"
}
variable "install_watson_studio" {
  default     = false
  type        = bool
  description = "Install Watson Studio module"
}
variable "install_watson_machine_learning" {
  default     = false
  type        = bool
  description = "Install Watson Machine Learning module"
}
variable "install_watson_open_scale" {
  default     = false
  type        = bool
  description = "Install Watson Open Scale module"
}
variable "install_data_virtualization" {
  default     = false
  type        = bool
  description = "Install Data Virtualization module"
}
variable "install_streams" {
  default     = false
  type        = bool
  description = "Install Streams module"
}
variable "install_analytics_dashboard" {
  default     = false
  type        = bool
  description = "Install Analytics Dashboard module"
}
variable "install_spark" {
  default     = false
  type        = bool
  description = "Install Analytics Engine powered by Apache Spark module"
}
variable "install_db2_warehouse" {
  default     = false
  type        = bool
  description = "Install DB2 Warehouse module"
}
variable "install_db2_data_gate" {
  default     = false
  type        = bool
  description = "Install DB2 Data_Gate module"
}
variable "install_rstudio" {
  default     = false
  type        = bool
  description = "Install RStudio module"
}
variable "install_db2_data_management" {
  default     = false
  type        = bool
  description = "Install DB2 Data Management module"
}

// ROKS Module : Local Variables and constansts

locals {
  infra                      = "classic"
  flavors                    = ["b3c.16x64"]
  workers_count              = [4]
  roks_version               = "4.6"
  kubeconfig_dir             = "./.kube/config"
  entitled_registry_key_file = "./entitlement.key"
}
