// Gamepad table data and rebinding bridge for the in-game Controls panel.
// Rows come from the generated Witcher3ModsControlRows.ws. Every context (Exploration, Swimming, Combat, Horse, Boat)
// keeps its own key per row in the hidden Witcher3ModsPadStore group; whenever the game switches input context the
// keys of that context are copied into the engine variables, which are global. Without the store XML the mod falls
// back to the previous behaviour (one global binding per row) and says so in a notification.
function Witcher3ModsControlPolish() : bool
{
    var Witcher3ModsAudioLanguage, Witcher3ModsTextLanguage : string;
    theGame.GetGameLanguageName(Witcher3ModsAudioLanguage, Witcher3ModsTextLanguage);
    return Witcher3ModsTextLanguage == "PL" || Witcher3ModsTextLanguage == "pl";
}

function Witcher3ModsSay(Witcher3ModsEnglish : string, Witcher3ModsPolishText : string) : string
{
    if (Witcher3ModsControlPolish()) return Witcher3ModsPolishText;
    return Witcher3ModsEnglish;
}

// A label is a game localisation key, or "=English|Polish" for text the game has no key for.
function Witcher3ModsControlLabel(Witcher3ModsKey : string) : string
{
    var Witcher3ModsText : string;
    var Witcher3ModsSplit : int;
    if (StrLeft(Witcher3ModsKey, 1) == "=")
    {
        Witcher3ModsText = StrMid(Witcher3ModsKey, 1);
        Witcher3ModsSplit = StrFindFirst(Witcher3ModsText, "|");
        if (Witcher3ModsSplit < 0) return Witcher3ModsText;
        if (Witcher3ModsControlPolish()) return StrMid(Witcher3ModsText, Witcher3ModsSplit + 1);
        return StrLeft(Witcher3ModsText, Witcher3ModsSplit);
    }
    Witcher3ModsText = GetLocStringByKeyExt(Witcher3ModsKey);
    if (Witcher3ModsText == "") return Witcher3ModsKey;
    return Witcher3ModsText;
}

function Witcher3ModsLayoutTitle(Witcher3ModsLayout : int) : string
{
    if (Witcher3ModsControlPolish())
    {
        switch (Witcher3ModsLayout)
        {
            case 0: return "Eksploracja";
            case 1: return "Pływanie";
            case 2: return "Walka";
            case 3: return "Koń";
            case 4: return "Łódź";
        }
    }
    return Witcher3ModsPadLayoutName(Witcher3ModsLayout);
}

function Witcher3ModsPadKeyName(Witcher3ModsKey : EInputKey, Witcher3ModsPlaystation : bool, Witcher3ModsPolish : bool) : string
{
    var Witcher3ModsName : string;
    if (Witcher3ModsKey == IK_Pad_A_CROSS) { if (Witcher3ModsPlaystation) return "Cross"; return "A"; }
    if (Witcher3ModsKey == IK_Pad_B_CIRCLE) { if (Witcher3ModsPlaystation) return "Circle"; return "B"; }
    if (Witcher3ModsKey == IK_Pad_X_SQUARE) { if (Witcher3ModsPlaystation) return "Square"; return "X"; }
    if (Witcher3ModsKey == IK_Pad_Y_TRIANGLE) { if (Witcher3ModsPlaystation) return "Triangle"; return "Y"; }
    if (Witcher3ModsKey == IK_Pad_LeftShoulder) { if (Witcher3ModsPlaystation) return "L1"; return "LB"; }
    if (Witcher3ModsKey == IK_Pad_RightShoulder) { if (Witcher3ModsPlaystation) return "R1"; return "RB"; }
    if (Witcher3ModsKey == IK_Pad_LeftTrigger) { if (Witcher3ModsPlaystation) return "L2"; return "LT"; }
    if (Witcher3ModsKey == IK_Pad_RightTrigger) { if (Witcher3ModsPlaystation) return "R2"; return "RT"; }
    if (Witcher3ModsKey == IK_Pad_LeftThumb) return "L3";
    if (Witcher3ModsKey == IK_Pad_RightThumb) return "R3";
    if (Witcher3ModsKey == IK_Pad_DigitUp) { if (Witcher3ModsPolish) return "Krzyżak - góra"; return "D-pad Up"; }
    if (Witcher3ModsKey == IK_Pad_DigitDown) { if (Witcher3ModsPolish) return "Krzyżak - dół"; return "D-pad Down"; }
    if (Witcher3ModsKey == IK_Pad_DigitLeft) { if (Witcher3ModsPolish) return "Krzyżak - lewo"; return "D-pad Left"; }
    if (Witcher3ModsKey == IK_Pad_DigitRight) { if (Witcher3ModsPolish) return "Krzyżak - prawo"; return "D-pad Right"; }
    if (Witcher3ModsKey == IK_Pad_Start) { if (Witcher3ModsPlaystation) return "Options"; return "Menu"; }
    if (Witcher3ModsKey == IK_Pad_Back_Select) { if (Witcher3ModsPlaystation) return "Touchpad"; return "View"; }
    if (Witcher3ModsKey == IK_Pad_LeftAxisX || Witcher3ModsKey == IK_Pad_LeftAxisY) { if (Witcher3ModsPolish) return "Lewa gałka"; return "L stick"; }
    if (Witcher3ModsKey == IK_Pad_RightAxisX || Witcher3ModsKey == IK_Pad_RightAxisY) { if (Witcher3ModsPolish) return "Prawa gałka"; return "R stick"; }
    Witcher3ModsName = Witcher3ModsKey;
    // The engine reports the DualShock/DualSense touchpad button under its own key name.
    if (Witcher3ModsName == "IK_PS4_TOUCH_PRESS") { if (Witcher3ModsPlaystation) return "Touchpad"; return "View"; }
    return StrReplace(Witcher3ModsName, "IK_Pad_", "");
}

