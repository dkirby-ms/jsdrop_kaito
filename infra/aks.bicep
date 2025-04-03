module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.8.3' = {
  name: 'managedClusterDeployment'
  params: {
    // Required parameters
    name: 'csmin001'
    primaryAgentPoolProfiles: [
      {
        count: 3
        mode: 'System'
        name: 'systempool'
        vmSize: 'Standard_DS4_v2'
        availabilityZones: [
          1
          3
        ]
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
        nodeTaints: [
          'sku=gpu:NoSchedule'
        ]
        enableAutoScaling: true
        minCount: 1
        maxCount: 2
      }
    ]
  }
}
