function Reset-IntuneDevice {

    <#
		IMPORTANT:
        ===========================================================================
        This script is provided 'as is' without any warranty. Any issues stemming 
        from use is on the user.
        ===========================================================================
		.DESCRIPTION
		Resets an Intune managed device.
        For more info on Wipe vs. Retire vs. Delete, see https://karstenkleinschmidt.de/2020/09/09/intune-what-is-retire-wipe-delete-fresh-start-autopilot-reset/
        Things to change to deploy in your environment:
        Line 78: replace x with clientID of your reigstered app. See https://docs.microsoft.com/en-us/graph/auth-v2-user for more info.
		===========================================================================
		.PARAMETER Device
		Required  - Name of the device to reset.
		.PARAMETER Wipe
		Initiates Wipe on specified device at next sync. Use KeepUserData switch if you'd like to keep user data.
        .PARAMETER KeepUserData
        Use this switch when wiping a device to keep user data (i.e., for a reinstall of Windows)
        .PARAMETER Retire
        Initiates Retire on specified device - device will not be removed from Intune until next sync.
        .PARAMETER AutoPilot
        Initiates an AutoPilot reset on specified device.
		===========================================================================
		.EXAMPLE
		Reset-IntuneDevice -Device DESKTOP-7XH8Z -Wipe -KeepUserData  <--- Wipes DESKTOP-7XH8Z and keeps user data
        Reset-IntuneDevice -Device DESKTOP-7XH8Z -Wipe <--- Wipes DESKTOP-7XH8Z and does NOT keep user data
        Reset-IntuneDevice -Device DESKTOP-7XH8Z -Retire  <--- Retires DESKTOP-7XH8Z at next sync
        Reset-IntuneDevice -Device DESKTOP-7XH8Z -AutoPilot  <--- AutoPilot resets DESKTOP-7XH8Z
	#>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [String]$Device,
        [Parameter()]
        [Switch]$Wipe,
        [Parameter()]
        [Switch]$KeepUserData,
        [Parameter()]
        [Switch]$Retire,
        [Parameter()]
        [Switch]$Autopilot
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
    
        $token = Get-MsalToken -clientid x -tenantid organizations
        $global:header = @{'Authorization' = $token.createauthorizationHeader();'ConsistencyLevel' = 'eventual'}
    
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

    If ($Wipe -and !$KeepUserData){

        $IntuneDevice = Get-IntuneDevice -Name $Device
        $Uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($IntuneDevice.Id)/wipe"
        $Body = @{

            "keepUserData" = $False;
            "keepEnrollmentData" = $False
        
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
    elseif ($Wipe -and $KeepUserData){

        $IntuneDevice = Get-IntuneDevice -Name $Device
        $Uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($IntuneDevice.Id)/wipe"
        $Body = @{

            "keepUserData" = $true;
            "keepEnrollmentData" = $true
        
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
    elseif ($Retire){

        $IntuneDevice = Get-IntuneDevice -Name $Device
        $Uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($IntuneDevice.Id)/retire"
        Try {

            Invoke-RestMethod -Uri $Uri -Headers $Header -Method POST

        }
        catch{
            $ResponseResult = $_.Exception.Response.GetResponseStream()
            $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
            $ResponseBody = $ResponseReader.ReadToEnd()
            $ResponseBody
        }
        

    }
    elseif ($Autopilot){

        $IntuneDevice = Get-IntuneDevice -Name $Device
        $Uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($IntuneDevice.Id)/wipe"
        $Body = @{

            "keepUserData" = $False;
            "keepEnrollmentData" = $True
        
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