param(
    [Parameter(Mandatory=$true)][string]$OutputPath,
    # Automatic: the mod plus install.cmd and uninstall.cmd. Manual: the mod alone, with no script in it, to be copied into the game folder by hand.
    [ValidateSet('Automatic','Manual')][string]$Variant = 'Automatic'
)
$ErrorActionPreference = 'Stop'
$Witcher3ModsRoot = Split-Path $PSScriptRoot -Parent
$Witcher3ModsPackage = Join-Path $Witcher3ModsRoot 'src/modWitcher3ModsControlMapping'
# Top-level folder inside the ZIP, and so in the game's mods folder. The mod000_ prefix makes the game load it before other mods, so its patched Flash wins over mods that replace the same file. The repository folder keeps its name.
$Witcher3ModsModName = 'mod000_Witcher3ModsControlMapping'
$Witcher3ModsXmlRelative = 'bin/config/r4game/user_config_matrix/pc/witcher3modscontrolmapping.xml'
# The archive is extracted into the game directory: mods/<mod>/... and bin/config/... (the engine reads
# the config matrix only from <Game>/bin/config, never from the mod folder).
$Witcher3ModsMod = @('LICENSE','THIRD-PARTY-NOTICES.txt','README.md','content/blob0.bundle','content/metadata.store','content/scripts/local/Witcher3ModsControlMapping.ws','content/scripts/local/Witcher3ModsControlRows.ws')
$Witcher3ModsScripts = @('install.cmd','uninstall.cmd')
# The installer scripts are in the repository package either way; only the Automatic ZIP carries them.
$Witcher3ModsExpectedPackage = @($Witcher3ModsMod + $(if ($Variant -eq 'Automatic') { $Witcher3ModsScripts }))
$Witcher3ModsExpected = @($Witcher3ModsExpectedPackage | ForEach-Object { "mods/$Witcher3ModsModName/$_" }) + @($Witcher3ModsXmlRelative)
if ((Get-FileHash "$Witcher3ModsRoot/LICENSE").Hash -ne (Get-FileHash "$Witcher3ModsPackage/LICENSE").Hash) { throw 'Root and packaged licenses differ.' }
if ((Get-FileHash "$Witcher3ModsRoot/THIRD-PARTY-NOTICES.txt").Hash -ne (Get-FileHash "$Witcher3ModsPackage/THIRD-PARTY-NOTICES.txt").Hash) { throw 'Root and packaged notices differ.' }
if ((Get-Content "$Witcher3ModsPackage/THIRD-PARTY-NOTICES.txt" -Raw).Length -lt 100) { throw 'Missing third-party notices.' }
$Witcher3ModsSources = @{}
foreach ($Witcher3ModsMember in $Witcher3ModsExpectedPackage) { $Witcher3ModsSources["mods/$Witcher3ModsModName/$Witcher3ModsMember"] = [IO.Path]::GetFullPath((Join-Path $Witcher3ModsPackage $Witcher3ModsMember)) }
$Witcher3ModsSources[$Witcher3ModsXmlRelative] = [IO.Path]::GetFullPath((Join-Path $Witcher3ModsPackage $Witcher3ModsXmlRelative))
# Every file under the package folder must be a known member, so nothing else can slip into a release.
$Witcher3ModsKnown = @($Witcher3ModsMod + $Witcher3ModsScripts + @($Witcher3ModsXmlRelative) | ForEach-Object { [IO.Path]::GetFullPath((Join-Path $Witcher3ModsPackage $_)) })
foreach ($Witcher3ModsItem in @(Get-Item $Witcher3ModsPackage) + @(Get-ChildItem $Witcher3ModsPackage -Recurse -Force)) {
    if ($Witcher3ModsItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Packages must not contain symlinks/junctions.' }
}
foreach ($Witcher3ModsFile in @(Get-ChildItem -LiteralPath $Witcher3ModsPackage -Recurse -Force -File)) {
    if ($Witcher3ModsFile.Length -eq 0 -or $Witcher3ModsFile.FullName -notin $Witcher3ModsKnown) { throw "Unexpected or empty member: $($Witcher3ModsFile.FullName)" }
}
foreach ($Witcher3ModsMember in $Witcher3ModsExpected) { if (-not (Test-Path -LiteralPath $Witcher3ModsSources[$Witcher3ModsMember] -PathType Leaf)) { throw "Missing package file: $Witcher3ModsMember" } }
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
# Every member is checked against an exact list, so the Manual package cannot contain a script.
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
