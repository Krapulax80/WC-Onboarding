function Process-OnBoarding01 {
  [CmdletBinding()]
  param(
    
    [Parameter(Mandatory = $true , ParameterSetName = 'WestCoast')] [switch]$Westcoast,
    [Parameter(Mandatory = $true , ParameterSetName = 'XMA')] [switch]$XMA,
    [Parameter(Mandatory = $true)] [string]$FirstName,
    [Parameter(Mandatory = $true)] [string]$LastName,
    [Parameter(Mandatory = $true)] [string]$EmployeeID,
    [Parameter(Mandatory = $true)] [string]$TemplateName,
    [Parameter(Mandatory = $true)] [string]$OutputFolder,
    [Parameter(Mandatory = $true)] [string]$Today,
    [Parameter(Mandatory = $true)] [string]$Manager,
    [Parameter(Mandatory = $true)] [object]$config,
    [Parameter(Mandatory = $true)] [object]$recipients,
    [Parameter(Mandatory = $true)] [object]$HRrecipients,
    [Parameter(Mandatory = $false)] [switch]$NoJBA,
    [Parameter(Mandatory = $false)] [switch]$WithMailboxMigration,
    [Parameter(Mandatory = $false)] [string] $MigrationCSV

  )

  <#
      # Internal use only: this is only for updating the passwords used for the script
      Create-Credential -WestCoast -AD -CredFolder "\\$($config.InfraServer)\c$\Scripts\AD\ONBoarding\Credentials\" -PasswordUpdate
      Create-Credential -WestCoast -AAD -CredFolder "\\$($config.InfraServer)\c$\Scripts\AD\ONBoarding\Credentials\" -PasswordUpdate
      Create-Credential -WestCoast -Exchange -CredFolder "\\$($config.InfraServer)\c$\Scripts\AD\ONBoarding\Credentials\" -PasswordUpdate

      Create-Credential -XMA -AD -CredFolder "\\$($config.InfraServer)\c$\Scripts\AD\ONBoarding\Credentials\" -PasswordUpdate
      Create-Credential -XMA -AAD -CredFolder "\\$($config.InfraServer)\c$\Scripts\AD\ONBoarding\Credentials\" -PasswordUpdate
      Create-Credential -XMA -Exchange -CredFolder "\\$($config.InfraServer)\c$\Scripts\AD\ONBoarding\Credentials\" -PasswordUpdate
      #>


  BEGIN {

    # configuration
    $SystemDomain = $config.SystemDomain
    $DomainNetBIOS = $config.DomainNetBIOS
    $AADSyncServer = $config.AADSyncServer ; $AADSyncServer = $AADSyncServer + '.' + $SystemDomain
    $ExchangeServer = $config.ExchangeServer ; $ExchangeServer = $ExchangeServer + '.' + $SystemDomain
    $HybridServer = $config.HybridServer ; $HybridServer = $HybridServer + '.' + $SystemDomain
    $OnpremisesMRSProxyURL = $config.OnpremisesMRSProxyURL + '.' + $SystemDomain
    $EOTargetDomain = $config.EOTargetDomain
    $PeopleFileServer = $config.PeopleFileServer ; $PeopleFileServer = $PeopleFileServer + '.' + $SystemDomain
    $ProfileFileServer = $config.ProfileFileServer ; $ProfileFileServer = $ProfileFileServer + '.' + $SystemDomain
    $RDSDiskFileServer = $config.RDSDiskFileServer ; $RDSDiskFileServer = $RDSDiskFileServer + '.' + $SystemDomain
    $StarterOU = $config.StarterOU
    $DFSHost = $config.DFSHost ; $DFSHost = $DFSHost + '.' + $SystemDomain
    $SmtpServer = $config.SMTPServer

    $ReportSender = 'newstarter' + '@' + $SystemDomain

    # attachments
    $ComputerUsagePolicy = $config.ComputerUsagePolicy
    if ($config.MFAGuide) {
      $MFAGuide = $config.MFAGuide
    }

    # credential and DC selection
    if ($Westcoast.IsPresent) {
      # Credentials for WC
      Create-Credential -WestCoast -AD -CredFolder "\\$($config.InfraServer)\c$\Scripts\AD\ONBoarding\Credentials\" -AD_Admin $($config.AD_Admin) -AAD_Admin $($config.AAD_Admin) -Exchange_Admin $($config.Exchange_Admin)
      Create-Credential -WestCoast -AAD -CredFolder "\\$($config.InfraServer)\c$\Scripts\AD\ONBoarding\Credentials\" -AD_Admin $($config.AD_Admin) -AAD_Admin $($config.AAD_Admin) -Exchange_Admin $($config.Exchange_Admin)
      Create-Credential -WestCoast -Exchange -CredFolder "\\$($config.InfraServer)\c$\Scripts\AD\ONBoarding\Credentials\" -AD_Admin $($config.AD_Admin) -AAD_Admin $($config.AAD_Admin) -Exchange_Admin $($config.Exchange_Admin)
      # Domain Controller for WC (I prefer to use the PDC emulator for simplicity)
      #$DC = (Get-ADForest -Identity $SystemDomain -Credential $AD_Credential |  Select-Object -ExpandProperty RootDomain |  Get-ADDomain |  Select-Object -Property PDCEmulator).PDCEmulator
      $DC = (Get-ADForest -Identity $SystemDomain -Credential $AD_Credential | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property InfrastructureMaster).InfrastructureMaster
    }
    elseif ($XMA.IsPresent) {
      # Credentials for XMA
      Create-Credential -XMA -AD -CredFolder "\\$($config.InfraServer)\c$\Scripts\AD\ONBoarding\Credentials\" -AD_Admin $($config.AD_Admin) -AAD_Admin $($config.AAD_Admin) -Exchange_Admin $($config.Exchange_Admin)
      Create-Credential -XMA -AAD -CredFolder "\\$($config.InfraServer)\c$\Scripts\AD\ONBoarding\Credentials\" -AD_Admin $($config.AD_Admin) -AAD_Admin $($config.AAD_Admin) -Exchange_Admin $($config.Exchange_Admin)
      Create-Credential -XMA -Exchange -CredFolder "\\$($config.InfraServer)\c$\Scripts\AD\ONBoarding\Credentials\" -AD_Admin $($config.AD_Admin) -AAD_Admin $($config.AAD_Admin) -Exchange_Admin $($config.Exchange_Admin)
      # Domain Controller for XMA
      $DC = (Get-ADForest -Identity $SystemDomain -Credential $AD_Credential | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property PDCEmulator).PDCEmulator
    }
    else {
      Write-Host -ForegroundColor Red 'Bad domain.'; Break
    }

  }

  PROCESS {

    <# create account names - part 1:
    - convert first name and last name to lowercase
    - capitalise both name
    - replace apostrophes (store the original name too)
        - construct the display name
    #>
    $TextInfo = (Get-Culture).TextInfo
    $FirstName = $FirstName.ToLower()
    $LastName = $LastName.ToLower()
    $FirstName = $TextInfo.ToTitleCase($FirstName)
    $LastName = $TextInfo.ToTitleCase($LastName)
    $displayFirstName = $FirstName
    $displayLastName = $LastName
    $FirstName = $FirstName -replace "'",''
    $LasttName = $LasttName -replace "'",''
    $NewDisplayName = ($displayFirstName + ' ' + $displayLastName)

    # collect details of the template user account
    if (Get-ADUser -Filter { SAMAccountName -eq $TemplateName } -Properties * -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue) {
      $TemplateUser = Get-ADUser $TemplateName -Properties * -Server $DC -Credential $AD_Credential
    }
    else {
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - User $TemplateName not found." -ForegroundColor Red 
    }

    # target OU
    $TemplateAccountOU = ($TemplateUser | Select-Object @{ n = 'Path'; e = { $_.DistinguishedName -replace "CN=$($_.cn),", '' } }).path

    # END SCRIPT EARLY IF TEMPLATES IS A LEAVER

    # Leavers stored in thiese OU-s
    if ($Westcoast.IsPresent) {
      $LeaverOU = 'OU=Leavers Pending Export,OU=Active Employees,OU=USERS,OU=WC2014,DC=westcoast,DC=co,DC=uk'
    }
    elseif ($XMA.Ispresent) {
      $LeaverOU = 'OU=90 day notice user accounts,DC=xma,DC=co,DC=uk'
    }

    # Verify if template is in the $LeaverOU. If it is, that terminates the script, as leavers are without groups (and licenses) therefore not suitable for serving as a template.
    if ($TemplateAccountOU -match $LeaverOU) {

      # Stop creation, alert Service Desk
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - User $TemplateName is a leaver - skipping new user creation" -ForegroundColor Red 
      Send-LeaverTemplateAlert -recipients $recipients -TemplateUser $TemplateUser -NewDisplayName $NewDisplayName -SystemDomain $SystemDomain -SmtpServer $SmtpServer -ReportSender $ReportSender 

    }
    else {

      # target country code
      $UsageLocation = $TemplateUser.extensionAttribute6 
    
      # target user domain
      $UserDomain = ($TemplateUser.UserPrincipalName).Split('\@')[1]

      <# create account names - part 2
    - use the previously created FirstName and LastName and the target user domain to construct the UPN
    - use FirstName and LastName to consruct the SAM, with truncation
    - construct the remote routing address (used for Enable-RemoteMailbox command)
    - create primary SMTP (used to check, if the remote routing address unique)
    - create the short (FirstNameL) SMTP address
    #>
      $NewUserPrincipalName = $FirstName + '.' + $LastName + '@' + $UserDomain
      $NewSAMAccountName = $FirstName + '.' + $LastName
      if ($NewSAMAccountName.Length -gt 20) {
        # Truncate pre-2000 name to 20 characters, if longer, to prevent errors
        $NewSAMAccountName = $NewSAMAccountName.substring(0, 20)
      }
      $NewRemoteRoutingAddress = ($FirstName + '.' + $LastName) + '@' + $EOTargetDomain
      $routingSMTP = 'smtp:' + $NewRemoteRoutingAddress
      $secondarySMTP = 'smtp:' + $FirstName + $LastName.substring(0, 1) + '@' + $UserDomain

      # Create new password for the NEW user account
      #Add-Type -AssemblyName System.Web
      $NewPassword = Generate-Password

      #region UNIQUENESS CHECKS

      # ensure the new SAM account name is unique
      if (! (Get-ADUser -Filter { SAMAccountName -eq $NewSAMAccountName } -Properties * -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue) ) {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - SAM account [$NewSAMAccountName] is unique."
      }
      else {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - SAM account [$NewSAMAccountName] is NOT unique. Generating unique SAM Name!" -ForegroundColor Yellow
        $NewSAMAccountName = Create-UniqueSAMName -NewSAMAccountName $NewSAMAccountName
        $sendHREmail = 'YES'
      }

      # ensure the User Principal Name is unique
      if (!(Get-ADUser -Filter { UserPrincipalName -eq $NewUserPrincipalName } -Properties * -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue )) {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - UPN  [$NewUserPrincipalName] is unique."
      }
      else {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - UPN  [$NewUserPrincipalName] is NOT unique. Generating unique UPN!" -ForegroundColor Yellow
        $NewUserPrincipalName = Create-UniqueUPN -NewUserPrincipalName $NewUserPrincipalName
        $sendHREmail = 'YES'
      }

      # ensure EmployeeID is unique
      if (($EmployeeID.gettype()).Name -notlike 'String') {
        $EmployeeID = [string]$EmployeeID # convert the $EmployeeID into string
      }
      if (!(Get-ADUser -Filter { EmployeeID -eq $EmployeeID } -Properties * -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue )) {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - EmployeeID  [$EmployeeID] is unique."
      }
      else {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - EmployeeID [$EmployeeID] is NOT unique. Generating unique EmployeeID!" -ForegroundColor Yellow
        $EmployeeID = Create-UniqueEmployeeID -EmployeeID $EmployeeID
      }

      # ensure routing address is unique
      if (!(Get-ADObject -Properties proxyAddresses -Filter { proxyAddresses -EQ $routingSMTP } -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue)) {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - PRIMARY SMTP (routing address) [$routingSMTP / $NewRemoteRoutingAddress] is unique."
      }
      else {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - PRIMARY SMTP (routing address) [$routingSMTP / $NewRemoteRoutingAddress] is NOT unique. Generating unique value!" -ForegroundColor Yellow
        $NewRemoteRoutingAddress = Create-UniquePrimarySMTP -SMTP $NewRemoteRoutingAddress
      }  

      # ensure secondary smtp is unique
      if (!(Get-ADObject -Properties proxyAddresses -Filter { proxyAddresses -EQ $secondarySMTP } -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue)) {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - SMTP [$secondarySMTP] is unique."
      }
      else {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - SMTP [$secondarySMTP] is NOT unique. Generating unique secondary SMTP!" -ForegroundColor Yellow
        $secondarySMTP = Create-UniqueSecondarySMTP -SMTP $secondarySMTP
      }

      #endregion

      #region ACCOUNT CREATION

      # create new AD account
      Create-NewUserObject -TemplateUser $TemplateUser -NewSAMAccountName $NewSAMAccountName -NewDisplayName $NewDisplayName -FirstName $FirstName -StarterOU $StarterOU -LastName $LastName -NewUserPrincipalName $NewUserPrincipalName -DC $DC -AD_Credential $AD_Credential

      # set the manager parameter
      Add-Manager -Manager $Manager -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential

      # JBA access (given by default)
      Add-JBAAccess -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential

      # set EmployeeID
      Add-EmployeeID -EmployeeID $EmployeeID -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential

      # set holiday entitlement
      if ($HolidayEntitlement) {
        Add-HolidayEntitlement -HolidayEntitlement $HolidayEntitlement -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential
      }

      # set start date
      if ($EmployeeStartDate) {
        Add-StartDate -EmployeeStartDate $EmployeeStartDate -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential
      }

      # set end date (account expires on this day)
      if ($EmployeeEndDate) {
        Add-EndDate -EmployeeEndDate $EmployeeEndDate -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential
      }

      # set contract type
      if ($ContractType) {
        Add-ContractType -ContractType $ContractType -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential
      }

      # configure custom extension attributes
      Add-ExtensionAttributes -TemplateUser $TemplateUser -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential

      # set membership of the new user (based on the template)
      Add-ToTemplatesGroups -TemplateUser $TemplateUser -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential

      # move the AD object to the target OU (OU of the template)
      Move-ToTemplatesOU -TemplateAccountOU $TemplateAccountOU -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential

      #endregion

      # Sync accross the domain, and also to AAD
      Get-ADSync -DC $DC -AD_Credential $AD_Credential
      Start-Sleep 30 # allow AD sync to finish
      Get-AADSync -AD_Credential $AD_Credential

      #region MAILBOX CREATION

      # mailbox creation
      if ((Get-ADUser -Identity $TemplateUser -Properties targetAddress -Server $DC -Credential $AD_Credential).TargetAddress -match 'onmicrosoft.com' ) {
        if ($WithMailboxMigration.Ispresent) {
          Create-OnlineMailboxWithMigration -NewSAMAccountName $NewSAMAccountName -NewUserPrincipalName $NewUserPrincipalName -EOTargetDomain $EOTargetDomain -HybridServer $HybridServer -Exchange_Credential $Exchange_Credential -AAD_Credential $AAD_Credential -InfraServer $($config.InfraServer)
        }
        else {
          Create-OnlineMailbox -NewRemoteRoutingAddress $NewRemoteRoutingAddress -NewSAMAccountName $NewSAMAccountName -NewUserPrincipalName $NewUserPrincipalName -Exchange_Credential $Exchange_Credential
        }
        $Flag = 'online'
      }
      else {
        # If the template was on-prem user
        Create-OnPremMailbox -EOTargetDomain $EOTargetDomain -NewSAMAccountName $NewSAMAccountName -NewUserPrincipalName $NewUserPrincipalName -Exchange_Credential $Exchange_Credential
        $Flag = 'onprem'
      }

      # add secondary SMTP
      try {
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Secondary SMTP [$secondarySMTP] added on [$NewSAMAccountName] "
        Set-ADUser $NewSAMAccountName -Add @{ ProxyAddresses = ($secondarySMTP) } -Server $DC -Credential $AD_Credential # this is done in AD
      }
      catch {
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host "[$timer] - Failed to add secondary SMTP [$secondarySMTP] added on [$NewSAMAccountName]" -ForegroundColor Red
      }

      # change primary email for non-UK users
      if ($UserDomain -ne $Systemdomain) {
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Non-UK user detected. Modifying SMTP addresses."
        #Create old (ToRemove) SMTP and new (ToAdd) SMTP
        $NewPrimarySMTP = 'SMTP:' + $NewSAMAccountName + '@' + $UserDomain
        $OldPrimarySMTP = 'SMTP:' + $NewSAMAccountName + '@' + $SystemDomain
        $NewSecondarySMTP = $OldPrimarySMTP -replace 'SMTP:', 'smtp:'
        #Update primary SMTP if needed
        Set-ADUser $NewSAMAccountName -Remove @{ProxyAddresses = $OldPrimarySMTP } -Server $DC -Credential $AD_Credential
        Set-ADUser $NewSAMAccountName -Add @{ProxyAddresses = $NewPrimarySMTP } -Server $DC -Credential $AD_Credential
        Set-ADUser $NewSAMAccountName -Add @{ProxyAddresses = $NewSecondarySMTP } -Server $DC -Credential $AD_Credential
        # Update mail address if needed
        Set-ADUser -Identity $NewSAMAccountName -Replace @{mail = ($NewSAMAccountName + '@' + $UserDomain) } -Server $DC -Credential $AD_Credential
        Set-ADUser -Identity $NewSAMAccountName -EmailAddress ($NewSAMAccountName + '@' + $UserDomain) -Server $DC -Credential $AD_Credential

        Write-Host #lazy line break
        Write-Host '___________________________________________________'
        Write-Host #lazy line break
        Write-Host 'Final mailbox parameters:' -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        Get-ADUser $NewSAMAccountName -Properties * -Server $DC -Credential $AD_Credential | Select-Object Name, UserPrincipalName, mail, EmailAddress, proxyaddresses | Format-List
        Write-Host '___________________________________________________'
        Write-Host #lazy line break
      }

      # # match the remote mailbox's exchange GUID to the one on the online mailbox
      # if ($Flag -match 'online') {
      #   Sync-ExchangeGuid -NewUserPrincipalName $NewUserPrincipalName -AAD_Credential $AAD_Credential -Exchange_Credential $Exchange_Credential
      # }

      #endregion

      # Sync accross the domain, and also to AAD
      Get-ADSync -DC $DC -AD_Credential $AD_Credential
      Start-Sleep 30 # allow AD sync to finish
      Get-AADSync -AD_Credential $AD_Credential

      #region LICENSING
      # connect to Microsoft Online Services (chosen by the $systemDomain parameter)
      #Connect-MSOnline -AAD_Credential $AAD_Credential -SystemDomain $SystemDomain
      $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Verbose "[$timer] - Connecting to Microsoft Online Services [$SystemDomain]"    
      Connect-MsolService -Credential $AAD_Credential >> $null

      # assume first that there were no unsuccesfull license assignments (this should be deprecated)
      $null = $licenseunasigned

      # verify that the template account had licenses
      if (Get-MsolUser -UserPrincipalName $TemplateUser.UserPrincipalName -ErrorAction SilentlyContinue) {
        #Get licenses of the Template account (some are excluded, as they are assigned from AD groups)
        $LicenseSKUs = ((Get-MsolUser -UserPrincipalName $TemplateUser.UserPrincipalName -ErrorAction SilentlyContinue).Licenses).AccountSkuid #| Where-Object { ($_ -notlike "*ENTERPRISEPACK") -and ($_ -notlike "*ATP_ENTERPRISE") }
      }
    
      # wait for the new user account to apear in AAD
      do {
        $MSOLACCPresent = $null

        # (delay between each check. Increased for XMA to avoid spam, as XMA domain is slow to sync, WC should be much faster)
        if ($SystemDomain -match 'xma.co.uk') {
          $delay = 180
        }
        elseif ($SystemDomain -match 'westcoast.co.uk') {
          $delay = 120
        }
        else {
          $delay = 120
        }

        $MSOLACCPresent = Get-MsolUser -UserPrincipalName $NewUserPrincipalName -ErrorAction Ignore
        if (!($MSOLACCPresent)) {
          $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Waiting for [$NewUserPrincipalName] to syncronise to Microsoft Online ... (next check is in $delay seconds)" -ForegroundColor Yellow
          Start-Sleep -Seconds $delay
        }

      }
      until($MSOLACCPresent)
      Start-Sleep -Seconds $delay
      $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Account [$NewUserPrincipalName] is present in Microsoft Online - continuing execution"
    
      # set the new user to the GB usage location (tenants are in GB even for IE/FR users)
      [void] (Set-MsolUser -UserPrincipalName $NewUserPrincipalName -UsageLocation $UsageLocation -ErrorAction Continue)

      # if the template was licensed...
      # ...license with F1 if the template had F1 license
      if (($LicenseSKUs) -and ($LicenseSKUs -match 'DESKLESSPACK') ) {
        Add-ADGroupMember 'LICENSE-Office_365_F3_F1' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Color "[$timer] - Adding licenses [",'Office F1 (DESKLESPACK) and ATP', '] to user account [', "$NewUserPrincipalName",'] account ', 'succeeded' -Color White,Yellow,White,Yellow,White,Green
      }
      # ... or give E3 with any other template that was licenses
      elseif ($LicenseSKUs) {
        Add-ADGroupMember 'LICENSE-Office_365_E3' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Color "[$timer] - Adding license [",'Office E3 (ENTERPRISEPACK) and ATP', '] to user account [', "$NewUserPrincipalName",'] account ', 'succeeded' -Color White,Yellow,White,Yellow,White,Green        
      } 
      else {
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Color "[$timer] - NOT adding licenses to user account [", "$NewUserPrincipalName",'] account ', 'as template was not licensed. ' -Color White,Yellow,White,Red
      }

      # foreach ($LicenseSKU in $LicenseSKUs) {
      #   Get-MSOLUserLicensed -LicenseSKU $LicenseSKU -NewSAMAccountName $NewSAMAccountName -NewUserPrincipalName $NewUserPrincipalName -DC $DC -AD_Credential $AD_Credential
      # }

      # }

      #endregion

      # final sync for mailbox parameters
      Get-ADSync -DC $DC -AD_Credential $AD_Credential
      Start-Sleep 30 # allow AD sync to finish
      Get-AADSync -AD_Credential $AD_Credential

      #region DFS

      if ($Westcoast.IsPresent) {
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Starting File server - DFS configuration"

        # Configuration
        $PeopleTargetPath = "\\$PeopleFileServer\PEOPLE$\$NewSAMAccountName"
        $ProfileTargetPath = "\\$ProfileFileServer\PROFILES$\$NewSAMAccountName"
        $PeopleDFS = "\\$SystemDomain\PEOPLE\$NewSAMAccountName"
        $ProfileDFS = "\\$SystemDomain\PROFILES\$NewSAMAccountName"

        #Create share
        Create-NewDFS -NewSAMAccountName $NewSAMAccountName -PeopleDFS $PeopleDFS -PeopleTargetPath $PeopleTargetPath -ProfileDFS $ProfileDFS -ProfileTargetPath $ProfileTargetPath # -DFSHost $DFSHost -AD_Credential $AD_Credential

      }
      elseif ($XMA.Ispresent) {
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - XMA user - skipping DFS configuration"
        <#DFS is not currently implemented for XMA #>
      }

      #endregion

      #region REPORTING

      Write-Host

      #Exchange
      $UserExchangeReportConverted = Generate-UserExchangeReport -NewSAMAccountName $NewSAMAccountName -Flag $Flag -SystemDomain $SystemDomain -Exchange_Credential $Exchange_Credential -AAD_Credential $AAD_Credential -NewUserPrincipalName $NewUserPrincipalName
      $UserExchangeReportCSV = '.\' + $OutputFolder + '\' + $Today + '\' + ($NewSAMAccountName -replace '\.', '_') + '_Exchange_report.csv'
      $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Saving EXCHANGE report to [$UserExchangeReportCSV]"
      $UserExchangeReportConverted | ConvertFrom-Csv | Export-Csv $UserExchangeReportCSV -Force -NoTypeInformation

      #AD
      $UserADReportConverted = Generate-UserADReport -NewSAMAccountName $NewSAMAccountName -DC $DC -AD_Credential $AD_Credential -AAD_Credential $AAD_Credential -NewPassword $NewPassword
      $UserADReportCSV = '.\' + $OutputFolder + '\' + $Today + '\' + ($NewSAMAccountName -replace '\.', '_') + '_AD_report.csv'
      $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Saving AD report to [$UserADReportCSV]"
      $UserADReportConverted | ConvertFrom-Csv | Export-Csv $UserADReportCSV -Force -NoTypeInformation    

      #DFS
      if ($Westcoast.IsPresent) {
        $UserDFSReportConverted = Generate-DFSReport -PeopleDFS $PeopleDFS -ProfileDFS $ProfileDFS -NewSAMAccountName $NewSAMAccountName
        $UserDFSReportCSV = '.\' + $OutputFolder + '\' + $Today + '\' + ($NewSAMAccountName -replace '\.', '_') + '_DFS_report.csv'
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Saving DFS report to [$UserDFSReportCSV]"
        $UserDFSReportConverted | ConvertFrom-Csv | Export-Csv $UserDFSReportCSV -Force -NoTypeInformation
      }
      elseif ($XMA.Ispresent) {
        <#DFS is not currently implemented for XMA #>
      }

      # send details (inc. password)  to the line manager of the new starter
      $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Sending  password of [$NewSAMAccountName] to [$Manager]"
      Send-PasswordToManager -XMA -Manager $Manager -NewPassword $NewPassword -NewSAMAccountName $NewSAMAccountName -NewDisplayName $NewDisplayName -SystemDomain $SystemDomain -SmtpServer $SmtpServer -ReportSender $ReportSender -DC $DC -AD_Credential $AD_Credential -ComputerUsagePolicy $ComputerUsagePolicy -MFAGuide $MFAGuide

      if ($Westcoast.IsPresent) {
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Sending AD, Exchange and DFS reports on [$NewSAMAccountName] account"
        Send-SummaryToRecipients -recipients $recipients -NewDisplayName $NewDisplayName -SmtpServer $SmtpServer -ReportSender $ReportSender -ADReportCSV $UserADReportCSV -ExchangeReportCSV $UserExchangeReportCSV -DFSReportCSV $UserDFSReportCSV -ADReport $global:UserADReport #-DFSReport $global:UserDFSReport -ExchangeReport $global:UserExchangeReport

        # Email to HR if the naming has additional numbers in it
        # if ($sendHREmail = "YES") {
        #   $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Sending  user details of [$NewSAMAccountName] to HR"
        #   Send-NameDetailsToHR -WestCoast -Manager $Manager -NewPassword $NewPassword -NewSAMAccountName $NewSAMAccountName -NewDisplayName $NewDisplayName -SystemDomain $SystemDomain -SmtpServer $SmtpServer -ReportSender $ReportSender -DC $DC -AD_Credential $AD_Credential -ComputerUsagePolicy $ComputerUsagePolicy -MFAGuide $MFAGuide
        # }

      }
      elseif ($XMA.Ispresent) {
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Sending AD and Exchange reports on [$NewSAMAccountName] account"
        Send-SummaryToRecipients -recipients $recipients -NewDisplayName $NewDisplayName -SmtpServer $SmtpServer -ReportSender $ReportSender -ADReportCSV $UserADReportCSV -ExchangeReport $UserExchangeReportCSV -ADReport $global:UserADReport #-ExchangeReport $global:UserExchangeReport -DFSReport $UserDFSReportCSV -DFSReport $global:UserDFSReport  #TODO: Not valid for XMA currently

        # # Email to HR if the naming has additional numbers in it
        # if ($sendHREmail = "YES") {
        #   $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Host "[$timer] - Sending  user details of [$NewSAMAccountName] to HR"
        #   Send-NameDetailsToHR -XMA -Manager $Manager -NewPassword $NewPassword -NewSAMAccountName $NewSAMAccountName -NewDisplayName $NewDisplayName -SystemDomain $SystemDomain -SmtpServer $SmtpServer -ReportSender $ReportSender -DC $DC -AD_Credential $AD_Credential -ComputerUsagePolicy $ComputerUsagePolicy -MFAGuide $MFAGuide
        # }

      }

      #endregion
    }
  }

  END {

  }
}

