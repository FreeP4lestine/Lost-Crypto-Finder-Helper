; ======================================================================================================================
; Scriptname:     Class_RichEdit.ahk
; Namespace:      RichEdit
; Author:         just me
; AHK Version:    1.1.21.03 (Unicode)
; OS Version:     Win 8.1 (x64)
; Function:       The class provides some wrapper functions for rich edit controls (v4.1 Unicode).
; Change History:
;    0.1.05.00    2015-04-14/just me - fixed LoadRTF() not closing the file after reading
;    0.1.04.00    2014-08-27/just me - fixed SetParaIndent() and changed indentation sample
;    0.1.03.00    2014-03-03/just me - added GetTextRange()
;    0.1.02.00    2013-12-01/just me - changed SetText() to handle RTF formatted text properly
;    0.1.01.00    2013-11-29/just me - bug fix -> GetSelText()
;    0.1.00.00    2013-11-17/just me - initial beta release
; Credits:
;    corrupt for cRichEdit:
;       http://www.autohotkey.com/board/topic/17869-crichedit-standard-richedit-control-for-autohotkey-scripts/
;    jballi for HE_Print:
;       http://www.autohotkey.com/board/topic/45513-function-he-print-wysiwyg-print-for-the-hiedit-control/
;    majkinetor for Dlg:
;       http://www.autohotkey.com/board/topic/15836-module-dlg-501/
; ======================================================================================================================
Class RichEdit {
   ; ===================================================================================================================
   ; Class variables - do not change !!!
   ; ===================================================================================================================
   ; RichEdit v4.1 (Unicode)
   Static Class := "RICHEDIT50W"
   ; RichEdit v4.1 (Unicode)
   Static DLL := "Msftedit.dll"
   ; DLL handle
   Static Instance := DllCall("Kernel32.dll\LoadLibrary", "Str", RichEdit.DLL, "UPtr")
   ; Callback function handling RichEdit messages
   Static SubclassCB := 0
   ; Number of controls/instances
   Static Controls := 0
   ; ===================================================================================================================
   ; Instance variables - do not change !!!
   ; ===================================================================================================================
   GuiName := ""
   GuiHwnd := ""
   HWND := ""
   DefFont := ""
   ; ===================================================================================================================
   ; CONSTRUCTOR
   ; ===================================================================================================================
   __New(GuiName, Options, MultiLine := True) {
      Static WS_TABSTOP := 0x10000, WS_HSCROLL := 0x100000, WS_VSCROLL := 0x200000, WS_VISIBLE := 0x10000000
           , WS_CHILD := 0x40000000
           , WS_EX_CLIENTEDGE := 0x200, WS_EX_STATICEDGE := 0x20000
           , ES_MULTILINE := 0x0004, ES_AUTOVSCROLL := 0x40, ES_AUTOHSCROLL := 0x80, ES_NOHIDESEL := 0x0100
           , ES_WANTRETURN := 0x1000, ES_DISABLENOSCROLL := 0x2000, ES_SUNKEN := 0x4000, ES_SAVESEL := 0x8000
           , ES_SELECTIONBAR := 0x1000000
      ; Check for Unicode
      If !(SubStr(A_AhkVersion, 1, 1) > 1) && !(A_IsUnicode) {
         MsgBox, 16, % A_ThisFunc, % This.__Class . " requires a unicode version of AHK!"
         Return False
      }
      ; Do not instantiate instances of RichEdit
      If (This.Base.HWND)
         Return False
      ; Determine the HWND of the GUI
      Gui, %GuiName%:+LastFoundExist
      GuiHwnd := WinExist()
      If !(GuiHwnd) {
         ErrorLevel := "ERROR: Gui " . GuiName . " does not exist!"
         Return False
      }
      ; Load library if necessary
      If (This.Base.Instance = 0) {
         This.Base.Instance := DllCall("Kernel32.dll\LoadLibrary", "Str", This.Base.DLL, "UPtr")
         If (ErrorLevel) {
            ErrorLevel := "ERROR: Error loading " . This.Base.DLL . " - " . ErrorLevel
            Return False
         }
      }
      ; Specify default styles & exstyles
      Styles := WS_TABSTOP | WS_VISIBLE | WS_CHILD | ES_AUTOHSCROLL
      If (MultiLine)
         Styles |= WS_HSCROLL | WS_VSCROLL | ES_MULTILINE | ES_AUTOVSCROLL | ES_NOHIDESEL | ES_WANTRETURN
                 | ES_DISABLENOSCROLL | ES_SAVESEL ; | ES_SELECTIONBAR does not work properly
      ExStyles := WS_EX_STATICEDGE
      ; Create the control
      CtrlClass := This.Class
      Gui, %GuiName%:Add, Custom, Class%CtrlClass% %Options% hwndHWND +%Styles% +E%ExStyles%
      If (MultiLine) {
         ; Adjust the formatting rectangle for multiline controls to simulate a selection bar
         ; EM_GETRECT = 0xB2, EM_SETRECT = 0xB3
         VarSetCapacity(RECT, 16, 0)
         SendMessage, 0xB2, 0, &RECT, , ahk_id %HWND%
         NumPut(NumGet(RECT, 0, "Int") + 10, RECT, 0, "Int")
         NumPut(NumGet(RECT, 4, "Int") + 2,  RECT, 4, "Int")
         SendMessage, 0xB3, 0, &RECT, , ahk_id %HWND%
         ; Set advanced typographic options
         ; EM_SETTYPOGRAPHYOPTIONS = 0x04CA (WM_USER + 202)
         ; TO_ADVANCEDTYPOGRAPHY	= 1, TO_ADVANCEDLAYOUT = 8 ? not documented
         SendMessage, 0x04CA, 0x01, 0x01, , ahk_id %HWND%
      }
      ; Initialize control
      ; EM_SETLANGOPTIONS = 0x0478 (WM_USER + 120)
      ; IMF_AUTOKEYBOARD = 0x01, IMF_AUTOFONT = 0x02
      SendMessage, 0x0478, 0, 0x03, , ahk_id %HWND%
      ; Subclass the control to get Tab key and prevent Esc from sending a WM_CLOSE message to the parent window.
      ; One of majkinetor's splendid discoveries!
      ; Initialize SubclassCB
      If (This.Base.SubclassCB = 0)
         This.Base.SubclassCB := RegisterCallback("RichEdit.SubclassProc")
      DllCall("Comctl32.dll\SetWindowSubclass", "Ptr", HWND, "Ptr", This.Base.SubclassCB, "Ptr", HWND, "Ptr", 0)
      This.GuiName := GuiName
      This.GuiHwnd := GuiHwnd
      This.HWND := HWND
      This.DefFont := This.GetFont(1)
      This.DefFont.Default := 1
      ; Correct AHK font size setting, if necessary
      If (Round(This.DefFont.Size) <> This.DefFont.Size) {
         This.DefFont.Size := Round(This.DefFont.Size)
         This.SetDefaultFont()
      }
      This.Base.Controls += 1
      ; Initialize the print margins
      This.GetMargins()
      ; Initialize the text limit
      This.LimitText(2147483647)
   }
   ; ===================================================================================================================
   ; DESTRUCTOR
   ; ===================================================================================================================
   __Delete() {
      If (This.HWND) {
         DllCall("Comctl32.dll\RemoveWindowSubclass", "Ptr", This.HWND, "Ptr", This.Base.SubclassCB, "Ptr", 0)
         DllCall("User32.dll\DestroyWindow", "Ptr", This.HWND)
         This.HWND := 0
         This.Base.Controls -= 1
         If (This.Base.Controls = 0) {
            DllCall("Kernel32.dll\FreeLibrary", "Ptr", This.Base.Instance)
            This.Base.Instance := 0
         }
      }
   }
   ; ===================================================================================================================
   ; ===================================================================================================================
   ; INTERNAL CLASSES ==================================================================================================
   ; ===================================================================================================================
   ; ===================================================================================================================
   Class CF2 { ; CHARFORMAT2 structure -> http://msdn.microsoft.com/en-us/library/bb787883(v=vs.85).aspx
      __New() {
         Static CF2_Size := 116
         This.Insert(":", {Mask: {O: 4, T: "UInt"}, Effects: {O: 8, T: "UInt"}
                         , Height: {O: 12, T: "Int"}, Offset: {O: 16, T: "Int"}
                         , TextColor: {O: 20, T: "Int"}, CharSet: {O: 24, T: "UChar"}
                         , PitchAndFamily: {O: 25, T: "UChar"}, FaceName: {O: 26, T: "Str32"}
                         , Weight: {O: 90, T: "UShort"}, Spacing: {O: 92, T: "Short"}
                         , BackColor: {O: 96, T: "UInt"}, LCID: {O: 100, T: "UInt"}
                         , Cookie: {O: 104, T: "UInt"}, Style: {O: 108, T: "Short"}
                         , Kerning: {O: 110, T: "UShort"}, UnderlineType: {O: 112, T: "UChar"}
                         , Animation: {O: 113, T: "UChar"}, RevAuthor: {O: 114, T: "UChar"}
                         , UnderlineColor: {O: 115, T: "UChar"}})
         This.Insert(".")
         This.SetCapacity(".", CF2_Size)
         Addr :=  This.GetAddress(".")
         DllCall("Kernel32.dll\RtlZeroMemory", "Ptr", Addr, "Ptr", CF2_Size)
         NumPut(CF2_Size, Addr + 0, 0, "UInt")
      }
      __Get(Name) {
         Addr := This.GetAddress(".")
         If (Name = "CF2")
            Return Addr
         If !This[":"].HasKey(Name)
            Return ""
         Attr := This[":"][Name]
         If (Name <> "FaceName")
            Return NumGet(Addr + 0, Attr.O, Attr.T)
         Return StrGet(Addr + Attr.O, 32)
      }
      __Set(Name, Value) {
         Addr := This.GetAddress(".")
         If !This[":"].HasKey(Name)
            Return ""
         Attr := This[":"][Name]
         If (Name <> "FaceName")
            NumPut(Value, Addr + 0, Attr.O, Attr.T)
         Else
            StrPut(Value, Addr + Attr.O, 32)
         Return Value
      }
   }
   ; -------------------------------------------------------------------------------------------------------------------
   Class PF2 { ; PARAFORMAT2 structure -> http://msdn.microsoft.com/en-us/library/bb787942(v=vs.85).aspx
      __New() {
         Static PF2_Size := 188
         This.Insert(":", {Mask: {O: 4, T: "UInt"}, Numbering: {O: 8, T: "UShort"}
                         , StartIndent: {O: 12, T: "Int"}, RightIndent: {O: 16, T: "Int"}
                         , Offset: {O: 20, T: "Int"}, Alignment: {O: 24, T: "UShort"}
                         , TabCount: {O: 26, T: "UShort"}, Tabs: {O: 28, T: "UInt"}
                         , SpaceBefore: {O: 156, T: "Int"}, SpaceAfter: {O: 160, T: "Int"}
                         , LineSpacing: {O: 164, T: "Int"}, Style: {O: 168, T: "Short"}
                         , LineSpacingRule: {O: 170, T: "UChar"}, OutlineLevel: {O: 171, T: "UChar"}
                         , ShadingWeight: {O: 172, T: "UShort"}, ShadingStyle: {O: 174, T: "UShort"}
                         , NumberingStart: {O: 176, T: "UShort"}, NumberingStyle: {O: 178, T: "UShort"}
                         , NumberingTab: {O: 180, T: "UShort"}, BorderSpace: {O: 182, T: "UShort"}
                         , BorderWidth: {O: 184, T: "UShort"}, Borders: {O: 186, T: "UShort"}})
         This.Insert(".")
         This.SetCapacity(".", PF2_Size)
         Addr :=  This.GetAddress(".")
         DllCall("Kernel32.dll\RtlZeroMemory", "Ptr", Addr, "Ptr", PF2_Size)
         NumPut(PF2_Size, Addr + 0, 0, "UInt")
      }
      __Get(Name) {
         Addr := This.GetAddress(".")
         If (Name = "PF2")
            Return Addr
         If !This[":"].HasKey(Name)
            Return ""
         Attr := This[":"][Name]
         If (Name <> "Tabs")
            Return NumGet(Addr + 0, Attr.O, Attr.T)
         Tabs := []
         Offset := Attr.O - 4
         Loop, 32
            Tabs[A_Index] := NumGet(Addr + 0, Offset += 4, "UInt")
         Return Tabs
      }
      __Set(Name, Value) {
         Addr := This.GetAddress(".")
         If !This[":"].HasKey(Name)
            Return ""
         Attr := This[":"][Name]
         If (Name <> "Tabs") {
            NumPut(Value, Addr + 0, Attr.O, Attr.T)
            Return Value
         }
         If !IsObject(Value)
            Return ""
         Offset := Attr.O - 4
         For Each, Tab In Value
            NumPut(Tab, Addr + 0, Offset += 4, "UInt")
         Return Tabs
      }
   }
   ; ===================================================================================================================
   ; ===================================================================================================================
   ; PRIVATE METHODS ===================================================================================================
   ; ===================================================================================================================
   ; ===================================================================================================================
   GetBGR(RGB) { ; Get numeric BGR value from numeric RGB value or HTML color name
      Static HTML := {BLACK:  0x000000, SILVER: 0xC0C0C0, GRAY:   0x808080, WHITE:   0xFFFFFF
                    , MAROON: 0x000080, RED:    0x0000FF, PURPLE: 0x800080, FUCHSIA: 0xFF00FF
                    , GREEN:  0x008000, LIME:   0x00FF00, OLIVE:  0x008080, YELLOW:  0x00FFFF
                    , NAVY:   0x800000, BLUE:   0xFF0000, TEAL:   0x808000, AQUA:    0xFFFF00}
      If HTML.HasKey(RGB)
         Return HTML[RGB]
      Return ((RGB & 0xFF0000) >> 16) + (RGB & 0x00FF00) + ((RGB & 0x0000FF) << 16)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetRGB(BGR) {  ; Get numeric RGB value from numeric BGR-Value
      Return ((BGR & 0xFF0000) >> 16) + (BGR & 0x00FF00) + ((BGR & 0x0000FF) << 16)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetMeasurement() { ; Get locale measurement (metric / inch)
      ; LOCALE_USER_DEFAULT = 0x0400, LOCALE_IMEASURE = 0x0D, LOCALE_RETURN_NUMBER = 0x20000000
      Static Metric := 2.54  ; centimeters
           , Inches := 1.00  ; inches
           , Measurement := ""
           , Len := A_IsUnicode ? 2 : 4
      If (Measurement = "") {
         VarSetCapacity(LCD, 4, 0)
         DllCall("Kernel32.dll\GetLocaleInfo", "UInt", 0x400, "UInt", 0x2000000D, "Ptr", &LCD, "Int", Len)
         Measurement := NumGet(LCD, 0, "UInt") ? Inches : Metric
      }
      Return Measurement
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SubclassProc(M, W, L, I, R) { ; RichEdit subclassproc
      ; Left out first parameter HWND, will be found in "This" when called by system
      ; See -> http://msdn.microsoft.com/en-us/library/bb776774%28VS.85%29.aspx
      If (M = 0x87) ; WM_GETDLGCODE
         Return 4   ; DLGC_WANTALLKEYS
      Return DllCall("Comctl32.dll\DefSubclassProc", "Ptr", This, "UInt", M, "Ptr", W, "Ptr", L)
   }
   ; ===================================================================================================================
   ; ===================================================================================================================
   ; PUBLIC METHODS ====================================================================================================
   ; ===================================================================================================================
   ; ===================================================================================================================
   ; -------------------------------------------------------------------------------------------------------------------
   ; Methods to be used by advanced users only
   ; -------------------------------------------------------------------------------------------------------------------
   GetCharFormat() { ; Retrieves the character formatting of the current selection.
      ; For details see http://msdn.microsoft.com/en-us/library/bb787883(v=vs.85).aspx.
      ; Returns a 'CF2' object containing the formatting settings.
      ; EM_GETCHARFORMAT = 0x043A
      CF2 := New This.CF2
      SendMessage, 0x043A, 1, % CF2.CF2, , % "ahk_id " . This.HWND
      Return (CF2.Mask ? CF2 : False)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetCharFormat(CF2) { ; Sets character formatting of the current selection.
      ; For details see http://msdn.microsoft.com/en-us/library/bb787883(v=vs.85).aspx.
      ; CF2 : CF2 object like returned by GetCharFormat().
      ; EM_SETCHARFORMAT = 0x0444
      SendMessage, 0x0444, 1, % CF2.CF2, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetParaFormat() { ; Retrieves the paragraph formatting of the current selection.
      ; For details see http://msdn.microsoft.com/en-us/library/bb787942(v=vs.85).aspx.
      ; Returns a 'PF2' object containing the formatting settings.
      ; EM_GETPARAFORMAT = 0x043D
      PF2 := New This.PF2
      SendMessage, 0x043D, 0, % PF2.PF2, , % "ahk_id " . This.HWND
      Return (PF2.Mask ? PF2 : False)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetParaFormat(PF2) { ; Sets the  paragraph formatting for the current selection.
      ; For details see http://msdn.microsoft.com/en-us/library/bb787942(v=vs.85).aspx.
      ; PF2 : PF2 object like returned by GetParaFormat().
      ; EM_SETPARAFORMAT = 0x0447
      SendMessage, 0x0447, 0, % PF2.PF2, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Control specific
   ; -------------------------------------------------------------------------------------------------------------------
   IsModified() { ; Has the control been  modified?
      ; EM_GETMODIFY = 0xB8
      SendMessage, 0xB8, 0, 0, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetModified(Modified := False) { ; Sets or clears the modification flag for an edit control.
      ; EM_SETMODIFY = 0xB9
      SendMessage, 0xB9, % !!Modified, 0, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetEventMask(Events := "") { ; Set the events which shall send notification codes control's owner
      ; Events : Array containing one or more of the keys defined in 'ENM'.
      ; For details see http://msdn.microsoft.com/en-us/library/bb774238(v=vs.85).aspx
      ; EM_SETEVENTMASK	= 	0x0445
      Static ENM := {NONE: 0x00, CHANGE: 0x01, UPDATE: 0x02, SCROLL: 0x04, SCROLLEVENTS: 0x08, DRAGDROPDONE: 0x10
                   , PARAGRAPHEXPANDED: 0x20, PAGECHANGE: 0x40, KEYEVENTS: 0x010000, MOUSEEVENTS: 0x020000
                   , REQUESTRESIZE: 0x040000, SELCHANGE: 0x080000, DROPFILES: 0x100000, PROTECTED: 0x200000
                   , LINK: 0x04000000}
      If !IsObject(Events)
         Events := ["NONE"]
      Mask := 0
      For Each, Event In Events {
         If ENM.HasKey(Event)
            Mask |= ENM[Event]
         Else
            Return False
      }
      SendMessage, 0x0445, 0, %Mask%, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Loading and storing RTF format
   ; -------------------------------------------------------------------------------------------------------------------
   GetRTF(Selection := False) { ; Gets the whole content of the control as rich text.
      ; Selection = False : whole contents (default)
      ; Selection = True  : current selection
      ; EM_STREAMOUT = 0x044A
      ; SF_TEXT = 0x1, SF_RTF = 0x2, SF_RTFNOOBJS = 0x3, SF_UNICODE = 0x10, SF_USECODEPAGE =	0x0020
      ; SFF_PLAINRTF = 0x4000, SFF_SELECTION = 0x8000
      ; UTF-8 = 65001, UTF-16 = 1200
      Static GetRTFCB := 0
      Flags := 0x4022 | (1200 << 16) | (Selection ? 0x8000 : 0)
      GetRTFCB := RegisterCallback("RichEdit.GetRTFProc")
      VarSetCapacity(ES, (A_PtrSize * 2) + 4, 0) ; EDITSTREAM structure
      NumPut(This.HWND, ES, 0, "Ptr")            ; dwCookie
      NumPut(GetRTFCB, ES, A_PtrSize + 4, "Ptr") ; pfnCallback
      SendMessage, 0x044A, %Flags%, &ES, , % "ahk_id " . This.HWND
      DllCall("Kernel32.dll\GlobalFree", "Ptr", GetRTFCB)
      Return This.GetRTFProc("Get", 0, 0)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetRTFProc(pbBuff, cb, pcb) { ; Callback procedure for GetRTF
      ; left out first parameter dwCookie, will be passed in "This" when called by system
      Static RTF := ""
      If (cb > 0) {
         RTF .= StrGet(pbBuff, cb, "CP0")
         Return 0
      }
      If (pbBuff = "Get") {
         Out := RTF
         VarSetCapacity(RTF, 0)
         Return Out
      }
      Return 1
   }
   ; -------------------------------------------------------------------------------------------------------------------
   LoadRTF(FilePath, Selection := False) { ; Loads RTF file into the control.
      ; FilePath = file path
      ; Selection = False : whole contents (default)
      ; Selection = True  : current selection
      ; EM_STREAMIN = 0x0449
      ; SF_TEXT = 0x1, SF_RTF = 0x2, SF_RTFNOOBJS = 0x3, SF_UNICODE = 0x10, SF_USECODEPAGE =	0x0020
      ; SFF_PLAINRTF = 0x4000, SFF_SELECTION = 0x8000
      ; UTF-16 = 1200
      Static LoadRTFCB := RegisterCallback("RichEdit.LoadRTFProc")
      Flags := 0x4002 | (Selection ? 0x8000 : 0) ; | (1200 << 16)
      If !(File := FileOpen(FilePath, "r"))
         Return False
      VarSetCapacity(ES, (A_PtrSize * 2) + 4, 0)  ; EDITSTREAM structure
      NumPut(File.__Handle, ES, 0, "Ptr")         ; dwCookie
      NumPut(LoadRTFCB, ES, A_PtrSize + 4, "Ptr") ; pfnCallback
      SendMessage, 0x0449, %Flags%, &ES, , % "ahk_id " . This.HWND
      Result := ErrorLevel
      File.Close()
      Return Result
   }
   ; -------------------------------------------------------------------------------------------------------------------
   LoadRTFProc(pbBuff, cb, pcb) { ; Callback procedure for LoadRTF
      ; Left out first parameter dwCookie, will be passed in "This" when called by system
      Return !DllCall("ReadFile", "Ptr", This, "Ptr", pbBuff, "UInt", cb, "Ptr", pcb, "Ptr", 0)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Scrolling
   ; -------------------------------------------------------------------------------------------------------------------
   GetScrollPos() { ; Obtains the current scroll position.
      ; Returns on object with keys 'X' and 'Y' containing the scroll position.
      ; EM_GETSCROLLPOS = 0x04DD
      VarSetCapacity(PT, 8, 0)
      SendMessage, 0x04DD, 0, &PT, , % "ahk_id " . This.HWND
      Return {X: NumGet(PT, 0, "Int"), Y: NumGet(PT, 4, "Int")}
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetScrollPos(X, Y) { ; Scrolls the contents of a rich edit control to the specified point.
      ; X : x-position to scroll to.
      ; Y : y-position to scroll to.
      ; EM_SETSCROLLPOS = 0x04DE
      VarSetCapacity(PT, 8, 0)
      NumPut(X, PT, 0, "Int")
      NumPut(Y, PT, 4, "Int")
      SendMessage, 0x04DE, 0, &PT, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ScrollCaret() { ; Scrolls the caret into view.
      ; EM_SCROLLCARET = 0x00B7
      SendMessage, 0x00B7, 0, 0, , % "ahk_id " . This.HWND
      Return True
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ShowScrollBar(SB, Mode := True) { ; Shows or hides one of the scroll bars of a rich edit control.
      ; SB   : Identifies which scroll bar to display: horizontal or vertical.
      ;        This parameter must be 1 (SB_VERT) or 0 (SB_HORZ).
      ; Mode : Specify TRUE to show the scroll bar and FALSE to hide it.
      ; EM_SHOWSCROLLBAR = 0x0460 (WM_USER + 96)
      SendMessage, 0x0460, %SB%, %Mode%, , % "ahk_id " . This.HWND
      Return True
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Text and selection
   ; -------------------------------------------------------------------------------------------------------------------
   FindText(Find, Mode := "") { ; Finds Unicode text within a rich edit control.
      ; Find : Text to search for.
      ; Mode : Optional array containing one or more of the keys specified in 'FR'.
      ;        For details see http://msdn.microsoft.com/en-us/library/bb788013(v=vs.85).aspx.
      ; Returns True if the text was found; otherwise false.
      ; EM_FINDTEXTEXW = 0x047C, EM_SCROLLCARET = 0x00B7
      Static FR:= {DOWN: 1, WHOLEWORD: 2, MATCHCASE: 4}
      Flags := 0
      For Each, Value In Mode
         If FR.HasKey(Value)
            Flags |= FR[Value]
      Sel := This.GetSel()
      Min := (Flags & FR.DOWN) ? Sel.E : Sel.S
      Max := (Flags & FR.DOWN) ? -1 : 0
      VarSetCapacity(FTX, 16 + A_PtrSize, 0)
      NumPut(Min, FTX, 0, "Int")
      NumPut(Max, FTX, 4, "Int")
      NumPut(&Find, FTX, 8, "Ptr")
      SendMessage, 0x047C, %Flags%, &FTX, , % "ahk_id " . This.HWND
      S := NumGet(FTX, 8 + A_PtrSize, "Int"), E := NumGet(FTX, 12 + A_PtrSize, "Int")
      If (S = -1) && (E = -1)
         Return False
      This.SetSel(S, E)
      This.ScrollCaret()
      Return
   }
   ; -------------------------------------------------------------------------------------------------------------------
   FindWordBreak(CharPos, Mode := "Left") { ; Finds the next word break before or after the specified character position
                                            ; or retrieves information about the character at that position.
      ; CharPos : Character position.
      ; Mode    : Can be one of the keys specified in 'WB'.
      ; Returns the character index of the word break or other values depending on 'Mode'.
      ; For details see http://msdn.microsoft.com/en-us/library/bb788018(v=vs.85).aspx.
      ; EM_FINDWORDBREAK = 0x044C (WM_USER + 76)
      Static WB := {LEFT: 0, RIGHT: 1, ISDELIMITER: 2, CLASSIFY: 3, MOVEWORDLEFT: 4, MOVEWORDRIGHT: 5, LEFTBREAK: 6
                  , RIGHTBREAK: 7}
      Option := WB.HasKey(Mode) ? WB[Mode] : 0
      SendMessage, 0x044C, %Option%, %CharPos%, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetSelText() { ; Retrieves the currently selected text as plain text.
      ; Returns selected text.
      ; EM_GETSELTEXT = 0x043E, EM_EXGETSEL = 0x0434
      VarSetCapacity(CR, 8, 0)
      SendMessage, 0x0434, 0, &CR, , % "ahk_id " . This.HWND
      L := NumGet(CR, 4, "Int") - NumGet(CR, 0, "Int") + 1
      If (L > 1) {
         VarSetCapacity(Text, L * 2, 0)
         SendMessage, 0x043E, 0, &Text, , % "ahk_id " . This.HWND
         VarSetCapacity(Text, -1)
      }
      Return Text
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetSel() { ; Retrieves the starting and ending character positions of the selection in a rich edit control.
      ; Returns an object containing the keys S (start of selection) and E (end of selection)).
      ; EM_EXGETSEL = 0x0434
      VarSetCapacity(CR, 8, 0)
      SendMessage, 0x0434, 0, &CR, , % "ahk_id " . This.HWND
      Return {S: NumGet(CR, 0, "Int"), E: NumGet(CR, 4, "Int")}
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetText() { ; Gets the whole content of the control as plain text.
      ; EM_GETTEXTEX = 0x045E
      Text := ""
      If (Length := This.GetTextLen() * 2) {
         VarSetCapacity(GTX, (4 * 4) + (A_PtrSize * 2), 0) ; GETTEXTEX structure
         NumPut(Length + 2, GTX, 0, "UInt") ; cb
         NumPut(1200, GTX, 8, "UInt")       ; codepage = Unicode
         VarSetCapacity(Text, Length + 2, 0)
         SendMessage, 0x045E, &GTX, &Text, , % "ahk_id " . This.HWND
         VarSetCapacity(Text, -1)
      }
      Return Text
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetTextLen() { ; Calculates text length in various ways.
      ; EM_GETTEXTLENGTHEX = 0x045F
      VarSetCapacity(GTL, 8, 0)     ; GETTEXTLENGTHEX structure
      NumPut(1200, GTL, 4, "UInt")  ; codepage = Unicode
      SendMessage, 0x045F, &GTL, 0, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetTextRange(Min, Max) { ; Retrieves a specified range of characters from a rich edit control.
      ; Min : Character position index immediately preceding the first character in the range.
      ;       Integer value to store as cpMin in the CHARRANGE structure.
      ; Max : Character position immediately following the last character in the range.
      ;       Integer value to store as cpMax in the CHARRANGE structure.
      ; CHARRANGE -> http://msdn.microsoft.com/en-us/library/bb787885(v=vs.85).aspx
      ; EM_GETTEXTRANGE = 0x044B
      If (Max <= Min)
         Return ""
      VarSetCapacity(Text, (Max - Min) << !!A_IsUnicode, 0)
      VarSetCapacity(TEXTRANGE, 16, 0) ; TEXTRANGE Struktur
      NumPut(Min, TEXTRANGE, 0, "UInt")
      NumPut(Max, TEXTRANGE, 4, "UInt")
      NumPut(&Text, TEXTRANGE, 8, "UPtr")
      SendMessage, 0x044B, 0, % &TEXTRANGE, , % "ahk_id " . This.HWND
      VarSetCapacity(Text, -1) ; Länge des Zeichenspeichers korrigieren 
      Return Text
   }
   ; -------------------------------------------------------------------------------------------------------------------
   HideSelection(Mode) { ; Hides or shows the selection.
      ; Mode : True to hide or False to show the selection.
      ; EM_HIDESELECTION = 0x043F (WM_USER + 63)
      SendMessage, 0x043F, %Mode%, 0, , % "ahk_id " . This.HWND
      Return True
   }
   ; -------------------------------------------------------------------------------------------------------------------
   LimitText(Limit)  { ; Sets an upper limit to the amount of text the user can type or paste into a rich edit control.
      ; Limit : Specifies the maximum amount of text that can be entered.
      ;         If this parameter is zero, the default maximum is used, which is 64K characters.
      ; EM_EXLIMITTEXT =  0x435 (WM_USER + 53)
      SendMessage, 0x0435, 0, %Limit%, , % "ahk_id " . This.HWND
      Return True
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ReplaceSel(Text := "") { ; Replaces the selected text with the specified text.
      ; EM_REPLACESEL = 0xC2
      SendMessage, 0xC2, 1, &Text, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetText(ByRef Text := "", Mode := "") { ; Replaces the selection or the whole content of the control.
      ; Mode : Option flags. It can be any reasonable combination of the keys defined in 'ST'.
      ; For details see http://msdn.microsoft.com/en-us/library/bb774284(v=vs.85).aspx.
      ; EM_SETTEXTEX = 0x0461, CP_UNICODE = 1200
      ; ST_DEFAULT = 0, ST_KEEPUNDO = 1, ST_SELECTION = 2, ST_NEWCHARS = 4 ???
      Static ST := {DEFAULT: 0, KEEPUNDO: 1, SELECTION: 2}
      Flags := 0
      For Each, Value In Mode
         If ST.HasKey(Value)
            Flags |= ST[Value]
      CP := 1200
      BufAddr := &Text
      ; RTF formatted text has to be passed as ANSI!!!
      If (SubStr(Text, 1, 5) = "{\rtf") || (SubStr(Text, 1, 5) = "{urtf") {
         Len := StrPut(Text, "CP0")
         VarSetCapacity(Buf, Len, 0)
         StrPut(Text, &Buf, "CP0")
         BufAddr := &Buf
         CP := 0
      }
      VarSetCapacity(STX, 8, 0)     ; SETTEXTEX structure
      NumPut(Flags, STX, 0, "UInt") ; flags
      NumPut(CP  ,  STX, 4, "UInt") ; codepage
      SendMessage, 0x0461, &STX, BufAddr, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetSel(Start, End) { ; Selects a range of characters.
      ; Start : zero-based start index
      ; End   : zero-beased end index (-1 = end of text))
      ; EM_EXSETSEL = 0x0437
      VarSetCapacity(CR, 8, 0)
      NumPut(Start, CR, 0, "Int")
      NumPut(End,   CR, 4, "Int")
      SendMessage, 0x0437, 0, &CR, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Appearance, styles, and options
   ; -------------------------------------------------------------------------------------------------------------------
   AutoURL(On) { ; Turn AutoURLDetection on/off
      ; EM_AUTOURLDETECT = 0x45B
      SendMessage, 0x45B, % !!On, 0, , % "ahk_id " . This.HWND
      WinSet, Redraw, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetOptions() { ; Retrieves rich edit control options.
      ; Returns an array of currently the set options as the keys defined in 'ECO'.
      ; For details see http://msdn.microsoft.com/en-us/library/bb774178(v=vs.85).aspx.
      ; EM_GETOPTIONS = 0x044E
      Static ECO := {AUTOWORDSELECTION: 0x01, AUTOVSCROLL: 0x40, AUTOHSCROLL: 0x80, NOHIDESEL: 0x100
                   , READONLY: 0x800, WANTRETURN: 0x1000, SAVESEL: 0x8000, SELECTIONBAR: 0x01000000
                   , VERTICAL: 0x400000}
      SendMessage, 0x044E, 0, 0, , % "ahk_id " . This.HWND
      O := ErrorLevel
      Options := []
      For Key, Value In ECO
         If (O & Value)
            Options.Insert(Key)
      Return Options
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetStyles() { ; Retrieves the current edit style flags.
      ; Returns an object containing keys as defined in 'SES'.
      ; For details see http://msdn.microsoft.com/en-us/library/bb788031(v=vs.85).aspx.
      ; EM_GETEDITSTYLE	= 0x04CD (WM_USER + 205)
      Static SES := {1: "EMULATESYSEDIT", 1: "BEEPONMAXTEXT", 4: "EXTENDBACKCOLOR", 32: "NOXLTSYMBOLRANGE", 64: "USEAIMM"
                   , 128: "NOIME", 256: "ALLOWBEEPS", 512: "UPPERCASE", 1024: "LOWERCASE", 2048: "NOINPUTSEQUENCECHK"
                   , 4096: "BIDI", 8192: "SCROLLONKILLFOCUS", 16384: "XLTCRCRLFTOCR", 32768: "DRAFTMODE"
                   , 0x0010000: "USECTF", 0x0020000: "HIDEGRIDLINES", 0x0040000: "USEATFONT", 0x0080000: "CUSTOMLOOK"
                   , 0x0100000: "LBSCROLLNOTIFY", 0x0200000: "CTFALLOWEMBED", 0x0400000: "CTFALLOWSMARTTAG"
                   , 0x0800000: "CTFALLOWPROOFING"}
      SendMessage, 0x04CD, 0, 0, , % "ahk_id " . This.HWND
      Result := ErrorLevel
      Styles := []
      For Key, Value In SES
         If (Result & Key)
            Styles.Insert(Value)
      Return Styles
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetZoom() { ; Gets the current zoom ratio.
      ; Returns the zoom ratio in percent.
      ; EM_GETZOOM = 0x04E0
      VarSetCapacity(N, 4, 0), VarSetCapacity(D, 4, 0)
      SendMessage, 0x04E0, &N, &D, , % "ahk_id " . This.HWND
      N := NumGet(N, 0, "Int"), D := NumGet(D, 0, "Int")
      Return (N = 0) && (D = 0) ? 100 : Round(N / D * 100)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetBkgndColor(Color) { ; Sets the background color.
      ; Color : RGB integer value or HTML color name or
      ;         "Auto" to reset to system default color.
      ; Returns the prior background color.
      ; EM_SETBKGNDCOLOR = 0x0443
      If (Color = "Auto")
         System := True, Color := 0
      Else
         System := False, Color := This.GetBGR(Color)
      SendMessage, 0x0443, %System%, %Color%, , % "ahk_id " . This.HWND
      Return This.GetRGB(ErrorLevel)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetOptions(Options, Mode := "SET") { ; Sets the options for a rich edit control.
      ; Options : Array of options as the keys defined in 'ECO'.
      ; Mode    : Settings mode: SET, OR, AND, XOR
      ; For details see http://msdn.microsoft.com/en-us/library/bb774254(v=vs.85).aspx.
      ; EM_SETOPTIONS = 0x044D
      Static ECO := {AUTOWORDSELECTION: 0x01, AUTOVSCROLL: 0x40, AUTOHSCROLL: 0x80, NOHIDESEL: 0x100, READONLY: 0x800
                   , WANTRETURN: 0x1000, SAVESEL: 0x8000, SELECTIONBAR: 0x01000000, VERTICAL: 0x400000}
           , ECOOP := {SET: 0x01, OR: 0x02, AND: 0x03, XOR: 0x04}
      If !ECOOP.HasKey(Mode)
         Return False
      O := 0
      For Each, Option In Options {
         If ECO.HasKey(Option)
            O |= ECO[Option]
         Else
            Return False
      }
      SendMessage, 0x044D, % ECOOP[Mode], %O%, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetStyles(Styles) { ; Sets the current edit style flags for a rich edit control.
      ; Styles : Object containing on or more of the keys defined in 'SES'.
      ;          If the value is 0 the style will be removed, otherwise it will be added.
      ; For details see http://msdn.microsoft.com/en-us/library/bb774236(v=vs.85).aspx.
      ; EM_SETEDITSTYLE	= 0x04CC (WM_USER + 204)
      Static SES = {EMULATESYSEDIT: 1, BEEPONMAXTEXT: 2, EXTENDBACKCOLOR: 4, NOXLTSYMBOLRANGE: 32, USEAIMM: 64
                  , NOIME: 128, ALLOWBEEPS: 256, UPPERCASE: 512, LOWERCASE: 1024, NOINPUTSEQUENCECHK: 2048
                  , BIDI: 4096, SCROLLONKILLFOCUS: 8192, XLTCRCRLFTOCR: 16384, DRAFTMODE: 32768
                  , USECTF: 0x0010000, HIDEGRIDLINES: 0x0020000, USEATFONT: 0x0040000, CUSTOMLOOK: 0x0080000
                  , LBSCROLLNOTIFY: 0x0100000, CTFALLOWEMBED: 0x0200000, CTFALLOWSMARTTAG: 0x0400000
                  , CTFALLOWPROOFING: 0x0800000}
      Flags := Mask := 0
      For Style, Value In Styles {
         If SES.HasKey(Style) {
            Mask |= SES[Style]
            If (Value <> 0)
               Flags |= SES[Style]
         }
      }
      If (Mask) {
         SendMessage, 0x04CC, %Flags%, %Mask%, ,, % "ahk_id " . This.HWND
         Return ErrorLevel
      }
      Return False
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetZoom(Ratio := "") { ; Sets the zoom ratio of a rich edit control.
      ; Ratio : Float value between 100/64 and 6400; a ratio of 0 turns zooming off.
      ; EM_SETZOOM = 0x4E1
      SendMessage, 0x4E1, % (Ratio > 0 ? Ratio : 100), 100, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Copy, paste, etc.
   ; -------------------------------------------------------------------------------------------------------------------
   CanRedo() { ; Determines whether there are any actions in the control redo queue.
      ; EM_CANREDO = 0x0455 (WM_USER + 85)
      SendMessage, 0x0455, 0, 0, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   CanUndo() { ; Determines whether there are any actions in an edit control's undo queue.
      ; EM_CANUNDO = 0x00C6
      SendMessage, 0x00C6, 0, 0, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   Clear() {
      ; WM_CLEAR = 0x303
      SendMessage, 0x303, 0, 0, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   Copy() {
      ; WM_COPY = 0x301
      SendMessage, 0x301, 0, 0, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   Cut() {
      ; WM_CUT = 0x300
      SendMessage, 0x300, 0, 0, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   Paste() {
      ; WM_PASTE = 0x302
      SendMessage, 0x302, 0, 0, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   Redo() {
      ; EM_REDO := 0x454
      SendMessage, 0x454, 0, 0, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   Undo() {
      ; EM_UNDO = 0xC7
      SendMessage, 0xC7, 0, 0, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SelAll() {
      ; Select all
      Return This.SetSel(0, -1)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   Deselect() {
      ; Deselect all
      Sel := This.GetSel()
      Return This.SetSel(Sel.S, Sel.S)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Font & colors
   ; -------------------------------------------------------------------------------------------------------------------
   ChangeFontSize(Diff) { ; Change font size
      ; Diff : any positive or negative integer, positive values are treated as +1, negative as -1.
      ; Returns new size.
      ; EM_SETFONTSIZE = 0x04DF
      ; Font size changes by 1 in the range 4 - 11 pt, by 2 for 12 - 28 pt, afterward to 36 pt, 48 pt, 72 pt, 80 pt,
      ; and by 10 for > 80 pt. The maximum value is 160 pt, the minimum is 4 pt
      Font := This.GetFont()
      If (Diff > 0 && Font.Size < 160) || (Diff < 0 && Font.Size > 4)
         SendMessage, 0x04DF, % (Diff > 0 ? 1 : -1), 0, , % "ahk_id " . This.HWND
      Else
         Return False
      Font := This.GetFont()
      Return Font.Size
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetFont(Default := False) { ; Get current font
      ; Set Default to True to get the default font.
      ; Returns an object containing current options (see SetFont())
      ; EM_GETCHARFORMAT = 0x043A
      ; BOLD_FONTTYPE = 0x0100, ITALIC_FONTTYPE = 0x0200
      ; CFM_BOLD = 1, CFM_ITALIC = 2, CFM_UNDERLINE = 4, CFM_STRIKEOUT = 8, CFM_PROTECTED = 16, CFM_SUBSCRIPT = 0x30000
      ; CFM_BACKCOLOR = 0x04000000, CFM_CHARSET := 0x08000000, CFM_FACE = 0x20000000, CFM_COLOR = 0x40000000
      ; CFM_SIZE = 0x80000000
      ; CFE_SUBSCRIPT = 0x10000, CFE_SUPERSCRIPT = 0x20000, CFE_AUTOBACKCOLOR = 0x04000000, CFE_AUTOCOLOR = 0x40000000
      ; SCF_SELECTION = 1
      Static Mask := 0xEC03001F
      Static Effects := 0xEC000000
      CF2 := New This.CF2
      CF2.Mask := Mask
      CF2.Effects := Effects
      SendMessage, 0x043A, % (Default ? 0 : 1), % CF2.CF2, , % "ahk_id " . This.HWND
      Font := {}
      Font.Name := CF2.FaceName
      Font.Size := CF2.Height / 20
      CFS := CF2.Effects
      Style := (CFS & 1 ? "B" : "") . (CFS & 2 ? "I" : "") . (CFS & 4 ? "U" : "") . (CFS & 8 ? "S" : "")
             . (CFS & 0x10000 ? "L" : "") . (CFS & 0x20000 ? "H" : "") . (CFS & 16 ? "P" : "")
      Font.Style := Style = "" ? "N" : Style
      Font.Color := This.GetRGB(CF2.TextColor)
      If (CF2.Effects & 0x04000000)
         Font.BkColor := "Auto"
      Else
         Font.BkColor := This.GetRGB(CF2.BackColor)
      Font.CharSet := CF2.CharSet
      Return Font
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetDefaultFont(Font := "") { ; Set default font
      ; Font : Optional object - see SetFont().
      If IsObject(Font) {
         For Key, Value In Font
            If This.DefFont.HasKey(Key)
               This.DefFont[Key] := Value
      }
      Return This.SetFont(This.DefFont)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetFont(Font) { ; Set current/default font
      ; Font : Object containing the following keys
      ;        Name    : optional font name
      ;        Size    : optional font size in points
      ;        Style   : optional string of one or more of the following styles
      ;                  B = bold, I = italic, U = underline, S = strikeout, L = subscript
      ;                  H = superschript, P = protected, N = normal
      ;        Color   : optional text color as RGB integer value or HTML color name
      ;                  "Auto" for "automatic" (system's default) color
      ;        BkColor : optional text background color (see Color)
      ;                  "Auto" for "automatic" (system's default) background color
      ;        CharSet : optional font character set
      ;                  1 = DEFAULT_CHARSET, 2 = SYMBOL_CHARSET
      ;        Empty parameters preserve the corresponding properties
      ; EM_SETCHARFORMAT = 0x0444
      ; SCF_DEFAULT = 0, SCF_SELECTION = 1
      CF2 := New This.CF2
      Mask := Effects := 0
      If (Font.Name != "") {
         Mask |= 0x20000000, Effects |= 0x20000000 ; CFM_FACE, CFE_FACE
         CF2.FaceName := Font.Name
      }
      Size := Font.Size
      If (Size != "") {
         If (Size < 161)
            Size *= 20
         Mask |= 0x80000000, Effects |= 0x80000000 ; CFM_SIZE, CFE_SIZE
         CF2.Height := Size
      }
      If (Font.Style != "") {
         Mask |= 0x3001F           ; all font styles
         If InStr(Font.Style, "B")
            Effects |= 1           ; CFE_BOLD
         If InStr(Font.Style, "I")
            Effects |= 2           ; CFE_ITALIC
         If InStr(Font.Style, "U")
            Effects |= 4           ; CFE_UNDERLINE
         If InStr(Font.Style, "S")
            Effects |= 8           ; CFE_STRIKEOUT
         If InStr(Font.Style, "P")
            Effects |= 16          ; CFE_PROTECTED
         If InStr(Font.Style, "L")
            Effects |= 0x10000     ; CFE_SUBSCRIPT
         If InStr(Font.Style, "H")
            Effects |= 0x20000     ; CFE_SUPERSCRIPT
      }
      If (Font.Color != "") {
         Mask |= 0x40000000        ; CFM_COLOR
         If (Font.Color = "Auto")
            Effects |= 0x40000000  ; CFE_AUTOCOLOR
         Else
            CF2.TextColor := This.GetBGR(Font.Color)
      }
      If (Font.BkColor != "") {
         Mask |= 0x04000000        ; CFM_BACKCOLOR
         If (Font.BkColor = "Auto")
            Effects |= 0x04000000  ; CFE_AUTOBACKCOLOR
         Else
            CF2.BackColor := This.GetBGR(Font.BkColor)
      }
      If (Font.CharSet != "") {
         Mask |= 0x08000000, Effects |= 0x08000000 ; CFM_CHARSET, CFE_CHARSET
         CF2.CharSet := Font.CharSet = 2 ? 2 : 1 ; SYMBOL|DEFAULT
      }
      If (Mask != 0) {
         Mode := Font.Default ? 0 : 1
         CF2.Mask := Mask
         CF2.Effects := Effects
         SendMessage, 0x0444, %Mode%, % CF2.CF2, , % "ahk_id " . This.HWND
         Return ErrorLevel
      }
      Return False
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ToggleFontStyle(Style) { ; Toggle single font style
      ; Style : one of the following styles
      ;         B = bold, I = italic, U = underline, S = strikeout, L = subscript, H = superschript, P = protected,
      ;         N = normal (reset all other styles)
      ; EM_GETCHARFORMAT = 0x043A, EM_SETCHARFORMAT = 0x0444
      ; CFM_BOLD = 1, CFM_ITALIC = 2, CFM_UNDERLINE = 4, CFM_STRIKEOUT = 8, CFM_PROTECTED = 16, CFM_SUBSCRIPT = 0x30000
      ; CFE_SUBSCRIPT = 0x10000, CFE_SUPERSCRIPT = 0x20000, SCF_SELECTION = 1
      CF2 :=This.GetCharFormat()
      CF2.Mask := 0x3001F ; FontStyles
      If (Style = "N")
         CF2.Effects := 0
      Else
         CF2.Effects ^= Style = "B" ? 1 : Style = "I" ? 2 : Style = "U" ? 4 : Style = "S" ? 8
                      : Style = "H" ? 0x20000 : Style = "L" ? 0x10000 : 0
      SendMessage, 0x0444, 1, % CF2.CF2, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Paragraph formatting
   ; -------------------------------------------------------------------------------------------------------------------
   AlignText(Align := 1) { ; Set paragraph's alignment
      ; Note: Values greater 3 doesn't seem to work though they should as documented
      ; Align: may contain one of the following numbers:
      ;        PFA_LEFT             1
      ;        PFA_RIGHT            2
      ;        PFA_CENTER           3
      ;        PFA_JUSTIFY          4 // New paragraph-alignment option 2.0 (*)
      ;        PFA_FULL_INTERWORD   4 // These are supported in 3.0 with advanced
      ;        PFA_FULL_INTERLETTER 5 // typography enabled
      ;        PFA_FULL_SCALED      6
      ;        PFA_FULL_GLYPHS      7
      ;        PFA_SNAP_GRID        8
      ; EM_SETPARAFORMAT = 0x0447, PFM_ALIGNMENT = 0x08
      If (Align >= 1) && (ALign <= 8) {
         PF2 := New This.PF2    ; PARAFORMAT2 struct
         PF2.Mask := 0x08       ; dwMask
         PF2.Alignment := Align ; wAlignment
         SendMessage, 0x0447, 0, % PF2.PF2, , % "ahk_id " . This.HWND
         Return True
      }
      Return False
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetBorder(Widths, Styles) { ; Set paragraph's borders
      ; Borders are not displayed in RichEdit, so the call of this function has no visible result.
      ; Even WordPad distributed with Win7 does not show them, but e.g. Word 2007 does.
      ; Widths : Array of the 4 border widths in the range of 1 - 15 in order left, top, right, bottom; zero = no border
      ; Styles : Array of the 4 border styles in the range of 0 - 7 in order left, top, right, bottom (see remarks)
      ; Note:
      ; The description on MSDN at http://msdn.microsoft.com/en-us/library/bb787942(v=vs.85).aspx is wrong!
      ; To set borders you have to put the border width into the related nibble (4 Bits) of wBorderWidth
      ; (in order: left (0 - 3), top (4 - 7), right (8 - 11), and bottom (12 - 15). The values are interpreted as
      ; half points (i.e. 10 twips). Border styles are set in the related nibbles of wBorders.
      ; Valid styles seem to be:
      ;     0 : \brdrdash (dashes)
      ;     1 : \brdrdashsm (small dashes)
      ;     2 : \brdrdb (double line)
      ;     3 : \brdrdot (dotted line)
      ;     4 : \brdrhair (single/hair line)
      ;     5 : \brdrs ? looks like 3
      ;     6 : \brdrth ? looks like 3
      ;     7 : \brdrtriple (triple line)
      ; EM_SETPARAFORMAT = 0x0447, PFM_BORDER = 0x800
      If !IsObject(Widths)
         Return False
      W := S := 0
      For I, V In Widths {
         If (V)
            W |= V << ((A_Index - 1) * 4)
         If Styles[I]
            S |= Styles[I] << ((A_Index - 1) * 4)
      }
      PF2 := New This.PF2
      PF2.Mask := 0x800
      PF2.BorderWidth := W
      PF2.Borders := S
      SendMessage, 0x0447, 0, % PF2.PF2, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetLineSpacing(Lines) { ; Sets paragraph's line spacing.
      ; Lines : number of lines as integer or float.
      ; SpacingRule = 5:
      ; The value of dyLineSpacing / 20 is the spacing, in lines, from one line to the next. Thus, setting
      ; dyLineSpacing to 20 produces single-spaced text, 40 is double spaced, 60 is triple spaced, and so on.
      ; EM_SETPARAFORMAT = 0x0447, PFM_LINESPACING = 0x100
      PF2 := New This.PF2
      PF2.Mask := 0x100
      PF2.LineSpacing := Abs(Lines) * 20
      PF2.LineSpacingRule := 5
      SendMessage, 0x0447, 0, % PF2.PF2, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetParaIndent(Indent := "Reset") { ; Sets space left/right of the paragraph.
      ; Indent : Object containing up to three keys:
      ;          - Start  : Optional - Absolute indentation of the paragraph's first line.
      ;          - Right  : Optional - Indentation of the right side of the paragraph, relative to the right margin.
      ;          - Offset : Optional - Indentation of the second and subsequent lines, relative to the indentation
      ;                                of the first line.
      ;          Values are interpreted as centimeters/inches depending on the user's locale measurement settings.
      ;          Call without passing a parameter to reset indentation.
      ; EM_SETPARAFORMAT = 0x0447
      ; PFM_STARTINDENT  = 0x0001
      ; PFM_RIGHTINDENT  = 0x0002
      ; PFM_OFFSET       = 0x0004
      Static PFM := {STARTINDENT: 0x01, RIGHTINDENT: 0x02, OFFSET: 0x04}
      Measurement := This.GetMeasurement()
      PF2 := New This.PF2
      If (Indent = "Reset")
         PF2.Mask := 0x07 ; reset indentation
      Else If !IsObject(Indent)
         Return False
      Else {
         PF2.Mask := 0
         If (Indent.HasKey("Start")) {
            PF2.Mask |= PFM.STARTINDENT
            PF2.StartIndent := Round((Indent.Start / Measurement) * 1440)
         }
         If (Indent.HasKey("Offset")) {
            PF2.Mask |= PFM.OFFSET
            PF2.Offset := Round((Indent.Offset / Measurement) * 1440)
         }
         If (Indent.HasKey("Right")) {
            PF2.Mask |= PFM.RIGHTINDENT
            PF2.RightIndent := Round((Indent.Right / Measurement) * 1440)
         }
      }
      If (PF2.Mask) {
         SendMessage, 0x0447, 0, % PF2.PF2, , % "ahk_id " . This.HWND
         Return ErrorLevel
      }
      Return False
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetParaNumbering(Numbering := "Reset") {
      ; Numbering : Object containing up to four keys:
      ;             - Type  : Options used for bulleted or numbered paragraphs.
      ;             - Style : Optional - Numbering style used with numbered paragraphs.
      ;             - Tab   : Optional - Minimum space between a paragraph number and the paragraph text.
      ;             - Start : Optional - Sequence number used for numbered paragraphs (e.g. 3 for C or III)
      ;             Tab is interpreted as centimeters/inches depending on the user's locale measurement settings.
      ;             Call without passing a parameter to reset numbering.
      ; EM_SETPARAFORMAT = 0x0447
      ; PARAFORMAT numbering options
      ; PFN_BULLET   1 ; tomListBullet
      ; PFN_ARABIC   2 ; tomListNumberAsArabic:   0, 1, 2,	...
      ; PFN_LCLETTER 3 ; tomListNumberAsLCLetter: a, b, c,	...
      ; PFN_UCLETTER 4 ; tomListNumberAsUCLetter: A, B, C,	...
      ; PFN_LCROMAN  5 ; tomListNumberAsLCRoman:  i, ii, iii,	...
      ; PFN_UCROMAN  6 ; tomListNumberAsUCRoman:  I, II, III,	...
      ; PARAFORMAT2 wNumberingStyle options
      ; PFNS_PAREN     0x0000 ; default, e.g.,                 1)
      ; PFNS_PARENS    0x0100 ; tomListParentheses/256, e.g., (1)
      ; PFNS_PERIOD    0x0200 ; tomListPeriod/256, e.g.,       1.
      ; PFNS_PLAIN     0x0300 ; tomListPlain/256, e.g.,        1
      ; PFNS_NONUMBER  0x0400 ; used for continuation w/o number
      ; PFNS_NEWNUMBER 0x8000 ; start new number with wNumberingStart
      ; PFM_NUMBERING      0x0020
      ; PFM_NUMBERINGSTYLE 0x2000
      ; PFM_NUMBERINGTAB   0x4000
      ; PFM_NUMBERINGSTART 0x8000
      Static PFM := {Type: 0x0020, Style: 0x2000, Tab: 0x4000, Start: 0x8000}
      Static PFN := {Bullet: 1, Arabic: 2, LCLetter: 3, UCLetter: 4, LCRoman: 5, UCRoman: 6}
      Static PFNS := {Paren: 0x0000, Parens: 0x0100, Period: 0x0200, Plain: 0x0300, None: 0x0400, New: 0x8000}
      PF2 := New This.PF2
      If (Numbering = "Reset")
         PF2.Mask := 0xE020
      Else If !IsObject(Numbering)
         Return False
      Else {
         If (Numbering.HasKey("Type")) {
            PF2.Mask |= PFM.Type
            PF2.Numbering := PFN[Numbering.Type]
         }
         If (Numbering.HasKey("Style")) {
            PF2.Mask |= PFM.Style
            PF2.NumberingStyle := PFNS[Numbering.Style]
         }
         If (Numbering.HasKey("Tab")) {
            PF2.Mask |= PFM.Tab
            PF2.NumberingTab := Round((Numbering.Tab / This.GetMeasurement()) * 1440)
         }
         If (Numbering.HasKey("Start")) {
            PF2.Mask |= PFM.Start
            PF2.NumberingStart := Numbering.Start
         }
      }
      If (PF2.Mask) {
         SendMessage, 0x0447, 0, % PF2.PF2, , % "ahk_id " . This.HWND
         Return ErrorLevel
      }
      Return False
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetParaSpacing(Spacing := "Reset") { ; Set space before / after the paragraph
      ; Spacing : Object containing one or two keys:
      ;           - Before : additional space before the paragraph in points
      ;           - After  : additional space after the paragraph in points
      ;           Call without passing a parameter to reset spacing to zero.
      ; EM_SETPARAFORMAT = 0x0447
      ; PFM_SPACEBEFORE  = 0x0040
      ; PFM_SPACEAFTER   = 0x0080
      Static PFM := {Before: 0x40, After: 0x80}
      PF2 := New This.PF2
      If (Spacing = "Reset")
         PF2.Mask := 0xC0 ; reset spacing
      Else If !IsObject(Spacing)
         Return False
      Else {
         If (Spacing.Before >= 0) {
            PF2.Mask |= PFM.Before
            PF2.SpaceBefore := Round(Spacing.Before * 20)
         }
         If (Spacing.After >= 0) {
            PF2.Mask |= PFM.After
            PF2.SpaceAfter := Round(Spacing.After * 20)
         }
      }
      If (PF2.Mask) {
         SendMessage, 0x0447, 0, % PF2.PF2, , % "ahk_id " . This.HWND
         Return ErrorLevel
      }
      Return False
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetDefaultTabs(Distance) { ; Set default tabstops
      ; Distance will be interpreted as inches or centimeters depending on the current user's locale.
      ; EM_SETTABSTOPS = 0xCB
      Static DUI := 64      ; dialog units per inch
           , MinTab := 0.20 ; minimal tab distance
           , MaxTab := 3.00 ; maximal tab distance
      IM := This.GetMeasurement()
      StringReplace, Distance, Distance, `,, .
      Distance := Round(Distance / IM, 2)
      If (Distance < MinTab)
         Distance := MinTab
      If (Distance > MaxTab)
         Distance := MaxTab
      VarSetCapacity(TabStops, 4, 0)
      NumPut(Round(DUI * Distance), TabStops, "Int")
      SendMessage, 0xCB, 1, &TabStops, , % "ahk_id " . This.HWND
      Result := ErrorLevel
      DllCall("User32.dll\UpdateWindow", "Ptr", This.HWND)
      Return Result
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SetTabStops(TabStops := "Reset") { ; Set paragraph's tabstobs
      ; TabStops is an object containing the integer position as hundredth of inches/centimeters as keys
      ; and the alignment ("L", "C", "R", or "D") as values.
      ; The position will be interpreted as hundredth of inches or centimeters depending on the current user's locale.
      ; Call without passing a  parameter to reset to default tabs.
      ; EM_SETPARAFORMAT = 0x0447, PFM_TABSTOPS = 0x10
      Static MinT := 30                ; minimal tabstop in hundredth of inches
      Static MaxT := 830               ; maximal tabstop in hundredth of inches
      Static Align := {L: 0x00000000   ; left aligned (default)
                     , C: 0x01000000   ; centered
                     , R: 0x02000000   ; right aligned
                     , D: 0x03000000}  ; decimal tabstop
      Static MAX_TAB_STOPS := 32
      IC := This.GetMeasurement()
      PF2 := New This.PF2
      PF2.Mask := 0x10
      If (TabStops = "Reset") {
         SendMessage, 0x0447, 0, % PF2.PF2, , % "ahk_id " . This.HWND
         Return !!(ErrorLevel)
      }
      If !IsObject(TabStops)
         Return False
      TabCount := 0
      Tabs  := []
      For Position, Alignment In TabStops {
         Position /= IC
         If (Position < MinT) Or (Position > MaxT)
         Or !Align.HasKey(Alignment) Or (A_Index > MAX_TAB_STOPS)
            Return False
         Tabs[A_Index] := (Align[Alignment] | Round((Position / 100) * 1440))
         TabCount := A_Index
      }
      If (TabCount) {
         PF2.TabCount := TabCount
         PF2.Tabs := Tabs
         SendMessage, 0x0447, 0, % PF2.PF2, , % "ahk_id " . This.HWND
         Return ErrorLevel
      }
      Return False
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Line handling
   ; -------------------------------------------------------------------------------------------------------------------
   GetLineCount() { ; Get the total number of lines

      ; EM_GETLINECOUNT = 0xBA
      SendMessage, 0xBA, 0, 0, , % "ahk_id " . This.HWND
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetCaretLine() { ; Get the line containing the caret
      ; EM_LINEINDEX = 0xBB, EM_EXLINEFROMCHAR = 0x0436
      SendMessage, 0xBB, -1, 0, , % "ahk_id " . This.HWND
      SendMessage, 0x0436, 0, %ErrorLevel%, , % "ahk_id " . This.HWND
      Return ErrorLevel + 1
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Statistics
   ; -------------------------------------------------------------------------------------------------------------------
   GetStatistics() { ; Get some statistic values
      ; Get the line containing the caret, it's position in this line, the total amount of lines, the absulute caret
      ; position and the total amount of characters.
      ; EM_GETSEL = 0xB0, EM_LINEFROMCHAR = 0xC9, EM_LINEINDEX = 0xBB, EM_GETLINECOUNT = 0xBA
      Stats := {}
      VarSetCapacity(GTL, 8, 0)  ; GETTEXTLENGTHEX structure
      SB := 0
      SendMessage, 0xB0, &SB, 0, , % "ahk_id " . This.HWND
      SB := NumGet(SB, 0, "UInt") + 1
      SendMessage, 0xBB, -1, 0, , % "ahk_id " . This.HWND
      Stats.LinePos := SB - ErrorLevel
      SendMessage, 0xC9, -1, 0, , % "ahk_id " . This.HWND
      Stats.Line := ErrorLevel + 1
      SendMessage, 0xBA, 0, 0, , % "ahk_id " . This.HWND
      Stats.LineCount := ErrorLevel
      Stats.CharCount := This.GetTextLen()
      Return Stats
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Layout
   ; -------------------------------------------------------------------------------------------------------------------
   WordWrap(On) { ; Turn wordwrapping on/off
      ; EM_SCROLLCARET = 0xB7, EM_SETTARGETDEVICE = 0x0448
      Sel := This.GetSel()
      SendMessage, 0x0448, 0, % (On ? 0 : -1), , % "ahk_id " . This.HWND
      This.SetSel(Sel.S, Sel.E)
      SendMessage, 0xB7, 0, 0,  % "ahk_id " . This.HWND
      Return On
   }
   ; -------------------------------------------------------------------------------------------------------------------
   WYSIWYG(On) { ; Show control as printed (WYSIWYG)
      ; Text measuring is based on the default printer's capacities, thus changing the printer may produce different
      ; results. See remarks/comments in Print() also.
      ; EM_SCROLLCARET = 0xB7, EM_SETTARGETDEVICE = 0x0448
      ; PD_RETURNDC = 0x0100, PD_RETURNDEFAULT = 0x0400
      Static PDC := 0
      Static PD_Size := (A_PtrSize = 4 ? 66 : 120)
      Static OffFlags := A_PtrSize * 5
      Sel := This.GetSel()
      If !(On) {
         DllCall("User32.dll\LockWindowUpdate", "Ptr", This.HWND)
         DllCall("Gdi32.dll\DeleteDC", "Ptr", PDC)
         SendMessage, 0x0448, 0, -1, , % "ahk_id " . This.HWND
         This.SetSel(Sel.S, Sel.E)
         SendMessage, 0xB7, 0, 0,  % "ahk_id " . This.HWND
         DllCall("User32.dll\LockWindowUpdate", "Ptr", 0)
         Return ErrorLevel
      }
      Numput(VarSetCapacity(PD, PD_Size, 0), PD)
      NumPut(0x0100 | 0x0400, PD, A_PtrSize * 5, "UInt") ; PD_RETURNDC | PD_RETURNDEFAULT
      If !DllCall("Comdlg32.dll\PrintDlg", "Ptr", &PD, "Int")
         Return
      DllCall("Kernel32.dll\GlobalFree", "Ptr", NumGet(PD, A_PtrSize * 2, "UPtr"))
      DllCall("Kernel32.dll\GlobalFree", "Ptr", NumGet(PD, A_PtrSize * 3, "UPtr"))
      PDC := NumGet(PD, A_PtrSize * 4, "UPtr")
      DllCall("User32.dll\LockWindowUpdate", "Ptr", This.HWND)
      Caps := This.GetPrinterCaps(PDC)
      ; Set up page size and margins in pixel
      UML := This.Margins.LT                   ; user margin left
      UMR := This.Margins.RT                   ; user margin right
      PML := Caps.POFX                         ; physical margin left
      PMR := Caps.PHYW - Caps.HRES - Caps.POFX ; physical margin right
      LPW := Caps.HRES                         ; logical page width
      ; Adjust margins
      UML := UML > PML ? (UML - PML) : 0
      UMR := UMR > PMR ? (UMR - PMR) : 0
      LineLen := LPW - UML - UMR
      SendMessage, 0x0448, %PDC%, %LineLen%, , % "ahk_id " . This.HWND
      This.SetSel(Sel.S, Sel.E)
      SendMessage, 0xB7, 0, 0,  % "ahk_id " . This.HWND
      DllCall("User32.dll\LockWindowUpdate", "Ptr", 0)
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; File handling
   ; -------------------------------------------------------------------------------------------------------------------
   LoadFile(File, Mode = "Open") { ; Load file
      ; File : file name
      ; Mode : Open / Add / Insert
      ;        Open   : Replace control's content
      ;        Append : Append to conrol's content
      ;        Insert : Insert at / replace current selection
      If !FileExist(File)
         Return False
      SplitPath, File, , , Ext
      If (Ext = "rtf") {
         If (Mode = "Open") {
            Selection := False
         } Else If (Mode = "Insert") {
            Selection := True
         } Else If (Mode = "Append") {
            This.SetSel(-1, -2)
            Selection := True
         }
         This.LoadRTF(File, Selection)
      } Else {
         FileRead, Text, %File%
         If (Mode = "Open") {
            This.SetText(Text)
         } Else If (Mode = "Insert") {
            This.ReplaceSel(Text)
         } Else If (Mode = "Append") {
            This.SetSel(-1, -2)
            This.ReplaceSel(Text)
         }
      }
      Return True
   }
   ; -------------------------------------------------------------------------------------------------------------------
   SaveFile(File) { ; Save file
      ; File : file name
      ; Returns True on success, otherwise False.
      GuiName := This.GuiName
      Gui, %GuiName%:+OwnDialogs
      SplitPath, File, , , Ext
      Text := Ext = "rtf" ? This.GetRTF() : This.GetText()
      If IsObject(FileObj := FileOpen(File, "w")) {
         FileObj.Write(Text)
         FileObj.Close()
         Return True
      }
      Return False
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Printing
   ; THX jballi ->  http://www.autohotkey.com/board/topic/45513-function-he-print-wysiwyg-print-for-the-hiedit-control/
   ; -------------------------------------------------------------------------------------------------------------------
   Print() {
      ; ----------------------------------------------------------------------------------------------------------------
      ; Static variables
      Static PD_ALLPAGES := 0x00, PD_SELECTION := 0x01, PD_PAGENUMS := 0x02, PD_NOSELECTION := 0x04
           , PD_RETURNDC := 0x0100, PD_USEDEVMODECOPIES := 0x040000, PD_HIDEPRINTTOFILE := 0x100000
           , PD_NONETWORKBUTTON := 0x200000, PD_NOCURRENTPAGE := 0x800000
           , MM_TEXT := 0x1
           , EM_FORMATRANGE := 0x0439, EM_SETTARGETDEVICE := 0x0448
           , DocName := "AHKRichEdit"
           , PD_Size := (A_PtrSize = 8 ? (13 * A_PtrSize) + 16 : 66)
      ErrorMsg := ""
      ; ----------------------------------------------------------------------------------------------------------------
      ; Prepare to call PrintDlg
      ; Define/Populate the PRINTDLG structure
      VarSetCapacity(PD, PD_Size, 0)
      Numput(PD_Size, PD, 0, "UInt")  ; lStructSize
      Numput(This.GuiHwnd, PD, A_PtrSize, "UPtr") ; hwndOwner
      ; Collect Start/End select positions
      Sel := This.GetSel()
      ; Determine/Set Flags
      Flags := PD_ALLPAGES | PD_RETURNDC | PD_USEDEVMODECOPIES | PD_HIDEPRINTTOFILE | PD_NONETWORKBUTTON
             | PD_NOCURRENTPAGE
      If (Sel.S = Sel.E)
         Flags |= PD_NOSELECTION
      Else
         Flags |= PD_SELECTION
      Offset := A_PtrSize * 5
      NumPut(Flags, PD, Offset, "UInt")       ; Flags
      ; Page and copies
      NumPut( 1, PD, Offset += 4, "UShort")   ; nFromPage
      NumPut( 1, PD, Offset += 2, "UShort")   ; nToPage
      NumPut( 1, PD, Offset += 2, "UShort")   ; nMinPage
      NumPut(-1, PD, Offset += 2, "UShort")   ; nMaxPage
      NumPut( 1, PD, Offset += 2, "UShort")   ; nCopies
      ; Note: Use -1 to specify the maximum page number (65535).
      ; Programming note: The values that are loaded to these fields are critical. The Print dialog will not
      ; display (returns an error) if unexpected values are loaded to one or more of these fields.
      ; ----------------------------------------------------------------------------------------------------------------
      ; Print dialog box
      ; Open the Print dialog.  Bounce If the user cancels.
      If !DllCall("Comdlg32.dll\PrintDlg", "Ptr", &PD, "UInt") {
         ErrorLevel := "Function: " . A_ThisFunc . " - DLLCall of 'PrintDlg' failed."
         Return False
      }
      ; Get the printer device context.  Bounce If not defined.
      If !(PDC := NumGet(PD, A_PtrSize * 4, "UPtr")) { ; hDC
         ErrorLevel := "Function: " . A_ThisFunc . " - Couldn't get a printer's device context."
         Return False
      }
      ; Free global structures created by PrintDlg
      DllCall("Kernel32.dll\GlobalFree", "Ptr", NumGet(PD, A_PtrSize * 2, "UPtr"))
      DllCall("Kernel32.dll\GlobalFree", "Ptr", NumGet(PD, A_PtrSize * 3, "UPtr"))
      ; ----------------------------------------------------------------------------------------------------------------
      ; Prepare to print
      ; Collect Flags
      Offset := A_PtrSize * 5
      Flags := NumGet(PD, OffSet, "UInt")           ; Flags
      ; Determine From/To Page
      If (Flags & PD_PAGENUMS) {
         PageF := NumGet(PD, Offset += 4, "UShort") ; nFromPage (first page)
         PageL := NumGet(PD, Offset += 2, "UShort") ; nToPage (last page)
      } Else {
         PageF := 1
         PageL := 65535
      }
      ; Collect printer capacities
      Caps := This.GetPrinterCaps(PDC)
      ; Set up page size and margins in Twips (1/20 point or 1/1440 of an inch)
      UML := This.Margins.LT                   ; user margin left
      UMT := This.Margins.TT                   ; user margin top
      UMR := This.Margins.RT                   ; user margin right
      UMB := This.Margins.BT                   ; user margin bottom
      PML := Caps.POFX                         ; physical margin left
      PMT := Caps.POFY                         ; physical margin top
      PMR := Caps.PHYW - Caps.HRES - Caps.POFX ; physical margin right
      PMB := Caps.PHYH - Caps.VRES - Caps.POFY ; physical margin bottom
      LPW := Caps.HRES                         ; logical page width
      LPH := Caps.VRES                         ; logical page height
      ; Adjust margins
      UML := UML > PML ? (UML - PML) : 0
      UMT := UMT > PMT ? (UMT - PMT) : 0
      UMR := UMR > PMR ? (UMR - PMR) : 0
      UMB := UMB > PMB ? (UMB - PMB) : 0
      ; Define/Populate the FORMATRANGE structure
      VarSetCapacity(FR, (A_PtrSize * 2) + (4 * 10), 0)
      NumPut(PDC, FR, 0, "UPtr")         ; hdc
      NumPut(PDC, FR, A_PtrSize, "UPtr") ; hdcTarget
      ; Define FORMATRANGE.rc
      ; rc is the area to render to (rcPage - margins), measured in twips (1/20 point or 1/1440 of an inch).
      ; If the user-defined margins are smaller than the printer's margins (the unprintable areas at the edges of each
      ; page), the user margins are set to the printer's margins. In addition, the user-defined margins must be adjusted
      ; to account for the printer's margins.
      ; For example: If the user requests a 3/4 inch (19.05 mm) left margin but the printer's left margin is 1/4 inch
      ; (6.35 mm), rc.Left is set to 720 twips (1/2 inch or 12.7 mm).
      Offset := A_PtrSize * 2
      NumPut(UML, FR, Offset += 0, "Int")       ; rc.Left
      NumPut(UMT, FR, Offset += 4, "Int")       ; rc.Top
      NumPut(LPW - UMR, FR, Offset += 4, "Int") ; rc.Right
      NumPut(LPH - UMB, FR, Offset += 4, "Int") ; rc.Bottom
      ; Define FORMATRANGE.rcPage
      ; rcPage is the entire area of a page on the rendering device, measured in twips (1/20 point or 1/1440 of an inch)
      ; Note: rc defines the maximum printable area which does not include the printer's margins (the unprintable areas
      ; at the edges of the page). The unprintable areas are represented by PHYSICALOFFSETX and PHYSICALOFFSETY.
      NumPut(0, FR, Offset += 4, "Int")         ; rcPage.Left
      NumPut(0, FR, Offset += 4, "Int")         ; rcPage.Top
      NumPut(LPW, FR, Offset += 4, "Int")       ; rcPage.Right
      NumPut(LPH, FR, Offset += 4, "Int")       ; rcPage.Bottom
      ; Determine print range.
      ; If "Selection" option is chosen, use selected text, otherwise use the entire document.
      If (Flags & PD_SELECTION) {
         PrintS := Sel.S
         PrintE := Sel.E
      } Else {
         PrintS := 0
         PrintE := -1            ; (-1 = Select All)
      }
      Numput(PrintS, FR, Offset += 4, "Int")    ; cr.cpMin
      NumPut(PrintE, FR, Offset += 4, "Int")    ; cr.cpMax
      ; Define/Populate the DOCINFO structure
      VarSetCapacity(DI, A_PtrSize * 5, 0)
      NumPut(A_PtrSize * 5, DI, 0, "UInt")
      NumPut(&DocName, DI, A_PtrSize, "UPtr")     ; lpszDocName
      NumPut(0       , DI, A_PtrSize * 2, "UPtr") ; lpszOutput
      ; Programming note: All other DOCINFO fields intentionally left as null.
      ; Determine MaxPrintIndex
      If (Flags & PD_SELECTION) {
          PrintM := Sel.E
      } Else {
          PrintM := This.GetTextLen()
      }
      ; Be sure that the printer device context is in text mode
      DllCall("Gdi32.dll\SetMapMode", "Ptr", PDC, "Int", MM_TEXT)
      ; ----------------------------------------------------------------------------------------------------------------
      ; Print it!
      ; Start a print job.  Bounce If there is a problem.
      PrintJob := DllCall("Gdi32.dll\StartDoc", "Ptr", PDC, "Ptr", &DI, "Int")
      If (PrintJob <= 0) {
         ErrorLevel := "Function: " . A_ThisFunc . " - DLLCall of 'StartDoc' failed."
         Return False
      }
      ; Print page loop
      PageC  := 0 ; current page
      PrintC := 0 ; current print index
      While (PrintC < PrintM) {
         PageC++
         ; Are we done yet?
         If (PageC > PageL)
            Break
         If (PageC >= PageF) && (PageC <= PageL) {
            ; StartPage function.  Break If there is a problem.
            If (DllCall("Gdi32.dll\StartPage", "Ptr", PDC, "Int") <= 0) {
               ErrorMsg := "Function: " . A_ThisFunc . " - DLLCall of 'StartPage' failed."
               Break
            }
         }
         ; Format or measure page
         If (PageC >= PageF) && (PageC <= PageL)
            Render := True
         Else
            Render := False
         SendMessage, %EM_FORMATRANGE%, %Render%, &FR, , % "ahk_id " . This.HWND
         PrintC := ErrorLevel
         If (PageC >= PageF) && (PageC <= PageL) {
            ; EndPage function. Break If there is a problem.
            If (DllCall("Gdi32.dll\EndPage", "Ptr", PDC, "Int") <= 0) {
               ErrorMsg := "Function: " . A_ThisFunc . " - DLLCall of 'EndPage' failed."
               Break
            }
         }
         ; Update FR for the next page
         Offset := (A_PtrSize * 2) + (4 * 8)
         Numput(PrintC, FR, Offset += 0, "Int") ; cr.cpMin
         NumPut(PrintE, FR, Offset += 4, "Int") ; cr.cpMax
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; End the print job
      DllCall("Gdi32.dll\EndDoc", "Ptr", PDC)
      ; Delete the printer device context
      DllCall("Gdi32.dll\DeleteDC", "Ptr", PDC)
      ; Reset control (free cached information)
      SendMessage %EM_FORMATRANGE%, 0, 0, , % "ahk_id " . This.HWND
      ; Return to sender
      If (ErrorMsg) {
         ErrorLevel := ErrorMsg
         Return False
      }
      Return True
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetMargins() { ; Get the default print margins
      Static PSD_RETURNDEFAULT := 0x00000400, PSD_INTHOUSANDTHSOFINCHES := 0x00000004
           , I := 1000 ; thousandth of inches
           , M := 2540 ; hundredth of millimeters
           , PSD_Size := (4 * 10) + (A_PtrSize * 11)
           , PD_Size := (A_PtrSize = 8 ? (13 * A_PtrSize) + 16 : 66)
           , OffFlags := 4 * A_PtrSize
           , OffMargins := OffFlags + (4 * 7)
      If !This.HasKey("Margins") {
         VarSetCapacity(PSD, PSD_Size, 0) ; PAGESETUPDLG structure
         NumPut(PSD_Size, PSD, 0, "UInt")
         NumPut(PSD_RETURNDEFAULT, PSD, OffFlags, "UInt")
         If !DllCall("Comdlg32.dll\PageSetupDlg", "Ptr", &PSD, "UInt")
            Return false
         DllCall("Kernel32.dll\GobalFree", UInt, NumGet(PSD, 2 * A_PtrSize, "UPtr"))
         DllCall("Kernel32.dll\GobalFree", UInt, NumGet(PSD, 3 * A_PtrSize, "UPtr"))
         Flags := NumGet(PSD, OffFlags, "UInt")
         Metrics := (Flags & PSD_INTHOUSANDTHSOFINCHES) ? I : M
         Offset := OffMargins
         This.Margins := {}
         This.Margins.L := NumGet(PSD, Offset += 0, "Int")           ; Left
         This.Margins.T := NumGet(PSD, Offset += 4, "Int")           ; Top
         This.Margins.R := NumGet(PSD, Offset += 4, "Int")           ; Right
         This.Margins.B := NumGet(PSD, Offset += 4, "Int")           ; Bottom
         This.Margins.LT := Round((This.Margins.L / Metrics) * 1440) ; Left in twips
         This.Margins.TT := Round((This.Margins.T / Metrics) * 1440) ; Top in twips
         This.Margins.RT := Round((This.Margins.R / Metrics) * 1440) ; Right in twips
         This.Margins.BT := Round((This.Margins.B / Metrics) * 1440) ; Bottom in twips
      }
      Return True
   }
   ; -------------------------------------------------------------------------------------------------------------------
   GetPrinterCaps(DC) { ; Get printer's capacities
      Static HORZRES         := 0x08, VERTRES         := 0x0A
           , LOGPIXELSX      := 0x58, LOGPIXELSY      := 0x5A
           , PHYSICALWIDTH   := 0x6E, PHYSICALHEIGHT  := 0x6F
           , PHYSICALOFFSETX := 0x70, PHYSICALOFFSETY := 0x71
           , Caps := {}
      ; Number of pixels per logical inch along the page width and height
      LPXX := DllCall("Gdi32.dll\GetDeviceCaps", "Ptr", DC, "Int", LOGPIXELSX, "Int")
      LPXY := DllCall("Gdi32.dll\GetDeviceCaps", "Ptr", DC, "Int", LOGPIXELSY, "Int")
      ; The width and height of the physical page, in twips.
      Caps.PHYW := Round((DllCall("Gdi32.dll\GetDeviceCaps", "Ptr", DC, "Int", PHYSICALWIDTH, "Int") / LPXX) * 1440)
      Caps.PHYH := Round((DllCall("Gdi32.dll\GetDeviceCaps", "Ptr", DC, "Int", PHYSICALHEIGHT, "Int") / LPXY) * 1440)
      ; The distance from the left/right edge (PHYSICALOFFSETX) and the top/bottom edge (PHYSICALOFFSETY) of the
      ; physical page to the edge of the printable area, in twips.
      Caps.POFX := Round((DllCall("Gdi32.dll\GetDeviceCaps", "Ptr", DC, "Int", PHYSICALOFFSETX, "Int") / LPXX) * 1440)
      Caps.POFY := Round((DllCall("Gdi32.dll\GetDeviceCaps", "Ptr", DC, "Int", PHYSICALOFFSETY, "Int") / LPXY) * 1440)
      ; Width and height of the printable area of the page, in twips.
      Caps.HRES := Round((DllCall("Gdi32.dll\GetDeviceCaps", "Ptr", DC, "Int", HORZRES, "Int") / LPXX) * 1440)
      Caps.VRES := Round((DllCall("Gdi32.dll\GetDeviceCaps", "Ptr", DC, "Int", VERTRES, "Int") / LPXY) * 1440)
      Return Caps
   }
}
