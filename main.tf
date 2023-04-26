# 1. Create Transit Gateways in China

module "controller-nsg" {
  source                             = "github.com/jocortems/aviatrix_alicloud_china_gateway_azure_controller_nsg"
  gateway_name                       = var.gateway_name
  gateway_region                     = var.alicloud_region_china
  controller_nsg_name                = var.controller_nsg_name
  controller_nsg_resource_group_name = var.controller_nsg_resource_group_name
  controller_nsg_rule_priority       = var.controller_nsg_rule_priority
  controller_subscription_name       = var.controller_subscription_name  
  ha_enabled                         = var.ha_enabled
}

module "mc-transit-ali" {
  source              = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version             = "2.3.2"
  name                = var.transit_vpc_name
  account             = var.controller_alicloud_account
  cloud               = "Ali"
  region              = var.aviatrix_alicloud_region
  az_support          = false
  enable_segmentation = var.enable_segmentation
  gw_name             = var.gateway_name
  insane_mode         = false
  cidr                = var.china_vpc_cidr
  ha_gw               = var.ha_enabled
  local_as_number     = var.china_gateway_bgp_asn
}


# 2. Create AliCloud CEN and Transit Routers

resource "alicloud_cen_instance" "cen" {
  cen_instance_name = var.alicloud_cen_name
  provider          = alicloud.global
}

# 2a. Retrieve Global Master and Slave Zones
data "alicloud_cen_transit_router_available_resources" "global" {
  provider   = alicloud.global
  depends_on = [alicloud_cen_instance.cen]
}

# 2b. Retrieve China Master and Slave Zones
data "alicloud_cen_transit_router_available_resources" "china" {
  provider   = alicloud.china
  depends_on = [alicloud_cen_instance.cen]
}

# 2c. Create vSwitch for Transit Router in Global Master Zone
resource "alicloud_vswitch" "global_master" {
  provider     = alicloud.global
  vswitch_name = format("%s-masterCENRouter", var.alicloud_cen_name)
  vpc_id       = var.global_vpc_id
  cidr_block   = cidrsubnet(var.global_vpc_cidr, 5, 4)
  zone_id      = data.alicloud_cen_transit_router_available_resources.global.resources[0].master_zones[0]
}

# 2d. Create vSwitch for Transit Router in Global Slave Zone
resource "alicloud_vswitch" "global_slave" {
  provider     = alicloud.global
  vswitch_name = format("%s-slaveCENRouter", var.alicloud_cen_name)
  vpc_id       = var.global_vpc_id
  cidr_block   = cidrsubnet(var.global_vpc_cidr, 5, 5)
  zone_id      = data.alicloud_cen_transit_router_available_resources.global.resources[0].slave_zones[1]
}

# 2e. Create vSwitch for Transit Router in China Master Zone
resource "alicloud_vswitch" "china_master" {
  provider     = alicloud.china
  vswitch_name = format("%s-masterCENRouter", var.alicloud_cen_name)
  vpc_id       = module.mc-transit-ali.vpc.vpc_id
  cidr_block   = cidrsubnet(module.mc-transit-ali.vpc.cidr, 5, 4)
  zone_id      = data.alicloud_cen_transit_router_available_resources.china.resources[0].master_zones[0]
}

# 2f. Create vSwitch for Transit Router China in Slave Zone
resource "alicloud_vswitch" "china_slave" {
  provider     = alicloud.china
  vswitch_name = format("%s-slaveCENRouter", var.alicloud_cen_name)
  vpc_id       = module.mc-transit-ali.vpc.vpc_id
  cidr_block   = cidrsubnet(module.mc-transit-ali.vpc.cidr, 5, 5)
  zone_id      = data.alicloud_cen_transit_router_available_resources.china.resources[0].slave_zones[1]
}


# 2g. Create CEN Transit Router in Region 1
resource "alicloud_cen_transit_router" "global_tr" {
  provider            = alicloud.global
  cen_id              = alicloud_cen_instance.cen.id
  transit_router_name = format("%s-globalCENRouter", var.alicloud_cen_name)  
}

