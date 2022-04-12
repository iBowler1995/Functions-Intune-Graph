function Get-IntuneUpdateRing {

    [CmdletBinding()]
    param (
        [Parameter()]
        [String]$Ring,
        [Parameter()]
        [Switch]$Status,
        [Parameter()]
        [Switch]$All
    )

<#
		IMPORTANT:
        ===========================================================================
        This script is provided 'as is' without any warranty. Any issues stemming 
        from use is on the user.
        ===========================================================================
		.DESCRIPTION
		Retrieves Intune Update Ring and status.
        Things to change before using:
        Line 69 - replace x with clientID of your reigstered app. See https://bit.ly/3KApKhJ for more info.
        Line 140 - replace x with clientID of your reigstered app. See https://bit.ly/3KApKhJ for more info.
		===========================================================================
		.PARAMETER Ring
		Name of the Update Ring to pull
        Returns update status for the specified Update Ring.
		===========================================================================
		.EXAMPLE
		Get-IntuneUpdateRing -Ring StandardUsers <--- This will retrieve details about the Update Ring itself
        Get-IntuneUpdateRing -Ring StandardUsers -Status <--- This will retrieve update status for Update Ring devices
	#>

###########################################################

    function Get-IntuneDeviceConfiguration {

        <#
            IMPORTANT:
            ===========================================================================
            This script is provided 'as is' without any warranty. Any issues stemming 
            from use is on the user.
            ===========================================================================
            .DESCRIPTION
            Retrieves Intune configuration policy.
            ===========================================================================
            .PARAMETER Name
            Required if not using All switch - Name of the configuration policy to retrieve.
            .PARAMETER All
            Retrieves all Intune configuration policies.
            .PARAMETER Status
            Returns device status for the specified configuration policy.
            ===========================================================================
            .EXAMPLE
            Get-IntuneConfigurationPolicy -Policy BlockAllUSB <--- Retrieves BlockAllUSB configuration policy
            Get-IntuneConfigurationPolicy -Policy BlockAllUSB -Status <--- Retrieves BlockAllUSB compliance policy device status
        #>
        
        [CmdletBinding()]
        param (
            [Parameter()]
            [String]$Name,
            [Parameter()]
            [Switch]$All,
            [Parameter()]
            [Switch]$Status
        )

        $token = Get-MsalToken -clientid x -tenantid organizations
        $global:header = @{'Authorization' = $token.createauthorizationHeader();'ConsistencyLevel' = 'eventual'}

        If ($All -and !$Name){

            $Uri = "https://graph.microsoft.com/beta/devicemanagement/deviceConfigurations"
            Try {

                (Invoke-RestMethod -Uri $Uri -Headers $Header).value

            }
            catch{
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody
            }

        }
        elseif ($Name -and !$All -and !$Status){

            $Uri = "https://graph.microsoft.com/beta/devicemanagement/deviceConfigurations?`$filter=displayName%20eq%20'$Name'"
            Try {

                (Invoke-RestMethod -Uri $Uri -Headers $Header).value

            }
            catch{
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody
            }

        }
        elseif ($Name -and !$All -and $Status){

            $Uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=displayName%20eq%20'$Name'"
            Try {

            $ConfigurationPolicy =  (Invoke-RestMethod -Uri $Uri -Headers $Header -Method GET).value
            $ConfigurationPolicyId = $ConfigurationPolicy | select -expand id
        
            }
            catch{
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody
            }

            Try {

                $Uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$ConfigurationPolicyId/deviceStatuses"
                (Invoke-RestMethod -Uri $Uri -Headers $Header).value | select id,deviceDisplayName,LastReportedDateTime,status,userPrincipalName

            }
            catch{
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody
            }

        }

    }

    
 ##########################################################

    $token = Get-MsalToken -clientid x -tenantid organizations
    $global:header = @{'Authorization' = $token.createauthorizationHeader();'ConsistencyLevel' = 'eventual'}

    If ($Ring  -and !$Status){

        $UpdateRing = Get-IntuneDeviceConfiguration -All | where {$_.displayName -like "*$Ring*"}
        $UpdateRingId = $UpdateRing.Id
        $Uri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$UpdateRingId"
        Try {

            Invoke-RestMethod -Uri $Uri -Headers $Header -Method Get

        }
        catch{
            $ResponseResult = $_.Exception.Response.GetResponseStream()
            $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
            $ResponseBody = $ResponseReader.ReadToEnd()
            $ResponseBody    
        }

    }
    elseif ($Ring -and $Status){

        $UpdateRing = Get-IntuneDeviceConfiguration -All | where {$_.displayName -like "*$Ring*"}
        $UpdateRingId = $UpdateRing.Id
        $Uri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$UpdateRingId/deviceStatuses"
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
    elseif ($All){

        Get-IntuneDeviceConfiguration -All | where {$_.microsoftUpdateServiceAllowed -eq 'true'}

    }

}