// Switch 2 Joy-Con mouse buttons (IK_Jcms*) are bound by default but are not gamepad buttons.
function Witcher3ModsIsMouserKey(Witcher3ModsKey : EInputKey) : bool
{
    var Witcher3ModsName : string;
    Witcher3ModsName = Witcher3ModsKey;
    return StrFindFirst(Witcher3ModsName, "IK_Jcms") == 0;
}

function Witcher3ModsPadReadKeys(Witcher3ModsProbe : name, Witcher3ModsPlaystation : bool, Witcher3ModsPolish : bool) : string
{
    var Witcher3ModsKeys : array<EInputKey>;
    var Witcher3ModsText : string;
    var Witcher3ModsIndex : int;
    theInput.GetPadKeysForAction(Witcher3ModsProbe, Witcher3ModsKeys);
    for (Witcher3ModsIndex = 0; Witcher3ModsIndex < Witcher3ModsKeys.Size(); Witcher3ModsIndex += 1)
    {
        if (Witcher3ModsIsMouserKey(Witcher3ModsKeys[Witcher3ModsIndex])) continue;
        if (Witcher3ModsText != "") Witcher3ModsText += " / ";
        Witcher3ModsText += Witcher3ModsPadKeyName(Witcher3ModsKeys[Witcher3ModsIndex], Witcher3ModsPlaystation, Witcher3ModsPolish);
    }
    if (Witcher3ModsText == "") return "-";
    return Witcher3ModsText;
}

// Some actions are not a single tap (input.ini): SpawnHorse needs a double press, HorseDismount a hold on a horse.
function Witcher3ModsPressStyle(Witcher3ModsLayout : int, Witcher3ModsProbe : name, Witcher3ModsKeys : string, Witcher3ModsPolish : bool) : string
{
    if (Witcher3ModsKeys == "-") return Witcher3ModsKeys;
    if (Witcher3ModsProbe == 'SpawnHorse') return "2x " + Witcher3ModsKeys;
    if (Witcher3ModsProbe == 'HorseDismount' && Witcher3ModsLayout == 3)
    {
        if (Witcher3ModsPolish) return "Przytrzymaj " + Witcher3ModsKeys;
        return "Hold " + Witcher3ModsKeys;
    }
    return Witcher3ModsKeys;
}

// First pad key of an action as an EInputKey number; 0 when unbound.
function Witcher3ModsPadFirstKey(Witcher3ModsProbe : name) : int
{
    var Witcher3ModsKeys : array<EInputKey>;
    var Witcher3ModsIndex : int;
    theInput.GetPadKeysForAction(Witcher3ModsProbe, Witcher3ModsKeys);
    for (Witcher3ModsIndex = 0; Witcher3ModsIndex < Witcher3ModsKeys.Size(); Witcher3ModsIndex += 1)
    {
        if (!Witcher3ModsIsMouserKey(Witcher3ModsKeys[Witcher3ModsIndex])) return (int)Witcher3ModsKeys[Witcher3ModsIndex];
    }
    return 0;
}

function Witcher3ModsPadHasKey(Witcher3ModsProbe : name, Witcher3ModsKey : EInputKey) : bool
{
    var Witcher3ModsKeys : array<EInputKey>;
    theInput.GetPadKeysForAction(Witcher3ModsProbe, Witcher3ModsKeys);
    return Witcher3ModsKeys.Contains(Witcher3ModsKey);
}

// ---------------------------------------------------------------------------------------------------------------
// Per-context store
// ---------------------------------------------------------------------------------------------------------------

// Engine input context -> table layout (Exploration, Swimming, Combat, Horse, Boat); -1 for every other context
// (menus, scenes, climbing, aiming ...), which keeps the bindings of the last layout.
function Witcher3ModsContextLayout(Witcher3ModsContext : name) : int
{
    switch (Witcher3ModsContext)
    {
        case 'Exploration': return 0;
        case 'Swimming': return 1;
        case 'Diving': return 1;
        case 'Combat': return 2;
        case 'Horse': return 3;
        case 'Boat': return 4;
        case 'BoatPassenger': return 4;
    }
    return -1;
}

function Witcher3ModsStoreReady() : bool
{
    var Witcher3ModsConfig : CInGameConfigWrapper;
    var Witcher3ModsIndex : int;
    Witcher3ModsConfig = (CInGameConfigWrapper)theGame.GetInGameConfigWrapper();
    if (!Witcher3ModsConfig) return false;
    for (Witcher3ModsIndex = 0; Witcher3ModsIndex < Witcher3ModsConfig.GetGroupsNum(); Witcher3ModsIndex += 1)
    {
        if (Witcher3ModsConfig.GetGroupName(Witcher3ModsIndex) == Witcher3ModsStoreGroup())
            return Witcher3ModsConfig.GetVarsNumByGroupName(Witcher3ModsStoreGroup()) >= Witcher3ModsStoreCount();
    }
    return false;
}

