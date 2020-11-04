function Generate-UserADReport {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)] [string]
    $NewSAMAccountName,
    [Parameter(Mandatory = $true)] [string]
    $DC,
    $NewPassword,
    [Parameter(Mandatory = $true)] [pscredential]
    $AD_Credential,
    [Parameter(Mandatory = $true)] [pscredential]
    $AAD_Credential
  )

  #region USER REPORT
  # Gather user report
  $FreshAccount = Get-ADUser $NewSAMAccountName -Properties * -Server $DC -Credential $AD_Credential
  Write-Host # separator line
  If ($FreshAccount.extensionAttribute10 -eq 1) {
    $JBA = 'YES'
  }
  elseif ($FreshAccount.extensionAttribute10 -eq 0) {
    $JBA = 'NO'
  }
  else {
    $JBA = 'N/A'
  }
  If ($FreshAccount.extensionAttribute11 -eq 0) {
    $Contract = 'Full Time'
  }
  elseif ($FreshAccount.extensionAttribute11 -eq 1) {
    $Contract = 'Part Time'
  }
  elseif ($FreshAccount.extensionAttribute11 -eq 2) {
    $Contract = 'Temp'
  }
  elseif ($FreshAccount.extensionAttribute11 -eq 3) {
    $Contract = 'External'
  }
  else {
    $Contract = 'N/A'
  }

  # Create report object
  $UserADReport = $null
  $UserADReport = @()
  $Obj = $null ; $Obj = New-Object -TypeName PSObject

  # Display/store report
  $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);  Write-Host "[$timer] - (SUMMARY - ACTIVE DIRECTORY) Created user [$($FreshAccount.DisplayName)]:" -ForegroundColor Magenta
  Write-Host "SAMAccountName      : $($FreshAccount.SAMAccountName)" ; $Obj | Add-Member -MemberType NoteProperty -Name SAMAccountName -Value $($FreshAccount.SAMAccountName)
  # Write-Host "Password            : $NewPassword"; $Obj | Add-Member -MemberType NoteProperty -Name Password -Value $NewPassword
  #TODO: COMPLETED - Send the password to the new starter's manager instead of the service desk (request from Janet)
  Write-Host "UserPrincipalName     : $($FreshAccount.UserPrincipalName)" ; $Obj | Add-Member -MemberType NoteProperty -Name UserPrincipalName -Value $($FreshAccount.UserPrincipalName)
  Write-Host "First Name            : $($FreshAccount.GivenName)" ; $Obj | Add-Member -MemberType NoteProperty -Name FirstName -Value $($FreshAccount.GivenName)
  Write-Host "Last Name             : $($FreshAccount.SurName)" ; $Obj | Add-Member -MemberType NoteProperty -Name LastName -Value $($FreshAccount.SurName)
  Write-Host "Template used         : $($TemplateUser.DisplayName)" ; $Obj | Add-Member -MemberType NoteProperty -Name TemplateUsed -Value $($TemplateUser.DisplayName)
  Write-Host "EmployeeID            : $($FreshAccount.EmployeeID)" ; $Obj | Add-Member -MemberType NoteProperty -Name EmployeeID -Value $($FreshAccount.EmployeeID)
  Write-Host "Job Title             : $($FreshAccount.Title)" ; $Obj | Add-Member -MemberType NoteProperty -Name JobTitle -Value $($FreshAccount.Title)
  Write-Host "Department            : $($FreshAccount.Department)" ; $Obj | Add-Member -MemberType NoteProperty -Name Department -Value $($FreshAccount.Department)
  Write-Host "Company               : $($FreshAccount.Company)" ; $Obj | Add-Member -MemberType NoteProperty -Name Company -Value $($FreshAccount.Company)
  Write-Host "Office                : $($FreshAccount.Office)" ; $Obj | Add-Member -MemberType NoteProperty -Name Office -Value $($FreshAccount.Office)
  Write-Host "Manager               : $($FreshAccount.Manager)" ; $Obj | Add-Member -MemberType NoteProperty -Name Manager -Value $($FreshAccount.Manager)
  Write-Host "Holiday entitlement   : $($FreshAccount.extensionAttribute15)" ; $Obj | Add-Member -MemberType NoteProperty -Name HolidayEntitlement -Value $($FreshAccount.extensionAttribute15)
  Write-Host "Start Date            : $($FreshAccount.extensionAttribute13)" ; $Obj | Add-Member -MemberType NoteProperty -Name StartDate -Value $($FreshAccount.extensionAttribute13)
  Write-Host "End Date              : $($FresAccount.AccountExpirationDate)" ; $Obj | Add-Member -MemberType NoteProperty -Name EndDate -Value $($FresAccount.AccountExpirationDate)
  Write-Host "Contract type         : $Contract" ; $Obj | Add-Member -MemberType NoteProperty -Name ContractType -Value $Contract
  Write-Host "JBA Access            : $JBA" ; $Obj | Add-Member -MemberType NoteProperty -Name JBAAccess -Value $JBA
  Write-Host "User domain           : $UserDomain"  ; $Obj | Add-Member -MemberType NoteProperty -Name UserDomain -Value $UserDomain
  Write-Host "Company Code          : $($FreshAccount.extensionAttribute5)" ; $Obj | Add-Member -MemberType NoteProperty -Name CompanyCode -Value $($FreshAccount.extensionAttribute5)
  Write-Host "Country Code          : $($FreshAccount.extensionAttribute6)" ; $Obj | Add-Member -MemberType NoteProperty -Name CountryCode -Value $($FreshAccount.extensionAttribute6)
  Write-Host "Short Company Code    : $($FreshAccount.extensionAttribute7)" ; $Obj | Add-Member -MemberType NoteProperty -Name ShortCompanyCode -Value $($FreshAccount.extensionAttribute7)

  # Generate CSV report
  $UserADReport += $Obj

  $UserADReportConverted =
  $UserADReport |
    Get-Member -MemberType NoteProperty |
    Select-Object @{name = 'Name';expression = { $_.name } },
    @{name = 'Value';expression = { ($($UserADReport)).($_.name) } } |
    ConvertTo-Csv
}
            
return $UserADReportConverted

# SIG # Begin signature block
# MIIOWAYJKoZIhvcNAQcCoIIOSTCCDkUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUr1zBhTie5aj7TCq6qO8TMHtq
# 7FqgggueMIIEnjCCA4agAwIBAgITTwAAAAb2JFytK6ojaAABAAAABjANBgkqhkiG
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
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUD9gieQDcfmt0SG0+ZmAM0KHiXjwwDQYJKoZI
# hvcNAQEBBQAEggEAAwrACjRBYF4o8RZSvYpdscwyfH14XVJbqKOvKAewhH/5plNi
# eNA4YZX73NIKYODIxDFNTGsu+pIFo8Iy0WVjYdub7O1zhu4Qi00ubzlRVZRxaVdA
# peOQT7y3H6D3ETVNJsWp86MTymuTvmAFAmjLseeXc4ezRURfDTTZ7Vx53j5wk7Ah
# 0clhoyrtLDFYcFvT/h6vkTl9PYcf5AW406BxKCqBW/6YNzPMJSymJu4+yn9GrA4+
# TWqImdhmzaOP6p7XxoCU36M1rvFr16pl2IDKBPyld1yGdicZNnRZ13I+AlCdQDRi
# gsZOBeClSiR8YB64BckcDh6epHzm6bqw6XadHg==
# SIG # End signature block
