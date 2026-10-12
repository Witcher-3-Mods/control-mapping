      // The right column keeps the native pad diagram; the left column is a table of live bindings
      // supplied by the Witcher3ModsControlMapping script (w3mRows), falling back to the native captions.
      private var Witcher3ModsMappingGeometry:Object;
      private var Witcher3ModsMappingHeading:TextField;
      private var Witcher3ModsMappingMeasure:TextField;
      private var Witcher3ModsMappingPrevArrow:flash.display.Sprite;
      private var Witcher3ModsMappingNextArrow:flash.display.Sprite;
      private var Witcher3ModsKeepLayout:int = -1;
      private static const Witcher3ModsContextHintId:int = 9031;
      private static const Witcher3ModsChangeHintId:int = 9032;

      private function Witcher3ModsRememberLayout(Witcher3ModsLayouts:Array):void
      {
         Witcher3ModsKeepLayout = (visible && Witcher3ModsMappingHeading && Witcher3ModsMappingHeading.visible && Witcher3ModsLayouts && selectedIndex < Witcher3ModsLayouts.length) ? selectedIndex : -1;
      }

      private function Witcher3ModsCreateMappingArrow(Witcher3ModsDirection:int):flash.display.Sprite
      {
         var Witcher3ModsArrow:flash.display.Sprite = new flash.display.Sprite();
         Witcher3ModsArrow.graphics.beginFill(0xC6A967);
         if (Witcher3ModsDirection < 0)
         {
            Witcher3ModsArrow.graphics.moveTo(18, 0);
            Witcher3ModsArrow.graphics.lineTo(18, 28);
            Witcher3ModsArrow.graphics.lineTo(0, 14);
         }
         else
         {
            Witcher3ModsArrow.graphics.moveTo(0, 0);
            Witcher3ModsArrow.graphics.lineTo(0, 28);
            Witcher3ModsArrow.graphics.lineTo(18, 14);
         }
         Witcher3ModsArrow.graphics.endFill();
         Witcher3ModsArrow.graphics.beginFill(0x000000, 0);
         Witcher3ModsArrow.graphics.drawRect(-8, -8, 34, 44);
         Witcher3ModsArrow.graphics.endFill();
         Witcher3ModsArrow.buttonMode = true;
         Witcher3ModsArrow.addEventListener(MouseEvent.CLICK, Witcher3ModsDirection < 0 ? handlePrevButtonTapOrClick : handleNextButtonTapOrClick, false, 0, true);
         parent.addChild(Witcher3ModsArrow);
         return Witcher3ModsArrow;
      }

      private function Witcher3ModsShowHints(Witcher3ModsData:Object, Witcher3ModsEditable:Boolean):void
      {
         var Witcher3ModsMenu:IngameMenu = parent as IngameMenu;
         if (!Witcher3ModsMenu || !Witcher3ModsMenu.mcInputFeedbackModule) return;
         Witcher3ModsMenu.mcInputFeedbackModule.appendButton(Witcher3ModsContextHintId, NavigationCode.GAMEPAD_RBLB, -1,
            Witcher3ModsData.w3mHintContext ? Witcher3ModsData.w3mHintContext : "Change context", true);
         if (Witcher3ModsEditable)
            Witcher3ModsMenu.mcInputFeedbackModule.appendButton(Witcher3ModsChangeHintId, NavigationCode.GAMEPAD_A, KeyCode.E,
               Witcher3ModsData.w3mHintChange ? Witcher3ModsData.w3mHintChange : "Change binding", true);
         else
            Witcher3ModsMenu.mcInputFeedbackModule.removeButton(Witcher3ModsChangeHintId, true);
      }

      private function Witcher3ModsMappingInput(Witcher3ModsEvent:InputEvent):Boolean
      {
         var Witcher3ModsTable:KeyBindsOptionModule = Witcher3ModsMappingTable();
         if (!Witcher3ModsTable || !Witcher3ModsTable.Witcher3ModsMappingPreview) return false;
         if (!visible || Witcher3ModsEvent.handled) return true;
         var Witcher3ModsDetails:InputDetails = Witcher3ModsEvent.details;
         if (Witcher3ModsDetails.value != InputValue.KEY_UP) return true;
         if (Witcher3ModsDetails.code == KeyCode.PAD_LEFT_SHOULDER || Witcher3ModsDetails.navEquivalent == NavigationCode.GAMEPAD_L1)
         {
            navigateLeft();
            Witcher3ModsEvent.handled = true;
         }
         else if (Witcher3ModsDetails.code == KeyCode.PAD_RIGHT_SHOULDER || Witcher3ModsDetails.navEquivalent == NavigationCode.GAMEPAD_R1)
         {
            navigateRight();
            Witcher3ModsEvent.handled = true;
         }
         else if (Witcher3ModsDetails.code == KeyCode.ESCAPE || Witcher3ModsDetails.navEquivalent == NavigationCode.GAMEPAD_B)
         {
            handleNavigateBack();
            Witcher3ModsEvent.handled = true;
         }
         return true;
      }

      private function Witcher3ModsMappingTable():KeyBindsOptionModule
      {
         var Witcher3ModsMenu:IngameMenu = parent as IngameMenu;
         return Witcher3ModsMenu ? Witcher3ModsMenu.mcKeyBindModule : null;
      }

      private function Witcher3ModsAppendMappingRows(Witcher3ModsRows:Array, Witcher3ModsCaption:String, Witcher3ModsButton:String):void
      {
         if (!Witcher3ModsCaption || Witcher3ModsCaption == "null") return;
         var Witcher3ModsPlain:TextField = new TextField();
         Witcher3ModsPlain.htmlText = Witcher3ModsCaption.replace(/&#10;|<br\s*\/?\s*>/gi, "\n");
         var Witcher3ModsLines:Array = Witcher3ModsPlain.text.split(/\r\n|\r|\n/);
         for each (var Witcher3ModsLine:String in Witcher3ModsLines)
         {
            if (Witcher3ModsLine.replace(/\s/g, "").length)
               Witcher3ModsRows.push({label:Witcher3ModsLine, value:Witcher3ModsButton, locked:true, permaLocked:true, tag:0});
         }
      }

      private function Witcher3ModsNativeRows(Witcher3ModsCurrent:Object, Witcher3ModsPS:Boolean):Array
      {
         var Witcher3ModsRows:Array = [];
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtAButton, Witcher3ModsPS ? "Cross" : "A");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtBButton, Witcher3ModsPS ? "Circle" : "B");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtXButton, Witcher3ModsPS ? "Square" : "X");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtYButton, Witcher3ModsPS ? "Triangle" : "Y");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtLeftBumper, Witcher3ModsPS ? "L1" : "LB");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtRightBumper, Witcher3ModsPS ? "R1" : "RB");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtLeftTrigger, Witcher3ModsPS ? "L2" : "LT");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtRightTrigger, Witcher3ModsPS ? "R2" : "RT");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtLeftJoy, "L stick / L3");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtRightJoy, "R stick / R3");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtDPad, "D-pad");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtStartButton, Witcher3ModsPS ? "Options" : "Menu");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtSelectButton, Witcher3ModsPS ? "Touchpad" : "View");
         Witcher3ModsAppendMappingRows(Witcher3ModsRows, Witcher3ModsCurrent.txtLeftJoyRightJoy, "L3 + R3");
         return Witcher3ModsRows;
      }

      private function Witcher3ModsMeasureTitle(Witcher3ModsTitle:String):Number
      {
         if (!Witcher3ModsMappingMeasure)
         {
            Witcher3ModsMappingMeasure = new TextField();
            Witcher3ModsMappingMeasure.embedFonts = txtLayoutName.embedFonts;
            Witcher3ModsMappingMeasure.defaultTextFormat = txtLayoutName.defaultTextFormat;
            Witcher3ModsMappingMeasure.wordWrap = false;
            Witcher3ModsMappingMeasure.autoSize = "left";
         }
         Witcher3ModsMappingMeasure.htmlText = Witcher3ModsTitle;
         return Witcher3ModsMappingMeasure.textWidth;
      }

      private function Witcher3ModsUpdateMappingTable():void
      {
         var Witcher3ModsTable:KeyBindsOptionModule = Witcher3ModsMappingTable();
         if (!Witcher3ModsTable || !dataArray || selectedIndex < 0 || selectedIndex >= dataArray.length) return;
         // This build targets the PC menu; preserve console-specific timelines.
         if (platformType != PlatformType.PLATFORM_PC && platformType != PlatformType.PLATFORM_PC_GDK) return;
         if (!Witcher3ModsMappingGeometry)
         {
            var Witcher3ModsBounds:flash.geom.Rectangle = getBounds(parent);
            Witcher3ModsMappingGeometry = {x:x, y:y, sx:scaleX, sy:scaleY,
               left:Witcher3ModsBounds.left, top:Witcher3ModsBounds.top,
               width:Witcher3ModsBounds.width};
         }
         var Witcher3ModsCurrent:Object = dataArray[selectedIndex];
         var Witcher3ModsPad:uint = InputManager.getInstance().gamepadType;
         var Witcher3ModsPS:Boolean = Witcher3ModsPad == EInputDeviceType.IDT_PS4 || Witcher3ModsPad == EInputDeviceType.IDT_PS5;
         var Witcher3ModsEditable:Boolean = Witcher3ModsCurrent.w3mRows != null && Witcher3ModsCurrent.w3mRows.length > 0;
         var Witcher3ModsRows:Array = Witcher3ModsEditable ? [].concat(Witcher3ModsCurrent.w3mRows) : Witcher3ModsNativeRows(Witcher3ModsCurrent, Witcher3ModsPS);

         scaleX = Witcher3ModsMappingGeometry.sx * 0.43;
         scaleY = Witcher3ModsMappingGeometry.sy * 0.43;
         Witcher3ModsBounds = getBounds(parent);
         x += Witcher3ModsMappingGeometry.left + Witcher3ModsMappingGeometry.width * 0.57 - Witcher3ModsBounds.left;
         y += Witcher3ModsMappingGeometry.top + 130 - Witcher3ModsBounds.top;
         Witcher3ModsTable.Witcher3ModsShowMappingPreview(Witcher3ModsRows,
            Witcher3ModsMappingGeometry.left, Witcher3ModsMappingGeometry.top + 110,
            Witcher3ModsMappingGeometry.width * 0.54,
            Witcher3ModsEditable, selectedIndex, Witcher3ModsCurrent.w3mPrompt ? Witcher3ModsCurrent.w3mPrompt : "");

         // The pad column shows only the pad; the context switcher lives above both columns.
         if (txtLayoutName) txtLayoutName.visible = false;
         if (mcLeftPCButton) mcLeftPCButton.visible = false;
         if (mcRightPCButton) mcRightPCButton.visible = false;

         if (!Witcher3ModsMappingHeading)
         {
            Witcher3ModsMappingHeading = new TextField();
            Witcher3ModsMappingHeading.mouseEnabled = false;
            Witcher3ModsMappingHeading.selectable = false;
            Witcher3ModsMappingHeading.embedFonts = txtLayoutName.embedFonts;
            Witcher3ModsMappingHeading.defaultTextFormat = txtLayoutName.defaultTextFormat;
            Witcher3ModsMappingHeading.multiline = true;
            Witcher3ModsMappingHeading.wordWrap = false;
            parent.addChild(Witcher3ModsMappingHeading);
            Witcher3ModsMappingPrevArrow = Witcher3ModsCreateMappingArrow(-1);
            Witcher3ModsMappingNextArrow = Witcher3ModsCreateMappingArrow(1);
         }
         // Fixed width from the longest context name, so the arrows never move between contexts.
         var Witcher3ModsTitleWidth:Number = 0;
         for each (var Witcher3ModsLayoutData:Object in dataArray)
            Witcher3ModsTitleWidth = Math.max(Witcher3ModsTitleWidth, Witcher3ModsMeasureTitle(Witcher3ModsLayoutData.layoutName));
         Witcher3ModsTitleWidth += 12;
         var Witcher3ModsSpan:Number = Witcher3ModsTitleWidth + 2 * (18 + 28);
         var Witcher3ModsStart:Number = Witcher3ModsMappingGeometry.left + (Witcher3ModsMappingGeometry.width - Witcher3ModsSpan) / 2;
         Witcher3ModsMappingHeading.autoSize = "none";
         Witcher3ModsMappingHeading.width = Witcher3ModsTitleWidth;
         Witcher3ModsMappingHeading.height = 95;
         Witcher3ModsMappingHeading.htmlText = "<p align='center'>" + Witcher3ModsCurrent.layoutName + "</p><p align='center'><font size='20' color='#C6A967'>" +
            (Witcher3ModsCurrent.w3mSubtitle ? Witcher3ModsCurrent.w3mSubtitle : "P1 / DEFAULT LAYOUT") + "</font></p>";
         Witcher3ModsMappingHeading.x = Witcher3ModsStart + 18 + 28;
         Witcher3ModsMappingHeading.y = Witcher3ModsMappingGeometry.top;
         var Witcher3ModsLine:flash.text.TextLineMetrics = Witcher3ModsMappingHeading.getLineMetrics(0);
         var Witcher3ModsArrowY:Number = Witcher3ModsMappingGeometry.top + 2 + Math.max(0, (Witcher3ModsLine.height - 28) / 2);
         Witcher3ModsMappingPrevArrow.x = Witcher3ModsStart;
         Witcher3ModsMappingPrevArrow.y = Witcher3ModsArrowY;
         Witcher3ModsMappingNextArrow.x = Witcher3ModsStart + Witcher3ModsSpan - 18;
         Witcher3ModsMappingNextArrow.y = Witcher3ModsArrowY;
         Witcher3ModsMappingHeading.visible = true;
         Witcher3ModsMappingPrevArrow.visible = true;
         Witcher3ModsMappingNextArrow.visible = true;
         Witcher3ModsShowHints(Witcher3ModsCurrent, Witcher3ModsEditable);
      }

      private function Witcher3ModsHideMappingTable():void
      {
         var Witcher3ModsTable:KeyBindsOptionModule = Witcher3ModsMappingTable();
         if (Witcher3ModsTable && Witcher3ModsTable.Witcher3ModsMappingPreview) Witcher3ModsTable.hide();
         if (Witcher3ModsMappingHeading) Witcher3ModsMappingHeading.visible = false;
         if (Witcher3ModsMappingPrevArrow) Witcher3ModsMappingPrevArrow.visible = false;
         if (Witcher3ModsMappingNextArrow) Witcher3ModsMappingNextArrow.visible = false;
         var Witcher3ModsMenu:IngameMenu = parent as IngameMenu;
         if (Witcher3ModsMenu && Witcher3ModsMenu.mcInputFeedbackModule)
         {
            Witcher3ModsMenu.mcInputFeedbackModule.removeButton(Witcher3ModsContextHintId, true);
            Witcher3ModsMenu.mcInputFeedbackModule.removeButton(Witcher3ModsChangeHintId, true);
         }
         if (txtLayoutName) txtLayoutName.visible = true;
         if (mcLeftPCButton) mcLeftPCButton.visible = true;
         if (mcRightPCButton) mcRightPCButton.visible = true;
         if (Witcher3ModsMappingGeometry)
         {
            x = Witcher3ModsMappingGeometry.x;
            y = Witcher3ModsMappingGeometry.y;
            scaleX = Witcher3ModsMappingGeometry.sx;
            scaleY = Witcher3ModsMappingGeometry.sy;
         }
      }

