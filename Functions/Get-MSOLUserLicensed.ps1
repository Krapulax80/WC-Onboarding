function  Get-MSOLUserLicensed {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)] [string]
    $LicenseSKU,
    $NewSAMAccountName,
    $NewUserPrincipalName,
    $DC,
    [Parameter(Mandatory = $true)] [pscredential]
    $AD_Credential
  )

  try {
    # IF the template had F1 license, add the new user to the F1 group
    if ($LicenseSKU -match 'DESKLESSPACK') {
      Add-ADGroupMember 'LICENSE-Office_365_F3_F1' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
      $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Color "[$timer] - Adding licenses [",'Office F1 (DESKLESPACK) and ATP', '] to user account [', "$NewUserPrincipalName",'] account ', 'succeeded' -Color White,Yellow,White,Yellow,White,Green
    }
    # ELSE add the user to the E3 group
    else {
      Add-ADGroupMember 'LICENSE-Office_365_E3' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
      $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Color "[$timer] - Adding license [",'Office E3 (ENTERPRISEPACK) and ATP', '] to user account [', "$NewUserPrincipalName",'] account ', 'succeeded' -Color White,Yellow,White,Yellow,White,Green
    }
    # # First attempt using a group for licensing
    # # E3 phone
    # if ($LicenseSKU -match 'MCOEV' -and $LicenseSKU -match 'ENTERPRISEPACK') {
    #   Add-ADGroupMember 'LICENSE-Office_365_E3_w_PHONE' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
    # }  
    # # E3 phone conf
    # elseif ($LicenseSKU -match 'MCOMEETADV' -and $LicenseSKU -match 'ENTERPRISEPACK') {
    #   Add-ADGroupMember 'LICENSE-Office_365_E3_w_CONFERENCE' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
    # }      
    # # E5 phone conf
    # elseif ($LicenseSKU -match 'MCOMEETADV' -and $LicenseSKU -match 'ENTERPRISEPREMIUM_NOPSTNCONF') {
    #   Add-ADGroupMember 'LICENSE-Office_365_E5_w_CONFERENCE' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
    # }  
    # # E5 users
    # elseif ($LicenseSKU -match 'ENTERPRISEPREMIUM_NOPSTNCONF') {
    #   Add-ADGroupMember 'LICENSE-Office_365_E5' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
    # } 
    # # E3 users 
    # elseif ($LicenseSKU -match 'ENTERPRISEPACK') {
    #   Add-ADGroupMember 'LICENSE-Office_365_E3' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
    # }                
    # # F1 users
    # elseif ($LicenseSKU -match 'DESKLESSPACK') {
    #   Add-ADGroupMember 'LICENSE-Office_365_F3_F1' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
    # }
    # #  Exchagne Online users
    # elseif ($LicenseSKU -match 'EXCHANGESTANDARD') {
    #   Add-ADGroupMember 'LICENSE-Office_365_EXCH_ONLINE' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
    # }
    # # ATP addon
    # elseif ($LicenseSKU -match 'ATP_ENTERPRISE') {
    #   Add-ADGroupMember 'LICENSE-Office_365_ATP_addon' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
    # } 
    # # visio users
    # elseif ($LicenseSKU -match 'VISIOCLIENT') {
    #   Add-ADGroupMember 'LICENSE-APP_VisioOnline' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
    # } 
    # # project pro users
    # elseif ($LicenseSKU -match 'PROJECTPROFESSIONAL') {
    #   Add-ADGroupMember 'LICENSE-APP_ProjectOnline_PROF' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
    # }
    # # power BI users
    # elseif ($LicenseSKU -match 'POWER_BI_PRO') {
    #   Add-ADGroupMember 'LICENSE-APP_PowerBI_PRO' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
    # } 
    # # project premium users
    # elseif ($LicenseSKU -match 'PROJECTPREMIUM') {
    #   Add-ADGroupMember 'LICENSE-APP_ProjectOnline_PREM' -Members $NewSAMAccountName -Server $DC -Credential $AD_Credential
    # } 
    # # every other SKU 
    # else {
    #   # If the license has no group, add it directly
    #   Set-MsolUserLicense -UserPrincipalName $NewUserPrincipalName -AddLicenses $LicenseSKU #-ErrorAction Stop
    # }
    # $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Color "[$timer] - Adding license [","$LicenseSKU", '] to user account [', "$NewUserPrincipalName",'] account ', 'succeeded' -Color White,Yellow,White,Yellow,White,Green
    # $licenseassigned += ' [' + $LicenseSKU + '] '
  }
  catch {
    $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Color '[$timer] - Adding licenses to user account [', "$NewUserPrincipalName",'] account ', 'failed. ' -Color White,Yellow,White,Red;
    # $timer = (Get-Date -Format yyy-MM-dd-HH:mm); Write-Color "[$timer] - Adding license [","$LicenseSKU", '] to user account [', "$NewUserPrincipalName",'] account ', 'failed. ','(Do you have enough licenses...?)' -Color White,Yellow,White,Yellow,White,Red,White;
    # $licenseunasigned += ' [' + $LicenseSKU + '] '
    Continue
  }
}

# SIG # Begin signature block
# MIIOWAYJKoZIhvcNAQcCoIIOSTCCDkUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1sBvOSUDi4OUfvKTa0XD4Foy
# afOgggueMIIEnjCCA4agAwIBAgITTwAAAAb2JFytK6ojaAABAAAABjANBgkqhkiG
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
# NwIBFTAjBgkqhkiG9w0BCQQxFgQU+9R7bUv8ntEd1RQwUpruR39zVbgwDQYJKoZI
# hvcNAQEBBQAEggEAKKR087WAFOZbYR3z7b+WJ/RC4k0TCeuSfLRb0mLDaN/T0S83
# Z5C4/65/YQHM8YOTGPsVsrnWROhbX9yEWnhCPYAS2cJ9z+dvq10AEWjdfaLDZLe1
# Hsz3w5giDfqfoJt7fqjTKQzDfIv0QiIzBH78JaOw8pQuRYp4LUmrUYD0w8WFwJ/e
# YyVHTuG4byapChFjqRKnuqFrSelPoj8HkZTTc6uYu2in0saglU3bL1D0LwJZThvn
# LiffJ/Hb8CHLkuhQ7YKkHiL45DgzJNavosTRJIepa34uQ2l9P2AfJi6vQqcgZOOW
# 2kQaB6CsPKq82z0UXOJ92A8wMhvNnZoi+4qHOQ==
# SIG # End signature block