// EInputKey number stored for a row of a layout; 0 when nothing is stored yet.
function Witcher3ModsStoredKey(Witcher3ModsStore : name) : int
{
    var Witcher3ModsConfig : CInGameConfigWrapper;
    Witcher3ModsConfig = (CInGameConfigWrapper)theGame.GetInGameConfigWrapper();
    return StringToInt(Witcher3ModsConfig.GetVarValue(Witcher3ModsStoreGroup(), Witcher3ModsStore), 0);
}

function Witcher3ModsSetStoredKey(Witcher3ModsStore : name, Witcher3ModsKey : int) : void
{
    var Witcher3ModsConfig : CInGameConfigWrapper;
    Witcher3ModsConfig = (CInGameConfigWrapper)theGame.GetInGameConfigWrapper();
    Witcher3ModsConfig.SetVarValue(Witcher3ModsStoreGroup(), Witcher3ModsStore, IntToString(Witcher3ModsKey));
}

// Fills every empty stored key with the key bound in the game right now (first start, or an update that added rows).
// Keys that are not a known pad button stay empty. Returns how many rows were filled.
function Witcher3ModsSeedStore() : int
{
    var Witcher3ModsVar, Witcher3ModsProbe, Witcher3ModsStore : name;
    var Witcher3ModsLabel : string;
    var Witcher3ModsLayoutIndex, Witcher3ModsRowIndex, Witcher3ModsKey, Witcher3ModsFilled : int;
    for (Witcher3ModsLayoutIndex = 0; Witcher3ModsLayoutIndex < Witcher3ModsPadLayoutCount(); Witcher3ModsLayoutIndex += 1)
    {
        for (Witcher3ModsRowIndex = 0; Witcher3ModsRowIndex < Witcher3ModsPadRowCount(Witcher3ModsLayoutIndex); Witcher3ModsRowIndex += 1)
        {
            if (!Witcher3ModsPadRow(Witcher3ModsLayoutIndex, Witcher3ModsRowIndex, Witcher3ModsVar, Witcher3ModsLabel, Witcher3ModsProbe, Witcher3ModsStore)) continue;
            if (Witcher3ModsVar == '') continue;
            if (Witcher3ModsStoredKey(Witcher3ModsStore) != 0) continue;
            Witcher3ModsKey = Witcher3ModsPadFirstKey(Witcher3ModsProbe);
            if (Witcher3ModsKey == 0 || Witcher3ModsPadKeyFromInt(Witcher3ModsKey) == IK_None) continue;
            Witcher3ModsSetStoredKey(Witcher3ModsStore, Witcher3ModsKey);
            Witcher3ModsFilled += 1;
        }
    }
    if (Witcher3ModsFilled > 0) theGame.SaveUserSettings();
    return Witcher3ModsFilled;
}

// Copies the stored keys of a layout into the engine variables that differ. Returns how many variables were written.
function Witcher3ModsWriteLayout(Witcher3ModsLayout : int) : int
{
    var Witcher3ModsConfig : CInGameConfigWrapper;
    var Witcher3ModsVar, Witcher3ModsProbe, Witcher3ModsStore : name;
    var Witcher3ModsLabel, Witcher3ModsKeyName : string;
    var Witcher3ModsKeyValue : EInputKey;
    var Witcher3ModsRowIndex, Witcher3ModsKey, Witcher3ModsWritten : int;
    Witcher3ModsConfig = (CInGameConfigWrapper)theGame.GetInGameConfigWrapper();
    for (Witcher3ModsRowIndex = 0; Witcher3ModsRowIndex < Witcher3ModsPadRowCount(Witcher3ModsLayout); Witcher3ModsRowIndex += 1)
    {
        if (!Witcher3ModsPadRow(Witcher3ModsLayout, Witcher3ModsRowIndex, Witcher3ModsVar, Witcher3ModsLabel, Witcher3ModsProbe, Witcher3ModsStore)) continue;
        if (Witcher3ModsVar == '') continue;
        Witcher3ModsKey = Witcher3ModsStoredKey(Witcher3ModsStore);
        if (Witcher3ModsKey == 0) continue;
        Witcher3ModsKeyValue = Witcher3ModsPadKeyFromInt(Witcher3ModsKey);
        if (Witcher3ModsKeyValue == IK_None) continue;
        if (Witcher3ModsPadHasKey(Witcher3ModsProbe, Witcher3ModsKeyValue)) continue;
        // INPUTPAD stores a single key name (confirmed by diagnostics), without the ";IK_None" slot used by PCInput.
        Witcher3ModsKeyName = Witcher3ModsKeyValue;
        Witcher3ModsConfig.SetVarValue(Witcher3ModsPadGroup(), Witcher3ModsVar, Witcher3ModsKeyName);
        Witcher3ModsWritten += 1;
    }
    return Witcher3ModsWritten;
}

