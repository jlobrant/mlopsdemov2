# MLOps Demo Scenario

![image](https://user-images.githubusercontent.com/31459994/189961497-b7516d79-594c-4f92-9234-0770f9586860.png)

# Step by Step guide - Manual Execution (Learning purpose)

## Prerequisite - Setting up new MLOPS

### Use Visual Studio Code to clone this repository:

![image](https://user-images.githubusercontent.com/31459994/192029368-4faaf3e2-d160-4cbd-830a-c29ed9218624.png)

![image](https://user-images.githubusercontent.com/31459994/192029880-f2310bd5-cbab-452e-89b0-d6fdf6a281be.png)


If you need any assistance to set this up, check the link below:

[VSCode - Source Control](https://code.visualstudio.com/docs/sourcecontrol/overview)

### **IMPORTANT!!!** Execute the demo in the root folder of your project

Authenticate using az login

```PowerShell
az login
```

Also set the default subscription id

```PowerShell
az account set --subscription "YOUR-SUBSCRIPTION-ID"
```


Open a New Terminal

![image](https://user-images.githubusercontent.com/31459994/192061495-90f3ac5c-9367-4daa-aad9-a1d91cd12870.png)

Use the root folder for this demo

![image](https://user-images.githubusercontent.com/31459994/192061574-b38230b4-05e8-4ff8-8a58-17a9424bb353.png)

### Edit the **env.ps1** file in the **scripts** folder

Update the **$resource_sufix** parameter before setting the environment variables (executing the env.ps1)

![image](https://user-images.githubusercontent.com/31459994/192061284-b67169b3-7778-49e6-9f62-e87a2e9f3a2e.png)

### Execute the PS script to set the environment variables

```PowerShell
. .\scripts\env.ps1
```

### Create the ML resource group you will use in this demo

```PowerShell
az group create -l $resource_region -n $resource_group_ml
```

### Create the 3 AML Workspaces to use in this demo (Dev, Test and Prod)

01 - Create Dev Workspace

```PowerShell
az ml workspace create --resource-group $resource_group_ml --name $workspace01 --location $resource_region --display-name "Dev Workspace"
```

02 - Create Test Workspace

```PowerShell
az ml workspace create --resource-group $resource_group_ml --name $workspace02 --location $resource_region --display-name "Test Workspace"
```

03 - Create Prod Workspace

```PowerShell
az ml workspace create --resource-group $resource_group_ml --name $workspace03 --location $resource_region --display-name "Prod Workspace"
```

You should see this in your RG after this step

![image](https://user-images.githubusercontent.com/31459994/192062910-e1d306ca-7c1d-41cf-af2c-273a503bd966.png)


### Create a Storage Account

Create the storage account group

```PowerShell
az group create -l $resource_region -n $resource_group_stg
```

Create a storage account 

```PowerShell
az storage account create --name $storage_name --resource-group $resource_group_stg --location $resource_region --sku Standard_ZRS --kind StorageV2 --enable-hierarchical-namespace true
```

**Important: Storage account names are unique. Make sure to use a different sufix in a new demo

### Create a User Managed Identity

Execute the cmd below. It will store the ID if the managed identity in the $managed_identity_id

```PowerShell
$managed_identity_id=$(az identity create  -n $managed_identity_mlgroup --query id -o tsv -g $resource_group_ml)
```

### Create Compute in all AML workspaces

Dev: 

```PowerShell
az ml compute create -f ./compute/computedev.yml --workspace-name $workspace01 --resource-group $resource_group_ml --identity-type user_assigned --user-assigned-identities $managed_identity_id
```

Test: 

```PowerShell
az ml compute create -f ./compute/computetest.yml --workspace-name $workspace02 --resource-group $resource_group_ml --identity-type user_assigned --user-assigned-identities $managed_identity_id
```

Prod: 

```PowerShell
az ml compute create -f ./compute/computeprod.yml --workspace-name $workspace03 --resource-group $resource_group_ml --identity-type user_assigned --user-assigned-identities $managed_identity_id
```

Grant access on the Storage Account you will use for the demo:


```PowerShell
$storage_acc_id=$(az storage account show --name $storage_name --resource-group $resource_group_stg --query id -o tsv)

$managed_identity_principal_id=$(az identity show --name $managed_identity_mlgroup --resource-group $resource_group_ml --query principalId -o tsv)

az role assignment create --role "Storage Blob Data Owner" --assignee-object-id $managed_identity_principal_id --scope $storage_acc_id
```

![image](https://user-images.githubusercontent.com/31459994/192065630-f51fd071-0453-4cac-872e-cd70d31eb326.png)



Grant access to the AML Workspaces managed identities:

```PowerShell
$workspace01spID=$(az resource list -n $workspace01 --resource-group $resource_group_ml --query [*].identity.principalId --out tsv)
$workspace02spID=$(az resource list -n $workspace02 --resource-group $resource_group_ml --query [*].identity.principalId --out tsv)
$workspace03spID=$(az resource list -n $workspace03 --resource-group $resource_group_ml --query [*].identity.principalId --out tsv)

az role assignment create --role "Storage Blob Data Owner" --assignee-object-id $workspace01spID --scope $storage_acc_id
az role assignment create --role "Storage Blob Data Owner" --assignee-object-id $workspace02spID --scope $storage_acc_id
az role assignment create --role "Storage Blob Data Owner" --assignee-object-id $workspace03spID --scope $storage_acc_id
```

Also give access to your own id

```PowerShell
$selfid=$(az ad signed-in-user show --query id -o tsv)
az role assignment create --role "Storage Blob Data Owner" --assignee-object-id $selfid --scope $storage_acc_id
```

Storage Access Control screenshot
![image](https://user-images.githubusercontent.com/31459994/192066302-2f920320-7cd5-4b36-a77b-02c64c6e4a03.png)


### Create the containers in the Storage Account

```PowerShell
az storage container create --name mlopsdemodev --account-name $storage_name --resource-group $resource_group_stg
az storage container create --name mlopsdemotest --account-name $storage_name --resource-group $resource_group_stg
az storage container create --name mlopsdemoprod --account-name $storage_name --resource-group $resource_group_stg
```


Use the following structure in test and prod containers

![image](https://user-images.githubusercontent.com/31459994/189990148-a45364ef-ec1d-41b6-8f2b-4c58b1ee4a61.png)


Upload the file **taxi-batch.csv** to test and prod containers under the **taxibatch** directory. The file is in the **/data** directory


## 1) Dev Steps - Workspace 01 (Dev)

### Create AML Environment

```powershell
az ml environment create --file ./dev/train-env.yml --workspace-name mlopsdemojb01 --resource-group rg-ml-mlopsworkspaces-jb
```

### Pipeline run

```powershell
az ml job create --file ./dev/pipeline.yml --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb01
```

## 2) Test Steps - Workspace 02 (Test)

### Create AML Enviroment

```powershell
az ml environment create --file ./test/test-env.yml --workspace-name mlopsdemojb02 --resource-group rg-ml-mlopsworkspaces-jb
```

### Create datastore and data asset

Datastore

```powershell
az ml datastore create --file ./test/data-store.yml --workspace-name mlopsdemojb02 --resource-group rg-ml-mlopsworkspaces-jb
```

Data Asset

```powershell
az ml data create -f ./test/file-data-asset.yml --workspace-name mlopsdemojb02 --resource-group rg-ml-mlopsworkspaces-jb
```

### Download model from Dev Workspace

```powershell
az ml model download --name taxi-model-mlops-demo --version 1 --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb01 --download-path ./model
```

### Register model on Test Workspace

```powershell
az ml model create --name taxi-test-model-mlops-demo --version 1 --path ./model/taxi-model-mlops-demo --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb02
```

### Register Batch Endpoint

```powershell
az ml batch-endpoint create --file ./test/batch-endpoint-test.yml --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb02
```

### Register Batch Deployment

```powershell
az ml batch-deployment create --file ./test/batch-deployment-test.yml --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb02
```

### Execute Batch Job

```powershell
az ml batch-endpoint invoke --name taxi-fare-batch-mlopsdemo-test --deployment-name batch-dp-mlopsdemo-test  --input-type uri_file --input azureml://datastores/mlopsdemotestcointainer/paths/taxibatch/taxi-batch.csv  --resource-group rg-ml-mlopsworkspaces-jb  --workspace-name mlopsdemojb02 --output-path azureml://datastores/mlopsdemotestcointainer/paths/taxioutput
```

## 3) Prod Steps - Workspace 03 (Prod)

### Create Environment

```powershell
az ml environment create --file ./prod/prod-env.yml --workspace-name mlopsdemojb03 --resource-group rg-ml-mlopsworkspaces-jb
```

### Create datastore and data asset

Datastore

```powershell
az ml datastore create --file ./prod/data-store.yml --workspace-name mlopsdemojb03 --resource-group rg-ml-mlopsworkspaces-jb
```

Data Asset

```powershell
az ml data create -f ./prod/file-data-asset.yml --workspace-name mlopsdemojb03 --resource-group rg-ml-mlopsworkspaces-jb
```

### Download model from Dev Workspace

Already done in Test step

### Register Model

```powershell
az ml model create --name taxi-prod-model-mlops-demo --version 1 --path ./model/taxi-model-mlops-demo --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb03
```

### Register Batch Endpoint

```powershell
az ml batch-endpoint create --file ./prod/batch-endpoint-prod.yml --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb03
```

### Register Batch Deployment

```powershell
az ml batch-deployment create --file ./prod/batch-deployment-prod.yml --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb03
```

### Execute Batch Job

```powershell
az ml batch-endpoint invoke --name taxi-fare-batch-mlopsdemo-prod --deployment-name batch-dp-mlopsdemo-prod --input-type uri_file --input azureml://datastores/mlopsdemoprodcointainer/paths/taxibatch/taxi-batch.csv --resource-group rg-ml-mlopsworkspaces-jb --workspace-name mlopsdemojb03 --output-path azureml://datastores/mlopsdemoprodcointainer/paths/taxioutput
```

## Demo Outcomes

### Dev Workspace

![image](https://user-images.githubusercontent.com/31459994/189990789-c095bd4a-4a98-42cf-a2c1-85ed2fab1bdb.png)

![image](https://user-images.githubusercontent.com/31459994/189990983-93d28187-3b56-49b6-996e-f7379574b29e.png)

### Test Workspace

![image](https://user-images.githubusercontent.com/31459994/189991064-b49fc8c0-426e-47e3-9b4f-dfcb2bd368b6.png)

![image](https://user-images.githubusercontent.com/31459994/189991354-0ba0ba7f-143a-4c74-bdd7-9012af47a063.png)

![image](https://user-images.githubusercontent.com/31459994/189991391-595b1af4-b468-40e9-8142-84f7d9459508.png)

![image](https://user-images.githubusercontent.com/31459994/189991441-7841d995-7bc5-45e4-86c8-3db743b5e8b2.png)

### Prod Workspace

![image](https://user-images.githubusercontent.com/31459994/189991518-146b149c-6822-4710-9c3d-7818752d9bb7.png)

![image](https://user-images.githubusercontent.com/31459994/189991642-ba508cfc-3fa5-4c86-9ca7-8d9a1b9cb150.png)

![image](https://user-images.githubusercontent.com/31459994/189991684-ac0a69e2-8c83-4296-b2ad-dbc8ab08bf4d.png)

![image](https://user-images.githubusercontent.com/31459994/189991726-34e220fa-7040-4687-8603-23f58c4523ba.png)

---------------------------------------------------------------------------------------------------------------

# GitHub Actions

## Dev Actions

Please check the Actions section in this repository:

![image](https://user-images.githubusercontent.com/31459994/192027244-cd908da0-5969-4aff-a6d3-7a756da3dfc1.png)



---------------------------------------------------------------------------------------------------------------

# Coming Soon

## AML Registries

### Registries objectives:

- Registry is a collection of AzureML Assets that can be used by one or more Workspaces.
- Registries facilitate sharing of assets among teams working across multiple Workspaces in an organization. Registries, by virtue of sharing assets, enable MLOps flow of assets across dev -> test -> prod environments.
- Registries can make Workspaces more project centric by decoupling iterative assets in Workspaces and final/prod ready assets in Registries.
- Assets in Registries can be used by Workspaces in any region (specified while creating the a Registry), with the service transparently replicating necessary resources (code snapshots, docker images) in the background.

![image](https://user-images.githubusercontent.com/31459994/191634386-22994cae-8069-48a1-a64e-973bc15e1514.png)

## Feathr Feature Store

![image](https://user-images.githubusercontent.com/31459994/191637601-c0ebff42-0504-422d-960d-db39b2b3a17f.png)

### Feature store motivation

With the advance of AI and machine learning, companies start to use complex machine learning pipelines in various applications, such as recommendation systems, fraud detection, and more. These complex systems usually require hundreds to thousands of features to support time-sensitive business applications, and the feature pipelines are maintained by different team members across various business groups.

In these machine learning systems, we see many problems that consume lots of energy of machine learning engineers and data scientists, in particular duplicated feature engineering, online-offline skew, and feature serving with low latency.

![image](https://user-images.githubusercontent.com/31459994/191637867-1b4831d5-5a7e-40d6-bc23-5cc214ef8242.png)

Reference: [Feathr: LinkedIn’s feature store is now available on Azure](https://azure.microsoft.com/en-us/blog/feathr-linkedin-s-feature-store-is-now-available-on-azure/)

