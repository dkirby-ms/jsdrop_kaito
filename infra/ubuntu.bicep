@description('The name of you Virtual Machine')
param vmName string = 'K3s-${namingGuid}'

@description('Username for the Virtual Machine')
param adminUsername string = 'arcdemo'

@description('RSA public key used for securing SSH access to ArcBox resources. This parameter is only needed when deploying the DataOps or DevOps flavors.')
@secure()
param sshRSAPublicKey string = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9uDKmlulaxL8fFkMdvSA0uqYJGS++B1dWjgDeRyGQK+9ohKhVe/87NuYuyDLp28kU6f1RvFZxaqf8u0NOpbWTl/j2TBP4bj9nDbjbzFpt+j+AHgLs+wy+URMIQI+C2i/8El9+kWrdBeqwqFOzDvVLC1WT//pqS9wismy8UvsAcapeHCoTLBsUg8f4GotNOf6925yHFrlvlsogwuVu2Ui+m49p+OLcQyXk6bOUCqFq+r4Y9KESqv4Q3P61hQ6Y27amxpLWoQi36XqasXCwnkhdobQSoBzrlMxUr10cX/511fOystbszD1+jlx3whvLC/gUXT5m9wwaRa0z7jwNaovNljAST7Yyclj/bRbW37plyUewTL7p1VoigHkW48U8R3vpaO0OBS55XvGoP+nxlwKg15v6l6br9n8TkJQ/cvemP6op+sSqRmtulQRvPoHjI/va6JdMNnPP3fLKFbM8+ezbVoF5lZWnJNxZ+KggPIfw+vc3NGQXXit8L1A23+HGc178kel7nZlFHG0bKTbgxeH7nsJ5h+U/yeaXX5IwSu1lpMHnzdQ6JKbXrrcm3jE5/+Ur2VIkUIFpdqav9DRLNDT2nC6I7+1ndDb4md3gX+B2zW78ircqFeRj4ZWmvJ/afg3puNb/s4jnVRb1oLg0+pAsWqyMgPHPYCKY+LPTavrHvQ== dakir@microsoft.com'

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version')
@allowed([
  '22_04-lts-gen2'
])
param ubuntuOSVersion string = '22_04-lts-gen2'

@description('Location for all resources.')
param azureLocation string = resourceGroup().location

@description('The size of the VM')
param vmSize string = 'Standard_D16s_v5'

@maxLength(5)
@description('Random GUID')
param namingGuid string = toLower(substring(newGuid(), 0, 5))

@description('Name of the Cloud VNet')
param virtualNetworkNameCloud string = 'vnet1'

@description('Name of the K3s subnet in the cloud virtual network')
param subnetNameCloudK3s string = 'subnet-k3s'

@description('Name of the inner-loop subnet in the cloud virtual network')
param subnetNameCloud string = 'subnet-cloud'

@description('Azure Region to deploy the Log Analytics Workspace')
param location string = resourceGroup().location

@description('Name of the prod Network Security Group')
param networkSecurityGroupNameCloud string = 'nsg-Prod'

var addressPrefixCloud = '10.16.0.0/16'
var subnetAddressPrefixK3s = '10.16.80.0/21'
var subnetAddressPrefixCloud = '10.16.64.0/21'
var networkInterfaceName = '${vmName}-NIC'
var osDiskType = 'Premium_LRS'
var diskSize = 512
var publicIpAddressName = '${vmName}-PIP'
var numberOfIPAddresses =  10 // The number of IP addresses to create
var cloudK3sSubnet = [
  {
    name: subnetNameCloudK3s
    properties: {
      addressPrefix: subnetAddressPrefixK3s
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      networkSecurityGroup: {
        id: networkSecurityGroupCloud.id
      }
    }
  }
]
var cloudSubnet = [
  {
    name: subnetNameCloud
    properties: {
      addressPrefix: subnetAddressPrefixCloud
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      networkSecurityGroup: {
        id: networkSecurityGroupCloud.id
      }
    }
  }
]

resource publicIpAddresses 'Microsoft.Network/publicIpAddresses@2022-01-01' = [for i in range(1, numberOfIPAddresses): {
  name: '${publicIpAddressName}${i}'
  location: azureLocation
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Basic'
  }
}]

// Create multiple NIC IP configurations and assign the public IP to the IP configuration
resource networkInterface 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: networkInterfaceName
  location: azureLocation
  properties: {
    ipConfigurations: [for i in range(1, numberOfIPAddresses): {
      name: 'ipconfig${i}'
      properties: {
        subnet: {
          id: cloudVirtualNetwork.properties.subnets[0].id
        }
        privateIPAllocationMethod: 'Dynamic'
        publicIPAddress: {
          id: publicIpAddresses[i-1].id
        }
        primary: i == 1 ? true : false
      }
    }]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: azureLocation
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        name: '${vmName}-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        diskSizeGB: diskSize
      }
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshRSAPublicKey
            }
          ]
        }
      }
    }
  }
}

// Add role assignment for the VM: Owner role
resource vmRoleAssignment_Owner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vm.id, 'Microsoft.Authorization/roleAssignments', 'Owner')
  scope: resourceGroup()
  properties: {
    principalId: vm.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
    principalType: 'ServicePrincipal'
  }
}

// Add role assignment for the VM: Storage Blob Data Contributor
resource vmRoleAssignment_Storage 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vm.id, 'Microsoft.Authorization/roleAssignments', 'Storage Blob Data Contributor')
  scope: resourceGroup()
  properties: {
    principalId: vm.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalType: 'ServicePrincipal'
  }
}



resource cloudVirtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: virtualNetworkNameCloud
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefixCloud
      ]
    }
    subnets: union (cloudK3sSubnet,cloudSubnet)
  }
}

resource networkSecurityGroupCloud 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: networkSecurityGroupNameCloud
  location: location
  properties: {
    securityRules: []
  }
}

output vnetId string = cloudVirtualNetwork.id
output k3sSubnetId string = cloudVirtualNetwork.properties.subnets[0].id
output cloudSubnetId string = cloudVirtualNetwork.properties.subnets[1].id
output virtualNetworkNameCloud string = cloudVirtualNetwork.name