# SIG # Begin signature block
# MIIOWAYJKoZIhvcNAQcCoIIOSTCCDkUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjfR2DjahIX1U7Zh6ASLBSPEt
# 1jSgggueMIIEnjCCA4agAwIBAgITTwAAAAb2JFytK6ojaAABAAAABjANBgkqhkiG
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
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUi7wKes5EXt8RHAtjjo0xNPDw8M8wDQYJKoZI
# hvcNAQEBBQAEggEA3pe+7WorFHF1nw/pc1xOqEn5Px6UCneijq5l6CWhUSPi3aus
# XfhrfWw0sTWp0J1lqAbvFz/5NKx5FKsmV6THyOxCfMKrt41s5tnfkT8Bhubc8yK8
# M22P4Z0QtX2CR+wct2NZZdhfu+JnsKrhveq8QTRyj8ImCoK6dTDopCgAzf+CjNpH
# hMF7JsSgLJXk0NMwAApO8jrqxvt5BrjTQamkwNkLNJEgzBK8U78IBC+pXpt4vBHI
# lUuEXutdr6FoR8XOyyrWyqIPGI95g2lFHGEHV3e6Sdg1d1G4SjDNA8AVnQQlWhxi
# Ix6O9/5H+8WLXs+eO30dH68KsrHJ6YBhxuKEHg==
# SIG # End signature block
