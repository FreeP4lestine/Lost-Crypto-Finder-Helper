#Requires AutoHotkey v1.1
#SingleInstance, Force
SetBatchLines, -1
#NoEnv
SetWorkingDir, % A_ScriptDir

#Include, Lib\Classes\Class_CtlColors.ahk
#Include, Lib\Classes\Class_ImageButton.ahk
#Include, Lib\Classes\Class_GDIplus.ahk

#Include, Lib\Language.ahk

FolderSet()
Colors := [0, 1, 3, 4, 5, 6, 7, 8, 9, "A", "B", "C", "D", "E", "F"]

Gui, +HwndMain
Gui, Margin, 10, 15
Gui, Color, 0xE6E6E6
Gui, Font, s12 Bold, Consolas

If (Acc := FileExist("Sets\Acc.chu")) {
    Account := {}
    FileRead, RawAccount, Sets\Acc.chu
    TextAccount := b64Decode(RawAccount)
    
    For Each, User in StrSplit(TextAccount, ",") {
        LOG := StrSplit(User, "|")
        Account[LOG[1]] := [LOG[2], LOG[3]]
    }
}

Gui, Add, Pic,, Img\Keys.png
Gui, Add, Text, xm+65 yp+5 w140 Center, % (Acc ? _87 : _92) ":"
Gui, Add, Edit, xp+140 yp-3 w200 vUserName -E0x200 Border
Gui, Add, Text, xp-140 yp+35 w140 Center, % (Acc ? _88 : _93) ":"
Gui, Add, Edit, xp+140 yp-3 w200 vPassWord -E0x200 Border

Gui, Add, Button, % "xp+100 yp+35 w100 HwndHCtrl vLogin g" (Acc ? E := "Next" : E := "NewNext"), % Acc ? _109 : _196
ImageButton.Create(HCtrl, [[3, 0x80FF80, 0x5ABB5A, 0x000000, 2,, 0x008000, 1]
                         , [3, 0x44DB44, 0x2F982F, 0x000000, 2,, 0x008000, 1]
                         , [3, 0x1AB81A, 0x107410, 0x000000, 2,, 0x008000, 1]
                         , [3, 0xCCCCCC, 0xCCCCCC, 0x000000, 2,, 0x999999, 1]]*)
Gui, Font, s10
Gui, Add, CheckBox, % "xm yp+35 vRL", % _32

If (!Acc) {
    GuiControl, Disabled, CN
    GuiControl, Disabled, RL
}

FileRead, CV, Version.txt
Gui, Add, Text, vCV w50, % "v" CV
Gui, Show,, LOGIN GUI

If FileExist("Sets\RAcc.chu") {
    FileRead, RawRL, Sets\RAcc.chu
    TextRL := StrSplit(b64Decode(RawRL), "|")
    If (Account[TextRL[1]][1] = TextRL[2]) {
        GuiControl, Focus, UserName
        SendInput, % TextRL[1]
        GuiControl, Focus, PassWord
        SendInput, % TextRL[2]
        GuiControl,, RL, 1
    }
}

If IsConnected()  {
    ;URLDownloadToFile, https://raw.githubusercontent.com/FreeP4lestine/Cassier/main/Program/Release/Version.txt, LVersion.txt
    ;If (!ErrorLevel) {
    ;    FileRead, LV, LVersion.txt
    ;    LV := Trim(LV, "`n")
    ;    If (StrReplace(LV, ".") > StrReplace(CV, ".")) {
    ;        Gui, Add, Button, xp+70 yp-5 wp+100 gUpdate HwndHCtrl vUpdate, % "[" LV "] - " _192
    ;        ImageButton.Create(HCtrl, [[3, 0xFF6F6F, 0xBC5454, 0x000000, 2,, 0xFF0000, 1]
    ;                                 , [3, 0xDC6262, 0x9C4545, 0x000000, 2,, 0xFF0000, 1]
    ;                                 , [3, 0xBF5454, 0x8A3C3C, 0x000000, 2,, 0xFF0000, 1]
    ;                                 , [3, 0xCCCCCC, 0xCCCCCC, 0x000000, 2,, 0xFF0000, 1]]*)
    ;    }
    ;}
}
Return

#If WinActive("ahk_id " Main)
    Enter::
        GoSub, % E
    Return
#If

