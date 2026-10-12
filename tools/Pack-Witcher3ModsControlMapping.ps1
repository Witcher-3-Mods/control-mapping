param(
    [Parameter(Mandatory=$true)][string]$RedkitPath,
    [Parameter(Mandatory=$true)][string]$FlashSwf,
    [switch]$AllowRedkitScratch
)
$ErrorActionPreference = 'Stop'
if (-not $AllowRedkitScratch) { throw 'Pass -AllowRedkitScratch to authorize the temporary REDkit import resource. This never installs into the game.' }
$Witcher3ModsRoot = Split-Path $PSScriptRoot -Parent
$Witcher3ModsRedkit = (Resolve-Path -LiteralPath $RedkitPath).Path
$Witcher3ModsSwf = (Resolve-Path -LiteralPath $FlashSwf).Path
$Witcher3ModsAllowedBuild = [IO.Path]::GetFullPath((Join-Path $Witcher3ModsRoot '.build')) + [IO.Path]::DirectorySeparatorChar
if (-not $Witcher3ModsSwf.StartsWith($Witcher3ModsAllowedBuild, [StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($Witcher3ModsSwf) -ne 'panel_ingamemenu.swf') { throw 'Expected the exact locally built panel_ingamemenu.swf under .build.' }
$Witcher3ModsBin = Join-Path $Witcher3ModsRedkit 'bin'
$Witcher3ModsRelative = 'gameplay/gui_new/swf/mainmenu/panel_ingamemenu.redswf'
$Witcher3ModsScratch = [IO.Path]::GetFullPath((Join-Path $Witcher3ModsBin $Witcher3ModsRelative))
$Witcher3ModsScratchRoot = [IO.Path]::GetFullPath((Join-Path $Witcher3ModsBin 'gameplay')) + [IO.Path]::DirectorySeparatorChar
if (-not $Witcher3ModsScratch.StartsWith($Witcher3ModsScratchRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Scratch path escaped REDkit/bin/gameplay.' }
if (Test-Path -LiteralPath $Witcher3ModsScratch) { throw "Preserve existing scratch resource: $Witcher3ModsScratch" }
$Witcher3ModsRun = Join-Path $Witcher3ModsRoot ('.build/package-controls-' + [Guid]::NewGuid().ToString('N'))
$Witcher3ModsPackage = Join-Path $Witcher3ModsRoot 'src/modWitcher3ModsControlMapping'
if (-not (Test-Path -LiteralPath "$Witcher3ModsPackage/THIRD-PARTY-NOTICES.txt")) { throw 'Missing package notices.' }
New-Item -ItemType Directory -Path $Witcher3ModsRun | Out-Null
$Witcher3ModsScratchHash = ''
function Invoke-Witcher3ModsControlWcc([string]$Witcher3ModsStep, [string[]]$Witcher3ModsArguments) {
    Write-Output "REDkit: $Witcher3ModsStep"
    & (Join-Path $Witcher3ModsBin 'x64_RedKit/wcc_lite.exe') @Witcher3ModsArguments "-wcclog=$Witcher3ModsRun/$Witcher3ModsStep.log" 2>&1 |
        Out-File -LiteralPath "$Witcher3ModsRun/$Witcher3ModsStep-console.log" -Encoding UTF8
    if ($LASTEXITCODE -ne 0) { throw "REDkit failed: $Witcher3ModsRun/$Witcher3ModsStep-console.log" }
}
Push-Location (Join-Path $Witcher3ModsBin 'x64_RedKit')
try {
    Invoke-Witcher3ModsControlWcc 'import' @('import', '-depot=local', "-file=$Witcher3ModsSwf", "-out=$Witcher3ModsRelative")
    if (-not (Test-Path -LiteralPath $Witcher3ModsScratch)) { throw 'Importer did not create the expected resource.' }
    $Witcher3ModsBackup = Join-Path "$Witcher3ModsRun/depot" $Witcher3ModsRelative
    New-Item -ItemType Directory -Force (Split-Path $Witcher3ModsBackup -Parent) | Out-Null
    Copy-Item -LiteralPath $Witcher3ModsScratch -Destination $Witcher3ModsBackup
    $Witcher3ModsExpectedHash = (Get-FileHash -LiteralPath $Witcher3ModsScratch).Hash
    if ($Witcher3ModsExpectedHash -ne (Get-FileHash -LiteralPath $Witcher3ModsBackup).Hash) { throw 'Scratch backup mismatch.' }
    $Witcher3ModsScratchHash = $Witcher3ModsExpectedHash
    Invoke-Witcher3ModsControlWcc 'cook' @('cook', '-platform=pc', "-file=$Witcher3ModsRelative", "-outdir=$Witcher3ModsRun/cooked/")
    Invoke-Witcher3ModsControlWcc 'pack' @('pack', "-dir=$Witcher3ModsRun/cooked/", "-outdir=$Witcher3ModsRun/packed/")
    Invoke-Witcher3ModsControlWcc 'metadata' @('metadatastore', "-path=$Witcher3ModsRun/packed/")
    Invoke-Witcher3ModsControlWcc 'unbundle' @('unbundle', "-dir=$Witcher3ModsRun/packed/", "-outdir=$Witcher3ModsRun/unpacked/")
    if (@(Get-ChildItem -LiteralPath "$Witcher3ModsRun/unpacked" -Recurse -File -Force).Count -ne 1) { throw 'Bundle must contain only the intended menu resource.' }
    if ((Get-FileHash -LiteralPath "$Witcher3ModsRun/cooked/$Witcher3ModsRelative").Hash -ne (Get-FileHash -LiteralPath "$Witcher3ModsRun/unpacked/$Witcher3ModsRelative").Hash) { throw 'Bundle roundtrip mismatch.' }
    foreach ($Witcher3ModsName in @('blob0.bundle', 'metadata.store')) {
        if ((Get-Item -LiteralPath "$Witcher3ModsRun/packed/$Witcher3ModsName").Length -eq 0) { throw "Empty output: $Witcher3ModsName" }
    }
    New-Item -ItemType Directory -Force "$Witcher3ModsPackage/content" | Out-Null
    foreach ($Witcher3ModsName in @('blob0.bundle', 'metadata.store')) {
        $Witcher3ModsTarget = "$Witcher3ModsPackage/content/$Witcher3ModsName"
        if (Test-Path -LiteralPath $Witcher3ModsTarget) {
            New-Item -ItemType Directory -Force "$Witcher3ModsRun/previous-package" | Out-Null
            Copy-Item -LiteralPath $Witcher3ModsTarget -Destination "$Witcher3ModsRun/previous-package/$Witcher3ModsName"
            if ((Get-FileHash -LiteralPath $Witcher3ModsTarget).Hash -ne (Get-FileHash -LiteralPath "$Witcher3ModsRun/previous-package/$Witcher3ModsName").Hash) { throw 'Previous package backup mismatch.' }
        }
        Copy-Item -LiteralPath "$Witcher3ModsRun/packed/$Witcher3ModsName" -Destination $Witcher3ModsTarget
        if ((Get-FileHash -LiteralPath $Witcher3ModsTarget).Hash -ne (Get-FileHash -LiteralPath "$Witcher3ModsRun/packed/$Witcher3ModsName").Hash) { throw 'Package copy mismatch.' }
    }
    Copy-Item -LiteralPath "$Witcher3ModsRoot/LICENSE" -Destination "$Witcher3ModsPackage/LICENSE"
    if ((Get-FileHash -LiteralPath "$Witcher3ModsRoot/LICENSE").Hash -ne (Get-FileHash -LiteralPath "$Witcher3ModsPackage/LICENSE").Hash) { throw 'License copy mismatch.' }
    Write-Output "Control mapping packaged: $Witcher3ModsPackage (SWF bundle only; scripts and bin/config are maintained in place). Not installed. Logs: $Witcher3ModsRun"
} finally {
    Pop-Location
    if ($Witcher3ModsScratchHash -and (Test-Path -LiteralPath $Witcher3ModsScratch)) {
        if ((Get-FileHash -LiteralPath $Witcher3ModsScratch).Hash -eq $Witcher3ModsScratchHash) {
            Remove-Item -LiteralPath $Witcher3ModsScratch
            Write-Output "Removed generated REDkit scratch file; recoverable copy: $Witcher3ModsBackup"
        } else { Write-Warning "Scratch resource changed; preserved: $Witcher3ModsScratch" }
    }
}
