#Ensure Powershell is using TLS 1.2
$tlsver = [Net.ServicePointManager]::SecurityProtocol 
Write-host "Current TLS versions available in Powershell:" $tlsver 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$tlsver = [Net.ServicePointManager]::SecurityProtocol 
Write-host "New TLS versions available in Powershell:" $tlsver 

#Remove elipsis dots from returned output. Return all output, if possible.
Write-host "Current enumeration limit: " $FormatEnumerationLimit
$FormatEnumerationLimit = -1
Write-host "New enumeration limit: " $FormatEnumerationLimit

# Increase the Function Count
Write-Host "Current max function count: " $MaximumFunctionCount
$MaximumFunctionCount = 8192
Write-Host "New max function count: " $MaximumFunctionCount
 
# Increase the Variable Count
Write-Host "Current max variable count: " $MaximumVariableCount
$MaximumVariableCount = 8192
Write-Host "New max variable count: " $MaximumVariableCount

#Trust PSGallery
Write-host "Current PSGallery Trust status:" (Get-PSRepository -name "PSGallery").installationpolicy
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Write-host "New PSGallery Trust status:" (Get-PSRepository -name "PSGallery").installationpolicy

#Update modules listed in $update variable
$update = "microsoft.graph"
foreach($checkmodule in $update)
{
    #getting version of installed module
    $version = (Get-Module -ListAvailable $checkmodule) | Sort-Object Version -Descending  | Select-Object Version -First 1
    #converting version to string
    $stringver = $version | Select-Object @{n='ModuleVersion'; e={$_.Version -as [string]}}
    $a = $stringver | Select-Object Moduleversion -ExpandProperty Moduleversion
    #getting latest module version from ps gallery 
    $psgalleryversion = Find-Module -Name $checkmodule | Sort-Object Version -Descending | Select-Object Version -First 1
    #converting version to string
    $onlinever = $psgalleryversion | select @{n='OnlineVersion'; e={$_.Version -as [string]}}
    $b = $onlinever | Select-Object OnlineVersion -ExpandProperty OnlineVersion

    if ($version -eq $null)
    {
        Write-host "Installing module:" $checkmodule
        Install-module $checkmodule -Force #-WhatIf
        $version = Get-Module -ListAvailable $checkmodule | Sort-Object Version -Descending | Select-Object Version -First 1
        $stringver = $version | out-string -Stream | select -skip 3
        Write-host "Module is version:" $stringver
    }
    elseif ([version]"$a" -ge [version]"$b")
    {
        Write-Host "Module: $checkmodule"
        Write-Host "Installed $a is equal or greater than $b"
        Write-Host "No update required"
    }
    elseif ([version]"$a" -lt [version]"$b")
    {
        Write-Host "Module: $checkmodule"
        Write-Host "Installed Module:$a is lower version than $b"
        #ask for update  
        $title    = 'Module Update'
        $question = "Do you want to update Module $checkmodule?"
        $choices  = '&Yes', '&No'

        $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
        if ($decision -eq 0)
        {
            Write-Host "Selected YES Updating module $checkmodule"
            Update-Module -Name $checkmodule -Verbose -Force
        }
        else
        {
            Write-Host "Selected NO , no updates to Module $checkmodule were done"
        }
    }
    else
    {
        Write-host "ERROR"
    }
}

#Set appropriate mode for import module operations
Write-host "Current Microsoft Graph profile:" (get-mgprofile).name
Select-MgProfile -Name "Beta"
Write-host "New Microsoft Graph profile:" (get-mgprofile).name

#Import nessesary module(s)
foreach($checkmodule in $update)
{
    import-module -name $checkmodule
}

#Connect Powershell to MS Graph
Connect-MgGraph -Scopes @("User.Read.All";"UserAuthenticationMethod.Read.All") #;"UserAuthenticationMethod.ReadWrite.All")

#Output file path
mkdir "C:\HJS"
$outpath = "C:\hjs\MFA_Status1.csv"

