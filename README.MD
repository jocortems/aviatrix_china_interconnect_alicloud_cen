# Aviatrix China and Global Interconnection Using AliCloud CEN

## Description

### Note:

This Terraform module interconnects an existing Aviatrix Transit Network deployed in AliCloud regions outside of China with an Aviatrix Transit Network deployed in AliCloud regions in China using Aviatrix Site to Cloud IPSec VPN.

This Terraform module:

- Is limited to Controllers deployed in Azure China
- Creates one Transit VPC and Aviatrix Transit Gateways in a region in AliCloud China
- Creates two vSwitches in the existing Transit VPC deployed in AliCloud Global region that will be used to interconnect with China, one for each CEN Transit Router Zone
- Creates an AliCloud CEN instance and transit routers in the China and Global regions that will be interconnected
- Attaches the existing Transit VPC deployed in AliCloud Global region and the Transit VPC in AliCloud China region to the CEN transit routers in their respective regions
- Creates the required route table artifacts to achieve communication between the Transit VPCs across the regions
- Creates a Site-to-Cloud connection on the Aviatrix Transit Gateways deployed in China region
- CEN Inter-region connection pricing defaults to Pay-by-data-transfer 
- Optionally, it creates a CEN Bandwidth package, or uses an existing CEN Bandwidth package if one is specified
- Optionally, it creates an EIP Bandwidth plan in China and Global regions, and attaches the Aviatrix Transit Gateways EIPs in China region to the EIP Bandwidth plan in China region
- Adds one or two security rules to the existing NSG associated with an Azure Controller deployed in China, depending on whether the Gateways are deployed in HA or not


## Prerequisites

