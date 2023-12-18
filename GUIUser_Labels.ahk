ShowInfo:
    If (R := LV_GetNext()) {
        LV_GetText(Nm, R, 1)
        LV_GetText(Pw, R, 2)
        LV_GetText(Lv, R, 3)
        GuiControl,, UN, % Nm
        GuiControl,, PW, % Pw
        GuiControl, ChooseString, LVL, % Lv
        If (UserList[Nm][3]) {
            GuiControl,, UserPic, % UserList[Nm][3]
        } Else {
            GuiControl,, UserPic, Img\UserLogo.png
        }
    }
Return

DelUser:
    If (R := LV_GetNext()) {
        LV_GetText(Nm, R, 1)
        If NoAdminsLeft(Nm) {
            MsgBox, 33, % _174, % _224
            IfMsgBox, Cancel
                Return
        }
        MsgBox, 33, % _174, % _91 " '" Nm "'"
        IfMsgBox, OK
        {
            UserList.Delete(Nm)
            UpdateAccounts()
            LoadAccounts()
        }
    }
Return

AddUser:
    InputBox, UN, % _87, % _87,, 300, 130
    InputBox, PW, % _88, % _88,, 300, 130
    LVL := "USER"
    
    If (UN != "") && (PW != "") && !UserList.HasKey(UN) {
        UserList[UN] := [PW, LVL]
        UpdateAccounts()
        LoadAccounts()
    } Else {
        Msgbox, 16, % _13, % _225
    }
Return

SaveChanges:
    GuiControlGet, UN,, UN
    GuiControlGet, PW,, PW
    GuiControlGet, LVL,, LVL
    
    If (R := LV_GetNext()) && (UN != "" && UN = Nm) && (PW != "") {
        UserList[Nm][1] := PW
        UserList[Nm][2] := LVL
        UpdateAccounts()
        LoadAccounts()
    } Else {
        Msgbox, 16, % _13, % _225
    }
Return

ChooseAPic:
    if !(R := LV_GetNext()) {
        Return
    }
    LV_GetText(Nm, R, 1)
    FileSelectFile, UserPic
    iF (UserPic != "") {
        GuiControl,, UserPic, % UserPic
        SplitPath, % UserPic,,, OutExt
        FileCopy, % UserPic, % "Img\Users\" Nm "." OutExt, 1
        UserList[Nm][3] := "Img\Users\" Nm "." OutExt
    } Else {
        GuiControl,, UserPic, Img\UserLogo.png
        FileDelete, % UserList[Nm][3]
        UserList[Nm].RemoveAt(3)
    }
Return

GuiClose:
    IniDelete, Sets\PID.ini, PID, GUIUser
ExitApp