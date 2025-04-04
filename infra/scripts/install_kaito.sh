#!/bin/bash
export clusterName="kaitotest"
export resourceGroupName="kaito"
export KAITO_WORKSPACE_VERSION=0.4.4
export GPU_NODE_POOL_NAME="gpu"
export namespace="kaito-workspace"

# Prerequisite: We are starting with a pre-existing AKS cluster that has a GPU node pool of at least 2 nodes of NC12v3 SKU. This can be deployed using the included Bicep template.

# Login to Azure and get kubeconfig for the AKS cluster
az login
az aks get-credentials --name $clusterName --resource-group $resourceGroupName --overwrite-existing

# Prep cluster for GPU operator
kubectl create ns gpu-operator
kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged

# Install GPU operator
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

helm install \
    --wait \
    --generate-name \
    -n gpu-operator \
    --create-namespace \
    nvidia/gpu-operator

# Check if GPU operator is running
kubectl -n gpu-operator wait pod \
    --for=condition=Ready \
    -l app.kubernetes.io/component=gpu-operator \
    --timeout=300s

# Check for Nvidia runtimeclass
kubectl get runtimeclass nvidia

# Label the GPU nodes
kubectl get nodes \
    -l agentpool="${GPU_NODE_POOL_NAME}" \
    -o name | \
    xargs -I {} \
    kubectl label --overwrite {} apps=gpu


# Install KAITO workspace controller
helm install $namespace  --set clusterName=$MY_CLUSTER --wait \
https://github.com/kaito-project/kaito/raw/gh-pages/charts/kaito/workspace-$KAITO_WORKSPACE_VERSION.tgz --namespace $namespace --create-namespace

# Check if KAITO workspace controller is running
kubectl -n $namespace wait pod \
    --for=condition=Ready \
    -l app.kubernetes.io/instance=$namespace \
    --timeout=300s



