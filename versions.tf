terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.52.0"
  }
    alicloud = {
      source = "aliyun/alicloud"
      version = "~> 1.203.0"
    }
    aviatrix = {
      source = "AviatrixSystems/aviatrix"
      version = "~> 2.24.3"
    } 
}
}

provider "alicloud" {
  alias = "global"
  region = var.alicloud_region_global
}

provider "alicloud" {
  alias = "china"
  region = var.alicloud_region_china
}