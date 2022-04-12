function Assign-IntuneApp {

    <#
		IMPORTANT:
        ===========================================================================
        This script is provided 'as is' without any warranty. Any issues stemming 
        from use is on the user.
        ===========================================================================
		.DESCRIPTION
		Adds or removes Intune App assignment using AAD group.
        Things to change to deploy in your environment:
        Line 40: replace x with clientID of your reigstered app. See https://bit.ly/3KApKhJ for more info.
		===========================================================================
		.PARAMETER App
		Required - Name of the app to assign.
		.PARAMETER Group
		Required - Name of the AAD group being assigned to the app.
        .PARAMETER Intent
        Required if not removing assignment - Intent of the assignment. Can be required, uninstall, available (lists in Company Portal), and availableWithoutEnrollment
        .PARAMETER RemoveAssignment
        Optional switch to remove group assignment from Intune app.
		===========================================================================
		.EXAMPLE
		Assign-IntuneApp -App 7-Zip -Group Intune-7-Zip -Intent Required <--- Assigns AAD group Intune-7-Zip to 7-Zip app and sets it to require install
        Assign-IntuneApp -App 7-Zip -Group Intune-7-Zip -RemoveAssignment <--- Removes Intune-7-Zip group assignment from 7-Zip app if it exists.
	#>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [String]$App,
        [Parameter(Mandatory = $True)]
        [String]$Group,
        [Parameter()][ValidateSet("Required","Uninstall","Available","availableWithoutEnrollment")]
        [String]$Intent,
        [Parameter()]
        [Switch]$RemoveAssignment
    )

    $token = Get-MsalToken -clientid x -tenantid organizations
    $global:header = @{'Authorization' = $token.createauthorizationHeader();'ConsistencyLevel' = 'eventual'}

    function Get-IntuneApp {

        <#
            IMPORTANT:
            ===========================================================================
            This script is provided 'as is' without any warranty. Any issues stemming 
            from use is on the user.
            ===========================================================================
            .DESCRIPTION
            Retrieves Intune managed app.
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

    $AppId = Get-IntuneApp -App $App | select -expand id
    $Target = Get-AADGroup -Name $Group | select -expand id
    If (!$RemoveAssignment){

        $Uri = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$AppId/assign"
        $Body = @{
            "mobileAppAssignments" = @(
            @{
                "@odata.type" = "#microsoft.graph.mobileAppAssignment";
                "intent" = $Intent;
                "target" = @{"@odata.type" = "microsoft.graph.groupAssignmentTarget";"groupId"=$Target};
                
            }
            )
        }
        $JSON = $Body | ConvertTo-Json -Depth 3
        Try {

            Invoke-RestMethod -Uri $Uri -Headers $Header -Body $JSON -Method POST -ContentType "application/Json" | out-null

        }
        catch{
            $ResponseResult = $_.Exception.Response.GetResponseStream()
            $ResponseReader = New-Object System.IO.StreamReader($ResponseResult)
            $ResponseBody = $ResponseReader.ReadToEnd()
            $ResponseBody
        }

    }
    else{
        
        $AppId = Get-IntuneApp -App VMWARE | select -expand id
        $Target = Get-AADGroup -Name '~Intune-Test' | select -expand id
        $GetUri = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$AppId/assignments"
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

            $Uri = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$AppId/assignments/$Id"
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