1. [Terraform v0.13+](https://www.terraform.io/downloads.html) - execute terraform files


## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.52 |
| <a name="provider_alicloud"></a> [alicloud](#provider\_alicloud) | ~> 1.203.0 |
| <a name="provider_aviatrix"></a> [aviatrix](#provider\_aviatrix) | ~> 2.24.3 |


## Available Modules

Module  | Description |
| ------- | ----------- |
| [aviatrix_alicloud_china_gateway_azure_controller_nsg](https://github.com/jocortems/aviatrix_alicloud_china_gateway_azure_controller_nsg) | Automates the creation of NSG rules in the NSG attached to an Aviatrix Controller deployed in Azure China for Aviatrix Gateways deployed in AliCloud in China regions |
| [mc-transit](https://registry.terraform.io/modules/terraform-aviatrix-modules/mc-transit/aviatrix/latest) | Aviatrix Terraform module for transit deployment in multiple clouds |


## Procedures for Running This Module

### 1. Authenticating to Azure

Set the environment in Azure CLI to Azure China:

```shell
az cloud set -n AzureChinaCloud
```

Login to the Azure CLI using:

```shell
az login --use-device-code
````
*Note: Please refer to the [documentation](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs#authenticating-to-azure-active-directory) for different methods of authentication to Azure, incase above command is not applicable.*

Pick the subscription you want and use it in the command below.

```shell
az account set --subscription <subscription_id>
```

Set environment variables ARM_ENDPOINT and ARM_ENVIRONMENT to use Azure China endpoints:

  ``` shell
  export ARM_ENDPOINT=https://management.chinacloudapi.cn
  export ARM_ENVIRONMENT=china
  ```

If executing this code from a CI/CD pipeline, the following environment variables are required. The service principal used to authenticate the CI/CD tool into Azure must either have subscription owner role or a custom role that has `Microsoft.Authorization/roleAssignments/write` to be able to succesfully create the role assignments required

``` shell
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
```

### 2. Authenticating to AliCloud

Set environment variables ALICLOUD_ACCESS_KEY and ALICLOUD_SECRET_KEY:

  ``` shell
  export ALICLOUD_ACCESS_KEY="anaccesskey"
  export ALICLOUD_SECRET_KEY="asecretkey"
  ```


### 3. Applying Terraform configuration

```hcl

module "aviatrix-cen-interconnect" {
    source                                             = "github.com/jocortems/aviatrix_alicloud_china_global_cen_interconnect"
    controller_alicloud_account                        = "alicloud-account"              # Required. Name of the China AliCloud account onboarded to the controller
    aviatrix_alicloud_region                           = "acs-cn-beijing (Beijing)"      # Required. Display Name of the China AliCloud region in the Aviatrix Controller
    china_vpc_cidr                                     = "172.18.2.0/23"                 # Required. CIDR used for the Transit VPC to be created in China Region
    gateway_name                                       = "avx-cn-transit-gw"             # Required. Name of the Transit Gateways to be created in China Region
    transit_vpc_name                                   = "avx-cn-transit-vpc"            # Required. Name of the Transit VPC to be created in China Region
    alicloud_region_china                              = "cn-beijing"                    # Required. AliCloud China Region ID - https://www.alibabacloud.com/help/en/basics-for-beginners/latest/regions-and-zones
    alicloud_region_global                             = "ap-southeast-1"                # Required. AliCloud Global Region ID - https://www.alibabacloud.com/help/en/basics-for-beginners/latest/regions-and-zones
    controller_nsg_name                                = "controllerha-nsg"              # Required. Name of the NSG associated with the Controller
    controller_nsg_resource_group_name                 = "avtx-controller"               # Required. Name of the resource group where the NSG associated with the controller is deployed
    controller_nsg_rule_priority                       = 400                             # Required. This number must be unique. Before running this module verify the priority number is available in the NSG associated with the Controller
    controller_subscription_name                       = "Windows Azure Enterprise"      # Optional. Defaults to the current subscription ID of the logged in user
    ha_enabled                                         = true/false                      # Optiona. Defaults to true. Must match HA deployment of Transit Gateway in AliCloud Global Region
    enable_segmentation                                = true/false                      # Optional. Defaults to false    
    global_vpc_id                                      = "vpc-abcd1234xxxx"              # Required. VPC ID of the existing Transit VPC deployed in AliCloud Global region
    global_transitgw_private_ip                        = "172.18.0.2"                    # Required. Private IP Address of the Primary Transit Gateway in AliCloud Global region
    global_transitgw_hagw_private_ip                   = "172.18.0.3"                    # Required. Private IP Address of the HA Transit Gateway in AliCloud Global region
    global_vpc_cidr                                    = "172.18.0.0/23"                 # Required. CIDR of the existing Transit VPC in AliCloud Global region
    alicloud_cen_global_geo                            = "Asia-Pacific"                  # Required. AliCloud Region where the Global Transit VPC is Deployed. Valid values are North-America, Asia-Pacific, Europe and Australia
    alicloud_cen_name                                  = "avx-cen"                       # Required. Name of the CEN instance to be created  
    cen_bandwidth_type                                 = DataTransfer/BandwidthPackage   # Optional. Defaults to DataTransfer. If BandwidthPackage is selected need to specify one of cen_bandwidth_package_name or cen_bandwidth_package_id
    cen_bandwidth_package_name                         =                                 # Optional. If specified, creates a CEN bandwidth package. Make sure you understand the limitations when creating a CEN Bandwidth Package
    cen_bandwidth_package_bandwdith                    = 0                               # Optional. Only needed if cen_bandwidth_package_name is specified
    cen_bandwidth_limit =                                                                # Optional. Only needed if using a CEN bandwidth package (cen_bandwidth_package_name or cen_bandwidth_package_id are defined)
    cen_bandwidth_package_period                       = 1                               # Optional. Only needed if cen_bandwidth_package_name is specified. Prepaid purchase period in months (1,2,3,6,12)
    cen_bandwidth_package_id                           =                                 # Optional. Only needed if an existing CEN bandwidth package will be used
    cen_transit_router_peer_attachment_bandwidth_limit = 2                               # Required. Defaults to 2Mbps. If using a CEN bandwidth package it must be less than cen_bandwidth_limit
    china_gateway_bgp_asn                              = 64900                           # Required. BGP ASN associated with the Transit Gateways to be created in China Region
    global_transit_bgp_asn                             = 64910                           # Required. BGP ASN associated with the existing Transit Gateways in Global Region
    pre_shared_key                                     = "vpnKey123"                     # Required. Site-to-Cloud Pre-Shared-Key. Must be manually configured on the Transit Gateways in Global Region
    alicloud_china_eip_bandwidth_plan_name             = "china-eip-bw"                  # Optional. If specified, creates an EIP Bandwidth plan in AliCloud China region where the Transit Gateways were created
    alicloud_global_eip_bandwidth_plan_name            = "global-eip-bw"                 # Optional. If specified, creates an EIP Bandwidth plan in AliCloud Global region of existing Transit Gateways
}

output "Remote_BGP_AS_Number" {
  value = module.cen-test.alicloud_china_transit_bgp_asn
}
output "Remote_Gateway_IP" {
  value = module.cen-test.avx_china_gw_private_ip
}

output "Local_Tunnel_IP" {  
  value = module.cen-test.avx_global_transit_s2c_local_tunnel_cidr
}

output "Remote_Tunnel_IP" {
  value = module.cen-test.avx_global_transit_s2c_remote_tunnel_cidr
}

output "Remote_BGP_AS_Number_Backup" {  
  value = module.cen-test.alicloud_china_transit_bgp_asn
}

output "Remote_Gateway_IP_Backup" {
  value = module.cen-test.avx_china_hagw_private_ip
}

output "Local_Tunnel_IP_Backup" {
  value = module.cen-test.avx_global_transit_s2c_backup_local_tunnel_cidr
}

output "Remote_Tunnel_IP_Backup" {
  value = module.cen-test.avx_global_transit_s2c_backup_remote_tunnel_cidr
}
```

### Execute

```shell
terraform init
terraform apply --var-file=<terraform.tfvars>
````

> **Note:** Configure Site-to-Cloud in the existing Aviatrix Transit Gateway in AliCloud Global region using the values of the outputs above for the tunnel CIDR configuration after the Terraform configuration is successfully aplied.

## **Disclaimer**:

The material embodied in this software/code is provided to you "as-is" and without warranty of any kind, express, implied or otherwise, including without limitation, any warranty of fitness for a particular purpose. In no event shall the Aviatrix Inc. be liable to you or anyone else for any direct, special, incidental, indirect or consequential damages of any kind, or any damages whatsoever, including without limitation, loss of profit, loss of use, savings or revenue, or the claims of third parties, whether or not Aviatrix Inc. has been advised of the possibility of such loss, however caused and on any theory of liability, arising out of or in connection with the possession, use or performance of this software/code.