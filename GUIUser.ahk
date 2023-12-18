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
Gui, Font, s12 Bold, Calibri

ButtonTheme := [[3, 0x80FF80, 0x5ABB5A, 0x000000, 2,, 0x008000, 1]
              , [3, 0x44DB44, 0x2F982F, 0x000000, 2,, 0x008000, 1]
              , [3, 0x1AB81A, 0x107410, 0x000000, 2,, 0x008000, 1]
              , [3, 0xCCCCCC, 0xCCCCCC, 0x000000, 2,, 0x999999, 1]]

ButtonTheme2 := [[3, 0xFF6F6F, 0xBC5454, 0x000000, 2,, 0xFF0000, 1]
               , [3, 0xDC6262, 0x9C4545, 0x000000, 2,, 0xFF0000, 1]
               , [3, 0xBF5454, 0x8A3C3C, 0x000000, 2,, 0xFF0000, 1]
               , [3, 0xCCCCCC, 0xCCCCCC, 0x000000, 2,, 0xFF0000, 1]]
qw := (A_ScreenWidth - 20) / 3
Gui, Add, GroupBox, % "BackgroundTrans xm+5 ym w" qw " h" A_ScreenHeight - 100, % _156

Gui, Add, Button, % "HwndHCtrl xp+" qw - 320 " yp+30 w150 gAddUser h30", % _89 " [++]"
ImageButton.Create(HCtrl, ButtonTheme* )

Gui, Add, Button, % "HwndHCtrl xp+160 yp wp gDelUser h30", % _91 " [--]"
ImageButton.Create(HCtrl, ButtonTheme2* )

Gui, Add, ListView, % "AltSubmit xm+15 ym+65 w" qw - 20 " h" A_ScreenHeight - 180 " gShowInfo c804000", % _38 "|" _88 "|" _207
LV_ModifyCol(1, (qw-20) / 3)
LV_ModifyCol(2, (qw-20) / 3)
LV_ModifyCol(3, (qw-20) / 3)
Gui, Add, GroupBox, % "BackgroundTrans xm+" qw + 10 " ym w" qw " h" A_ScreenHeight - 100, % _211
Gui, Add, Text, xp+10 yp+30 BackgroundTrans, % _214 ": "
Gui, Add, Pic, % "xp+" ((qw - 220) / 2) " yp+30 w200 h200 vUserPic Border BackgroundTrans gChooseAPic", Img\UserLogo.png
Gui, Add, Text, % "xp-" ((qw - 220) / 2) " yp+220 BackgroundTrans" , % _87 ": "
Gui, Add, Edit, % "vUN w" qw - 20 " -E0x200 Border cGreen"
Gui, Add, Text, BackgroundTrans , % _88 ": "
Gui, Add, Edit, % "w" qw - 20 " vPW -E0x200 Border cRed"
Gui, Add, Text, BackgroundTrans , % _207 ": "
Gui, Add, DDL, % "w" qw - 20 " vLVL -E0x200 Border", %_212%|%_213%
Gui, Add, Button, % "HwndHCtrl xp yp+50 wp gSaveChanges h30", % _62
ImageButton.Create(HCtrl, ButtonTheme* )

Gui, Add, GroupBox, % "BackgroundTrans xm+" (qw + 8) * 2 " ym w" qw - 15 " h" A_ScreenHeight - 100, % _215
Gui, Add, CheckBox, % "BackgroundTrans Center xp+10 yp+30 wp-20", % _216
Gui, Add, CheckBox, % "BackgroundTrans Center wp", % _222
Gui, Add, CheckBox, % "BackgroundTrans Center wp", % _223
Gui, Add, CheckBox, % "BackgroundTrans Center wp", % _217
Gui, Add, CheckBox, % "BackgroundTrans Center wp", % _218
Gui, Add, CheckBox, % "BackgroundTrans Center wp", % _219
Gui, Add, CheckBox, % "BackgroundTrans Center wp", % _220
Gui, Add, CheckBox, % "BackgroundTrans Center wp", % _221

Global UserList
LoadAccounts()

Gui, Font, s12
Levels := ["Admin", "User"]
Gui, Add, StatusBar
SB_SetParts(10, 200, 200)
SB_SetText(_206 ": " AdminName, 2)
SB_SetText(_207 ": " Levels[Level], 3)
Gui, Show, Maximize, GUI User
Return

#Include, GUIUser_Functions.ahk
#Include, GUIUser_Hotkeys.ahk
#Include, GUIUser_Labels.ahk