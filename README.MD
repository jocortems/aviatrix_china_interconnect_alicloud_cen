# Aviatrix China and Global Interconnection Using AliCloud CEN

## Description

### Note:

This Terraform module deploys and interconnects two Aviatrix Transit VPCs in AliCloud using AliCloud (CEN)[https://www.alibabacloud.com/help/en/cloud-enterprise-network/latest/what-is-cloud-enterprise-network#concept-2090845]

This Terraform module:

- Is limited to Controllers deployed in Azure China running version 6.7 - 6.9
- Creates one Transit VPC and Aviatrix Transit Gateways in a region in AliCloud China
- Creates one Transit VPC and Aviatrix Transit Gateways in a region in AliCloud Global
- Creates an AliCloud CEN instance and transit routers in the China and Global regions that will be interconnected and attached the created Transit VPCs
- Creates the required route table artifacts to achieve communication between the Transit VPCs across the regions
- Creates Site-to-Cloud connections between the Avaitrix Transit Gateways
- CEN Inter-region connection pricing defaults to Pay-by-data-transfer
- Optionally, it creates a CEN Bandwidth package, or uses an existing CEN Bandwidth package if one is specified
- Adds one or two security rules to the existing NSG associated with an Azure Controller deployed in China, depending on whether the Gateways are deployed in HA or not


## Prerequisites

1. [Terraform v0.13+](https://www.terraform.io/downloads.html) - execute terraform files


## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | ~> 3.52 |
| <a name="provider_alicloud"></a> [alicloud](https://registry.terraform.io/providers/aliyun/alicloud/latest) | ~> 1.203.0 |
| <a name="provider_aviatrix"></a> [aviatrix](https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest) | >= 2.22.0 |


## Available Modules

Module  | Description |
| ------- | ----------- |
| [aviatrix_alicloud_china_gateway_azure_controller_nsg](https://github.com/jocortems/aviatrix_alicloud_china_gateway_azure_controller_nsg) | Automates the creation of NSG rules in the NSG attached to an Aviatrix Controller deployed in Azure China for Aviatrix Gateways deployed in AliCloud in China regions |
| [alicloud-cen-deploy](https://github.com/jocortems/alicloud_cen_deploy) | Deploys an AliCloud CEN and interconnects two existing VPCs to the CEN |


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
      version = "~> 2.24.3"
      configuration_aliases = [aviatrix.china, aviatrix.global]
    } 
}
}

provider aviatrix {
  alias                   = "global"
  // additional configuration
}

provider aviatrix {
  alias                   = "china"
  // additional configuration
}

provider "alicloud" {
  alias = "china"
  region = "cn-beijing"
}

provider "alicloud" {
  alias = "global"
  region = "ap-southeast-1"
}

provider azurerm {
    environment = "china"
    features {}    
}


module "interconnect_global_china" {
  providers = {
    aviatrix.global = aviatrix.global
    aviatrix.china  = aviatrix.china
    alicloud.global = alicloud.global
    alicloud.china  = alicloud.china
  }

  source = "github.com/jocortems/aviatrix_alicloud_china_global_cen_interconnect"
  china_controller_account_name                         = "ali-account"                             # Required. Name of the AliCloud account onboarded on China Aviatrix Controller
  global_controller_account_name                        = "ali-account"                             # Required. Name of the AliCloud account onboarded on Global Aviatrix Controller
  controller_nsg_name                                   = "controllerha-nsg"                        # Required. Name of the NSG associated with the Aviatrix Controller deployed in China Region
  controller_nsg_resource_group_name                    = "china-controller"                        # Required. Name of the Resource Group associated with the NSG for the Aviatrix Controller deployed in China Region
  controller_nsg_rule_priority                          = 1000                                      # Required. Priority of the NSG rule associated with the Aviatrix Controller deployed in China Region. This number must be unique, before assigning verify the NSG does not have a rule with the same priority. If deploying the Gateway in HA two rules will be created using consecutive priorities, the priority specified here will be for the first gateway
  ha_enabled                                            = true/false                                # Optional. Default true
  china_transit_vpc_name                                = "china-transit-vpc"                       # Required.
  gw_china_region                                       = "acs-cn-beijing (Beijing)"                # Required. Name of the China Region to deploy the Aviatrix Transit Gateways to. Must match display name in Aviatrix Controller
  china_gateway_name                                    = "china-transit-gw"                        # Optional. Name of the Transit Gateway in China. If not provided defaults to the value of china_transit_vpc_name
  china_gateway_size                                    = "ecs.g5ne.large"                          # Optional. Default ecs.g5ne.large
  china_vpc_cidr                                        = "10.200.0.0/23"                           # Required. Must be /23
  china_gateway_bgp_asn                                 = 64901                                     # Required. Must be unique in the network
  enable_segmentation_china                             = true/false                                # Optional. Default false        
  global_transit_vpc_name                               = "global-transit-vpc"                      # Required
  gw_global_region                                      = "acs-ap-southeast-1 (Singapore)"          # Required. Name of the Global Region to deploy the Aviatrix Transit Gateways to. Must match display name in Aviatrix Controller
  global_gateway_name                                   = "global-transit-gw"                       # Optional. Name of the Transit Gateway in Global. If not provided defaults to the value of global_transit_vpc_name
  global_gateway_size                                   = "ecs.g5ne.large"                          # Optional. Default ecs.g5ne.large
  global_vpc_cidr                                       = "10.210.0.0/23"                           # Required. Must be /23
  global_gateway_bgp_asn                                = 64902                                     # Required. Must be unique in the network
  enable_segmentation_global                            = true/false                                # Optional. Default false        
  ali_china_region                                      = "cn-beijing"                              # Required. Name of the AliCloud China region where the Gateways are deployed. Must match AliCloud Region ID
  ali_global_region                                     = "ap-southeast-1"                          # Required. Name of the AliCloud Global region where the Gateways are deployed. Must match AliCloud Region ID
  cen_name                                              = "my-cen"                                  # Required. CEN instance name
  cen_global_geo                                        = "Asia-Pacific"                            # Required. Name of the AliCloud Geo. Valid values are "Asia-Pacific", "North-America", "Europe" and "Australia"
  pre_shared_key                                        = "s2cipseckey"                             # Required. Site-to-Cloud IPSec VPN key
  cen_bandwidth_type                                    = "DataTransfer"                            # Optional. Default "DataTransfer". If using a Bandwidth plan with CEN change to "BandwidthPackage"
  cen_bandwidth_package_name                            =                                           # Optional. Creates a new bandwidth package to use with CEN if provided. Conflicts with cen_bandwidth_package_id
  cen_bandwidth_package_id                              =                                           # Optional. Specifies an existing bandwidth package to use with CEN. Conflicts with cen_bandwidth_package_name
  cen_bandwidth_package_bandwdith                       = 100                                       # Optional. Default 100Mbps. Only needed if cen_bandwidth_package_name is specified
  cen_bandwidth_package_period                          = 1                                         # Optional. Default 1 month. Only needed if cen_bandwidth_package_name is specified  
  cen_bandwidth_limit                                   = 100                                       # Optional. Default 100Mbps. Needed if either cen_bandwidth_package_name or cen_bandwidth_package_id are specified. Must be less than or equal to cen_bandwidth_package_bandwdith if creating a bandwidth package, or less than the existing bandwidth package bandwidth if using an existing one  
  cen_transit_router_peer_attachment_bandwidth_limit    = 100                                       # Optional. Defaults to 100Mbps. This value is used regardless of whether a bandwidth package is used or not 
  bgp_manual_spoke_advertise_cidrs_china                =                                           # Optional. Default Null. List of CIDRs to be advertised to on-premises via BGP. For example "10.2.0.0/16,10.4.0.0/16"
  bgp_manual_spoke_advertise_cidrs_global               =                                           # Optional. Default Null. List of CIDRs to be advertised to on-premises via BGP. For example "10.2.0.0/16,10.4.0.0/16" 
  bgp_polling_time_china                                = 20                                        # Optional. Default 20 seconds. BGP polling time in seconds between gateway and controller
  bgp_polling_time_global                               = 20                                        # Optional. Default 20 seconds. BGP polling time in seconds between gateway and controller
  bgp_hold_time_china                                   = 20                                        # Optional. Default 20 seconds
  bgp_hold_time_global                                  = 20                                        # Optional. Default 20 seconds
  prepend_as_path_china                                 = []                                        # Optional. Default empty list
  prepend_as_path_global                                = []                                        # Optional. Default empty list
  bgp_ecmp_china                                        = true/false                                # Optional. Default true
  bgp_ecmp_global                                       = true/false                                # Optional. Default true
  enable_preserve_as_path_china                         = true/false                                # Optional. Default false
  enable_preserve_as_path_global                        = true/false                                # Optional. Default false
  customized_spoke_vpc_routes_china                     =                                           # Optional. Default null
  customized_spoke_vpc_routes_global                    =                                           # Optional. Default null
  excluded_advertised_spoke_routes_china                =                                           # Optional. Default null
  excluded_advertised_spoke_routes_global               =                                           # Optional. Default null
  enable_learned_cidrs_approval_china                   = true/false                                # Optional. Default false
  enable_learned_cidrs_approval_global                  = true/false                                # Optional. Default false
  learned_cidrs_approval_mode_china                     = "gateway"                                 # Optional. Default "gateway"
  learned_cidrs_approval_mode_global                    = "gateway"                                 # Optional. Default "gateway"
  approved_learned_cidrs_china                          = []                                        # Optional. Default empty list
  approved_learned_cidrs_global                         = []                                        # Optional. Default empty list
  enable_vpc_dns_server_china                           = true/false                                # Optional. Default false
  enable_vpc_dns_server_global                          = true/false                                # Optional. Default false
  china_gw_tags                                         = {}                                        # Optional. Default empty
  global_gw_tags                                        = {}                                        # Optional. Default empty
  tunnel_detection_time_china                           = 20                                        # Optional. Default 20 seconds
  tunnel_detection_time_global                          = 20                                        # Optional. Default 20 seconds  
}
```

### Execute

```shell
terraform init
terraform apply --var-file=<terraform.tfvars>
````

## **Disclaimer**:

The material embodied in this software/code is provided to you "as-is" and without warranty of any kind, express, implied or otherwise, including without limitation, any warranty of fitness for a particular purpose. In no event shall the Aviatrix Inc. be liable to you or anyone else for any direct, special, incidental, indirect or consequential damages of any kind, or any damages whatsoever, including without limitation, loss of profit, loss of use, savings or revenue, or the claims of third parties, whether or not Aviatrix Inc. has been advised of the possibility of such loss, however caused and on any theory of liability, arising out of or in connection with the possession, use or performance of this software/code.