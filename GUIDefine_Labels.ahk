DelGroup:
    GuiControlGet, Group,, Group
    If (Group != "ALL") {
        Msgbox, 36,% _187, % _194 " " Group " ?"
        IfMsgBox, Yes
        {
            Msgbox, 36,% _187, % _174
            IfMsgBox, Yes
            {
                FileRemoveDir, % "Sets\Def\" Group, 1
                LoadGroups()
            }
        }
    }
Return

FillForms:
    If (Row := LV_GetNext()) {
        LV_GetText(Dbc, Row, 1)
        LV_GetText(Dnm, Row, 2)
        LV_GetText(Dbp, Row, 3)
        LV_GetText(Dsp, Row, 4)
        LV_GetText(Dst, Row, 5)

        GuiControl,, Dbc, % Dbc
        GuiControl,, Dnm, % Dnm
        GuiControl,, Dbp, % Dbp
        GuiControl,, Dsp, % Dsp
        GuiControl,, Dst, % Trim(Dst, "[]")
    }
Return

AddGroup:
    InputBox, Groupname, % _184, % _185,, 300, 130
    If !InStr(FileExist("Sets\Def\" Groupname), "D") && (Groupname != "ALL") {
        FileCreateDir, % "Sets\Def\" Groupname
        If (!ErrorLevel) {
            GuiControl,, Group, % Groupname
        }
    }
    Groupname   := Groupname = "ALL" ? "" : Groupname "\"
    Row         := 0
    While (Row := LV_GetNext(Row)) {
        LV_GetText(Bc, Row, 1)
        Loop, Files, % "Sets\Def\" Bc ".def", R
            Src := A_LoopFileFullPath
        FileMove, % Src, % "Sets\Def\" Groupname Bc ".def"
    }
    GuiControl, ChooseString, Group, % "|" (Groupname = "" ? "ALL" : SubStr(Groupname, 1, -1))
Return

ResetAll:
    GuiControlGet, Group,, Group
    If (Group = "ALL") {
        Loop, Files, Sets\Def\*.def, R
        {
            FileRead, Content, % A_LoopFileFullPath
            Content := StrSplit(Content, ";")
            FileOpen(A_LoopFileFullPath, "w").Write(Content[1] ";" Content[2] ";" Content[3] ";0").Close()
        }
        StockSum := LoadProducts()
    } Else {
        Loop, Files, Sets\Def\%Group%\*.def
        {
            FileRead, Content, % A_LoopFileFullPath
            Content := StrSplit(Content, ";")
            FileOpen(A_LoopFileFullPath, "w").Write(Content[1] ";" Content[2] ";" Content[3] ";0").Close()
        }
        GoSub, DisplayGroup
    }
    
Return

DisplayGroup:
    GuiControlGet, Group,, Group
    GuiControl,, StockSum
    If (GROUP != "ALL") {
        LV_Delete(), Files := ""
        Loop, Files, % "Sets\Def\" Group "\*.def"
        {
            Bc := StrReplace(A_LoopFileName, ".def")
            Files .= Files != "" ? "`n" Bc : Bc
        }
    
        Sort, Files, N
        StockSum := 0
        
        Loop, Parse, Files, `n
        {
            FileRead, Content, % "Sets\Def\" Group "\" A_LoopField ".def"
            Content := StrSplit(Content, ";"), Content[4] != "" ? StockSum += Content[4] * Content[3] : 0
            LV_Add(, A_LoopField, Content[1], Content[2], Content[3], "[" (Content[4] != "" ? Content[4] : 0) "]")
            GuiControl,, StockSum, % StockSum " " ConvertMillimsToDT(StockSum)
        }
    } Else {
        StockSum := LoadProducts()
    }
Return

Edit:
    If (Row := LV_GetNext()) {
        LV_GetText(Dbc, Row, 1)
        LV_GetText(Dnm, Row, 2)
        LV_GetText(Dbp, Row, 3)
        LV_GetText(Dsp, Row, 4)
        LV_GetText(Dst, Row, 5)

        GuiControl,, Dbc, % Dbc
        GuiControl,, Dnm, % Dnm
        GuiControl,, Dbp, % Dbp
        GuiControl,, Dsp, % Dsp
        GuiControl,, Dst, % Trim(Dst, "[]")

        EditModOn := 1
    }
Return

GuiClose:
    IniDelete, Sets\PID.ini, PID, GUIDefine
ExitApp