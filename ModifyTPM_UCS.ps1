#This script will prompt user from input deciding whether to modify TPM settings for UCSM servers.
#IMM servers are not supported by the script.

#Check version of powershell
Get-Host | Select-Object Version
#Check version of Modules




#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#UCSM Input


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#UCSM Connect
# Run Install-Module -Name Cisco.UCSManager from Powershell prompt to install latest version
Import-Module Cisco.UCSManager

#Login to UCS, saves login to  file in the location specified
$DirPathUCS = read-host -Prompt "Enter the path (i.e. c:\path) where you want the UCSM credential file created"
New-Item -ItemType Directory ucs-sessions -Force

#Modify this to read CSV file
$UCSM_IP1 = read-host -Prompt "Enter the IP address of UCS Manager"
Connect-Ucs $UCSM_IP1
$CredPathUCS = $DirPathUCS + '\ucs-sessions\ucscreds.xml'
Export-UcsPSSession -Path $CredPathUCS
Disconnect-Ucs
$handleUCS = Connect-Ucs -Path $CredPathUCS


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#UCSM Test


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#UCSM Modify


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#UCSM Output


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
