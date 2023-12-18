#Requires AutoHotkey v1.1
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1

#Persistent
#SingleInstance, Force

7zipExitCode:= {  0	    : "No error"
                , 1	    : "Warning (Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed."
                , 2	    : "Fatal error"
                , 7	    : "Command line error"
                , 8	    : "Not enough memory for operation"
                , 255	: "User stopped the process"}

Gui, Add, ListBox, w100 r10 vCompileAHK, % "StartUp"
                                        . "|Import"
                                        . "|GUIUser"
                                        . "|GUISubmit"
                                        . "|GUISell"
                                        . "|GUIReview"
                                        . "|GUIKridiM"
                                        . "|GUIKridi"
                                        . "|GUIDetails"
                                        . "|GUIDefine"
                                        . "|GUIUpdate"
                                        . "|Uninstall"

Gui, Add, ListBox, xp+110 wp hp vCopyRES, % "Img"
                                         . "|Lib"

Gui, Add, ListBox, xp+110 wp hp vCompressF, % "HighChart"
                                           . "|CH-Install"

Gui, Add, Button, xm wp gCompileSel, Compile
Gui, Add, Button, xp yp+25 wp gCompileAll, Compile All

Gui, Add, Button, xp+110 yp-25 wp gCopySel, Copy
Gui, Add, Button, xp yp+25 wp gCopyAll, Copy All

Gui, Add, Button, xp+110 yp-25 wp gCompressSel, Compress
Gui, Add, Button, xp yp+25 wp gCompressAll, Compress All

Gui, Add, Edit, xm w320 vLog -VScroll -HScroll ReadOnly
FileRead, Version, Version.txt
Gui, Add, Edit, Center cRed vVersion w100, % Version 
Gui, Add, Button, wp, Prepare All
Gui, Show,, Create a release
Return

CompileSel:
    GuiControlGet, CompileAHK
    If (CompileAHK) {
        For Each, Script in StrSplit(CompileAHK, "|") {
            CompileScript(Script)
        }
    }
Return

CompileAll:
    CompileScript("StartUp")
    CompileScript("Import")
    CompileScript("GUIUser")
    CompileScript("GUISubmit")
    CompileScript("GUISell")
    CompileScript("GUIReview")
    CompileScript("GUIKridiM")
    CompileScript("GUIKridi")
    CompileScript("GUIDetails")
    CompileScript("GUIDefine")
    CompileScript("GUIUpdate")
    CompileScript("Uninstall")
Return

CopySel:
    GuiControlGet, CopyRES
    If (CopyRES)
        PrepareResource(CopyRES)
Return

CopyAll:
    PrepareResource("Img")
    PrepareResource("Lib")
Return

CompressSel:
    GuiControlGet, CompressF
    Switch CompressF {
        Case "HighChart":
            GuiControl,, Log, Compressing into HighChart...
            FileDelete, __Release\HighChart.zip
            RunWait, %ComSpec% /c __Compiler\7za.exe a -aoa __Release\HighChart.zip HighChart\
            If (ErrorLevel) {
                Msgbox, 16, Error, % "Error Code: " ErrorLevel "`n" 7zipExitCode[ErrorLevel]
            } ELse {
                GuiControl,, Log, Compressing into HighChart.zip... - OK!
            }
        Return

        Case "CH-Install":
            GuiControl,, Log, Compressing into CH-Install.zip...
            FileDelete, __Release\CH-Install.zip
            FileDelete, __Release\Install.exe
            GuiControlGet, Version
            FileOpen("Version.txt", "w").Write(Version).Close()
            FileCopy, Version.txt, __Release\Version.txt, 1
            RunWait, %ComSpec% /c cd __Release && ..\__Compiler\7za.exe a -aoa CH-Install.zip *
            If (E := ErrorLevel) {
                Msgbox, 16, Error, % "Error Code: " E "`n" 7zipExitCode[E]
            } ELse {
                GuiControl,, Log, Compressing into CH-Install.zip... - OK!
            }
        Return
    }
Return

CompressAll:
    GuiControl,, Log, Compressing into HighChart...
    FileDelete, __Release\HighChart.zip
    RunWait, %ComSpec% /c __Compiler\7za.exe a -aoa __Release\HighChart.zip HighChart\
    If (ErrorLevel) {
        Msgbox, 16, Error, % "Error Code: " ErrorLevel "`n" 7zipExitCode[ErrorLevel]
    } ELse {
        GuiControl,, Log, Compressing into HighChart.zip... - OK!
    }
    
    GuiControl,, Log, Compressing into CH-Install.zip...
    FileDelete, __Release\CH-Install.zip
    FileDelete, __Release\Install.exe
    GuiControlGet, Version
    FileOpen("Version.txt", "w").Write(Version).Close()
    FileCopy, Version.txt, __Release\Version.txt, 1
    RunWait, %ComSpec% /c cd __Release && ..\__Compiler\7za.exe a -aoa CH-Install.zip *
    If (ErrorLevel) {
        Msgbox, 16, Error, % "Error Code: " ErrorLevel "`n" 7zipExitCode[ErrorLevel]
    } ELse {
        GuiControl,, Log, Compressing into CH-Install.zip... - OK!
    }
Return

ButtonPrepareAll:
    GoSub, CompileAll
    GoSub, CopyAll
    GoSub, CompressAll
    CompileScript("Install")
    GuiControl,, Log, %A_ScriptDir%\__Release\Install.exe
Return

GuiClose:
ExitApp

CompileScript(AHKName, MoveTo := "") {
    GuiControlGet, Log
    RunWait, % """__Compiler\Ahk2Exe.exe"""
             . " /in   """    AHKName ".ahk"""
             . " /out  """    AHKName ".exe"""
             . " /icon "      (FileExist(AHKName ".ico") ? AHKName ".ico" : "Default.ico")
             . " /base ""__Compiler\Unicode 32-bit.bin"""
    If (!ErrorLevel) {
        GuiControl,, Log, % "Compiling " AHKName " - OK!"
        If (!MoveTo)
            FileMove, %AHKName%.exe, __Release\%AHKName%.exe, 1
        Else 
            FileMove, %AHKName%.exe, __Release\%AHKName%.exe, 1
    }
    Else
        Msgbox, 16, Error, % "Compiling " AHKName ".ahk... - ERROR!"
}

PrepareResource(Element) {
    GuiControl,, Log, % "Copying " Element "..."
    Sleep, 250
    If !InStr(FileExist(Element), "D") {
        FileCopy, % Element, % "__Release\" Element, 1
    } Else {
        FileCopyDir, % Element, % "__Release\" Element, 1
    }
    If (!ErrorLevel)
        GuiControl,, Log, % "Copying " Element ".. - OK!"
    Else
        Msgbox, 16, Error, % "Copying " Element "... - ERROR!"
}