# 2h. Create CEN Transit Router in Region 2 - wait for Transit Router Region 1 to be created to avoid blocking error
resource "alicloud_cen_transit_router" "china_tr" {
  provider            = alicloud.china
  depends_on          = [alicloud_cen_transit_router.global_tr]
  cen_id              = alicloud_cen_instance.cen.id
  transit_router_name = format("%s-chinaCENRouter", var.alicloud_cen_name)
}

# 3. Attach VPC to Transit Router
# 3a. Create VPC Attachment to Global Transit Router
resource "alicloud_cen_transit_router_vpc_attachment" "global" {
  provider                        = alicloud.global
  cen_id                          = alicloud_cen_instance.cen.id
  transit_router_id               = alicloud_cen_transit_router.global_tr.transit_router_id
  vpc_id                          = var.global_vpc_id
  transit_router_attachment_name  = format("%s-tr-global-attachment", var.alicloud_cen_name)

  zone_mappings {
    vswitch_id = alicloud_vswitch.global_master.id
    zone_id    = data.alicloud_cen_transit_router_available_resources.global.resources[0].master_zones[0]
  }
  zone_mappings {
    vswitch_id = alicloud_vswitch.global_slave.id
    zone_id    = data.alicloud_cen_transit_router_available_resources.global.resources[0].slave_zones[1]
  }  
}

# 3b. Create VPC Attachment to China Transit Router
resource "alicloud_cen_transit_router_vpc_attachment" "china" {
  provider                        = alicloud.china
  cen_id                          = alicloud_cen_instance.cen.id
  transit_router_id               = alicloud_cen_transit_router.china_tr.transit_router_id
  vpc_id                          = module.mc-transit-ali.vpc.vpc_id
  transit_router_attachment_name  = format("%s-tr-china-attachment", var.alicloud_cen_name)

  zone_mappings {
    vswitch_id = alicloud_vswitch.china_master.id
    zone_id    = data.alicloud_cen_transit_router_available_resources.china.resources[0].master_zones[0]
  }
  zone_mappings {
    vswitch_id = alicloud_vswitch.china_slave.id
    zone_id    = data.alicloud_cen_transit_router_available_resources.china.resources[0].slave_zones[1]
  }
}

# 4. Create and associate Route tables
# 4a. Create Transit Router Route Table in Global Region
resource "alicloud_cen_transit_router_route_table" "global_rtb" {
  provider                        = alicloud.global
  transit_router_id               = alicloud_cen_transit_router.global_tr.transit_router_id
  transit_router_route_table_name = format("%s-globalRT", var.alicloud_cen_name)  
}

# 4b. Create Transit Router Route Table in China Region
resource "alicloud_cen_transit_router_route_table" "china_rtb" {
  provider                        = alicloud.china
  transit_router_id               = alicloud_cen_transit_router.china_tr.transit_router_id
  transit_router_route_table_name = format("%s-chinaRT", var.alicloud_cen_name)  
}

# 4c. Create Intra-Region Route Table Association in Global Region
resource "alicloud_cen_transit_router_route_table_association" "global_rtb_association" {
  provider                      = alicloud.global
  depends_on                    = [alicloud_cen_transit_router_peer_attachment.global_to_china]
  transit_router_route_table_id = alicloud_cen_transit_router_route_table.global_rtb.transit_router_route_table_id
  transit_router_attachment_id  = alicloud_cen_transit_router_vpc_attachment.global.transit_router_attachment_id  
}

# 4d. Create Intra-Region Route Table Association in China Region
resource "alicloud_cen_transit_router_route_table_association" "china_rtb_association" {
  provider                      = alicloud.china
  depends_on                    = [alicloud_cen_transit_router_peer_attachment.global_to_china]
  transit_router_route_table_id = alicloud_cen_transit_router_route_table.china_rtb.transit_router_route_table_id
  transit_router_attachment_id  = alicloud_cen_transit_router_vpc_attachment.china.transit_router_attachment_id
}

