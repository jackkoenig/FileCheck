# Taken from https://github.com/llvm/circt/blob/467cd20347fe520fa311c268d17798b22e099d90/utils/find-vs.ps1
# Find and enter a Visual Studio development environment.
# Required to use Ninja instead of msbuild on our build agents.
function Enter-VsDevEnv {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Prerelease,
        [Parameter()]
        [string]$architecture = "x64"
    )

    $ErrorActionPreference = 'Stop'

    if ($null -eq (Get-InstalledModule -name 'VSSetup' -ErrorAction SilentlyContinue)) {
        Install-Module -Name 'VSSetup' -Scope CurrentUser -SkipPublisherCheck -Force
    }
    Import-Module -Name 'VSSetup'

    Write-Verbose 'Searching for VC++ instances'
    $vsinfo = `
        Get-VSSetupInstance  -All -Prerelease:$Prerelease `
    | Select-VSSetupInstance `
        -Latest -Product * `
        -Require 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64'

    $vspath = $vsinfo.InstallationPath

    switch ($env:PROCESSOR_ARCHITECTURE) {
        "amd64" { $hostarch = "x64" }
        "x86" { $hostarch = "x86" }
        "arm64" { $hostarch = "arm64" }
        default { throw "Unknown architecture: $switch" }
    }

    $devShellModule = "$vspath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"

    Import-Module -Global -Name $devShellModule

    Write-Verbose 'Setting up environment variables'
    Enter-VsDevShell -VsInstanceId $vsinfo.InstanceId  -SkipAutomaticLocation `
        -devCmdArguments "-arch=$architecture -host_arch=$hostarch"

    Set-Item -Force -path "Env:\Platform" -Value $architecture

    remove-Module Microsoft.VisualStudio.DevShell, VSSetup
}

Enter-VsDevEnv
