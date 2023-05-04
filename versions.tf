terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.52.0"
  }
    alicloud = {
      source = "aliyun/alicloud"
      version = "~> 1.203.0"
      configuration_aliases = [alicloud.china, alicloud.global]
    }
    aviatrix = {
      source = "AviatrixSystems/aviatrix"
      version = ">= 2.22.0"
      configuration_aliases = [aviatrix.china, aviatrix.global]
    } 
}
}