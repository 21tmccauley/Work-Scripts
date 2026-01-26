$choice = Read-Host "Do you want all devices or just ones with -o and -n? (Enter 'all' or 'o-n')"

if ($choice -eq 'all') {
    # Search in Library and Public OUs under Workstations
    $libraryOU = "OU=Library,OU=Workstations,OU=HBLL,DC=byu,DC=local"
    $publicOU = "OU=Public,OU=Workstations,OU=HBLL,DC=byu,DC=local"
    
    $computers = @()
    $computers += Get-ADComputer -Filter * -SearchBase $libraryOU -Properties LastLogonDate, CanonicalName
    $computers += Get-ADComputer -Filter * -SearchBase $publicOU -Properties LastLogonDate, CanonicalName
} else {
    $filter = "(Name -like '*-o*') -or (Name -like '*-n*')"
    $computers = Get-ADComputer -Filter $filter -SearchBase "OU=HBLL,DC=byu,DC=local" -Properties LastLogonDate, CanonicalName
}

$fileName = Read-Host "Enter the output filename (without extension)"
if (-not $fileName.EndsWith('.xlsx')) {
    $fileName += '.xlsx'
}
$outputFile = "$env:USERPROFILE\Desktop\$fileName"

$computers | Select-Object Name, LastLogonDate, CanonicalName | 
Export-Excel -Path $outputFile -AutoSize -FreezeTopRow

