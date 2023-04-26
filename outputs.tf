output "avx_china_gw_private_ip" {
  description = "Private IP address of the Avaitrix Transit Primary GW in China. This will be used to terminate the S2C tunnel from the Transti Gateways in Global over CEN"
  value = module.mc-transit-ali.transit_gateway.private_ip
}

output "avx_china_hagw_private_ip" {
  description = "Private IP address of the Avaitrix Transit HA GW in China. This will be used to terminate the S2C tunnel from the Transti Gateways in Global over CEN"
  value = module.mc-transit-ali.transit_gateway.ha_private_ip
}

output "avx_global_transit_s2c_local_tunnel_cidr" {
  description = "S2C BGP Local Tunnel Configuration in Global Aviatrix Transit"
  value = var.ha_enabled ? "${cidrhost(local.tunnel_cidr_blocks[0], 2)}/30,${cidrhost(local.tunnel_cidr_blocks[2], 2)}/30" : "${cidrhost(local.tunnel_cidr_blocks[0], 2)}/30"
}

output "avx_global_transit_s2c_remote_tunnel_cidr" {
  description = "S2C BGP Remote Tunnel Configuration in Global Aviatrix Transit"
  value = var.ha_enabled ? "${cidrhost(local.tunnel_cidr_blocks[0], 1)}/30,${cidrhost(local.tunnel_cidr_blocks[2], 1)}/30" : "${cidrhost(local.tunnel_cidr_blocks[0], 1)}/30"
}

output "avx_global_transit_s2c_backup_local_tunnel_cidr" {
  description = "S2C BGP Local Backup Tunnel Configuration in Global Aviatrix Transit"
  value = var.ha_enabled ? "${cidrhost(local.tunnel_cidr_blocks[1], 2)}/30,${cidrhost(local.tunnel_cidr_blocks[3], 2)}/30" : null
}

output "avx_global_transit_s2c_backup_remote_tunnel_cidr" {
  description = "S2C BGP Remote Backup Tunnel Configuration in Global Aviatrix Transit"
  value = var.ha_enabled ? "${cidrhost(local.tunnel_cidr_blocks[1], 1)}/30,${cidrhost(local.tunnel_cidr_blocks[3], 1)}/30" : null
}

output "alicloud_china_eip_bandwidth_plan" {
  description = "EIP Bandwidth plan created for China Region. Create an association for the EIP of the Aviatrix transit in Global Region with this plan"
  value = var.alicloud_china_eip_bandwidth_plan_name == null ? null : alicloud_common_bandwidth_package.alicloud_china_eip_bandwidth_plan[0].id
}

output "alicloud_global_eip_bandwidth_plan" {
  description = "EIP Bandwidth plan created for Global Region. Create an association for the EIP of the Aviatrix transit in Global Region with this plan"
  value = var.alicloud_global_eip_bandwidth_plan_name == null ? null : alicloud_common_bandwidth_package.alicloud_global_eip_bandwidth_plan[0].id
}

output "alicloud_china_transit_bgp_asn" {
  description = "BGP ASN configured on the Aviatrix Transit Gateway Deployed in AliCloud China"
  value = module.mc-transit-ali.transit_gateway.local_as_number
}