// Counts the rows of a layout whose stored key is not what the engine reports; Witcher3ModsFirstBad names the first.
function Witcher3ModsCheckLayout(Witcher3ModsLayout : int, out Witcher3ModsFirstBad : string) : int
{
    var Witcher3ModsVar, Witcher3ModsProbe, Witcher3ModsStore : name;
    var Witcher3ModsLabel : string;
    var Witcher3ModsKeyValue : EInputKey;
    var Witcher3ModsRowIndex, Witcher3ModsKey, Witcher3ModsBad : int;
    Witcher3ModsFirstBad = "";
    for (Witcher3ModsRowIndex = 0; Witcher3ModsRowIndex < Witcher3ModsPadRowCount(Witcher3ModsLayout); Witcher3ModsRowIndex += 1)
    {
        if (!Witcher3ModsPadRow(Witcher3ModsLayout, Witcher3ModsRowIndex, Witcher3ModsVar, Witcher3ModsLabel, Witcher3ModsProbe, Witcher3ModsStore)) continue;
        if (Witcher3ModsVar == '') continue;
        Witcher3ModsKey = Witcher3ModsStoredKey(Witcher3ModsStore);
        if (Witcher3ModsKey == 0) continue;
        Witcher3ModsKeyValue = Witcher3ModsPadKeyFromInt(Witcher3ModsKey);
        if (Witcher3ModsKeyValue == IK_None) continue;
        if (!Witcher3ModsPadHasKey(Witcher3ModsProbe, Witcher3ModsKeyValue))
        {
            if (Witcher3ModsBad == 0) Witcher3ModsFirstBad = Witcher3ModsControlLabel(Witcher3ModsLabel);
            Witcher3ModsBad += 1;
        }
    }
    return Witcher3ModsBad;
}

// Writes a layout and confirms the engine took it. The engine may only report a new binding after the settings are
// saved, so a failed check is retried once with a save; Witcher3ModsSaved tells the caller to save from now on.
function Witcher3ModsApplyLayout(Witcher3ModsLayout : int, Witcher3ModsSaveFirst : bool, out Witcher3ModsSaved : bool, out Witcher3ModsFirstBad : string) : int
{
    var Witcher3ModsBad : int;
    Witcher3ModsSaved = Witcher3ModsSaveFirst;
    Witcher3ModsFirstBad = "";
    if (Witcher3ModsWriteLayout(Witcher3ModsLayout) == 0) return 0;
    if (Witcher3ModsSaveFirst) theGame.SaveUserSettings();
    Witcher3ModsBad = Witcher3ModsCheckLayout(Witcher3ModsLayout, Witcher3ModsFirstBad);
    if (Witcher3ModsBad > 0 && !Witcher3ModsSaveFirst)
    {
        theGame.SaveUserSettings();
        Witcher3ModsSaved = true;
        Witcher3ModsBad = Witcher3ModsCheckLayout(Witcher3ModsLayout, Witcher3ModsFirstBad);
    }
    return Witcher3ModsBad;
}

// ---------------------------------------------------------------------------------------------------------------
// Gameplay side: follow the input context of Geralt
// ---------------------------------------------------------------------------------------------------------------

@addField(W3PlayerWitcher)
var Witcher3ModsAppliedLayout : int;

@addField(W3PlayerWitcher)
var Witcher3ModsLastContext : name;

@addField(W3PlayerWitcher)
var Witcher3ModsSaveNeeded : bool;

@addField(W3PlayerWitcher)
var Witcher3ModsFaultReported : bool;

// Applies the stored keys of a layout to the engine; returns a message when the engine did not take them.
@addMethod(W3PlayerWitcher)
function Witcher3ModsApplyNow(Witcher3ModsLayout : int) : string
{
    var Witcher3ModsSaved : bool;
    var Witcher3ModsFirstBad : string;
    var Witcher3ModsBad : int;
    Witcher3ModsAppliedLayout = Witcher3ModsLayout + 1;
    if (!Witcher3ModsStoreReady()) return "";
    Witcher3ModsSeedStore();
    Witcher3ModsBad = Witcher3ModsApplyLayout(Witcher3ModsLayout, Witcher3ModsSaveNeeded, Witcher3ModsSaved, Witcher3ModsFirstBad);
    Witcher3ModsSaveNeeded = Witcher3ModsSaved;
    if (Witcher3ModsBad > 0)
        return Witcher3ModsSay("Control Mapping: the engine did not apply the " + Witcher3ModsLayoutTitle(Witcher3ModsLayout) + " bindings (" + Witcher3ModsFirstBad + ", " + IntToString(Witcher3ModsBad) + " rows).",
            "Control Mapping: silnik nie zastosował przypisań dla kontekstu " + Witcher3ModsLayoutTitle(Witcher3ModsLayout) + " (" + Witcher3ModsFirstBad + ", wierszy: " + IntToString(Witcher3ModsBad) + ").");
    return "";
}

@addMethod(W3PlayerWitcher)
function Witcher3ModsSyncContext() : void
{
    var Witcher3ModsContext : name;
    var Witcher3ModsLayout : int;
    var Witcher3ModsFault : string;
    Witcher3ModsContext = theInput.GetContext();
    if (Witcher3ModsContext == Witcher3ModsLastContext) return;
    Witcher3ModsLastContext = Witcher3ModsContext;
    Witcher3ModsLayout = Witcher3ModsContextLayout(Witcher3ModsContext);
    if (Witcher3ModsLayout < 0 || Witcher3ModsAppliedLayout == Witcher3ModsLayout + 1) return;
    Witcher3ModsFault = Witcher3ModsApplyNow(Witcher3ModsLayout);
    if (Witcher3ModsFault != "" && !Witcher3ModsFaultReported)
    {
        Witcher3ModsFaultReported = true;
        theGame.GetGuiManager().ShowNotification(Witcher3ModsFault,, true);
    }
}

