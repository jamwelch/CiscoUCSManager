#Run this command first from powershell command line
#Install-Module -Name Cisco.UCSManager 
Import-Module Cisco.UCSManager

#Login to UCS, saves login to  file in the location specified
$DirPath = read-host -Prompt "Enter the path (i.e. c:\path) where you want the credential file created"
New-Item -ItemType Directory ucs-sessions
$UCSM_IP1 = read-host -Prompt "Enter the IP address of UCS Manager"
Connect-Ucs $UCSM_IP1
$CredPath = $DirPath + '\ucs-sessions\ucscreds.xml'
Export-UcsPSSession -Path $CredPath
