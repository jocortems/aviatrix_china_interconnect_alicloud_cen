# 1. Create Transit Gateway in China Region
# 1a. Create VPC in China Region

resource "aviatrix_vpc" "china_vpc" {
  provider             = aviatrix.china
  cloud_type           = 8192
  account_name         = var.china_controller_account_name
  region               = var.gw_china_region
  name                 = var.china_transit_vpc_name
  cidr                 = var.china_vpc_cidr
  aviatrix_transit_vpc = true
}

# 1b. Create the gateways

module "controller-nsg" {
  providers = {
    alicloud.china = alicloud.china
  }  
  source                             = "github.com/jocortems/aviatrix_alicloud_china_gateway_azure_controller_nsg"
  gateway_name                       = var.china_gateway_name
  controller_nsg_name                = var.controller_nsg_name
  controller_nsg_resource_group_name = var.controller_nsg_resource_group_name
  controller_nsg_rule_priority       = var.controller_nsg_rule_priority  
  ha_enabled                         = var.ha_enabled
}

resource "aviatrix_transit_gateway" "china" {
  provider                          = aviatrix.china
  cloud_type                        = 8192
  account_name                      = var.china_controller_account_name
  gw_name                           = var.china_gateway_name == null ? var.china_transit_vpc_name : var.china_gateway_name
  vpc_id                            = aviatrix_vpc.china_vpc.vpc_id
  vpc_reg                           = aviatrix_vpc.china_vpc.region
  gw_size                           = var.china_gateway_size
  subnet                            = aviatrix_vpc.china_vpc.public_subnets[0].cidr
  ha_subnet                         = var.ha_enabled ? aviatrix_vpc.china_vpc.public_subnets[1].cidr : null
  ha_gw_size                        = var.ha_enabled ? var.china_gateway_size : null
  enable_segmentation               = var.enable_segmentation_china
  connected_transit                 = var.connected_transit_china
  bgp_manual_spoke_advertise_cidrs  = var.bgp_manual_spoke_advertise_cidrs_china
  bgp_polling_time                  = var.bgp_polling_time_china
  bgp_hold_time                     = var.bgp_hold_time_china
  prepend_as_path                   = var.prepend_as_path_china
  local_as_number                   = var.china_gateway_bgp_asn
  bgp_ecmp                          = var.bgp_ecmp_china
  enable_preserve_as_path           = var.enable_preserve_as_path_china
  customized_spoke_vpc_routes       = var.customized_spoke_vpc_routes_china
  filtered_spoke_vpc_routes         = var.filtered_spoke_vpc_routes_china
  excluded_advertised_spoke_routes   = var.excluded_advertised_spoke_routes_china
  enable_learned_cidrs_approval     = var.enable_learned_cidrs_approval_china
  learned_cidrs_approval_mode       = var.learned_cidrs_approval_mode_china
  approved_learned_cidrs            = var.approved_learned_cidrs_china
  enable_vpc_dns_server             = var.enable_vpc_dns_server_china
  tunnel_detection_time             = var.tunnel_detection_time_china
  tags                              = var.china_gw_tags
}

# 2. Create Transit Gateway in Global Region
# 2a. Create VPC in Global Region
resource "aviatrix_vpc" "global_vpc" {
  provider              = aviatrix.global
  cloud_type            = 8192
  account_name          = var.global_controller_account_name
  region                = var.gw_global_region
  name                  = var.global_transit_vpc_name
  cidr                  = var.global_vpc_cidr
  aviatrix_transit_vpc  = true
}

