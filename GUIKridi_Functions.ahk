LoadKridiUsers() {
    GuiControl, , KLB, |
    Loop, Files, % "Kr\*", D
        GuiControl,, KLB, % A_LoopFileName

    TotalValue := 0
    Obj := FileOpen("Dump\tmp.sell", "r")
    While !Obj.AtEOF() {
        Line := Obj.ReadLine()
        Col     := StrSplit(Line, ",")
        LV_Add(, Col[1], Col[2], Col[3], Col[4], Col[5])
        TotalValue += Col[5]
    }
    Obj.Close()
    GuiControl,, Total, % "+" TotalValue " " ConvertMillimsToDT(TotalValue, "+")
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

ConvertMillimsToDT(Value, Sign := "") {
    If (Value = "..." || !Value)
        Return
    ValueArr := StrSplit(Value / 1000, ".")
    Return, "(" (Sign ? " " Sign " " : "") ValueArr[1] (ValueArr[2] ? "." RTrim(ValueArr[2], 0) : "") " DT)"
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