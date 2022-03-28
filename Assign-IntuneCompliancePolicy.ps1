function Assign-IntuneCompliancePolicy {

    <#
		IMPORTANT:
        ===========================================================================
        This script is provided 'as is' without any warranty. Any issues stemming 
        from use is on the user.
        ===========================================================================
		.DESCRIPTION
		Adds or Removes assignment to an Intune compliance policy using an AAD group.
        Things to change to deploy in your environment:
        Line 36: replace x with clientID of your reigstered app. See https://docs.microsoft.com/en-us/graph/auth-v2-user for more info.
		===========================================================================
		.PARAMETER Policy
		Required - Name of compliance policy to assign.
		.PARAMETER Group
		Required - Name of the group to assign the policy to.
        .PARAMETER RemoveAssignment
        Optional switch to remove group assignment from Intune compliance policy.
		===========================================================================
		.EXAMPLE
		Assign-IntuneCompliancePolicy -Policy StandardUser -Group StandardUsers <--- Assigns StandardUser compliance policy to AAD group StandardUsers
        Assign-IntuneCompliancePolicy -Policy StandardUser -Group StandardUsers -RemoveAssignment <--- Unassigns StandardUser compliance policy from StandardUsers AAD group
	#>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [String]$Policy,
        [Parameter(Mandatory = $True)]
        [String]$Group,
        [Parameter(Mandatory = $True)]
        [Switch]$RemoveAssignment
    )

    $token = Get-MsalToken -clientid x -tenantid organizations
    $global:header = @{'Authorization' = $token.createauthorizationHeader();'ConsistencyLevel' = 'eventual'}

    function Get-IntuneCompliancePolicy {
    
        <#
            IMPORTANT:
            ===========================================================================
            This script is provided 'as is' without any warranty. Any issues stemming 
            from use is on the user.
            ===========================================================================
            .DESCRIPTION
            Retrieves Intune compliancy policy.
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

###########################################################

    function Get-AADGroup {

        <#
            IMPORTANT:
            ===========================================================================
            This script is provided 'as is' without any warranty. Any issues stemming 
            from use is on the user.
            ===========================================================================
            .DESCRIPTION
            Gets an Azure AD Group
            ===========================================================================
            .PARAMETER All
            Lists all AAD groups by displayName.
            .PARAMETER Name
            The displayName of the group to get.
            ===========================================================================
            .EXAMPLE
            Get-AADGroup -All <--- This will return all AzureAD groups
            Get-AADGroup -Name Azure-Test <--- This will return the group Azure-Test
        #>

        [cmdletbinding()]
        param(

            [Parameter()]
            [Switch]$All,
            [Parameter()]
            [String]$Name

        )

        
        If ($All) {

            $uri = "https://graph.microsoft.com/v1.0/groups"
            $Groups = While (!$NoMoreGroups) {

                Try {
                    
                    $GetGroups = Invoke-RestMethod -uri $uri -headers $header -method GET

                }
                catch{
                    $ResponseResult = $_.Exception.Response.GetResponseStream()
                    $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                    $ResponseBody = $ResponseReader.ReadToEnd()
                    $ResponseBody    
                }
                    
                $getGroups.value
                If ($getGroups."@odata.nextlink") {

                    $uri = $getGroups."@odata.nextlink"

                }
                Else {
                
                    $NoMoreGroups = $True

                }
            }
            $NoMoreGroups = $False
            $Groups | select displayName | sort displayName

        }
        elseif ($Name -ne $Null) {

            $Uri = "https://graph.microsoft.com/v1.0/groups"
            $Groups = While (!$NoMoreGroups) {

                Try {
                    
                    $GetGroups = Invoke-RestMethod -uri $uri -headers $header -method GET

                }
                catch{
                    $ResponseResult = $_.Exception.Response.GetResponseStream()
                    $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                    $ResponseBody = $ResponseReader.ReadToEnd()
                    $ResponseBody    
                }
                    
                $getGroups.value
                If ($getGroups."@odata.nextlink") {

                    $uri = $getGroups."@odata.nextlink"

                }
                Else {
                
                    $NoMoreGroups = $True

                }
            }
            $NoMoreGroups = $False
            $Groups | where {$_.displayName -eq $Name}

        }
        else {

            Write-Host "Please specify individual group or use All switch."

        }

    }

###########################################################

    $ComplianceId = Get-IntuneCompliancePolicy -Policy $Policy | select -expand id
    $Target = Get-AADGroup -Name $Group | select -expand id
    If ($Group -and $Configuration -and !$RemoveAssignment){

        $Uri = "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies/$ComplianceId/assign"
        $Body = @{

            "assignments" = @(

                @{

                    "odata.type" = "microsoft.graph.deviceCompliancePolicyAssignment";
                    "id" = $Target;
                    "target" = @{"@odata.type" = "microsoft.graph.groupAssignmentTarget";"groupId"=$Target};

                }

            )

        }
        $JSON = $Body | ConvertTo-Json -Depth 3
        Try {

            (Invoke-RestMethod -Uri $Uri -Headers $Header -Method Post -ContentType "application/Json" -Body $JSON).value

        }
        catch{
            $ResponseResult = $_.Exception.Response.GetResponseStream()
            $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
            $ResponseBody = $ResponseReader.ReadToEnd()
            $ResponseBody
        }

    }
    elseif ($Group -and $Configuration -and $RemoveAssignment){

        $GetUri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$ConfigId/assignments"
            Try {
        
                $Get = (Invoke-RestMethod -Uri $GetUri -Headers $Header -Method GET).value
        
            }
            catch{
                $ResponseResult = $_.Exception.Response.GetResponseStream()
                $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
                $ResponseBody = $ResponseReader.ReadToEnd()
                $ResponseBody
            }
            $Id = $Get.id | select-string -pattern $Target | foreach {$_.Line}
            If ($Get.id -like "*$Target*"){

                $Uri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$ConfigId/assignments/$Id"
                Try {

                    Invoke-RestMethod -Uri $Uri -Headers $Header -Method Delete | out-null

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