#Requires AutoHotkey v1.1
#SingleInstance, Force
SetBatchLines, -1
#NoEnv
SetWorkingDir, % A_ScriptDir

Gui, Font, Bold s12, Consolas
Gui, +HwndMain -Border +Resize
FileRead, Version, LVersion.txt
Gui, Add, Text, w300 Center, % "Cash Helper v" Version
Gui, Add, Text, w300 Center vDownloadInfo cRed
Gui, Add, Progress, xp yp+50 wp h15 +0x00000008 HwndPB -Smooth
DllCall("User32.dll\SendMessage", "Ptr", PB, "Int", 0x00000400 + 10, "Ptr", 1, "Ptr", 50)
SetTimer, CheckSize, 1000
Gui, Show
Return

CheckSize:
    FileGetSize, Size, % A_Temp "\Install.exe", B
    GuiControl,, DownloadInfo, % "↓ " Round(Size/1000000, 2) " mb..."
Return

GuiClose:
ExitApp