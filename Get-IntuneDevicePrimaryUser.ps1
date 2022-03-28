function Get-IntuneDevicePrimaryUser {

    <#
		IMPORTANT:
        ===========================================================================
        This script is provided 'as is' without any warranty. Any issues stemming 
        from use is on the user.
        ===========================================================================
		.DESCRIPTION
		Retrieves the primary user for an Intune managed device.
        Things to change to deploy in your environment:
        Line 29: replace x with clientID of your reigstered app. See https://docs.microsoft.com/en-us/graph/auth-v2-user for more info.
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