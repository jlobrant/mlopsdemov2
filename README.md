# MLOps - Step by step guide

![image](https://user-images.githubusercontent.com/31459994/192173420-d528a14c-0fb5-47f3-a5a5-0618a652589b.png)

This guide was inspired by the Azure MLOPs (v2) solution accelerator, and the goal is to help you understand all the steps involved in building the foundation of an ML environment with MLOps.

Check the MLOPs Solution Accelerator (v2) repository for more information:


[Azure MLOps (v2) solution accelerator](https://github.com/Azure/mlops-v2)


# Step by Step guide - Manual Execution (Learning purpose)

## Prerequisite - Setting up new MLOPS

### Fork this repository

In the top-right corner of the page, click **Fork**

![image](https://user-images.githubusercontent.com/31459994/192172615-25910aae-0e32-4816-9aa2-fadeb9dc4e0b.png)

Select an owner for the forked repository, optionally, add a description of your fork, and click Create fork.

![image](https://user-images.githubusercontent.com/31459994/192172409-f57c0d6b-2c48-4537-80be-2dbb1f189e80.png)

### Use Visual Studio Code to clone the forked repository:

![image](https://user-images.githubusercontent.com/31459994/192029368-4faaf3e2-d160-4cbd-830a-c29ed9218624.png)

![image](https://user-images.githubusercontent.com/31459994/192029880-f2310bd5-cbab-452e-89b0-d6fdf6a281be.png)

If you need help setting this up, check the link below:

[VSCode - Source Control](https://code.visualstudio.com/docs/sourcecontrol/overview)

### **IMPORTANT!!!** Execute the demo in the root folder of your project

Open a New Terminal

![image](https://user-images.githubusercontent.com/31459994/192061495-90f3ac5c-9367-4daa-aad9-a1d91cd12870.png)

Use the root folder for this demo

![image](https://user-images.githubusercontent.com/31459994/192061574-b38230b4-05e8-4ff8-8a58-17a9424bb353.png)

### Authenticate using az login

```PowerShell
az login
```

![image](https://user-images.githubusercontent.com/31459994/192172839-a32dacc5-3928-49a2-bbce-f1b728e19bb7.png)


![image](https://user-images.githubusercontent.com/31459994/192172780-2a10233a-44b8-4f10-b85c-5d0ff22e4654.png)



### Edit the **env.ps1** file in the **scripts** folder

***IMPORTANT! Update the **$resource_sufix** parameter and **$subscriptionId** before setting the environment variables (executing the env.ps1)***

![image](https://user-images.githubusercontent.com/31459994/192129117-b06224db-2839-4f4c-8961-18a3ae08e77b.png)

### Execute the PS script to set the environment variables

```PowerShell
. .\scripts\env.ps1
```

Check at least one of the variables to make sure the environment variables are set

```PowerShell
Write-Output $resource_sufix
```

![image](https://user-images.githubusercontent.com/31459994/192173079-bc0b68a3-9df1-4f9b-b364-687e826cb1ef.png)


Set the default subscription id

```PowerShell
az account set --subscription $subscriptionId
```

### Create the ML resource group you will use in this demo

```PowerShell
az group create -l $resource_region -n $resource_group_ml
```

### Create the 3 AML Workspaces that you need for this demo (Dev, Test and Prod)

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

***Important: Storage account names are unique. Make sure to use a different sufix in a new demo***

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

![image](https://user-images.githubusercontent.com/31459994/192067816-f7eb4731-a43b-4aa5-90df-966aa484c8a1.png)

Upload the csv file that will be used in batch deployment to the proper directory

```PowerShell
az storage azcopy blob upload -c mlopsdemotest --account-name $storage_name -s "data/taxi-batch.csv" -d "taxibatch/taxi-batch.csv"

az storage azcopy blob upload -c mlopsdemotest --account-name $storage_name -s "data/taxi-request.json" -d "taxioutput/taxi-request.json"
```

![image](https://user-images.githubusercontent.com/31459994/192067983-ebe18c6f-7961-4521-b856-f7b8b1f13aaa.png)

Repeat for **prod** container

```PowerShell
az storage azcopy blob upload -c mlopsdemoprod --account-name $storage_name -s "data/taxi-batch.csv" -d "taxibatch/taxi-batch.csv"

az storage azcopy blob upload -c mlopsdemoprod --account-name $storage_name -s "data/taxi-request.json" -d "taxioutput/taxi-request.json"
```

## 1) Dev Workspace Steps

In this step you will run a job in the Dev workspace and register a model. This model will be later transfered to Test and Prod workspaces in the following steps.

### Create AML Environment

```powershell
az ml environment create --file ./dev/train-env.yml --workspace-name $workspace01 --resource-group $resource_group_ml
```

### Pipeline run

```powershell
az ml job create --file ./dev/pipeline.yml --resource-group $resource_group_ml --workspace-name $workspace01
```

After this command, a pipeline will be triggered in the Dev workspace. The result of this execution is a model being registered in the Dev workspace.

![image](https://user-images.githubusercontent.com/31459994/192121950-1b336999-be3f-498e-bcb2-b79af391a797.png)

![image](https://user-images.githubusercontent.com/31459994/192122667-03194aec-07ec-421e-90de-2aa66eccec13.png)


## 2) Test Workspace Steps

### Create AML Enviroment

```powershell
az ml environment create --file ./test/test-env.yml --workspace-name $workspace02 --resource-group $resource_group_ml
```

### Create datastore and data asset

Datastore

```powershell
az ml datastore create --file ./test/data-store.yml --workspace-name $workspace02 --resource-group $resource_group_ml --set account_name=$storage_name
```

Data Asset

```powershell
az ml data create -f ./test/file-data-asset.yml --workspace-name $workspace02 --resource-group $resource_group_ml
```

### Download model from Dev Workspace

```powershell
az ml model download --name taxi-model-mlops-demo --version 1 --resource-group $resource_group_ml --workspace-name $workspace01 --download-path ./model
```

### Register model on Test Workspace

```powershell
az ml model create --name taxi-test-model-mlops-demo --version 1 --path ./model/taxi-model-mlops-demo --resource-group $resource_group_ml --workspace-name $workspace02
```

### Register Batch Endpoint

```powershell
$endpoint_name_test = "taxifare-b-mldemo-t-$resource_sufix"

az ml batch-endpoint create --file ./test/batch-endpoint-test.yml --resource-group $resource_group_ml --workspace-name $workspace02 --set name=$endpoint_name_test
```

### Register Batch Deployment

```powershell
az ml batch-deployment create --file ./test/batch-deployment-test.yml --resource-group $resource_group_ml --workspace-name $workspace02 --set endpoint_name=$endpoint_name_test
```

### Execute Batch Job

```powershell
az ml batch-endpoint invoke --name $endpoint_name_test --deployment-name batch-dp-mlopsdemo-test  --input-type uri_file --input azureml://datastores/mlopsdemotestcointainer/paths/taxibatch/taxi-batch.csv --resource-group $resource_group_ml --workspace-name $workspace02 --output-path azureml://datastores/mlopsdemotestcointainer/paths/taxioutput
```

This command will invoke a job, that will use the deployed model in the test workspace, and generate the results from the data in the **taxi-batch.csv** in the **taxioutput** folder in the test container

![image](https://user-images.githubusercontent.com/31459994/192123162-04e811f2-b363-471f-8f90-3d2f993df122.png)

![image](https://user-images.githubusercontent.com/31459994/192123493-2b161819-9f4d-452c-be5c-b9f331b797c2.png)

![image](https://user-images.githubusercontent.com/31459994/192123516-afcbe6a0-b668-4b18-908a-cdfbded43d3d.png)

![image](https://user-images.githubusercontent.com/31459994/192123532-1f4de0bb-f452-410d-aa47-edb336fc4f98.png)


Now you can verify the results and analyze the performance of the model using shadow production data.


## 3) Prod Steps - Workspace 03 (Prod)

### Create Environment

```powershell
az ml environment create --file ./prod/prod-env.yml --workspace-name $workspace03 --resource-group $resource_group_ml
```

### Create datastore and data asset

Datastore

```powershell
az ml datastore create --file ./prod/data-store.yml --workspace-name $workspace03 --resource-group $resource_group_ml --set account_name=$storage_name
```

Data Asset

```powershell
az ml data create -f ./prod/file-data-asset.yml --workspace-name $workspace03 --resource-group $resource_group_ml
```

### Download model from Dev Workspace

Already done in Test step.

### Register Model

```powershell
az ml model create --name taxi-prod-model-mlops-demo --version 1 --path ./model/taxi-model-mlops-demo --resource-group $resource_group_ml --workspace-name $workspace03
```

### Register Batch Endpoint

```powershell
$endpoint_name_prod = "taxifare-b-mldemo-p-$resource_sufix"

az ml batch-endpoint create --file ./prod/batch-endpoint-prod.yml --resource-group $resource_group_ml --workspace-name $workspace03 --set name=$endpoint_name_prod
```

### Register Batch Deployment

```powershell
az ml batch-deployment create --file ./prod/batch-deployment-prod.yml --resource-group $resource_group_ml --workspace-name $workspace03 --set endpoint_name=$endpoint_name_prod
```

### Execute Batch Job

```powershell
az ml batch-endpoint invoke --name $endpoint_name_prod --deployment-name batch-dp-mlopsdemo-prod --input-type uri_file --input azureml://datastores/mlopsdemoprodcointainer/paths/taxibatch/taxi-batch.csv --resource-group $resource_group_ml --workspace-name $workspace03 --output-path azureml://datastores/mlopsdemoprodcointainer/paths/taxioutput
```
<br /><br />
**We expect to get the same results in the Test Workspace and Production Workspace in this demo, but the idea is that the file in the prod container is the actual production data, as the file in the test container is shadow production data, which means some actual data that was selected to test the model**

<br /><br />
**The Development, Test and Production environment in a real use case will be used with different datasets**


---------------------------------------------------------------------------------------------------------------

# GitHub Actions

## Setup GitHub Authentication

### Create application and service principal

You'll need to create an Azure Active Directory application and service principal and then assign a role on your subscription to your application so that your workflow has access to your subscription

You will create one Service Principal per environment

```powershell
$githubapp_dev="gitAppdev$resource_sufix"
$githubapp_test="gitApptest$resource_sufix"
$githubapp_prod="gitAppprod$resource_sufix"

az ad app create --display-name $githubapp_dev
az ad app create --display-name $githubapp_test
az ad app create --display-name $githubapp_prod

$githubapp_dev_cid=$(az ad app list --display-name $githubapp_dev --query [*].appId -o tsv)
$githubapp_dev_oid=$(az ad app list --display-name $githubapp_dev --query [*].id -o tsv)
az ad sp create --id $githubapp_dev_cid

$githubapp_dev_assigneeid=$(az ad sp show --id $githubapp_dev_cid --query id -o tsv)
az role assignment create --role contributor --subscription $subscriptionId --assignee-object-id  $githubapp_dev_assigneeid --assignee-principal-type ServicePrincipal --scope /subscriptions/$subscriptionId/resourceGroups/$resource_group_ml

$githubapp_test_cid=$(az ad app list --display-name $githubapp_test --query [*].appId -o tsv)
$githubapp_test_oid=$(az ad app list --display-name $githubapp_test --query [*].id -o tsv)
az ad sp create --id $githubapp_test_cid

$githubapp_test_assigneeid=$(az ad sp show --id $githubapp_test_cid --query id -o tsv)
az role assignment create --role contributor --subscription $subscriptionId --assignee-object-id  $githubapp_test_assigneeid --assignee-principal-type ServicePrincipal --scope /subscriptions/$subscriptionId/resourceGroups/$resource_group_ml


$githubapp_prod_cid=$(az ad app list --display-name $githubapp_prod --query [*].appId -o tsv)
$githubapp_prod_oid=$(az ad app list --display-name $githubapp_prod --query [*].id -o tsv)
az ad sp create --id $githubapp_prod_cid

$githubapp_prod_assigneeid=$(az ad sp show --id $githubapp_prod_cid --query id -o tsv)
az role assignment create --role contributor --subscription $subscriptionId --assignee-object-id  $githubapp_prod_assigneeid --assignee-principal-type ServicePrincipal --scope /subscriptions/$subscriptionId/resourceGroups/$resource_group_ml

```

Set your GitHub name as an environment variable, and also the repository name

Replace with yout GitHub account

```powershell
$github_org="jlobrant"
$github_repo="mlopsdemov2"
```

Configure the GitHub connection

```powershell
$devgraphuri="https://graph.microsoft.com/beta/applications/$githubapp_dev_oid/federatedIdentityCredentials"
$devgraphbody="{'name':'GitHubDevDeploy','issuer':'https://token.actions.githubusercontent.com','subject':'repo:$github_org/${github_repo}:environment:Dev','description':'Development Environment','audiences':['api://AzureADTokenExchange']}"

az rest --method POST --uri $devgraphuri --body $devgraphbody
```

After this step, you will see the credential configured in the Azure portal under Application Registrations. Select the service principal you just created and select certificates and secrets from the menu on the left as shown in the screenshot below:
<br />

![image](https://user-images.githubusercontent.com/31459994/192126260-6bba566c-9abf-45f4-94f7-e45682212dca.png)

Repeat this step for the Test and Prod Apps

```powershell
$testgraphuri="https://graph.microsoft.com/beta/applications/$githubapp_test_oid/federatedIdentityCredentials"
$testgraphbody="{'name':'GitHubTestDeploy','issuer':'https://token.actions.githubusercontent.com','subject':'repo:$github_org/${github_repo}:environment:Test','description':'Test Environment','audiences':['api://AzureADTokenExchange']}"

az rest --method POST --uri $testgraphuri --body $testgraphbody
```

```powershell
$prodgraphuri="https://graph.microsoft.com/beta/applications/$githubapp_prod_oid/federatedIdentityCredentials"
$prodgraphbody="{'name':'GitHubProdDeploy','issuer':'https://token.actions.githubusercontent.com','subject':'repo:$github_org/${github_repo}:environment:Prod','description':'Prod Environment','audiences':['api://AzureADTokenExchange']}"

az rest --method POST --uri $prodgraphuri --body $prodgraphbody
```

## Configure your GitHub

### Create the Environments in your GitHub repository

This step will be necessary to allow you build an end2end Actions workflow

![image](https://user-images.githubusercontent.com/31459994/192126516-4678deb0-8aa3-4332-8585-e8b5a6729fe4.png)

Under Environment secrets, create secrets for **AZURE_CLIENT_ID**, **AZURE_TENANT_ID**, and **AZURE_SUBSCRIPTION_ID**

![image](https://user-images.githubusercontent.com/31459994/192126618-ebab502b-49d9-4704-92bf-76f057367701.png)

Get the values in App Resgistrations on Azure Portal. Also get your Subscription ID value

![image](https://user-images.githubusercontent.com/31459994/192126658-47cbe81c-43b6-4926-a4a0-fc201b8620cc.png)

Also, create a resource group secret and a workspace secret with the RG name and the workspace of the environment (example: Dev, Test and Prod according to the workspaces name)

![image](https://user-images.githubusercontent.com/31459994/192126779-cba3aea1-f592-488b-917c-5fcbb1d29428.png)

In Dev, use the value of the variable $workspace01, in Test $workspace02 and Prod $workspace03

***IMPORTANT: Also create a WORKSPACE_NAME_DEV secret in Test and Prod, as you will need this to donwload the model from Dev to Register in the proper environment***

![image](https://user-images.githubusercontent.com/31459994/192128261-59e0aded-bf83-4625-bde2-4ce11d2ef71b.png)

Use the value from parameter $workspace01

<br /><br />

### Workflow Sample

The following workflow sample is configured in this repository. This example will run a pipeline in Dev workspace, download the model and register the model in Test and Prod environment. You can improve this by adding other actions like invoking the endpoints and evaluating the results of the batch invoke

```YAML
on:
      push:
            paths:
                  - 'data-science/**'

permissions:
      id-token: write
      contents: read

jobs:
  Pipeline-Dev:
    runs-on: ubuntu-latest
    environment: Dev
    steps:
    
    - name: check out repo
      uses: actions/checkout@v2
    
    - name: login
      uses: azure/login@v1
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        

    - name: Setup Azure ML Cli
      run: bash setupml.sh
      working-directory: scripts
            
    - name: Execute ML Pipeline
      run: az ml job create --file ./dev/pipeline.yml --resource-group ${{ secrets.RESOURCE_GROUP }} --workspace-name ${{ secrets.WORKSPACE_NAME }}

  Promote-to-Test:
    runs-on: ubuntu-latest
    environment: Test
    needs: [Pipeline-Dev]
    steps:
    
    - name: check out repo
      uses: actions/checkout@v2
    
    - name: login
      uses: azure/login@v1
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        

    - name: Setup Azure ML Cli
      run: bash setupml.sh
      working-directory: scripts

    - name: Download Model
      run: az ml model download --name taxi-model-mlops-demo --version 1 --resource-group ${{ secrets.RESOURCE_GROUP }} --workspace-name ${{ secrets.WORKSPACE_NAME_DEV }} --download-path ./model
            
    - name: Register Model Test
      run: az ml model create --name taxi-test-model-mlops-demo --version 1 --path ./model/taxi-model-mlops-demo --resource-group ${{ secrets.RESOURCE_GROUP }} --workspace-name ${{ secrets.WORKSPACE_NAME }}

  Promote-to-Prod:
    runs-on: ubuntu-latest
    environment: Prod
    needs: [Pipeline-Dev,Promote-to-Test]
    steps:
    
    - name: check out repo
      uses: actions/checkout@v2
    
    - name: login
      uses: azure/login@v1
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        

    - name: Setup Azure ML Cli
      run: bash setupml.sh
      working-directory: scripts
            
    - name: Download Model
      run: az ml model download --name taxi-model-mlops-demo --version 1 --resource-group ${{ secrets.RESOURCE_GROUP }} --workspace-name ${{ secrets.WORKSPACE_NAME_DEV }} --download-path ./model
            
    - name: Register Model Prod
      run: az ml model create --name taxi-test-model-mlops-demo --version 1 --path ./model/taxi-model-mlops-demo --resource-group ${{ secrets.RESOURCE_GROUP }} --workspace-name ${{ secrets.WORKSPACE_NAME }}
```

This workflow is configure to trigger the action when you make some changes in the python code inside the **data-science** folder

### Configuring Manual Approvals

For the Test and Prod environment, configure the **Environment protection rules**. Add at least one login in the **Required reviewers**

![image](https://user-images.githubusercontent.com/31459994/192127532-b3b3d4b0-bd43-4775-8558-462c178d9c10.png)

![image](https://user-images.githubusercontent.com/31459994/192127545-48e38124-8f48-41bc-9806-6829a53ff91b.png)

This way, the MLOps process will require a review before moving the model to Test and later to Prod
<br /><br />

As you submit an Action and a manual approval is required, you will receive an email requesting approval
<br /><br />
![image](https://user-images.githubusercontent.com/31459994/192127648-3e14075c-5cbb-4e49-9224-844d780ddf5c.png)
<br /><br />

Click **review deployments** to approve and release the task
![image](https://user-images.githubusercontent.com/31459994/192127656-e78cd0b0-08d1-449f-9428-52b7160c8eb7.png)

![image](https://user-images.githubusercontent.com/31459994/192127670-93508cbf-671f-4413-8daa-b0bac6f022dc.png)

<br /><br />

Do the same for Production environment

![image](https://user-images.githubusercontent.com/31459994/192127700-a723e9f4-f3b0-4089-8726-e33a823286d5.png)

![image](https://user-images.githubusercontent.com/31459994/192127713-10bcb3e4-9c64-4981-88f8-41ed173e4837.png)

<br /><br />

WE DID IT!!!
![image](https://user-images.githubusercontent.com/31459994/192127859-9215acc3-43e1-49ee-b69d-e42dbb1b074c.png)

<br /><br />

***If you've followed all the steps correctly up to this point, you now have your MLOps working and now it's time to improve your repository based on your needs***

---------------------------------------------------------------------------------------------------------------

# Coming Soon

## Azure ML Registries (Preview)

Azure Machine Learning entities can be grouped into two broad categories:

- Assets such as models, environments, components, and datasets are durable entities that are workspace agnostic. For example, a model can be registered with any workspace and deployed to any endpoint.
- Resources such as compute, job, and endpoints are transient entities that are workspace specific. For example, an online endpoint has a scoring URI that is unique to a specific instance in a specific workspace. Similarly, a job runs for a known duration and generates logs and metrics each time it's run.

Assets lend themselves to being stored in a central repository and used in different workspaces, possibly in different regions. Resources are workspace specific.

AzureML registries (preview) enable you to create and use those assets in different workspaces. Registries support multi-region replication for low latency access to assets, so you can use assets in workspaces located in different Azure regions. Creating a registry will provision Azure resources required to facilitate replication. First, Azure blob storage accounts in each supported region. Second, a single Azure Container Registry with replication enabled to each supported region.

[Manage Azure Machine Learning registries (preview)](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-manage-registries?tabs=cli)

![image](https://user-images.githubusercontent.com/31459994/201561724-d8f8171d-271d-4531-8802-d01875b953a3.png)

## Feathr Feature Store

![image](https://user-images.githubusercontent.com/31459994/191637601-c0ebff42-0504-422d-960d-db39b2b3a17f.png)

### Feature store motivation

With the advance of AI and machine learning, companies start to use complex machine learning pipelines in various applications, such as recommendation systems, fraud detection, and more. These complex systems usually require hundreds to thousands of features to support time-sensitive business applications, and the feature pipelines are maintained by different team members across various business groups.

In these machine learning systems, we see many problems that consume lots of energy of machine learning engineers and data scientists, in particular duplicated feature engineering, online-offline skew, and feature serving with low latency.

![image](https://user-images.githubusercontent.com/31459994/191637867-1b4831d5-5a7e-40d6-bc23-5cc214ef8242.png)

Reference: [Feathr: LinkedIn???s feature store is now available on Azure](https://azure.microsoft.com/en-us/blog/feathr-linkedin-s-feature-store-is-now-available-on-azure/)

