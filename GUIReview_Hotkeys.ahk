#If WinActive("ahk_id " Main)
Enter::
    GuiControlGet, Begin,, Begin
    GuiControlGet, End,, End
    GuiControl, Choose, Dates, 0

    While (End >= Begin) {
        FormatTime, FBegin, % Begin, yyyy/MM/dd
        GuiControl, ChooseString, Dates, % "|-- " FBegin " --"
        Begin += 1, Days
    }
Return