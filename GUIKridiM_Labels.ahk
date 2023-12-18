ShowKridiInfo:
    GuiControlGet, KLB,, KLB
    If (KLB) {
        DateRow := KridiDates(KLB)
        PayVal := PayDates(KLB)
        Ba := DateRow[3] - PayVal[2]
        GuiControl,, Balance, % KLB ": " Ba " " ConvertMillimsToDT(Ba)
    }
Return

PayOut:
    GuiControlGet, PayBack,, PayBack
    If (PayBack) {
        GuiControlGet, KLB,, KLB
        MsgBox, 36, % _187, % KLB " " _188 " " PayBack " " ConvertMillimsToDT(PayBack)
        IfMsgBox, Yes
        {
            MsgBox, 36, % _187, % _189
            IfMsgBox, Yes
            {
                FileAppend, % PayBack, % "Kr\" KLB "\" A_Now ".pay"
                GuiControl,, PayBack
                PayVal := PayDates(KLB)
                Ba := DateRow[3] - PayVal[2]
                GuiControl,, Balance, % KLB ": " Ba " " ConvertMillimsToDT(Ba)
            }
        }
        
    }
Return

KridiOut:
    GuiControlGet, Kridi,, Kridi
    If (Kridi > 0) {
        GuiControlGet, KLB,, KLB
        MsgBox, 36, % _187, % KLB " " _197 " " Kridi " " ConvertMillimsToDT(PayBack)
        IfMsgBox, Yes
        {
            MsgBox, 36, % _187, % _189
            IfMsgBox, Yes
            {
                FormatTime, OutTime, % Now := A_Now, yyyy/MM/dd HH:mm:ss
                FileAppend, % AdminName "|" OutTime "> > " Kridi ";" Kridi ";0", % "Kr\" KLB "\" A_Now ".sell"
                GuiControl,, Kridi
                DateRow := KridiDates(KLB)
                Ba := DateRow[3] - PayVal[2]
                GuiControl,, Balance, % KLB ": " Ba " " ConvertMillimsToDT(Ba)
            }
        }
    }
Return

SelectFromLV:
    GuiControlGet, KDate,, KDate
    If (!KDate)
        Return
    Loop, % LV_GetCount() {
        LV_Modify(A_Index, "-Select")
    }
    If (!InStr(KDate, "|")) {
        For Each, Row in DateRow[1][KDate] {
            LV_Modify(Row, "Select")
        }
        GuiControl, Focus, LV
    } Else {
        For Each, Date in StrSplit(KDate, "|") {
            For Each, Row in DateRow[1][Date] {
                LV_Modify(Row, "Select")
            }
            GuiControl, Focus, LV
        }
    }
    
    GuiControl,, SubThisKridi, % DateRow[2][KDate] "`n" ConvertMillimsToDT(DateRow[2][KDate])
Return

ShowPayVal:
    GuiControlGet, PDate,, PDate
    If (PDate) {
        GuiControl,, ThisPay, % PayVal[1][PDate] "`n" ConvertMillimsToDT(PayVal[1][PDate])
    }
Return

Add:
    InputBox, PersonName, Name?, Person Name?,, 300, 130
    Validity := ErrorLevel
    If (Validity = 0) {
        If (PersonName != "") && (PersonName ~= "\b\w+\b") && !InStr(FileExist("Kr\" PersonName), "D") {
            FileCreateDir, % "Kr\" PersonName
            LoadKridis(PersonName)
        } Else {
            MsgBox, 16, % _13, % _199
        }
    }
Return

KUpdateVal:

Return

GUIClose:
    IniDelete, Sets\PID.ini, PID, GUIKridiM
ExitApp