function Assign-IntuneDeviceConfiguration {
    
    <#
		IMPORTANT:
        ===========================================================================
        This script is provided 'as is' without any warranty. Any issues stemming 
        from use is on the user.
        ===========================================================================
		.DESCRIPTION
		Adds or removes Intune configuration policy assignment using AAD group.
        Things to change to deploy in your environment:
        Line 36: replace x with clientID of your reigstered app. See https://docs.microsoft.com/en-us/graph/auth-v2-user for more info.
		===========================================================================
		.PARAMETER Configuration
		Required - Name of the configuration to assign.
		.PARAMETER Group
		Required - Name of the AAD group being assigned to the configuration policy.
        .PARAMETER RemoveAssignment
        Optional switch to remove group assignment from Intune app.
		===========================================================================
		.EXAMPLE
		Assign-IntuneDeviceConfiguration -Configuration DeviceEncryption -Group AllUsers <--- Assigns AAD group AllUsers to DeviceEncryption configuration policy
        Assign-IntuneDeviceConfiguration -Configuration DeviceEncryption -Group AllUsers -RemoveAssignment <--- Removes assignment if exist
	#>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [String]$Group,
        [Parameter(Mandatory = $True)]
        [String]$Configuration,
        [Parameter()]
        [Switch]$RemoveAssignment
    )

    $token = Get-MsalToken -clientid x -tenantid organizations
    $global:header = @{'Authorization' = $token.createauthorizationHeader();'ConsistencyLevel' = 'eventual'}

###########################################################

    function Get-IntuneDeviceConfiguration {

        [CmdletBinding()]
        param (
            [Parameter()]
            [String]$Name,
            [Parameter()]
            [Switch]$All
        )

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
        elseif (!$All -and $Name){

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

    $ConfigId = Get-IntuneDeviceConfiguration -Name EndpointProtection | select -expand id
    $Target = Get-AADGroup -Name $Group | select -expand id
    If ($Group -and $Configuration -and !$RemoveAssignment){

        $Uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$ConfigId/assign"
        $Body = @{

            "assignments" = @(

                @{

                    "odata.type" = "microsoft.graph.deviceConfigurationAssignment";
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