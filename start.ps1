param([switch]$SkipRepositoryUpdate=$FALSE,[switch]$SkipVirtualMachine=$FALSE,[switch]$SkipVirtualMachineUpdate=$FALSE,[String]$DevelopmentEnvironmentPath)



$ErrorActionPreference = "Stop"
$scriptInvocation = $MyInvocation

function Get-Script-Path {
    return $scriptInvocation.MyCommand.Definition
}

function Get-Script-Directory {
    return Split-Path (Get-Script-Path) -Parent
}

function Get-Script-Invocation-Parameters-String {
    ($scriptInvocation.BoundParameters.Keys | ForEach-Object { if ($scriptInvocation.MyCommand.Parameters[$_].SwitchParameter) { "-" + $_ } else { "-" + $_ + " `"" + $scriptInvocation.BoundParameters[$_]  + "`""} }) -join " "
}

if ($DevelopmentEnvironmentPath -eq '')
{
    $DevelopmentEnvironmentPath = (Get-Script-Directory)
}

$gitBashExePath = (Join-Path -Path ${env:ProgramFiles} -ChildPath "Git\bin\sh.exe")
$sshKeyFileName = 'devvm'

# Helper fucntions

function Set-Permanent-User-Environment-Variable {
    param([Parameter(mandatory=$TRUE)][String]$Name, [Parameter(mandatory=$TRUE)][String]$Value)

    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    Set-Item -Path env:$Name -Value $Value
}

Set-Permanent-User-Environment-Variable -Name 'HOME' -Value $env:UserProfile

function Executable-Not-In-Path {
    param([Parameter(mandatory=$TRUE)][String]$ExecutableName)

    (Get-Command $ExecutableName -ErrorAction SilentlyContinue) -eq $null
}

function Reload-Path-Environment-Variable {
   $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Chocolatey-Package-Not-Installed {
    param([Parameter(mandatory=$TRUE)][String]$PackageName)

    (Get-Installed-Chocolatey-Packages | Where-Object { $_ -match "^$PackageName\s" } | Measure-Object).Count -eq 0
}

function Get-Installed-Chocolatey-Packages {
    (Invoke-External-Command-And-Return-Output chocolatey -Arguments @("list","-localonly"))[1]
}


function Invoke-External-Command {
    param([Parameter(mandatory=$TRUE)][String]$Executable, [Boolean]$IgnoreErrors=$FALSE, [String[]]$Arguments=@())

    &$Executable $Arguments | Out-Host
    $executableExitCode = $LastExitCode

    if (!$IgnoreErrors -and $executableExitCode -ne $null -and $executableExitCode -ne 0) {
        throw "A non-zero exit code ($executableExitCode) was thrown whilst executing '$executable $Arguments'"
    }
}

function Invoke-External-Command-And-Return-Output {
    param([Parameter(mandatory=$TRUE)][String]$Executable, [Boolean]$IgnoreErrors=$FALSE, [String[]]$Arguments=@())

    &$Executable $Arguments | Tee-Object -Variable executableOutput | Out-Null
    $executableExitCode = $LastExitCode

    if (!$IgnoreErrors -and $executableExitCode -ne $null -and $executableExitCode -ne 0) {
        throw "A non-zero exit code ($executableExitCode) was thrown whilst executing '$Executable $Arguments'"
    }

    return @($executableExitCode, $executableOutput)
}

function Invoke-Command-In-Git-Bash {
    param([Parameter(mandatory=$TRUE)][String]$CommandString)

    $changeDirectoryFlag = ('--cd="{0}"' -f (Get-Location))
    Invoke-External-Command $gitBashExePath -Arguments @($changeDirectoryFlag, '--login', '-c', ('"{0}"' -f $CommandString))
}

function Run-Vagrant-Subcommand-And-Return-Output {
    param([Parameter(mandatory=$TRUE)][String]$Subcommand, [Boolean]$IgnoreErrors=$FALSE, [String[]]$Arguments=@())

    Push-Location -Path $DevelopmentEnvironmentPath
    $output=(Invoke-External-Command-And-Return-Output -Executable vagrant -IgnoreErrors $IgnoreErrors -Arguments (, $Subcommand + $Arguments))
    Pop-Location

    $output
}

function Get-Unix-Path {
    param([Parameter(mandatory=$TRUE)][String]$AbsoluteWindowsPath)

    '/' + (($AbsoluteWindowsPath  -Replace ':', '' ) -Replace '\\', '/')
}

function Write-Info {
    param([Parameter(mandatory=$TRUE)][String]$message)
    Write-Host -ForegroundColor Magenta "`n$message"
}

# Set up funcs

function Install-Chocolatey {
    Write-Info "Installing Chocolatey..."
    Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
    Reload-Path-Environment-Variable
}

function Ensure-Chocolately-Installed {
    Write-Info "Checking Chocolatey..."
    if (Executable-Not-In-Path "chocolatey") {
        if (Current-Identity-Is-Non-Admin-Role) {
          Invoke-Script-In-Admin-Role
          exit
        }
        Install-Chocolatey
    }
}

function Ensure-Chocolately-Package-Installed {
    param([Parameter(mandatory=$TRUE)][String]$PackageName)

    Write-Info "Checking Chocolatey package $PackageName"
    if (Chocolatey-Package-Not-Installed $PackageName) {
        if (Current-Identity-Is-Non-Admin-Role) {
          Invoke-Script-In-Admin-Role
          exit
        }
        Install-Chocolatey-Package $PackageName
    }
}

function Install-Chocolatey-Package {
    param([Parameter(mandatory=$TRUE)][String]$PackageName)

    Write-Info "Installing chocolatey package '$PackageName'..."
    Invoke-External-Command chocolatey -Arguments @("install", "--yes", "--verbose", "$PackageName")
    Reload-Path-Environment-Variable
}

function Current-Identity-Is-Non-Admin-Role {
    $windowsIdentity = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    !$windowsIdentity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Script-In-Admin-Role {
    $scriptPath = (Get-Script-Path)
    $scriptInvocationCommand = "cd {0} && @powershell -ExecutionPolicy ByPass -NoProfile -File $scriptPath {1}" -f (Get-Location), (Get-Script-Invocation-Parameters-String)
    Start-Process -Verb RunAs -FilePath cmd -ArgumentList @("/k", $scriptInvocationCommand)
}

function Ensure-SSH-Key-Exists {
    $sshKeyFilePath = Join-Path -Path (Get-SSH-Configuration-Directory-Path) -ChildPath $sshKeyFileName

    if (Test-Path $sshKeyFilePath) {
        return
    }
    Generate-SSH-Key-At $sshKeyFilePath
}

function Get-SSH-Configuration-Directory-Path {
    return Join-Path -Path $env:UserProfile -ChildPath ".ssh"
}

function Generate-SSH-Key-At {
    param([Parameter(mandatory=$TRUE)][String]$sshKeyFilePath)

    Write-Info "Generating SSH key pair for use with Git..."
    Write-Info "Use your password vault to generate and store a strong passphrase."
    New-Item -ItemType Directory -Force -Path (Split-Path $sshKeyFilePath -Parent) | Out-Null
    Invoke-Command-In-Git-Bash ('ssh-keygen -t rsa -b 4096 -f "{0}"' -f (Get-Unix-Path $sshKeyFilePath))
    Write-Info "SSH key pair generated"
}

function Wait-For-User-To-Hit-Confirm {
    param([Parameter(mandatory=$TRUE)][String]$promptText)

    $title = ""
    $choices = [System.Management.Automation.Host.ChoiceDescription[]](New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Confirm 'yes' to the question")
    $defaultChoice = -1

    $result = $host.ui.PromptForChoice($title, $promptText, $choices, $defaultChoice)
}

function Update-Development-Environment-Repository {

    if ($SkipRepositoryUpdate)
    {
        return;
    }

    Write-Info "Updating repository..."
    $developmentEnvironmentPath = (Get-Location)
    Push-Location $developmentEnvironmentPath
    Invoke-External-Command git -Arguments ('pull','--rebase')
    Pop-Location
}

function Ensure-Vagrant-Plugins-Are-Up-To-Date {
    Write-Info "Ensuring installed Vagrant plugins are up to date..."
    Run-Vagrant-Subcommand plugin update
}

function Ensure-Vagrant-Box-Is-Up-To-Date {
    Write-Info "Ensuring installed Vagrant box is up to date..."
    Run-Vagrant-Subcommand box update
}

function Run-Vagrant-Subcommand {
    Push-Location -Path $DevelopmentEnvironmentPath
    Invoke-External-Command vagrant -Arguments $args
    Pop-Location
}

function Vagrant-Is-Running {
    Push-Location -Path $DevelopmentEnvironmentPath
    $vagrantStatusResult=(Run-Vagrant-Subcommand-And-Return-Output status -IgnoreErrors $TRUE)
    $vagrantStatusExitCode=$vagrantStatusResult[0]
    $vagrantStatusOutput=$vagrantStatusResult[1] -join "`n"
    Pop-Location

    $vagrantStatusExitCode -eq 0 -and $vagrantStatusOutput.Contains("running") -and !$vagrantStatusOutput.Contains("not running")
}

function Start-Virtual-Machine {
    if (Vagrant-Is-Running) {
      Write-Info "Provision virtual machine..."
      Run-Vagrant-Subcommand provision
    } else  {
      Write-Info "Starting virtual machine..."
      Run-Vagrant-Subcommand up
    }
}

# Run these steps

Ensure-Chocolately-Installed
Ensure-Chocolately-Package-Installed 'git'
Ensure-Chocolately-Package-Installed 'vagrant'
Ensure-Chocolately-Package-Installed 'openssh'
if (Current-Identity-Is-Non-Admin-Role) {
  Ensure-SSH-Key-Exists
  Update-Development-Environment-Repository
  Ensure-Vagrant-Plugins-Are-Up-To-Date
  Ensure-Vagrant-Box-Is-Up-To-Date
  Start-Virtual-Machine
} else {
  Write-Info "Skipping VM startup while installing packages, close admin shell and re-run when done"
}
