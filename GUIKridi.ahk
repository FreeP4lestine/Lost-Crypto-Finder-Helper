#SingleInstance, Force
SetBatchLines, -1
SetWorkingDir, % A_ScriptDir

#Include, Lib\Classes\Class_CtlColors.ahk
#Include, Lib\Classes\Class_ImageButton.ahk
#Include, Lib\Classes\Class_GDIplus.ahk

#Include, Lib\Language.ahk

FolderSet()

Gui, -MinimizeBox
Gui, Color, 0xD8D8AD
Gui, Margin, 10, 10
Gui, Font, s15 Bold, Calibri
Gui, Add, Edit, w200 vKName -E0x200 Border gCheckKExist
Gui, Font, s13
Gui, Add, Button, xm+210 ym w100 h33 HwndHCtrl gEnter, % _36
ImageButton.Create(HCtrl,[[0, 0x2ECB52, , 0x000000, 0, , 0x28A745, 2]
                        , [0, 0x31E059, , 0x000000, 0, , 0x28A745, 2]
                        , [0, 0x37F462, , 0x000000, 0, , 0x28A745, 2]
                        , [0, 0xD8D8AD, , 0xB2B2B2, 0, , 0xB2B2B2, 2]]* )
Gui, Font, s15
Gui, Add, ListBox, w200 xm ym+40 vKLB h450 gDisplayThisKridi -Multi
Gui, Add, ListView, xm+210 ym+40 w760 h435 Grid cBlue HwndHCtrl -Hdr, Col1|Col2|Col3|Col4|Col5

LV_ModifyCol(1, 0)
LV_ModifyCol(2, 190)
LV_ModifyCol(3, 190 " Center")
LV_ModifyCol(4, 190 " Center")
LV_ModifyCol(5, 190 " Center")
Gui, Add, Edit, xm+550 ym w200 h33 -E0x200 Border ReadOnly vTotal Center
Gui, Add, Edit, xm+768 ym w200 h33 -E0x200 Border ReadOnly vThisTotal Center cRed HwndE
CtlColors.Attach(E, "FFFFFF", "000000")

Gui, Show
LoadKridiUsers()
Return

#Include, GUIKridi_Functions.ahk
#Include, GUIKridi_Labels.ahk
#Include, GUIKridi_Hotkeys.ahk