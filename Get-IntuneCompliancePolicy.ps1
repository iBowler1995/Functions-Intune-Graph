function Get-IntuneCompliancePolicy {
    
    <#
		IMPORTANT:
        ===========================================================================
        This script is provided 'as is' without any warranty. Any issues stemming 
        from use is on the user.
        ===========================================================================
		.DESCRIPTION
		Retrieves Intune compliancy policy.
        Things to change to deploy in your environment:
        Line 36: replace x with clientID of your reigstered app. See https://bit.ly/3KApKhJ for more info.
		===========================================================================
		.PARAMETER Policy
		Required if not using All switch - Name of the compliance policy to retrieve.
		.PARAMETER All
		Retrieves all Intune compliance policies.
        .PARAMETER Status
        Returns device status for the specified compliance policy.
		===========================================================================
		.EXAMPLE
		Get-IntuneCompliancePolicy -Policy StandardUser <--- Retrieves StandardUser compliance policy
        Get-IntuneCompliancePolicy -Policy StandardUser -Status <--- Retrieves StandardUser compliance policy device status
	#>
    
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]$Policy,
        [Parameter()]
        [Switch]$All,
        [Parameter()]
        [Switch]$Status
    )

    $token = Get-MsalToken -clientid x -tenantid organizations
    $global:header = @{'Authorization' = $token.createauthorizationHeader();'ConsistencyLevel' = 'eventual'}

    If (!$Policy -and $All){

        $Uri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies"
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
    elseif ($Policy -and !$All -and !$Status){

        $Uri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies?`$filter=displayName%20eq%20'$Policy'"
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
    elseif ($Policy -and !$All -and $Status){

        $Uri = "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies?`$filter=displayName%20eq%20'$Policy'"
        Try {

           $CompliancePolicy =  (Invoke-RestMethod -Uri $Uri -Headers $Header -Method GET).value
           $CompliancePolicyId = $CompliancePolicy | select -expand id
    
        }
        catch{
            $ResponseResult = $_.Exception.Response.GetResponseStream()
            $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
            $ResponseBody = $ResponseReader.ReadToEnd()
            $ResponseBody
        }

        Try {

            $Uri = "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies/$CompliancePolicyId/deviceStatuses"
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