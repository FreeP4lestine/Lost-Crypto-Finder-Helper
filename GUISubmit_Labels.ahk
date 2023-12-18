Valid:
    MsgBox, 33, % _174, % _175
    IfMsgBox, OK
    {
        FileCreateDir, % "Valid\" (Now := A_Now)
        Loop, % LV_GetCount() {
            LV_GetText(File, A_Index, 1)
            FileMove, % File, % "Valid\" Now
        }
        LoadAllSells()
        AnalyzeUsers()
        AnalyzeDates()
    }
Return

Chart:
    GuiControl, Disabled, Chart
    GuiControlGet, ProfByProduct,, ProfByProduct
    If (ProfByProduct = 1){
        If (RowCount := LV_GetCount()) {
            Dummy := {}
            Loop, % RowCount {
                LV_GetText(F, A_Index, 1)
                LV_GetText(S, A_Index, 3)
                LV_GetText(B, A_Index, 4)
                LV_GetText(P, A_Index, 5)

                SplitPath, % F,,,, O

                RegExMatch(S, "\d+", S)
                RegExMatch(B, "\d+", B)
                RegExMatch(P, "\d+", P)

                If !Dummy.HasKey("" (O := SubStr(O, 1, 8)) "") {
                    Dummy["" O ""] := [0, 0, 0]
                }

                Dummy["" O ""][1] += S
                Dummy["" O ""][2] += B
                Dummy["" O ""][3] += P
            }

            Dates   := ""
            Sells   := ""
            Costs   := ""
            Profits := ""

            For Each, Date in Dummy {
                FormatTime, D, % Each, yyyy/MM/dd
                Dates   .= Dates   != ""  ? ",'"  D "'"    : "'" D "'"
                Sells   .= Sells   != ""  ? ","  Date[1]   : Date[1]
                Costs   .= Costs   != ""  ? ","  Date[2]   : Date[2]
                Profits .= Profits != ""  ? ","  Date[3]   : Date[3] 
            }
            Dates   := "[" Dates   "]"
            Sells   := "[" Sells   "]"
            Costs   := "[" Costs   "]"
            Profits := "[" Profits "]"

            FileCopy, HighChart\template\Chart.html, Template.html, 1
            FileCopy, HighChart\template\Chart.css, Template.css, 1
            FileCopy, HighChart\template\Chart.js, Template.js, 1

            FileRead, JS, Template.js

            JS := StrReplace(JS, "'[CASH_HELPER_DATES_HOLDER]'", Dates)
            JS := StrReplace(JS, "'[CASH_HELPER_SELLS_HOLDER]'", Sells)
            JS := StrReplace(JS, "'[CASH_HELPER_BUYS_HOLDER]'", Costs)
            JS := StrReplace(JS, "'[CASH_HELPER_PROFITS_HOLDER]'", Profits)

            FileOpen("Template.js"  , "w").Write(JS).Close()
            Run, Template.html
        }
    }
    GuiControl, Enabled, Chart
Return

ShowDetails:
    GuiControlGet, ProfByProduct,, ProfByProduct
    If !(Row := LV_GetNext()) || ProfByProduct = 2
        Return
    LV_GetText(FileName, Row, 1)
    Run, % "GUIDetails." (A_IsCompiled ? "exe" : "ahk") " " FileName
Return

ShowTheInfo:
    GuiControlGet, ProfByProduct,, ProfByProduct
    GuiControlGet, ProfByName,, ProfByName
    GuiControlGet, Dates,, Dates

    GuiControl,, Overview, % View[ProfByProduct] " | " ProfByName " | " Dates

    ProfByName := (ProfByName = _74) ? "" : ProfByName
    UpdateHeaders()

    DataSum := [0, 0, 0]
    Info    := {}
    If (ProfByProduct = 1) {
        For Each, Line in LVContent["Lines"] {
            FormatTime, ThisDay, % SubStr(Line[1][1], 1, 8), '--' yyyy/MM/dd '--'
            UName := (Line[2].Length() = 2) ? Line[2][1] : ""

            If InStr(Dates, ThisDay) && InStr(UName, ProfByName) {
                LV_Add(, Line[1][2], Line[2][1] (Line[2][2] ? " | " Line[2][2] : ""), Line[3], Line[4], Line[5], Line[6])
                DataSum[1] += Line[8][1]
                DataSum[2] += Line[8][2]
                DataSum[3] += Line[8][3]
                UpdateSumValues(DataSum)
            }
        }
    }

    If (ProfByProduct = 2) {
        For Each, Line in LVContent["Lines"] {
            FormatTime, ThisDay, % SubStr(Line[1][1], 1, 8), '--' yyyy/MM/dd '--'
            UName := (Line[2].Length() = 2) ? Line[2][1] : ""
            If InStr(Dates, ThisDay) && InStr(UName, ProfByName) {
                For Barcode, Detail in Line[7] {
                    If !Info.HasKey("" Barcode "") {
                        Info["" Barcode ""] := [LV_Add(, Barcode, Detail[1], Detail[2], Detail[3], Detail[4], Detail[5])
                                              , Detail[1]
                                              , Detail[2]
                                              , Detail[3]
                                              , Detail[4]
                                              , Detail[5]]
                    } Else {
                        Info["" Barcode ""][3] += Detail[2]
                        Info["" Barcode ""][4] += Detail[3]
                        Info["" Barcode ""][5] += Detail[4]
                        Info["" Barcode ""][6] += Detail[5]
                        LV_Modify(Info["" Barcode ""][1],,,, Info["" Barcode ""][3], Info["" Barcode ""][4], Info["" Barcode ""][5], Info["" Barcode ""][6])
                    }
                }
                DataSum[1] += Line[8][1]
                DataSum[2] += Line[8][2]
                DataSum[3] += Line[8][3]
                UpdateSumValues(DataSum)
            }
        }
    }
Return

GuiClose:
    IniDelete, Sets\PID.ini, PID, GUISubmit
ExitApp