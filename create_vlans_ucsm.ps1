#Feb.1.2021 -jamwelch@cisco.com
#script tested with Powershell 5.1.19041.610

#Check version of powershell
Get-Host | Select-Object Version

#Run this command first from powershell command line
#Install-Module -Name Cisco.UCSManager 
Import-Module Cisco.UCSManager

#Login to UCS, saves login to  file in the location specified
$DirPath = read-host -Prompt "Enter the path (i.e. c:\path) where you want the credential file created"
New-Item -ItemType Directory ucs-sessions -Force
$UCSM_IP1 = read-host -Prompt "Enter the IP address of UCS Manager"
Connect-Ucs $UCSM_IP1
$CredPath = $DirPath + '\ucs-sessions\ucscreds.xml'
Export-UcsPSSession -Path $CredPath
Disconnect-Ucs
$handle = Connect-Ucs -Path $CredPath

#Create Vlans
$VlanPath = read-host -Prompt "Enter the path and name of the csv file with the vlan information (i.e. c:\path\file.csv)"
$groupname = read-host -Prompt "Enter the name for the vlan group"
$lan = (Get-UcsLanCloud -Ucs $handle)
import-csv $VlanPath | % {Start-UcsTransaction -Ucs $handle
$lan | Add-UcsVlan -Ucs $handle -Name $_.Name -Id $_.Id
$mo = Get-UcsLanCloud  -Ucs $handle | Add-UcsFabricNetGroup  -Ucs $handle -ModifyPresent -Name $groupname
$mo_1 = $mo | Add-UcsFabricPooledVlan -ModifyPresent -Name $_.Name
Complete-UcsTransaction -Ucs $handle }
Disconnect-Ucs