GuiClose:
    IniRead, PIDs, Sets\PID.ini, PID
    Loop, Parse, PIDs, `n, `r
    {
        Process, Close, % StrSplit(A_LoopField, "=")[2]
    }
ExitApp

Update:
    ;Gui, Hide
    ;Run, % "GUIUpdate" (A_IsCompiled ? ".exe" : ".ahk"),,, PID
    ;URLDownloadToFile, https://github.com/FreeP4lestine/Cassier/raw/main/Installer/Install.exe, % A_Temp "\Install.exe"
    ;Process, Close, % PID
    ;Run, % A_Temp "\Install.exe"
    ;ExitApp
Return

NewNext:
    GuiControlGet, UserName,, UserName
    GuiControlGet, PassWord,, PassWord
    If (UserName != "") && (PassWord != "") {
        If (Obj := FileOpen("Sets\Acc.chu", "w")) {
            Obj.Write(b64Encode(UserName "|" PassWord "|Admin")).Close()
            Reload
        }
    }
Return

Next:
    GuiControlGet, UserName,, UserName
    GuiControlGet, PassWord,, PassWord
    If (UserName != "") && (PassWord == Account[UserName][1]) {
        If (Account[UserName][1] != "") {
            GuiControlGet, RL,, RL
            If (RL) {
                FileOpen("Sets\RAcc.chu", "w").Write(b64Encode(UserName "|" PassWord)).Close()
            } Else {
                FileDelete, Sets\RAcc.chu
            }
            
            Gui, Destroy
            Gui, +HwndMain
            Gui, Margin, 10, 10
            Gui, Color, 0xE6E6E6
            Gui, Font, s12 Bold, Consolas

            Gui, Add, Button, w140 h90 gGUISell HwndHCtrl, % "`n`n`n" _115
            ImageButton.Create(HCtrl, [[0, "Img\OM\1.png"]
                                     , [0, "Img\OM\2.png",, 0x0080FF]
                                     , [0, "Img\OM\3.png",, 0xFF0000]
                                     , [0, "Img\OM\4.png"]]*)
            If (Account[UserName][2] = "Admin") {
                Gui, Add, Button, xp+150 yp w140 h90 gGUISubmit HwndHCtrl, % "`n`n`n" _116
                ImageButton.Create(HCtrl, [ [0, "Img\ED\1.png"]
                                        ,   [0, "Img\ED\2.png",, 0x0080FF]
                                        ,   [0, "Img\ED\3.png",, 0xFF0000]
                                        ,   [0, "Img\ED\4.png"]]*)
                Gui, Add, Button, xp+150 yp w140 h90 gGUIDefine HwndHCtrl, % "`n`n`n" _117
                ImageButton.Create(HCtrl, [ [0, "Img\DE\1.png"]
                                        ,   [0, "Img\DE\2.png",, 0x0080FF]
                                        ,   [0, "Img\DE\3.png",, 0xFF0000]
                                        ,   [0, "Img\DE\4.png"]]*)
                Gui, Add, Button, xp+150 yp w140 h90 gGUIReview HwndHCtrl, % "`n`n`n" _119
                ImageButton.Create(HCtrl, [ [0, "Img\PR\1.png"]
                                        ,   [0, "Img\PR\2.png",, 0x0080FF]
                                        ,   [0, "Img\PR\3.png",, 0xFF0000]
                                        ,   [0, "Img\PR\4.png"]]*)
                Gui, Add, Button, xp+150 yp w140 h90 gGUIKridiM HwndHCtrl, % "`n`n`n" _121
                ImageButton.Create(HCtrl, [ [0, "Img\KR\1.png"]
                                        ,   [0, "Img\KR\2.png",, 0x0080FF]
                                        ,   [0, "Img\KR\3.png",, 0xFF0000]
                                        ,   [0, "Img\KR\4.png"]]*)
                Gui, Add, Button, xp+150 yp w140 h90 gGUIUser HwndHCtrl, % "`n`n`n" _156
                ImageButton.Create(HCtrl, [ [0, "Img\AM\1.png"]
                                          , [0, "Img\AM\2.png",, 0x0080FF]
                                          , [0, "Img\AM\3.png",, 0xFF0000]
                                          , [0, "Img\AM\4.png"]]*)
            }
            Gui, Show,, START UP GUI
            OnMessage(0x1000, "Message")
            FileOpen("Sets\Login.Hwnd", "w").Write(Main).Close()
        }
    }
