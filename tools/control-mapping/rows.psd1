# Single source for the gamepad table.
# Vars  -> one config variable per rebindable function; Actions are the engine input actions it owns (all contexts).
# Layouts -> order must match InGameMenu_CreateControllerData (Exploration, Swimming, Combat, Horse, Boat).
# Label values are game localisation keys, or =English|Polish for text the game has no key for. Probe is the action whose current pad key is displayed.
# A row without Var is shown but locked (system buttons and sticks).
@{
    Group = 'Witcher3ModsPadInput'
    # Hidden group that keeps one pad key per (context, row variable). The script copies the row keys of the active
    # context into the Group variables above whenever the game switches input context. Values are EInputKey numbers.
    StoreGroup = 'Witcher3ModsPadStore'
    Version = '2.0'
    # Pad keys the script may write back from a stored number (EInputKey has no int-to-enum cast in WitcherScript).
    PadKeys = @('IK_Pad_A_CROSS','IK_Pad_B_CIRCLE','IK_Pad_X_SQUARE','IK_Pad_Y_TRIANGLE','IK_Pad_LeftShoulder','IK_Pad_RightShoulder','IK_Pad_LeftTrigger','IK_Pad_RightTrigger','IK_Pad_LeftThumb','IK_Pad_RightThumb','IK_Pad_DigitUp','IK_Pad_DigitDown','IK_Pad_DigitLeft','IK_Pad_DigitRight','IK_Pad_Start','IK_Pad_Back_Select')
    Vars = @(
        @{ Id = 'W3MPadInteract';    Label = 'ControlLayout_Interact';          Probe = 'Interact'; Actions = 'Interact;InteractHold;Use;UseDevice;Open;Close;Lock;Unlock;Take;Push;Pull;Locked;Destroy;PrayForSun;PrayForStorm;Arm;Disarm;GatherBrushwood;PlaceHerbs;Drink;PlaceOffering;Grab;Free;Ignite;UnblockGate;UseItem;Read;PullAxe;Interaction;Extinguish;CallJohnny;HideBible;SitAndWait;PlaceBottle;WineSlot;BurnBody;PutBack;Debung;Touch;CutRope;KneelDown;PlaceTribute;HangPainting;PlaceArmor;PlaceSword;GiveAlms;PlaceLure;PlaceBeans;Look;TakePaintGreen;TakePaintBlue;TakePaintRed;TakePaintYellow;TakePaintPurple;DisposePaint;HideIn;PlaceTrophy;BuryBody;SqueezeIn;PetDog;PickOilLamp;PlaceOilLamp;PlaceCrystal;SitDown;Knock;Unequip;FastTravel;GatherHerbs;Examine;EnterBoat;EnterBoatFromSwimming;MountHorse;Talk;Container;Stash' }
        @{ Id = 'W3MPadSprint';      Label = 'ControlLayout_RunSprint';         Actions = 'Sprint' }
        @{ Id = 'W3MPadSprintToggle'; Label = 'toggle_sprint';                  Actions = 'SprintToggle' }
        @{ Id = 'W3MPadJump';        Label = 'panel_button_common_jump';        Probe = 'Jump'; Actions = 'Jump;ExplorationInteraction;Roll' }
        @{ Id = 'W3MPadFastAttack';  Label = 'panel_groupname_fast_attack';     Probe = 'AttackLight'; Actions = 'AttackLight;SpecialAttackLight;Finisher;Finish' }
        @{ Id = 'W3MPadStrongAttack'; Label = 'panel_groupname_strong_attack';  Probe = 'AttackHeavy'; Actions = 'AttackHeavy;SpecialAttackHeavy' }
        @{ Id = 'W3MPadCastSign';    Label = 'ControlLayout_CastSign';          Probe = 'CastSign'; Actions = 'CastSign;CastSignHold' }
        @{ Id = 'W3MPadQuickItem';   Label = 'ControlLayout_UseQuickSlot';      Probe = 'ThrowItem'; Actions = 'ThrowItem;ThrowItemHold' }
        @{ Id = 'W3MPadFocus';       Label = 'ControlLayout_Focus';             Actions = 'Focus' }
        @{ Id = 'W3MPadGuard';       Label = 'panel_input_action_lockandguard'; Probe = 'LockAndGuard'; Actions = 'LockAndGuard;Alternate' }
        @{ Id = 'W3MPadRadial';      Label = 'ControlLayout_RadialMenu';        Actions = 'RadialMenu' }
        @{ Id = 'W3MPadSummonHorse'; Label = 'ControlLayout_SummonHorse';       Actions = 'SpawnHorse' }
        @{ Id = 'W3MPadChangeQuest'; Label = 'ControlLayout_ChangeQuest';       Probe = 'TrackQuest'; Actions = 'TrackQuest;HighlightObjective' }
        @{ Id = 'W3MPadCameraLock';  Label = 'camera_lock';                     Actions = 'CameraLock' }
        @{ Id = 'W3MPadSteel';       Label = 'draw_steel';                      Actions = 'SteelSword' }
        @{ Id = 'W3MPadSilver';      Label = 'draw_silver';                     Actions = 'SilverSword' }
        @{ Id = 'W3MPadPotion1';     Label = 'potion_1';                        Probe = 'DrinkPotion1'; Actions = 'DrinkPotion1;DrinkPotionUpperHold' }
        @{ Id = 'W3MPadPotion2';     Label = 'potion_2';                        Probe = 'DrinkPotion2'; Actions = 'DrinkPotion2;DrinkPotionLowerHold' }
        @{ Id = 'W3MPadDodge';       Label = 'ControlLayout_Dodge';             Actions = 'Dodge' }
        @{ Id = 'W3MPadRoll';        Label = 'ControlLayout_Roll';              Probe = 'CbtRoll'; Actions = 'CbtRoll' }
        @{ Id = 'W3MPadDiveDown';    Label = 'ControlLayout_Dive';              Actions = 'DiveDown' }
        @{ Id = 'W3MPadDiveUp';      Label = 'ControlLayout_Emerge';            Actions = 'DiveUp' }
        @{ Id = 'W3MPadGallop';      Label = 'gallop_and_canter';               Probe = 'Gallop'; Actions = 'Gallop;Canter;Follow' }
        @{ Id = 'W3MPadHorseJump';   Label = 'panel_button_common_jump';        Probe = 'HorseJump'; Actions = 'HorseJump' }
        @{ Id = 'W3MPadDismount';    Label = 'dismount_horse';                  Probe = 'HorseDismount'; Actions = 'HorseDismount' }
        @{ Id = 'W3MPadBoatDismount'; Label = '=Leave the boat|Wyjście z łodzi';  Probe = 'BoatDismount'; Actions = 'BoatDismount' }
        @{ Id = 'W3MPadVehicleAttack'; Label = 'panel_groupname_fast_attack';   Probe = 'VehicleAttack'; Actions = 'VehicleAttack' }
        @{ Id = 'W3MPadVehicleSign'; Label = 'ControlLayout_CastSign';          Probe = 'VehicleCastSign'; Actions = 'VehicleCastSign' }
        @{ Id = 'W3MPadVehicleItem'; Label = 'ControlLayout_UseQuickSlot';      Probe = 'VehicleItemAction'; Actions = 'VehicleItemAction;VehicleItemActionHold' }
        @{ Id = 'W3MPadAccelerate';  Label = '=Accelerate|Przyspieszanie';       Probe = 'GI_Accelerate'; Actions = 'GI_Accelerate' }
        @{ Id = 'W3MPadDecelerate';  Label = '=Decelerate|Zwalnianie';            Probe = 'GI_Decelerate'; Actions = 'GI_Decelerate' }
    )
    Locked = @{
        Movement = @{ Label = 'ControlLayout_Movement';      Probe = 'GI_AxisLeftY' }
        Camera   = @{ Label = 'ControlLayout_ControlCamera'; Probe = 'GI_AxisRightY' }
        Start    = @{ Label = 'PANEL_MENUSELECTOR';          Probe = 'FastMenu' }
        Select   = @{ Label = 'ControlLayout_system_menu';   Probe = 'IngameMenu' }
    }
    Layouts = @(
        @{ Name = 'Exploration'; Rows = @('W3MPadInteract','W3MPadSprint','W3MPadJump','W3MPadFastAttack','W3MPadStrongAttack','W3MPadCastSign','W3MPadQuickItem','W3MPadFocus','W3MPadRadial','W3MPadSummonHorse','W3MPadSprintToggle','W3MPadChangeQuest','W3MPadSteel','W3MPadSilver','W3MPadPotion1','W3MPadPotion2','@Movement','@Camera','@Start','@Select') }
        @{ Name = 'Swimming';    Rows = @('W3MPadInteract','W3MPadDiveDown','W3MPadDiveUp','W3MPadQuickItem','W3MPadFocus','W3MPadRadial','W3MPadChangeQuest','W3MPadCameraLock','@Movement','@Camera','@Start','@Select') }
        @{ Name = 'Combat';      Rows = @('W3MPadRoll','W3MPadDodge','W3MPadFastAttack','W3MPadStrongAttack','W3MPadCastSign','W3MPadQuickItem','W3MPadGuard','W3MPadRadial','W3MPadCameraLock','W3MPadSteel','W3MPadSilver','W3MPadPotion1','W3MPadPotion2','@Movement','@Camera','@Start','@Select') }
        @{ Name = 'Horse';       Rows = @('W3MPadGallop','W3MPadHorseJump','W3MPadDismount','W3MPadVehicleAttack','W3MPadVehicleSign','W3MPadVehicleItem','W3MPadFocus','W3MPadRadial','W3MPadChangeQuest','W3MPadSteel','W3MPadSilver','W3MPadPotion1','W3MPadPotion2','@Movement','@Camera','@Start','@Select') }
        @{ Name = 'Boat';        Rows = @('W3MPadAccelerate','W3MPadDecelerate','W3MPadBoatDismount','W3MPadVehicleItem','W3MPadFocus','W3MPadRadial','W3MPadChangeQuest','W3MPadCameraLock','@Movement','@Camera','@Start','@Select') }
    )
}