# 1b. Create the gateways
resource "aviatrix_transit_gateway" "global" {
  provider                         = aviatrix.global
  cloud_type                       = 8192
  account_name                     = var.global_controller_account_name
  gw_name                          = var.global_gateway_name == null ? var.global_transit_vpc_name : var.global_gateway_name
  vpc_id                           = aviatrix_vpc.global_vpc.vpc_id
  vpc_reg                          = aviatrix_vpc.global_vpc.region
  gw_size                          = var.global_gateway_size
  subnet                           = aviatrix_vpc.global_vpc.public_subnets[0].cidr
  ha_subnet                        = var.ha_enabled ? aviatrix_vpc.global_vpc.public_subnets[1].cidr : null
  ha_gw_size                       = var.ha_enabled ? var.global_gateway_size : null
  enable_segmentation              = var.enable_segmentation_global
  connected_transit                = var.connected_transit_global
  bgp_manual_spoke_advertise_cidrs = var.bgp_manual_spoke_advertise_cidrs_global
  bgp_polling_time                 = var.bgp_polling_time_global
  bgp_hold_time                    = var.bgp_hold_time_global
  prepend_as_path                  = var.prepend_as_path_global
  local_as_number                  = var.global_gateway_bgp_asn
  bgp_ecmp                         = var.bgp_ecmp_global
  enable_preserve_as_path          = var.enable_preserve_as_path_global
  customized_spoke_vpc_routes      = var.customized_spoke_vpc_routes_global
  filtered_spoke_vpc_routes        = var.filtered_spoke_vpc_routes_global
  excluded_advertised_spoke_routes  = var.excluded_advertised_spoke_routes_global
  enable_learned_cidrs_approval    = var.enable_learned_cidrs_approval_global
  learned_cidrs_approval_mode      = var.learned_cidrs_approval_mode_global
  approved_learned_cidrs           = var.approved_learned_cidrs_global
  enable_vpc_dns_server            = var.enable_vpc_dns_server_global
  tunnel_detection_time            = var.tunnel_detection_time_global
  tags                             = var.global_gw_tags
}

module "cen" {
    providers = {
      alicloud.china = alicloud.china
      alicloud.global = alicloud.global
    }
    source = "github.com/jocortems/alicloud_cen_deploy"
    ali_china_region                                    = var.ali_china_region
    ali_global_region                                   = var.ali_global_region
    china_vpc_cidr                                      = var.china_vpc_cidr
    global_vpc_cidr                                     = var.global_vpc_cidr
    china_vpc_id                                        = aviatrix_vpc.china_vpc.vpc_id
    global_vpc_id                                       = aviatrix_vpc.global_vpc.vpc_id
    cen_name                                            = var.cen_name
    cen_global_geo                                      = var.cen_global_geo    
    cen_bandwidth_type                                  = var.cen_bandwidth_type
    cen_bandwidth_package_name                          = var.cen_bandwidth_package_name
    cen_bandwidth_package_bandwdith                     = var.cen_bandwidth_package_bandwdith
    cen_bandwidth_limit                                 = var.cen_bandwidth_limit
    cen_bandwidth_package_period                        = var.cen_bandwidth_package_period
    cen_bandwidth_package_id                            = var.cen_bandwidth_package_id
    cen_transit_router_peer_attachment_bandwidth_limit  = var.cen_transit_router_peer_attachment_bandwidth_limit
}