// The player timer runs every frame; the context only changes on state transitions, so a name compare is all it costs.
@wrapMethod(W3PlayerWitcher)
function OnPlayerTickTimer( deltaTime : float )
{
    wrappedMethod(deltaTime);
    Witcher3ModsSyncContext();
}

// ---------------------------------------------------------------------------------------------------------------
// Menu side: the table and the pad diagram
// ---------------------------------------------------------------------------------------------------------------

// Not every action is a single tap: SpawnHorse needs a double press, HorseDismount a hold on a horse.
function Witcher3ModsCaptionLine(Witcher3ModsLayout : int, Witcher3ModsProbe : name, Witcher3ModsLabel : string) : string
{
    if (Witcher3ModsProbe == 'SpawnHorse') return GetLocStringByKeyExt("ControlLayout_doubleTap") + " - " + Witcher3ModsLabel;
    if (Witcher3ModsProbe == 'HorseDismount' && Witcher3ModsLayout == 3) return GetLocStringByKeyExt("ControlLayout_hold") + " - " + Witcher3ModsLabel;
    return Witcher3ModsLabel;
}

// Pad-diagram caption of one button: every action the layout binds to it, one per line, each after Witcher3ModsPrefix.
function Witcher3ModsButtonCaption(Witcher3ModsLayout : int, Witcher3ModsKey : EInputKey, Witcher3ModsUseStore : bool, Witcher3ModsPrefix : string) : string
{
    var Witcher3ModsVar, Witcher3ModsProbe, Witcher3ModsStore : name;
    var Witcher3ModsLabel, Witcher3ModsText : string;
    var Witcher3ModsRowIndex, Witcher3ModsStored : int;
    for (Witcher3ModsRowIndex = 0; Witcher3ModsRowIndex < Witcher3ModsPadRowCount(Witcher3ModsLayout); Witcher3ModsRowIndex += 1)
    {
        if (!Witcher3ModsPadRow(Witcher3ModsLayout, Witcher3ModsRowIndex, Witcher3ModsVar, Witcher3ModsLabel, Witcher3ModsProbe, Witcher3ModsStore)) continue;
        if (Witcher3ModsVar == '') continue;
        Witcher3ModsStored = 0;
        if (Witcher3ModsUseStore) Witcher3ModsStored = Witcher3ModsStoredKey(Witcher3ModsStore);
        if (Witcher3ModsStored == 0) Witcher3ModsStored = Witcher3ModsPadFirstKey(Witcher3ModsProbe);
        if (Witcher3ModsStored != (int)Witcher3ModsKey) continue;
        if (Witcher3ModsText != "") Witcher3ModsText += "&#10;";
        Witcher3ModsText += Witcher3ModsPrefix + Witcher3ModsCaptionLine(Witcher3ModsLayout, Witcher3ModsProbe, Witcher3ModsControlLabel(Witcher3ModsLabel));
    }
    return Witcher3ModsText;
}

// Sticks keep their fixed movement/camera caption; actions on the stick click are added below it.
function Witcher3ModsStickCaption(Witcher3ModsLayout : int, Witcher3ModsThumb : EInputKey, Witcher3ModsBaseLabel : string, Witcher3ModsUseStore : bool) : string
{
    var Witcher3ModsPressed : string;
    Witcher3ModsPressed = Witcher3ModsButtonCaption(Witcher3ModsLayout, Witcher3ModsThumb, Witcher3ModsUseStore, GetLocStringByKeyExt("ControlLayout_press") + " ");
    if (Witcher3ModsPressed == "") return GetLocStringByKeyExt(Witcher3ModsBaseLabel);
    return GetLocStringByKeyExt(Witcher3ModsBaseLabel) + "&#10;" + Witcher3ModsPressed;
}

function Witcher3ModsDPadCaption(Witcher3ModsLayout : int, Witcher3ModsUseStore : bool, Witcher3ModsPolish : bool) : string
{
    var Witcher3ModsText, Witcher3ModsPart : string;
    Witcher3ModsPart = Witcher3ModsButtonCaption(Witcher3ModsLayout, IK_Pad_DigitLeft, Witcher3ModsUseStore, Witcher3ModsSay("Left - ", "Lewo - "));
    if (Witcher3ModsPart != "") Witcher3ModsText = Witcher3ModsPart;
    Witcher3ModsPart = Witcher3ModsButtonCaption(Witcher3ModsLayout, IK_Pad_DigitRight, Witcher3ModsUseStore, Witcher3ModsSay("Right - ", "Prawo - "));
    if (Witcher3ModsPart != "")
    {
        if (Witcher3ModsText != "") Witcher3ModsText += "&#10;";
        Witcher3ModsText += Witcher3ModsPart;
    }
    Witcher3ModsPart = Witcher3ModsButtonCaption(Witcher3ModsLayout, IK_Pad_DigitUp, Witcher3ModsUseStore, Witcher3ModsSay("Up - ", "Góra - "));
    if (Witcher3ModsPart != "")
    {
        if (Witcher3ModsText != "") Witcher3ModsText += "&#10;";
        Witcher3ModsText += Witcher3ModsPart;
    }
    Witcher3ModsPart = Witcher3ModsButtonCaption(Witcher3ModsLayout, IK_Pad_DigitDown, Witcher3ModsUseStore, Witcher3ModsSay("Down - ", "Dół - "));
    if (Witcher3ModsPart != "")
    {
        if (Witcher3ModsText != "") Witcher3ModsText += "&#10;";
        Witcher3ModsText += Witcher3ModsPart;
    }
    return Witcher3ModsText;
}

