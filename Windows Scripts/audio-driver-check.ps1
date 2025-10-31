# Active Audio Device Identification Script
# Get-CimInstane is the newer approach I think

$SoundDevices = Get-CimInstance -ClassName Win32_SoundDevice

Write-Host "Querying for sound devices..."

#Create an array to store the device information
$DeviceList = @()

# Loop through each device and add the information to the array
foreach ($Device in $SoundDevices) {

    #Now find the driver associated with this device's PnP ID
    # Query the PnPSignedDriver property where the DeviceID matches 
    $Driver = Get-CimINstance -ClassName Win32_PnPSignedDriver | Where-Object {$_.DeviceID -eq $Device.PNPDeviceID}

    # Create a custom object with the device information
    $DeviceObject = [PSCustomObject]@{
        Name = $Device.Name
        Manufacturer = $Device.Manufacturer
        Status = $Device.Status
        PNPDeviceID = $Device.PNPDeviceID
        DriverVersion = $Driver.DriverVersion
        DriverProvider = $Driver.ProviderName
        DriverDate = $Driver.Date
    }

    # Add new object to the list

    $DeviceList += $DeviceObject

    Write-Host "--- Audio Device and Driver Report ---"
    $DeviceList | Format-Table -AutoSize


}


