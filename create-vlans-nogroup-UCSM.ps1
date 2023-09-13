##########################################################################
#This script is a user-friendly way to create a bunch of VLAN objects in UCSM.
#It requires the use of a CSV file to import the VLAN data. Use the example in the repository as a template. Do not change the column header names.
#It will create VLAN objects in the LAN Cloud for a single UCS domain. This script does not add them to a vlan group.
##########################################################################

#Feb.23.2021 -jamwelch@cisco.com
#version 1.1a - Feb.23.2021
#script tested with Powershell 5.1.19041.610


#Ask user if they have prepared the CSV file for import.  If Y, the script will continue.  If N, the script will end.
write-host -nonewline "Have you prepared the CSV File for importing the VLAN data? (Y/N) If not, then answer N to exit and do that first."
$response = read-host
if ( $response -ne "Y" ) { exit }

#Check version of powershell
Get-Host | Select-Object Version

#Run this command first from powershell command line
#Install-Module -Name Cisco.UCSManager 
Import-Module Cisco.UCSManager

#Login to UCS, saves login to  file in the location specified
$DirPath = read-host -Prompt "Enter the path (i.e. c:\path) where you want the credential file created."
New-Item -ItemType Directory ucs-sessions -Force
$UCSM_IP1 = read-host -Prompt "Enter the IP address of UCS Manager"
Connect-Ucs $UCSM_IP1
$CredPath = $DirPath + '\ucs-sessions\ucscreds.xml'
Export-UcsPSSession -Path $CredPath
Disconnect-Ucs
$handle = Connect-Ucs -Path $CredPath

#Create Vlans
$VlanPath = read-host -Prompt "Enter the path and name of the csv file with the vlan information (i.e. c:\path\file.csv)"
$lan = (Get-UcsLanCloud -Ucs $handle)
#Create the VLAN objects
import-csv $VlanPath | % {Start-UcsTransaction -Ucs $handle
$lan | Add-UcsVlan -Ucs $handle -Name $_.Name -Id $_.Id
Complete-UcsTransaction -Ucs $handle }
Disconnect-Ucs

#Delete credentials file and folder
$DelPath = $DirPath + '\ucs-sessions'
Get-ChildItem -Path $DelPath -File | Remove-Item
Remove-Item -Path $DelPath
