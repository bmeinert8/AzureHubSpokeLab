@description('The location of the resources being deployed.')
param location string = resourceGroup().location

@description('The admin username for the vms.')
@secure()
param adminUsername string

@description('The admin password for the vms.')
@secure()
param adminPassword string

@description('The Name of the application gateway.')
param applicationGatewayName string = 'eus2appgw'

@description('The name of the application gateway backend.')
param applicationGatewayBEName string = 'appgw-be'

@description('The name of the public ip address for the application gateway.')
param appGWPublicIPAddressName string = 'appgwpip'

@description('The name of the application gateway http listener.')
param httpListenerName string = 'listener1'

@description('The name of the load balancer.')
param loadBalancerName string = 'lb1eus'

@description('The name of the backend pool for the load balancer.')
param loadBalancerBEPoolName string = 'lbeusbackend'

@description('The name of the frontend configuration for the load balancer.')
param loadBalancerFEName string = 'lbeusfrontend'

@description('The name of the public ip address for the load balancer.')
param lbPublicIPAddressName string = 'lbpip'

@description('The name of the load balancer probe.')
param loadBalancerProbeName string = 'probe1'

@description('The name of the first load balancing rule.')
param lbRule1Name string = 'rule1'

@description('The name of the first network interface.')
param networkInterface1Name string = 'nic1'

@description('The name of the second network interface.')
param networkInterface2Name string = 'nic2'

@description('The name of the third network interface.')
param networkInterface3Name string = 'nic3'

@description('The name of the fourth network interface.')
param networkInterface4Name string = 'nic4'

@description('The name of the first network security group.')
param nsgNames array = [
  'nsg1'
  'nsg2'
  'nsg3'
]

@description('The name of the route table.')
param routeTableName string = 'rt023'

@description('The name of vm1 os disk.')
param virtualMachine1DiskName string = 'vm1disk'

@description('The name of vm2 os disk.')
param virtualMachine2DiskName string = 'vm2disk'

@description('The name of vm3 os disk.')
param virtualMachine3DiskName string = 'vm3disk'

@description('The name of vm4 os disk.')
param virtualMachine4DiskName string = 'vm4disk'

@description('The name of the first virtual machine.')
param virtualMachine1Name string = 'vm1'

@description('The name of the second virtual machine.')
param virtualMachine2Name string = 'vm2'

@description('The name of the third virtual machine.')
param virtualMachine3Name string = 'vm3'

@description('The name of the fourth virtual machine.')
param virtualMachine4Name string = 'vm4'

@description('The size of the virtual machine.')
param vmSize string = 'Standard_D2s_v3'

@description('The name of the first virtual network.')
param virtualNetowrk1Name string = 'vnet1'

@description('The name of the second virtual network.')
param virtualNetowrk2Name string = 'vnet2'

@description('The name of the third virtual network.')
param virtualNetowrk3Name string = 'vnet3'




var routesConfig = {
  name: 'virtualNetwork3-to-VirtualNetwork2'
  properties: {
    addressPrefix: '10.62.0.0/20'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: '10.60.0.4'
    hasBgpOverride: false
  }
}

var rdpRuleConfig = {
  name: 'default-allow-rdp'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '3389'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 1000
    direction: 'Inbound'
  }
}

var httpRuleConfig = {
  name: 'default-allow-http'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '80'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 1100
    direction: 'Inbound'
  }
}

var virtualMachineImageReference =  {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}

var virtualNetwork1Config = {
  addressPrefix: '10.60.0.0/16'
  subnet1Name: 'Subnet0'
  subnet1Prefix: '10.60.0.0/24'
  subnet2Name: 'Subnet1'
  subnet2Prefix: '10.60.1.0/24'
  subnet3name: 'Subnet-appgw'
  subnet3Prefix: '10.60.3.224/27'
}

var virtualNetwork2Config = {
  addressprefix: '10.62.0.0/16'
  subnetName: 'subnet0'
  subnetPrefix: '10.62.0.0/24'
}

var virtualNetwork3Config = {
  addressprefix: '10.63.0.0/16'
  subnetName: 'subnet0'
  subnetPrefix: '10.63.0.0/24'
}



resource appGWPublicIPAddress 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: appGWPublicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-06-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: virtualNetwork1::virtualNetwork1subnet3.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGWPublicIPAddress.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: applicationGatewayBEName
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: '${applicationGatewayName}-http1'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: httpListenerName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName,'appGwPublicFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendports', applicationGatewayName,'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'routingRule1'
        properties: {
          ruleType: 'Basic'
          priority: 10
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, httpListenerName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, applicationGatewayBEName)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName,'${applicationGatewayName}-http1')
          }
        }
      }
    ]
    enableHttp2: false
  }
}
resource loadBalancer 'Microsoft.Network/loadBalancers@2023-06-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: loadBalancerFEName
        properties: {
          publicIPAddress: {
            id: lbPublicIPAddress.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: loadBalancerBEPoolName
      }
    ]
    loadBalancingRules: [
      {
        name: lbRule1Name
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, loadBalancerFEName)
          } 
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, loadBalancerBEPoolName)
          }
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'Tcp'
          enableTcpReset: false
          loadDistribution: 'Default'
          disableOutboundSnat: true
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, loadBalancerProbeName)
          }
        }
      }
    ]
    probes: [
      {
        name: loadBalancerProbeName
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 1
          probeThreshold: 1
        }
      }
    ]
  }
}

