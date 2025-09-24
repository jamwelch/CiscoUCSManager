##########################################################################
#This script is a user-friendly way to modify the vlans in a vnic template in UCSM.
#It will remove all discrete vlans for a vnic template and add a vlan group to it.
#  !!!IMPORTANT!!!  This script is only intendend to be used for demonstration purposes representing what is capable in the UCS API using Powershell.
##########################################################################

#Sept.24.2025 - jamwelch@cisco.com
#version 1.1a - Sept.24.2025
#script tested with Powershell 7.5.3

#Check version of powershell
Get-Host | Select-Object Version

#Run this command first from powershell command line
#This installs the UCS Manager Powershell module from https://www.powershellgallery.com/packages/Cisco.UCSManager
#Internet access is required
#Install-Module -Name Cisco.UCSManager 
Import-Module Cisco.UCSManager

$VlanGrp = read-host -Prompt "Enter the name of the new VLAN Group to be added to the vnic templates.  The VLAN Group should already be in UCS Manager LAN Cloud.  Do Not include the prefix 'VLAN Group '. This is automatically added."

#Simple way to login to a single UCS domain and store login in a handle variable
$UCSM_IP1 = read-host -Prompt "Enter the IP address of UCS Manager"
$handle = Connect-Ucs $UCSM_IP1 -Credential (Get-Credential)

Add-Type -AssemblyName System.Windows.Forms

# Sample command to generate items (replace this with your actual command)
$items = Get-UcsVnicTemplate -Ucs $handle | Select-Object -ExpandProperty Name | Sort-Object -Unique

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Select Items"
$form.Size = New-Object System.Drawing.Size(300,400)
$form.StartPosition = "CenterScreen"

# Create CheckedListBox
$checkedListBox = New-Object System.Windows.Forms.CheckedListBox
$checkedListBox.Size = New-Object System.Drawing.Size(260,300)
$checkedListBox.Location = New-Object System.Drawing.Point(10,10)
$checkedListBox.SelectionMode = 'One'

# Add items to CheckedListBox
foreach ($item in $items) {
    $checkedListBox.Items.Add($item) | Out-Null
}

$form.Controls.Add($checkedListBox)

# Create OK button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Location = New-Object System.Drawing.Point(100,320)
$okButton.Add_Click({
    $form.Tag = $checkedListBox.CheckedItems
    $form.Close()
})

$form.Controls.Add($okButton)

# Show the form
$form.ShowDialog() | Out-Null

# Retrieve selected items
$selectedItems = $form.Tag

# Output selected items or a message if none selected
if ($selectedItems.Count -gt 0) {
    "You selected:"
    $selectedItems | ForEach-Object { $_ }
} else {
    "No items were selected."
}
Start-UcsTransaction -Ucs $handle

$selectedItems | ForEach-Object{
	#From the list of vnic templates that were selected, iterate through the list
	#Get the object of the vnic template
	$vnicTemplateObj = Get-UcsVnicTemplate -Ucs $handle -Name $_
	Write-Output "Working on removing vlans from " $vnicTemplateObj.Name
	#Get a list of vlans for the vnic template
	$vnicVlansList = $vnicTemplateObj | Get-UcsVnicInterface -Ucs $handle | Select-Object Name
	#Iterate through the list of vlans
	$vnicVLansList | ForEach-Object{
		#Remove each vlan from the vnic template
		$vnicTemplateObj | Get-UcsVnicInterface -Name $_.Name | Remove-UcsVnicInterface -Force
		#Write output to record the removal
		Write-Output "Removed" $_.Name
		#Add VLAN Group
		Start-UcsTransaction -Ucs $handle
		$vnicTemplateObj | Add-UcsFabricNetGroupRef -ModifyPresent -Name $VlanGrp
		Write-Output "VLAN Group " $VlanGrp " added"
	}
}
Complete-UcsTransaction -Ucs $handle
Disconnect-Ucs
