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

ButtonTheme := [[3, 0x80FF80, 0x5ABB5A, 0x000000, 2,, 0x008000, 1]
              , [3, 0x44DB44, 0x2F982F, 0x000000, 2,, 0x008000, 1]
              , [3, 0x1AB81A, 0x107410, 0x000000, 2,, 0x008000, 1]
              , [3, 0xCCCCCC, 0xCCCCCC, 0x000000, 2,, 0x999999, 1]]

ButtonTheme2 := [[3, 0xFF6F6F, 0xBC5454, 0x000000, 2,, 0xFF0000, 1]
               , [3, 0xDC6262, 0x9C4545, 0x000000, 2,, 0xFF0000, 1]
               , [3, 0xBF5454, 0x8A3C3C, 0x000000, 2,, 0xFF0000, 1]
               , [3, 0xCCCCCC, 0xCCCCCC, 0x000000, 2,, 0xFF0000, 1]]
               
ButtonTheme3 := [[3, 0xFFC080, 0xBE8F60, 0x000000, 2,, 0xFF8000, 1]
               , [3, 0xE0AA72, 0xA47C53, 0x000000, 2,, 0xFF8000, 1]
               , [3, 0xC89664, 0x906D48, 0x000000, 2,, 0xFF8000, 1]
               , [3, 0xCCCCCC, 0xCCCCCC, 0x000000, 2,, 0xFF8000, 1]]

ButtonTheme4 := [[3, 0x96C864, 0x739A4C, 0x000000, 2,, 0x80FF00, 1]
               , [3, 0x8CBB5D, 0x658643, 0x000000, 2,, 0x80FF00, 1]
               , [3, 0x79A051, 0x56733A, 0x000000, 2,, 0x80FF00, 1]
               , [3, 0xCCCCCC, 0xCCCCCC, 0x000000, 2,, 0x80FF00, 1]]

Gui, Add, Button, % "xm+5 ym+20 gAdd HwndHCtrl w190 h60", % _198
ImageButton.Create(HCtrl, ButtonTheme* )

Gui, Font, s16
Gui, Add, Edit, % "xm+5 ym+90 wp r2 vAllKridi -E0x200 Border Center ReadOnly HwndHCtrl -VScroll"
CtlColors.Attach(HCtrl, "EAEAB5")

Gui, Font, s14
qw := ((A_ScreenWidth - 255) // 3)
Gui, Add, ListBox, % "wp h" A_ScreenHeight - 340 " vKLB HwndHCtrl Multi gShowKridiInfo 0x100"
CtlColors.Attach(HCtrl, "EAEAB5")
Gui, Font, s16
Gui, Add, Button, % "gDelete HwndHCtrl wp h60", % _191
ImageButton.Create(HCtrl, ButtonTheme2* )

Gui, Font, s14
Gui, Add, ListView, % "xm+421 ym+20 w" qw * 3 - 391 " h" A_ScreenHeight - 200 " vLV", % "|" _38 "|" _68 "|" _39

LV_ModifyCol(1, "0 Center")
LV_ModifyCol(2, qw - 130)
LV_ModifyCol(3, qw - 130)
LV_ModifyCol(4, qw - 130)

Gui, Font, s16
Gui, Add, Edit, % "xp-201 yp w190 r2 vThisKridi -E0x200 Border Center ReadOnly HwndHCtrl -VScroll"
CtlColors.Attach(HCtrl, "FFC080")

Gui, Font, s14
Gui, Add, ListBox, % "wp h" A_ScreenHeight - 425 " vKDate gSelectFromLv AltSubmit HwndHCtrl Multi 0x100"
CtlColors.Attach(HCtrl, "FFC080")

Gui, Font, s16
Gui, Add, Edit, % "wp r2 vSubThisKridi -E0x200 Border Center ReadOnly HwndHCtrl -VScroll"
CtlColors.Attach(HCtrl, "FFC080")

Gui, Add, Edit, % "wp vKridi -E0x200 Border Center HwndHCtrl -VScroll Number"
CtlColors.Attach(HCtrl, "FFFFFF")

Gui, Add, Button, % "wp h30 HwndHCtrl gKridiOut", % _29
ImageButton.Create(HCtrl, ButtonTheme3*)

Gui, Add, Edit, % "xm+" qw * 3 - 391 + 12 + 421 " ym+20 wp r2 vPay -E0x200 Border Center ReadOnly HwndHCtrl -VScroll"
CtlColors.Attach(HCtrl, "96C864")

Gui, Font, s14
Gui, Add, ListBox, % "wp h" A_ScreenHeight - 425 " vPDate HwndHCtrl AltSubmit gShowPayVal 0x100"
CtlColors.Attach(HCtrl, "96C864")

Gui, Font, s16
Gui, Add, Edit, % "wp r2 vThisPay -E0x200 Border Center ReadOnly HwndHCtrl -VScroll"
CtlColors.Attach(HCtrl, "96C864")

Gui, Add, Edit, % "wp vPayBack -E0x200 Border Center HwndHCtrl -VScroll Number"
CtlColors.Attach(HCtrl, "FFFFFF")

Gui, Add, Button, % "wp h30 HwndHCtrl gPayOut", % _186
ImageButton.Create(HCtrl, ButtonTheme4*)

Gui, Font, s20
Gui, Add, Edit, % "vBalance xm+421 y" A_ScreenHeight - 160 " w" qw * 3 - 391 " -E0x200 Border Center HwndHCtrl ReadOnly"
CtlColors.Attach(HCtrl, "D8D8AD", "FF0000")

Gui, Font, s12
Levels := ["Admin", "User"]
Gui, Add, StatusBar
SB_SetParts(10, 200, 200)
SB_SetText(_206 ": " AdminName, 2)
SB_SetText(_207 ": " Levels[Level], 3)

Gui, Show, Maximize, Review GUI
ThemeAdd()
LoadKridis()
Return

#Include, GUIKridiM_Hotkeys.ahk
#Include, GUIKridiM_Functions.ahk
#Include, GUIKridiM_Labels.ahk