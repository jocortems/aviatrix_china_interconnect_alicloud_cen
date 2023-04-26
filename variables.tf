variable "gateway_name" {
    type = string
    description = "Name of the Aviatrix Gateway"
}

variable "china_gateway_bgp_asn" {
    type = number
    description = "BGP ASN associated to China Transit Gateway"
    validation {
      condition = var.china_gateway_bgp_asn >= 1024 || var.china_gateway_bgp_asn <= 65535
      error_message = "Only 2-byte ASN is supported"
    }
}

variable "global_transit_bgp_asn" {
    type = number
    description = "BGP ASN associated to Global Transit Gateway"
    validation {
      condition = var.global_transit_bgp_asn >= 1024 || var.global_transit_bgp_asn <= 65535
      error_message = "Only 2-byte ASN is supported"
    }
}

variable "pre_shared_key" {
    type = string
    description = "Pre-shared key to use for S2C VPN Between China and Global"  
}

variable "alicloud_region_china" {
    type = string
    description = "Alibaba China Cloud Region Name"
}

variable "alicloud_region_global" {
    type = string
    description = "Alibaba Global Cloud Region Name"
}

variable "controller_nsg_name" {
    type = string
    description = "Name of the Network Security Group attached to the Aviatrix Controller Network Interface"  
}

variable "controller_nsg_resource_group_name" {
    type = string
    description = "Name of the Resource Group where the Network Security Group attached to the Aviatrix Controller Network Interface is deployed"  
}

variable "controller_nsg_rule_priority" {
    type = number
    description = "Priority of the rule that will be created in the existing Network Security Group attached to the Aviatrix Controller Network Interface. This number must be unique. Valid values are 100-4096"
    
    validation {
      condition = var.controller_nsg_rule_priority >= 100 && var.controller_nsg_rule_priority <= 4096
      error_message = "Priority must be a number between 100 and 4096"
    }
}

variable "ha_enabled" {
    type = bool
    description = "Whether HAGW will be deployed. Defaults to true"
    default = true
}

variable "controller_subscription_name" {
  type = string
  description = "Display Name of the Azure subscription where the Aviatrix Controller is created"
  default = ""
}

variable "transit_vpc_name" {
  type = string
  description = "Name of the transit VCN to be created in AliCloud"
}

variable "controller_alicloud_account" {
  type = string
  description = "Name of the AliCloud account onboarded to the controller"
}

variable "aviatrix_alicloud_region" {
  type = string
  description = "Region Name as exposed by the Aviatrix controller, example 'cn-beijing (Beijing)'"
}

variable "enable_segmentation" {
  type = bool
  description = "Whether to enable network segmentation in Aviatrix"
  default = false
}

variable "china_vpc_cidr" {
  type = string
  description = "CIDR used for the Aviatrix Transit VPC"  
}

variable "global_vpc_id" {
  type = string
  description = "VPC ID of the Aviatrix Transit VPC in Global Region"
}

variable "global_transitgw_private_ip" {
  type = string
  description = "Private IP address of Aviatrix Gateway in Global Region"
}

variable "global_transitgw_hagw_private_ip" {
  type = string
  description = "Private IP address of Aviatrix HA Gateway in Global Region"
  default = null
}

variable "global_transit_gw_eip_id" {
  type = string
  description = "EIP ID associated with Aviatrix Transit Gateway in Global Region"
  default = null  
}

variable "global_transit_hagw_eip_id" {
  type = string
  description = "EIP ID associated with Aviatrix Transit HA Gateway in Global Region"
  default = null  
}

variable "global_vpc_cidr" {
  type = string
  description = "CIDR of the Aviatrix Transit VPC in Global Region"
}

variable "alicloud_cen_name" {
  type = string
  description = "Name assigned to the AliCloud CEN instance"  
}

variable "cen_bandwidth_package_name" {
  type = string
  description = "If this variable is provided a new CEN Bandwidth package of type Prepaid will be created. Conflicts wtih cen_bandwidth_package_id"
  default = null
}

variable "cen_bandwidth_package_bandwdith" {
  type = number
  description = "Bandwidth allocated to the CEN bandwdith package to be created. Only needed if cen_bandwidth_package_name is specified"
  default = 0
}

variable "cen_bandwidth_limit" {
  type = number
  description = "Bandwidth allocated to the CEN from an existing CEN bandwidth package. Must be less than or equal to cen_bandwidth_package_bandwdith"
  default = null
}

variable "cen_bandwidth_package_period" {
  type = number
  description = "CEN bandwidth package purchase period in months. Note CEN Bandwidth package resource cannot be deleted before period. Valid values are 1, 2, 3, 6, 12"
  default = 1
  validation {
    condition     = can(index([1, 2, 3, 6, 12], var.cen_bandwidth_package_period))
    error_message = "Invalid period value. Allowed values are: 1, 2, 3, 6, 12."
  }
}

variable "cen_bandwidth_package_id" {
  type = string
  description = "Pre-created CEN bandwidth package ID. Conflicts with cen_bandwidth_package_name"
  default = null
}

variable "cen_bandwidth_type" {
  type = string
  description = "The method that is used to allocate bandwidth to the cross-region connection"
  default = "DataTransfer"
  validation {
    condition     = can(regex("^(BandwidthPackage|DataTransfer)$", var.cen_bandwidth_type))
    error_message = "Invalid value. Allowed values are: BandwidthPackage, DataTransfer."
  }
}

variable "cen_transit_router_peer_attachment_bandwidth_limit" {
  type = number
  description = "Bandwidth limit assigned to the Transit Router Peer attachment between China and Global"
  default = 2
}

variable "alicloud_cen_global_geo" {
  type = string
  description = "Name of the Geo where the global transit VPC connecting to CEN is deployed. Valid values are Nort-America, Asia-Pacific, Europe and Australia"
  validation {
    condition     = can(regex("^(North-America|Asia-Pacific|Europe|Australia)$", var.alicloud_cen_global_geo))
    error_message = "Invalid value. Allowed values are: North-America, Asia-Pacific, Europe, Australia."
  }
}

variable "alicloud_china_eip_bandwidth_plan_name" {
  type = string
  description = "Name of the bandwidth plan to be created in China region to associate Aviatrix Transit GWs Public IP Addresses with to overcome 200Mbps limit"
  default = null
}

variable "alicloud_global_eip_bandwidth_plan_name" {
  type = string
  description = "Name of the bandwidth plan be created in Global region to associate Aviatrix Transit GWs Public IP Addresses with to overcome 200Mbps limit"
  default = null
}

variable "alicloud_china_eip_bandwidth_plan_bandwidth" {
  type = number
  description = "Bandwidth associated to the EIP bandwidth plan in China Region in Mbps. Needed if alicloud_china_eip_bandwidth_plan_name is defined. Note this is not prepaid, it is pay-as-you-go"
  default = 500
}

variable "alicloud_global_eip_bandwidth_plan_bandwidth" {
  type = number
  description = "Bandwidth associated to the EIP bandwidth plan in Global Region in Mbps. Needed if alicloud_global_eip_bandwidth_plan_name is defined. Note this is not prepaid, it is pay-as-you-go"
  default = 500
}

variable "tunnel_supernet" {
  description = "/24 Supernet for tunnel IP addresses"
  type        = string
  default     = "169.254.0.0/28"
}

locals {
  tunnel_cidr_blocks = cidrsubnets(var.tunnel_supernet, 2, 2, 2, 2)
}