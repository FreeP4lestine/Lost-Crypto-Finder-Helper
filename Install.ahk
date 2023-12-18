#Requires AutoHotkey v1.1
#SingleInstance, Force
SetBatchLines, -1
SetWorkingDir, % A_ScriptDir

FileInstall, __Release\CH-Install.zip, CH-Install.zip, 1
FileInstall, Install.png, Install.png, 1

Gui, -MinimizeBox
Gui, Font, s20 Bold, Calibri
Gui, Color, White
Gui, Add, Text, Center BackgroundTrans w400, Cash Helper
Gui, Add, Pic, xm yp-10 w64 h64 BackgroundTrans, Install.png
Gui, Font, Norm
Gui, Font, s10 Bold
Gui, Add, Edit, ReadOnly w290 vLoc, %A_ProgramFiles%\Cash Helper
IS := InstallState()
Gui, Font, s8
Gui, Add, Button, xp+300 yp w100 vCG, Change
Gui, Font, s10
Gui, Add, Checkbox, xp-300 yp+30 Checked gInstallWay vIAU, Install for all users
Gui, Add, Checkbox, yp+20 vPort, Portable
Gui, Add, Button, w100 vIB gButtonInstall, % IS[1]
Gui, Add, Progress, w400 vPB -Smooth h15 Hidden
Gui, Font, s8
Gui, Add, Text, xp yp+17 wp Center vPercent BackgroundTrans

FileInstall, __Release\Version.txt, Version.txt, 1

FileRead, Version, Version.txt
Gui, Show,, Install Setup %Version%
GuiControl, Focus, IB
Return
InstallWay:
    GuiControlGet, IAU
    If (IAU) {
        GuiControl,, Loc, %A_ProgramFiles%\Cash Helper
    } Else {
        GuiControl,, Loc, %A_AppData%\Cash Helper
    }
    IS := InstallState()
Return

GuiClose:
ExitApp

ButtonInstall:
    If !FileExist("CH-Install.zip") {
        MsgBox, 16, Error, Install package not found.
        Return
    }
    GuiControl, Disabled, IB
    GuiControl, Disabled, IAU
    GuiControl, Disabled, Port
    GuiControl, Disabled, Loc
    GuiControl, Disabled, CG
    GuiControl,, IB, % IS[2]
    GuiControlGet, Loc
    GuiControl, Show, PB
    GuiControl,, PB, + 20
    GuiControl,, Percent, 20 `%
    FileCopyDir, CH-Install.zip, % Loc, 1
    FileDelete, CH-Install.zip
    GuiControl,, PB, + 30
    GuiControl,, Percent, 50 `%
    FileCopyDir, % Loc "\HighChart.zip", % Loc "\", 1
    FileDelete, % Loc "\HighChart.zip"
    GuiControl,, PB, + 40
    GuiControl,, Percent, 90 `%
    FileCopy, Version.txt, % Loc, 1
    FileDelete, Version.txt
    GuiControl,, PB, + 10
    GuiControl,, Percent, 100 `%
    GuiControlGet, Port
    
    If (!Port) {
        RegPath := "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Cash Helper"
        RegWrite, REG_SZ, %RegPath%, DisplayName, Cash Helper
        RegWrite, REG_SZ, %RegPath%, DisplayVersion, %Version%
        RegWrite, REG_SZ, %RegPath%, DisplayIcon, %Loc%\StartUp.exe
        RegWrite, REG_SZ, %RegPath%, InstallLocation, %Loc%\
        RegWrite, REG_SZ, %RegPath%, UninstallString, %Loc%\Uninstall.exe
        RegWrite, REG_DWORD, %RegPath%, NoModify, 1
        RegWrite, REG_DWORD, %RegPath%, NoRepair, 1
        RegWrite, REG_SZ, %RegPath%, Publisher, Chandoul Mohamed
        GuiControl,, Log, Creating a shortcut...
        FileCreateShortcut, %Loc%\StartUp.exe, %A_Desktop%\Cash Helper.lnk
    }
    
    GuiControl,, IB, COMPLETE!
    
    MsgBox, 4, Launch, Run Cash Helper now?
    IfMsgBox, Yes
    {
        Run, % Loc "\StartUp.exe"
    }
