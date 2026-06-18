<#
.SYNOPSIS
Uploads Python package artifacts in a wheelhouse directory to a Nexus PyPI repository.

.DESCRIPTION
This script is intended for an internal network where the package artifacts were
already downloaded on an external network with "pip download".

It uploads .whl, .tar.gz, and .zip files by calling "python -m twine upload".
Credentials can be passed with PSCredential or provided through TWINE_USERNAME
and TWINE_PASSWORD environment variables.

.EXAMPLE
.\Upload-PypiPackagesToNexus.ps1 `
  -RepositoryUrl "https://nexus.example.com/repository/pypi-hosted/" `
  -WheelhousePath ".\wheelhouse" `
  -Credential (Get-Credential)

.EXAMPLE
$env:TWINE_USERNAME = "admin"
$env:TWINE_PASSWORD = "password"
.\Upload-PypiPackagesToNexus.ps1 -RepositoryUrl "https://nexus.example.com/repository/pypi-hosted/"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RepositoryUrl,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WheelhousePath = ".\wheelhouse",

    [Parameter()]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter()]
    [string]$Python = "python",

    [Parameter()]
    [switch]$SkipExisting,

    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

function Resolve-ExistingDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
    $item = Get-Item -LiteralPath $resolved.Path -ErrorAction Stop

    if (-not $item.PSIsContainer) {
        throw "WheelhousePath is not a directory: $($item.FullName)"
    }

    return $item.FullName
}

function Test-PythonModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonCommand,

        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    & $PythonCommand -c "import $ModuleName" 2>$null
    return ($LASTEXITCODE -eq 0)
}

$wheelhouse = Resolve-ExistingDirectory -Path $WheelhousePath

$packages = Get-ChildItem -LiteralPath $wheelhouse -File |
    Where-Object {
        $_.Name -like "*.whl" -or
        $_.Name -like "*.tar.gz" -or
        $_.Name -like "*.zip"
    } |
    Sort-Object Name

if (-not $packages) {
    throw "No uploadable Python package files were found in: $wheelhouse"
}

Write-Host "Nexus PyPI repository: $RepositoryUrl"
Write-Host "Wheelhouse: $wheelhouse"
Write-Host "Upload file count: $($packages.Count)"

if ($DryRun) {
    Write-Host ""
    Write-Host "Dry run only. Files that would be uploaded:"
    $packages | ForEach-Object { Write-Host " - $($_.Name)" }
    exit 0
}

if ($Credential) {
    $env:TWINE_USERNAME = $Credential.UserName
    $env:TWINE_PASSWORD = $Credential.GetNetworkCredential().Password
}

if (-not $env:TWINE_USERNAME) {
    throw "Username was not provided. Pass -Credential or set TWINE_USERNAME."
}

if (-not $env:TWINE_PASSWORD) {
    throw "Password was not provided. Pass -Credential or set TWINE_PASSWORD."
}

if (-not (Test-PythonModule -PythonCommand $Python -ModuleName "twine")) {
    throw @"
The Python module 'twine' is not available.

Install it in the internal network Python environment, or upload the twine package
and its dependencies to the environment first.

Example:
  $Python -m pip install twine
"@
}

$twineArgs = @(
    "-m", "twine", "upload",
    "--non-interactive",
    "--repository-url", $RepositoryUrl
)

if ($SkipExisting) {
    $twineArgs += "--skip-existing"
}

$twineArgs += $packages.FullName

& $Python @twineArgs

if ($LASTEXITCODE -ne 0) {
    throw "twine upload failed with exit code $LASTEXITCODE."
}

Write-Host "Upload completed."