// The pad picture on the right is fed by one caption per button. These replace the native texts so the labels follow
// the bindings of the layout; Start, Select and the stick-click photo mode keep their native captions.
function Witcher3ModsAttachCaptions(Witcher3ModsLayout : CScriptedFlashObject, Witcher3ModsLayoutIndex : int, Witcher3ModsUseStore : bool, Witcher3ModsPolish : bool) : void
{
    Witcher3ModsLayout.SetMemberFlashString("txtAButton", Witcher3ModsButtonCaption(Witcher3ModsLayoutIndex, IK_Pad_A_CROSS, Witcher3ModsUseStore, ""));
    Witcher3ModsLayout.SetMemberFlashString("txtBButton", Witcher3ModsButtonCaption(Witcher3ModsLayoutIndex, IK_Pad_B_CIRCLE, Witcher3ModsUseStore, ""));
    Witcher3ModsLayout.SetMemberFlashString("txtXButton", Witcher3ModsButtonCaption(Witcher3ModsLayoutIndex, IK_Pad_X_SQUARE, Witcher3ModsUseStore, ""));
    Witcher3ModsLayout.SetMemberFlashString("txtYButton", Witcher3ModsButtonCaption(Witcher3ModsLayoutIndex, IK_Pad_Y_TRIANGLE, Witcher3ModsUseStore, ""));
    Witcher3ModsLayout.SetMemberFlashString("txtLeftBumper", Witcher3ModsButtonCaption(Witcher3ModsLayoutIndex, IK_Pad_LeftShoulder, Witcher3ModsUseStore, ""));
    Witcher3ModsLayout.SetMemberFlashString("txtRightBumper", Witcher3ModsButtonCaption(Witcher3ModsLayoutIndex, IK_Pad_RightShoulder, Witcher3ModsUseStore, ""));
    Witcher3ModsLayout.SetMemberFlashString("txtLeftTrigger", Witcher3ModsButtonCaption(Witcher3ModsLayoutIndex, IK_Pad_LeftTrigger, Witcher3ModsUseStore, ""));
    Witcher3ModsLayout.SetMemberFlashString("txtRightTrigger", Witcher3ModsButtonCaption(Witcher3ModsLayoutIndex, IK_Pad_RightTrigger, Witcher3ModsUseStore, ""));
    Witcher3ModsLayout.SetMemberFlashString("txtLeftJoy", Witcher3ModsStickCaption(Witcher3ModsLayoutIndex, IK_Pad_LeftThumb, "ControlLayout_Movement", Witcher3ModsUseStore));
    Witcher3ModsLayout.SetMemberFlashString("txtRightJoy", Witcher3ModsStickCaption(Witcher3ModsLayoutIndex, IK_Pad_RightThumb, "ControlLayout_ControlCamera", Witcher3ModsUseStore));
    Witcher3ModsLayout.SetMemberFlashString("txtDPad", Witcher3ModsDPadCaption(Witcher3ModsLayoutIndex, Witcher3ModsUseStore, Witcher3ModsPolish));
}

