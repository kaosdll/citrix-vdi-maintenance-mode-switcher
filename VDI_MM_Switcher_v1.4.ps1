<#
.SYNOPSIS
    This script enable or disable Maintenance Mode for Citrix VDI machines.
.DESCRIPTION
    The script read a static text file with hostnames and enable or disable maintance mode for each machine.
    The script will wait 60 seconds after each machine.
    If a target VDI is powered off it will be started automatically, if a target VDI is powered on it will be restarted if not in use.
.PARAMETER MaintenanceMode
    Specifies if the Maintenance Mode should be switched on or off. Options: Enable, Disable.
.PARAMETER HostListFile
    List of target Host names without Domain.
.EXAMPLE
    powershell.exe '.\VDI_MM_Switcher_v1.4.ps1' -MaintenanceMode "Enable" -HostListFile "C:\VDI_MM_Switcher\hosts.txt"
.EXAMPLE
    powershell.exe '.\VDI_MM_Switcher_v1.4.ps1' -MaintenanceMode "Disable" -HostListFile "C:\VDI_MM_Switcher\hosts.txt"
.NOTES
    Change Log
    V1.0 - 05.04.2016 - Manuel Kuss - frist release
    V1.1 - 05.04.2016 - Manuel Kuss - added logging
    V1.3 - 06.04.2016 - Manuel Kuss - added param()
    V1.4 - 07.04.2016 - Manuel Kuss - added SummaryState check
.LINK 
    http://www.nova17.de
#>

param(
    [string]$MaintenanceMode,
    [string]$HostListFile
)

Clear

## Load Addins
Add-PSSnapin Citrix.*

## Syntax Checker
If (($MaintenanceMode -eq "") -or ($HostListFile -eq "")) {
    Write-Host "ERROR MISSING PARAMETER`nSyntax: .\VDI_MM_Switcher_v1.4.ps1 -MaintenanceMode `"Enable/Disable`" -HostListFile `"C:\Path\hosts.txt`"" -ForegroundColor Red
    Exit
} 

## Variables (customize)
$AdminServer = 'hostname.domain.tld'
$ADDomain = 'YOUR-AD-DOMAIN'
## Variables
$HostList = Get-Content $HostListFile
$Logfile = "$HostListFile" + "_$MaintenanceMode" + ".log"

## Output
Write-Host "Executing..." -ForegroundColor Yellow
$starttime = Get-Date -Format G
write "--------------------------------------------------------" | Out-File $Logfile
Write "Script Start Time: $starttime" | Out-File $Logfile -Append
write "--------------------------------------------------------" | Out-File $Logfile -Append

## Enable Maintenance Mode Loop ##
if ($MaintenanceMode -eq 'Enable') 
    {
    foreach ($item in $HostList)
        {
            ## Write DOMAIN\HOSTNAME to $TargetVDI
            $TargetVDI = "$ADDomain" + "\" + "$item"
            
            ## Enable Maintenance Mode
            Write "Enable MaintenanceMode for $TargetVDI" | Out-File $Logfile -Append
            Set-BrokerMachineMaintenanceMode -InputObject $TargetVDI $true -adminaddress $AdminServer

            ## Restart if TargetVDI is not in use
            foreach ($item in Get-BrokerDesktop | Where-Object{($_.MachineName -eq "$TargetVDI") -and ($_.PowerState -eq "On") -and ($_.SummaryState -ne "InUse")} | Select-Object -Property MachineName)
                { New-BrokerHostingPowerAction -MachineName $TargetVDI -Action Restart -adminaddress $AdminServer | Out-File $Logfile -Append }

            ## If TargetVDI is powered off
            foreach ($item in Get-BrokerDesktop | Where-Object{($_.MachineName -eq "$TargetVDI") -and ($_.PowerState -eq "Off")} | Select-Object -Property MachineName)
                { New-BrokerHostingPowerAction -MachineName $TargetVDI -Action TurnOn -adminaddress $AdminServer | Out-File $Logfile -Append }
            
            ## Pause
            Write "--------------------------------------------------------" | Out-File $Logfile -Append
            Start-Sleep 60
        }
    }

## Disable Maintenance Mode Loop ##
if ($MaintenanceMode -eq 'Disable') 
    {
    foreach ($item in $HostList)
        {
            ## Write DOMAIN\HOSTNAME to $TargetVDI
            $TargetVDI = "$ADDomain" + "\" + "$item"
          
            ## Disable MaintenanceMode
            Write "Disable MaintenanceMode for $TargetVDI" | Out-File $Logfile -Append
            Set-BrokerMachineMaintenanceMode -InputObject $TargetVDI $false -adminaddress $AdminServer
            
            ## Restart if TargetVDI is not in use
            foreach ($item in Get-BrokerDesktop | Where-Object{($_.MachineName -eq "$TargetVDI") -and ($_.PowerState -eq "On") -and ($_.SummaryState -ne "InUse")} | Select-Object -Property MachineName)
                { New-BrokerHostingPowerAction -MachineName $TargetVDI -Action Restart -adminaddress $AdminServer | Out-File $Logfile -Append }
                           
            ## Pause
            Write "--------------------------------------------------------" | Out-File $Logfile -Append
            Start-Sleep 60
        }
    }

## Output
$endtime = Get-Date -Format G
Write "Script End Time: $endtime" | Out-File $Logfile -Append
write "--------------------------------------------------------" | Out-File $Logfile -Append
Write-Host "Script Execuded." -ForegroundColor Yellow
