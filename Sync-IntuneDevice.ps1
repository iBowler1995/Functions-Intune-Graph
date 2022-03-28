function Sync-IntuneDevice {

    <#
		IMPORTANT:
        ===========================================================================
        This script is provided 'as is' without any warranty. Any issues stemming 
        from use is on the user.
        ===========================================================================
		.DESCRIPTION
		Syncs an Intune managed device.
        Things to change to deploy in your environment:
        Line 32: replace x with clientID of your reigstered app. See https://docs.microsoft.com/en-us/graph/auth-v2-user for more info.
		===========================================================================
		.PARAMETER Device
		Required if not using All switch - Name of the device to sync.
		.PARAMETER All
		Syncs all Intune managed devices.
		===========================================================================
		.EXAMPLE
		Sync-IntuneDevice -Name DESKTOP-7XH8Z <--- Syncs DESKTOP-7XH8Z
        Sync-IntuneDevice -All <--- Syncs all Intune managed devices.
	#>
    
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $False)]
        [Switch]$All,
        [Parameter(Mandatory = $False)]
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
###########################################################
  
        If (!$All -and $Device){

            $IntuneDevice = Get-IntuneDevice -Name $Device
            $IntuneDeviceId = $IntuneDevice.Id
            $SyncUri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$IntuneDeviceId/syncDevice"
            Try {
    
                Invoke-RestMethod -Uri $SyncUri -Headers $Header -Method Post
    
            }
            catch{
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody
            }
        
        }
        elseif ($All -and !$Device){
    
            $IntuneDevices = Get-IntuneDevice -All
            foreach ($IntuneDevice in $IntuneDevices){
    
                $IDevice = Get-IntuneDevice -Name $IntuneDevice.deviceName
                $IntuneDeviceID = $IDevice.Id 
                $SyncUri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$IntuneDeviceId/syncDevice"
                Try {
    
                    Write-Host "Sending sync request to $($IntuneDevice.deviceName)..." -f white
                    Invoke-RestMethod -Uri $SyncUri -Headers $Header -Method Post | Out-Null
                    Write-Host "Sync request sent to $($IntuneDevice.deviceName)." -f Green
                    Write-Host "==========================================" -f White
    
                }
                catch{
                    $ResponseResult = $_.Exception.Response.GetResponseStream()
                    $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                    $ResponseBody = $ResponseReader.ReadToEnd()
                    $ResponseBody
                }
    
            }
    
        }
        else{
    
            Write-Host "Please specify a device using the -Name parameter or use the -All switch to see all devices." -f Red
    
        }
    
    }