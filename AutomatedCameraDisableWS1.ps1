#*******************************************************************************************************************************************************************************#
# Project                   : Automated Camera Disable                                                                                                                          #
#                                                                                                                                                                               #
# Program name              : AutomatedCameraDisableWS1.ps1                                                                                                                     #
#                                                                                                                                                                               #
# Author                    : Nestor Lee                                                                                                                                        #           
#                                                                                                                                                                               #
# Date created (DDMMYYYY)   : 07122020                                                                                                                                          #
#                                                                                                                                                                               #
# Purpose                   : Done up for the purpose of a PoC to * to showcase how Workspace ONE can be used to block/disable Mobile Device camera and user swipes ID card     #
#                                                                                                                                                                               #
# Revision History          :                                                                                                                                                   #
#                                                                                                                                                                               #
# Date (DDMMYYYY)       Author      Ref     Revision (Date in DDMMYYYY format)                                                                                                  #
# 07122020              Nestor Lee  1       First version - 07122020                                                                                                            #
#                                                                                                                                                                               #
#*******************************************************************************************************************************************************************************#        

<#=============== Android Example Start=============#
---------- Processing ----------
Name -> Android User
Email -> androiduser@nestorlee.com
User Action -> Swipe In
********** Completed End **********


---------- Processing ----------
Name -> Android User
Email -> androiduser@nestorlee.com
User Action -> Swipe Out
********** Completed End **********
#=============== Android Example End ===============#>

<#=============== iOS Example Start=============#
---------- Processing ----------
Name -> iOS User
Email -> iosuser@nestorlee.com
User Action -> Swipe In
********** Completed End **********


---------- Processing ----------
Name -> iOS User
Email -> iosuser@nestorlee.com
User Action -> Swipe Out
********** Completed End **********

=============== iOS Example End ===============#>


# Define the path of the log file
$filename = "log.txt" # Enter the logname path 
$reader = new-object System.IO.StreamReader(New-Object IO.FileStream($filename, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [IO.FileShare]::ReadWrite))

# Workspace ONE APIs Key
$APIUsername = ""
$APIPassword = ""
$APIKey = ""
$APIUrl = "https://as510.awmdm.sg/API" # Follow the format: https://<API Server URL>/API 

# Define the Profile IDs for each of the Platforms which contains the payload to block/disable camera
$iOSProfileID = ""
$AndroidProfileID = "" 

# Encoding the Authentication and Authorization headers used for all API requests
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $APIUsername,$APIPassword)))
$APIRequestHeaders = @{
    "aw-tenant-code" = $APIKey
    Authorization=("Basic {0}" -f $base64AuthInfo)
}

# Function that calls the API to install/remove profile to block/unblock, disable/enable camera
function Set-DeviceProfileAction($action, $deviceSerialNumber, $mobileDeviceOS){
    $APIRequestParams = @{
        "SerialNumber" = $deviceSerialNumber
    }
    if($mobileDeviceOS -eq "Android"){
        $actionURL = ("$APIURL/mdm/profiles/$AndroidProfileID/$action").ToString()
    }
    elseif($mobileDeviceOS -eq "Apple"){
        $actionURL = ("$APIURL/mdm/profiles/$iOSProfileID/$action").ToString()
    }
    write-output "Doing action: $action on $mobileDeviceOS device with Serial Number $deviceSerialNumber"
    Invoke-RestMethod -Method 'POST' -Uri $actionURL -Header $APIRequestHeaders -ContentType 'application/json' -Body ($APIRequestParams|ConvertTo-Json)
}

# Function that calls the API to get the Workspace ONE UEM Enrollment Username from the User Email
function Get-UserNameFromUserEmail($userEmail){
    $actionURL = ("$APIURL/system/users/search?email=$userEmail").ToString()
    $userInformationObject = Invoke-RestMethod -Method 'GET' -Uri $actionURL -Header $APIRequestHeaders -ContentType 'application/json' | ConvertTo-Json
    $parsedUserInfomation = $userInformationObject | ConvertFrom-Json

    $parsedUserName = $parsedUserInfomation.psobject.properties.Value.UserName
    
    return $parsedUserName
}

# Function that calls the API to retrieve device details such as Platform and Device Serial Number
function Get-DeviceDetailsFromUserName($userName){
    $actionURL = ("$APIURL/mdm/devices/search?user=$userName").ToString()
    $deviceInformationObject = Invoke-RestMethod -Method 'GET' -Uri $actionURL -Header $APIRequestHeaders -ContentType 'application/json' | ConvertTo-Json
    $parsedDeviceInfomation = $deviceInformationObject | ConvertFrom-Json    

    $deviceDetailsObject = New-Object -TypeName psobject

    $parsedDeviceSerialNumber = $parsedDeviceInfomation.psobject.properties.Value.SerialNumber
    $deviceDetailsObject | Add-Member -MemberType NoteProperty -Name SerialNumber -Value $parsedDeviceSerialNumber

    $parsedDevicePlatform = $parsedDeviceInfomation.psobject.properties.Value.Platform
    $deviceDetailsObject | Add-Member -MemberType NoteProperty -Name Platform -Value $parsedDevicePlatform

    return $deviceDetailsObject
}

# Function that is called when a new entry in the log file is detected
function New-InputReceivedFromFile($fileInputObject){
    $deviceUser = Get-UserNameFromUserEmail($fileInputObject.email)
    $deviceObject = Get-DeviceDetailsFromUserName($deviceUser)
    if($fileInputObject.userAction -eq "Swipe In"){
        $action = "install"
    }
    elseif($fileInputObject.userAction -eq "Swipe Out"){
        $action = "remove"
    }
    Set-DeviceProfileAction $action $deviceObject.SerialNumber $deviceObject.Platform
} 

# Code will start running at EOF. Will ignore any log entries entered before this script is ran.
$lastMaxOffset = $reader.BaseStream.Length

# Main 
while ($true)
{
    Start-Sleep -m 100

    $actionBlock = New-Object -TypeName psobject

    # If the file size has not changed, idle
    if ($reader.BaseStream.Length -eq $lastMaxOffset) {
        continue;
    }

    # When file size detected to have changed, seek to the last max offset
    $reader.BaseStream.Seek($lastMaxOffset, [System.IO.SeekOrigin]::Begin) | out-null

    # Read out of the file until the EOF
    $line = ""
    
    while (($line = $reader.ReadLine()) -ne $null) {
        # write-output $line
        # $block += ,@($line)
        if($line -match "(?i)^name"){
            $posOfDelimitter = $line.IndexOf(">")
            $userName = ($line.Substring($posOfDelimitter+1)).Trim()
            $actionBlock | Add-Member -MemberType NoteProperty -Name userFirstNameLastName -Value $userName
        }
        if($line -match "(?i)^email"){
            $posOfDelimitter = $line.IndexOf(">")
            $email = ($line.Substring($posOfDelimitter+1)).Trim()
            $actionBlock | Add-Member -MemberType NoteProperty -Name email -Value $email
        }
        if($line -match "(?i)^user"){
            $posOfDelimitter = $line.IndexOf(">")
            $userAction = ($line.Substring($posOfDelimitter+1)).Trim()
            $actionBlock | Add-Member -MemberType NoteProperty -Name userAction -Value $userAction
        }
    }

    if($null -ne $actionBlock.userFirstNameLastName -and $null -ne $actionBlock.email -and $null -ne $actionBlock.userAction ){
        New-InputReceivedFromFile($actionBlock)
    }   

    # Update the last max offset
    $lastMaxOffset = $reader.BaseStream.Position
}