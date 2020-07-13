     [CmdletBinding()]
     [CmdletBinding()]
     param (
     )
# This is the script wrapper that should be called for the execution.

## SET UP THE ENVIRONMENT
  Import-Module PSWriteColor
  # Collect work folders (names)
    $FunctionFolder   = "Functions"
    $InputFolder      = "Input"
    $OutputFolder     = "Output"
    $ConfigFolder     = "Config"
    $LogFolder        = "Logs"; #$LogFolder = "$global:CurrentPath\$LogFolder"
  # Establish script location
    $CurrentPath = $null
    $global:CurrentPath = Split-Path -parent $PSCommandPath
    Set-Location $global:CurrentPath
    # Import input files to work on
      $Inputfiles = Get-ChildItem .\$InputFolder | Where-Object {$_.Name -like "*.csv"}
    # Import functions to work with
      $functions = Get-ChildItem .\$FunctionFolder
      foreach ($f in $functions)
        {
        #Write-Host -ForegroundColor Cyan "Importing function $f"
        if ($f -match ".ps1"){
          . .\$FunctionFolder\$f
        }
        }
    # Transcript START
      $TranscriptFile = ".\" + $LogFolder + "\" + "OnboardingProcessing_" + (Get-Date -Format yyyy-MM-dd-hh-mm) + ".log"
      $ErrorFile = ".\" + $LogFolder + "\" + "OnboardingProcessing_ERRORS_" + (Get-Date -Format yyyy-MM-dd-hh-mm) + ".log"
#      Start-Transcript -Path $TranscriptFile

    # Create today folder
    $Today = Get-date -Format ddMM
    [void] (New-Item -Path $outputFolder -Name $Today -ItemType Directory -ErrorAction SilentlyContinue)

## ONBOARDING PROCESS -
  # Announce start of the process
  Write-Host #separator line
   $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);	Write-Host "[$timer] - PHASE1 OF THE ONBOARDING PROCESS STARTED." -BackgroundColor Black

  # Process each (.csv) files in the input folder.
  foreach ($I in $Inputfiles){
  $CSVImport = Import-CSV $($I.Fullname)

    # Process each line of the CSV
    foreach ($Line in $CSVImport){

      # Construct variables from the line contents
      $Domain = $FirstName = $LastName = $EmployeeID = $TemplateName = $HolidayEntitlement = $EmployeeStartDate = $null
      $Domain                         = $Line.Domain
      $FirstName                      = $Line.FirstName
      $LastName                       = $Line.LastName
      $EmployeeID                     = $Line.EmployeeID
      $TemplateName                   = $Line.TemplateName
      $HolidayEntitlement             = $Line.HolidayEntitlement
      $EmployeeStartDate              = $Line.StartDate
      $EmployeeEndDate                = $Line.EndDate
      $ContractType                   = $Line.ContractType

      # Run against each line
      # TODO: report, if the domain is correct
        # Pipe, if the workdomain is WestCoast
        if ($Domain -match "WestCoast"){
        $configCSV = ".\" + $ConfigFolder + "\westcoast.csv"
        $config = Import-Csv $configCSV
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);	Write-Host "[$timer] - Domain [$domain] is valid. OnBoarding user: [$FirstName $LastName] - please stand by" -ForegroundColor Yellow
        Process-OnBoarding01 -WestCoast -FirstName $FirstName -LastName $LastName -EmployeeID $EmployeeID -TemplateName $TemplateName -OutputFolder  $OutputFolder -Today $Today -config $config
        Write-Host
        }
        # Pipe, if the workdomain is XMA
        elseif ($Domain -match "XMA"){
        $configCSV = ".\" + $ConfigFolder + "\xma.csv"
        $config = Import-Csv $configCSV
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);	Write-Host "[$timer] - Domain [$domain] is valid. OnBoarding user: [$FirstName $LastName] - please stand by" -ForegroundColor Yellow
        Process-OnBoarding01 -XMA -FirstName $FirstName -LastName $LastName -EmployeeID $EmployeeID -TemplateName $TemplateName -OutputFolder $OutputFolder -Today $Today -config $config
        Write-Host
        }
        # Pipe, if the domain is not within the expected values
        else {
        # # Manual feedback
        $timer = (Get-Date -Format yyyy-MM-dd-HH:mm);	Write-Host "[$timer] - Domain [$domain] is invalid. Valid options are 'WESTCOAST and XMA'. " -ForegroundColor Red
        }
    }

  # Reporting
  Write-Host # separator line
  $timer = (Get-Date -Format yyyy-MM-dd-HH:mm); Write-Host -ForegroundColor Yellow "[$timer] - Generating reports of the script run"

    #Report on the input file
    $InputReport = ".\" + $OutputFolder + "\" + $Today + "\" +  ($I.Name -replace ".csv","_PROCESSED.csv")
    Generate-InputReport -CSVImport $CSVImport; $global:InputReport | ConvertFrom-Csv | Export-Csv $InputReport -Force
    #Report on AD actions (in the Generate-USERADREport.ps1)
    #Report on Mailbox actions
    #Report on misc actions

  #$CSVImport | Export-csv -Path $CSVExport01 -NoTypeInformation -Force # first add in the original import
  #TODO: Add FULL reporting
  #TODO: Add logging

  # Finally, discard the processed original input file
  #Remove-Item -Path $($I.Fullname) -Force #-Whatif

  # Transcript STOP
  #Stop-Transcript
  if ($Error ) {$Error | Out-File $ErrorFile}
  else { "[INFO] NO ERRORS DURING SCRIPT RUN"| Out-File $ErrorFile} # also send errors to a file


  # And cleanup the variables
  Variable-Cleanup
}

# SIG # Begin signature block
# MIIOWAYJKoZIhvcNAQcCoIIOSTCCDkUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+uCf/5XVmAcDigiQUcjZnCyg
# a72gggueMIIEnjCCA4agAwIBAgITTwAAAAb2JFytK6ojaAABAAAABjANBgkqhkiG
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
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUs6sam7D2JeeyI15nkFQITBKhR3UwDQYJKoZI
# hvcNAQEBBQAEggEAeuC1Xv320975CJbs0GSQP0pV7vmiTDhErI4FhC+bnlEeJSzW
# YwP0p9hHoEkHkQuTYmVqScGVKbrXhmggA8rrTIoGb9/Kyyhn74R8Czuh/SKJELrX
# a9sS0t8lTY0sEEV+P+OggcXlziYuYYYSG50CAxMb6NIS4BzDn2oxyw1/g//1bYnD
# J5WD1Er2kT8Usx+0qv66o2KM4olm08v5nK1nH1N7B7BCaNPoi2lqjlsrrSaFJ3sG
# nSP7geJwvObdW1XTWEJVvMArsuid7Xm1847jt2Qv3/Q7VoHPKt3NlDqRWVzRO/IP
# E7TfDkIqhsmWGtonPgJ3dxpCr8BTtsg/81OLlA==
# SIG # End signature block
