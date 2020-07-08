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

  # WORK IN WESTCOAST DOMAIN
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
  }

  # (INVALID WORK DOMAIN DEFINED)
  else {
    Write-Host -ForeGroundColor Red "Bad domain."; Break
  }

  # ACTIVE DIRECTORY

    #region Construct the user parameters

    # Capitalise first and last name of the NEW user account
    $TextInfo = (Get-Culture).TextInfo
    $FirstName = $TextInfo.ToTitleCase($FirstName)
    $LastName = $TextInfo.ToTitleCase($LastName)

    # Collect details of the TEMPLATE  user account
    if (Get-ADUser -Filter {SAMAccountName -eq $TemplateName } -Properties * -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue) {
    $TemplateUser = Get-ADUser $TemplateName -Properties * -Server $DC -Credential $AD_Credential
    } else { Write-Host -ForegroundColor Red "User $TemplateName not found." }

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
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);	Write-Host "[$timer] - SAM account [$NewSAMAccountName] is unique." -ForegroundColor Green
    } else {
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);	Write-Host "[$timer] - SAM account [$NewSAMAccountName] is NOT unique. Generating unique SAM Name!" -ForeGroundColor Red
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
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);	Write-Host "[$timer] - UPN  [$NewUserPrincipalName] is unique." -ForegroundColor Green
   } else {
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);	Write-Host "[$timer] - UPN  [$NewUserPrincipalName] is NOT unique. Generating unique UPN!" -ForeGroundColor Red
      Create-UniqueUPN -NewUserPrincipalName $NewUserPrincipalName
      $NewUserPrincipalName = $global:NewUserPrincipalName
    }
    #TODO: Report the UPN

    # Check if Employee ID already exists. If it does, create a unique one
    if (($EmployeeID.gettype()).Name -notlike "String"){
        $EmployeeID = [string]$EmployeeID # convert the $EmployeeID into string
    }    
    if(!(Get-ADUser -Filter {EmployeeID -eq $EmployeeID} -Properties * -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue )){
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);	Write-Host "[$timer] - EmployeeID  [$EmployeeID] is unique." -ForegroundColor Green
    } else {
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);	Write-Host "[$timer] - EmployeeID [$EmployeeID] is NOT unique. Generating unique EmployeeID!" -ForeGroundColor Red
      Create-UniqueEmployeeID -EmployeeID $EmployeeID
      $EmployeeID = $global:EmployeeID
    }
    #TODO: Report the EmployeeID

    #endregion

    #region Create and configure the NEW USER Account
    
    # Define the NEW AD OBJECT
      $params = @{
      'SamAccountName'         = $NewSAMAccountName;
      'Instance'               = $TemplateUser.DistinguishedName;
      'DisplayName'            = $NewDisplayName;
      'GivenName'              = $FirstName;
      'Path'                   = $StarterOU;
      'SurName'                = $LastName;
      #'PasswordNeverExpires' = $password_never_expires;
      #'CannotChangePassword' = $cannot_change_password;
      'Description'            = "NEW STARTER - Created by " + ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) + " at " + (Get-Date -Format G); # description entry to help identify, who set the account up
      'Enabled'                = $true;
      'UserPrincipalName'      = $NewUserPrincipalName;
      'AccountPassword'        = (ConvertTo-SecureString -AsPlainText $NewPassword -Force);
      'ChangePasswordAtLogon'  = $true;
      'Title'                  = $TemplateUser.title; # Job title. This is taken from the $TemplateUser
      'Department'             = $TemplateUser.Department; # Department. This is taken from the $TemplateUser
      'Company'                = $TemplateUser.Company; # Company. This is taken from the $TemplateUser
      'Office'                 = $TemplateUser.Office; # Office. This is taken from the $TemplateUser
      }

      # Create the NEW USER ACCOUNT
      New-ADUser -Name $NewDisplayName @params -Server $DC -Credential $AD_Credential -Erroraction Stop -Verbose #-Whatif
      #TODO: Add reporting of success/failure/error

      # Wait for the NEW USER appear in AD
      do {
        $Userfound = (Get-ADUser -Filter {SAMAccountName -eq $NewSAMAccountName } -Properties * -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue )
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Verbose "[$timer] - Configuring account [$NewSAMAccountName] - please wait." -Verbose
        Start-Sleep -Seconds 15
      } until ($Userfound)

      # Check, if the template had a MANAGER. If yes, assign the new account to this manager
      if ($TemplateUser.Manager)
      { $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Verbose "[$timer] Setting [$NewSAMAccountName] to manager [$($TemplateUser.Manager)]" -Verbose
         Set-ADUser -Identity $NewSAMAccountName -Manager $TemplateUser.Manager -Server $DC -Credential $AD_Credential -Verbose
      }
      #TODO: Add outcome to manager added
      
      # Unless specifically said otherwise, assign JBA ACCESS to the account
      if ($NoJBA.IsPresent) {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Host "[$timer] Deny JBA access for [$NewSAMAccountName]" -ForegroundColor Red
        Set-ADUser -Identity $NewSAMAccountName -Add @{ extensionAttribute10 = 0} -Server $DC -Credential $AD_Credential -Verbose
      } else {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Verbose "[$timer] Adding JBA access to [$NewSAMAccountName]" -Verbose
        Set-ADUser -Identity $NewSAMAccountName -Add @{ extensionAttribute10 = 1} -Server $DC -Credential $AD_Credential -Verbose
      }
      #TODO: Add outcome to JBA access level

      # Assign EMPLOYEE ID to the new user account
      try {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Verbose "[$timer] Setting EmployeeID [$EmployeeID] on [$NewSAMAccountName]" -Verbose
        Set-ADUser -Identity $NewSAMAccountName -EmployeeID $EmployeeID -Server $DC -Credential $AD_Credential -Verbose
      }
       catch {
         $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Host "[$timer] Failed to set EmployeeID on [$NewSAMAccountName]" -ForegroundColor Red
      }
      #TODO: Add outcome of setting the EmployeeID

      # Assign HOLIDAY ENTITLEMENT to the new account
      if ($HolidayEntitlement){
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Verbose "[$timer] Setting Holiday Entitlement  [$HolidayEntitlement days] on [$NewSAMAccountName]" -Verbose
          		if ($HolidayEntitlement -gt 0){
              Set-ADUser -Identity $NewSAMAccountName -Add @{ extensionAttribute15 = $HolidayEntitlement } -Server $DC -Credential $AD_Credential -Verbose
              }
      } else {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Host "[$timer] Holiday Entitlement is undefined for [$NewSAMAccountName]" -ForegroundColor Red
      }
      #TODO: Add outcome of the holiday entitlement

      # Set the START DATE of the account. (This is purely administrative, account can be used ASAP!)
      if ($EmployeeStartDate){
        if ($EmployeeStartDate -match '^(19|20)\d\d[- /.](0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])$') {
          $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Verbose "[$timer] Setting Start Date  [$EmployeeStartDate] on [$NewSAMAccountName]" -Verbose
          Set-ADUser -Identity $NewSAMAccountName -Add @{ extensionAttribute13 = $EmployeeStartDate } -Server $DC -Credential $AD_Credential
        } else {
          $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Host "[$timer] Start date is incorrect - [$EmployeeStartDate]. Please ensujre it is yyyy/mm/dd and between 1900/01/01 and 2099/12/31!" -ForegroundColor Red
        }
      } else {
          $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Host "[$timer] Start date is not defined." -ForegroundColor Yellow
      }
      #TODO: Add outcome of the addition of the start data

      # Select the releavant CONTRACT TYPE of the new AD user
      if ($ContractType){
        if ($ContractType -match "FullTime"){
          $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Verbose "[$timer] Setting user contract to  [$ContractType] on [$NewSAMAccountName]" -Verbose
          Set-ADUser -Identity $NewSAMAccountName -Add @{ extensionAttribute11 = 0 } -Server $DC -Credential $AD_Credential -Verbose
        } elseif ($ContractType -match "PartTime") {
          $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Verbose "[$timer] Setting user contract to  [$ContractType] on [$NewSAMAccountName]" -Verbose
          Set-ADUser -Identity $NewSAMAccountName -Add @{ extensionAttribute11 = 1 } -Server $DC -Credential $AD_Credential -Verbose
        } elseif ($ContractType -match "Temp") {
          $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Verbose "[$timer] Setting user contract to  [$ContractType] on [$NewSAMAccountName]" -Verbose
          Set-ADUser -Identity $NewSAMAccountName -Add @{ extensionAttribute11 = 2 } -Server $DC -Credential $AD_Credential -Verbose          
        } elseif ($ContractType -match "External") {
          $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Verbose "[$timer] Setting user contract to  [$ContractType] on [$NewSAMAccountName]" -Verbose
          Set-ADUser -Identity $NewSAMAccountName -Add @{ extensionAttribute11 = 3 } -Server $DC -Credential $AD_Credential -Verbose
        } else {
          $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Host "[$timer] Contract type incorrect on [$NewSAMAccountName]!" -ForegroundColor Red
        }
      } else {
          $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Host "[$timer] Contract type undefined on [$NewSAMAccountName]!" -ForegroundColor Red
      }
      #TODO: Add outcome of the contract type setting

      #FIXME: Add expiry / end date 

      # Mirror ALL GROUP MEMBERSHIP of the template account to the new user
      try {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Verbose "[$timer] Adding [$NewSAMAccountName] to the groups of [$($TemplateUser.SAMAccountName)] " -Verbose
        $TemplateUser.Memberof | ForEach-Object { Add-ADGroupMember $_ $NewSAMAccountName -Server $DC -Credential $AD_Credential}
      }
      catch {
          $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Host "[$timer] Failed to adding [$NewSAMAccountName] to the groups of [$($TemplateUser.SAMAccountName)] " -ForegroundColor Red
      }
      #TODO: Add outcome of the group addition

      # MOVE the new user account to the same OU as the template account
      try {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Verbose "[$timer] Moving [$NewSAMAccountName] to the OU [$TemplateAccountOU]" -Verbose
        Get-ADUser $NewSAMAccountName -Server $DC -Credential $AD_Credential | Move-ADObject -TargetPath $TemplateAccountOU -Server $DC -Credential $AD_Credential
      }
      catch {
          $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Host "[$timer] Failed to move [$NewSAMAccountName] to the OU [$TemplateAccountOU]" -ForegroundColor Red
      }
      #TODO: Add outcome of the OU move

      # Gather user report
      $FreshAccount = Get-ADUser $NewSAMAccountName -Properties * -Server $DC -Credential $AD_Credential
      Write-Host # separator line
      If ($FreshAccount.extensionAttribute10 -eq 1) {$JBA = "YES"} elseif ($FreshAccount.extensionAttribute10 -eq 0) { $JBA = "NO"} else {$JBA = "N/A"}
      If ($FreshAccount.extensionAttribute11 -eq 0) {$Contract = "Full Time"} elseif ($FreshAccount.extensionAttribute11 -eq 1) { $Contract = "Part Time"} elseif ($FreshAccount.extensionAttribute11 -eq 2) {$Contract = "Temp"} elseif ($FreshAccount.extensionAttribute11 -eq 3) {$Contract = "External"} else {$Contract = "N/A"}
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Host "[$timer] (SUMMARY) Created user [$($FreshAccount.DisplayName)]:" -ForegroundColor Magenta
      Write-Host "SAMAccountName      : $($FreshAccount.SAMAccountName)"
      Write-Host "UserPrincipalName   : $($FreshAccount.UserPrincipalName)"
      Write-Host "First Name          : $($FreshAccount.GivenName)"
      Write-Host "Last Name           : $($FreshAccount.SurName)"
      Write-Host "Template used       : $($TemplateUser.DisplayName)"
      Write-Host "EmployeeID          : $($FreshAccount.EmployeeID)"
      Write-Host "Title               : $($FreshAccount.Title)"
      Write-Host "Department          : $($FreshAccount.Department)"
      Write-Host "Company             : $($FreshAccount.Company)"
      Write-Host "Office              : $($FreshAccount.Office)"
      Write-Host "Manager             : $($FreshAccount.Manager)"
      Write-Host "Holiday entitlement : $($FreshAccount.extensionAttribute15)"
      Write-Host "Start Date          : $($FreshAccount.extensionAttribute13)"
      Write-Host "Contract type       : $Contract"
      Write-Host "JBA Access          : $JBA"
      Write-Host "User domain         : $UserDomain"

      $FreshAccount = $null
    #endregion

  # EXCHANGE
  #Process-StarterMailbox

}