# 4e. Create Intra-Region Route Table Propagation in Global Region
resource "alicloud_cen_transit_router_route_table_propagation" "global_rtb_propagation" {
  provider                      = alicloud.global
  depends_on                    = [alicloud_cen_transit_router_peer_attachment.global_to_china]
  transit_router_route_table_id = alicloud_cen_transit_router_route_table.global_rtb.transit_router_route_table_id
  transit_router_attachment_id  = alicloud_cen_transit_router_vpc_attachment.global.transit_router_attachment_id
}

# 4f. Create Intra-Region Route Table Propagation in China Region
resource "alicloud_cen_transit_router_route_table_propagation" "china_rtb_propagation" {
  provider                      = alicloud.china
  depends_on                    = [alicloud_cen_transit_router_peer_attachment.global_to_china]
  transit_router_route_table_id = alicloud_cen_transit_router_route_table.china_rtb.transit_router_route_table_id
  transit_router_attachment_id  = alicloud_cen_transit_router_vpc_attachment.china.transit_router_attachment_id
}


# 5. Allocate Bandwidth to the CEN
# 5a. Create Bandwidth Package Plan and Associate with CEN
resource "alicloud_cen_bandwidth_package" "cen_bandwidth_package" {
  count                      = var.cen_bandwidth_package_name == null ? 0 : 1
  provider                   = alicloud.global
  cen_bandwidth_package_name = var.cen_bandwidth_package_name  
  bandwidth                  = var.cen_bandwidth_package_bandwdith
  period                     = var.cen_bandwidth_package_period
  geographic_region_a_id     = var.alicloud_cen_global_geo
  geographic_region_b_id     = "China"
}

#5b. Attach the bandwidth package to the CEN
resource "alicloud_cen_bandwidth_package_attachment" "cen_bandwidth_package_attachment" {
  count                = var.cen_bandwidth_package_id == null || var.cen_bandwidth_package_name == null  ? 0 : 1
  provider             = alicloud.global
  instance_id          = alicloud_cen_instance.cen.id
  bandwidth_package_id = var.cen_bandwidth_package_name == null ? var.cen_bandwidth_package_id : alicloud_cen_bandwidth_package.cen_bandwidth_package[0].id
}

#5c. Assign a bandwidth limit from the bandwidth package to the CEN
resource "alicloud_cen_bandwidth_limit" "cen_bandwidth_limit" {
  count       = var.cen_bandwidth_package_id == null || var.cen_bandwidth_package_name == null  ? 0 : 1
  provider    = alicloud.global
  instance_id = alicloud_cen_instance.cen.id
  region_ids  = [
    var.alicloud_region_china,
    var.alicloud_region_global,
  ]
  bandwidth_limit = var.cen_bandwidth_limit
  depends_on = [
    alicloud_cen_bandwidth_package_attachment.cen_bandwidth_package_attachment[0],
    alicloud_cen_transit_router_vpc_attachment.global,
    alicloud_cen_transit_router_vpc_attachment.china,
  ]
}

# 6. Create Cross-Region Connections
# 6a. Peer Global and China transit routers
resource "alicloud_cen_transit_router_peer_attachment" "global_to_china" {
  provider                       = alicloud.global
  cen_id                         = alicloud_cen_instance.cen.id
  transit_router_id              = alicloud_cen_transit_router.global_tr.transit_router_id
  peer_transit_router_region_id  = var.alicloud_region_china
  peer_transit_router_id         = alicloud_cen_transit_router.china_tr.transit_router_id
  cen_bandwidth_package_id       = var.cen_bandwidth_type == "DataTransfer" ? null : var.cen_bandwidth_package_id != null ? var.cen_bandwidth_package_id : alicloud_cen_bandwidth_package.cen_bandwidth_package[0].id
  bandwidth                      = var.cen_transit_router_peer_attachment_bandwidth_limit
  bandwidth_type                 = var.cen_bandwidth_type
  transit_router_attachment_name = "${var.alicloud_region_global}-to-${var.alicloud_region_china}"

  auto_publish_route_enabled      = true
  route_table_association_enabled = false
  route_table_propagation_enabled = false

  timeouts {
    create = "5m"
    delete = "5m"
    update = "5m"
  }  
}