// Attach rows to the native layouts; Flash falls back to the native text when w3mRows is absent.
function Witcher3ModsAttachPadRows(Witcher3ModsLayouts : CScriptedFlashArray, Witcher3ModsStorage : CScriptedFlashValueStorage) : void
{
    var Witcher3ModsLayout, Witcher3ModsRowData : CScriptedFlashObject;
    var Witcher3ModsRows : CScriptedFlashArray;
    var Witcher3ModsVar, Witcher3ModsProbe, Witcher3ModsStore : name;
    var Witcher3ModsLabel, Witcher3ModsKeys : string;
    var Witcher3ModsPolish, Witcher3ModsPlaystation, Witcher3ModsUseStore : bool;
    var Witcher3ModsLayoutIndex, Witcher3ModsRowIndex, Witcher3ModsLimit, Witcher3ModsKey : int;
    Witcher3ModsPolish = Witcher3ModsControlPolish();
    Witcher3ModsPlaystation = theInput.UsesPlaystationPadScript();
    Witcher3ModsUseStore = Witcher3ModsStoreReady();
    if (Witcher3ModsUseStore) Witcher3ModsSeedStore();
    Witcher3ModsLimit = Witcher3ModsLayouts.GetLength();
    if (Witcher3ModsLimit > Witcher3ModsPadLayoutCount()) Witcher3ModsLimit = Witcher3ModsPadLayoutCount();
    for (Witcher3ModsLayoutIndex = 0; Witcher3ModsLayoutIndex < Witcher3ModsLimit; Witcher3ModsLayoutIndex += 1)
    {
        Witcher3ModsLayout = Witcher3ModsLayouts.GetElementFlashObject(Witcher3ModsLayoutIndex);
        if (!Witcher3ModsLayout) continue;
        Witcher3ModsRows = Witcher3ModsStorage.CreateTempFlashArray();
        for (Witcher3ModsRowIndex = 0; Witcher3ModsRowIndex < Witcher3ModsPadRowCount(Witcher3ModsLayoutIndex); Witcher3ModsRowIndex += 1)
        {
            if (!Witcher3ModsPadRow(Witcher3ModsLayoutIndex, Witcher3ModsRowIndex, Witcher3ModsVar, Witcher3ModsLabel, Witcher3ModsProbe, Witcher3ModsStore)) continue;
            Witcher3ModsKey = 0;
            if (Witcher3ModsUseStore && Witcher3ModsVar != '') Witcher3ModsKey = Witcher3ModsStoredKey(Witcher3ModsStore);
            if (Witcher3ModsKey != 0 && Witcher3ModsPadKeyFromInt(Witcher3ModsKey) != IK_None)
            {
                Witcher3ModsKeys = Witcher3ModsPadKeyName(Witcher3ModsPadKeyFromInt(Witcher3ModsKey), Witcher3ModsPlaystation, Witcher3ModsPolish);
            }
            else
            {
                Witcher3ModsKey = Witcher3ModsPadFirstKey(Witcher3ModsProbe);
                Witcher3ModsKeys = Witcher3ModsPadReadKeys(Witcher3ModsProbe, Witcher3ModsPlaystation, Witcher3ModsPolish);
            }
            Witcher3ModsRowData = Witcher3ModsStorage.CreateTempFlashObject();
            Witcher3ModsRowData.SetMemberFlashString("label", Witcher3ModsControlLabel(Witcher3ModsLabel));
            Witcher3ModsRowData.SetMemberFlashString("value", Witcher3ModsPressStyle(Witcher3ModsLayoutIndex, Witcher3ModsProbe, Witcher3ModsKeys, Witcher3ModsPolish));
            Witcher3ModsRowData.SetMemberFlashBool("locked", Witcher3ModsVar == '');
            Witcher3ModsRowData.SetMemberFlashBool("permaLocked", Witcher3ModsVar == '');
            // With the store the tag names the stored key, which tells OnChangeKeybind the layout as well.
            if (Witcher3ModsUseStore && Witcher3ModsVar != '') Witcher3ModsRowData.SetMemberFlashUInt("tag", NameToFlashUInt(Witcher3ModsStore));
            else Witcher3ModsRowData.SetMemberFlashUInt("tag", NameToFlashUInt(Witcher3ModsVar));
            Witcher3ModsRowData.SetMemberFlashUInt("key", Witcher3ModsKey);
            Witcher3ModsRows.PushBackFlashObject(Witcher3ModsRowData);
        }
        Witcher3ModsLayout.SetMemberFlashArray("w3mRows", Witcher3ModsRows);
        Witcher3ModsAttachCaptions(Witcher3ModsLayout, Witcher3ModsLayoutIndex, Witcher3ModsUseStore, Witcher3ModsPolish);
        if (Witcher3ModsPolish)
        {
            Witcher3ModsLayout.SetMemberFlashString("w3mSubtitle", "Bieżące przypisania");
            Witcher3ModsLayout.SetMemberFlashString("w3mPrompt", "Zamień z:");
            Witcher3ModsLayout.SetMemberFlashString("w3mHintContext", "Zmień kontekst");
            Witcher3ModsLayout.SetMemberFlashString("w3mHintChange", "Zamień przypisanie");
            Witcher3ModsLayout.SetMemberFlashString("w3mHintCancel", "Anuluj");
        }
        else
        {
            Witcher3ModsLayout.SetMemberFlashString("w3mSubtitle", "Current bindings");
            Witcher3ModsLayout.SetMemberFlashString("w3mPrompt", "Swap with:");
            Witcher3ModsLayout.SetMemberFlashString("w3mHintContext", "Change context");
            Witcher3ModsLayout.SetMemberFlashString("w3mHintChange", "Swap binding");
            Witcher3ModsLayout.SetMemberFlashString("w3mHintCancel", "Cancel");
        }
    }
}

// Same data path as the native panel, with pad rows added for Geralt. Ciri keeps the native text.
@replaceMethod(CR4IngameMenu)
function SendControllerData() : void
{
    var Witcher3ModsLayouts : CScriptedFlashArray;
    if ((W3ReplacerCiri)thePlayer)
    {
        Witcher3ModsLayouts = InGameMenu_CreateControllerDataCiri(m_flashValueStorage);
    }
    else
    {
        Witcher3ModsLayouts = InGameMenu_CreateControllerData(m_flashValueStorage);
        Witcher3ModsAttachPadRows(Witcher3ModsLayouts, m_flashValueStorage);
    }
    m_flashValueStorage.SetFlashArray("ingamemenu.gamepad.mappings", Witcher3ModsLayouts);
}

@addMethod(CR4IngameMenu)
function Witcher3ModsRejectBinding(Witcher3ModsText : string) : void
{
    showNotification(Witcher3ModsText, 0, true);
    OnPlaySoundEvent("gui_global_denied");
}

