# Set paths
$Env:HCIBoxDir = "C:\HCIBox"
$Env:HCIBoxLogsDir = "C:\HCIBox\Logs"
$Env:HCIBoxVMDir = "C:\HCIBox\Virtual Machines"
$Env:HCIBoxKVDir = "C:\HCIBox\KeyVault"
$Env:HCIBoxGitOpsDir = "C:\HCIBox\GitOps"
$Env:HCIBoxIconDir = "C:\HCIBox\Icons"
$Env:HCIBoxVHDDir = "C:\HCIBox\VHD"
$Env:HCIBoxSDNDir = "C:\HCIBox\SDN"
$Env:HCIBoxWACDir = "C:\HCIBox\Windows Admin Center"
$Env:agentScript = "C:\HCIBox\agentScript"
$Env:ToolsDir = "C:\Tools"
$Env:tempDir = "C:\Temp"
$Env:VMPath = "C:\VMs"

# Import Configuration Module
$ConfigurationDataFile = "$Env:HCIBoxDir\HCIBox-Config.psd1"
$SDNConfig = Import-PowerShellDataFile -Path $ConfigurationDataFile

Start-Transcript -Path $Env:HCIBoxLogsDir\Uninstall-ArcResourceBridge.log

# Set AD Domain cred
$user = "jumpstart.local\administrator"
$password = ConvertTo-SecureString -String $SDNConfig.SDNAdminPassword -AsPlainText -Force
$adcred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $password

$vnet = $SDNConfig.AKSvSwitchName
$subId = $env:subscriptionId
$rg = $env:resourceGroup
$resource_name = "HCIBox-ResourceBridge"
$custom_location_name = "hcibox-rb-cl"
$csv_path = "C:\ClusterStorage\S2D_vDISK1"

Invoke-Command -VMName $SDNConfig.HostList  -Credential $adcred -ScriptBlock {
    # Remove the vnet
    az azurestackhci virtualnetwork delete --subscription $using:subId --resource-group $using:rg --name $using:vnet --yes
    
    # Remove the gallery images
    $galleryImageName = "ubuntu20"
    az azurestackhci galleryimage delete --subscription $using:subId --resource-group $using:rg --name $galleryImageName --yes
    $galleryImageName = "win2k22"
    az azurestackhci galleryimage delete --subscription $using:subId --resource-group $using:rg --name $galleryImageName --yes

    # Remove the custom location
    az customlocation delete --resource-group $using:rg --name $using:custom_location_name --yes

    # Remove the Kubernetes extension
    az k8s-extension delete --cluster-type appliances --cluster-name "hcibox-resourcebridge" --resource-group $using:rg --name hci-vmoperator --yes

    # Remove the appliance
    az arcappliance delete hci --config-file $using:csv_path\ResourceBridge\hci-appliance.yaml --yes

    # Remove the config files
    Remove-ArcHciConfigFiles
}

Stop-Transcript
