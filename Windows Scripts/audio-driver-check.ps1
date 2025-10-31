# Active Audio Device Identification Script

#Create a COM object for audio device enumeration
$AudioDevices = New-Object -ComObject MMDeviceEnumerator

#Get all audio devices
$Devices = $AudioDevices.GetDefaultAudioEnpoint(0,0)

# Get the friendly name 
$DeviceName - $AudioDevice.FriendlyName

#Get the device id
$DeviceID = $AudioDevice.Identification

#Display the device information
Write-Host "Active Audio Device: $DeviceName"
Write-Host "Device ID: $DeviceID"