// Flash sends one call per swapped row (the second row gets the first row's key); the key goes into the store of the
// layout shown in the table. When that layout is the one the game is playing in, it is applied to the engine at once.
@addMethod(CR4IngameMenu)
function Witcher3ModsApplyStoreBinding(Witcher3ModsStore : name, Witcher3ModsLayout : int, Witcher3ModsKey : EInputKey) : void
{
    var Witcher3ModsPlayer : W3PlayerWitcher;
    var Witcher3ModsOld, Witcher3ModsNew : int;
    var Witcher3ModsFault : string;
    Witcher3ModsOld = Witcher3ModsStoredKey(Witcher3ModsStore);
    Witcher3ModsNew = (int)Witcher3ModsKey;
    if (Witcher3ModsPadKeyFromInt(Witcher3ModsNew) == IK_None)
    {
        Witcher3ModsRejectBinding(Witcher3ModsSay("Control Mapping: this button cannot be assigned.", "Control Mapping: tego przycisku nie można przypisać."));
        SendControllerData();
        return;
    }
    hasChangedOption = true;
    Witcher3ModsSetStoredKey(Witcher3ModsStore, Witcher3ModsNew);
    if (Witcher3ModsStoredKey(Witcher3ModsStore) != Witcher3ModsNew)
    {
        if (Witcher3ModsOld != 0) Witcher3ModsSetStoredKey(Witcher3ModsStore, Witcher3ModsOld);
        Witcher3ModsRejectBinding(Witcher3ModsSay("Control Mapping: the binding could not be saved.", "Control Mapping: nie udało się zapisać przypisania."));
        SendControllerData();
        return;
    }
    theGame.SaveUserSettings();
    Witcher3ModsPlayer = GetWitcherPlayer();
    if (Witcher3ModsPlayer && Witcher3ModsPlayer.Witcher3ModsAppliedLayout == Witcher3ModsLayout + 1)
    {
        Witcher3ModsFault = Witcher3ModsPlayer.Witcher3ModsApplyNow(Witcher3ModsLayout);
        if (Witcher3ModsFault != "") Witcher3ModsRejectBinding(Witcher3ModsFault);
    }
    SendControllerData();
}

// Previous behaviour, used only while the store XML is missing: one global binding per row.
@addMethod(CR4IngameMenu)
function Witcher3ModsApplyPadBinding(Witcher3ModsVar : name, Witcher3ModsKey : EInputKey) : void
{
    var Witcher3ModsConfig : CInGameConfigWrapper;
    var Witcher3ModsLayoutIndex, Witcher3ModsRowIndex : int;
    var Witcher3ModsRowVar, Witcher3ModsProbe, Witcher3ModsRowStore : name;
    var Witcher3ModsLabel, Witcher3ModsValue, Witcher3ModsOld : string;
    var Witcher3ModsApplied : bool;
    Witcher3ModsConfig = (CInGameConfigWrapper)theGame.GetInGameConfigWrapper();
    // INPUTPAD stores a single key name (confirmed by diagnostics), without the ";IK_None" slot used by PCInput.
    Witcher3ModsValue = Witcher3ModsKey;
    Witcher3ModsOld = Witcher3ModsConfig.GetVarValue(Witcher3ModsPadGroup(), Witcher3ModsVar);
    hasChangedOption = true;
    Witcher3ModsConfig.SetVarValue(Witcher3ModsPadGroup(), Witcher3ModsVar, Witcher3ModsValue);
    theGame.SaveUserSettings();
    for (Witcher3ModsLayoutIndex = 0; Witcher3ModsLayoutIndex < Witcher3ModsPadLayoutCount() && !Witcher3ModsApplied; Witcher3ModsLayoutIndex += 1)
    {
        for (Witcher3ModsRowIndex = 0; Witcher3ModsRowIndex < Witcher3ModsPadRowCount(Witcher3ModsLayoutIndex); Witcher3ModsRowIndex += 1)
        {
            if (Witcher3ModsPadRow(Witcher3ModsLayoutIndex, Witcher3ModsRowIndex, Witcher3ModsRowVar, Witcher3ModsLabel, Witcher3ModsProbe, Witcher3ModsRowStore) && Witcher3ModsRowVar == Witcher3ModsVar)
            {
                Witcher3ModsApplied = Witcher3ModsPadHasKey(Witcher3ModsProbe, Witcher3ModsKey);
                break;
            }
        }
    }
    if (!Witcher3ModsApplied)
    {
        // Put the previous value back so a rejected key never leaves the action unbound.
        if (Witcher3ModsOld != "")
        {
            Witcher3ModsConfig.SetVarValue(Witcher3ModsPadGroup(), Witcher3ModsVar, Witcher3ModsOld);
            theGame.SaveUserSettings();
        }
        if (Witcher3ModsControlPolish()) showNotification("Silnik nie zastosował nowego przypisania.");
        else showNotification("The engine did not apply the new binding.");
        OnPlaySoundEvent("gui_global_denied");
    }
    SendControllerData();
}

@wrapMethod(CR4IngameMenu)
function OnChangeKeybind(keybindTag : name, newKeybindValue : EInputKey) : void
{
    var Witcher3ModsLayout : int;
    var Witcher3ModsVar : name;
    if (Witcher3ModsStoreLookup(keybindTag, Witcher3ModsLayout, Witcher3ModsVar))
    {
        Witcher3ModsApplyStoreBinding(keybindTag, Witcher3ModsLayout, newKeybindValue);
    }
    else if (Witcher3ModsPadIsVar(keybindTag))
    {
        Witcher3ModsApplyPadBinding(keybindTag, newKeybindValue);
    }
    else
    {
        wrappedMethod(keybindTag, newKeybindValue);
    }
}
