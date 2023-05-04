variable "controller_nsg_name" {
  type = string
  description = "Name of the NSG associated with the Aviatrix Controller deployed in China Region"
}
  
variable "controller_nsg_resource_group_name" {
  type = string
  description = "Name of the Resource Group associated with the NSG for the Aviatrix Controller deployed in China Region"
}

variable "controller_nsg_rule_priority" {
  type = number 
  description = "Priority of the NSG rule associated with the Aviatrix Controller deployed in China Region. This number must be unique, before assigning verify the NSG does not have a rule with the same priority. If deploying the Gateway in HA two rules will be created using consecutive priorities, the priority specified here will be for the first gateway"
}

variable "ha_enabled" {
  type = bool
  description = "Whether to enable HA for the Gateways deployed both in China and Global Regions"
  default = true
}

variable "china_controller_account_name" {
  type = string
  description = "Name of the Aviatrix Controller AliCloud Account in China Region"
}

variable "global_controller_account_name" {
  type = string
  description = "Name of the Aviatrix Controller AliCloud Account in Global Region"
}

variable "china_transit_vpc_name" {
  type = string
  description = "Name of the Aviatrix Transit VPC in China Region"
}

variable "gw_china_region" {
  type = string
  description = "Name of the Region where the Aviatrix Transit Gateway will be deployed in China Region. This must match Aviatrix Controller list. Example \"acs-cn-beijing (Beijing)\""
}

variable "gw_global_region" {
  type = string
  description = "Name of the Region where the Aviatrix Transit Gateway will be deployed in Global Region. This must match Aviatrix Controller list. Example \"acs-ap-southeast-1 (Singapore)\""
}

variable "china_gateway_name" {
  type = string
  description = "Name of the Aviatrix Transit Gateway in China Region. If not provided defaults to the VPC name in China Region"
  default = null
}

variable "china_gateway_size" {
  type = string
  description = "Instance Size of the Aviatrix Transit Gateway in China Region. Must be different from the BGP ASN used in Global Region"
  default = "ecs.g5ne.large"
}

variable "china_gateway_bgp_asn" {
  type = number
  description = "BGP ASN of the Aviatrix Transit Gateway in China Region"

  validation {
    condition     = var.china_gateway_bgp_asn >= 1024 && var.china_gateway_bgp_asn <= 65535
    error_message = "Invalid BGP ASN value. Allowed values are: 1024 - 65535"
  }
}

variable "global_transit_vpc_name" {
  type = string
  description = "Name of the Aviatrix Transit VPC in Global Region"
}

variable "global_gateway_name" {
  type = string
  description = "Name of the Aviatrix Transit Gateway in Global Region. If not provided defaults to the VPC name in Global Region"
}

variable "global_gateway_size" {
  type = string
  description = "Instance Size of the Aviatrix Transit Gateway in Global Region"
  default = "ecs.g5ne.large"
}
  
variable "global_gateway_bgp_asn" {
  type = number
  description = "BGP ASN of the Aviatrix Transit Gateway in Global Region. Must be different from the BGP ASN used in China Region"

  validation {
    condition     = var.global_gateway_bgp_asn >= 1024 && var.global_gateway_bgp_asn <= 65535
    error_message = "Invalid BGP ASN value. Allowed values are: 1024 - 65535"
  }
}

variable "pre_shared_key" {
  type = string
  description = "Pre-shared key used for the IPsec tunnel between China and Global Regions"
}

variable "ali_china_region" {
    type = string
    description = "Alibaba China Cloud Region Name"
}

variable "ali_global_region" {
    type = string
    description = "Alibaba Global Cloud Region Name"
}

variable "china_vpc_cidr" {
  type = string
  description = "CIDR used for the Aviatrix Transit VPC"  
}

variable "global_vpc_cidr" {
  type = string
  description = "CIDR of the Aviatrix Transit VPC in Global Region"
}

variable "enable_segmentation_china" {
  type = bool
  description = "Enable Segmentation on transit gateway deployed in China Region"
  default = false
}

variable "enable_segmentation_global" {
  type = bool
  description = "Enable Segmentation on transit gateway deployed in Global Region"
  default = false
}

