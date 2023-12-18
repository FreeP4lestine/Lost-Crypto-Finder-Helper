#If WinActive("ahk_id " Main)
    Delete::
        GuiControlGet, KLB,, KLB
        If (KLB) {
            MsgBox, 36, % _187, % KLB " " _190
            IfMsgBox, Yes
            {
                MsgBox, 36, % _187, % _189
                IfMsgBox, Yes
                {
                    FileMoveDir, % "Kr\" KLB, % "CKr\", 1
                    LoadKridis()
                }
            }
        }
    Return
#If