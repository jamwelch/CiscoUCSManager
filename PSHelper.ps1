<#
.SYNOPSIS
    Helper script to create a self-signed certificate, trust it, and sign a PowerShell script.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath  # Full path to the .ps1 file you want to sign
)

Write-Host "=== Step 1: Creating self-signed certificate ==="
$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject "CN=Local PowerShell Code Signing" `
    -CertStoreLocation Cert:\CurrentUser\My

if (-not $cert) {
    Write-Error "Failed to create certificate."
    exit 1
}

Write-Host "Certificate created with Thumbprint: $($cert.Thumbprint)"

Write-Host "=== Step 2: Adding certificate to Trusted Root store ==="
$rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root","CurrentUser"
$rootStore.Open("ReadWrite")
$rootStore.Add($cert)
$rootStore.Close()

Write-Host "Certificate added to Trusted Root store."

Write-Host "=== Step 3: Signing script $ScriptPath ==="
Set-AuthenticodeSignature -FilePath $ScriptPath -Certificate $cert -HashAlgorithm SHA256

Write-Host "Done! Verify signature with:"
Write-Host "Get-AuthenticodeSignature `"$ScriptPath`" | Format-List"
