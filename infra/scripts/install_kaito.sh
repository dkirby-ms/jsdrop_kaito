#!/bin/bash
clusterName="csmin001"
resourceGroupName="kaito"

az login

az aks get-credentials --name $clusterName --resource-group $resourceGroupName --overwrite-existing

export KAITO_WORKSPACE_VERSION=0.4.4

helm install kaito-workspace  --set clusterName=$MY_CLUSTER --wait \
https://github.com/kaito-project/kaito/raw/gh-pages/charts/kaito/workspace-$KAITO_WORKSPACE_VERSION.tgz --namespace kaito-workspace --create-namespace



