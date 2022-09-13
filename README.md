# mlopsdemov2

![image](https://user-images.githubusercontent.com/31459994/189961497-b7516d79-594c-4f92-9234-0770f9586860.png)

# Setting up new MLOPS

Create Identity

az identity create  -n mlopsdemostgacc --query id -o tsv -g rg-ml-mlopsworkspaces-jb

Get the result and add the string in the create compute script.
Example: /subscriptions/.../resourcegroups/rg-ml-mlopsworkspaces-jb/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mlopsdemostgacc

Create Compute

Dev: az ml compute create -f ./compute/computedev.yml --workspace-name mlopsdemojb01 --resource-group rg-ml-mlopsworkspaces-jb
Test: az ml compute create -f ./compute/computetest.yml --workspace-name mlopsdemojb02 --resource-group rg-ml-mlopsworkspaces-jb
Prod: az ml compute create -f ./compute/computeprod.yml --workspace-name mlopsdemojb03 --resource-group rg-ml-mlopsworkspaces-jb

Grant access on the Storage Account you will use for the demo:

![image](https://user-images.githubusercontent.com/31459994/189962665-1ca157b1-fc19-4c5f-a6c1-1658c5750e95.png)

# Dev Steps - Workspace 01 (Dev)

## Create AML Environment

az ml environment create --file ./dev/train-env.yml --workspace-name mlopsdemojb01 --resource-group rg-ml-mlopsworkspaces-jb
