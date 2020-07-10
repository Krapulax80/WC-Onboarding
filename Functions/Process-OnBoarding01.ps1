function Process-OnBoarding01 {
  [CmdletBinding()]
  param(## Domain selector
    [Parameter(Mandatory=$true , ParameterSetName="WestCoast")] [switch]$Westcoast,
    [Parameter(Mandatory=$true , ParameterSetName="XMA")] [switch]$XMA,
    [Parameter(Mandatory=$true)] [string]$FirstName,
    [Parameter(Mandatory=$true)] [string]$LastName,
    [Parameter(Mandatory=$true)] [string]$EmployeeID,
    [Parameter(Mandatory=$true)] [string]$TemplateName,
    [Parameter(Mandatory=$false)] [switch]$NoJBA
  )

      <#
      # Internal use only: this is only for updating the passwords used for the script
      Create-Credential -WestCoast -AD -CredFolder "\\BNWINFRATS01.westcoast.co.uk\c$\Scripts\AD\ONBoarding\Credentials\" -PasswordUpdate
      Create-Credential -WestCoast -AAD -CredFolder "\\BNWINFRATS01.westcoast.co.uk\c$\Scripts\AD\ONBoarding\Credentials\" -PasswordUpdate
      Create-Credential -WestCoast -Exchange -CredFolder "\\BNWINFRATS01.westcoast.co.uk\c$\Scripts\AD\ONBoarding\Credentials\" -PasswordUpdate

      Create-Credential -XMA -AD -CredFolder "\\BNWINFRATS01.westcoast.co.uk\c$\Scripts\AD\ONBoarding\Credentials\" -PasswordUpdate
      Create-Credential -XMA -AAD -CredFolder "\\BNWINFRATS01.westcoast.co.uk\c$\Scripts\AD\ONBoarding\Credentials\" -PasswordUpdate
      Create-Credential -XMA -Exchange -CredFolder "\\BNWINFRATS01.westcoast.co.uk\c$\Scripts\AD\ONBoarding\Credentials\" -PasswordUpdate
      #>

  # WORK IN WESTCOAST DOMAIN

    #region Select work domain
    if ($Westcoast.IsPresent){
      # Credentials for WC
      Create-Credential -WestCoast -AD -CredFolder "\\BNWINFRATS01.westcoast.co.uk\c$\Scripts\AD\ONBoarding\Credentials\"
      Create-Credential -WestCoast -AAD -CredFolder "\\BNWINFRATS01.westcoast.co.uk\c$\Scripts\AD\ONBoarding\Credentials\"
      Create-Credential -WestCoast -Exchange -CredFolder "\\BNWINFRATS01.westcoast.co.uk\c$\Scripts\AD\ONBoarding\Credentials\"
      # Variables for WC
      $SystemDomain = "westcoast.co.uk"
      $DomainNetBIOS = "WESTCOASTLTD"
      $AADSyncServer = "BNWAZURESYNC01"; $AADSyncServer = $AADSyncServer + "." + $SystemDomain
      $ExchangeServer = "BNWEXCHDAG01N01" ; $ExchangeServer = $ExchangeServer + "." + $SystemDomain
      $HybridServer = "migration" ; $HybridServer = $HybridServer + "." + $SystemDomain
      $OnpremisesMRSProxyURL = "mail" + "." + $SystemDomain
      $EOTargetDomain = "westcoastltd365.mail.onmicrosoft.com"
      $PeopleFileServer = "BNWFS05"; $PeopleFileServer = $PeopleFileServer + "." + $SystemDomain
      $ProfileFileServer = "BNWFS05"; $ProfileFileServer = $ProfileFileServer + "." + $SystemDomain
      $RDSDiskFileServer = "BNWFS04"; $RDSDiskFileServer = $RDSDiskFileServer  + "." + $SystemDomain
      $StarterOU = "OU=Active Employees,OU=USERS,OU=WC2014,DC=westcoast,DC=co,DC=uk"
      # Domain Controller for WC (I prefer to use the PDC emulator for simplicity)
      #$DC = (Get-ADForest -Identity $SystemDomain -Credential $AD_Credential |  Select-Object -ExpandProperty RootDomain |  Get-ADDomain |  Select-Object -Property PDCEmulator).PDCEmulator
      $DC = (Get-ADForest -Identity $SystemDomain -Credential $AD_Credential |  Select-Object -ExpandProperty RootDomain |  Get-ADDomain |  Select-Object -Property InfrastructureMaster).InfrastructureMaster
      $DFSHost = "BNWITRDS01"; $DFSHost = $DFSHost + "." + $SystemDomain
    }
    # WORK IN XMA DOMAIN
    elseif ($XMA.IsPresent){
      # Credentials for XMA
      Create-Credential -XMA -AD -CredFolder "\\BNWINFRATS01.westcoast.co.uk\c$\Scripts\AD\ONBoarding\Credentials\"
      Create-Credential -XMA -AAD -CredFolder "\\BNWINFRATS01.westcoast.co.uk\c$\Scripts\AD\ONBoarding\Credentials\"
      Create-Credential -XMA -Exchange -CredFolder "\\BNWINFRATS01.westcoast.co.uk\c$\Scripts\AD\ONBoarding\Credentials\"
      # Variables for XMA
      $SystemDomain = "xma.co.uk"
      $DomainNetBIOS = "XMA"
      $AADSyncServer = "BNXO365SYNC02"; $AADSyncServer = $AADSyncServer + "." + $SystemDomain
      $ExchangeServer = "BNXEXCH001N01" ; $ExchangeServer = $ExchangeServer + "." + $SystemDomain
      $HybridServer = "migration" ; $HybridServer = $HybridServer + "." + $SystemDomain
      $OnpremisesMRSProxyURL = "xmaexchcas" + "." + $SystemDomain
      $EOTargetDomain = "xmalimited.mail.onmicrosoft.com"
      $PeopleFileServer = ""; $PeopleFileServer = $PeopleFileServer + "." + $SystemDomain
      $ProfileFileServer = ""; $ProfileFileServer = $ProfileFileServer + "." + $SystemDomain
      $StarterOU = "OU=Users,OU=XMA LTD,DC=xma,DC=co,DC=uk"
      # Domain Controller for XMA
      $DC = (Get-ADForest -Identity $SystemDomain -Credential $AD_Credential |  Select-Object -ExpandProperty RootDomain |  Get-ADDomain |  Select-Object -Property PDCEmulator).PDCEmulator
      $DFSHost = ""; $DFSHost = $DFSHost + "." + $SystemDomain
    }
    # (INVALID WORK DOMAIN DEFINED)
    else {
      Write-Host -ForeGroundColor Red "Bad domain."; Break
    }
    #endregion

  # ACTIVE DIRECTORY

    #region Construct the new user account's PARAMETERS

    # Capitalise first and last name of the NEW user account
    $TextInfo = (Get-Culture).TextInfo
    $FirstName = $TextInfo.ToTitleCase($FirstName)
    $LastName = $TextInfo.ToTitleCase($LastName)

    # Collect details of the TEMPLATE  user account
    if (Get-ADUser -Filter {SAMAccountName -eq $TemplateName } -Properties * -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue) {
    $TemplateUser = Get-ADUser $TemplateName -Properties * -Server $DC -Credential $AD_Credential
    } else { $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);  Write-Host "[$timer] - User $TemplateName not found." -ForegroundColor Red }

    # Construct parent OU of the TEMPLATE user account
    $TemplateAccountOU = ($TemplateUser | Select-Object @{ n = 'Path'; e = { $_.DistinguishedName -replace "CN=$($_.cn),",'' } }).path

    # Conutry code of the TEMPLATE account
    $UsageLocation = $TemplateUser.extensionAttribute6 # Country code

    # Declare the USER DOMAIN
    $UserDomain = ($TemplateUser.UserPrincipalName).Split("\@")[1]

    # Generate various names for the NEW user account
    $NewUserPrincipalName = $FirstName + "." + $LastName + "@" + $UserDomain
    $NewSAMAccountName = $FirstName + "." +  $LastName
      if ($NewSAMAccountName.Length -gt 20) { # Truncate pre-2000 name to 20 characters, if longer, to prevent errors
      $NewSAMAccountName = $NewSAMAccountName.substring(0,20)
      }

    # Create new password for the NEW user account
    Add-Type -AssemblyName System.Web
    $NewPassword = [System.Web.Security.Membership]::GeneratePassword(12,4)

    # Check if the SAM Account Name  already exists. If it does, create a unique one
    if(! (Get-ADUser -Filter {SAMAccountName -eq $NewSAMAccountName } -Properties * -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue) ){
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);  Write-Verbose "[$timer] - SAM account [$NewSAMAccountName] is unique." -Verbose
    } else {
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);  Write-Host "[$timer] - SAM account [$NewSAMAccountName] is NOT unique. Generating unique SAM Name!" -ForeGroundColor Yellow
      Create-UniqueSAMName -NewSAMAccountName $NewSAMAccountName
      $NewSAMAccountName = $global:NewSAMAccountName
    }
    # TODO: Report the SAM Name

    # Derivative names created from the SAM Account Name (these should make these guranteed unique, however we will double check this just in case)
    $NewUserPrincipalName = $NewSAMAccountName + "@" + $UserDomain
    $NewRemoteRoutingAddress = $NewSAMAccountName  + "@" + $EOTargetDomain
    $NewDisplayName = $NewSAMAccountName -replace "\."," "

    # Check if the UPN already exists. If it does, create a unique one
    if(!(Get-ADUser -Filter {UserPrincipalName -eq $NewUserPrincipalName} -Properties * -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue )){
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);  Write-Verbose "[$timer] - UPN  [$NewUserPrincipalName] is unique." -Verbose
   } else {
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);  Write-Host "[$timer] - UPN  [$NewUserPrincipalName] is NOT unique. Generating unique UPN!" -ForeGroundColor Yellow
      Create-UniqueUPN -NewUserPrincipalName $NewUserPrincipalName
      $NewUserPrincipalName = $global:NewUserPrincipalName
    }
    #TODO: Report the UPN

    # Check if Employee ID already exists. If it does, create a unique one
    if (($EmployeeID.gettype()).Name -notlike "String"){
        $EmployeeID = [string]$EmployeeID # convert the $EmployeeID into string
    }
    if(!(Get-ADUser -Filter {EmployeeID -eq $EmployeeID} -Properties * -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue )){
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);  Write-Verbose "[$timer] - EmployeeID  [$EmployeeID] is unique." -Verbose
    } else {
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);  Write-Host "[$timer] - EmployeeID [$EmployeeID] is NOT unique. Generating unique EmployeeID!" -ForeGroundColor Yellow
      Create-UniqueEmployeeID -EmployeeID $EmployeeID
      $EmployeeID = $EmployeeID
    }
    #TODO: Report the EmployeeID

    #endregion

    #region Create and configure the NEW USER ACCOUNT

      # Run the creation function
      Create-NewUserObject -TemplateUser $TemplateUser -NewSAMAccountName $NewSAMAccountName -NewDisplayName $NewDisplayName -FirstName $FirstName -StarterOU $StarterOU -LastName $LastName -NewUserPrincipalName $NewUserPrincipalName -DC $DC -AD_Credential $AD_Credential

      # Check, if the template had a MANAGER. If yes, assign the new account to this manager
      Add-Manager -TemplateUser $TemplateUser -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential

      # Unless specifically said otherwise, assign JBA ACCESS to the account
      Add-JBAAccess -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential

      # Assign EMPLOYEE ID to the new user account
      Add-EmployeeID -EmployeeID $EmployeeID -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential

      # Assign HOLIDAY ENTITLEMENT to the new account
      if ($HolidayEntitlement){
      Add-HolidayEntitlement -HolidayEntitlement $HolidayEntitlement -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential
      }

      # Set the START DATE of the account. (This is purely administrative, account can be used ASAP!)
      if ($EmployeeStartDate){
      Add-StartDate -EmployeeStartDate $EmployeeStartDate -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential
      }

      # Select the releavant CONTRACT TYPE of the new AD user
      if ($ContractType)
      {
      Add-ContractType -ContractType $ContractType -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential
      }

      #FIXME: Add expiry / end date

      # Mirror ALL GROUP MEMBERSHIP of the template account to the new user
      Add-ToTemplatesGroups -TemplateUser $TemplateUser -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential

      # MOVE the new user account to the same OU as the template account
      Move-ToTemplatesOU -TemplateAccountOU $TemplateAccountOU -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential

    #endregion

  # EXCHANGE
    #region Construct mailbox's PARAMETERS

  # Construct the secondary SMTP ADDRESS
  $secondarySMTP = "smtp:" + $FirstName + $LastName.substring(0,1) + "@" + $UserDomain

  # Check if the SECONDARY SMTP ALREADY EXISTS. If it does, create a unique one
  if (!(Get-ADObject -Properties proxyAddresses -Filter { proxyAddresses -EQ $secondarySMTP } -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue)) {
  $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);  Write-Verbose "[$timer] - SMTP [$secondarySMTP] is unique." -Verbose
    } else {
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);  Write-Host "[$timer] - SMTP [$secondarySMTP] is NOT unique. Generating unique secondary SMTP!" -ForeGroundColor Yellow
      Create-UniqueSMTP -SMTP $secondarySMTP
      $secondarySMTP = $global:secondarySMTP
    }
  #TODO: Add reporting of success/failure/error

  # Set the new secondary SMTP on the AD object
     try {
      $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Verbose "[$timer] - Secondary SMTP [$secondarySMTP] added on [$NewSAMAccountName] " -Verbose
      Set-ADUser $NewSAMAccountName -Add @{ ProxyAddresses = ($secondarySMTP)} -Server $DC -Credential $AD_Credential # this is done in AD
     }
     catch {
           $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);  Write-Host "[$timer] Failed to add secondary SMTP [$secondarySMTP] added on [$NewSAMAccountName]" -ForegroundColor Red
     }
     #TODO: Report success / failure / error

     # (For non-UK users only)
    # For non-UK users set the primary SMTP to their relevant COUNTRY DOMAIN (eg. westcoast.ie)
      if ($UserDomain -ne $Systemdomain){
      $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Verbose "[$timer] - Non-UK user detected. Modifying SMTP addresses." -Verbose
          #Create old (ToRemove) SMTP and new (ToAdd) SMTP
      $NewPrimarySMTP = "SMTP:" + $NewSAMAccountName + "@" + $UserDomain
      $OldPrimarySMTP = "SMTP:" + $NewSAMAccountName + "@" + $SystemDomain
      $NewSEcondarySMTP = $OldPrimarySMTP -replace "SMTP:","smtp:"
        #Update primary SMTP if needed
        Set-ADUser $NewSAMAccountName -remove @{ProxyAddresses=$OldPrimarySMTP} -Server $DC -Credential $AD_Credential
        Set-ADUser $NewSAMAccountName -add @{ProxyAddresses=$NewPrimarySMTP} -Server $DC -Credential $AD_Credential
        Set-ADUser $NewSAMAccountName -add @{ProxyAddresses=$NewSEcondarySMTP} -Server $DC -Credential $AD_Credential
        # Update mail address if needed
        Set-ADUser -Identity $NewSAMAccountName -Replace @{mail=($NewSAMAccountName + "@" + $UserDomain)} -Server $DC -Credential $AD_Credential
    }
     #TODO: Report success / failure / error
    #endregion

    #region Create the NEW MAILBOX

    # If the template user was Office365 user
      if ((Get-ADUser -Identity $TemplateUser -Properties targetAddress -Server $DC -Credential $AD_Credential).TargetAddress -match "onmicrosoft.com" ) {
      Create-OnlineMailbox -NewRemoteRoutingAddress $NewRemoteRoutingAddress -NewSAMAccountName $NewSAMAccountName -NewUserPrincipalName $NewUserPrincipalName -Exchange_Credential $Exchange_Credential
        $Flag = "online"
      } else {
    # If the template was on-prem user
      Create-OnPremMailbox -EOTargetDomain $EOTargetDomain -NewSAMAccountName $NewSAMAccountName -NewUserPrincipalName $NewUserPrincipalName -Exchange_Credential $Exchange_Credential
      $Flag = "onprem"
     }
     #TODO: Report outcome of the mailbox creation / failure / error
    #endregion

  # AD & AAD Syncronisation
    #region SYNC
    Get-ADSync -DC $DC -AD_Credential $AD_Credential
    Start-Sleep 30 # allow AD sync to finish
    Get-AADSync -AD_Credential $AD_Credential
    #endregion

  # MICROSOFT ONLINE SERVICES

      #region CONNECT to MSOnline
      Connect-MSOnline -AAD_Credential $AAD_Credential
      #endregion

      #region Gather LICENSE LIST from the template user
      $licenseassigned = $null = $licenseunasigned
        #Only do this, if the template has license
        if (Get-MsolUser -UserPrincipalName $TemplateUser.UserPrincipalName -ErrorAction SilentlyContinue){
          #Get licenses of the Template account (some are excluded, as they are assigned from AD groups)
          $LicenseSKUs = ((Get-MsolUser -UserPrincipalName $TemplateUser.UserPrincipalName -ErrorAction SilentlyContinue).Licenses).AccountSkuid #| Where-Object { ($_ -notlike "*ENTERPRISEPACK") -and ($_ -notlike "*ATP_ENTERPRISE") }
        }
      #endregion

      #region Wait for the new account to APPEAR IN MSONLINE (AAD)
          do {
          $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Waiting for [$NewUserPrincipalName] to syncronise to Microsoft Online ... (next check is in 30 seconds)" -ForegroundColor Yellow
          Get-MsolUser -UserPrincipalName $NewUserPrincipalName -ErrorAction SilentlyContinue
          Start-Sleep -Seconds 30
          }
          until(Get-MsolUser -UserPrincipalName $NewUserPrincipalName -ErrorAction SilentlyContinue)
          $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Verbose "[$timer] - Account [$NewUserPrincipalName] is present in Microsoft Online - continuing execution" -Verbose
      #endregion

  # DISTRIBUTED FILE SYSTEM

    #region DFS PARAMETERS
      if ($Westcoast.IsPresent) {
        $PeopleTargetPath = "\\$PeopleFileServer\PEOPLE$\$NewSAMAccountName"
        $ProfileTargetPath = "\\$ProfileFileServer\PROFILES$\$NewSAMAccountName"
        $PeopleDFS = "\\$SystemDomain\PEOPLE\$NewSAMAccountName"
        $ProfileDFS = "\\$SystemDomain\PROFILES\$NewSAMAccountName"
      }
      elseif ($XMA.Ispresent){

      }
    #endregion

    #region PROVISION DFS
    if ($Westcoast.IsPresent) {
    Create-NewDFS -NewSAMAccountName $NewSAMAccountName -PeopleDFS $PeopleDFS -PeopleTargetPath $PeopleTargetPath -ProfileDFS $ProfileDFS -ProfileTargetPath $ProfileTargetPath # -DFSHost $DFSHost -AD_Credential $AD_Credential
    }
    elseif ($XMA.Ispresent){
      #FIXME: What to do for XMA user shares?
    }
    #endregion

  # USER REPORTING

    #region LICENSING the new user
       # When the user account is present, assign licensed to it to match the template (minus the licenses that come from groups)
       # Location is always GB
        Set-MsolUser -UserPrincipalName $NewUserPrincipalName -UsageLocation $UsageLocation
        # Assign each licenses of the template account to the new user
        if ($LicenseSKUs){
          foreach ($LicenseSKU in $LicenseSKUs){
            Get-MSOLUserLicensed -LicenseSKU $LicenseSKU -NewSAMAccountName $NewSAMAccountName -NewUserPrincipalName $NewUserPrincipalName -DC $DC -AD_Credential $AD_Credential
          }
        }
      #endregion

    #region USER REPORT
      Write-Host # separator line
      Generate-UserADReport -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential -AAD_Credential $AAD_Credential
      Generate-UserExchangeReport -NewSAMAccountName $NewSAMAccountName -Flag $Flag -Exchange_Credential $Exchange_Credential -AAD_Credential $AAD_Credential
      #endregion

}