ExitApp

ButtonChange:
    If (Dir := SelectFolderEx(StartingFolder := "", Prompt := "Select Program Location",, OkBtnLabel := "OK!")) {
        GuiControl,, Loc, % Dir "\Cash Helper"
        InstallState()
    }
Return

SelectFolderEx(StartingFolder := "", Prompt := "", OwnerHwnd := 0, OkBtnLabel := "") {
    Static OsVersion := DllCall("GetVersion", "UChar")
    , IID_IShellItem := 0
    , InitIID := VarSetCapacity(IID_IShellItem, 16, 0)
    & DllCall("Ole32.dll\IIDFromString", "WStr", "{43826d1e-e718-42ee-bc55-a1e261c37bfe}", "Ptr", &IID_IShellItem)
    , Show              := A_PtrSize * 3
    , SetOptions        := A_PtrSize * 9
    , SetFolder         := A_PtrSize * 12
    , SetTitle          := A_PtrSize * 17
    , SetOkButtonLabel  := A_PtrSize * 18
    , GetResult         := A_PtrSize * 20
    SelectedFolder      := ""
    
    If (OsVersion < 6) {
        FileSelectFolder, SelectedFolder, *%StartingFolder%, 3, %Prompt%
        Return SelectedFolder
    }
    
    OwnerHwnd := DllCall("IsWindow", "Ptr", OwnerHwnd, "UInt") ? OwnerHwnd : 0
    If !(FileDialog := ComObjCreate("{DC1C5A9C-E88A-4dde-A5A1-60F82A20AEF7}", "{42f85136-db7e-439c-85f1-e4075d135fc8}"))
        Return ""
    VTBL := NumGet(FileDialog + 0, "UPtr")
    DllCall(NumGet(VTBL + SetOptions, "UPtr"), "Ptr", FileDialog, "UInt", 0x00002028, "UInt")
    
    If (StartingFolder <> "")
        If !DllCall("Shell32.dll\SHCreateItemFromParsingName", "WStr", StartingFolder, "Ptr", 0, "Ptr", &IID_IShellItem, "PtrP", FolderItem)
            DllCall(NumGet(VTBL + SetFolder, "UPtr"), "Ptr", FileDialog, "Ptr", FolderItem, "UInt")
    
    If (Prompt <> "")
        DllCall(NumGet(VTBL + SetTitle, "UPtr"), "Ptr", FileDialog, "WStr", Prompt, "UInt")
    
    If (OkBtnLabel <> "")
        DllCall(NumGet(VTBL + SetOkButtonLabel, "UPtr"), "Ptr", FileDialog, "WStr", OkBtnLabel, "UInt")
    
    If !DllCall(NumGet(VTBL + Show, "UPtr"), "Ptr", FileDialog, "Ptr", OwnerHwnd, "UInt") {
        If !DllCall(NumGet(VTBL + GetResult, "UPtr"), "Ptr", FileDialog, "PtrP", ShellItem, "UInt") {
            GetDisplayName := NumGet(NumGet(ShellItem + 0, "UPtr"), A_PtrSize * 5, "UPtr")
            If !DllCall(GetDisplayName, "Ptr", ShellItem, "UInt", 0x80028000, "PtrP", StrPtr)
            SelectedFolder := StrGet(StrPtr, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "Ptr", StrPtr)
            ObjRelease(ShellItem)
        }
    }
    
    If (FolderItem)
        ObjRelease(FolderItem)
        
    ObjRelease(FileDialog)
    Return SelectedFolder
}

InstallState() {
    RegRead, IC, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Cash Helper, InstallLocation
    GuiControlGet, Loc
    IS := (IC = Loc "\") ? ["Update", "Updating..."] : ["Install", "Installing..."]
    GuiControl,, IB, % IS[1]
    Return, IS
}