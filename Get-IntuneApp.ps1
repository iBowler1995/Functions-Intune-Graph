function Get-IntuneApp {

    <#
		IMPORTANT:
        ===========================================================================
        This script is provided 'as is' without any warranty. Any issues stemming 
        from use is on the user.
        ===========================================================================
		.DESCRIPTION
		Retrieves Intune managed app.
        Things to change to deploy in your environment:
        Line 36: replace x with clientID of your reigstered app. See https://docs.microsoft.com/en-us/graph/auth-v2-user for more info.
		===========================================================================
		.PARAMETER App
		Required if not using All switch - Name of the app to retrieve.
		.PARAMETER All
		Retrieves all Intune managed apps.
        .PARAMETER Status
        Returns device install status for the specified app.
		===========================================================================
		.EXAMPLE
		Assign-IntuneApp -App 7-Zip -Group Intune-7-Zip -Intent Required <--- Assigns AAD group Intune-7-Zip to 7-Zip app and sets it to require install
        Assign-IntuneApp -App 7-Zip -Group Intune-7-Zip -RemoveAssignment <--- Removes Intune-7-Zip group assignment from 7-Zip app if it exists.
	#>
    
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]$App,
        [Parameter()]
        [Switch]$All,
        [Parameter()]
        [Switch]$Status
    )

    $token = Get-MsalToken -clientid x -tenantid organizations
    $global:header = @{'Authorization' = $token.createauthorizationHeader();'ConsistencyLevel' = 'eventual'}

    If (!$App -and $All){

        $Uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps"
        Try {

            $AllApps = Invoke-RestMethod -Uri $Uri -Headers $Header -Method GET
            $Apps = $AllApps.value | where {$_.appAvailability -notlike "*global*"}
            Return $Apps
    
        }
        catch{
            $ResponseResult = $_.Exception.Response.GetResponseStream()
            $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
            $ResponseBody = $ResponseReader.ReadToEnd()
            $ResponseBody
        }
        
    }
    elseif ($App -and !$All -and !$Status){

        $Uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$Filter=displayName%20eq%20'$App'"
        Try {

            (Invoke-RestMethod -Uri $Uri -Headers $Header -Method GET).value
    
        }
        catch{
            $ResponseResult = $_.Exception.Response.GetResponseStream()
            $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
            $ResponseBody = $ResponseReader.ReadToEnd()
            $ResponseBody
        }

    }
    elseif ($App -and !$All -and $Status){

        $Uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$Filter=displayName%20eq%20'$App'"
        Try {

           $IntuneApp =  (Invoke-RestMethod -Uri $Uri -Headers $Header -Method GET).value
           $IntuneAppId = $IntuneApp | select -expand id
    
        }
        catch{
            $ResponseResult = $_.Exception.Response.GetResponseStream()
            $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
            $ResponseBody = $ResponseReader.ReadToEnd()
            $ResponseBody
        }

        Try {

            $Uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$IntuneAppId/deviceStatuses"
            (Invoke-RestMethod -Uri $Uri -Headers $Header).value | select id,deviceName,deviceId,lastSyncDateTime,InstallState,installStateDetail,errorCode,userPrincipalName

        }
catch{
            $ResponseResult = $_.Exception.Response.GetResponseStream()
            $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
            $ResponseBody = $ResponseReader.ReadToEnd()
            $ResponseBody
        }

    }

}