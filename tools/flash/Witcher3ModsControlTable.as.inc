      public var Witcher3ModsMappingPreview:Boolean = false;
      private var Witcher3ModsTableGeometry:Object;
      private var Witcher3ModsTableColumn:int = 1;
      private var Witcher3ModsCellFocus:flash.display.Shape;
      private var Witcher3ModsLastMove:int = 0;
      private var Witcher3ModsLastMoveTime:int = 0;
      private var Witcher3ModsEditable:Boolean = false;
      private var Witcher3ModsPrompt:String = "";
      private var Witcher3ModsCapturing:Boolean = false;
      private var Witcher3ModsCaptureRow:Object;
      private var Witcher3ModsCaptureLayer:flash.display.Sprite;
      private var Witcher3ModsCaptureText:TextField;
      private var Witcher3ModsLayoutMemory:int = -1;
      private var Witcher3ModsRowMemory:int = 0;
      private var Witcher3ModsScrollMemory:int = 0;
      private var Witcher3ModsAllRows:Array;
      private var Witcher3ModsSwapShift:Number = 0;
      // The native table has 11 renderers on its timeline; the mapping table adds two more so it is not cut short.
      private static const Witcher3ModsNativeRowCount:int = 11;
      private static const Witcher3ModsExtraRowCount:int = 2;
      private var Witcher3ModsExtraRenderers:Array = [];
      private var Witcher3ModsScrollGrowth:Number = 0;
      private var Witcher3ModsVisibleRows:int = 11;
      private function Witcher3ModsNativeRenderers():Vector.<scaleform.clik.interfaces.IListItemRenderer>
      {
         var Witcher3ModsList:Vector.<scaleform.clik.interfaces.IListItemRenderer> = new Vector.<scaleform.clik.interfaces.IListItemRenderer>();
         Witcher3ModsList.push(mcItemRenderer1, mcItemRenderer2, mcItemRenderer3, mcItemRenderer4, mcItemRenderer5, mcItemRenderer6,
            mcItemRenderer7, mcItemRenderer8, mcItemRenderer9, mcItemRenderer10, mcItemRenderer11);
         return Witcher3ModsList;
      }

      // Returns 0 on success; any other value leaves the native 11 rows.
      private function Witcher3ModsAddExtraRows():int
      {
         if (Witcher3ModsExtraRenderers.length > 0) return 0;
         try
         {
            var Witcher3ModsStep:Number = (mcItemRenderer11.y - mcItemRenderer1.y) / (Witcher3ModsNativeRowCount - 1);
            if (!(Witcher3ModsStep > 0)) return 2;
            var Witcher3ModsList:Vector.<scaleform.clik.interfaces.IListItemRenderer> = Witcher3ModsNativeRenderers();
            // The rows are instances of the timeline symbol (mcKeybindItemRenderer), not of the bare base class.
            var Witcher3ModsRowClass:Class = Object(mcItemRenderer1).constructor as Class;
            for (var Witcher3ModsIndex:int = 0; Witcher3ModsIndex < Witcher3ModsExtraRowCount; Witcher3ModsIndex++)
            {
               var Witcher3ModsExtra:KeybindItemRenderer = new Witcher3ModsRowClass() as KeybindItemRenderer;
               if (!Witcher3ModsExtra)
               {
                  Witcher3ModsRemoveExtraRows();
                  return 4;
               }
               if (!Witcher3ModsExtra.txtKeybind || !Witcher3ModsExtra.mcLockedIcon)
               {
                  Witcher3ModsRemoveExtraRows();
                  return 3;
               }
               Witcher3ModsExtra.transform.matrix = mcItemRenderer1.transform.matrix.clone();
               Witcher3ModsExtra.y = mcItemRenderer1.y + Witcher3ModsStep * (Witcher3ModsNativeRowCount + Witcher3ModsIndex);
               addChildAt(Witcher3ModsExtra, getChildIndex(mcItemRenderer11) + 1 + Witcher3ModsIndex);
               Witcher3ModsExtraRenderers.push(Witcher3ModsExtra);
               Witcher3ModsList.push(Witcher3ModsExtra);
            }
            mcList.itemRendererList = Witcher3ModsList;
            if (mcScrollbar && Witcher3ModsScrollGrowth == 0)
            {
               Witcher3ModsScrollGrowth = Witcher3ModsStep * Witcher3ModsExtraRowCount;
               mcScrollbar.height = mcScrollbar.height + Witcher3ModsScrollGrowth;
            }
            Witcher3ModsVisibleRows = Witcher3ModsNativeRowCount + Witcher3ModsExtraRowCount;
         }
         catch (Witcher3ModsError:Error)
         {
            Witcher3ModsRemoveExtraRows();
            return 1;
         }
         return 0;
      }

      // Back to the native 11 renderers (also used before the native PC keybind table is shown).
      private function Witcher3ModsRemoveExtraRows():void
      {
         if (Witcher3ModsExtraRenderers.length == 0 && Witcher3ModsScrollGrowth == 0) return;
         mcList.itemRendererList = Witcher3ModsNativeRenderers();
         for each (var Witcher3ModsExtra:KeybindItemRenderer in Witcher3ModsExtraRenderers)
         {
            if (Witcher3ModsExtra.parent == this) removeChild(Witcher3ModsExtra);
         }
         Witcher3ModsExtraRenderers = [];
         if (mcScrollbar && Witcher3ModsScrollGrowth != 0) mcScrollbar.height = mcScrollbar.height - Witcher3ModsScrollGrowth;
         Witcher3ModsScrollGrowth = 0;
         Witcher3ModsVisibleRows = Witcher3ModsNativeRowCount;
      }

      public function Witcher3ModsShowMappingPreview(Witcher3ModsRows:Array, Witcher3ModsLeft:Number, Witcher3ModsTop:Number, Witcher3ModsWidth:Number, Witcher3ModsCanEdit:Boolean, Witcher3ModsLayout:int, Witcher3ModsPromptText:String):void
      {
         var Witcher3ModsKeep:Boolean = Witcher3ModsLayout == Witcher3ModsLayoutMemory;
         if (!Witcher3ModsTableGeometry)
         {
            Witcher3ModsTableGeometry = {x:x, y:y, sx:scaleX, sy:scaleY,
               reset:mcResetDefaultsButtonPC.visible, safety:mcSafetiesEnabledButtonPC.visible};
         }
         Witcher3ModsMappingPreview = true;
         Witcher3ModsEditable = Witcher3ModsCanEdit;
         Witcher3ModsPrompt = Witcher3ModsPromptText;
         Witcher3ModsEndCapture();
         stopChangingKeybind();
         // Avoid showWithData: its first-open path changes global smart-keybind state.
         super.show();
         mcResetDefaultsButtonPC.visible = false;
         mcSafetiesEnabledButtonPC.visible = false;
         Witcher3ModsAllRows = Witcher3ModsRows;
         Witcher3ModsAddExtraRows();
         mcList.dataProvider = new DataProvider(Witcher3ModsRows);
         mcList.scrollPosition = Witcher3ModsKeep ? Witcher3ModsScrollMemory : 0;
         mcList.selectedIndex = Witcher3ModsKeep ? Math.max(0, Math.min(Witcher3ModsRows.length - 1, Witcher3ModsRowMemory)) : 0;
         Witcher3ModsLayoutMemory = Witcher3ModsLayout;
         mcList.validateNow();
         registerMouseEvents();
         // Measure the table itself; the hidden full-screen rebind dialog is larger.
         var Witcher3ModsBounds:flash.geom.Rectangle = mcItemRenderer1.getBounds(this);
         if (mcScrollbar) Witcher3ModsBounds = Witcher3ModsBounds.union(mcScrollbar.getBounds(this));
         var Witcher3ModsScale:Number = Witcher3ModsWidth / Witcher3ModsBounds.width;
         scaleX = Witcher3ModsScale;
         scaleY = Witcher3ModsScale;
         Witcher3ModsBounds = mcItemRenderer1.getBounds(parent);
         x += Witcher3ModsLeft - Witcher3ModsBounds.left;
         var Witcher3ModsHeader:TextField = getChildByName("tfAction") as TextField;
         if (Witcher3ModsHeader) Witcher3ModsBounds = Witcher3ModsHeader.getBounds(parent);
         y += Witcher3ModsTop - Witcher3ModsBounds.top;
         Witcher3ModsDrawCell();
      }

      private function Witcher3ModsOnHide():void
      {
         Witcher3ModsEndCapture();
         Witcher3ModsLayoutMemory = -1;
         if (Witcher3ModsCellFocus) Witcher3ModsCellFocus.visible = false;
      }

      private function Witcher3ModsRestoreTable():void
      {
         Witcher3ModsEndCapture();
         Witcher3ModsRemoveExtraRows();
         if (Witcher3ModsCellFocus) Witcher3ModsCellFocus.visible = false;
         if (Witcher3ModsTableGeometry)
         {
            x = Witcher3ModsTableGeometry.x;
            y = Witcher3ModsTableGeometry.y;
            scaleX = Witcher3ModsTableGeometry.sx;
            scaleY = Witcher3ModsTableGeometry.sy;
            mcResetDefaultsButtonPC.visible = Witcher3ModsTableGeometry.reset;
            mcSafetiesEnabledButtonPC.visible = Witcher3ModsTableGeometry.safety;
         }
      }

      private function Witcher3ModsDrawCell():void
      {
         if (!Witcher3ModsCellFocus)
         {
            Witcher3ModsCellFocus = new flash.display.Shape();
            addChild(Witcher3ModsCellFocus);
         }
         Witcher3ModsCellFocus.graphics.clear();
         var Witcher3ModsRenderer:KeybindItemRenderer = mcList.getSelectedRenderer() as KeybindItemRenderer;
         if (!Witcher3ModsRenderer || !Witcher3ModsRenderer.data) return;
         var Witcher3ModsRowBounds:flash.geom.Rectangle = Witcher3ModsRenderer.getBounds(this);
         var Witcher3ModsKeyBounds:flash.geom.Rectangle = Witcher3ModsRenderer.txtKeybind.getBounds(this);
         var Witcher3ModsLeft:Number = Witcher3ModsTableColumn == 0 ? Witcher3ModsRowBounds.left : Witcher3ModsKeyBounds.left;
         var Witcher3ModsRight:Number = Witcher3ModsTableColumn == 0 ? Witcher3ModsKeyBounds.left : Witcher3ModsKeyBounds.right;
         Witcher3ModsCellFocus.graphics.lineStyle(2, 0xC6A967);
         Witcher3ModsCellFocus.graphics.drawRect(Witcher3ModsLeft + 3, Witcher3ModsRowBounds.top + 3,
            Math.max(0, Witcher3ModsRight - Witcher3ModsLeft - 6), Math.max(0, Witcher3ModsRowBounds.height - 6));
         Witcher3ModsCellFocus.visible = true;
      }

      // Swap mode: the same table, filtered to the other editable rows, shown over a dimmed screen.
      private function Witcher3ModsBeginCapture():void
      {
         var Witcher3ModsRenderer:KeybindItemRenderer = mcList.getSelectedRenderer() as KeybindItemRenderer;
         if (!Witcher3ModsEditable || !Witcher3ModsRenderer || !Witcher3ModsRenderer.data) return;
         var Witcher3ModsSource:Object = Witcher3ModsRenderer.data;
         if (Witcher3ModsSource.locked || !Witcher3ModsSource.tag || !Witcher3ModsSource.key)
         {
            dispatchEvent(new GameEvent(GameEvent.CALL,"OnLockedKeybindTried"));
            return;
         }
         var Witcher3ModsTargets:Array = [];
         for each (var Witcher3ModsRow:Object in Witcher3ModsAllRows)
         {
            if (!Witcher3ModsRow.locked && Witcher3ModsRow.tag && Witcher3ModsRow.key && Witcher3ModsRow.key != Witcher3ModsSource.key)
               Witcher3ModsTargets.push(Witcher3ModsRow);
         }
         if (Witcher3ModsTargets.length == 0)
         {
            dispatchEvent(new GameEvent(GameEvent.CALL,"OnLockedKeybindTried"));
            return;
         }
         Witcher3ModsCaptureRow = Witcher3ModsSource;
         Witcher3ModsCapturing = true;
         if (!Witcher3ModsCaptureLayer)
         {
            Witcher3ModsCaptureLayer = new flash.display.Sprite();
            Witcher3ModsCaptureText = new TextField();
            Witcher3ModsCaptureText.selectable = false;
            Witcher3ModsCaptureText.mouseEnabled = false;
            Witcher3ModsCaptureText.multiline = true;
            Witcher3ModsCaptureText.wordWrap = true;
            var Witcher3ModsHeader:TextField = getChildByName("tfAction") as TextField;
            if (Witcher3ModsHeader)
            {
               Witcher3ModsCaptureText.embedFonts = Witcher3ModsHeader.embedFonts;
               Witcher3ModsCaptureText.defaultTextFormat = Witcher3ModsHeader.defaultTextFormat;
            }
            Witcher3ModsCaptureLayer.addChild(Witcher3ModsCaptureText);
         }
         parent.addChild(Witcher3ModsCaptureLayer);
         parent.setChildIndex(this, parent.numChildren - 1);
         var Witcher3ModsWidth:Number = stage.stageWidth;
         var Witcher3ModsHeight:Number = stage.stageHeight;
         Witcher3ModsCaptureLayer.graphics.clear();
         Witcher3ModsCaptureLayer.graphics.beginFill(0x000000, 0.92);
         Witcher3ModsCaptureLayer.graphics.drawRect(0, 0, Witcher3ModsWidth, Witcher3ModsHeight);
         Witcher3ModsCaptureLayer.graphics.endFill();

         mcList.dataProvider = new DataProvider(Witcher3ModsTargets);
         mcList.scrollPosition = 0;
         mcList.selectedIndex = 0;
         mcList.validateNow();
         // Centre the table on screen while swapping.
         var Witcher3ModsBounds:flash.geom.Rectangle = mcItemRenderer1.getBounds(parent);
         if (mcScrollbar) Witcher3ModsBounds = Witcher3ModsBounds.union(mcScrollbar.getBounds(parent));
         Witcher3ModsSwapShift = Witcher3ModsWidth / 2 - (Witcher3ModsBounds.left + Witcher3ModsBounds.right) / 2;
         x += Witcher3ModsSwapShift;
         var Witcher3ModsTop:Number = Witcher3ModsBounds.top;
         var Witcher3ModsTitle:TextField = getChildByName("tfAction") as TextField;
         if (Witcher3ModsTitle) Witcher3ModsTop = Witcher3ModsTitle.getBounds(parent).top;

         var Witcher3ModsFormat:flash.text.TextFormat = Witcher3ModsCaptureText.defaultTextFormat;
         Witcher3ModsFormat.size = 40;
         Witcher3ModsFormat.align = "center";
         Witcher3ModsFormat.color = 0xC6A967;
         Witcher3ModsCaptureText.defaultTextFormat = Witcher3ModsFormat;
         Witcher3ModsCaptureText.x = Witcher3ModsWidth * 0.1;
         Witcher3ModsCaptureText.width = Witcher3ModsWidth * 0.8;
         Witcher3ModsCaptureText.height = 130;
         Witcher3ModsCaptureText.htmlText = Witcher3ModsPrompt + "<br><font size='26' color='#FFFFFF'>" + Witcher3ModsSource.label + " - " + Witcher3ModsSource.value + "</font>";
         Witcher3ModsCaptureText.y = Math.max(10, Witcher3ModsTop - 150);
         Witcher3ModsCaptureLayer.visible = true;
         Witcher3ModsDrawCell();
      }

      private function Witcher3ModsEndCapture():void
      {
         var Witcher3ModsWasCapturing:Boolean = Witcher3ModsCapturing;
         Witcher3ModsCapturing = false;
         Witcher3ModsCaptureRow = null;
         if (Witcher3ModsCaptureLayer) Witcher3ModsCaptureLayer.visible = false;
         if (!Witcher3ModsWasCapturing) return;
         x -= Witcher3ModsSwapShift;
         Witcher3ModsSwapShift = 0;
         if (Witcher3ModsAllRows)
         {
            mcList.dataProvider = new DataProvider(Witcher3ModsAllRows);
            mcList.scrollPosition = Witcher3ModsScrollMemory;
            mcList.selectedIndex = Math.max(0, Math.min(Witcher3ModsAllRows.length - 1, Witcher3ModsRowMemory));
            mcList.validateNow();
            Witcher3ModsDrawCell();
         }
      }

      private function Witcher3ModsConfirmSwap():void
      {
         var Witcher3ModsRenderer:KeybindItemRenderer = mcList.getSelectedRenderer() as KeybindItemRenderer;
         var Witcher3ModsSource:Object = Witcher3ModsCaptureRow;
         if (!Witcher3ModsRenderer || !Witcher3ModsRenderer.data || !Witcher3ModsSource) return;
         var Witcher3ModsTarget:Object = Witcher3ModsRenderer.data;
         Witcher3ModsEndCapture();
         // Swap the two keys so every action stays bound.
         dispatchEvent(new GameEvent(GameEvent.CALL,"OnChangeKeybind",[uint(Witcher3ModsSource.tag),uint(Witcher3ModsTarget.key)]));
         dispatchEvent(new GameEvent(GameEvent.CALL,"OnChangeKeybind",[uint(Witcher3ModsTarget.tag),uint(Witcher3ModsSource.key)]));
      }

      private function Witcher3ModsPreviewInput(Witcher3ModsEvent:InputEvent):void
      {
         if (!visible || Witcher3ModsEvent.handled) return;
         var Witcher3ModsDetails:InputDetails = Witcher3ModsEvent.details;
         var Witcher3ModsDirection:int = 0;
         var Witcher3ModsColumn:int = -1;
         var Witcher3ModsAccept:Boolean = Witcher3ModsDetails.navEquivalent == NavigationCode.GAMEPAD_A || Witcher3ModsDetails.code == KeyCode.ENTER || Witcher3ModsDetails.code == KeyCode.E;
         if (Witcher3ModsDetails.navEquivalent == NavigationCode.UP || Witcher3ModsDetails.code == KeyCode.UP || Witcher3ModsDetails.code == KeyCode.PAD_DIGIT_UP) Witcher3ModsDirection = -1;
         if (Witcher3ModsDetails.navEquivalent == NavigationCode.DOWN || Witcher3ModsDetails.code == KeyCode.DOWN || Witcher3ModsDetails.code == KeyCode.PAD_DIGIT_DOWN) Witcher3ModsDirection = 1;
         if (Witcher3ModsDetails.code == KeyCode.PAGE_UP) Witcher3ModsDirection = -11;
         if (Witcher3ModsDetails.code == KeyCode.PAGE_DOWN) Witcher3ModsDirection = 11;
         if (Witcher3ModsDetails.navEquivalent == NavigationCode.LEFT || Witcher3ModsDetails.code == KeyCode.LEFT || Witcher3ModsDetails.code == KeyCode.PAD_DIGIT_LEFT) Witcher3ModsColumn = 0;
         if (Witcher3ModsDetails.navEquivalent == NavigationCode.RIGHT || Witcher3ModsDetails.code == KeyCode.RIGHT || Witcher3ModsDetails.code == KeyCode.PAD_DIGIT_RIGHT) Witcher3ModsColumn = 1;
         // Own row/cell navigation; never forward these keys to the global editor.
         if (Witcher3ModsDirection || Witcher3ModsColumn >= 0)
         {
            Witcher3ModsEvent.handled = true;
            if (Witcher3ModsDetails.value != InputValue.KEY_DOWN && Witcher3ModsDetails.value != InputValue.KEY_HOLD) return;
            if (!mcList.dataProvider || mcList.dataProvider.length == 0) return;
            if (Witcher3ModsColumn >= 0) Witcher3ModsTableColumn = Witcher3ModsColumn;
            if (Witcher3ModsDirection)
            {
               // One physical press can reach the menu as both a key and a navigation event.
               var Witcher3ModsNow:int = getTimer();
               if (Witcher3ModsDirection == Witcher3ModsLastMove && Witcher3ModsNow - Witcher3ModsLastMoveTime < 70) return;
               Witcher3ModsLastMove = Witcher3ModsDirection;
               Witcher3ModsLastMoveTime = Witcher3ModsNow;
            }
            mcList.selectedIndex = Math.max(0, Math.min(mcList.dataProvider.length - 1, mcList.selectedIndex + Witcher3ModsDirection));
            mcList.validateNow();
            if (!Witcher3ModsCapturing)
            {
               Witcher3ModsRowMemory = mcList.selectedIndex;
               Witcher3ModsScrollMemory = mcList.scrollPosition;
            }
            Witcher3ModsDrawCell();
         }
         else if (Witcher3ModsCapturing)
         {
            Witcher3ModsEvent.handled = true;
            if (Witcher3ModsDetails.value != InputValue.KEY_UP) return;
            if (Witcher3ModsAccept) Witcher3ModsConfirmSwap();
            else if (Witcher3ModsDetails.code == KeyCode.ESCAPE || Witcher3ModsDetails.code == KeyCode.PAD_BACK_SELECT || Witcher3ModsDetails.navEquivalent == NavigationCode.GAMEPAD_B) Witcher3ModsEndCapture();
         }
         else if (Witcher3ModsEditable && Witcher3ModsDetails.value == InputValue.KEY_UP && Witcher3ModsAccept)
         {
            Witcher3ModsEvent.handled = true;
            Witcher3ModsBeginCapture();
         }
      }
      private function Witcher3ModsPreviewDoubleClick():void
      {
         if (!Witcher3ModsCapturing) Witcher3ModsBeginCapture();
      }