Return

GUISell:
    Run, % "GUISell" (A_IsCompiled ? ".exe" : ".ahk") " " UserName " " PassWord,,, PID
    IniWrite, % PID, Sets\PID.ini, PID, GUISell
Return

GUISubmit:
    Run, % "GUISubmit" (A_IsCompiled ? ".exe" : ".ahk") " " UserName " " PassWord,,, PID
    IniWrite, % PID, Sets\PID.ini, PID, GUISubmit
Return

GUIDefine:
    Run, % "GUIDefine" (A_IsCompiled ? ".exe" : ".ahk") " " UserName " " PassWord,,, PID
    IniWrite, % PID, Sets\PID.ini, PID, GUIDefine
Return
    
GUIReview:
    Run, % "GUIReview" (A_IsCompiled ? ".exe" : ".ahk") " " UserName " " PassWord,,, PID
    IniWrite, % PID, Sets\PID.ini, PID, GUIReview
Return

GUIKridiM:
    Run, % "GUIKridiM" (A_IsCompiled ? ".exe" : ".ahk") " " UserName " " PassWord,,, PID
    IniWrite, % PID, Sets\PID.ini, PID, GUIKridiM
Return

GUIUser:
    Run, % "GUIUser" (A_IsCompiled ? ".exe" : ".ahk") " " UserName " " PassWord,,, PID
    IniWrite, % PID, Sets\PID.ini, PID, GUIUser
Return

b64Encode(string) {
    VarSetCapacity(bin, StrPut(string, "UTF-8")) && len := StrPut(string, &bin, "UTF-8") - 1 
    if !(DllCall("crypt32\CryptBinaryToString", "ptr", &bin, "uint", len, "uint", 0x1, "ptr", 0, "uint*", size))
        throw Exception("CryptBinaryToString failed", -1)
    VarSetCapacity(buf, size << 1, 0)
    if !(DllCall("crypt32\CryptBinaryToString", "ptr", &bin, "uint", len, "uint", 0x1, "ptr", &buf, "uint*", size))
        throw Exception("CryptBinaryToString failed", -1)
    return StrGet(&buf)
}

b64Decode(string) {
    if !(DllCall("crypt32\CryptStringToBinary", "ptr", &string, "uint", 0, "uint", 0x1, "ptr", 0, "uint*", size, "ptr", 0, "ptr", 0))
        throw Exception("CryptStringToBinary failed", -1)
    VarSetCapacity(buf, size, 0)
    if !(DllCall("crypt32\CryptStringToBinary", "ptr", &string, "uint", 0, "uint", 0x1, "ptr", &buf, "uint*", size, "ptr", 0, "ptr", 0))
        throw Exception("CryptStringToBinary failed", -1)
    return StrGet(&buf, size, "UTF-8")
}

FolderSet() {
    Array := [ "Curr"
             , "Sets"
             , "Sets\Def"
             , "Valid"
             , "Dump"
             , "Kr"
             , "Unvalid"
             , "Hist"    ]
    For Every, Folder in Array {
        If !FolderExist(Folder) {
            FileCreateDir, % Folder
        }
    }
}

FolderExist(Folder) {
    Return InStr(FileExist(Folder), "D")
}

IsConnected() {
    Return DllCall("Wininet.dll\InternetGetConnectedState", "Str", 0x40, "Int", 0)
}

Message() {
    Global Account, UserName, PassWord
    FileRead, Message, Sets\Login.Request
    MsgData := StrSplit(Message, "|")
    If (MsgData[1] = "Run") {
        If (Account[UserName][2] = "Admin") {
            Run, % MsgData[2] " " UserName " " PassWord
        } Else If InStr(MsgData[2], "GUISell") {
            Run, % MsgData[2] " " UserName " " PassWord
        }
    } Else If (MsgData[1] = "Reload") {
        IniRead, PIDs, Sets\PID.ini, PID
        Loop, Parse, PIDs, `n, `r
        {
            Process, Close, % StrSplit(A_LoopField, "=")[2]
        }
        Reload
    }
}

RandomColor(Colors) {
    Color := ""
    Loop, 6 {
        Random, Index, 1, 16
        Color .= Colors[Index]
    }
    Return, Color
}