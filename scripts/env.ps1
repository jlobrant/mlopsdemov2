# Setup parameters
# Please update the sufix before running setup scripts
$resource_sufix="demo"
# Parameters
$resource_region="eastus2"
$resource_group_ml="rg-demo-mlops-$($resource_sufix)"
$resource_group_stg="rg-demo-mlops-storage-$($resource_sufix)"
$workspace01="ml-mlopsdemo-$($resource_sufix)-01"
$workspace02="ml-mlopsdemo-$($resource_sufix)-02"
$workspace03="ml-mlopsdemo-$($resource_sufix)-03"
$storage_name="stgaccmlops2demo$($resource_sufix)"
$managed_identity_mlgroup="mlopsuidemo$($resource_sufix)"