# End-to-end test of install.cmd and uninstall.cmd against a fake game folder. The scripts are started the way a double-click
# starts them (cmd.exe /c, with the script's own folder as the working directory); what they did is read from the files,
# because a batch file that leaves through "(goto)" does not report PowerShell's exit code.
# Covers: install and overwrite (mod folder and config XML), install from the installed copy itself (a ZIP extracted into the
# game folder), uninstall from inside the mod folder (the whole folder must go, the junction target must survive), the
# controls-reset question and /resetcontrols, answering the confirmation, cancelling, uninstall from the extracted download,
# nothing installed, and a folder that is not a game.
$ErrorActionPreference = 'Stop'
$Witcher3ModsRoot = Split-Path $PSScriptRoot -Parent
$Witcher3ModsPackage = Join-Path $Witcher3ModsRoot 'src/modWitcher3ModsControlMapping'
$Witcher3ModsModName = 'mod000_Witcher3ModsControlMapping'
$Witcher3ModsFormerName = 'modWitcher3ModsControlMapping'
$Witcher3ModsXmlRelative = 'bin\config\r4game\user_config_matrix\pc\witcher3modscontrolmapping.xml'
# The work folder is kept short: Windows PowerShell 5.1 and cmd.exe reject long paths.
$Witcher3ModsWork = Join-Path ([IO.Path]::GetTempPath()) ('w3m-test-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))

function Assert-Witcher3Mods([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "Test failed: $Message" }
    Write-Output "ok: $Message"
}
# Runs a .cmd like a double-click does. $Typed is what the user types, handed over as a file of raw ASCII bytes (writing through
# Process.StandardInput would put a UTF-8 byte order mark in front of the first answer). Returns everything the script printed.
function Invoke-Witcher3ModsScript([string]$Script, [string]$Arguments, [string]$Typed = '') {
    $inputFile = Join-Path $Witcher3ModsWork ('in-' + [Guid]::NewGuid().ToString('N') + '.txt')
    $outputFile = Join-Path $Witcher3ModsWork ('out-' + [Guid]::NewGuid().ToString('N') + '.txt')
    [IO.File]::WriteAllBytes($inputFile, [Text.Encoding]::ASCII.GetBytes($Typed))
    # cmd /c drops the outer pair of quotes, so the script path can be quoted inside them.
    $commandLine = '/c ""' + $Script + '" ' + $Arguments + '"'
    $process = Start-Process -FilePath $env:ComSpec -ArgumentList $commandLine -WorkingDirectory (Split-Path $Script -Parent) -RedirectStandardInput $inputFile -RedirectStandardOutput $outputFile -Wait -PassThru -WindowStyle Hidden
    $reader = New-Object IO.StreamReader (New-Object IO.FileStream $outputFile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::ReadWrite))
    try { $output = $reader.ReadToEnd() } finally { $reader.Dispose() }
    return $output
}

