<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
#>

[cmdletbinding(SupportsShouldProcess = $True)]
param(
    # [Parameter(Mandatory=$True)] [string] $Param1
)
    
begin {

    # SET ENVIRONMENT
    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    
    #region DRAW THE GUI
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $Form = New-Object system.Windows.Forms.Form
    $Form.ClientSize = '420,630'
    $Form.text = "Onboarding Form v0.1"
    $Form.TopMost = $false

    $DomainSelector = New-Object system.Windows.Forms.Label
    $DomainSelector.text = "Select work domains"
    $DomainSelector.AutoSize = $true
    $DomainSelector.width = 25
    $DomainSelector.height = 10
    $DomainSelector.location = New-Object System.Drawing.Point(50, 30)
    $DomainSelector.Font = 'Microsoft Sans Serif,10'

    $WCDomain = New-Object System.Windows.Forms.CheckBox
    $WCDomain.text = "WestCoast"
    $WCDomain.AutoSize = $false
    $WCDomain.width = 95
    $WCDomain.height = 20
    $WCDomain.location = New-Object System.Drawing.Point(50, 60)
    $WCDomain.Font = 'Microsoft Sans Serif,10'

    $XMADomain = New-Object System.Windows.Forms.CheckBox
    $XMADomain.text = "XMA"
    $XMADomain.AutoSize = $false
    $XMADomain.width = 95
    $XMADomain.height = 20
    $XMADomain.location = New-Object System.Drawing.Point(210, 60)
    $XMADomain.Font = 'Microsoft Sans Serif,10'

    $TSAMNeeded = New-Object system.Windows.Forms.Label
    $TSAMNeeded.text = "SAM Account Name of the TEMPLATE user *"
    $TSAMNeeded.AutoSize = $true
    $TSAMNeeded.visible = $false
    $TSAMNeeded.width = 60
    $TSAMNeeded.height = 20
    $TSAMNeeded.location = New-Object System.Drawing.Point(50, 120)
    $TSAMNeeded.Font = 'Microsoft Sans Serif,10'

    $TSAM = New-Object system.Windows.Forms.TextBox
    $TSAM.multiline = $false
    $TSAM.width = 150
    $TSAM.height = 30
    $TSAM.visible = $false
    $TSAM.location = New-Object System.Drawing.Point(50, 150)
    $TSAM.Font = 'Microsoft Sans Serif,10'

    $ButtonTSAM_FILTER = New-Object system.Windows.Forms.Button
    $ButtonTSAM_FILTER.text = "FIND TEMPLATE *"
    $ButtonTSAM_FILTER.width = 150
    $ButtonTSAM_FILTER.height = 25
    $ButtonTSAM_FILTER.visible = $false
    $ButtonTSAM_FILTER.location = New-Object System.Drawing.Point(240, 150)
    $ButtonTSAM_FILTER.Font = 'Microsoft Sans Serif,10'

    $MSAMNeeded = New-Object system.Windows.Forms.Label
    $MSAMNeeded.text = "SAM Account Name of the MANAGER *"
    $MSAMNeeded.AutoSize = $true
    $MSAMNeeded.visible = $false
    $MSAMNeeded.width = 60
    $MSAMNeeded.height = 20
    $MSAMNeeded.location = New-Object System.Drawing.Point(50, 180)
    $MSAMNeeded.Font = 'Microsoft Sans Serif,10'

    $MSAM = New-Object system.Windows.Forms.TextBox
    $MSAM.multiline = $false
    $MSAM.width = 150
    $MSAM.height = 30
    $MSAM.visible = $false
    $MSAM.location = New-Object System.Drawing.Point(50, 210)
    $MSAM.Font = 'Microsoft Sans Serif,10'

    $FNameNeeded = New-Object system.Windows.Forms.Label
    $FNameNeeded.text = "Frist name of the new user: *"
    $FNameNeeded.AutoSize = $true
    $FNameNeeded.visible = $false
    $FNameNeeded.width = 60
    $FNameNeeded.height = 20
    $FNameNeeded.location = New-Object System.Drawing.Point(50, 240)
    $FNameNeeded.Font = 'Microsoft Sans Serif,10'

    $FName = New-Object system.Windows.Forms.TextBox
    $FName.multiline = $false
    $FName.width = 150
    $FName.height = 30
    $FName.visible = $false
    $FName.location = New-Object System.Drawing.Point(50, 270)
    $FName.Font = 'Microsoft Sans Serif,10'

    $PickStartDate = New-Object System.Windows.Forms.CheckBox
    $PickStartDate.text = "Select Start Date"
    $PickStartDate.AutoSize = $false
    $PickStartDate.width = 150
    $PickStartDate.height = 20
    $PickStartDate.location = New-Object System.Drawing.Point(250, 270)
    $PickStartDate.Font = 'Microsoft Sans Serif,10'
    $PickStartDate.visible = $false

    $DisplayStartDate = New-Object system.Windows.Forms.Label
    $DisplayStartDate.text = ""
    $DisplayStartDate.AutoSize = $true
    $DisplayStartDate.visible = $false
    $DisplayStartDate.width = 60
    $DisplayStartDate.height = 20
    $DisplayStartDate.location = New-Object System.Drawing.Point(250, 300)
    $DisplayStartDate.Font = 'Microsoft Sans Serif,10'
    $DisplayStartDate.Visible = $false

    $LNameNeeded = New-Object system.Windows.Forms.Label
    $LNameNeeded.text = "Last name of the new user: *"
    $LNameNeeded.AutoSize = $true
    $LNameNeeded.visible = $false
    $LNameNeeded.width = 60
    $LNameNeeded.height = 20
    $LNameNeeded.location = New-Object System.Drawing.Point(50, 300)
    $LNameNeeded.Font = 'Microsoft Sans Serif,10'

    $LName = New-Object system.Windows.Forms.TextBox
    $LName.multiline = $false
    $LName.width = 150
    $LName.height = 30
    $LName.visible = $false
    $LName.location = New-Object System.Drawing.Point(50, 330)
    $LName.Font = 'Microsoft Sans Serif,10'

    $PickEndDate = New-Object System.Windows.Forms.CheckBox
    $PickEndDate.text = "Select End Date"
    $PickEndDate.AutoSize = $false
    $PickEndDate.width = 150
    $PickEndDate.height = 20
    $PickEndDate.location = New-Object System.Drawing.Point(250, 330)
    $PickEndDate.Font = 'Microsoft Sans Serif,10'
    $PickEndDate.visible = $false

    $DisplayEndDate = New-Object system.Windows.Forms.Label
    $DisplayEndDate.text = ""
    $DisplayEndDate.AutoSize = $true
    $DisplayEndDate.visible = $false
    $DisplayEndDate.width = 60
    $DisplayEndDate.height = 20
    $DisplayEndDate.location = New-Object System.Drawing.Point(250, 360)
    $DisplayEndDate.Font = 'Microsoft Sans Serif,10'
    $DisplayEndDate.Visible = $false

    $EmpIDNeeded = New-Object system.Windows.Forms.Label
    $EmpIDNeeded.text = "Employee ID of the new user: *"
    $EmpIDNeeded.AutoSize = $true
    $EmpIDNeeded.visible = $false
    $EmpIDNeeded.width = 60
    $EmpIDNeeded.height = 20
    $EmpIDNeeded.location = New-Object System.Drawing.Point(50, 360)
    $EmpIDNeeded.Font = 'Microsoft Sans Serif,10'

    $EmpID = New-Object system.Windows.Forms.TextBox
    $EmpID.multiline = $false
    $EmpID.width = 75
    $EmpID.height = 30
    $EmpID.visible = $false
    $EmpID.location = New-Object System.Drawing.Point(50, 390)
    $EmpID.Font = 'Microsoft Sans Serif,10'

    $ContractTypeNeeded = New-Object system.Windows.Forms.Label
    $ContractTypeNeeded.text = "Contract type of the new user:"
    $ContractTypeNeeded.AutoSize = $true
    $ContractTypeNeeded.visible = $false
    $ContractTypeNeeded.width = 60
    $ContractTypeNeeded.height = 20
    $ContractTypeNeeded.location = New-Object System.Drawing.Point(50, 420)
    $ContractTypeNeeded.Font = 'Microsoft Sans Serif,10'

    $ContractType = New-Object system.Windows.Forms.TextBox
    $ContractType.multiline = $false
    $ContractType.width = 75
    $ContractType.height = 30
    $ContractType.visible = $false
    $ContractType.location = New-Object System.Drawing.Point(50, 450)
    $ContractType.Font = 'Microsoft Sans Serif,10'

    $HolidayNeeded = New-Object system.Windows.Forms.Label
    $HolidayNeeded.text = "Holidays for the new user:"
    $HolidayNeeded.AutoSize = $true
    $HolidayNeeded.visible = $false
    $HolidayNeeded.width = 60
    $HolidayNeeded.height = 20
    $HolidayNeeded.location = New-Object System.Drawing.Point(240, 420)
    $HolidayNeeded.Font = 'Microsoft Sans Serif,10'

    $Holiday = New-Object system.Windows.Forms.TextBox
    $Holiday.multiline = $false
    $Holiday.width = 75
    $Holiday.height = 30
    $Holiday.visible = $false
    $Holiday.location = New-Object System.Drawing.Point(240, 450)
    $Holiday.Font = 'Microsoft Sans Serif,10'

    $ButtonMSAM_FILTER = New-Object system.Windows.Forms.Button
    $ButtonMSAM_FILTER.text = "FIND MANAGER *"
    $ButtonMSAM_FILTER.width = 150
    $ButtonMSAM_FILTER.height = 25
    $ButtonMSAM_FILTER.visible = $false
    $ButtonMSAM_FILTER.location = New-Object System.Drawing.Point(240, 210)
    $ButtonMSAM_FILTER.Font = 'Microsoft Sans Serif,10'

    $SELECTIONClicky = New-Object system.Windows.Forms.Label
    $SELECTIONClicky.text = "(click on above to select template and manager)"
    $SELECTIONClicky.AutoSize = $true
    $SELECTIONClicky.visible = $false
    $SELECTIONClicky.width = 90
    $SELECTIONClicky.height = 30
    $SELECTIONClicky.location = New-Object System.Drawing.Point(90, 300)
    $SELECTIONClicky.Font = 'Microsoft Sans Serif,10'

    $SELECTIONClicky2 = New-Object system.Windows.Forms.Label
    $SELECTIONClicky2.text = "please note:`n - we will create the `n user in the template's domain `n  - template and manager should be `n in the same domain"
    $SELECTIONClicky2.AutoSize = $true
    $SELECTIONClicky2.visible = $false
    $SELECTIONClicky2.width = 90
    $SELECTIONClicky2.height = 30
    $SELECTIONClicky2.location = New-Object System.Drawing.Point(90, 330)
    $SELECTIONClicky2.Font = 'Microsoft Sans Serif,10'
    $SELECTIONClicky2.ForeColor = "Blue"

    $SelectedTemplateUser = New-Object system.Windows.Forms.ListBox
    $SelectedTemplateUser.text = "please select"
    $SelectedTemplateUser.width = 250
    $SelectedTemplateUser.height = 90
    $SelectedTemplateUser.location = New-Object System.Drawing.Point(90, 120)
    $SelectedTemplateUser.Visible = $false

    $SelectedManagerUser = New-Object system.Windows.Forms.ListBox
    $SelectedManagerUser.text = "please select"
    $SelectedManagerUser.width = 250
    $SelectedManagerUser.height = 90
    $SelectedManagerUser.location = New-Object System.Drawing.Point(90, 210)
    $SelectedManagerUser.Visible = $false

    $ConfirmSummary = New-Object system.Windows.Forms.Label
    $ConfirmSummary.text = "Please review and confirm"
    $ConfirmSummary.AutoSize = $true
    $ConfirmSummary.visible = $false
    $ConfirmSummary.width = 25
    $ConfirmSummary.height = 10
    $ConfirmSummary.location = New-Object System.Drawing.Point(60, 30)
    $ConfirmSummary.Font = 'Microsoft Sans Serif,10'

    $Summary = New-Object System.Windows.Forms.TextBox
    $Summary.text = ""
    $Summary.TextAlign = 'Left'
    $Summary.AutoSize = $true
    $Summary.multiline = $true
    $Summary.width = 340
    $Summary.height = 410
    $Summary.visible = $false
    $Summary.ReadOnly = $true
    $Summary.location = New-Object System.Drawing.Point(60, 60)

    $ButtonCONFIRM_1 = New-Object system.Windows.Forms.Button
    $ButtonCONFIRM_1.text = "CONFIRM (1)"
    $ButtonCONFIRM_1.width = 100
    $ButtonCONFIRM_1.height = 30
    $ButtonCONFIRM_1.location = New-Object System.Drawing.Point(30, 560)
    $ButtonCONFIRM_1.Font = 'Microsoft Sans Serif,10'
    $ButtonCONFIRM_1.ForeColor = "Red"

    $ButtonCONFIRM_2 = New-Object system.Windows.Forms.Button
    $ButtonCONFIRM_2.text = "CONFIRM (2)"
    $ButtonCONFIRM_2.width = 100
    $ButtonCONFIRM_2.height = 30
    $ButtonCONFIRM_2.location = New-Object System.Drawing.Point(30, 560)
    $ButtonCONFIRM_2.Font = 'Microsoft Sans Serif,10'
    $ButtonCONFIRM_2.visible = $false

    $ButtonOK = New-Object system.Windows.Forms.Button
    $ButtonOK.text = "OK"
    $ButtonOK.width = 100
    $ButtonOK.height = 30
    $ButtonOK.visible = $false
    $ButtonOK.location = New-Object System.Drawing.Point(30, 560)
    $ButtonOK.Font = 'Microsoft Sans Serif,10'

    $ButtonCLOSE = New-Object system.Windows.Forms.Button
    $ButtonCLOSE.text = "CLOSE"
    $ButtonCLOSE.width = 100
    $ButtonCLOSE.height = 30
    $ButtonCLOSE.visible = $true
    $ButtonCLOSE.location = New-Object System.Drawing.Point(290, 560)
    $ButtonCLOSE.Font = 'Microsoft Sans Serif,10'

    $StaredItems = New-Object system.Windows.Forms.Label
    $StaredItems.text = 'Items marked with * are mandatory !'
    $StaredItems.AutoSize = $true
    $StaredItems.visible = $false
    $StaredItems.width = 60
    $StaredItems.height = 20
    $StaredItems.location = New-Object System.Drawing.Point(50, 510)
    $StaredItems.Font = 'Microsoft Sans Serif,10'
    $StaredItems.ForeColor = "Blue"

    $Form.controls.AddRange(@($DomainSelector, $WCDomain, $XMADomain, $TSAMNeeded, $TSAM, $MSAMNeeded, $MSAM, $ButtonTSAM_FILTER, $ButtonMSAM_FILTER, $FNameNeeded, $FName, $PickStartDate, $DisplayStartDate, $LNameNeeded, `
                $LName, $PickEndDate, $DisplayEndDate, $EmpIDNeeded, $EmpID, $ContractTypeNeeded, $ContractType, $HolidayNeeded, $Holiday, $SELECTIONClicky, $SelectedTemplateUser, $SelectedManagerUser, $ButtonCONFIRM_1, $ButtonCONFIRM_2, $Summary, $ConfirmSummary, $SELECTIONClicky2, $ButtonOK, $ButtonCLOSE, $StaredItems))
    # $LName, $EmpIDNeeded, $EmpID, $SELECTIONClicky, $SelectedTemplateUser, $SelectedManagerUser, $ForwardingNeeded, $ForwardeeAddress, <#$ButtonCANCEL,#>$ButtonCONFIRM_1, $ButtonCONFIRM_2, $RequestForwardee, $Summary, $ConfirmSummary, $ButtonOK, $ButtonCLOSE))

    #endregion

    #region PARAMETERS 

    $RequestingUser = ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
    $hour = Get-Date -Format yyyy-MM-dd-HH-00
    $CSVFolder = "\\bnwinfrats01\InputOn\"
    $CSV = $CSVFolder + "OnBoarding_hourly_" + $hour + ".csv"
    $TextInfo = (Get-Culture).TextInfo
    $DCWestCoast = (Get-ADForest -Identity "westcoast.co.uk" |	Select-Object -ExpandProperty RootDomain |	Get-ADDomain |	Select-Object -Property PDCEmulator).PDCEmulator
    $DCXMA = (Get-ADForest -Identity "xma.co.uk" |	Select-Object -ExpandProperty RootDomain |	Get-ADDomain |	Select-Object -Property PDCEmulator).PDCEmulator
    $AllWestCoastUsers = Get-ADUser -Filter * -searchbase "OU=Active Employees,OU=USERS,OU=WC2014,DC=westcoast,DC=co,DC=uk" -Properties Name, SAMAccountName, UserPrincipalName, DistinguishedName, EmployeeID -Server $DCWestCoast | Where-Object { $_.Name -notlike "_*" }
    $AllWestCoastUsers += Get-ADUser -Filter * -searchbase "OU=Westcoast Employees,OU=USERS,OU=LIVE,OU=WESTCOAST,DC=westcoast,DC=co,DC=uk" -Properties Name, SAMAccountName, UserPrincipalName, DistinguishedName, EmployeeID -Server $DCWestCoast | Where-Object { $_.Name -notlike "_*" }
    $AllXMAUsers = Get-ADUser -Filter * -searchbase "OU=Users,OU=XMA LTD,DC=xma,DC=co,DC=uk" -Properties Name, SAMAccountName, UserPrincipalName, DistinguishedName, EmployeeID  -Server $DCXMA | Where-Object { $_.Name -notlike "_*" }
    $AllGroupUsers = $AllWestCoastUsers + $AllXMAUsers | Sort-Object

    #endregion

    #region FUNCTIONS 
    function FilterTEMPLATEList {
        Try {
            ShowTEMPLATEUserList
            if ( ($WCDomain.Checked -eq $true) -and ($XMADomain.Checked -eq $true) ) {
                $SelectedTemplateUser.Items.Clear()
                $SelectedTemplateUser.Items.AddRange( ($AllGroupUsers | Where-Object { $_.SAMAccountName -match $TSAM.Text } | Sort-Object UserPrincipalName ).userprincipalname )
            }
            elseif ($WCDomain.Checked -eq $true) {
                $SelectedTemplateUser.Items.Clear()
                $SelectedTemplateUser.Items.AddRange( ($AllWestCoastUsers | Where-Object { $_.SAMAccountName -match $TSAM.Text } | Sort-Object UserPrincipalName ).userprincipalname )
            }

            elseif ($XMADomain.Checked -eq $true) {
                $SelectedTemplateUser.Items.Clear()
                $SelectedTemplateUser.Items.AddRange( ($AllXMAUsers | Where-Object { $_.SAMAccountName -match $TSAM.Text } | Sort-Object UserPrincipalName ).userprincipalname )
            }
        }
        catch {
            $SelectedTemplateUser.Items.Clear()
            $SelectedTemplateUser.Items.AddRange( "NO MATCHING USER FOUND!" )
            Write-Host -ForegroundColor Red "Matching (template) user not found!"
        }
    }

    function FilterMANAGERList {
        Try {
            ShowMANAGERUserList
            if ( ($WCDomain.Checked -eq $true) -and ($XMADomain.Checked -eq $true) ) {
                $SelectedManagerUser.Items.Clear()
                $SelectedManagerUser.Items.AddRange( ($AllGroupUsers | Where-Object { $_.SAMAccountName -match $MSAM.Text } | Sort-Object UserPrincipalName ).userprincipalname )
            }
            elseif ($WCDomain.Checked -eq $true) {
                $SelectedManagerUser.Items.Clear()
                $SelectedManagerUser.Items.AddRange( ($AllWestCoastUsers | Where-Object { $_.SAMAccountName -match $MSAM.Text } | Sort-Object UserPrincipalName ).userprincipalname )
            }
            elseif ($XMADomain.Checked -eq $true) {
                $SelectedManagerUser.Items.Clear()
                $SelectedManagerUser.Items.AddRange( ($AllXMAUsers | Where-Object { $_.SAMAccountName -match $MSAM.Text } | Sort-Object UserPrincipalName ).userprincipalname )
            }
        }
        catch {
            $SelectedManagerUser.Items.Clear()
            $SelectedManagerUser.Items.AddRange( "NO MATCHING USER FOUND!" )
            Write-Host -ForegroundColor Red "Matching (manager) user not found!"
        }
    }
    function ShowSAMBlock {
        $TSAMNeeded.Visible = $true
        $StaredItems.Visible = $true
        $TSAM.Visible = $true
        $MSAMNeeded.Visible = $true
        $MSAM.Visible = $true
        $ButtonTSAM_FILTER.Visible = $true
        $ButtonMSAM_FILTER.Visible = $true
        $FNameNeeded.Visible = $true
        $PickStartDate.visible = $true
        $PickEndDate.visible = $true
        $FName.Visible = $true
        $LNameNeeded.Visible = $true
        $LName.Visible = $true
        $EmpIDNeeded.Visible = $true
        $EmpID.Visible = $true
        $ContractTypeNeeded.Visible = $true
        $ContractType.visible = $true
        $HolidayNeeded.Visible = $true
        $Holiday.visible = $true
    }
    function HideFirstPageElements {
        $TSAMNeeded.Visible = $false
        $StaredItems.visible = $false
        $TSAM.Visible = $false
        $MSAMNeeded.Visible = $false
        $MSAM.Visible = $false   
        $ButtonTSAM_FILTER.Visible = $false
        $ButtonMSAM_FILTER.Visible = $false
        $FNameNeeded.Visible = $false
        $PickStartDate.visible = $false
        $PickEndDate.visible = $false
        $FName.Visible = $false
        $LNameNeeded.Visible = $false
        $LName.Visible = $false
        $EmpIDNeeded.Visible = $false
        $EmpID.Visible = $false
        $ContractTypeNeeded.visible = $false
        $ContractType.visible = $false
        $HolidayNeeded.visible = $false
        $Holiday.visible = $false
        $DisplayStartDate.visible = $false
        $DisplayEndDate.visible = $false
    }
    function ShowTEMPLATEUserList {
        $SelectedTemplateUser.Visible = $true
        $SELECTIONClicky.Visible = $true
        $SELECTIONClicky2.visible = $true
    }
    function ShowMANAGERUserList {
        $SelectedManagerUser.Visible = $true
        $SELECTIONClicky.Visible = $true
        $SELECTIONClicky2.visible = $true
    }
    function Build-Summary {
        $global:TemplateADUser = $SelectedTemplateUser.SelectedItem
        $U = ($global:TemplateADUser -split "@")[0]

        If ($global:TemplateADUser -match "westcoast") {
            $global:WorkDomain = "WESTCOAST"
            $global:TemplateADUser = Get-ADUser $U -Properties * -Server $DCWestCoast
        }

        If ($global:TemplateADUser -match "xma") {
            $global:WorkDomain = "XMA"
            $global:TemplateADUser = Get-ADUser $U -Properties * -Server $DCXMA
        }
        $global:ManagerADUser = $SelectedManagerUser.SelectedItem
        $U = ($global:ManagerADUser -split "@")[0]

        If ($global:ManagerADUser -match "westcoast") {
            $global:WorkDomain = "WESTCOAST"
            $global:ManagerADUser = Get-ADUser $U -Properties * -Server $DCWestCoast
        }

        If ($global:ManagerADUser -match "xma") {
            $global:WorkDomain = "XMA"
            $global:ManagerADUser = Get-ADUser $U -Properties * -Server $DCXMA
        }    

        $Summary.Text =
        "
        Entering the following user to the CSV:
        -----------------------------------------------
        NEW ACCOUNT
        -----------------------------------------------
        DOMAIN: $($global:WorkDomain)
        Name: $($FName.text) $($LName.text)`n
        FirstName: $($FName.text)`n
        LastName: $($LName.text)`n
        SAMAccountName: $($FName.text + "." + $LName.text)`n
        UserPrincipalName: $($FName.text + "." + $LName.text + "@" + $global:WorkDomain + ".co.uk")`n
        Employee ID: $($EmpID.text)`n
        -----------------------------------------------
        SETTINGS
        -----------------------------------------------
        (template will be used for cloning; `n
        manager will be added as the manager `n
        of the user)`n
        Template user: $($global:TemplateADUser.SAMAccountName)`n
        Manager user: $($global:ManagerADUser.SAMAccountName)
        "

        if ($Holiday.text) {
            $Summary.Text +=
            "
        Holiday entitlement: $($Holiday.text) (days) "
        }

        if ($ContractType.text) {
            $Summary.Text +=
            "
        Contract type: $($ContractType.text) "
        }

        if ($global:SelectedStartDate) {
            $Summary.Text +=
            "
        Start date: $($global:SelectedStartDate) "
        }


        $Summary.Text +=
        " 
        -----------------------------------------------
        Click 'OK' to continue saving the file
        "

        $Summary.visible = $true
    }
    function Summary_CSVSuccess {
        $Summary.Text = "
        File saved to:`n
        `n
        $CSV`n
        "
        $Summary.ForeColor = "Green"
        $Summary.BackColor = "Black"
        $ButtonOK.Visible = $false
        $ConfirmSummary.visible = $false
    }
    function Summary_CSVFailed {
        $Summary.Text = "
        Failed to save the CSV. Do you have rights to the location?`n
        `n
        $CSVFolder`n
        "
        $Summary.ForeColor = "Red"
        $Summary.BackColor = "Black"
        $ButtonOK.Visible = $false
        $ConfirmSummary.visible = $false
    }
    function CSV_Test {
        if (Test-Path $CSV) {
            Summary_CSVSuccess
        }
        else {
            Summary_CSVFailed
        }
    }
    function ShowForwardingBlock {
        $ForwardeeAddress.Visible = $true
        $RequestForwardee.Visible = $true
    }
    function HideForwardingBlock {
        $ForwardingNeeded.Visible = $false
        $ForwardeeAddress.Visible = $false
    }
    function HideStartingElements {
        #HideOriginalElements
        $DomainSelector.Visible = $false
        $WCDomain.Visible = $false
        $XMADomain.Visible = $false
        $SelectedTemplateUser.Visible = $false
        $SelectedManagerUser.Visible = $false
        $ButtonCONFIRM_1.Visible = $false
        # $RequestForwardee.Visible = $false
        $SELECTIONClicky.Visible = $false
        $SELECTIONClicky2.visible = $false
    }
    function ShowVerification {
        #DisplayNewElements
        $Summary.Visible = $true
        $ConfirmSummary.Visible = $true
        $SELECTIONClicky2.Visible = $false
        $ButtonOK.Visible = $true
        $ButtonCONFIRM_2.visible = $false
        <#$ButtonCANCEL.visible                     = $true#>
        Build-Summary
    }
    function ButtonCONFIRM_1toButtonCONFIRM_2 {
        $ButtonCONFIRM_1.visible = $false
        $ButtonCONFIRM_2.visible = $true
        $ButtonCONFIRM_2.ForeColor = "Red"
    }
    function SelectedUserClick {
        if (($SelectedManagerUser.SelectedItem ) -and ($SelectedTemplateUser.SelectedItem)) {
            $ButtonCONFIRM_2.ForeColor = "Green"
        }
    }
    function BuildCSV {
        $Result = @()
        $Obj = New-Object -TypeName PSObject
        $Obj | Add-Member -MemberType NoteProperty -Name Domain -Value $global:WorkDomain
        $Obj | Add-Member -MemberType NoteProperty -Name FirstName -Value $($FName.text)
        $Obj | Add-Member -MemberType NoteProperty -Name LastName -Value $($LName.text)
        $Obj | Add-Member -MemberType NoteProperty -Name EmployeeID -Value $($EmpID.text)
        $Obj | Add-Member -MemberType NoteProperty -Name TemplateName -Value $($global:TemplateADUser.SAMAccountName)
        $Obj | Add-Member -MemberType NoteProperty -Name Manager -Value $($global:ManagerADUser.SAMAccountName)
        if ($Holiday.Text) {
            $Obj | Add-Member -MemberType NoteProperty -Name HolidayEntitlement -Value $($Holiday.Text)
        }
        if ($ContractType.Text) {
            $Obj | Add-Member -MemberType NoteProperty -Name ContractType -Value $($ContractType.Text)
        }    
        if ($global:SelectedStartDate) {
            $Obj | Add-Member -MemberType NoteProperty -Name StartDate -Value $($global:SelectedStartDate)
        }              
        $Obj | Add-Member -MemberType NoteProperty -Name RequestingUser -Value $RequestingUser
        $Result += $Obj
        Try {
            $Result | Export-csv -Path $CSV -Force -Append -NoTypeInformation
        }
        catch {
            Write-Verbose "Problem with writing CSV. Please contact [fabrice.semti@westcoast.co.uk]!"
        }
    }

    function MinimumDetailsPresentCheck {
        if ($TSAM.text -and $MSAM.text -and $FName.text -and $LName.text -and $EmpID.text) {
            $ButtonCONFIRM_1.ForeColor = "Green"
        }
        else {
            $ButtonCONFIRM_1.ForeColor = "Red"
        }
    }

    function StartDatePicker {
        #Graphical Date Picker
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $form = New-Object Windows.Forms.Form
        
        $form.Text = 'Select a Date'
        $form.Size = New-Object Drawing.Size @(250, 300  )
        $form.StartPosition = 'CenterScreen'
        
        $StartDateCalendarGUI = New-Object System.Windows.Forms.MonthCalendar
        $StartDateCalendarGUI.ShowTodayCircle = $false
        $StartDateCalendarGUI.MaxSelectionCount = 1
        $form.Controls.Add($StartDateCalendarGUI)
        
        $OKButton = New-Object System.Windows.Forms.Button
        $OKButton.Location = New-Object System.Drawing.Point(80, 200)
        $OKButton.Size = New-Object System.Drawing.Size(75, 23)
        $OKButton.Text = 'OK'
        $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.AcceptButton = $OKButton
        $form.Controls.Add($OKButton)
        
        
        $form.Topmost = $true
        
        $result = $form.ShowDialog()
        
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $date = $StartDateCalendarGUI.SelectionStart
            #$DeliveryDate = $($date.ToShortDateString())
            $StartDate = ($date.GetDateTimeFormats("d") -match '\d{4}-\d{2}-\d{2}')
            # Display this in the $DisplayStartDate form
            $DisplayStartDate.text = $StartDate
            $DisplayStartDate.visible = $true
        }
        return $StartDate 
    }

    function EndDatePicker {
        #Graphical Date Picker
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $form = New-Object Windows.Forms.Form
        
        $form.Text = 'Select a Date'
        $form.Size = New-Object Drawing.Size @(250, 300  )
        $form.StartPosition = 'CenterScreen'
        
        $EndDateCalendarGUI = New-Object System.Windows.Forms.MonthCalendar
        $EndDateCalendarGUI.ShowTodayCircle = $false
        $EndDateCalendarGUI.MaxSelectionCount = 1
        $form.Controls.Add($EndDateCalendarGUI)
        
        $OKButton = New-Object System.Windows.Forms.Button
        $OKButton.Location = New-Object System.Drawing.Point(80, 200)
        $OKButton.Size = New-Object System.Drawing.Size(75, 23)
        $OKButton.Text = 'OK'
        $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.AcceptButton = $OKButton
        $form.Controls.Add($OKButton)
        
        
        $form.Topmost = $true
        
        $result = $form.ShowDialog()
        
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $date = $EndDateCalendarGUI.SelectionStart
            #$DeliveryDate = $($date.ToShortDateString())
            $EndDate = ($date.GetDateTimeFormats("d") -match '\d{4}-\d{2}-\d{2}')
            # Display this in the $DisplayEndDate form
            $DisplayEndDate.text = $EndDate
            $DisplayEndDate.visible = $true
        }
        return $EndDate 
    }
    
    #endregion


    


}
    
process {

    $ButtonTSAM_FILTER.Add_Click( {
            if ($TSAM.text) {
                $ButtonTSAM_FILTER.text = "THANKS"
                $ButtonTSAM_FILTER.ForeColor = "Green"
            }
            else {
                $ButtonTSAM_FILTER.text = "INVALID"
                $ButtonTSAM_FILTER.ForeColor = "Red"
            }
            # HideFirstPageElements
            # FilterTEMPLATEList
            MinimumDetailsPresentCheck
        })

    $ButtonMSAM_FILTER.Add_Click( {
            if ($MSAM.text) {
                $ButtonMSAM_FILTER.text = "THANKS"
                $ButtonMSAM_FILTER.ForeColor = "Green"
            }
            else {
                $ButtonMSAM_FILTER.text = "INVALID"
                $ButtonMSAM_FILTER.ForeColor = "Red"
            }
            # HideMSAMBlock
            # FilterTEMPLATEList
            MinimumDetailsPresentCheck
        })   

    # Display domain user lists
    $WCDomain.Add_Click( {
            ShowSAMBlock <#;PopulateDropdown#>
            MinimumDetailsPresentCheck
        })

    $XMADomain.Add_Click( {
            ShowSAMBlock <#;PopulateDropdown#>
            MinimumDetailsPresentCheck
        })

    $PickStartDate.Add_Click( {
            $global:SelectedStartDate = StartDatePicker
        })

    $PickEndDate.Add_Click( {
            # $global:SelectedStartDate = StartDatePicker
            $global:SelectedEndDate = EndDatePicker
        })        

    # Button actions
    $ButtonCONFIRM_1.Add_Click( {
            HideFirstPageElements
            FilterTEMPLATEList
            FilterMANAGERList
            ButtonCONFIRM_1toButtonCONFIRM_2
            # HideForwardingBlock
            # HideStartingElements
            # ShowVerification
        })

    $ButtonCONFIRM_2.Add_Click( {
            HideStartingElements
            ShowVerification
            #ButtonCONFIRM_2toACCEPT

        })

    $ButtonCLOSE.Add_Click( {
            $Form.Close()
            $Form.Dispose()
        })

    <#$ButtonCANCEL.Add_Click({ $Form.Refresh() })#>
    $ButtonOK.Add_Click( {
            BuildCSV
            CSV_Test
        })

    $SelectedTemplateUser.Add_Click( {
            SelectedUserClick
        })

    $SelectedManagerUser.Add_Click( {
            SelectedUserClick
        })

    $FName.Add_Click( {
            MinimumDetailsPresentCheck
        })

    $LName.Add_Click( {
            MinimumDetailsPresentCheck
        })

    $EmpID.Add_Click( {
            MinimumDetailsPresentCheck
        })

    $ContractType.Add_Click( {
            MinimumDetailsPresentCheck
        })

    $Holiday.Add_Click( {
            MinimumDetailsPresentCheck
        })
    
}

end {

    [void]$Form.ShowDialog()

}
# SIG # Begin signature block
# MIIOWAYJKoZIhvcNAQcCoIIOSTCCDkUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgosgaaQ6lgS7e66ArBvvdXZf
# MfWgggueMIIEnjCCA4agAwIBAgITTwAAAAb2JFytK6ojaAABAAAABjANBgkqhkiG
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
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUBCXcC5Mh9Fxz3kSAApsLaxhj4skwDQYJKoZI
# hvcNAQEBBQAEggEAxKsVZLG9lUE8scf1IwyvHcfk2ICs98dpIOCJq8k44T0hfuDG
# sJn8s5sJ+sHpmBLik3e+lex/TTOzqffdofXbV1Z3yg1KkhOACu08NHBFe/3te275
# WGBenG0rVHrk9i2dA0mQxMJrglBZWWfzzSviQMYGO13G/eBuEUXKBN3YacY7dLKK
# e6tv44j2LA9e1YwMb18ThrFWxUis7XqxBc/UbNSTI/ouZ8CnT1mPSdj0u28AWvAe
# ImXgNmM3/uhERqq8CD4Ask85KOIT7GIwVtUjKYdnFaKF8gswZ1mFhtj/L9qGjXe1
# Y8m9gA9zv5NS0V0YR5YFrN2VliXUxKDQry0pVw==
# SIG # End signature block
