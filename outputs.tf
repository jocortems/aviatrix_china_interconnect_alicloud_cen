output "china_vpc" {
    value = aviatrix_vpc.china_vpc
}

output "global_vpc" {
    value = aviatrix_vpc.global_vpc
}

output "china_gateway" {
    value = aviatrix_transit_gateway.china
}

output "global_gateway" {
    value = aviatrix_transit_gateway.global
}

output "cen" {
    value = module.cen.cen_instance
}

output "cen_bandwidth_package" {
    value = module.cen.cen_bandwidth_package
}

output "cen_global_transit_router" {
    value = module.cen.cen_global_transit_router
}

output "cen_china_transit_router" {
    value = module.cen.cen_china_transit_router
}

output "cen_china_transit_router_route_table" {
    value = module.cen.cen_china_transit_router_route_table
}

output "cen_global_transit_router_route_table" {
    value = module.cen.cen_global_transit_router_route_table
}

output "gateway_address" {
  value = var.cen_instance_id == null ? null : module.controller-nsg[0].gateway_address
}

output "gatewayha_address" {
  value = var.cen_instance_id == null ? null : module.controller-nsg[0].gatewayha_address
}