# 6b. Create Cross-Region Route Table Association in Global Region
resource "alicloud_cen_transit_router_route_table_association" "global_xregion_rtb_association" {
  provider                      = alicloud.global
  depends_on                    = [alicloud_cen_transit_router_vpc_attachment.global]
  transit_router_route_table_id = alicloud_cen_transit_router_route_table.global_rtb.transit_router_route_table_id
  transit_router_attachment_id  = alicloud_cen_transit_router_peer_attachment.global_to_china.transit_router_attachment_id  
}

# 6c. Create Cross-Region Route Table Association in China Region
resource "alicloud_cen_transit_router_route_table_association" "china_xregion_rtb_association" {
  provider                      = alicloud.china
  depends_on                    = [alicloud_cen_transit_router_vpc_attachment.china]
  transit_router_route_table_id = alicloud_cen_transit_router_route_table.china_rtb.transit_router_route_table_id
  transit_router_attachment_id  = alicloud_cen_transit_router_peer_attachment.global_to_china.transit_router_attachment_id  
}

# 6d. Create Cross-Region Route Table Propagation in Global Region
resource "alicloud_cen_transit_router_route_table_propagation" "global_xregion_rtb_propagation" {
  provider                      = alicloud.global
  depends_on                    = [alicloud_cen_transit_router_vpc_attachment.global]
  transit_router_route_table_id = alicloud_cen_transit_router_route_table.global_rtb.transit_router_route_table_id
  transit_router_attachment_id  = alicloud_cen_transit_router_peer_attachment.global_to_china.transit_router_attachment_id
}

# 6e. Create Cross-Region Route Table Propagation in China Region
resource "alicloud_cen_transit_router_route_table_propagation" "china_xregion_rtb_propagation" {
  provider                      = alicloud.china
  depends_on                    = [alicloud_cen_transit_router_vpc_attachment.china]
  transit_router_route_table_id = alicloud_cen_transit_router_route_table.china_rtb.transit_router_route_table_id
  transit_router_attachment_id  = alicloud_cen_transit_router_peer_attachment.global_to_china.transit_router_attachment_id
}

# 6f. Retrieve Transit VPC Route Table in Global Region
data "alicloud_route_tables" "global_transit_rtb" {
  provider = alicloud.global
  vpc_id   = var.global_vpc_id
}

# 6g. Retrieve Transit VPC Route Table in China Region
data "alicloud_route_tables" "china_transit_rtb" {
  provider = alicloud.china
  vpc_id   = module.mc-transit-ali.vpc.vpc_id  
}

# 6h. Create Route from Transit VPC Global Region to Transit VPC China Region
resource "alicloud_route_entry" "global_to_china" {
  provider              = alicloud.global
  depends_on            = [alicloud_cen_transit_router_peer_attachment.global_to_china]
  route_table_id        = data.alicloud_route_tables.global_transit_rtb.tables[0].route_table_id
  destination_cidrblock = var.china_vpc_cidr
  nexthop_type          = "Attachment" # Transit Router
  nexthop_id            = alicloud_cen_transit_router_vpc_attachment.global.transit_router_attachment_id
}

# 6i. Create Route from Transit VPC China Region to Transit VPC Global Region
resource "alicloud_route_entry" "china_to_global" {
  provider              = alicloud.china
  depends_on            = [alicloud_cen_transit_router_peer_attachment.global_to_china]
  route_table_id        = data.alicloud_route_tables.china_transit_rtb.tables[0].route_table_id
  destination_cidrblock = var.global_vpc_cidr
  nexthop_type          = "Attachment" # Transit Router
  nexthop_id            = alicloud_cen_transit_router_vpc_attachment.china.transit_router_attachment_id  
}


#7. Create Aviatrix S2C Configuration on China Transit to Global Transit