resource lbPublicIPAddress 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: lbPublicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource networkInterface1 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: networkInterface1Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork1::virtualNetwork1Subnet1.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, loadBalancerBEPoolName)
            }
          ]
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: true
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: networkSecurityGroups[0].id
    }
    nicType: 'Standard'
  }
}

resource networkInterface2 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: networkInterface2Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork1::virtualNetwork1subnet2.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, loadBalancerBEPoolName)
            }
          ]
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: true
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: networkSecurityGroups[0].id
    }
    nicType: 'Standard'
  }
}

resource networkInterface3 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: networkInterface3Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork2::virtualNetwork2subnet1.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: networkSecurityGroups[1].id
    }
    nicType: 'Standard'
  }
}

resource networkInterface4 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: networkInterface4Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork3::virtualNetwork3Subnet1.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: networkSecurityGroups[2].id
    }
    nicType: 'Standard'
  }
}

resource  networkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2023-06-01' = [for name in nsgNames: {
  name: '${name}'
  location: location
  properties: {
    securityRules: [
      {
        name: rdpRuleConfig.name
        properties: rdpRuleConfig.properties
      }
      {
        name: httpRuleConfig.name
        properties: httpRuleConfig.properties
      }
    ]
  } 
}]

resource routeTable 'Microsoft.Network/routeTables@2023-06-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: routesConfig.name
        properties: routesConfig.properties
      }
    ]
  }

  resource routeTableRoute 'routes' existing ={
    name:routesConfig.name
  }
}

resource virtualMachine1 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachine1Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: virtualMachineImageReference
      osDisk: {
        osType: 'Windows'
        name: virtualMachine1DiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    osProfile: {
      computerName: virtualMachine1Name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface1.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }

  resource virtualMachine1IIS 'extensions' = {
    name: '${virtualMachine1Name}-IIS'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Compute'
      type: 'CustomScriptExtension'
      typeHandlerVersion: '1.7'
      settings: {
        commandToExecute: 'powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item \'C:\\inetpub\\wwwroot\\iisstart.htm\' && powershell.exe Add-Content -Path \'C:\\inetpub\\wwwroot\\iisstart.htm\' -Value $(\'Hello World from \' + $env:computername)'
      }
    }
  }

  resource virtualMachine2networkWatcherAgent 'extensions' = {
    name: '${virtualMachine1Name}-NWA'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.NetworkWatcher'
      type: 'NetworkWatcherAgentWindows'
      typeHandlerVersion: '1.4'
    }
  }
}

resource virtualMachine2 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachine2Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: virtualMachineImageReference
      osDisk: {
        osType: 'Windows'
        name: virtualMachine2DiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    osProfile: {
      computerName: virtualMachine2Name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface2.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }

  resource virtualMachine2IIS 'extensions' = {
    name: '${virtualMachine2Name}-IIS'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Compute'
      type: 'CustomScriptExtension'
      typeHandlerVersion: '1.7'
      settings: {
        commandToExecute: 'powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item \'C:\\inetpub\\wwwroot\\iisstart.htm\' && powershell.exe Add-Content -Path \'C:\\inetpub\\wwwroot\\iisstart.htm\' -Value $(\'Hello World from \' + $env:computername)'
      }
    }
  }

  resource virtualMachine2networkWatcherAgent 'extensions' = {
    name: '${virtualMachine2Name}-NWA'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.NetworkWatcher'
      type: 'NetworkWatcherAgentWindows'
      typeHandlerVersion: '1.4'
    }
  }
}

resource virtualMachine3 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachine3Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: virtualMachineImageReference
      osDisk: {
        osType: 'Windows'
        name: virtualMachine3DiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    osProfile: {
      computerName: virtualMachine3Name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface3.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }

  resource virtualMachine3IIS 'extensions' = {
    name: '${virtualMachine3Name}-IIS'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Compute'
      type: 'CustomScriptExtension'
      typeHandlerVersion: '1.7'
      settings: {
        commandToExecute: 'powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item \'C:\\inetpub\\wwwroot\\iisstart.htm\' && powershell.exe Add-Content -Path \'C:\\inetpub\\wwwroot\\iisstart.htm\' -Value $(\'Hello World from \' + $env:computername)'
      }
    }
  }

  resource virtualMachine3networkWatcherAgent 'extensions' = {
    name: '${virtualMachine3Name}-NWA'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.NetworkWatcher'
      type: 'NetworkWatcherAgentWindows'
      typeHandlerVersion: '1.4'
    }
  }
}