variable "connected_transit_china" {
  type = bool
  description = "Enable Connected Transit on transit gateway deployed in China Region"
  default = true
}

variable "connected_transit_global" {
  type = bool
  description = "Enable Connected Transit on transit gateway deployed in Global Region"
  default = true
}

variable "bgp_manual_spoke_advertise_cidrs_china" {
  type = string
  description = "List of CIDRs to be advertised to on-premises via BGP from China Region. For example \"10.2.0.0/16,10.4.0.0/16\""
  default = null
}

variable "bgp_manual_spoke_advertise_cidrs_global" {
  type = string
  description = "List of CIDRs to be advertised to on-premises via BGP from China Region. For example \"10.2.0.0/16,10.4.0.0/16\""
  default = null
}

variable "bgp_polling_time_china" {
  type = number
  description = "BGP polling time in seconds for China Region between gateway and controller"
  default = 20
}

variable "bgp_polling_time_global" {
  type = number
  description = "BGP polling time in seconds for Global Region between gateway and controller"
  default = 20
}

variable "bgp_hold_time_china" {
  type = number
  description = "BGP hold time in seconds for China Region"
  default = 20
}

variable "bgp_hold_time_global" {
  type = number
  description = "BGP hold time in seconds for Global Region"
  default = 20
}

variable "prepend_as_path_china" {
  type = list(string)
  description = "Prepend AS Path for China Region"
  default = []
}

variable "prepend_as_path_global" {
  type = list(string)
  description = "Prepend AS Path for Global Region"
  default = []
}

variable "bgp_ecmp_china" {
  type = bool
  description = "Enable BGP ECMP for China Region"
  default = true
}

variable "bgp_ecmp_global" {
  type = bool
  description = "Enable BGP ECMP for Global Region"
  default = true
}

variable "enable_preserve_as_path_china" {
  type = bool
  description = "Enable Preserve AS Path for China Region"
  default = false
}

variable "enable_preserve_as_path_global" {
  type = bool
  description = "Enable Preserve AS Path for Global Region"
  default = false
}

variable "customized_spoke_vpc_routes_china" {
  type = string
  description = "A list of comma-separated CIDRs to be customized for the spoke VPC routes. When configured, it will replace all learned routes in VPC routing tables, including RFC1918 and non-RFC1918 CIDRs. It applies to all spoke gateways attached to this transit gateway. . For example \"10.0.0.0/16,10.2.0.0/16\""
  default = null
}

variable "customized_spoke_vpc_routes_global" {
  type = string
  description = "A list of comma-separated CIDRs to be customized for the spoke VPC routes. When configured, it will replace all learned routes in VPC routing tables, including RFC1918 and non-RFC1918 CIDRs. It applies to all spoke gateways attached to this transit gateway. . For example \"10.0.0.0/16,10.2.0.0/16\""
  default = null
}

variable "filtered_spoke_vpc_routes_china" {
  type = string
  description = "A list of comma-separated CIDRs to be filtered from the spoke VPC route table. When configured, filtering CIDR(s) or it’s subnet will be deleted from VPC routing tables as well as from spoke gateway’s routing table. It applies to all spoke gateways attached to this transit gateway.  For example \"10.2.0.0/16,10.3.0.0/16\""
  default = null
}

variable "filtered_spoke_vpc_routes_global" {
  type = string
  description = "A list of comma-separated CIDRs to be filtered from the spoke VPC route table. When configured, filtering CIDR(s) or it’s subnet will be deleted from VPC routing tables as well as from spoke gateway’s routing table. It applies to all spoke gateways attached to this transit gateway.  For example \"10.2.0.0/16,10.3.0.0/16\""
  default = null
}

variable "excluded_advertised_spoke_routes_china" {
  type = string
  description = "A list of comma-separated CIDRs to be advertised to on-prem as 'Excluded CIDR List'. When configured, it inspects all the advertised CIDRs from its spoke gateways and remove those included in the 'Excluded CIDR List'. Example: \"10.4.0.0/16,10.5.0.0/16\""
  default = null
}

