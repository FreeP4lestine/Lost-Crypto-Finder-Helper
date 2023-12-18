#Requires AutoHotkey v1.1
#SingleInstance, Force
SetBatchLines, -1
SetWorkingDir, % A_ScriptDir

FileInstall, Uninstall.png, Uninstall.png, 1

Gui, -MinimizeBox
Gui, Font, s20 Bold, Calibri
Gui, Color, White
Gui, Add, Text, Center BackgroundTrans w400, Cash Helper
Gui, Add, Pic, xm yp-10 w64 h64 BackgroundTrans, Uninstall.png
Gui, Font, Norm
Gui, Font, s10 Bold
Gui, Add, Edit, ReadOnly w400 vLoc, % A_ScriptDir
IS := InstallState()
Gui, Add, Button, w100 vUB, % IS[1]

If (IS[1] = "Not Installed") {
    GuiControl, Disabled, UB
}

Gui, Add, Progress, vPB w100 -Smooth h15 w400 Hidden
Gui, Font, s8
Gui, Add, Text, xp yp+17 wp Center vPercent BackgroundTrans
Gui, Show
Return

GuiClose:
ExitApp

ButtonUninstall:
    GuiControl, Disabled, UB
    RegDelete, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Cash Helper
    FileDelete, % A_Desktop "\Cash Helper.lnk"
    GuiControlGet, Loc
    FileRemoveDir, % Loc, 1
    FileOpen(A_Temp "\CH_Uninstall.bat", "w").Write("timeout 1`nrd /s /q """ Loc """").Close()
    MsgBox,, Complete, Uninstall Complete!
    Run, % A_Temp "\CH_Uninstall.bat",, Hide
    ExitApp
Return

InstallState() {
    RegRead, IC, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Cash Helper, InstallLocation
    GuiControlGet, Loc
    IS := (IC = Loc "\") ? ["Uninstall", "Uninstalling..."] : ["Not Installed", ""]
    GuiControl,, IB, % IS[1]
    Return, IS
}