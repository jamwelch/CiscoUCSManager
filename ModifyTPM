#This script will prompt user from input deciding whether to modify TPM settings for UCSM servers or standalone C-Series servers via CIMC.
#IMM servers are not supported by the script.

#Check version of powershell
Get-Host | Select-Object Version
#Check version of Modules




# Order of Operation 1. Decide on management mode. 2. Feed list of devices into script. 3. Start Loop operation to A. Connect to devices B. Test or Check devices current status. C. Modify devices as needed D. Produce Output for devices.

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#Choose Management Mode

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#UCSM Input

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#CIMC Input

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
#CIMC Connect
# Run Install-Module -Name Cisco.IMC from Powershell prompt to install latest version
Import-Module Cisco.IMC

#Login to CIMC, saves login to  file in the location specified
$DirPathIMC = read-host -Prompt "Enter the path (i.e. c:\path) where you want the CIMC credential file created"
New-Item -ItemType Directory cimc-sessions -Force

#Modify this to read CSV file
$CIMC_IP1 = read-host -Prompt "Enter the IP address of CIMC"
Connect-Imc $UCSM_IP1
$CredPathIMC = $DirPathIMC + '\cimc-sessions\imccreds.xml'
Export-UcsPSSession -Path $CredPathIMC
Disconnect-Imc
$handleIMC = Connect-Imc -Path $CredPathIMC

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#UCSM Test

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#CIMC Test

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#UCSM Modify

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#CIMC Modify

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#UCSM Output

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#CIMC Output

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
