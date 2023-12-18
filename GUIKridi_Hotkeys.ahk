#If WinActive("ahk_id " Kridi)
    Enter::
        GuiControlGet, KName,, KName
        If (KName = "")
            GuiControlGet, KName,, KLB
            
        If (KName != "") {
            FileOpen("Dump\Kridi.sell", "w").Write(KName).Close()
            ;FileDelete, % "Dump\Kridi.sell"
            ExitApp
        }
    Return
#If