resource "aviatrix_transit_external_device_conn" "china_to_global" {
  depends_on = [
    alicloud_cen_transit_router_peer_attachment.global_to_china
  ]
  vpc_id            = module.mc-transit-ali.vpc.vpc_id
  connection_name   = "${var.alicloud_region_china}-to-${var.alicloud_region_global}"
  gw_name           = module.mc-transit-ali.transit_gateway.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "IPSec"
  pre_shared_key    = var.pre_shared_key
  direct_connect    = true
  remote_gateway_ip = var.global_transitgw_private_ip
  bgp_local_as_num  = module.mc-transit-ali.transit_gateway.local_as_number
  bgp_remote_as_num = var.global_transit_bgp_asn

  ha_enabled               = var.ha_enabled ? true : false
  backup_pre_shared_key    = var.ha_enabled ? var.pre_shared_key : null
  backup_direct_connect    = var.ha_enabled ? true : false
  backup_remote_gateway_ip = var.ha_enabled ? var.global_transitgw_hagw_private_ip : null
  backup_bgp_remote_as_num = var.ha_enabled ? var.global_transit_bgp_asn : null

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

#8 Create EIP Bandwidth plans and associate with Aviatrix Transit Gateways Public IP addresses to overcome limit of 200Mbps
#8a. Create EIP Bandwidth Plan in China Region
resource "alicloud_common_bandwidth_package" "alicloud_china_eip_bandwidth_plan" {
  count                  = var.alicloud_china_eip_bandwidth_plan_name == null ? 0: 1
  provider               = alicloud.china
  bandwidth              = var.alicloud_china_eip_bandwidth_plan_bandwidth
  internet_charge_type   = "PayByTraffic"
  bandwidth_package_name = var.alicloud_china_eip_bandwidth_plan_name
  description            = "Bandwidth Package Associated with Aviatrix Transit EIPs in ${var.alicloud_region_china}"
}

#8b. Create EIP Bandwidth Plan in Global Region
resource "alicloud_common_bandwidth_package" "alicloud_global_eip_bandwidth_plan" {
  count                  = var.alicloud_global_eip_bandwidth_plan_name == null ? 0: 1
  provider               = alicloud.global
  bandwidth              = var.alicloud_global_eip_bandwidth_plan_bandwidth
  internet_charge_type   = "PayByTraffic"
  bandwidth_package_name = var.alicloud_global_eip_bandwidth_plan_name
  description            = "Bandwidth Package Associated with Aviatrix Transit EIPs in ${var.alicloud_region_global}"
}

#8c. Associate EIP Bandwidth Plan in China with Aviatrix Transit Gateways in China Public IP addresses
resource "alicloud_common_bandwidth_package_attachment" "avx_china_gateway" {
  count                = var.alicloud_china_eip_bandwidth_plan_name == null ? 0: 1
  provider             = alicloud.china
  bandwidth_package_id = alicloud_common_bandwidth_package.alicloud_china_eip_bandwidth_plan[0].id
  instance_id          = module.controller-nsg.gateway_eip_id
}

resource "alicloud_common_bandwidth_package_attachment" "avx_china_gatewayha" {
  count                = var.ha_enabled ? var.alicloud_china_eip_bandwidth_plan_name != null ? 1 : 0 : 0
  provider             = alicloud.china
  bandwidth_package_id = alicloud_common_bandwidth_package.alicloud_china_eip_bandwidth_plan[0].id
  instance_id          = module.controller-nsg.gatewayha_eip_id
}

#8d. Associate EIP Bandwidth Plan in Global with Aviatrix Transit Gateways in Global Public IP addresses

resource "alicloud_common_bandwidth_package_attachment" "avx_global_gateway" {
  count                = var.alicloud_global_eip_bandwidth_plan_name == null ? 0: 1
  provider             = alicloud.global
  bandwidth_package_id = alicloud_common_bandwidth_package.alicloud_global_eip_bandwidth_plan[0].id
  instance_id          = var.global_transit_gw_eip_id
}

resource "alicloud_common_bandwidth_package_attachment" "avx_global_gatewayha" {
  count                = var.ha_enabled ? var.alicloud_global_eip_bandwidth_plan_name != null ? 1 : 0 : 0
  provider             = alicloud.global
  bandwidth_package_id = alicloud_common_bandwidth_package.alicloud_global_eip_bandwidth_plan[0].id
  instance_id          = var.global_transit_hagw_eip_id
}