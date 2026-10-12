# Witcher3ModsControlMapping — agent instructions

Before modifying the mod, read both rule files in full:

- [.agents/rules/compatibility.md](.agents/rules/compatibility.md)
- [.agents/rules/validation.md](.agents/rules/validation.md)

CDPR references:

- [CDPR language guide](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36307090/WS+Language+Guide)
- [CDPR annotations](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36241598/WS+Script+Compilation+Errors+overrides)

The installable package is `src/modWitcher3ModsControlMapping` (goes to `<Game>/mods/`). The engine reads the
config matrix only from `<Game>/bin/config`, so its XML lives in the package's `bin/...` folder; the release ZIPs
place it at `bin/config/...` next to `mods`, and `install.exe` copies it there. Keep user instructions in the root
README.md only; the package's own README.md just links to it and carries the required CDPR notices.

Every release `v0.0.x` has two ZIPs: Automatic (the mod plus `install.exe` and `uninstall.exe`) and Manual (the same
without any `.exe`).

Source layout:

- `tools/control-mapping/rows.psd1` is the single source of rows and actions. After editing it run
  `tools/Build-Witcher3ModsControlRows.ps1`, which generates the XML and `Witcher3ModsControlRows.ws`.
- Flash patches are `tools/flash/*.as.inc`, applied by `tools/Build-Witcher3ModsControlMapping.ps1`
  (JPEXS `ffdec.jar` + Java) to the installed REDkit `panel_ingamemenu.swf`;
  `tools/Pack-Witcher3ModsControlMapping.ps1` cooks it with REDkit into the package bundle.
- `src/modWitcher3ModsControlMapping/Common.cs`, `Install.cs` and `Uninstall.cs` are the plain C# sources of
  `install.exe` and `uninstall.exe` (the mod's own values are in the `Mod` class in `Common.cs`). The `.exe` files
  are not stored in the repository: `tools/Build-Witcher3ModsInstallers.ps1` compiles them with the compiler that
  ships with Windows, and the release ZIP carries only the built files.
- `tools/New-Witcher3ModsReleaseArchive.ps1 -Variant Automatic|Manual` builds and verifies the release ZIPs.
- `tools/Test-Witcher3ModsInstallers.ps1` is the end-to-end installer test (fake game folder); the pull-request check
  and the release job run it.

Facts established in game (keep them true when changing the code):

- Gamepad bindings are written through config-matrix variables of display type `INPUTPAD`; the value is a single
  key name such as `IK_Pad_B_CIRCLE`, never `KEY;IK_None`. A wrong format makes the engine write `IK_None`
  into `input.settings`, unbinding the actions in every context.
- Flash key codes are not `EInputKey` values. Always send the key number read from the engine.
- Read bindings with `theInput.GetPadKeysForAction`; skip `IK_Jcms*` (Switch 2 Joy-Con mouse) keys.

Preserve user changes. Do not commit, push, publish or install into the game without authorization. A repository
edit alone does not authorize changing the active game installation, `Documents/The Witcher 3/input.settings`
or the game's `bin/config`.