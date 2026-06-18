<#
.SYNOPSIS
wheelhouse 폴더의 Python 패키지 파일을 Nexus PyPI 저장소에 업로드한다.

.DESCRIPTION
외부망에서 "pip download"로 미리 내려받은 패키지 파일을 내부망 Nexus에
업로드할 때 사용하는 스크립트다.

".whl", ".tar.gz", ".zip" 파일을 찾아 "python -m twine upload"로 업로드한다.
인증 정보는 PSCredential로 전달하거나 TWINE_USERNAME, TWINE_PASSWORD 환경
변수로 제공할 수 있다.

이미 Nexus에 있는 파일은 기본으로 건너뛴다. 기존 파일 업로드를 다시
시도하려면 -OverwriteExisting 옵션을 사용한다.

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
    [switch]$OverwriteExisting,

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
    throw "업로드 가능한 Python 패키지 파일을 찾지 못했습니다: $wheelhouse"
}

Write-Host "Nexus PyPI 저장소: $RepositoryUrl"
Write-Host "wheelhouse 경로: $wheelhouse"
Write-Host "업로드 대상 파일 수: $($packages.Count)"

if ($DryRun) {
    Write-Host ""
    Write-Host "Dry run 모드입니다. 실제 업로드는 하지 않고 대상 파일만 표시합니다:"
    $packages | ForEach-Object { Write-Host " - $($_.Name)" }
    exit 0
}

if ($Credential) {
    $env:TWINE_USERNAME = $Credential.UserName
    $env:TWINE_PASSWORD = $Credential.GetNetworkCredential().Password
}

if (-not $env:TWINE_USERNAME) {
    throw "사용자명이 없습니다. -Credential을 전달하거나 TWINE_USERNAME을 설정하세요."
}

if (-not $env:TWINE_PASSWORD) {
    throw "비밀번호가 없습니다. -Credential을 전달하거나 TWINE_PASSWORD를 설정하세요."
}

if (-not (Test-PythonModule -PythonCommand $Python -ModuleName "twine")) {
    throw @"
Python 모듈 'twine'을 사용할 수 없습니다.

내부망 Python 환경에 twine을 먼저 설치하거나, twine 패키지와 의존성을
내부망 환경에 먼저 업로드/설치하세요.

예시:
  $Python -m pip install twine
"@
}

$twineArgs = @(
    "-m", "twine", "upload",
    "--non-interactive",
    "--repository-url", $RepositoryUrl
)

if (-not $OverwriteExisting) {
    $twineArgs += "--skip-existing"
}

$twineArgs += $packages.FullName

& $Python @twineArgs

if ($LASTEXITCODE -ne 0) {
    throw "twine upload가 실패했습니다. 종료 코드: $LASTEXITCODE"
}

Write-Host "업로드가 완료되었습니다."