variable "excluded_advertised_spoke_routes_global" {
  type = string
  description = "A list of comma-separated CIDRs to be advertised to on-prem as 'Excluded CIDR List'. When configured, it inspects all the advertised CIDRs from its spoke gateways and remove those included in the 'Excluded CIDR List'. Example: \"10.4.0.0/16,10.5.0.0/16\""
  default = null
}

variable "enable_learned_cidrs_approval_china" {
  type = bool
  description = "Switch to enable/disable encrypted transit approval for transit gateway."
  default = false
}

variable "enable_learned_cidrs_approval_global" {
  type = bool
  description = "Switch to enable/disable encrypted transit approval for transit gateway."
  default = false
}

variable "learned_cidrs_approval_mode_china" {
  type = string
  description = "Learned CIDRs approval mode. Either gateway (approval on a per gateway basis) or connection (approval on a per connection basis)."
  default = "gateway"

  validation {
    condition = can(regex("^(gateway|connection)$", var.learned_cidrs_approval_mode_china))
    error_message = "Invalid learned_cidrs_approval_mode_china. Valid values are gateway or connection."
  }
}

variable "learned_cidrs_approval_mode_global" {
  type = string
  description = "Learned CIDRs approval mode. Either gateway (approval on a per gateway basis) or connection (approval on a per connection basis)."
  default = "gateway"

  validation {
    condition = can(regex("^(gateway|connection)$", var.learned_cidrs_approval_mode_global))
    error_message = "Invalid learned_cidrs_approval_mode_global. Valid values are gateway or connection."
  }
}

variable "approved_learned_cidrs_china" {
  type = list(string)
  description = "A set of approved learned CIDRs. Only valid when enable_learned_cidrs_approval is set to true. Example: [\"10.250.0.0/16\", \"10.251.0.0/16\"]."
  default = []
}

variable "approved_learned_cidrs_global" {
  type = list(string)
  description = "A set of approved learned CIDRs. Only valid when enable_learned_cidrs_approval is set to true. Example: [\"10.250.0.0/16\", \"10.251.0.0/16\"]."
  default = []
}

variable "enable_vpc_dns_server_china" {
  type = bool
  description = "Enable VPC DNS Server for Gateway"
  default = false
}

variable "enable_vpc_dns_server_global" {
  type = bool
  description = "Enable VPC DNS Server for Gateway"
  default = false
}

variable "tunnel_detection_time_china" {
  type = number
  description = "The IPsec tunnel down detection time for the Transit Gateway in seconds. Must be a number in the range [20-600]. The default value is set by the controller (60 seconds if nothing has been changed)"
  default = 20
}

variable "tunnel_detection_time_global" {
  type = number
  description = "The IPsec tunnel down detection time for the Transit Gateway in seconds. Must be a number in the range [20-600]. The default value is set by the controller (60 seconds if nothing has been changed)"
  default = 20
}

variable "china_gw_tags" {
  type = map(string)
  description = "A mapping of tags to assign to the resource."
  default = {}
}

variable "global_gw_tags" {
  type = map(string)
  description = "A mapping of tags to assign to the resource."
  default = {}
}

variable "cen_name" {
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
  default = 100
}

variable "cen_bandwidth_limit" {
  type = number
  description = "Bandwidth allocated to the CEN from an existing CEN bandwidth package. Must be less than or equal to cen_bandwidth_package_bandwdith"
  default = 100
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
  default = 100
}

variable "cen_global_geo" {
  type = string
  description = "Name of the Geo where the global transit VPC connecting to CEN is deployed. Valid values are Nort-America, Asia-Pacific, Europe and Australia"
  validation {
    condition     = can(regex("^(North-America|Asia-Pacific|Europe|Australia)$", var.cen_global_geo))
    error_message = "Invalid value. Allowed values are: North-America, Asia-Pacific, Europe, Australia."
  }
}

variable "tunnel_supernet" {
  description = "/24 Supernet for tunnel IP addresses"
  type        = string
  default     = "169.254.0.0/28"
}

locals {
  tunnel_cidr_blocks = cidrsubnets(var.tunnel_supernet, 2, 2, 2, 2)
}