#Main script to get various auth status
$i=0
$data = get-mguser -Filter 'accountEnabled eq true' -All
$array = foreach ($user in $data)
{
    $MFACount = $null
    
    $m0count = $null
    $m1count = $null
    $m2count = $null
    $m3count = $null
    $m4count = $null
    $m5count = $null
    $m6count = $null
    $m7count = $null

    $m0odata = $null
    $m0phonenumber = $null
    $m0phonetype = $null
    $m0smssigninstate = $null
    $m1odata = $null
    $m2odata = $null
    $m2displayName = $null
    $m2devicetag = $null
    $m2phoneappversion = $null
    $m2created = $null
    $m2clientappname = $null
    $m3odata = $null
    $m3displayname = $null
    $m3devicetag = $null
    $m3phoneappversion = $null
    $m3created = $null
    $m3creation = $null
    $m3clientappname = $null
    $m4odata = $null
    $m4emailAddress = $null
    $m5odata = $null
    $m5displayName = $null
    $m5createdDateTime = $null
    $m5keyStrength = $null
    $m6odata = $null
    $m7odata = $null
    $m7displayname = $null
    $m7creationDateTime = $null
    $m7createdDateTime = $null
    $m7aaGUID = $null
    $m7model = $null
    $m7attestationCertificates = $null
    $m7attestationLevel = $null

    $mfamethods = get-mguserauthenticationmethod -UserId $user.userprincipalname
    $mfacount = $mfamethods.count
    foreach ($mfamethod in $mfamethods)
    {
        if (($mfamethod.additionalproperties.'@odata.type').ToString() -like "#microsoft.graph.phoneAuthenticationMethod")
        {
            $m0count++
            $m0odata += $mfamethod.additionalproperties.'@odata.type' + ","
            $m0phonenumber += $mfamethod.additionalproperties.phoneNumber + ","
            $m0phonetype += $mfamethod.additionalproperties.phoneType + ","
            $m0smssigninstate += $mfamethod.additionalproperties.smsSignInState + ","
        }
        elseif (($mfamethod.additionalproperties.'@odata.type').ToString() -like "#microsoft.graph.passwordAuthenticationMethod")
        {
            $m1count++
            $m1odata += $mfamethod.additionalproperties.'@odata.type' + ","
        }
        elseif (($mfamethod.additionalproperties.'@odata.type').ToString() -like "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod")
        {
            $m2count++
            $m2odata += $mfamethod.additionalproperties.'@odata.type' + ","
            $m2displayName += $mfamethod.additionalproperties.displayName + ","
            $m2devicetag += $mfamethod.additionalproperties.deviceTag + ","
            $m2phoneappversion += $mfamethod.additionalproperties.phoneAppVersion + ","
            $m2created += $mfamethod.additionalproperties.createdDateTime + ","
            $m2clientappname += $mfamethod.additionalproperties.clientAppName + ","
        }
        elseif (($mfamethod.additionalproperties.'@odata.type').ToString() -like "#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod")
        {
            $m3count++
            $m3odata += $mfamethod.additionalproperties.'@odata.type' + ","
            $m3displayname += $mfamethod.additionalproperties.displayName + ","
            #$m3devicetag += $mfamethod.additionalproperties.deviceTag + ","
            #$m3phoneappversion += $mfamethod.additionalproperties.phoneAppVersion + ","
            $m3creation += $mfamethod.additionalproperties.creationDateTime.tostring() + ","
            $m3created += $mfamethod.additionalproperties.createdDateTime + ","
            #$m3clientappname += $mfamethod.additionalproperties.clientAppName + ","
        }
        elseif (($mfamethod.additionalproperties.'@odata.type').ToString() -like "#microsoft.graph.emailAuthenticationMethod")
        {
            $m4count++
            $m4odata += $mfamethod.additionalproperties.'@odata.type' + ","
            $m4emailAddress += $mfamethod.additionalproperties.emailAddress + ","
        }
        elseif (($mfamethod.additionalproperties.'@odata.type').ToString() -like "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod")
        {
            $m5count++
            $m5odata += $mfamethod.additionalproperties.'@odata.type' + ","
            $m5displayName += $mfamethod.additionalproperties.displayName + ","
            $m5createdDateTime += $mfamethod.additionalproperties.createdDateTime + ","
            $m5keyStrength += $mfamethod.additionalproperties.keyStrength + ","
        }
        elseif (($mfamethod.additionalproperties.'@odata.type').ToString() -like "#microsoft.graph.softwareOathAuthenticationMethod")
        {
            $m6count++
            $m6odata += $mfamethod.additionalproperties.'@odata.type' + ","
        }
        elseif (($mfamethod.additionalproperties.'@odata.type').ToString() -like "#microsoft.graph.fido2AuthenticationMethod")
        {
            $m7count++
            $m7odata += $mfamethod.additionalproperties.'@odata.type' + ","
            $m7displayname += $mfamethod.additionalproperties.displayName + ","
            $m7creationDateTime += $mfamethod.additionalproperties.creationDateTime + ","
            $m7createdDateTime += $mfamethod.additionalproperties.createdDateTime + ","
            $m7aaGuid += $mfamethod.additionalproperties.aaGuid + ","
            $m7model += $mfamethod.additionalproperties.model + ","
            $m7attestationCertificates += $mfamethod.additionalproperties.attestationCertificates + ","
            $m7attestationLevel += $mfamethod.additionalproperties.attestationLevel + ","
        }
        else
        {
            Write-host "NO MATCH ON MFA TYPE:" $user.UserPrincipalName " - " ($mfamethod.additionalproperties.'@odata.type').ToString()
        }
    }
    New-Object PSObject -Property @{
            UserPrincipalName = $user.UserPrincipalName
            "Number of Auth Entities Proofed Up" = $mfacount
            "# of Phone" = (&{if($m0count) {$m0count} elseif(!$m0count) {"0"}})
            "# of Password" = (&{if($m1count) {$m1count} elseif(!$m1count) {"0"}})
            "# of TOTP" = (&{if($m2count) {$m2count} elseif(!$m2count) {"0"}})
            "# of Passwordless" = (&{if($m3count) {$m3count} elseif(!$m3count) {"0"}})
            "# of Email" = (&{if($m4count) {$m4count} elseif(!$m4count) {"0"}})
            "# of WHFB" = (&{if($m5count) {$m5count} elseif(!$m5count) {"0"}})
            "# of Software OAUTH" = (&{if($m6count) {$m6count} elseif(!$m6count) {"0"}})
            "# of FIDO2" = (&{if($m7count) {$m7count} elseif(!$m7count) {"0"}})
            "TXT Message MFA" = (&{if($m0odata) {"Yes"} elseif(!$m0odata) {"No"}})
            "Phone Number" = $m0phonenumber
            "Phone Type" = $m0phonetype
            "SMS As Username State" = $m0smssigninstate
            "Does Account Have Password?" = (&{if($m1odata) {"Yes"} elseif(!$m1odata) {"No"}})
            "TOTP Proofed Up?" = (&{if($m2odata) {"Yes"} elseif(!$m2odata) {"No"}})
            "TOTP Device Name" = $m2displayName
            "TOTP Token Type" = $m2devicetag
            "TOTP App Version" = $m2phoneappversion
            "TOTP App Creation Date/Time (only shows if passwordless & MS Auth)" = $m2created
            "App Used for TOTP" = $m2clientappname
            "Passwordless Auth Enabled?" = (&{if($m3odata) {"Yes"} elseif(!$m3odata) {"No"}})
            "Device Used for Passwordless Auth" = $m3displayname
            #m3devicetag = $m3devicetag
            #m3phoneappversion = $m3phoneappversion
            "Passwordless Created" = $m3created
            "Passwordless Creation" = $m3creation
            #m3clientappname = $m3clientappname
            "Email SSPR" = (&{if($m4odata) {"Yes"} elseif(!$m4odata) {"No"}})
            "Email Address" = $m4emailAddress
            "WHFB" = (&{if($m5odata) {"Yes"} elseif(!$m5odata) {"No"}})
            "WHFB Hostname" = $m5displayName
            "WHFB Created" = $m5createdDateTime
            "WHFB KeyStrength" = $m5keyStrength
            "Software OAUTH?" = (&{if($m6odata) {"Yes"} elseif(!$m6odata) {"No"}})
            "FIDO2 MFA" = (&{if($m7odata) {"Yes"} elseif(!$m7odata) {"No"}})
            "FIDO2 Device" = $m7displayname
            "FIDO2 Creation" = $m7creationDateTime
            "FIDO2 Created" = $m7createdDateTime
            "FIDO2 aaGuid" = $m7aaGuid
            "FIDO2 Model" = $m7model
            "FIDO2 Attest Cert" = $m7attestationCertificates
            "FIDO2 Attest Level" = $m7attestationLevel
        }
    $i++
    $percent = ($i / $data.count) * 100
    Write-host "Progress:" $i "of" $data.count "or" $percent "%"
}

#Export results in a specific order to $outpath
$array | select UserPrincipalName,"Number of Auth Entities Proofed Up","# of Phone","# of Password","# of TOTP","# of Passwordless","# of Email","# of WHFB","# of Software OAUTH","# of FIDO2","TXT Message MFA","Phone Number","Phone Type","SMS As Username State","Does Account Have Password?","TOTP Proofed Up?","TOTP Device Name","TOTP Token Type","TOTP App Version","TOTP App Creation Date/Time (only shows if passwordless & MS Auth)","App Used for TOTP","Passwordless Auth Enabled?","Device Used for Passwordless Auth","Passwordless Created","Passwordless Creation","Email SSPR","Email Address","WHFB","WHFB Hostname","WHFB Created","WHFB KeyStrength","Software OAUTH?","FIDO2 MFA","FIDO2 Device","FIDO2 Creation","FIDO2 Created","FIDO2 aaGuid","FIDO2 Model","FIDO2 Attest Cert","FIDO2 Attest Level" | Export-Csv $outpath -NoTypeInformation

#Properly close Powershell connection to MS Graph
Disconnect-MgGraph