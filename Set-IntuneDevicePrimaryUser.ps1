function Set-IntuneDevicePrimaryUser {

    <#
		IMPORTANT:
        ===========================================================================
        This script is provided 'as is' without any warranty. Any issues stemming 
        from use is on the user.
        ===========================================================================
		.DESCRIPTION
		Sets Intune managed device primary user.
        Things to change to deploy in your environment:
        Line 38: replace x with clientID of your reigstered app. See https://bit.ly/3KApKhJ for more info.
		===========================================================================
		.PARAMETER Device
		Required - Name of the device to to change users on.
		.PARAMETER User
		Name of the new primary user.
        .PARAMETER LastUser
        Sets the specified device's primary user to the last signed in user on that device.
		===========================================================================
		.EXAMPLE
		Set-IntuneDevicePrimaryUser -Device DESKTOP-7XH8Z -User bjameson@contoso.com <--- Sets DESKTOP-7XH8Z primary user to bjameson@contoso.com
        Set-IntuneDevicePrimaryUser -Device DESKTOP-7XH8Z -LastUser <--- Sets DESKTOP-7XH8Z primary user to last signed in user
	#>
    
    [cmdletbinding()]
    
    param
    (
    [parameter(Mandatory=$true)]
    [String]$Device,
    [parameter()]
    [String]$User,
    [Parameter()]
    [Switch]$LastUser
    )

    $token = Get-MsalToken -clientid x -tenantid organizations
    $global:header = @{'Authorization' = $token.createauthorizationHeader();'ConsistencyLevel' = 'eventual'}

    function Get-IntuneDevice {

        <#
            IMPORTANT:
            ===========================================================================
            This script is provided 'as is' without any warranty. Any issues stemming 
            from use is on the user.
            ===========================================================================
            .DESCRIPTION
            Retrieves Intune managed device.
            ===========================================================================
            .PARAMETER Name
            Required if not using All switch - Name of the device to retrieve.
            .PARAMETER All
            Retrieves all Intune managed apps.
            ===========================================================================
            .EXAMPLE
            Assign-IntuneDevice -Name DESKTOP-7XH8Z <--- Retrieves DESKTOP-7XH8Z if exist
            Assign-IntuneDevice -All <--- Retrieves all Intune managed devices.
        #>
        
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

#################################################################
function Get-IntuneDevicePrimaryUser {

    <#
		IMPORTANT:
        ===========================================================================
        This script is provided 'as is' without any warranty. Any issues stemming 
        from use is on the user.
        ===========================================================================
		.DESCRIPTION
		Retrieves the primary user for an Intune managed device.
		===========================================================================
		.PARAMETER Name
		Required - Name of device to query.
		===========================================================================
		.EXAMPLE
		Get-IntuneDevicePrimaryUser -Device DESKTOP-7XH8Z <--- Retrieves primary user for DESKTOP-7XH8Z
	#>
    
    [CmdletBinding()]
    param (

        [Parameter()]
        [String]$Device

    )
  
    function Get-IntuneDevice {

        <#
            IMPORTANT:
            ===========================================================================
            This script is provided 'as is' without any warranty. Any issues stemming 
            from use is on the user.
            ===========================================================================
            .DESCRIPTION
            Retrieves Intune managed device.
            ===========================================================================
            .PARAMETER Name
            Required if not using All switch - Name of the device to retrieve.
            .PARAMETER All
            Retrieves all Intune managed devices.
            ===========================================================================
            .EXAMPLE
            Assign-IntuneDevice -Name DESKTOP-7XH8Z <--- Retrieves DESKTOP-7XH8Z if exist
            Assign-IntuneDevice -All <--- Retrieves all Intune managed devices.
        #>
        
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

    #################################################################

    $Device = Get-IntuneDevice -Name $Device
    $DeviceId = $Device.value.Id
    $Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$DeviceId/users"
    Try {
    
        (Invoke-RestMethod -Uri $Uri -Headers $Header -Method Get).value
        

    }
    catch{
        $ResponseResult = $_.Exception.Response.GetResponseStream()
        $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
        $ResponseBody = $ResponseReader.ReadToEnd()
        $ResponseBody    
    }
        

}

#################################################################
    function Get-AADUser {

        [cmdletbinding()]
        param(

            [Parameter()]
            [Switch]$All,
            [Parameter()]
            [String]$UPN

        )
        
        <#
            IMPORTANT:
            ===========================================================================
            This script is provided 'as is' without any warranty. Any issues stemming 
            from use is on the user.
            ===========================================================================
            .DESCRIPTION
            Gets an Azure AD User
            ===========================================================================
            .PARAMETER All
            Lists all AAD users by displayName.
            .PARAMETER Name
            The displayName of the user to get.
            ===========================================================================
            .EXAMPLE
            Get-AADUser -All <--- This will return all AzureAD users
            Get-AADUser -UPN bjameson@example.com <--- This will return the user bjameson@example.com
        #>

        If ($All) {
    
            $uri = "https://graph.microsoft.com/v1.0/users"
            $Users = While (!$NoMoreUsers) {

                $GetUsers = Invoke-RestMethod -uri $uri -headers $header -method GET
                $getUsers.value
                If ($getUsers."@odata.nextlink") {

                    $uri = $getUsers."@odata.nextlink"

                }
                Else {
                
                    $NoMoreUsers = $True

                }
            }
            $NoMoreUsers = $False
            $Users| select displayName | sort displayName

        }
        elseif ($UPN -ne $Null) {

            $Uri = "https://graph.microsoft.com/v1.0/users/$UPN"
            Try {
            
                Invoke-RestMethod -Uri $Uri -Headers $header -Method Get

            }
            catch{
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody    
            }
                

        }
        else {

            Write-Host "Please specify individual user or use All switch."

        }

    }

#################################################################

    If ($LastUser){

    try {
        
        $IntuneDevice = Get-IntuneDevice -Name $Device
        $IntuneDeviceId = $IntuneDevice.value.Id
        $UPN = $IntuneDevice.value.usersLoggedOn.UserId
        $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$IntuneDeviceId')/users/`$ref"
        
        $JSON = @{ 
            
            "@odata.id"="https://graph.microsoft.com/beta/users/$UPN" 
        
        } | ConvertTo-Json -Compress

        $uri
        $JSON

	} 
    catch{
        $ResponseResult = $_.Exception.Response.GetResponseStream()
        $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
        $ResponseBody = $ResponseReader.ReadToEnd()
        $ResponseBody
        }
        

    }
    elseIf (!$LastUser -and $User){

        $IntuneDevice = Get-IntuneDevice -Name $Device
        $IntuneDeviceId = $IntuneDevice.value.Id
        $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$IntuneDeviceId')/users/`$ref"
        $UserId = Get-AADUser -UPN $User | select -expand Id
        
        $JSON = @{ 
            
            "@odata.id"="https://graph.microsoft.com/beta/users/$UserId" 
        
        } | ConvertTo-Json -Compress

        Try {
            
            Invoke-RestMethod -Uri $Uri -Headers $Header -Body $JSON -ContentType "application/Json" -Method POST

        }

        catch{
            $ResponseResult = $_.Exception.Response.GetResponseStream()
            $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
            $ResponseBody = $ResponseReader.ReadToEnd()
            $ResponseBody
            }

    }
    else {

        Write-Host "Please specify a user with the -User switch or select the -LastUser switch to set the primary user to last logged on user."

    }
}