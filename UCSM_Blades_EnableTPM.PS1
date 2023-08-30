#This script will prompt user from input deciding whether to modify TPM settings for UCSM servers.
#IMM servers are not supported by the script.
#Script assumes all objects are in Org Root

#8.30.2023 -jamwelch@cisco.com
#Tested with Powershell 7.3.6

#Check version of powershell
Get-Host | Select-Object Version

# Run Install-Module -Name Cisco.UCSManager from Powershell prompt to install latest version
Import-Module Cisco.UCSManager
Set-UcsPowerToolConfiguration -SupportMultipleDefaultUcs $true

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Get List of Servers to modify from a CSV file
# Ask user if they have prepared the CSV file for import.  If Y, the script will continue.  If N, the script will end.
$title    = 'CSV Ready?'
$question = 'Have you prepared the CSV File with server data and saved it as a "tpm.csv" in the folder where the script files are stored? If not, then answer No to exit and do that first.'
$choices  = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {
    #Login to UCS, saves login to  file in the location specified
    $DirPathUCS = read-host -Prompt "Enter the path (i.e. c:\path) where the script files are stored."
    New-Item -ItemType Directory ucs-sessions -Force
    #change the name of the input file if needed.
    $csvinput = $DirPathUCS + "\tpm.csv"
    $csvdata = import-csv $csvinput
} else {
    exit
}
Start-Sleep -Seconds 1.5
# Verify the CSV Data
$csvrecords = $csvdata.Length - 1
if ($csvrecords -gt 1){
    Write-Output $csvdata
}
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Connect to UCS Manager
Write-Host "Connecting  to UCS Manager"
$UCSM_IP1 = read-host -Prompt "Enter the IP address of UCS Manager"
$CredPathUCS = $DirPathUCS + '\ucs-sessions\ucscreds.xml'
$KeyPathUCS = $DirPathUCS + '\ucs-sessions\ucscreds.key'
Connect-Ucs $UCSM_IP1
Export-UcsPSSession -LiteralPath $CredPathUCS
Disconnect-Ucs
Start-Sleep -Seconds 1.5
$credkey = read-host -Prompt "Enter key value used to store it securely." -MaskInput
ConvertTo-SecureString -String $credkey -AsPlainText -Force | ConvertFrom-SecureString | Out-File $KeyPathUCS
$key = ConvertTo-SecureString (Get-Content $KeyPathUCS)
$handleUCS = Connect-Ucs -Key $key -LiteralPath $CredPathUCS
$handleUCS
Write-Host "Connected to UCS Manager"
Get-UcsPSSession
Start-Sleep -Seconds 1.5
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Create Empty lists to use later
$BPList = [System.Collections.Generic.List[PSObject]]::new()
$SPList = [System.Collections.Generic.List[PSObject]]::new()
# Create Empty array to use later
$BP2SPMap = @{}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Get necessary information about each Blade
# Loop through each Serial number in CSV to get list of Service Profiles
foreach ($SN in $csvdata){
    Start-UcsTransaction
    #Find a blade matching the Serial number
    $BladeServer = Get-UcsBlade | Where-Object -Property Serial -EQ $SN.Serial
    Write-Host "Adding " + $BladeServer.Name + "to the list of servers to modify."
    #Get Dn of this blade
    $BladeProfileDn = $BladeServer | Select-Object AssignedToDn -ExpandProperty AssignedToDn
    Complete-UcsTransaction
    #Get Service Profile for the blade
    Start-UcsTransaction
    $BladeSP =  Get-UcsServiceProfile | Where-Object -Property Dn -EQ $BladeProfileDn
    #Get Name of Service Profile
    $SPName = $BladeSP | Select-Object Name
    Complete-UcsTransaction
    #Add Service Profile to SPList
    $SPList.Add($SPName.Name)
    Write-Host "Successfully added " + $BladeServer.Name + "to the list."
    Start-Sleep -Seconds 1.5
}


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Loop through list of Service Profiles to get Bios Policies List
foreach ($SP in $SPList){
    #Get the current Bios Policy
    Start-UcsTransaction
    $BiosPol = $BladeSP | Select-Object BiosProfileName -ExpandProperty BiosProfileName
    Write-Host $SP + " is currently using the Bios policy " + $BiosPol.Name
    #Update hash table (aka map) for server profile to bios policy
    $BP2SPMap.add($SP, $BiosPol)
    Complete-UcsTransaction
    #Add this policy to the Bios Policy List
    if ( -not ( $BiosPol -in $BPList) ) {
        $BPList.Add($BiosPol)}
        Start-Sleep -Seconds 1.5
}
Write-Output $BP2SPMap

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Loop through the list of Bios Policies and Create a clone for each
foreach ($BP in $BPList){
    if ($BP.Length -gt 1){
    #Get the settings of the policies
    Start-UcsTransaction
    $BPSet = Get-UcsBiosPolicy $BP -Hierarchy
    Complete-UcsTransaction
    #Make a clone of the Bios Policy
    #Name the new bios policy adding "_TPM" to the end
    $NewBP = $BP + '_TPM'
    #Create new blank destination policy
    Write-Host "Creating a clone of Bios Policy " + $BP " with name " + $NewBP
    Start-UcsTransaction
    Add-UcsBiosPolicy -Name $NewBP
    Complete-UcsTransaction
    #Get the new Bios Policy settings
    Start-UcsTransaction
    $NewBPSet = Get-UcsBiosPolicy -Name $NewBP -Hierarchy
    Complete-UcsTransaction
    #Create map to compare settings
    $xlateDn = @{ }
    $xlateDn['org-root/bios-prof-'+$BP] = 'org-root/bios-prof-'+$NewBP
    #Compare original with new Bios settings and sync them up in order to create a "clone" of the original
    Write-Host 
    Start-UcsTransaction
    $diff = Compare-UcsManagedObject ($NewBPSet) ($BPSet) -XlateMap $xlateDn
    Sync-UcsManagedObject ($diff) -Force
    Complete-UcsTransaction
    #Modify the cloned bios policy (to enable TPM)
    Write-Host "Enabling TPM on the cloned Bios Policy " + $NewBP
    Start-UcsTransaction
    Get-UcsBiosPolicy -Name $NewBP -LimitScope | Add-UcsManagedObject -ModifyPresent  -ClassId BiosVfTrustedPlatformModule -PropertyMap @{VpTrustedPlatformModuleSupport="enabled"; }
    Complete-UcsTransaction
    Write-Host "Sucessfully modified Bios Policy " + $NewBP
    Start-Sleep -Seconds 1.5
}}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Loop through list of Service Profiles and unbind from their templates
foreach($SP in $SPList){
    if ($SP.Length -gt 1){
    #Unbind the Profile from the Template
    Write-Host "Unbind Service Profile " + $SP + " from Service Profile Template."
    Start-UcsTransaction
    Add-UcsServiceProfile -ModifyPresent -Name $SP -SrcTemplName ""
    Complete-UcsTransaction
    Write-Host "Successfully unbound " + $SP
    Start-Sleep -Seconds 1.5
}}
# Loop through list of Service Profiles to swap out the Bios Policies with the modified versions
foreach($SP in $SPList){
    if ($SP.Length -gt 1){
    #Lookup name of Bios Policy
    $BPName = $BP2SPMap | Select-Object $SP
    #Identify correct name of new policy
    $BPNewName = $BPName.$SP + '_TPM'
    #Modify the Service Profile with the New Bios Policy - NOTE -- Need an array to way to map SP to BP here
    Write-Host "Modifying Service Profile " + $SP + " with new Bios Policy " + $BPNewName
    Start-UcsTransaction
    Add-UcsServiceProfile -ModifyPresent -Name $SP -BiosProfileName $BPNewName
    Complete-UcsTransaction
    Write-Host "Successfully modified " $SP
    Start-Sleep -Seconds 1.5
}}
# Servers should be prompted for reboot at this point to enforce changes in the Bios Policy
Write-Host "Disconnecting from UCS Manager"
Disconnect-Ucs
