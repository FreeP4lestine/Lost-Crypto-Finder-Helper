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

UpdateAccounts() {
    Data := ""
    For User, Info in UserList {
        Data .= Data != "" ? "," User "|" Info[1] "|" Info[2] (Info[3] != "" ? "|" Info[3] : "") : User "|" Info[1] "|" Info[2] (Info[3] != "" ? "|" Info[3] : "")
    }
    If (Data != "")
        FileOpen("Sets\Acc.chu", "w").Write(b64Encode(Data)).Close()
    Else {
        FileDelete, Sets\Acc.chu
        FileDelete, Sets\RAcc.chu
        FileRead, Reciever, Sets\Login.Hwnd
        FileOpen("Sets\Login.Request", "w").Write("Reload").Close()
        SendMessage, 0x1000,,,, ahk_id %Reciever%
        ExitApp
    }
}

LoadAccounts() {
    UserList := {}
    LV_Delete()
    If FileExist("Sets\Acc.chu") {
        FileRead, RawAccount, Sets\Acc.chu
        Account := b64Decode(RawAccount)
        For Every, Acc in StrSplit(Account, ",") {
            Info := StrSplit(Acc, "|")
            UserList[Info[1]] := [Info[2], Info[3], Info[4]]
            LV_Add(, Info[1], Info[2], Info[3])
        }
    }
}

NoAdminsLeft(Nm) {
    tmp := UserList
    tmp.Delete(Nm)
    For User, Info in tmp {
        If (Info[2] = "ADMIN") {
            Return, 0
        }
    }
    Return, 1
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