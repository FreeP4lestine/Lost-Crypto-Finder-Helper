#If WinActive("ahk_id " Main)
    Enter::
        GuiControlGet, Bc, , Bc
        GuiControl, Disabled, Bc
        If (!Selling) {
            Barcode := Bc
            If (ProdDefs["" Barcode ""]["Name"] != "")
            && (ProdDefs["" Barcode ""]["SellPrice"] != "") 
            && (ProdDefs["" Barcode ""]["Quantity"] != "") {
                Nm                  := ProdDefs["" Barcode ""]["Name"]
                SellPrice           := ProdDefs["" Barcode ""]["SellPrice"]
                ThisCurrQuantity    := ProdDefs["" Barcode ""]["Quantity"] ? ProdDefs["" Barcode ""]["Quantity"] : 0
                QuantitySumArg      := SellPrice "x1"

                JobDone             := 0
                Loop, % LV_GetCount() {
                    LV_GetText(ThisBc, Row := A_Index, 1)
                    If (ThisBc = Barcode) {
                        LV_GetText(AddedCurrQuantity, Row, 2), AddedCurrQuantity := StrSplit(AddedCurrQuantity, "  >>  ")
                        LV_GetText(AddedQuantitySumArg, Row, 4), AddedQuantitySumArg := StrSplit(AddedQuantitySumArg, "x"), QuantitySumArg := AddedQuantitySumArg[1] "x" AddedQuantitySumArg[2] + 1
                        LV_GetText(PreviousSum, Row, 5)
                        SellPrice := ProdDefs["" Barcode ""]["SellPrice"]
                        LV_Modify(Row,,, AddedCurrQuantity[1] "  >>  " AddedCurrQuantity[2] - 1,, QuantitySumArg, PreviousSum + SellPrice)
                        JobDone := 1
                        Break
                    }
                }
                If (!JobDone) {
                    LV_Add("", Barcode, ThisCurrQuantity "  >>  " ThisCurrQuantity - 1, Nm, QuantitySumArg, SellPrice)
                }
                CalculateSum()
                WriteSession()
                GuiControl, Enabled, AddUp
                GuiControl, Enabled, AddDown
                GuiControl, Enabled, AddSell
                GuiControl, Enabled, AddDelete
            }
        } Else {
            FormatTime, OutTime, % (Now := A_Now), yyyy/MM/dd HH:mm:ss
            SellOBJ := FileOpen(LastestSO := "Curr\" Now ".sell", "w")
            SellOBJ.Write(AdminName "|" OutTime)
            
            I := Sum := Cost := 0
            Loop, % LV_GetCount() {
                LV_GetText(Bc, A_Index, 1)
                LV_GetText(Qn, A_Index, 4)
                Qn := StrSplit(Qn, "x")[2]

                If (!Qn) || (!Bc) {
                    MsgBox, 16, % _13, % _160 "`nRow: " A_Index
                    Continue
                }

                ProdDefs["" Bc ""]["Quantity"] -= Qn

                FileRead, Content, % "Sets\Def\" Bc ".def"
                Content := StrSplit(Content, ";")

                DefObj := FileOpen("Sets\Def\" Bc ".def", "w")
                DefObj.Write(Content[1] ";" Content[2] ";" Content[3] ";" Content[4] - Qn)
                DefObj.Close()

                Name    := ProdDefs["" Bc ""]["Name"]
                SellStr := ProdDefs["" Bc ""]["SellPrice"] "x" Qn
                Sell    := ProdDefs["" Bc ""]["SellPrice"] * Qn
                Sum     += Sell
                BuyStr  := ProdDefs["" Bc ""]["BuyPrice"] "x" Qn
                Buy     := ProdDefs["" Bc ""]["BuyPrice"] * Qn

                Cost += Buy
                SellOBJ.Write(((A_Index > 1) ? "|" : "> ") Bc ";" Name ";" SellStr ";" Sell ";" BuyStr ";" Buy ";" Sell - Buy)

                I += Qn
                InsertLineAtStart("Dump\Last.sell", Bc)
            }
            
            SellOBJ.Write("> " Sum ";" Cost ";" Sum - Cost)
            SellOBJ.Close()
            
            If FileExist("Dump\Kridi.sell") {
                FileRead, Content, Dump\Kridi.sell
                If !InStr(FileExist("Kr\" Content), "D") {
                    FileCreateDir, % "Kr\" Content
                }
                FileMove, % LastestSO, % "Kr\" Content
                FileDelete, % "Dump\Kridi.sell"
                LastestSO := StrReplace(LastestSO, "Curr\", "Kr\" Content "\")
            }
            
            Selling := 0
            GuiControl, Disabled, AddEnter
            GuiControl, Disabled, AddUp
            GuiControl, Disabled, AddDown
            GuiControl, Disabled, AddSell
            GuiControl, Disabled, AddSubmit
            If (Level = 1)
                GuiControl, Disabled, SubKridi
            GuiControl, Disabled, AddDelete
            GuiControl, Disabled, Cancel
            
            GuiControl,, AllSum
            GuiControl,, Change
            GuiControl,, GivenMoney
            GuiControl, Hide, GivenMoney
            GuiControl, Hide, AllSum
            GuiControl, Hide, Change
            
            GuiControl, Show, Bc
            GuiControl, Show, AddEnter
            GuiControl, Show, Nm
            GuiControl, Show, Qn
            GuiControl, Show, Sum
            LV_Delete()
            
            WriteSession()
            CalculateSum()
            TrancsView(1, 1)
            CheckLatestSells()
            
            CurrentProfit[1] += I
            CurrentProfit[2] += Sum
            CurrentProfit[3] += Cost
            CurrentProfit[4] += Sum - Cost

            GuiControl,, ItemsSold, % (CurrentProfit[1]) " " _37
            GuiControl,, SoldP,     % (CurrentProfit[2]) "`n" ConvertMillimsToDT(CurrentProfit[2])
            GuiControl,, CostP,     % (CurrentProfit[3]) "`n" ConvertMillimsToDT(CurrentProfit[3])
            GuiControl,, ProfitP,   % (CurrentProfit[4]) "`n" ConvertMillimsToDT(CurrentProfit[4])
        }
        GuiControl, Enabled, Bc
        GuiControl, , Bc
        GuiControl, Focus, Bc
        Sleep, 125
    Return

    Space::
        GuiControlGet, FocusedControl, FocusV
        If (FocusedControl ~= "Client|SellDesc") {
            SendInput, {Space}
        } Else {
            If LV_GetCount() {
                SellView()
                AllSum := 0
                Loop, % LV_GetCount() {
                    LV_GetText(ThisAllSum, A_Index, 5)
                    AllSum += ThisAllSum
                }
                GuiControl, , AllSum, % AllSum
                GuiControl, Disabled, AddUp
                GuiControl, Disabled, AddDown
                GuiControl, Disabled, AddDelete
                GuiControl, Disabled, AddSell
                If (Level = 1)
                    GuiControl, Enabled, SubKridi
                GuiControl, Enabled, AddSubmit
                GuiControl, Enabled, Cancel
                GuiControl, Focus, GivenMoney
                CalculateSum()
                Selling := 1
            } Else {
                GuiControl, Focus, Bc
            }
        }
        Sleep, 125
    Return

    Left::
        If !(--Session) {
            Session += 10
        }

        Loop, 10 {
            If (A_Index = Session) {
                GuiControl, Disabled, Session%A_Index%
            } Else {
                GuiControl, Enabled, Session%A_Index%
            }
        }

        RestoreSession()
        CalculateSum()
        Sleep, 125
    Return

    Right::
        If (++Session = 11) {
            Session -= 10
        }

        Loop, 10 {
            If (A_Index = Session) {
                GuiControl, Disabled, Session%A_Index%
            } Else {
                GuiControl, Enabled, Session%A_Index%
            }
        }

        RestoreSession()
        CalculateSum()
        Sleep, 125
    Return

    Up::
        If (Row := LV_GetNext()) {
            LV_GetText(ThisQn, Row, 4)
            LV_GetText(ThisBc, Row, 1)
            VQ := StrSplit(ThisQn, "x")
            LV_Modify(Row,,, ProdDefs["" ThisBc ""]["Quantity"] "  >>  " ProdDefs["" ThisBc ""]["Quantity"] - (VQ[2] + 1),, VQ[1] "x" VQ[2] + 1, VQ[1] * (VQ[2] + 1))
        } Else If (Row := LV_GetCount()) {
            LV_GetText(ThisQn, Row, 4)
            LV_GetText(ThisBc, Row, 1)
            VQ := StrSplit(ThisQn, "x")
            LV_Modify(Row,,, ProdDefs["" ThisBc ""]["Quantity"] "  >>  " ProdDefs["" ThisBc ""]["Quantity"] - (VQ[2] + 1),, VQ[1] "x" VQ[2] + 1, VQ[1] * (VQ[2] + 1))
        }
        CalculateSum()
        WriteSession()
        Sleep, 125
    Return

    Down::
        GuiControlGet, Focused, FocusV
        If (Row := LV_GetNext()) {
            LV_GetText(ThisQn, Row, 4)
            LV_GetText(ThisBc, Row, 1)
            VQ := StrSplit(ThisQn, "x")
            If (VQ[2] > 1) {
                LV_Modify(Row,,, ProdDefs["" ThisBc ""]["Quantity"] "  >>  " ProdDefs["" ThisBc ""]["Quantity"] - (VQ[2] - 1),, VQ[1] "x" VQ[2] - 1, VQ[1] * (VQ[2] - 1))
            }
        } Else If (Row := LV_GetCount()) {
            LV_GetText(ThisQn, Row, 4)
            LV_GetText(ThisBc, Row, 1)
            VQ := StrSplit(ThisQn, "x")
            If (VQ[2] > 1) {
                LV_Modify(Row,,, ProdDefs["" ThisBc ""]["Quantity"] "  >>  " ProdDefs["" ThisBc ""]["Quantity"] - (VQ[2] - 1),, VQ[1] "x" VQ[2] - 1, VQ[1] * (VQ[2] - 1))
            }
        }
        CalculateSum()
        WriteSession()
        Sleep, 125
    Return

    Delete::
        If (LV_GetCount()) {
            If (Row := LV_GetNext()) {
                LV_Delete(Row)
                CalculateSum()
            } Else {
                LV_Delete(1)
                CalculateSum()
            }
            If (!LV_GetCount()) {
                GuiControl, Disabled, AddEnter
                GuiControl, Disabled, AddUp
                GuiControl, Disabled, AddDown
                GuiControl, Disabled, AddSell
                GuiControl, Disabled, AddSubmit
                GuiControl, Disabled, SubKridi
                GuiControl, Disabled, AddDelete
                GuiControl, Disabled, Cancel
                LV_Delete()
                GuiControl, Focus, Bc
            }
        }
        WriteSession()
        Sleep, 125
    Return

    Esc::
        If (Selling) {
            Selling := 0
            
            GuiControl, Disabled, AddEnter
            GuiControl, Disabled, AddUp
            GuiControl, Disabled, AddDown
            GuiControl, Disabled, AddSell
            GuiControl, Disabled, AddSubmit
            GuiControl, Disabled, SubKridi
            GuiControl, Disabled, AddDelete
            GuiControl, Disabled, Cancel
            
            GuiControl,, AllSum
            GuiControl,, Change
            GuiControl,, GivenMoney
            GuiControl, Hide, GivenMoney
            GuiControl, Hide, AllSum
            GuiControl, Hide, Change

            GuiControl,, Bc
            GuiControl, Show, Bc
            GuiControl, Show, AddEnter
            GuiControl, Show, Nm
            GuiControl, Show, Qn
            GuiControl, Show, Sum
            ;LV_Delete()
            GuiControl, Focus, Bc
            WriteSession()
            CalculateSum()
        }
        CheckLatestSells()
        Sleep, 125
    Return

    ^F::
        GuiControlGet, Bc,, Bc
        GuiControl,, Search, |
        SearchList := []
        For Every, Product in ProdDefs {
            If InStr(Product["Name"], Bc) {
                SearchList.Push("" Every "")
                GuiControl, , Search, % Product["Name"]
            }
        }
        Sleep, 125
    Return

    Tab::
        If (Level = 1) {
            GuiControlGet, Visi, Visible, ItemsSold
            Action := (Visi) ? "Hide" : "Show"

            GuiControl, % Action, ItemsSold
            GuiControl, % Action, SoldP
            GuiControl, % Action, CostP
            GuiControl, % Action, ProfitP
        } Else {
            SendInput, {Tab}
        }
        Sleep, 125
    Return
#If