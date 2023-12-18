ThemeAdd() {
    Loop, 5 {
        Gui, Add, Text, % "y0 x" 208 + A_Index * 2 " w1 h" A_ScreenHeight " HwndHCtrl"
        CtlColors.Attach(HCtrl, "7D7D64")
    }
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

ConvertMillimsToDT(Value, Sign := "") {
    If (Value = "..." || !Value)
        Return
    ValueArr := StrSplit(Value / 1000, ".")
    Return, "[" (Sign ? Sign " " : "") ValueArr[1] (ValueArr[2] ? "." RTrim(ValueArr[2], 0) : "") " DT]"
}

AddToList(File, DataSum) {
    FileRead, Content, % File
    SplitPath, % File, OutFileName
    Date := SubStr(OutFileName, 1, 8)
    DataAll  := StrSplit(Content, "> ")

    DateUser := StrSplit(DataAll[1], "|")
    If (DateUser.Length() = 2) && !LVContent["Users"].HasKey("" DateUser[1] "") {
        LVContent["Users"]["" DateUser[1] ""] := ""
    }

    Data     := StrSplit(DataAll[3], ";")
    If (Data[1] Data[2] Data[3] ~= "\b\d+\b") {
        Names := "", Items := {}
        For Each, Prod in StrSplit(Trim(DataAll[2], "|"), "|") {
            Info := StrSplit(Prod, ";")
            If !Items.HasKey("" Info[1] "") {
                Items["" Info[1] ""] := [Info[2], 0, 0, 0, 0]
            }
            Items["" Info[1] ""][2] += StrSplit(Info[3], "x")[2]
            Items["" Info[1] ""][3] += Info[4]
            Items["" Info[1] ""][4] += Info[6]
            Items["" Info[1] ""][5] += Info[7]
            Names .= Names ? " | " Info[2] : Info[2]
        }

        C1 := ["" Date "", File]
        C2 := DateUser
        C3 := "+ " Data[1] " " ConvertMillimsToDT(Data[1], "+")
        C4 := "- " Data[2] " " ConvertMillimsToDT(Data[2], "+")
        C5 := "+ " Data[3] " " ConvertMillimsToDT(Data[3], "+")
        C6 := Names
        C7 := Items
        C8 := Data

        LVContent["Lines"].Push([C1, C2, C3, C4, C5, C6, C7, C8])
        If !LVContent["Dates"].HasKey("" Date "") {
            LVContent["Dates"]["" Date ""] := ""
        }
    }
}

LoadAllSells() {
    DataSum     := [0, 0, 0]
    LVContent   := { "Lines"  : []
                   , "Users"  : {}
                   , "Dates"  : {} }

    GuiControl,, Sold
    GuiControl,, Bought
    GuiControl,, ProfitEq
    Loop, Files, Curr\*.sell, R
        DataSum := AddToList(A_LoopFileFullPath, DataSum)
}

AnalyzeUsers() {
    Global _74
    GuiControl,, ProfByName, |
    GuiControl,, ProfByName, % _74
    For User in LVContent["Users"] {
        GuiControl,, ProfByName, % User
    }
    GuiControl, Choose, ProfByName, 1
}

AnalyzeDates() {
    GuiControl,, Dates, |
    For Date in LVContent["Dates"] {
        FormatTime, ThisDay, % Date, yyyy/MM/dd
        GuiControl,, Dates, % "-- " ThisDay " --"
    }
}

UpdateHeaders() {
    Global
    LV_Delete()
    If (ProfByProduct = 1) && (Header = 2) {
        For Each, Title in [[_70, 0], [_71, qw], [_39, 0], [_40, 0], [_41, 0], [_79, qw]]
            LV_ModifyCol(Each, Title[2], Title[1])
        Header := 1
    } 
    If (ProfByProduct = 2) && (Header = 1) {
        For Each, Title in [[_63, sqw := qw / 3], [_38, sqw], [_68, sqw, " Integer Left"], [_39, sqw, " Integer Left"], [_40, sqw, " Integer Left"], [_41, sqw, " Integer Left"]]
            LV_ModifyCol(Each, Title[2] Title[3], Title[1])
        Header := 2
    }
}

UpdateSumValues(DataSum) {
    GuiControl,, Sold, % "+ " DataSum[1] " " ConvertMillimsToDT(DataSum[1], "+")
    GuiControl,, Bought, % "- " DataSum[2] " " ConvertMillimsToDT(DataSum[2], "-")
    GuiControl,, ProfitEq, % "+ " DataSum[3] " " ConvertMillimsToDT(DataSum[3], "+")
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