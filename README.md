# mlopsdemov2

![image](https://user-images.githubusercontent.com/31459994/189961497-b7516d79-594c-4f92-9234-0770f9586860.png)

# Setting up new MLOPS

## Create 3 AML Workspaces to use in the demo

01 - Dev Workspace
02 - Test Workspace
03 - Prod Workspace

## Create a Storage Account and Containers

Create a storage account that you will use in the demo. Example: developmentjbdemo

Also creates mlopsdemodev, mlopsdemotest and mlopsdemoprod containers

## Create a User Managed Identity

az identity create  -n mlopsdemostgacc --query id -o tsv -g rg-ml-mlopsworkspaces-jb

Get the result and add the string in the create compute script.
Example: /subscriptions/.../resourcegroups/rg-ml-mlopsworkspaces-jb/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mlopsdemostgacc

## Create Compute

Dev: az ml compute create -f ./compute/computedev.yml --workspace-name mlopsdemojb01 --resource-group rg-ml-mlopsworkspaces-jb
Test: az ml compute create -f ./compute/computetest.yml --workspace-name mlopsdemojb02 --resource-group rg-ml-mlopsworkspaces-jb
Prod: az ml compute create -f ./compute/computeprod.yml --workspace-name mlopsdemojb03 --resource-group rg-ml-mlopsworkspaces-jb

Grant access on the Storage Account you will use for the demo:

![image](https://user-images.githubusercontent.com/31459994/189962665-1ca157b1-fc19-4c5f-a6c1-1658c5750e95.png)


## Create the containers in the Storage Account

![image](https://user-images.githubusercontent.com/31459994/189990051-91c17663-d9ad-4fc5-bdd3-ecbf2426b735.png)

Use the following structure in test and prod containers

![image](https://user-images.githubusercontent.com/31459994/189990148-a45364ef-ec1d-41b6-8f2b-4c58b1ee4a61.png)


# Dev Steps - Workspace 01 (Dev)

## Create AML Environment

az ml environment create --file ./dev/train-env.yml --workspace-name mlopsdemojb01 --resource-group rg-ml-mlopsworkspaces-jb

## Pipeline run

az ml job create --file ./dev/pipeline.yml --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb01

# Test Steps - Workspace 02 (Test)

## Create AML Enviroment

az ml environment create --file ./test/test-env.yml --workspace-name mlopsdemojb02 --resource-group rg-ml-mlopsworkspaces-jb

## Create datastore and data asset

Datastore

az ml datastore create --file ./test/data-store.yml --workspace-name mlopsdemojb02 --resource-group rg-ml-mlopsworkspaces-jb

Data Asset

az ml data create -f ./test/file-data-asset.yml --workspace-name mlopsdemojb02 --resource-group rg-ml-mlopsworkspaces-jb

## Download model from Dev Workspace

az ml model download --name taxi-model-mlops-demo --version 1 --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb01 --download-path ./model

## Register model on Test Workspace

az ml model create --name taxi-test-model-mlops-demo --version 1 --path ./model/taxi-model-mlops-demo --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb02

## Register Batch Endpoint

az ml batch-endpoint create --file ./test/batch-endpoint-test.yml --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb02

## Register Batch Deployment

az ml batch-deployment create --file ./test/batch-deployment-test.yml --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb02

## Execute Batch Job

az ml batch-endpoint invoke --name taxi-fare-batch-mlopsdemo-test --deployment-name batch-dp-mlopsdemo-test --input-type uri_file --input azureml://datastores/mlopsdemotestcointainer/paths/taxibatch/taxi-batch.csv --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb02 --output-path azureml://datastores/mlopsdemotestcointainer/paths/taxioutput

# Prod Steps - Workspace 03 (Prod)

## Create Environment

az ml environment create --file ./prod/prod-env.yml --workspace-name mlopsdemojb03 --resource-group rg-ml-mlopsworkspaces-jb

## Create datastore and data asset

Datastore

az ml datastore create --file ./prod/data-store.yml --workspace-name mlopsdemojb03 --resource-group rg-ml-mlopsworkspaces-jb

Data Asset

az ml data create -f ./prod/file-data-asset.yml --workspace-name mlopsdemojb03 --resource-group rg-ml-mlopsworkspaces-jb

## Download model from Dev Workspace

Already done in Test step

## Register Model

az ml model create --name taxi-prod-model-mlops-demo --version 1 --path ./model/taxi-model-mlops-demo --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb03

## Register Batch Endpoint

az ml batch-endpoint create --file ./prod/batch-endpoint-prod.yml --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb03

## Register Batch Deployment

az ml batch-deployment create --file ./prod/batch-deployment-prod.yml --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb03

## Execute Batch Job

az ml batch-endpoint invoke --name taxi-fare-batch-mlopsdemo-prod --deployment-name batch-dp-mlopsdemo-prod --input-type uri_file --input azureml://datastores/mlopsdemoprodcointainer/paths/taxibatch/taxi-batch.csv --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb03 --output-path azureml://datastores/mlopsdemoprodcointainer/paths/taxioutput
