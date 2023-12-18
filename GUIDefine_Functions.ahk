LoadGroups() {
    Global _74
    GuiControl,, Group, |
    GuiControl,, Group, % _74
    Loop, Files, Sets\Def\*, D
        GuiControl,, Group, % A_LoopFileName
    GuiControl, Choose, Group, |1
}

LogIn(Username, Password) {
    If (FileExist("Sets\Acc.chu")) {
        Account := {}
        FileRead, RawAccount, Sets\Acc.chu
        TextAccount := b64Decode(RawAccount)
        
        For Each, User in StrSplit(TextAccount, ",") {
            LOG := StrSplit(User, "|")
            Account[LOG[1]] := [LOG[2], LOG[3]]
        }
        
        If (Account[Username][1] = Password) {
            If (Account[Username][2] = "Admin")
                Return, 1
            Else If (Account[Username][2] = "User")
                Return, 2
        }
    }
    Return, 0
}

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

LoadProducts() {
    LV_Delete(), Files := "", Loc := {}
    GuiControl,, StockSum
    Loop, Files, % "Sets\Def\*.def", R
    {
        Bc := StrReplace(A_LoopFileName, ".def")
        Files .= Files != "" ? "`n" Bc : Bc
        Loc["" Bc ""] := A_LoopFileFullPath
    }

    Sort, Files, N
    StockSum := 0

    GuiControlGet, ViewMode,, ViewMode
    Loop, Parse, Files, `n
    {
        If (ViewMode = 2) && !FileExist("Sets\Def\" A_LoopField ".def") {
            Continue
        }
        FileRead, Content, % Loc["" A_LoopField ""]
        Content := StrSplit(Content, ";"), Content[4] != "" ? StockSum += Content[4] * Content[3] : 0
        LV_Add(, A_LoopField, Content[1], Content[2], Content[3], "[" (Content[4] != "" ? Content[4] : 0) "]")
        GuiControl,, StockSum, % StockSum " " ConvertMillimsToDT(StockSum)
        
    }
    Return, StockSum
}

ConvertMillimsToDT(Value, Sign := "") {
    If (Value + 1 = "")
        Return
    ValueArr := StrSplit(Value / 1000, ".")
    Return, "[" ValueArr[1] (ValueArr[2] ? "." RTrim(ValueArr[2], 0) : "") " DT]"
}

FolderSet() {
    Array := [ "Curr"
             , "Sets"
             , "Sets\Def"
             , "Valid"
             , "Dump"
             , "Kr"
             , "CKr" 
             , "Unvalid" 
             , "Hist" ]

    For Every, Folder in Array {
        If !FolderExist(Folder) {
            FileCreateDir, % Folder
        }
    }
}

FolderExist(Folder) {
    Return InStr(FileExist(Folder), "D")
}

ThemeAdd() {
    Loop, 5 {
        Gui, Add, Text, % "y0 x" 208 + A_Index * 2 " w1 h" A_ScreenHeight " HwndHCtrl"
        CtlColors.Attach(HCtrl, "7D7D64")
    }
}

Add() {
    Global StockSum, _177, _178
    GuiControlGet, Dbc,, Dbc
    
    ExistedDef := ""
    Loop, Files, % "Sets\Def\" Dbc ".def", R
    {
        ExistedDef := A_LoopFileFullPath
    }

    If (ExistedDef != "") {
        FileRead, Content, % ExistedDef
        MsgBox, 48, % _177, % _178 "`n`n" Dbc " = " StrSplit(Content, ";")[1]
        Return, 0
    }
    
    GuiControlGet, Group,, Group
    WD := (Group = "ALL") ? "Sets\Def\" : "Sets\Def\" Group "\"

    GuiControlGet, Dnm,, Dnm
    GuiControlGet, Dbp,, Dbp
    GuiControlGet, Dsp,, Dsp
    GuiControlGet, Dst,, Dst

    LV_Insert(1,, Dbc, Dnm, Dbp, Dsp, "[" Dst "]")
    FileOpen(WD Dbc ".def", "w").Write(Dnm ";" Dbp ";" Dsp ";" Dst).Close()
    
    GuiControl,, Dbc
    GuiControl,, Dnm
    GuiControl,, Dbp
    GuiControl,, Dsp
    GuiControl,, Dst

    StockSum += Dsp * Dst
    GuiControl,, StockSum, % StockSum " " ConvertMillimsToDT(StockSum)
    GuiControl, Focus, Dbc

    FileOpen("Sets\Message.Request", "w").Write("Update_Definitions").Close()
    FileRead, Reciever, Sets\GUISell.Hwnd
    SendMessage, 0x1000,,,, ahk_id %Reciever%
    Return, 1
}

Modify() {
    Global Row, _177, _178, StockSum
    GuiControlGet, Dbc,, Dbc
    LV_GetText(Bc, Row, 1)
    ExistedDef := ""
    Loop, Files, % "Sets\Def\" Dbc ".def", R
    {
        ExistedDef := A_LoopFileFullPath
    }

    If (Bc != Dbc) && (ExistedDef != "") {
        FileRead, Content, % ExistedDef
        MsgBox, 48, % _177, % _178 "`n`n" Dbc " = " StrSplit(Content, ";")[1]
        Return, 0
    }

    ExistedDef := ""
    Loop, Files, % "Sets\Def\" Bc ".def", R
    {
        ExistedDef := A_LoopFileFullPath
    }

    If (ExistedDef != "") {
        SplitPath, % ExistedDef,, WD
        WD .= "\"
    } Else {
        GuiControlGet, Group,, Group
        WD := (Group = "ALL") ? "Sets\Def\" : "Sets\Def\" Group "\"
    }

    GuiControlGet, Dnm,, Dnm
    GuiControlGet, Dbp,, Dbp
    GuiControlGet, Dsp,, Dsp
    GuiControlGet, Dst,, Dst
    
    FileDelete, % WD Bc ".def"
    FileOpen(WD Dbc ".def", "w").Write(Dnm ";" Dbp ";" Dsp ";" Dst).Close()
    
    LV_GetText(St, Row, 5)
    LV_GetText(Sp, Row, 4)
    StockSum -= Trim(St, "[]") * Sp
    StockSum += Dsp * Dst
    LV_Modify(Row,, Dbc, Dnm, Dbp, Dsp, "[" Dst "]")

    GuiControl,, Dbc
    GuiControl,, Dnm
    GuiControl,, Dbp
    GuiControl,, Dsp
    GuiControl,, Dst
    GuiControl,, StockSum, % StockSum " " ConvertMillimsToDT(StockSum)
    GuiControl, Focus, Dbc

    FileOpen("Sets\Message.Request", "w").Write("Update_Definitions").Close()
    FileRead, Reciever, Sets\GUISell.Hwnd
    SendMessage, 0x1000,,,, ahk_id %Reciever%
    Return, 1
}

VerifyInputs() {
    Global _181, _182, _177, _178
    GuiControlGet, Dbc,, Dbc
    If (Dbc = "") {
        GuiControl, Focus, Dbc
        ShakeControl("Dbc")
        Return, 0
    }
    GuiControlGet, Dnm,, Dnm
    If (Dnm = "") {
        GuiControl, Focus, Dnm
        ShakeControl("Dnm")
        Return, 0
    }
    If InStr(Dnm, ";") {
        GuiControl, Focus, Dnm
        ShakeControl("Dnm")
        Return, 0
    }
    GuiControlGet, Dbp,, Dbp
    If (Dbp = "") {
        GuiControl, Focus, Dbp
        ShakeControl("Dbp")
        Return, 0
    }
    GuiControlGet, Dsp,, Dsp
    If (Dsp = "") {
        GuiControl, Focus, Dsp
        ShakeControl("Dsp")
        Return, 0
    }
    GuiControlGet, Dst,, Dst
    If (Dst = "") {
        GuiControl, Focus, Dst
        ShakeControl("Dst")
        Return, 0
    }
    Return, 1
}

ShakeControl(Ctrl) {
    GuiControlGet, Pos, Pos, % Ctrl
    Loop, 5 {
        GuiControl, Move, % Ctrl, % "x" PosX -= 4
        Sleep, 50
        GuiControl, Move, % Ctrl, % "x" PosX += 4
        Sleep, 50
    }
}