resource virtualMachine4 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachine4Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: virtualMachineImageReference
      osDisk: {
        osType: 'Windows'
        name: virtualMachine4DiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    osProfile: {
      computerName: virtualMachine4Name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface4.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }

  resource virtualMachine4IIS 'extensions' = {
    name: '${virtualMachine4Name}-IIS'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Compute'
      type: 'CustomScriptExtension'
      typeHandlerVersion: '1.7'
      settings: {
        commandToExecute: 'powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item \'C:\\inetpub\\wwwroot\\iisstart.htm\' && powershell.exe Add-Content -Path \'C:\\inetpub\\wwwroot\\iisstart.htm\' -Value $(\'Hello World from \' + $env:computername)'
      }
    }
  }

  resource virtualMachine3networkWatcherAgent 'extensions' = {
    name: '${virtualMachine4Name}-NWA'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.NetworkWatcher'
      type: 'NetworkWatcherAgentWindows'
      typeHandlerVersion: '1.4'
    }
  }
}

resource virtualNetwork1 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: virtualNetowrk1Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetwork1Config.addressPrefix
      ]
    }
    subnets: [
      {
        name: virtualNetwork1Config.subnet1Name
        properties: {
          addressPrefix: virtualNetwork1Config.subnet1Prefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: virtualNetwork1Config.subnet2Name
        properties: {
          addressPrefix: virtualNetwork1Config.subnet2Prefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: virtualNetwork1Config.subnet3name
        properties: {
          addressPrefix: virtualNetwork1Config.subnet3Prefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }

  resource virtualNetwork1Subnet1 'subnets' existing = {
    name: virtualNetwork1Config.subnet1Name
  }

  resource virtualNetwork1subnet2 'subnets' existing = {
    name: virtualNetwork1Config.subnet2Name
  }

  resource virtualNetwork1subnet3 'subnets' existing = {
    name: virtualNetwork1Config.subnet3name
  }

  resource virtualNetwork1Peering1 'virtualNetworkPeerings' = {
    name: '${virtualNetowrk1Name}-to-${virtualNetowrk2Name}'
    properties: {
      remoteVirtualNetwork: {
        id: virtualNetwork2.id
      }
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: false
      allowGatewayTransit: true
      useRemoteGateways: false
      doNotVerifyRemoteGateways: false
    }
  }

  resource virtualNetwork1Peering2 'virtualNetworkPeerings' = {
    name: '${virtualNetowrk1Name}-to-${virtualNetowrk3Name}'
    properties: {
      remoteVirtualNetwork: {
        id: virtualNetwork3.id
      }
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: false
      allowGatewayTransit: true
      useRemoteGateways: false
      doNotVerifyRemoteGateways: false
    }
  }
}

resource virtualNetwork2 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: virtualNetowrk2Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetwork2Config.addressprefix
      ]
    }
    subnets: [
      {
        name: virtualNetwork2Config.subnetName
        properties: {
          addressPrefix: virtualNetwork2Config.subnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }

  resource virtualNetwork2subnet1 'subnets' existing = {
    name: virtualNetwork2Config.subnetName
  }

  resource virtualNetwork2Peering 'virtualNetworkPeerings' = {
    name:'${virtualNetowrk2Name}-to-${virtualNetowrk1Name}'
    properties: {
      remoteVirtualNetwork: {
        id: virtualNetwork1.id
      }
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      allowGatewayTransit: false
      useRemoteGateways: false
      doNotVerifyRemoteGateways: false
    }
  }
}

resource virtualNetwork3 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: virtualNetowrk3Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetwork3Config.addressprefix
      ]
    }
    subnets: [
      {
        name: virtualNetwork3Config.subnetName
        properties: {
          addressPrefix: virtualNetwork3Config.subnetPrefix
          routeTable: {
            id: routeTable.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }

  resource virtualNetwork3Subnet1 'subnets' existing = {
    name: virtualNetwork3Config.subnetName
  }

  resource virtualNetwork3Peering 'virtualNetworkPeerings' = {
    name: '${virtualNetowrk3Name}-to-${virtualNetowrk1Name}'
    properties: {
      remoteVirtualNetwork: {
        id: virtualNetwork1.id
      }
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      allowGatewayTransit: false
      useRemoteGateways: false
      doNotVerifyRemoteGateways: false
    }
  }
}

output deployedNSGs array = [for (name, i) in nsgNames: {
  orgName: name
  nsgName: networkSecurityGroups[i].name
  resourceId: networkSecurityGroups[i].id
}]
