param(
    # Folder with install.exe and uninstall.exe, built by tools/Build-Witcher3ModsInstallers.ps1.
    [Parameter(Mandatory=$true)][string]$InstallerDirectory
)
# End-to-end test of the two .exe files against a fake game folder: install (also from a ZIP extracted into the game folder),
# uninstall from inside the installed mod folder (the way users run it, with that folder as the working directory), the
# controls-reset question, both ways to finish (1 / 2), and uninstall from the extracted download.
$ErrorActionPreference = 'Stop'
$Witcher3ModsInstallers = [IO.Path]::GetFullPath($InstallerDirectory)
$Witcher3ModsModName = 'modWitcher3ModsControlMapping'
$Witcher3ModsXmlRelative = 'bin\config\r4game\user_config_matrix\pc\witcher3modscontrolmapping.xml'
# The work folder is kept short: the C# runtime and Windows PowerShell 5.1 reject long paths.
$Witcher3ModsWork = Join-Path ([IO.Path]::GetTempPath()) ('w3m-test-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))

function Assert-Witcher3Mods([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "Test failed: $Message" }
    Write-Output "ok: $Message"
}
function Invoke-Witcher3Mods([string]$Exe, [string[]]$Arguments, [string]$WorkingDirectory) {
    $process = Start-Process -FilePath $Exe -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -Wait -PassThru -WindowStyle Hidden
    return $process.ExitCode
}
# Runs a program with the given lines typed on its keyboard; returns its exit code and everything it printed.
function Invoke-Witcher3ModsInteractive([string]$Exe, [string[]]$Arguments, [string]$WorkingDirectory, [string]$Typed) {
    $start = New-Object Diagnostics.ProcessStartInfo $Exe
    $start.Arguments = $Arguments -join ' '
    $start.WorkingDirectory = $WorkingDirectory
    $start.UseShellExecute = $false
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.CreateNoWindow = $true
    $process = [Diagnostics.Process]::Start($start)
    $process.StandardInput.Write($Typed)
    $process.StandardInput.Close()
    $output = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()
    return [pscustomobject]@{ ExitCode = $process.ExitCode; Output = $output }
}

try {
    $game = Join-Path $Witcher3ModsWork 'game'
    $docs = Join-Path $Witcher3ModsWork 'docs'
    # The release ZIP is extracted into a folder that looks like the game folder: mods\<mod>\... and bin\config\...
    $download = Join-Path $Witcher3ModsWork 'download'
    $downloadMod = "$download\mods\$Witcher3ModsModName"
    foreach ($dir in @("$game\bin\config\r4game", "$game\content\content0", "$game\mods\modOtherMod", $docs, "$downloadMod\content", (Split-Path "$download\$Witcher3ModsXmlRelative" -Parent))) { New-Item -ItemType Directory -Force $dir | Out-Null }
    Set-Content -LiteralPath "$game\mods\modOtherMod\keep.txt" -Value 'other mod'
    Set-Content -LiteralPath "$downloadMod\content\blob0.bundle" -Value 'bundle'
    Set-Content -LiteralPath "$download\$Witcher3ModsXmlRelative" -Value '<redxml/>'
    Copy-Item "$Witcher3ModsInstallers\install.exe", "$Witcher3ModsInstallers\uninstall.exe" $downloadMod
    $settings = "$docs\user.settings"
    [IO.File]::WriteAllText($settings, "[Video]`r`nBrightness=1`r`n[Witcher3ModsPadInput]`r`nSwap=1`r`n[Witcher3ModsPadStore]`r`nStored=2`r`n[Audio]`r`nVolume=7`r`n", [Text.Encoding]::GetEncoding(28591))
    $inputSettings = "$docs\input.settings"
    Set-Content -LiteralPath $inputSettings -Value 'my bindings'
    $mod = "$game\mods\$Witcher3ModsModName"
    $xml = "$game\$Witcher3ModsXmlRelative"
    $installArguments = @('/yes', "`"/game:$game`"")

    # Install into the fake game: the mod folder and the config XML, once clean and once over an existing copy.
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$downloadMod\install.exe" $installArguments $downloadMod) -eq 0) 'install.exe exits with 0'
    Assert-Witcher3Mods (Test-Path -LiteralPath "$mod\content\blob0.bundle") 'install.exe copied the mod'
    Assert-Witcher3Mods (Test-Path -LiteralPath $xml) 'install.exe put the config XML into bin\config'
    Assert-Witcher3Mods ((Test-Path -LiteralPath "$mod\uninstall.exe") -and (Test-Path -LiteralPath "$mod\install.exe")) 'the installed mod carries both programs'
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$downloadMod\install.exe" $installArguments $downloadMod) -eq 0) 'installing over an existing copy exits with 0'
    # Run from the installed copy itself (a ZIP extracted into the game folder): the XML is already in place, nothing to copy.
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$mod\install.exe" @('/yes') $mod) -eq 0) 'install.exe run from inside the game folder exits with 0'
    Assert-Witcher3Mods ((Test-Path -LiteralPath $xml) -and (Test-Path -LiteralPath "$mod\content\blob0.bundle")) 'the files are still in place afterwards'

    # A junction inside the mod folder must be removed as a link, never followed.
    $outside = Join-Path $Witcher3ModsWork 'outside'
    New-Item -ItemType Directory -Force $outside | Out-Null
    Set-Content -LiteralPath "$outside\canary.txt" -Value 'must survive'
    New-Item -ItemType Junction -Path "$mod\link" -Target $outside | Out-Null

    # Uninstall the way a user does: double-click uninstall.exe inside the mod folder. /yes does not reset the controls.
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$mod\uninstall.exe" @('/yes', "`"/docs:$docs`"") $mod) -eq 0) 'uninstall.exe run from the mod folder exits with 0'
    Assert-Witcher3Mods (-not (Test-Path -LiteralPath "$mod\content")) 'the mod folder content is gone'
    Assert-Witcher3Mods (-not (Test-Path -LiteralPath $xml)) 'the config XML is gone'
    Assert-Witcher3Mods (-not (Test-Path -LiteralPath "$mod\link")) 'the junction is gone'
    Assert-Witcher3Mods (Test-Path -LiteralPath "$outside\canary.txt") 'the junction target was not touched'
    Assert-Witcher3Mods (@(Get-ChildItem -LiteralPath $mod -Force).Name -join ',' -eq 'uninstall.exe') 'only the running uninstall.exe is left behind'
    Assert-Witcher3Mods (Test-Path -LiteralPath "$game\mods\modOtherMod\keep.txt") 'another mod was not touched'
    $text = [IO.File]::ReadAllText($settings, [Text.Encoding]::GetEncoding(28591))
    Assert-Witcher3Mods (($text -notmatch 'Witcher3ModsPad(Input|Store)') -and ($text -match 'Brightness=1') -and ($text -match 'Volume=7')) 'only the mod sections (PadInput and PadStore) left user.settings'
    Assert-Witcher3Mods (@(Get-ChildItem $docs -Filter 'user.settings.bak-uninstall-*').Count -eq 1) 'a backup of user.settings was made'
    Assert-Witcher3Mods (Test-Path -LiteralPath $inputSettings) 'input.settings was not touched without /resetcontrols'

    # Interactive uninstall. Answers: reset controls (y), continue (y), two invalid choices, then option 1 (the user deletes the folder).
    Remove-Item -LiteralPath $mod -Recurse -Force
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$downloadMod\install.exe" $installArguments $downloadMod) -eq 0) 'installing again exits with 0'
    $run = Invoke-Witcher3ModsInteractive "$mod\uninstall.exe" @("`"/docs:$docs`"") $mod "y`r`ny`r`nx`r`n3`r`n1`r`n`r`n"
    Assert-Witcher3Mods ($run.ExitCode -eq 0) 'interactive uninstall exits with 0'
    Assert-Witcher3Mods (([regex]::Matches($run.Output, 'Please type 1 or 2\.')).Count -eq 2) 'anything but 1 or 2 asks again'
    Assert-Witcher3Mods (@(Get-ChildItem -LiteralPath $mod -Force).Name -join ',' -eq 'uninstall.exe') 'option 1 leaves the folder to the user'
    Write-Output $run.Output
    Write-Output ("docs folder: " + ((Get-ChildItem $docs -Force).Name -join ', '))
    Assert-Witcher3Mods ((-not (Test-Path -LiteralPath $inputSettings)) -and (@(Get-ChildItem $docs -Filter 'input.settings.bak-uninstall-*').Count -eq 1)) 'answering y reset the controls and kept a copy of input.settings'

    # Interactive uninstall, option 2: everything including uninstall.exe and its folder goes, a moment after the window closes.
    # Answers: do not reset controls (n), continue (y), option 2.
    Remove-Item -LiteralPath $mod -Recurse -Force
    Set-Content -LiteralPath $inputSettings -Value 'my bindings'
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$downloadMod\install.exe" $installArguments $downloadMod) -eq 0) 'installing once more exits with 0'
    $run = Invoke-Witcher3ModsInteractive "$mod\uninstall.exe" @("`"/docs:$docs`"") $mod "n`r`ny`r`n2`r`n"
    Assert-Witcher3Mods ($run.ExitCode -eq 0) 'uninstall with option 2 exits with 0'
    $deadline = (Get-Date).AddSeconds(20)
    while ((Test-Path -LiteralPath $mod) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 300 }
    Assert-Witcher3Mods (-not (Test-Path -LiteralPath $mod)) 'option 2 removed uninstall.exe and the mod folder'
    Assert-Witcher3Mods (Test-Path -LiteralPath $inputSettings) 'answering n left input.settings alone'

    # Uninstall from the extracted download: the whole mod folder goes, nothing is left behind.
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$downloadMod\install.exe" $installArguments $downloadMod) -eq 0) 'installing again exits with 0'
    $uninstallFromDownload = @('/yes', "`"/game:$game`"", "`"/docs:$docs`"")
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$downloadMod\uninstall.exe" $uninstallFromDownload $downloadMod) -eq 0) 'uninstall.exe run from the download exits with 0'
    Assert-Witcher3Mods ((-not (Test-Path -LiteralPath $mod)) -and (-not (Test-Path -LiteralPath $xml))) 'the mod folder and the config XML were removed completely'
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$downloadMod\uninstall.exe" $uninstallFromDownload $downloadMod) -eq 0) 'uninstalling when nothing is installed exits with 0'

    # A folder that is not a game is rejected with exit code 1.
    Assert-Witcher3Mods ((Invoke-Witcher3Mods "$downloadMod\uninstall.exe" @('/yes', "`"/game:$Witcher3ModsWork`"") $downloadMod) -eq 1) 'a folder that is not a game exits with 1'
    Write-Output 'Installer end-to-end test passed.'
} finally {
    Remove-Item -LiteralPath $Witcher3ModsWork -Recurse -Force -ErrorAction SilentlyContinue
}
