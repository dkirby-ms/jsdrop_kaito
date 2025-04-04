module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.8.3' = {
  name: 'managedClusterDeployment'
  params: {
    // Required parameters
    name: 'controlplane'
    primaryAgentPoolProfiles: [
      {
        count: 3
        mode: 'System'
        name: 'systempool'
        vmSize: 'Standard_DS4_v2'
        // Removed availabilityZones and added availabilitySet
        type: 'AvailabilitySet'

      }
    ]
    // Non-required parameters
    aadProfile: {
      aadProfileEnableAzureRBAC: true
      aadProfileManaged: true
    }
    managedIdentities: {
      systemAssigned: true
    }
    agentPools: [
      {
        name: 'gpupool'
        count: 2
        mode: 'User'
        vmSize: 'Standard_NC12s_v3'  // GPU-enabled VM size
        osDiskSizeGB: 128
        osType: 'Linux'
        maxPods: 110
        minCount: 1
        maxCount: 2
        // Added availability set configuration for GPU pool
        type: 'AvailabilitySet'
      }
    ]
  }
}
