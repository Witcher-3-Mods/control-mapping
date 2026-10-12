param(
    [Parameter(Mandatory=$true)][string]$OutputPath,
    # Automatic: the mod folder plus install.exe and uninstall.exe. Manual: the mod folder alone, with no program in it, to be copied into the game's mods folder by hand.
    [ValidateSet('Automatic','Manual')][string]$Variant = 'Automatic',
    # Folder with install.exe and uninstall.exe, built by tools/Build-Witcher3ModsInstallers.ps1 (Automatic only). They are build output, not repository files.
    [string]$InstallerDirectory
)
$ErrorActionPreference = 'Stop'
$Witcher3ModsRoot = Split-Path $PSScriptRoot -Parent
$Witcher3ModsPackage = Join-Path $Witcher3ModsRoot 'src/modWitcher3ModsControlMapping'
$Witcher3ModsModName = 'modWitcher3ModsControlMapping'
$Witcher3ModsXmlRelative = 'bin/config/r4game/user_config_matrix/pc/witcher3modscontrolmapping.xml'
# The archive is extracted into the game directory: mods/<mod>/... and bin/config/... (the engine reads
# the config matrix only from <Game>/bin/config, never from the mod folder).
# Repository files of the package. The installers' sources (Common.cs, Install.cs, Uninstall.cs) stay in the repository: the ZIP carries only the built .exe files (Automatic).
$Witcher3ModsExpectedPackage = @('LICENSE','THIRD-PARTY-NOTICES.txt','README.md','content/blob0.bundle','content/metadata.store','content/scripts/local/Witcher3ModsControlMapping.ws','content/scripts/local/Witcher3ModsControlRows.ws')
$Witcher3ModsRepositoryOnly = @('Common.cs','Install.cs','Uninstall.cs')
$Witcher3ModsBuiltExpected = @(if ($Variant -eq 'Automatic') { 'install.exe'; 'uninstall.exe' })
$Witcher3ModsExpected = @($Witcher3ModsExpectedPackage + $Witcher3ModsBuiltExpected | ForEach-Object { "mods/$Witcher3ModsModName/$_" }) + @($Witcher3ModsXmlRelative)
if ((Get-FileHash "$Witcher3ModsRoot/LICENSE").Hash -ne (Get-FileHash "$Witcher3ModsPackage/LICENSE").Hash) { throw 'Root and packaged licenses differ.' }
if ((Get-FileHash "$Witcher3ModsRoot/THIRD-PARTY-NOTICES.txt").Hash -ne (Get-FileHash "$Witcher3ModsPackage/THIRD-PARTY-NOTICES.txt").Hash) { throw 'Root and packaged notices differ.' }
if ((Get-Content "$Witcher3ModsPackage/THIRD-PARTY-NOTICES.txt" -Raw).Length -lt 100) { throw 'Missing third-party notices.' }
if ($Variant -eq 'Automatic') {
    if (-not $InstallerDirectory) { throw 'The Automatic package needs -InstallerDirectory.' }
    $Witcher3ModsInstallers = [IO.Path]::GetFullPath($InstallerDirectory)
}
# Where each ZIP member comes from: repository files for the sources, the build output for the .exe files.
$Witcher3ModsSources = @{}
foreach ($Witcher3ModsMember in $Witcher3ModsExpectedPackage) { $Witcher3ModsSources["mods/$Witcher3ModsModName/$Witcher3ModsMember"] = Join-Path $Witcher3ModsPackage $Witcher3ModsMember }
foreach ($Witcher3ModsBuilt in $Witcher3ModsBuiltExpected) { $Witcher3ModsSources["mods/$Witcher3ModsModName/$Witcher3ModsBuilt"] = Join-Path $Witcher3ModsInstallers $Witcher3ModsBuilt }
$Witcher3ModsSources[$Witcher3ModsXmlRelative] = Join-Path $Witcher3ModsPackage $Witcher3ModsXmlRelative
foreach ($Witcher3ModsKey in @($Witcher3ModsSources.Keys)) { $Witcher3ModsSources[$Witcher3ModsKey] = [IO.Path]::GetFullPath($Witcher3ModsSources[$Witcher3ModsKey]) }
# Every file under the package folder must be one of the expected members or one of the installers' sources: nothing else can slip into a release.
foreach ($Witcher3ModsItem in @(Get-Item $Witcher3ModsPackage) + @(Get-ChildItem $Witcher3ModsPackage -Recurse -Force)) {
    if ($Witcher3ModsItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Packages must not contain symlinks/junctions.' }
}
$Witcher3ModsRepositoryPaths = @($Witcher3ModsRepositoryOnly | ForEach-Object { [IO.Path]::GetFullPath((Join-Path $Witcher3ModsPackage $_)) })
$Witcher3ModsPackageSources = @($Witcher3ModsExpectedPackage | ForEach-Object { [IO.Path]::GetFullPath((Join-Path $Witcher3ModsPackage $_)) }) + @([IO.Path]::GetFullPath((Join-Path $Witcher3ModsPackage $Witcher3ModsXmlRelative)))
foreach ($Witcher3ModsFile in @(Get-ChildItem -LiteralPath $Witcher3ModsPackage -Recurse -Force -File)) {
    if ($Witcher3ModsFile.Length -eq 0 -or ($Witcher3ModsFile.FullName -notin $Witcher3ModsPackageSources -and $Witcher3ModsFile.FullName -notin $Witcher3ModsRepositoryPaths)) { throw "Unexpected or empty member: $($Witcher3ModsFile.FullName)" }
}
foreach ($Witcher3ModsMember in $Witcher3ModsExpected) {
    if (-not (Test-Path -LiteralPath $Witcher3ModsSources[$Witcher3ModsMember] -PathType Leaf) -or (Get-Item -LiteralPath $Witcher3ModsSources[$Witcher3ModsMember]).Length -eq 0) { throw "Missing package file: $Witcher3ModsMember" }
}
$Witcher3ModsOutput = [IO.Path]::GetFullPath($OutputPath)
if ($Witcher3ModsOutput.StartsWith($Witcher3ModsRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -and -not $Witcher3ModsOutput.StartsWith((Join-Path $Witcher3ModsRoot '.build') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Archive output must be outside the sources (use .build or a temp folder).' }
if (Test-Path -LiteralPath $Witcher3ModsOutput) { throw 'Refusing to overwrite an existing archive.' }
New-Item -ItemType Directory -Force (Split-Path $Witcher3ModsOutput -Parent) | Out-Null
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$Witcher3ModsZip = [IO.Compression.ZipFile]::Open($Witcher3ModsOutput, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($Witcher3ModsMember in $Witcher3ModsExpected) {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Witcher3ModsZip, $Witcher3ModsSources[$Witcher3ModsMember], $Witcher3ModsMember, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $Witcher3ModsZip.Dispose() }
# Every member is checked against an exact list, so the Manual package cannot contain an .exe.
$Witcher3ModsZip = [IO.Compression.ZipFile]::OpenRead($Witcher3ModsOutput)
try {
    $Witcher3ModsMembers = @($Witcher3ModsZip.Entries | Where-Object { $_.Name })
    if ($Witcher3ModsMembers.Count -ne $Witcher3ModsExpected.Count) { throw 'Archive member count mismatch.' }
    foreach ($Witcher3ModsMember in $Witcher3ModsMembers) {
        $Witcher3ModsRelative = $Witcher3ModsMember.FullName.Replace('\','/')
        if ($Witcher3ModsRelative -notin $Witcher3ModsExpected) { throw 'Unexpected ZIP path.' }
        $Witcher3ModsStream = $Witcher3ModsMember.Open()
        $Witcher3ModsSha = [Security.Cryptography.SHA256]::Create()
        try { $Witcher3ModsHash = [BitConverter]::ToString($Witcher3ModsSha.ComputeHash($Witcher3ModsStream)).Replace('-','') }
        finally { $Witcher3ModsStream.Dispose(); $Witcher3ModsSha.Dispose() }
        if ($Witcher3ModsHash -ne (Get-FileHash $Witcher3ModsSources[$Witcher3ModsRelative]).Hash) { throw 'ZIP byte verification failed.' }
    }
} finally { $Witcher3ModsZip.Dispose() }
Write-Output "Verified $Variant release ZIP: $Witcher3ModsOutput"
