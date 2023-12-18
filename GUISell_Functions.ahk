ConvertMillimsToDT(Value, Sign := "") {
    If (Value = "..." || !Value)
        Return
    ValueArr := StrSplit(Value / 1000, ".")
    Return, "[" (Sign ? Sign " " : "") ValueArr[1] (ValueArr[2] ? "." RTrim(ValueArr[2], 0) : "") " DT]"
}

RestoreSession() {
    Global Session
    If LV_GetCount() {
        LV_Delete()
        GuiControl, Disabled, AddUp
        GuiControl, Disabled, AddDown
        GuiControl, Disabled, AddSell
        GuiControl, Disabled, AddDelete
    }

    If FileExist("Dump\" Session ".session") {
        Obj := FileOpen("Dump\" Session ".session", "r")
        While !Obj.AtEOF() {
            Line := Trim(Obj.ReadLine(), "`n")
            Col := StrSplit(Line, ",")
            LV_Add(, Col[1], Col[2], Col[3], Col[4], Col[5])
        }
        Obj.Close()
        If LV_GetCount() {
            GuiControl, Enabled, AddUp
            GuiControl, Enabled, AddDown
            GuiControl, Enabled, AddSell
            GuiControl, Enabled, AddDelete
        }
    }
    GuiControl, Focus, Bc
}

WriteSession() {
    Global Session
    Obj := FileOpen("Dump\" Session ".session", "w")
    Loop, % LV_GetCount() {
        LV_GetText(Col1, A_Index, 1)
        LV_GetText(Col2, A_Index, 2)
        LV_GetText(Col3, A_Index, 3)
        LV_GetText(Col4, A_Index, 4)
        LV_GetText(Col5, A_Index, 5)
        Obj.WriteLine(Col1 "," Col2 "," Col3 "," Col4 "," Col5)
    }
    Obj.Close()
}

SetExplorerTheme(HCTL) {
    If (DllCall("GetVersion", "UChar") > 5) {
        VarSetCapacity(ClassName, 1024, 0)
        If DllCall("GetClassName", "Ptr", HCTL, "Str", ClassName, "Int", 512, "Int") {
            Return !DllCall("UxTheme.dll\SetWindowTheme", "Ptr", HCTL, "WStr", "Explorer", "Ptr", 0)
        }
    }
    Return False
}

LoadDefinitions() {
    Definitions := {}
    Loop, Files, Sets\Def\*.Def, R
    {
        FileRead, Content, % A_LoopFileFullPath
        Content := StrSplit(Content, ";")
        Definitions["" StrReplace(A_LoopFileName, ".def") ""] := { "Name" : Content[1]
            , "BuyPrice" : Content[2]
            , "SellPrice" : Content[3]
        , "Quantity" : Content[4] }
    }
    Return, Definitions
}

CalculateSum() {
    Global AdditionalInfo
    CharSum := 0
    Loop, % LV_GetCount() {
        LV_GetText(ThisCharSum, A_Index, 5)
        CharSum += ThisCharSum
    }
    If (CharSum) {
        GuiControlGet, Remise, , Remise
        CharSumRemise := CharSum
        If (Remise) && (AdditionalInfo) {
            CharSumRemise -= Round(Remise / 100 * CharSum)
        }
        GuiControl, , ThisListSum, % CharSumRemise " " ConvertMillimsToDT(CharSumRemise)
        GuiControl, , AllSum, % CharSumRemise
    } Else {
        GuiControl, , ThisListSum
    }
}

CartView() {
    Global Selling
    Selling := 0
    GuiControl, , AllSum
    GuiControl, , Change
    GuiControl, , GivenMoney
    GuiControl, Hide, GivenMoney
    GuiControl, Hide, AllSum
    GuiControl, Hide, Change
    GuiControl, Show, Bc
    GuiControl, Show, AddEnter
    GuiControl, Show, Nm
    GuiControl, Show, Qn
    GuiControl, Show, Sum
    LV_Delete()
    GuiControl, Focus, Bc
}

SellView() {
    Global Selling
    Selling := 1
    GuiControl, Hide, Bc
    GuiControl, Hide, AddEnter
    GuiControl, Hide, Nm
    GuiControl, Hide, Qn
    GuiControl, Hide, Sum
    GuiControl, Show, GivenMoney
    GuiControl, Show, AllSum
    GuiControl, Show, Change
    GuiControl, Focus, GivenMoney
}

TrancsView(Tranc, View) {
    Global _126, THCtrl, CountToHide := 1
    If (View) {
        GuiControl, Show, Transc
        GuiControl, Show, TranscOK
        If (Tranc) {
            FormatTime, Now, % A_Now, yyyy/MM/dd 'at' HH:mm:ss
            CtlColors.Change(THCtrl, "008000", "FFFFFF")
            GuiControl, , Transc, % Now
            GuiControl, , TranscOK, Img\OK.png
            SetTimer, TranscHide, 1000
        } Else {
            CtlColors.Change(THCtrl, "CCCCCC")
            GuiControl, , Transc
            GuiControl, , TranscOK, Img\Idle.png
        }
    } Else {
        GuiControl, Hide, Transc
        GuiControl, Hide, TranscOK
    }
}

CheckLatestSells() {
    Global ProdDefs, SearchList := []
    GuiControl,, Search, |
    If FileExist("Dump\Last.sell") {
        Loop, Read, Dump\Last.sell
        {
            If (ProdDefs["" Trim(A_LoopReadLine, "`n") ""] != "") {
                GuiControl,, Search, % " -- " ProdDefs["" Trim(A_LoopReadLine, "`n") ""]["Name"] " -- "
                SearchList.Push("" A_LoopReadLine "")
            }
        }
    }
}

CalculateCurrent() {
    Global _37
    S := B := P := I := 0
    Loop, Files, Curr\*.sell
    {
        FileRead, Content, % A_LoopFileFullPath
        Content := StrSplit(StrSplit(Content, "> ")[2], "|")
        For Each, One in Content {
            F := StrSplit(One, ";")
            I += StrSplit(F[3], "x")[2]
            S += F[4]
            B += F[6]
            P += F[7]
        }
    }

    GuiControl,, ItemsSold, % I " " _37
    GuiControl,, SoldP, % S "`n" ConvertMillimsToDT(S)
    GuiControl,, CostP, % B "`n" ConvertMillimsToDT(B)
    GuiControl,, ProfitP, % P "`n" ConvertMillimsToDT(P)

    Return, [I, S, B, P]
}

LogIn(Username, Password) {
    If (FileExist("Sets\Acc.chu")) {
        Account := {}
        FileRead, RawAccount, Sets\Acc.chu
        TextAccount := b64Decode(RawAccount)

        For Each, User in StrSplit(TextAccount, ",") {
            LOG := StrSplit(User, "|")
            Account[LOG[1]] := [LOG[2], LOG[3], LOG[4]]
        }

        If (Account[Username][1] = Password) {
            If (Account[Username][3]) {
                UserPic := Account[Username][3]
            }
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

GUISellHistory(Text) {
    FormatTime, OutTime, % A_Now, yyyy/MM/dd HH:mm:ss
    Obj := FileOpen("Hist\SellHistory.Hist", "a")
    Obj.WriteLine(OutTime " ==> " Text)
    Obj.Close()
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

Message() {
    Global ProdDefs
    FileRead, Message, Sets\Message.Request
    If (Message = "Update_Definitions") {
        ProdDefs := LoadDefinitions()
    }
}

SetEditCueBanner(HWND, Cue) {
    Static EM_SETCUEBANNER := (0x1500 + 1)
    Return DllCall("User32.dll\SendMessageW", "Ptr", HWND, "Uint", EM_SETCUEBANNER, "Ptr", True, "WStr", Cue)
}

InsertLineAtStart(File, Text) {
    rText := FileOpen("Dump\Last.sell", "r").Read(5000)
    FileOpen("Dump\Last.sell", "w").Write(Text "`n" rText).Close()
}
