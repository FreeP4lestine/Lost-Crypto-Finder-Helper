GuiClose:
    IniDelete, Sets\PID.ini, PID, GUISell
ExitApp

LaunchKeyboard:
    Run, osk.exe
Return

SubKridi:
    Obj := FileOpen("Dump\tmp.sell", "w")
    Loop, % LV_GetCount() {
        LV_GetText(C1, A_Index, 1)
        LV_GetText(C2, A_Index, 2)
        LV_GetText(C3, A_Index, 3)
        LV_GetText(C4, A_Index, 4)
        LV_GetText(C5, A_Index, 5)
        Obj.Write(C1 "," C2 "," C3 "," C4 "," C5 "`n")
    }
    Obj.Close()

    RunWait, % "GUIKridi" (A_IsCompiled ? ".exe" : ".ahk")
    GoSub, Enter
Return

Calc:
    GuiControlGet, GivenMoney,, GivenMoney
    GuiControlGet, AllSum,, AllSum
    GuiControl, , Change

    Change := GivenMoney - AllSum
    If GivenMoney is Digit
    {
        GuiControl, , Change, % (Change >= 0) ? Change : 0
    }
Return

AnalyzeAvail:
    GuiControlGet, Bc,, Bc
    If (Bc != "") {
        If (ProdDefs.HasKey("" Bc "")) {
            GuiControl, , Nm,   % ProdDefs["" Bc ""]["Name"]
            GuiControl, , Qn,   % ProdDefs["" Bc ""]["Quantity"]
            GuiControl, , Sum,  % ProdDefs["" Bc ""]["SellPrice"]
            GuiControl, Enabled, AddEnter
        } Else {
            GuiControl, , Nm
            GuiControl, , Sum
            GuiControl, , Qn
            GuiControl, Disabled, AddEnter
        }
    } Else {
        GuiControl, , Nm
        GuiControl, , Sum
        GuiControl, , Qn
        GuiControl, Disabled, AddEnter
    }
Return

Remise:
    GuiControlGet, Remise, , Remise
    If (Remise > 100) 
        GuiControl, , Remise, % Remise := ""
    CalculateSum()
Return

Client:
    SellDesc:
        CalculateSum()
    Return
Return

AdditionalInfo:
    If (AdditionalInfo := !AdditionalInfo) {
        GuiControl, Enabled, Remise
        GuiControl, Enabled, Client
        GuiControl, Enabled, SellDesc
        GuiControl, ,AdditionalInfoPic, % "Img\MIE.png"
    } Else {
        GuiControl, Disabled, Remise
        GuiControl, Disabled, Client
        GuiControl, Disabled, SellDesc
        GuiControl, ,AdditionalInfoPic, % "Img\MID.png"
    }
    CalculateSum()
Return

ViewLastTrans:
    If (LastestSO) {
        Run, % "GUIDetails" (A_IsCompiled ? ".exe" : ".ahk") " " LastestSO
    }
Return

Session1:
    Session := 1
    Loop, 10 {
        If (A_Index = 1) {
            GuiControl, Disabled, Session%A_Index%
        } Else {
            GuiControl, Enabled, Session%A_Index%
        }
    }

    RestoreSession()
    CalculateSum()
Return

Session2:
    Session := 2
    Loop, 10 {
        If (A_Index = 2) {
            GuiControl, Disabled, Session%A_Index%
        } Else {
            GuiControl, Enabled, Session%A_Index%
        }
    }

    RestoreSession()
    CalculateSum()
Return

Session3:
    Session := 3
    Loop, 10 {
        If (A_Index = 3) {
            GuiControl, Disabled, Session%A_Index%
        } Else {
            GuiControl, Enabled, Session%A_Index%
        }
    }

    RestoreSession()
    CalculateSum()
Return

Session4:
    Session := 4
    Loop, 10 {
        If (A_Index = 4) {
            GuiControl, Disabled, Session%A_Index%
        } Else {
            GuiControl, Enabled, Session%A_Index%
        }
    }

    RestoreSession()
    CalculateSum()
Return

Session5:
    Session := 5
    Loop, 10 {
        If (A_Index = 5) {
            GuiControl, Disabled, Session%A_Index%
        } Else {
            GuiControl, Enabled, Session%A_Index%
        }
    }

    RestoreSession()
    CalculateSum()
Return

Session6:
    Session := 6
    Loop, 10 {
        If (A_Index = 6) {
            GuiControl, Disabled, Session%A_Index%
        } Else {
            GuiControl, Enabled, Session%A_Index%
        }
    }

    RestoreSession()
    CalculateSum()
Return

Session7:
    Session := 7
    Loop, 10 {
        If (A_Index = 7) {
            GuiControl, Disabled, Session%A_Index%
        } Else {
            GuiControl, Enabled, Session%A_Index%
        }
    }

    RestoreSession()
    CalculateSum()
Return

Session8:
    Session := 8
    Loop, 10 {
        If (A_Index = 8) {
            GuiControl, Disabled, Session%A_Index%
        } Else {
            GuiControl, Enabled, Session%A_Index%
        }
    }

    RestoreSession()
    CalculateSum()
Return

Session9:
    Session := 9
    Loop, 10 {
        If (A_Index = 9) {
            GuiControl, Disabled, Session%A_Index%
        } Else {
            GuiControl, Enabled, Session%A_Index%
        }
    }

    RestoreSession()
    CalculateSum()
Return

Session10:
    Session := 10
    Loop, 10 {
        If (A_Index = 10) {
            GuiControl, Disabled, Session%A_Index%
        } Else {
            GuiControl, Enabled, Session%A_Index%
        }
    }

    RestoreSession()
    CalculateSum()
Return

WriteToBc:
    GuiControlGet, Search,, Search
    If (Search) {
        GuiControl,, Bc, % SearchList[Search]
    }
Return

TranscHide:
    If (++CountToHide = 30) {
        SetTimer, TranscHide, Off
        CountToHide := 0
        GuiControl, Hide, Transc
        GuiControl, Hide, TranscOK
    }
Return