# SIG # Begin signature block
# MIIOWAYJKoZIhvcNAQcCoIIOSTCCDkUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU20YzkRDYUroUN7u9kcsR4Ro5
# CVygggueMIIEnjCCA4agAwIBAgITTwAAAAb2JFytK6ojaAABAAAABjANBgkqhkiG
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
# NwIBFTAjBgkqhkiG9w0BCQQxFgQU0xOdA5HH1/jDWPswDJ2Ebj6oEVEwDQYJKoZI
# hvcNAQEBBQAEggEAunzjqVXrYsjJR4pdY1MEemMZyU47OBUQvQDNfWYRVCxATpNr
# dgpJ5BzpgB/J9guZiF7fBz+cpMNHW5r3hcwe63R4djoNq02+b7J2ZuDlFPtmMZ3N
# AJGbri1hq1PpwbsusWHmWfMVM7J78RR9kDVlnDmlo9vR22Pgi3iZF2jA+ejNmzxM
# DluQDxi0IKZ57TIRSqiw0QCNoZdTp8e19L1RhN7yQW1P26QCg/Ie9KDNMB74kP03
# G4dQN4wcu04DnSS881lg3hRzrVggFNGqowmTiz94mJghxBGqxntMNBHSaA6/yyO3
# gDC9JRMy9ivpIA3XgpINybUCwjAvS/a+cgWG3w==
# SIG # End signature block
