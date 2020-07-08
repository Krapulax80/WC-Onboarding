function global:Process-StarterMailbox {

    # USER parameters
    $secondarySMTP = "smtp:" + $FirstName + $LastName.substring(0,1) + "@" + $global:UserDomain
    $NewSAMAccountName = $global:NewSAMAccountName
    $NewUserPrincipalName = $global:NewUserPrincipalName
    $UserDomain = $global:UserDomain
    $TemplateUser = $global:TemplateUser

    # Check if the secondary SMTP exists. If it does, create a unique one
    if (!(Get-ADObject -Properties proxyAddresses -Filter { proxyAddresses -EQ $secondarySMTP } -Server $DC -Credential $AD_Credential -ErrorAction SilentlyContinue)) {
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);	Write-Host "[$timer] - SMTP [$secondarySMTP] is unique." -ForegroundColor Green
    } else {
      $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);	Write-Host "[$timer] - SMTP [$secondarySMTP] is NOT unique. Generating unique secondary SMTP!" -ForeGroundColor Red
      Create-UniqueSMTP -SMTP $secondarySMTP
      $secondarySMTP = $global:secondarySMTP
    }
      #TODO: Add reporting of success/failure/error    

    # ...declare the connector address for o365 ...
    $NewRemoteRoutingAddress = $FirstName + "." + $LastName + "@" + $EOTargetDomain

    # Set up the new user with the secondary SMTP
     try {
      $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Verbose "[$timer] - Secondary SMTP [$secondarySMTP] added on [$NewSAMAccountName] " -Verbose
	    Set-ADUser $NewSAMAccountName -Add @{ ProxyAddresses = ($secondarySMTP)} -Server $DC -Credential $AD_Credential # this is done in AD
     }
     catch {
           $timer = (Get-Date -Format yyyy-MM-dd-HH:mm:ss);	Write-Host "[$timer] Failed to add secondary SMTP [$secondarySMTP] added on [$NewSAMAccountName]" -ForegroundColor Red
     }
     #TODO: Report success / failure / error

    # For non-UK users set the primary SMTP to their relevant country domain
    	if ($UserDomain -ne $Systemdomain){
		$timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Verbose "[$timer] - Non-UK user detected. Modifying SMTP addresses." -Verbose
				#Create old (wrong) SMTP and new (correct) SMTP
		$NewPrimarySMTP = "SMTP:" + $NewSAMAccountName + "@" + $UserDomain
		$OldPrimarySMTP = "SMTP:" + $NewSAMAccountName + "@" + $SystemDomain
		$NewSEcondarySMTP = $OldPrimarySMTP -replace "SMTP:","smtp:"

		#Update primary SMTP if needed
		#If ( (Get-ADUser $NewSAMAccountName  -Properties ProxyAddresses).ProxyAddresses -cmatch $OldPrimarySMTP){
		Set-ADUser $NewSAMAccountName -remove @{ProxyAddresses=$OldPrimarySMTP} -Server $DC -Credential $AD_Credential
		Set-ADUser $NewSAMAccountName -add @{ProxyAddresses=$NewPrimarySMTP} -Server $DC -Credential $AD_Credential
		Set-ADUser $NewSAMAccountName -add @{ProxyAddresses=$NewSEcondarySMTP} -Server $DC -Credential $AD_Credential
		#}
		# Update mail address if needed
		Set-ADUser -Identity $NewSAMAccountName -Replace @{mail=($NewSAMAccountName + "@" + $UserDomain)} -Server $DC -Credential $AD_Credential
	}
     #TODO: Report success / failure / error

     # CREATE THE MAILBOX
     # If the template user was Office365 user
     if ((Get-ADUser -Identity $TemplateUser -Properties targetAddress -Server $DC -Credential $AD_Credential).TargetAddress -match "onmicrosoft.com" ) {
        Get-PSSession | Remove-PSSession
        Connect-OnPremExchange
        [void](Enable-RemoteMailbox -Identity $NewSAMAccountName -RemoteRoutingAddress $NewRemoteRoutingAddress)
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Verbose"[$timer] - Online mailbox created for [$NewUserPrincipalName]. Ensure the user is licensed in order for the user to access it." -Verbose
     } else { 
    # If the template was on-prem user
        Get-PSSession | Remove-PSSession
        Connect-OnPremExchange
        [void](Enable-Mailbox -Identity $NewSAMAccountName ) # create the mailbox
        [void](Enable-Mailbox -Identity $NewSAMAccountName -RemoteArchive -ArchiveDomain $EOTargetDomain) # places the archive in the cloud
        #Feedback
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Verbose "[$timer] - On-prem mailbox created for [$NewUserPrincipalName]. Archive is in the cloud." -Verbose
     }

}
# SIG # Begin signature block
# MIIOWAYJKoZIhvcNAQcCoIIOSTCCDkUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5uT0QjOvs9gPGz54sZMJubVg
# 4kCgggueMIIEnjCCA4agAwIBAgITTwAAAAb2JFytK6ojaAABAAAABjANBgkqhkiG
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
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUfFTejYvMtdM2ZByLhkAeKFr3Y+EwDQYJKoZI
# hvcNAQEBBQAEggEAtHAe13NFAR+cPfS2dOl8oyAHG7WkZOha2cKqh6eiKByb+9TW
# xocUdG/A3MKCyBkS0/3sHBvIamT7vFIlgPWWubH31Y0nZjIMm3VitKCBYH9lhG1D
# hTETlua5HN0XTxOeUJcjs4h/dAPApwCW0+uhCYYn7L1MzLNBhDnIxshu1xM1H9Fm
# Dw8S3/5arIGcJ3/Bsknm4d/xamvA8tfuTvLgEvsj0eve4uiD9IKwAl0/MsSbhLul
# Y+unNmfbckAYZ68wvBOmhtk5kIgNWoh1fxQbHSPrae0MSHY6kZoeIIl997eNgenF
# 0VuoAyBREhb3i9fmyjvCJ8lg+k8C7wsjxG5t2Q==
# SIG # End signature block
