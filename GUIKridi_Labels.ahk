GuiClose:
    FileDelete, % "Dump\Kridi.sell"
ExitApp

CheckKExist:
    GuiControlGet, KName,, KName
    GuiControl, Choose, KLB, 0
    GuiControl, ChooseString, KLB, % "|" KName
Return

DisplayThisKridi:
    MaxValue := 0
    GuiControlGet, KLB,, KLB
    Loop, Files, % "Kr\" KLB "\*.sell"
    {
        FileRead, Content, % A_LoopFileFullPath
        Content := StrSplit(Content, "> ")[3]
        MaxValue += StrSplit(Content, ";")[1]
    }
    GuiControl,, ThisTotal, % MaxValue " " ConvertMillimsToDT(MaxValue)
Return