resource "aviatrix_transit_external_device_conn" "china_to_global" {
  provider          = aviatrix.china
  vpc_id            = aviatrix_vpc.china_vpc.vpc_id
  connection_name   = "${var.ali_china_region}-to-${var.ali_global_region}"
  gw_name           = aviatrix_transit_gateway.china.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "IPSec"
  pre_shared_key    = var.pre_shared_key
  direct_connect    = true
  remote_gateway_ip = aviatrix_transit_gateway.global.private_ip
  bgp_local_as_num  = aviatrix_transit_gateway.china.local_as_number
  bgp_remote_as_num = aviatrix_transit_gateway.global.local_as_number

  ha_enabled               = var.ha_enabled ? true : false
  backup_pre_shared_key    = var.ha_enabled ? var.pre_shared_key : null
  backup_direct_connect    = var.ha_enabled ? true : false
  backup_remote_gateway_ip = var.ha_enabled ? aviatrix_transit_gateway.global.ha_private_ip : null
  backup_bgp_remote_as_num = var.ha_enabled ? aviatrix_transit_gateway.global.local_as_number : null

  local_tunnel_cidr         = var.ha_enabled ? "${cidrhost(local.tunnel_cidr_blocks[0], 1)}/30,${cidrhost(local.tunnel_cidr_blocks[1], 1)}/30" : "${cidrhost(local.tunnel_cidr_blocks[0], 1)}/30"
  remote_tunnel_cidr        = var.ha_enabled ? "${cidrhost(local.tunnel_cidr_blocks[0], 2)}/30,${cidrhost(local.tunnel_cidr_blocks[1], 2)}/30" : "${cidrhost(local.tunnel_cidr_blocks[0], 2)}/30"
  backup_local_tunnel_cidr  = var.ha_enabled ? "${cidrhost(local.tunnel_cidr_blocks[2], 1)}/30,${cidrhost(local.tunnel_cidr_blocks[3], 1)}/30" : null
  backup_remote_tunnel_cidr = var.ha_enabled ? "${cidrhost(local.tunnel_cidr_blocks[2], 2)}/30,${cidrhost(local.tunnel_cidr_blocks[3], 2)}/30" : null

  enable_ikev2           = true
  custom_algorithms      = true
  phase_1_authentication = "SHA-256"
  phase_2_authentication = "NO-AUTH"
  phase_1_dh_groups      = "14"
  phase_2_dh_groups      = "14"
  phase_1_encryption     = "AES-256-CBC"
  phase_2_encryption     = "AES-256-GCM-128"
}

resource "aviatrix_transit_external_device_conn" "global_to_china" {
  provider          = aviatrix.global
  vpc_id            = aviatrix_vpc.global_vpc.vpc_id
  connection_name   = "${var.ali_global_region}-to-${var.ali_china_region}"
  gw_name           = aviatrix_transit_gateway.global.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "IPSec"
  pre_shared_key    = var.pre_shared_key
  direct_connect    = true
  remote_gateway_ip = aviatrix_transit_gateway.china.private_ip
  bgp_local_as_num  = aviatrix_transit_gateway.global.local_as_number
  bgp_remote_as_num = aviatrix_transit_gateway.china.local_as_number

  ha_enabled               = var.ha_enabled ? true : false
  backup_pre_shared_key    = var.ha_enabled ? var.pre_shared_key : null
  backup_direct_connect    = var.ha_enabled ? true : false
  backup_remote_gateway_ip = var.ha_enabled ? aviatrix_transit_gateway.china.ha_private_ip : null
  backup_bgp_remote_as_num = var.ha_enabled ? aviatrix_transit_gateway.china.local_as_number : null

  local_tunnel_cidr         = var.ha_enabled ? "${cidrhost(local.tunnel_cidr_blocks[0], 2)}/30,${cidrhost(local.tunnel_cidr_blocks[3], 2)}/30" : "${cidrhost(local.tunnel_cidr_blocks[0], 2)}/30"
  remote_tunnel_cidr        = var.ha_enabled ? "${cidrhost(local.tunnel_cidr_blocks[0], 1)}/30,${cidrhost(local.tunnel_cidr_blocks[3], 1)}/30" : "${cidrhost(local.tunnel_cidr_blocks[0], 1)}/30"
  backup_local_tunnel_cidr  = var.ha_enabled ? "${cidrhost(local.tunnel_cidr_blocks[2], 2)}/30,${cidrhost(local.tunnel_cidr_blocks[1], 2)}/30" : null
  backup_remote_tunnel_cidr = var.ha_enabled ? "${cidrhost(local.tunnel_cidr_blocks[2], 1)}/30,${cidrhost(local.tunnel_cidr_blocks[1], 1)}/30" : null

  enable_ikev2           = true
  custom_algorithms      = true
  phase_1_authentication = "SHA-256"
  phase_2_authentication = "NO-AUTH"
  phase_1_dh_groups      = "14"
  phase_2_dh_groups      = "14"
  phase_1_encryption     = "AES-256-CBC"
  phase_2_encryption     = "AES-256-GCM-128"
}