# SIG # Begin signature block
# MIIOWAYJKoZIhvcNAQcCoIIOSTCCDkUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAnuhPCUInI+O0aPRiaZ4OhkY
# EmegggueMIIEnjCCA4agAwIBAgITTwAAAAb2JFytK6ojaAABAAAABjANBgkqhkiG
# 9w0BAQsFADBiMQswCQYDVQQGEwJHQjEQMA4GA1UEBxMHUmVhZGluZzElMCMGA1UE
# ChMcV2VzdGNvYXN0IChIb2xkaW5ncykgTGltaXRlZDEaMBgGA1UEAxMRV2VzdGNv
# YXN0IFJvb3QgQ0EwHhcNMTgxMjA0MTIxNzAwWhcNMzgxMjA0MTE0NzA2WjBrMRIw
# EAYKCZImiZPyLGQBGRYCdWsxEjAQBgoJkiaJk/IsZAEZFgJjbzEZMBcGCgmSJomT
# 8ixkARkWCXdlc3Rjb2FzdDEmMCQGA1UEAxMdV2VzdGNvYXN0IEludHJhbmV0IElz
# c3VpbmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7nBk9j3wR
# GgkxrPuXjIXlptisoOhKZp7KCB+BhxaxlTGW5lxhEaNirirM4jaM04kXojFZxhHV
# lTl2W3TPOfeIEXxcZYigPgh9d6wgTTb2cSRq1872YjMytxSps14LAbY8CEu+fQmC
# AbL6V8EgtnAmzMBBqOOi6x7bMHoGkJPwDOSUM01LHPoT8cg9KVIFioJHpex/Xeko
# FiRwgW7uS+dh57iCGRWVCZaDrFIXWKj4dOHJigsEPkbmJUPSYILF8SYglFiJpM7b
# xl3RPuy2GvJRq5Ikyn0SvnpAG72Ge664PV5sFdtzdNkIE7RsE6zUEqK1v2pt7CcC
# qh4en3v54ouZAgMBAAGjggFCMIIBPjASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsG
# AQQBgjcVAgQWBBSBYkDZbTpVK0nuvapWivWUf0tBKDAdBgNVHQ4EFgQUU3PVQuhx
# ickSLEsfPyKpNozqrT8wGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0P
# BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYDVR0jBBgwFoAUuxfhV4noKzmJ
# eDD6ejIRp0cSBu8wPQYDVR0fBDYwNDAyoDCgLoYsaHR0cDovL3BraS53ZXN0Y29h
# c3QuY28udWsvcGtpL3Jvb3RjYSgxKS5jcmwwSAYIKwYBBQUHAQEEPDA6MDgGCCsG
# AQUFBzAChixodHRwOi8vcGtpLndlc3Rjb2FzdC5jby51ay9wa2kvcm9vdGNhKDEp
# LmNydDANBgkqhkiG9w0BAQsFAAOCAQEAaYMr/xfHuo3qezz8rtbzGkfUwqNFjd0s
# 7d02B07aO5q0i7LMtZTMxph9DbeJRvm+d8Sr4DSiWgtJdb0eYsx4xj5lDrsXDuO2
# 2Mb4hKjtqzDVW5PEJzC72BPOSfkgfW6PZmscMPtJnn0TPM24DzkYmjhnsA97Ltjv
# 1wuvUi2G0nPIbzfBZWnnuCx5PhSovssQU5E3ZlVLew6a8WME0lPOmR9c38TARqWh
# tvS/wqmUaCEUF6rmUDY0MgY/Wrg2TIbtlYFWe9PksI4jmTE4Ndy5BW8smx+8YOoF
# fCOldshHHgFJVG7Bat6vrT8AaUSs6crPBRMpbeouD0iujXts+LdV2TCCBvgwggXg
# oAMCAQICEzQAA+ZyHBAttK7qIqcAAQAD5nIwDQYJKoZIhvcNAQELBQAwazESMBAG
# CgmSJomT8ixkARkWAnVrMRIwEAYKCZImiZPyLGQBGRYCY28xGTAXBgoJkiaJk/Is
# ZAEZFgl3ZXN0Y29hc3QxJjAkBgNVBAMTHVdlc3Rjb2FzdCBJbnRyYW5ldCBJc3N1
# aW5nIENBMB4XDTIwMDUxODA4MTk1MloXDTI2MDUxODA4Mjk1MlowgacxEjAQBgoJ
# kiaJk/IsZAEZFgJ1azESMBAGCgmSJomT8ixkARkWAmNvMRkwFwYKCZImiZPyLGQB
# GRYJd2VzdGNvYXN0MRIwEAYDVQQLEwlXRVNUQ09BU1QxDTALBgNVBAsTBExJVkUx
# DjAMBgNVBAsTBVVTRVJTMQ8wDQYDVQQLEwZBZG1pbnMxHjAcBgNVBAMTFUZhYnJp
# Y2UgU2VtdGkgKEFETUlOKTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# APVwqF2TGtzPlxftCjtb23neDu2cWyovIpo1TgU0ptNYrJM8tAY6W8Yt5Vw+8xzU
# 45sxmbMzU2JpJaqEPFe3+gXWJtL99/ZusyXCDbubzYmNu06WE6XqMqG/KRfZ3BpN
# Gw5s3KlxWVj/H12i7JPbMvfyAl8lgz/YBO0XVdoozcAglEck7c8DBaRTb4J7vX/O
# IS7dYu+gmkZJCv2+O6vTNTlK7bIHAQPWzSPibzU9dRPlHiPOTcHoYB+YNpmbgNxn
# fdaFMB+xY1GcYoKwVRl6UEF/od8TKehzUp/hHFlXiH+miz692ptXhi3dOp6R4Stn
# Ku0IoBfBi/CQcgl5Uko6kckCAwEAAaOCA1YwggNSMD4GCSsGAQQBgjcVBwQxMC8G
# JysGAQQBgjcVCIb24huEi+UUg4mdM4f4p0GE8aVDgSaGkPwogZ23PAIBZAIBAjAT
# BgNVHSUEDDAKBggrBgEFBQcDAzALBgNVHQ8EBAMCB4AwGwYJKwYBBAGCNxUKBA4w
# DDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU7eheFlEriypJznAoYQVEx7IAmBkwHwYD
# VR0jBBgwFoAUU3PVQuhxickSLEsfPyKpNozqrT8wggEuBgNVHR8EggElMIIBITCC
# AR2gggEZoIIBFYY6aHR0cDovL3BraS53ZXN0Y29hc3QuY28udWsvcGtpLzAxX2lu
# dHJhbmV0aXNzdWluZ2NhKDEpLmNybIaB1mxkYXA6Ly8vQ049V2VzdGNvYXN0JTIw
# SW50cmFuZXQlMjBJc3N1aW5nJTIwQ0EoMSksQ049Qk5XQURDUzAxLENOPUNEUCxD
# Tj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1
# cmF0aW9uLERDPXdlc3Rjb2FzdCxEQz1jbyxEQz11az9jZXJ0aWZpY2F0ZVJldm9j
# YXRpb25MaXN0P2Jhc2U/b2JqZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQw
# ggEmBggrBgEFBQcBAQSCARgwggEUMEYGCCsGAQUFBzAChjpodHRwOi8vcGtpLndl
# c3Rjb2FzdC5jby51ay9wa2kvMDFfaW50cmFuZXRpc3N1aW5nY2EoMSkuY3J0MIHJ
# BggrBgEFBQcwAoaBvGxkYXA6Ly8vQ049V2VzdGNvYXN0JTIwSW50cmFuZXQlMjBJ
# c3N1aW5nJTIwQ0EsQ049QUlBLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENO
# PVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9d2VzdGNvYXN0LERDPWNvLERD
# PXVrP2NBQ2VydGlmaWNhdGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9u
# QXV0aG9yaXR5MDUGA1UdEQQuMCygKgYKKwYBBAGCNxQCA6AcDBp3Y2FkbWluLmZz
# QHdlc3Rjb2FzdC5jby51azANBgkqhkiG9w0BAQsFAAOCAQEAeM0HkiWDX+fmhIsv
# WxZb+D/tLDztccfYND16zFAoReu0VmTUz570CEMhLyHGh1jk3y/pb26UmjqHFeVh
# /EVu/EQNCuT5gQPKh64FQsBVinugNHWMhDySywykKwkdnqEpY++UNxQyyj6xpTM0
# tg+h8Wd1IlDN98SwLBy4x16SwgGTdwKvU9CyBuMRQjPlSJKjCL+14T0C8d2SBGW3
# 9uLCqjyMd288Q3QgrbDoHSg/x+vsnrDzOHMThM/2aMPbcO0wqafK9G5qdoIc0dqe
# So/vU6rsNLwQ1sniJQxerKZnWJjEfl8M5OcUxws5n7D3fqpHZ2VxLCIYp6yuPkHY
# R5daezGCAiQwggIgAgEBMIGCMGsxEjAQBgoJkiaJk/IsZAEZFgJ1azESMBAGCgmS
# JomT8ixkARkWAmNvMRkwFwYKCZImiZPyLGQBGRYJd2VzdGNvYXN0MSYwJAYDVQQD
# Ex1XZXN0Y29hc3QgSW50cmFuZXQgSXNzdWluZyBDQQITNAAD5nIcEC20ruoipwAB
# AAPmcjAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkq
# hkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGC
# NwIBFTAjBgkqhkiG9w0BCQQxFgQU3rtaJ2P66km6SmxcQLBsR6kSgZowDQYJKoZI
# hvcNAQEBBQAEggEALoXtWyXAqHMMXK+B++PPLBKtyRNsalVYP0D9m8x1PXrmTt7L
# +aVXMVddyncKQOUYGi8GMwhOEeyOQirp9YeGEX7HYyIO13aMF1PloDZTVHdkw5tZ
# Xrpdru9vJNSX8RVZ7Wh6ADZK8Uj8TEGHPhOP50I7N7R5LbdJDJZepfQTey1gIwL0
# BhHe+kjOPUX0x5ntS2iOJZa85pCDSsShfuLM0oAv/hiv2oh+qRZBHsDh3ybjKnb/
# Js3TTOgtqUYt9VSwAto/1vgE1fKwUQ3e39KLA79YECGTnQkPBYgXWUXBuKxam77y
# 2f8DajdgtlWH9rw42JTQhC+CxInDI7uMKi3iFw==
# SIG # End signature block
