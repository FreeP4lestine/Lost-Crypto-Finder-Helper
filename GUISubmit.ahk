#Requires AutoHotkey v1.1
#SingleInstance, Force
SetBatchLines, -1
SetWorkingDir, % A_ScriptDir

#Include, Lib\Classes\Class_CtlColors.ahk
#Include, Lib\Classes\Class_ImageButton.ahk
#Include, Lib\Classes\Class_GDIplus.ahk

#Include, Lib\Language.ahk

FolderSet()

If !Level := LogIn(AdminName := A_Args[1], AdminPass := A_Args[2]) {
    FileRead, Reciever, Sets\Login.Hwnd
    FileOpen("Sets\Login.Request", "w").Write("Run|" A_ScriptFullPath).Close()
    SendMessage, 0x1000,,,, ahk_id %Reciever%
    Sleep, 1000
    MsgBox, 16, % _112, % _114
    ExitApp
}

Gui, +HwndMain +Resize
Gui, Add, Pic, % "x0 y0", Img\BG.png
Gui, Margin, 10, 10
Gui, Color, 0x7D7D3A
Gui, Font, s14 Bold, Calibri

Gui, Add, Text, % "xm+5 ym w190 vProfByProductText BackgroundTrans", % _202 ":"
Gui, Add, DDL, xp yp+30 wp vProfByProduct gShowTheInfo AltSubmit, % _203 "||" _204

Gui, Add, Text, % "wp vProfByNameText BackgroundTrans", % _156 ":"
Gui, Add, DDL, xp yp+30 wp vProfByName gShowTheInfo

Gui, Add, Text, % "wp vDatesText BackgroundTrans", % _72 ":"
Gui, Font, Italic
Gui, Add, ListBox, % "0x100 wp h" A_ScreenHeight - 330 " vDates HwndHCtrl gShowTheInfo Multi"
CtlColors.Attach(HCtrl, "D8D8AD", "404000")

Gui, Font, Norm
Gui, Font, s15 Bold

qw := ((A_ScreenWidth - 255) / 2)

ButtonTheme := [[3, 0x80FF80, 0x5ABB5A, 0x000000, 2,, 0x008000, 1]
              , [3, 0x44DB44, 0x2F982F, 0x000000, 2,, 0x008000, 1]
              , [3, 0x1AB81A, 0x107410, 0x000000, 2,, 0x008000, 1]
              , [3, 0xCCCCCC, 0xCCCCCC, 0x000000, 2,, 0x999999, 1]]

Gui, Add, Button, % "x" A_ScreenWidth - 327 " ym+40 vEnsBtn w300 h40 HwndHCtrl gValid", % _9
ImageButton.Create(HCtrl, ButtonTheme*)

Gui, Font, s12 Italic
Gui, Add, Edit, % "xm+220 yp+10 w" qw " vOverview -E0x200 HwndHCtrl"
CtlColors.Attach(HCtrl, "000000", "FFFF00")

Gui, Font, Norm
Gui, Font, s15 Bold
Gui, Add, ListView, % "w" (qw * 2) " h" A_ScreenHeight - 240 " vLV Grid gShowDetails HwndHCtrl BackgroundE6E6E6 -Multi", % _70 "|" _71 "|" _39 "|" _40 "|" _41 "|" _79

LV_ModifyCol(1, "0")
LV_ModifyCol(2, qw)
LV_ModifyCol(3, 0)
LV_ModifyCol(4, 0)
LV_ModifyCol(5, 0)
LV_ModifyCol(6, qw)

Gui, Font, s20
Gui, Add, Edit, % "xm+220 y" A_ScreenHeight - 132 " w" (qw * 2) / 3 " vSold Center -E0x200 ReadOnly cGreen Border HwndHCtrl"
CtlColors.Attach(HCtrl, "EAEAB5", "404000")
Gui, Font, s15
Gui, Add, Button, xm+5 yp w190 gChart vChart HwndHCtrl h40, % "→ " _173 " ←"
ImageButton.Create(HCtrl, ButtonTheme*)

Gui, Font, s20
Gui, Add, Edit, % "xp+" (qw * 2)/3 + 215 " yp w" (qw * 2) / 3 " h40 vBought -E0x200 ReadOnly Center cRed Border HwndHCtrl"
CtlColors.Attach(HCtrl, "EAEAB5", "FF0000")
Gui, Add, Edit, % "xp+" (qw * 2)/3 " yp wp hp vProfitEq -E0x200 ReadOnly Center cGreen Border HwndHCtrl"
CtlColors.Attach(HCtrl, "EAEAB5", "008000")
ThemeAdd()

Gui, Font, s12
Levels := ["Admin", "User"]
View := ["Normal", "More Details"]
Gui, Add, StatusBar
SB_SetParts(10, 200, 200)
SB_SetText(_206 ": " AdminName, 2)
SB_SetText(_207 ": " Levels[Level], 3)
Gui, Show, Maximize, Submit GUI
Global LVContent, Header := 1
LoadAllSells()
AnalyzeUsers()
AnalyzeDates()
GuiControl, Choose, Dates, |1
Return

#Include, GUISubmit_Hotkeys.ahk
#Include, GUISubmit_Functions.ahk
#Include, GUISubmit_Labels.ahk