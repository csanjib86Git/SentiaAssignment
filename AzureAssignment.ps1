
<#
.SYNOPSIS
This is a script for creating Azure rm resources,Creating policy and assigning policy to the subscription and resource group In azure
.DESCRIPTION
a Resource Group with the name GRP-SentiaWE5 in West Europe
a Storage Account with name sentiaazurestorage1239 in the above created Resource Group, using encryption and an unique name, starting with the prefix 'sentia'
A Virtual Network in the above created Resource Group with three subnets, using 172.16.0.0/12 as the address prefix
Apply the following tags to the resource group: Environment='Test', Company='Sentia'
Create a policy definition using a template and parameter file, to restrict the resourcetypes to only allow: compute, network and storage resourcetypes
Assign the policy definition to the subscription and resource group created previously
.PARAMETER SubscriptionId
This is the subscrition ID for which need to be provided while execuring the Script
.EXAMPLE
AzureAssignment -SubscriptionId <subscriptionID>
.NOTES
    Author: Sanjib Chakraborty
    Date:   June 1st, 2018
    Version: 1.0
#>
Param(
    [Parameter(Mandatory=$True)]
    [String]
    $SubscriptionId
    )

#Declaring Varialbles
$ResourceGroup = "GRP-SentiaWE5"
$resourceGroupLocation = "West Europe"
$VirtualNetwork = "SentiaVirtualNetwork"
$storageAccountName = "sentiaazurestorage1239"
$templateFilePath = "C:\temp1\template.json"
$ParameterFilePath = "C:\temp1\rule.json"

<#
.SYNOPSIS
    Registers RP
#>
Function RegisterRP {
    Param(
        [String]$ResourceProviderNamespace
        )

        Write-Host "Registering resource provider '$ResourceProviderNamespace'";
        Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

################################################################
#Script body
################################################################

# Sign in
Write-Host "Log in...";
Login-AzureRmAccount;

#select subsciption
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzureRmSubscription -SubscriptionId $SubscriptionId;

#Register Resource Providers
$ResourceProviders = @("microsoft.compute","microsoft.network","microsoft.storage");
if($resourceProviders.length) {
    Write-Host "Registering resource providers" -ForegroundColor Blue -BackgroundColor Yellow
    foreach($resourceProvider in $resourceproviders) {
        RegisterRP($resourceprovider);
    Write-Host "$resourceProvider has been registered" -ForegroundColor Blue -BackgroundColor Green
    }
}
 
#Create for existing resource group in "West Europe" with the following tags to the resource group: Environment='Test', Company='Sentia'

Write-Host "Creating a new Resource Group with Name '$ResourceGroup' in '$resourceGroupLocation' the following tags to the resource group: Environment='Test', Company='Sentia'" -ForegroundColor Blue -BackgroundColor Yellow
$RmGroup = New-AzureRmResourceGroup -Name "$ResourceGroup" -Location $resourceGroupLocation -Tag @{Environment='Test'; Company='Sentia'} -Force -Confirm
$rmGroupName = $RmGroup.ResourceGroupname
$rmGroupName
#$rmgroup.resourceID
Write-Host "Azure Resource Group "$ResourceGroup" has been created" -ForegroundColor Blue -BackgroundColor Green

#Creating a Storage Account in $rmGroupName
Write-Host "Creating a storage account in $rmGroupName" -ForegroundColor Blue -BackgroundColor Yellow
$rmStorage = New-AzureRmStorageAccount -Name "$storageAccountName" -ResourceGroupName $rmGroupName -SkuName Standard_GRS -Location "$resourceGroupLocation"
Write-Host "Storage account '$storageAccountName' has been created" -ForegroundColor Blue -BackgroundColor Green

#Creating a Virtual Network in $rmGroupName with three subnets
Write-Host "Creating 1st subnet with the name 'Subnet1'" -ForegroundColor Blue -BackgroundColor Yellow
$Subnet1 = New-AzureRmVirtualNetworkSubnetConfig -Name Subnet1 -AddressPrefix "172.16.0.0/14"
Write-Host "$Subnet1 has been craeted, will create 2nd subnet..." -ForegroundColor Blue -BackgroundColor Green

Write-Host "Creating 2nd subnet with the name 'Subnet2'" -ForegroundColor Blue -BackgroundColor Yellow
$Subnet2 = New-AzureRmVirtualNetworkSubnetConfig -Name Subnet2  -AddressPrefix "172.20.0.0/14"
Write-Host "Subnet2 has been craeted, will create 3rd subnet..." -ForegroundColor Blue -BackgroundColor Green

Write-Host "Creating 3rd subnet with the name 'Subnet3'" -ForegroundColor Blue -BackgroundColor Yellow
$Subnet3 = New-AzureRmVirtualNetworkSubnetConfig -Name Subnet3  -AddressPrefix "172.24.0.0/14"
Write-Host "Subnet3 has been craeted, " -ForegroundColor Blue -BackgroundColor Green

Write-Host "Creating the Virtual network '$VirtualNetwork' with previously created subnets" -ForegroundColor Blue -BackgroundColor Yellow
New-AzureRmVirtualNetwork -Name $VirtualNetwork -ResourceGroupName $rmGroupName -Location $resourceGroupLocation -AddressPrefix "172.16.0.0/12" -Subnet $Subnet1,$Subnet2,$subnet3
Write-Host "'$VirtualNetwork' has been created with previously created subnets" -ForegroundColor Blue -BackgroundColor Green


#Create a policy definition using a template and parameter file, to restrict the resourcetypes to only allow: compute, network and storage resourcetypes
Write-Host "Creating a policy definition with name 'Allowed-Resourcetypes'" -ForegroundColor Blue -BackgroundColor Yellow
$definition = New-AzureRmPolicyDefinition -Name "allowed-resourcetypes" -DisplayName "Allowed resource types" -description "This policy enables you to specify the resource types that your organization can deploy." -Policy 'https://raw.githubusercontent.com/Azure/azure-policy/master/samples/built-in-policy/allowed-resourcetypes/azurepolicy.rules.json' -Parameter 'https://raw.githubusercontent.com/Azure/azure-policy/master/samples/built-in-policy/allowed-resourcetypes/azurepolicy.parameters.json' -Mode All
$definition
Write-Host "Policy Definistion 'Allowed-Resourcetypes' has been created" -ForegroundColor Blue -BackgroundColor Green

#Assign the created policy defintion using a template file
Write-Host "Creating an assignment with name 'Allowed-Resourcetypesassignment'" -ForegroundColor Blue -BackgroundColor Yellow
$assignment = New-AzureRMPolicyAssignment -Name "allowed-resourcetypesassignment" -listOfResourceTypesAllowed "C:\temp1\rule.json" -PolicyDefinition $definition -Scope $rmgroup.resourceID
$assignment
Write-Host "An assignment with name 'Allowed-Resourcetypesassignment' has been created" -ForegroundColor Blue -BackgroundColor Green







