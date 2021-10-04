#This little powertool snippet will print out all disks in a domain including SN, Firmware, OEM PID, Cisco SKU:

foreach ($disk in Get-UcsStorageLocalDisk)
{
$mfgdisk = Get-UcsStorageLocalDisk -Dn $disk
$ciscosku = Get-UcsEquipmentLocalDiskCapProvider -Vendor $mfgdisk.Vendor -Model $mfgdisk.Model | Get-UcsEquipmentManufacturingDefStorage
$output = $mfgdisk.dn + " " + $mfgdisk.Serial + " " + $mfgdisk.DeviceVersion + " " + $mfgdisk.Model + " " + $ciscosku.sku
Write-Output $output
}
