param(
    [Parameter(Mandatory=$true)][string]$RedkitPath,
    [Parameter(Mandatory=$true)][string]$JavaPath,
    [Parameter(Mandatory=$true)][string]$FfdecPath
)
$ErrorActionPreference = 'Stop'
$Witcher3ModsRoot = Split-Path $PSScriptRoot -Parent
$Witcher3ModsBuild = Join-Path $Witcher3ModsRoot ('.build/control-mapping-' + [Guid]::NewGuid().ToString('N'))
$Witcher3ModsNative = Join-Path $RedkitPath 'r4data/gameplay/gui_new/swf/mainmenu/panel_ingamemenu.swf'
$Witcher3ModsPrefix = 'red.game.witcher3.menus.mainmenu.'
foreach ($Witcher3ModsPath in @($Witcher3ModsNative, $JavaPath, $FfdecPath)) {
    if (-not (Test-Path -LiteralPath $Witcher3ModsPath -PathType Leaf)) { throw "Missing tool/input: $Witcher3ModsPath" }
}
New-Item -ItemType Directory -Path $Witcher3ModsBuild | Out-Null
function Invoke-Witcher3ModsFlash([string[]]$Witcher3ModsArguments) {
    & $JavaPath '-Djava.awt.headless=true' -jar $FfdecPath @Witcher3ModsArguments
    if ($LASTEXITCODE -ne 0) { throw "Flash command failed: $($Witcher3ModsArguments -join ' ')" }
}
function Replace-Witcher3ModsControlOnce([string]$Witcher3ModsText, [string]$Witcher3ModsFrom, [string]$Witcher3ModsTo) {
    if ([regex]::Matches($Witcher3ModsText, [regex]::Escape($Witcher3ModsFrom)).Count -ne 1) { throw "Unsupported native source anchor: $Witcher3ModsFrom" }
    return $Witcher3ModsText.Replace($Witcher3ModsFrom, $Witcher3ModsTo)
}
function Add-Witcher3ModsControlGuard([string]$Witcher3ModsText, [string]$Witcher3ModsMethod, [string]$Witcher3ModsCode) {
    $Witcher3ModsPattern = '(?m)(^      (?:override )?(?:public|private|protected) function ' + [regex]::Escape($Witcher3ModsMethod) + '\([^\r\n]*\r?\n      \{)'
    if ([regex]::Matches($Witcher3ModsText, $Witcher3ModsPattern).Count -ne 1) { throw "Missing/ambiguous method: $Witcher3ModsMethod" }
    return [regex]::Replace($Witcher3ModsText, $Witcher3ModsPattern, [Text.RegularExpressions.MatchEvaluator]{param($Witcher3ModsMatch) $Witcher3ModsMatch.Value + "`n" + $Witcher3ModsCode})
}
$Witcher3ModsClasses = @('GamepadMappingModule', 'KeyBindsOptionModule')
Invoke-Witcher3ModsFlash @('-selectclass', (($Witcher3ModsClasses | ForEach-Object { $Witcher3ModsPrefix + $_ }) -join ','), '-export', 'script', "$Witcher3ModsBuild/source", $Witcher3ModsNative)
$Witcher3ModsScripts = "$Witcher3ModsBuild/source/scripts/red/game/witcher3/menus/mainmenu"
$Witcher3ModsPath = "$Witcher3ModsScripts/GamepadMappingModule.as"
$Witcher3ModsText = Get-Content -LiteralPath $Witcher3ModsPath -Raw -Encoding UTF8
$Witcher3ModsMethods = Get-Content -LiteralPath "$PSScriptRoot/flash/Witcher3ModsControlMapping.as.inc" -Raw -Encoding UTF8
$Witcher3ModsText = Replace-Witcher3ModsControlOnce $Witcher3ModsText '      public function GamepadMappingModule()' ($Witcher3ModsMethods + "`n      public function GamepadMappingModule()")
$Witcher3ModsText = Replace-Witcher3ModsControlOnce $Witcher3ModsText '         this.updateButtonCaption(this.txtDPadWithLines,_loc1_.txtDPad);' "         this.updateButtonCaption(this.txtDPadWithLines,_loc1_.txtDPad);`n         Witcher3ModsUpdateMappingTable();"
$Witcher3ModsText = Add-Witcher3ModsControlGuard $Witcher3ModsText 'hide' '         Witcher3ModsHideMappingTable();'
$Witcher3ModsText = Add-Witcher3ModsControlGuard $Witcher3ModsText 'handleInputNavigate' '         if (Witcher3ModsMappingInput(param1)) return;'
# Keep the selected context when the script re-sends the rows after a rebind.
$Witcher3ModsText = Add-Witcher3ModsControlGuard $Witcher3ModsText 'showWithData' '         Witcher3ModsRememberLayout(param1);'
$Witcher3ModsText = Replace-Witcher3ModsControlOnce $Witcher3ModsText '         this.selectedIndex = 0;' '         this.selectedIndex = Witcher3ModsKeepLayout >= 0 && Witcher3ModsKeepLayout < param1.length ? Witcher3ModsKeepLayout : 0;'
[IO.File]::WriteAllText($Witcher3ModsPath, $Witcher3ModsText, (New-Object Text.UTF8Encoding($false)))
$Witcher3ModsPath = "$Witcher3ModsScripts/KeyBindsOptionModule.as"
$Witcher3ModsText = Get-Content -LiteralPath $Witcher3ModsPath -Raw -Encoding UTF8
$Witcher3ModsMethods = Get-Content -LiteralPath "$PSScriptRoot/flash/Witcher3ModsControlTable.as.inc" -Raw -Encoding UTF8
$Witcher3ModsText = Replace-Witcher3ModsControlOnce $Witcher3ModsText '      public function KeyBindsOptionModule()' ($Witcher3ModsMethods + "`n      public function KeyBindsOptionModule()")
$Witcher3ModsText = Add-Witcher3ModsControlGuard $Witcher3ModsText 'showWithData' "         Witcher3ModsRestoreTable();`n         Witcher3ModsMappingPreview = false;"
$Witcher3ModsText = Add-Witcher3ModsControlGuard $Witcher3ModsText 'handleInputNavigate' '         if (Witcher3ModsMappingPreview) { Witcher3ModsPreviewInput(param1); return; }'
$Witcher3ModsText = Replace-Witcher3ModsControlOnce $Witcher3ModsText '   import flash.text.TextFormat;' "   import flash.text.TextFormat;`n   import flash.utils.getTimer;"
$Witcher3ModsText = Add-Witcher3ModsControlGuard $Witcher3ModsText 'hide' '         Witcher3ModsOnHide();'
$Witcher3ModsText = Add-Witcher3ModsControlGuard $Witcher3ModsText 'onItemDoubleClick' '         if (Witcher3ModsMappingPreview) { Witcher3ModsPreviewDoubleClick(); return; }'
foreach ($Witcher3ModsMethod in @('onItemMouseOver','handleScroll')) {
    $Witcher3ModsText = Add-Witcher3ModsControlGuard $Witcher3ModsText $Witcher3ModsMethod '         if (Witcher3ModsCellFocus) Witcher3ModsCellFocus.visible = false;'
}
foreach ($Witcher3ModsMethod in @('onItemClicked','startChangingKeybind','resetKeybinds','smartKeybindingPressed','onRightClick','onMouseClick','onMouseScroll')) {
    $Witcher3ModsText = Add-Witcher3ModsControlGuard $Witcher3ModsText $Witcher3ModsMethod '         if (Witcher3ModsMappingPreview) return;'
}
# Correct the native capture flag so the temporary shared table unregisters cleanly.
$Witcher3ModsText = Replace-Witcher3ModsControlOnce $Witcher3ModsText 'stage.removeEventListener(MouseEvent.MOUSE_WHEEL,this.onMouseScroll,false);' 'stage.removeEventListener(MouseEvent.MOUSE_WHEEL,this.onMouseScroll,true);'
[IO.File]::WriteAllText($Witcher3ModsPath, $Witcher3ModsText, (New-Object Text.UTF8Encoding($false)))
$Witcher3ModsOutput = "$Witcher3ModsBuild/panel_ingamemenu.swf"
$Witcher3ModsArguments = @('-replace', $Witcher3ModsNative, $Witcher3ModsOutput)
foreach ($Witcher3ModsClass in $Witcher3ModsClasses) { $Witcher3ModsArguments += @(($Witcher3ModsPrefix + $Witcher3ModsClass), "$Witcher3ModsScripts/$Witcher3ModsClass.as") }
Invoke-Witcher3ModsFlash $Witcher3ModsArguments
# Compare untouched roots and static initialization, not just inserted strings.
$Witcher3ModsPreserved = @('red.game.witcher3.menus.mainmenu.IngameMenu', 'red.core.CoreComponent', 'red.core.CoreMenu', 'red.core.CoreMenuModule')
Invoke-Witcher3ModsFlash @('-selectclass', ($Witcher3ModsPreserved -join ','), '-export', 'script', "$Witcher3ModsBuild/native", $Witcher3ModsNative)
Invoke-Witcher3ModsFlash @('-selectclass', ($Witcher3ModsPreserved -join ','), '-export', 'script', "$Witcher3ModsBuild/built", $Witcher3ModsOutput)
foreach ($Witcher3ModsClass in $Witcher3ModsPreserved) {
    $Witcher3ModsRelative = 'scripts/' + $Witcher3ModsClass.Replace('.', '/') + '.as'
    if ((Get-FileHash -LiteralPath "$Witcher3ModsBuild/native/$Witcher3ModsRelative").Hash -ne (Get-FileHash -LiteralPath "$Witcher3ModsBuild/built/$Witcher3ModsRelative").Hash) { throw "Unintended native class change: $Witcher3ModsClass" }
}
Invoke-Witcher3ModsFlash @('-selectclass', (($Witcher3ModsClasses | ForEach-Object { $Witcher3ModsPrefix + $_ }) -join ','), '-export', 'script', "$Witcher3ModsBuild/verify", $Witcher3ModsOutput)
Write-Output "Control mapping SWF compiled. Cook this exact SWF: $Witcher3ModsOutput"
