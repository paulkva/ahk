EditTxt := "Sample_Text`nMore Sample"
Gui, New
Gui, Add, Text, vMyText, %EditTxt%
GuiControlGet, TextSize, Pos, MyText
GuiControl, Hide, MyText
Gui, Show, Autosize

MsgBox Text size is %TextSizeW% x %TextSizeH% pixels