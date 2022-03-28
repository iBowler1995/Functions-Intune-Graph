function Rename-IntuneDevice {

    <#
		IMPORTANT:
        ===========================================================================
        This script is provided 'as is' without any warranty. Any issues stemming 
        from use is on the user.
        ===========================================================================
		.DESCRIPTION
		Renames an Intune managed device.
        Things to change to deploy in your environment:
        Line 57: replace x with clientID of your reigstered app. See https://docs.microsoft.com/en-us/graph/auth-v2-user for more info.
		===========================================================================
		.PARAMETER Device
		Required if not using all or bulk switch - Name of device to rename.
        .PARAMETER Rename
        Required if not using all or bulk switch - New name of the device.
        .PARAMETER Bulk
        Switch to specify that you have a file of devices to rename. Must be used with FileName, Pattern, and either Numbers or Letters (or both) switches.
        .PARAMETER FileName
        Path to the file containing the devices to be renamed.
        .PARAMETER All
        Renames all Intune devices. Must be used with Pattern and either Numbers or Letters (or both) switches.
        .PARAMETER Pattern
        Prefix for your new device names. Example: -Pattern Desktop -Numbers -Letters will rename each specified device to DESKTOP-{randomly generated alphanumeric string}.
        .PARAMETER Numbers
        Switch to add randomized numbers to the end of new device names. Only use with Bulk or All switches.
        .PARAMETER Letters
        Switch to add randomized letters to the end of new device names. Only use with Bulk or All switches.
		===========================================================================
		.EXAMPLE
		Rename-IntuneDevice -Device DESKTOP-7XH8Z
	#>
    
    [CmdletBinding()]
    param (

        [Parameter()]
        [String]$Device,
        [Parameter()]
        [String]$Rename,
        [Parameter()]
        [Switch]$Bulk,
        [Parameter()]
        [Switch]$All,
        [Parameter()]
        [String]$FileName,
        [Parameter()]
        [Switch]$Pattern,
        [Parameter()]
        [Switch]$Numbers,
        [Parameter()]
        [Switch]$Letters

    )

    $token = Get-MsalToken -clientid x -tenantid organizations
    $global:header = @{'Authorization' = $token.createauthorizationHeader();'ConsistencyLevel' = 'eventual'}

    function Get-IntuneDevice {

        [CmdletBinding()]
        param (
    
            [Parameter()]
            [String]$Name,
            [Parameter()]
            [Switch]$All
    
        )
    
        If (!$All -and $Name){
    
            $Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=deviceName%20eq%20'$Name'"
            Try { 
                
                $Device = (Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header).value
                If ($Device -ne $Null) {
    
                    $device
    
                }
                else {
    
                    Write-Host "Device $Name not found." -f Red
    
                }
            
            }
            catch{
                    $ResponseResult = $_.Exception.Response.GetResponseStream()
                    $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                    $ResponseBody = $ResponseReader.ReadToEnd()
                    $ResponseBody
                }
                
    
        }
        elseif (!$All -and !$Name){
    
            Write-Host "Please specify a device using the -Name parameter or use the -All switch to see all devices." -f Red
    
        }
        elseif ($All -and !$Name){
    
            $Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=(((deviceType%20eq%20%27desktop%27)%20or%20(deviceType%20eq%20%27windowsRT%27)%20or%20(deviceType%20eq%20%27winEmbedded%27)%20or%20(deviceType%20eq%20%27surfaceHub%27)))"
            Try {
                    
                (Invoke-RestMethod -uri $uri -headers $header -method GET).value
    
            }
            catch{
                
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody    
            }
                
    
        }
        else{
    
            Write-Host "Please specify a device using the -Name parameter or use the -All switch to see all devices." -f Red
    
        }
    
    }
###########################################################

Function New-RandomComputerName{
    [CmdletBinding(SupportsShouldProcess=$True)]

    Param(
        [int]$Length,
        [switch]$Letters
    )

    If (!$Letters){

        #Characters Sets to be for Password Creation

    $CharSimple = "A","B","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","W","X","Y","Z","1","2","3","4","5","6","7","8","9","0"
    $CharNumbers = "1","2","3","4","5","6","7","8","9","0"
    
    #Verify if the Password contains at least 1 digit character

    $ContainsNumber = $False
    $Name = $Null
    
    #Sets which Character Array to use based on $Complex

    #Loop to actually generate the password

    for ($i=0;$i -lt $Length; $i++)
        {$c = Get-Random -InputObject $CharSimple
            if ([char]::IsDigit($c))
        {$ContainsNumber = $True}
        $Name += $c}
    
    #Check to see if a Digit was seen, if not, fixit

    if ($ContainsNumber)
        {
            Return $Name
        }
        else
        {
            $Position = Get-Random -Maximum $Length
            $Number = Get-Random -InputObject $CharNumbers
            $NameArray = $Name.ToCharArray()
            $NameArray[$Position] = $Number
            $Name = ""
            foreach ($s in $NameArray)
            {
                $Name += $s
            }
        Return $Name
    
        }

    }
    else{

        $String = -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
        $Name = $String.ToUpper()
        Return $Name

    }

}

###########################################################
    If ($Device -and !$Bulk){

        $IntuneDevice = Get-IntuneDevice -Name $Device
        $Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($IntuneDevice.Id)/setDeviceName"
        $Body = @{

            "deviceName" = $Rename
            
        }
        $JSON = $Body | ConvertTo-Json

        Try {

            Invoke-RestMethod -Uri $Uri -Headers $Header -Method POST -Body $JSON -ContentType "application/Json"
            
        }
        catch{
                    
            $ResponseResult = $_.Exception.Response.GetResponseStream()
            $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
            $ResponseBody = $ResponseReader.ReadToEnd()
            $ResponseBody    
        }
            

    }
    elseif ($Device -and $Bulk){

        Write-Host "Cannot use both -Device and -Bulk parameter." -f Yellow

    }
    elseif (!$Device -and $Bulk -and $Pattern -and $FileName -and !$All -and $Numbers -and !$Letters){

        $Devices = Get-Content $FileName
        $Random = Get-Random -Maximum 9999
        $NewName = "$Pattern-$Random"
        $DeviceExists = Get-IntuneDevice -Name $NewName
        while ($DeviceExists -ne $Null){

            Write-Host "Device already exists with name generated, trying again." -f Yellow
            Write-Host "============" -f white
            $Random = Get-Random -Maximum 9999
            $NewName = "$Pattern-$Random"
            $DeviceExists = Get-IntuneDevice -Name $NewName

        }

        foreach ($Item in $Devices){

            $IntuneDevice = Get-IntuneDevice -Name $Device
            $Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($IntuneDevice.Id)/setDeviceName"
            $Body = @{

                "deviceName" = $NewName
                
            }
            $JSON = $Body | ConvertTo-Json

            Try {

                Invoke-RestMethod -Uri $Uri -Headers $Header -Method POST -Body $JSON -ContentType "application/Json"
                
            }
            catch{
                        
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody
            }
            

        }

    }
    elseif (!$Device -and $Bulk -and $Pattern -and $FileName -and !$All -and !$Numbers -and $Letters){

        $Devices = Get-Content $FileName
        $Random = New-RandomComputerName -Length 5 -Letters
        $NewName = "$Pattern-$Random"
        $DeviceExists = Get-IntuneDevice -Name $NewName
        while ($DeviceExists -ne $Null){

            Write-Host "Device already exists with name generated, trying again." -f Yellow
            Write-Host "============" -f white
            $Random = Get-Random -Maximum 9999
            $NewName = "$Pattern-$Random"
            $DeviceExists = Get-IntuneDevice -Name $NewName

        }

        foreach ($Item in $Devices){

            $IntuneDevice = Get-IntuneDevice -Name $Device
            $Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($IntuneDevice.Id)/setDeviceName"
            $Body = @{

                "deviceName" = $NewName
                
            }
            $JSON = $Body | ConvertTo-Json

            Try {

                Invoke-RestMethod -Uri $Uri -Headers $Header -Method POST -Body $JSON -ContentType "application/Json"
                
            }
            catch{
                        
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody
            }
            

        }

    }
    elseif (!$Device -and $Bulk -and $Pattern -and $FileName -and !$All -and $Numbers -and $Letters){

       
        $Devices = Get-Content $FileName
        $Random = New-RandomComputerName -Length 5
        $NewName = "$Pattern-$Random"
        $DeviceExists = Get-IntuneDevice -Name $NewName
        while ($DeviceExists -ne $Null){

            Write-Host "Device already exists with name generated, trying again." -f Yellow
            Write-Host "============" -f white
            $Random = Get-Random -Maximum 9999
            $NewName = "$Pattern-$Random"
            $DeviceExists = Get-IntuneDevice -Name $NewName

        }

        foreach ($Item in $Devices){

            $IntuneDevice = Get-IntuneDevice -Name $Device
            $Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($IntuneDevice.Id)/setDeviceName"
            $Body = @{

                "deviceName" = $NewName
                
            }
            $JSON = $Body | ConvertTo-Json

            Try {

                Invoke-RestMethod -Uri $Uri -Headers $Header -Method POST -Body $JSON -ContentType "application/Json"
                
            }
            catch{
                        
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody
            }
            

        }

    }
    elseif (!$Device -and !$Bulk -and $Pattern -and $All -and $Numbers -and !$Letters){

        $Devices = Get-IntuneDevice -All
        $Random = Get-Random -Maximum 9999
        $NewName = "$Pattern-$Random"
        $DeviceExists = Get-IntuneDevice -Name $NewName
        while ($DeviceExists -ne $Null){

            Write-Host "Device already exists with name generated, trying again." -f Yellow
            Write-Host "============" -f white
            $Random = Get-Random -Maximum 9999
            $NewName = "$Pattern-$Random"
            $DeviceExists = Get-IntuneDevice -Name $NewName

        }

        foreach ($Item in $Devices){

            $IntuneDevice = Get-IntuneDevice -Name $Device
            $Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($IntuneDevice.Id)/setDeviceName"
            $Body = @{

                "deviceName" = $NewName
                
            }
            $JSON = $Body | ConvertTo-Json

            Try {

                Invoke-RestMethod -Uri $Uri -Headers $Header -Method POST -Body $JSON -ContentType "application/Json"
                
            }
            catch{
                        
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody
            }
            

        }

    }
    elseif (!$Device -and !$Bulk -and $Pattern -and $All -and $Numbers -and !$Letters) {

        $Devices = Get-Content $FileName
        $Random = New-RandomComputerName -Length 5 -Letters
        $NewName = "$Pattern-$Random"
        $DeviceExists = Get-IntuneDevice -Name $NewName
        while ($DeviceExists -ne $Null){

            Write-Host "Device already exists with name generated, trying again." -f Yellow
            Write-Host "============" -f white
            $Random = Get-Random -Maximum 9999
            $NewName = "$Pattern-$Random"
            $DeviceExists = Get-IntuneDevice -Name $NewName

        }

        foreach ($Item in $Devices){

            $IntuneDevice = Get-IntuneDevice -Name $Device
            $Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($IntuneDevice.Id)/setDeviceName"
            $Body = @{

                "deviceName" = $NewName
                
            }
            $JSON = $Body | ConvertTo-Json

            Try {

                Invoke-RestMethod -Uri $Uri -Headers $Header -Method POST -Body $JSON -ContentType "application/Json"
                
            }
            catch{
                        
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody
            }
            

        }

    }

    }
    elseif (!$Device -and !$Bulk -and $Pattern -and $All -and $Numbers -and $Letters){

        $Devices = Get-IntuneDevice -All
        $Random = New-RandomComputerName -Length 5
        $NewName = "$Pattern-$Random"
        $DeviceExists = Get-IntuneDevice -Name $NewName
        while ($DeviceExists -ne $Null){

            Write-Host "Device already exists with name generated, trying again." -f Yellow
            Write-Host "============" -f white
            $Random = Get-Random -Maximum 9999
            $NewName = "$Pattern-$Random"
            $DeviceExists = Get-IntuneDevice -Name $NewName

        }

        foreach ($Item in $Devices){

            $IntuneDevice = Get-IntuneDevice -Name $Device
            $Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($IntuneDevice.Id)/setDeviceName"
            $Body = @{

                "deviceName" = $NewName
                
            }
            $JSON = $Body | ConvertTo-Json

            Try {

                Invoke-RestMethod -Uri $Uri -Headers $Header -Method POST -Body $JSON -ContentType "application/Json"
                
            }
            catch{
                        
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody
            }
            

        }

    }

}