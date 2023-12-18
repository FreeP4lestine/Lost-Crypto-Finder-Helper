#If WinActive("ahk_id " Main)
    Enter::
        If !VerifyInputs()
            Return
        If (!EditModOn) {
            Add()
            Return
        }
        If Modify() {
            EditModOn := 0
        }
    Return

    Delete::
        If (Row := LV_GetNext()) {
            LV_GetText(Bc, Row, 1)
            LV_GetText(St, Row, 5)
            LV_GetText(Sp, Row, 4)
        
            LV_Delete(Row)

            ExistedDef := ""
            Loop, Files, % "Sets\Def\" Bc ".def", R
            {
                ExistedDef := A_LoopFileFullPath
            }

            If (ExistedDef != "")
                FileDelete, % ExistedDef

            GuiControlGet, StockSum
            StockSum -= Trim(St, "[]") * Sp
            GuiControl,, StockSum, % StockSum " " ConvertMillimsToDT(StockSum)

            EditModOn := 0
        }
    Return

    Esc::
        GuiControl,, Dbc
        GuiControl,, Dnm
        GuiControl,, Dbp
        GuiControl,, Dsp
        GuiControl,, Dst
        EditModOn := 0
        GuiControl, Focus, Dbc
        LoadProducts()
    Return
    
    ^!LButton::
        MouseClick
        GoSub, FillForms
    Return
    
    ^F::
        GuiControlGet, Group,, Group
        GuiControlGet, Dbc,, Dbc
        GuiControlGet, Dnm,, Dnm
        GuiControlGet, Dbp,, Dbp
        GuiControlGet, Dsp,, Dsp
        GuiControlGet, Dst,, Dst
        If (Group = "ALL") {
            If (Dbc != "") || (Dnm != "") || (Dst != "") || (Dbp != "") || (Dsp != "") {
                LV_Delete()
                Loop, Files, Sets\Def\*.def, R
                {
                    FileRead, Content, % A_LoopFileFullPath
                    Content := StrSplit(Content, ";")
                    If InStr(StrReplace(A_LoopFileName, ".def"), Dbc) && InStr(Content[1], Dnm) && InStr(Content[2], Dbp) && InStr(Content[3], Dsp) && InStr(Content[4], Dst) {
                        LV_Add(, StrReplace(A_LoopFileName, ".def"), Content[1], Content[2], Content[3], "[" (Content[4] != "" ? Content[4] : 0) "]")
                    }
                }
            }
        } Else {
            If (Dbc != "") || (Dnm != "") || (Dst != "") || (Dbp != "") || (Dsp != "") {
                LV_Delete()
                Loop, Files, Sets\Def\%Group%\*.def
                {
                    FileRead, Content, % A_LoopFileFullPath
                    Content := StrSplit(Content, ";")
                    If InStr(StrReplace(A_LoopFileName, ".def"), Dbc) && InStr(Content[1], Dnm) && InStr(Content[2], Dbp) && InStr(Content[3], Dsp) && InStr(Content[4], Dst) {
                        LV_Add(, StrReplace(A_LoopFileName, ".def"), Content[1], Content[2], Content[3], "[" (Content[4] != "" ? Content[4] : 0) "]")
                    }
                }
            }
        }
    Return
#If