try {
    $game = Join-Path $Witcher3ModsWork 'game'
    $docs = Join-Path $Witcher3ModsWork 'docs'
    # The release ZIP is extracted into a folder that looks like the game folder: mods\<mod>\... and bin\config\...
    $download = Join-Path $Witcher3ModsWork 'download'
    $downloadMod = "$download\mods\$Witcher3ModsModName"
    foreach ($dir in @("$game\bin\config\r4game", "$game\content\content0", "$game\mods\modOtherMod", "$game\mods\$Witcher3ModsFormerName", $docs, "$downloadMod\content", (Split-Path "$download\$Witcher3ModsXmlRelative" -Parent))) { New-Item -ItemType Directory -Force $dir | Out-Null }
    Set-Content -LiteralPath "$game\mods\modOtherMod\keep.txt" -Value 'other mod'
    Set-Content -LiteralPath "$game\mods\$Witcher3ModsFormerName\old.txt" -Value 'copy under the former folder name'
    Set-Content -LiteralPath "$downloadMod\content\blob0.bundle" -Value 'bundle'
    Set-Content -LiteralPath "$download\$Witcher3ModsXmlRelative" -Value '<redxml/>'
    foreach ($name in 'install.cmd', 'uninstall.cmd') { Copy-Item "$Witcher3ModsPackage\$name" $downloadMod }
    $settings = "$docs\user.settings"
    [IO.File]::WriteAllText($settings, "[Video]`r`nBrightness=1`r`n[Witcher3ModsPadInput]`r`nSwap=1`r`n[Witcher3ModsPadStore]`r`nStored=2`r`n[Audio]`r`nVolume=7`r`n", [Text.Encoding]::GetEncoding(28591))
    $inputSettings = "$docs\input.settings"
    Set-Content -LiteralPath $inputSettings -Value 'my bindings'
    $mod = "$game\mods\$Witcher3ModsModName"
    $xml = "$game\$Witcher3ModsXmlRelative"
    $gameArgument = '/game:"' + $game + '"'
    $docsArgument = '/docs:"' + $docs + '"'

    # One game must be listed once: a folder written the way the Steam registry stores it (lowercase, forward slashes) has to come
    # back with the casing stored on disk, or the same game appears twice. The function is read out of each script itself, not copied,
    # and the script must really use it when it builds the list of game folders.
    foreach ($name in 'install.cmd', 'uninstall.cmd') {
        $scriptText = [IO.File]::ReadAllText("$Witcher3ModsPackage\$name")
        $scriptBody = $scriptText.Substring($scriptText.IndexOf('#POWERSHELL'))
        $parseErrors = $null
        $tokens = $null
        $tree = [Management.Automation.Language.Parser]::ParseInput($scriptBody, [ref]$tokens, [ref]$parseErrors)
        $function = $tree.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-DiskCasePath' }, $true)
        Assert-Witcher3Mods (($parseErrors.Count -eq 0) -and ($null -ne $function)) "$name parses and defines Get-DiskCasePath"
        . ([scriptblock]::Create($function.Extent.Text))
        $storedPath = Join-Path $env:SystemRoot 'System32'
        $registryStyle = $storedPath.ToLowerInvariant().Replace('\', '/')
        Assert-Witcher3Mods ((Get-DiskCasePath $registryStyle) -ceq (Get-DiskCasePath $storedPath)) "$name writes a registry-style path with the casing stored on disk"
        Assert-Witcher3Mods (([regex]::Matches($scriptBody, 'Get-DiskCasePath')).Count -ge 2) "$name uses Get-DiskCasePath when it lists the game folders"
    }

    # Install into the fake game: the mod folder and the config XML, once clean and once over an existing copy.
    $output = Invoke-Witcher3ModsScript "$downloadMod\install.cmd" "/yes $gameArgument"
    Assert-Witcher3Mods ($output -match 'was installed') 'install.cmd reports success'
    Assert-Witcher3Mods (Test-Path -LiteralPath "$mod\content\blob0.bundle") 'install.cmd copied the mod'
    Assert-Witcher3Mods (Test-Path -LiteralPath $xml) 'install.cmd put the config XML into bin\config'
    Assert-Witcher3Mods (-not (Test-Path -LiteralPath "$game\mods\$Witcher3ModsFormerName")) 'the copy under the former folder name was removed'
    Assert-Witcher3Mods ((Test-Path -LiteralPath "$mod\install.cmd") -and (Test-Path -LiteralPath "$mod\uninstall.cmd")) 'the installed mod carries both scripts'
    Assert-Witcher3Mods (Test-Path -LiteralPath "$game\mods\modOtherMod\keep.txt") 'another mod was not touched'
    $output = Invoke-Witcher3ModsScript "$downloadMod\install.cmd" "/yes $gameArgument"
    Assert-Witcher3Mods (($output -match 'was installed') -and (Test-Path -LiteralPath $xml)) 'installing over an existing copy works'
    # Run from the installed copy itself, with no /game (a ZIP extracted into the game folder): the XML is already in place.
    $output = Invoke-Witcher3ModsScript "$mod\install.cmd" '/yes'
    Assert-Witcher3Mods (($output -match 'was installed') -and (Test-Path -LiteralPath $xml) -and (Test-Path -LiteralPath "$mod\content\blob0.bundle")) 'install.cmd run from inside the game folder works'

    # A junction inside the mod folder must be removed as a link, never followed.
    $outside = Join-Path $Witcher3ModsWork 'outside'
    New-Item -ItemType Directory -Force $outside | Out-Null
    Set-Content -LiteralPath "$outside\canary.txt" -Value 'must survive'
    New-Item -ItemType Junction -Path "$mod\link" -Target $outside | Out-Null

    # Uninstall the way a user does: double-click uninstall.cmd inside the mod folder. /yes does not reset the controls.
    $output = Invoke-Witcher3ModsScript "$mod\uninstall.cmd" "/yes $docsArgument"
    Assert-Witcher3Mods ($output -match 'was uninstalled') 'uninstall.cmd run from the mod folder reports success'
    Assert-Witcher3Mods (-not (Test-Path -LiteralPath $mod)) 'the whole mod folder is gone, uninstall.cmd included'
    Assert-Witcher3Mods (-not (Test-Path -LiteralPath $xml)) 'the config XML is gone'
    Assert-Witcher3Mods (Test-Path -LiteralPath "$outside\canary.txt") 'the junction target was not touched'
    Assert-Witcher3Mods (Test-Path -LiteralPath "$game\mods\modOtherMod\keep.txt") 'another mod was not touched'
    $text = [IO.File]::ReadAllText($settings, [Text.Encoding]::GetEncoding(28591))
    Assert-Witcher3Mods (($text -notmatch 'Witcher3ModsPad(Input|Store)') -and ($text -match 'Brightness=1') -and ($text -match 'Volume=7')) 'only the mod sections (PadInput and PadStore) left user.settings'
    Assert-Witcher3Mods (@(Get-ChildItem $docs -Filter 'user.settings.bak-uninstall-*').Count -eq 1) 'a backup of user.settings was made'
    Assert-Witcher3Mods (Test-Path -LiteralPath $inputSettings) 'input.settings was not touched without /resetcontrols'

    # Answering the questions. Order: "Reset controls? [y/N]", "Continue? [Y/n]", then the "Press Enter to close" line.
    # Reset no and cancel: nothing changes.
    $null = Invoke-Witcher3ModsScript "$downloadMod\install.cmd" "/yes $gameArgument"
    $output = Invoke-Witcher3ModsScript "$mod\uninstall.cmd" $docsArgument "n`r`nn`r`n`r`n"
    Assert-Witcher3Mods (($output -match 'Cancelled') -and (Test-Path -LiteralPath "$mod\content\blob0.bundle") -and (Test-Path -LiteralPath $inputSettings)) 'answering n and n cancels and changes nothing'
    # Reset yes and continue: the mod goes and input.settings is moved aside.
    $output = Invoke-Witcher3ModsScript "$mod\uninstall.cmd" $docsArgument "y`r`ny`r`n`r`n"
    Assert-Witcher3Mods (($output -match 'was uninstalled') -and (-not (Test-Path -LiteralPath $mod))) 'answering y and y uninstalls'
    Assert-Witcher3Mods ((-not (Test-Path -LiteralPath $inputSettings)) -and (@(Get-ChildItem $docs -Filter 'input.settings.bak-uninstall-*').Count -eq 1)) 'answering y reset the controls and kept a copy of input.settings'
    # Reset no and continue: the mod goes, input.settings stays.
    Set-Content -LiteralPath $inputSettings -Value 'my bindings'
    $null = Invoke-Witcher3ModsScript "$downloadMod\install.cmd" "/yes $gameArgument"
    $output = Invoke-Witcher3ModsScript "$mod\uninstall.cmd" $docsArgument "n`r`ny`r`n`r`n"
    Assert-Witcher3Mods (($output -match 'was uninstalled') -and (-not (Test-Path -LiteralPath $mod)) -and (Test-Path -LiteralPath $inputSettings)) 'answering n and y uninstalls and leaves input.settings alone'
    # /yes together with /resetcontrols resets without asking.
    $null = Invoke-Witcher3ModsScript "$downloadMod\install.cmd" "/yes $gameArgument"
    $output = Invoke-Witcher3ModsScript "$mod\uninstall.cmd" "/yes /resetcontrols $docsArgument"
    Assert-Witcher3Mods ((-not (Test-Path -LiteralPath $mod)) -and (-not (Test-Path -LiteralPath $inputSettings)) -and (@(Get-ChildItem $docs -Filter 'input.settings.bak-uninstall-*').Count -eq 2)) '/yes /resetcontrols resets the controls without asking'

    # Uninstall from the extracted download: finds the installed mod through /game, removes it and its XML, keeps the download.
    $null = Invoke-Witcher3ModsScript "$downloadMod\install.cmd" "/yes $gameArgument"
    $output = Invoke-Witcher3ModsScript "$downloadMod\uninstall.cmd" "/yes $gameArgument $docsArgument"
    Assert-Witcher3Mods (($output -match 'was uninstalled') -and (-not (Test-Path -LiteralPath $mod)) -and (-not (Test-Path -LiteralPath $xml)) -and (Test-Path -LiteralPath "$downloadMod\content\blob0.bundle")) 'uninstall.cmd run from the download removes the installed mod and keeps the download'
    $output = Invoke-Witcher3ModsScript "$downloadMod\uninstall.cmd" "/yes $gameArgument $docsArgument"
    Assert-Witcher3Mods ($output -match 'Nothing to remove') 'uninstalling when nothing is installed says so'

    # A folder that is not a game is rejected before anything is changed.
    $output = Invoke-Witcher3ModsScript "$downloadMod\install.cmd" ('/yes /game:"' + $Witcher3ModsWork + '"')
    Assert-Witcher3Mods (($output -match 'Not a Witcher 3 folder') -and (-not (Test-Path -LiteralPath $mod))) 'a folder that is not a game is rejected'
    Write-Output 'Installer end-to-end test passed.'
} finally {
    Remove-Item -LiteralPath $Witcher3ModsWork -Recurse -Force -ErrorAction SilentlyContinue
}
