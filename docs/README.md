# Exploring KAITO enabled by Azure Arc

## Introduction

This guide provides a quick way to explore KAITO enabled by Azure Arc. The guide includes a optional Bicep template for setting up an Arc-enabled cluster with a GPU node by using AKS. You can also use your own Kubernetes cluster and GPU if desired with some modifications to the script.

## Prerequisites

Before you begin, ensure you have the following:

* An Azure subscription with access to Azure Kubernetes Service (AKS) and Azure Arc.
* Available NCSv12 or other GPU quota in your Azure subscription OR bring your own Kubernetes cluster with GPU.
* Access to the code by cloning [the repo](https://github.com/dkirby-ms/jsdrop_kaito) to a local dev folder.
* Azure CLI installed and logged into the Azure subscription you will use.

## Step-by-Step Guide

### Step 1 (Optional): Setting Up an Arc-connected Kubernetes environment with GPU

Setup an AKS cluster to simulate an on-premises cluster and GPU. For this Bicep template, you will need Compute quota for 24 Standard_NCSv3 series vCPU. The script was tested with East US and East US 2.

Open a Bash shell where you cloned the [GitHub repository](https://github.com/dkirby-ms/jsdrop_kaito). From the shell, run the following commands to create an Azure resource group and begin a deployment of AKS using a Bicep template.

    az group create -n JumpstartKAITO -l eastus2

    az deployment group create -g JumpstartKAITO -f infra/aks.bicep

Once the deployment completes, continue to the next step.

### Step 2: Arc-enable the cluster

After the cluster is deployed, run the _infra/scripts/install_arc.sh_ script from the same shell.

    chmod 700 ./infra/scripts/install_arc.sh
    ./infra/scripts/install_arc.sh

### Step 3: Deploy KAITO and a falcon-7b-instruct model and ask a question

Next we will run the install_kaito.sh script deploy KAITO and ask an LLM a question.

    chmod 700 ./infra/scripts/install_kaito.sh
    ./infra/scripts/install_kaito.sh

## Troubleshooting

* **GPU Quota Issues**: If you encounter GPU quota issues, request quota relief through the appropriate channels. Ensure that your subscription has access to the necessary GPU resources.

* **Deployment Failures**: If KAITO fails to deploy, check the configuration files and ensure that all dependencies are installed correctly. Refer to the logs for more details on the errors.
