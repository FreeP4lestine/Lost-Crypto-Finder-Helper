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

ThemeAdd() {
    Loop, 5 {
        Gui, Add, Text, % "y0 x" 208 + A_Index * 2 " w1 h" A_ScreenHeight " HwndHCtrl"
        CtlColors.Attach(HCtrl, "7D7D64")
    }
}

ConvertMillimsToDT(Value, Sign := "") {
    If (Value = "..." || !Value)
        Return
    ValueArr := StrSplit(Value / 1000, ".")
    Return, "[" (Sign ? Sign " " : "") ValueArr[1] (ValueArr[2] ? "." RTrim(ValueArr[2], 0) : "") " DT]"
}

LoadKridis(ChooseName := "") {
    GuiControl,, KLB, |
    GuiControl,, SelectFromLv, |
    LV_Delete()

    GuiControl,, SubThisKridi
    GuiControl,, ThisKridi
    GuiControl,, AllKridi
    GuiControl,, ThisPay
    GuiControl,, PayBack
    GuiControl,, Pay
    GuiControl,, PDate
    GuiControl,, Balance
    
    AK := 0
    Loop, Files, Kr\*, D
    {
        Name := A_LoopFileName
        Loop, Files, % "Kr\" Name "\*.sell"
        {
            FileRead, Content, % A_LoopFileFullPath
            AK += StrSplit(StrSplit(Content, "> ")[3], ";")[1]
        }
        GuiControl,, KLB, % Name
        GuiControl,, AllKridi, % AK "`n" ConvertMillimsToDT(AK)
    }
    
    If (ChooseName = "")
        GuiControl, Choose, KLB, |1
    Else {
        GuiControl, ChooseString, KLB, |%ChooseName%
    }
}

KridiDates(KLB) {
    LV_Delete()
    GuiControl,, KDate, |

    DateRow := {}, ItemSum := {}, I := 0, TK := 0
    Loop, Files, % "Kr\" KLB "\*.sell"
    {
        FileRead, Content, % A_LoopFileFullPath
        Content := StrSplit(Content, "> ")
        Date    := StrSplit(Content[1], "|")[2]
        
        DateRow[++I]  := []
        ItemSum[I]    := StrSplit(Content[3], ";")[1]
        TK      += ItemSum[I]
        
        GuiControl,, ThisKridi, % TK "`n" ConvertMillimsToDT(TK)
        GuiControl,, KDate, % Date
        
        Sells   := StrSplit(Trim(Content[2], "|"), "|")
        
        For Every, Sell in Sells {
            SubSell := StrSplit(Sell, ";")
            Row := LV_Add(, SubSell[1], SubSell[2], SubSell[3], SubSell[4])
            DateRow[I].Push(Row)
        }
    }
    GuiControl,, SubThisKridi
    Return, [DateRow, ItemSum, TK]
}

PayDates(KLB) {
    P := 0, PayVal := {}
    GuiControl,, PDate, |
    GuiControl,, Pay
    GuiControl,, ThisPay
    Loop, Files, % "Kr\" KLB "\*.pay"
    {
        FileRead, Content, % A_LoopFileFullPath
        P               += Content
        PayVal[A_Index] := Content
        
        GuiControl,, Pay, % P "`n" ConvertMillimsToDT(P)
        
        FormatTime, oTime, % StrReplace(A_LoopFileName, ".pay"), yyyy/MM/dd HH:mm:ss
        GuiControl,, PDate, % oTime
    }
    Return, [PayVal, P]
}