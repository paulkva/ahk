; *********************************************************************************
; 		Automatic Mapping of All Monitors, Move & Resize Windows  -START-
; *********************************************************************************
#SingleInstance force
#Persistent

; Initialization of Arrays used
; Variables used for Temporary Monitor Number used to later organize Monitors in Ascending Order
; (1D Arrays)
MonTopTemp := []
MonBtmTemp := []
MonLftTemp := []
MonRgtTemp := []

; Variables used for Definitive Monitor Number in Ascending Order
; (1D Arrays)
global Mon := {}, DebugOSD := 1
Mon.Top := []
Mon.Btm := []
Mon.Lft := []
Mon.Rgt := []

; Variables used for Row Alignment with Bottom of Monitors
MonDIMBtmT := []

;InitMon()
;{
; Retrieve the Quantity of Monitors connected to system
SysGet, MonQty, MonitorCount

; Retrieve Coordinates and Dimensions of each Monitor
Loop, %MonQty%
{
	SysGet, MonWRKA, MonitorWorkArea, %A_Index%
	SysGet, MonDIM, Monitor, %A_Index%

	MonTopTemp[A_Index] := MonWRKATop
	MonBtmTemp[A_Index] := MonWRKABottom
	MonLftTemp[A_Index] := MonWRKALeft
	MonRgtTemp[A_Index] := MonWRKARight

	RowCntTemp = %RowCntTemp%, %MonWRKATop%
	ColCntTemp = %ColCntTemp%, %MonWRKALeft%

	; Variables used for Row Alignment with Bottom of Monitors
	MonDIMBtmT[A_Index] := MonDIMBottom
	RowCntBtmT = %RowCntBtmT%, %MonDIMBottom%
}

; Trim the first character (a comma ",") 
StringTrimLeft, RowCnt, RowCntTemp, 1
StringTrimLeft, ColCnt, ColCntTemp, 1
; Bottom of Row Alignment
StringTrimLeft, RowBtmCnt, RowCntBtmT, 1

; List out each unique value of Row and Column, defining boundaries
Sort RowCnt, N U D,
Sort ColCnt, N U D,
; Bottom of Row Alignment
Sort RowBtmCnt, N U D,

; Count the number of Rows and Columns
Loop, Parse, RowCnt, `,
{
	RowQty := A_Index
}
Loop, Parse, ColCnt, `,
{
	ColQty := A_Index
}
; Bottom of Row Alignment
Loop, Parse, RowBtmCnt, `,
{
	RowBtmQty := A_Index
}

; Separates each value of Row and Column into an Array Variable
RowValues := StrSplit(RowCnt, ",", " ")
ColValues := StrSplit(ColCnt, ",", " ")
; Bottom of Row Alignment
RowBtmValues := StrSplit(RowBtmCnt, ",", " ")

; ***** Monitor Mapping Initialization *****
; After counting how many Rows and Columns there are, the script will verify if
; there is a Monitor in each of the Rows/Columns Positions. If there is a gap
; (no Monitor in a Row/Column), the Space should not register in the Mapping

; Counter to Assign Monitor Number, from Top Left to Bottom Right
MonOrdr := 1

Loop, %RowQty%
{
	; Keep the current Row in Memory
	RowPosA_Index := A_Index

	Loop, %ColQty%
	{
		; Keep the current Column in Memory
		ColPosA_Index := A_Index

		Loop, %MonQty%
		{
			; Keep the current Monitor Number in Memory
			MonNrA_Index := A_Index

			If (ColValues[ColPosA_Index] == MonLftTemp[MonNrA_Index] AND RowValues[RowPosA_Index] == MonTopTemp[MonNrA_Index])
			{
				; Assign COORDINATES and DIMENSIONS of Monitors in Order, per MONITOR NUMBER, from Top Left to Bottom Right
				Mon.Top[MonOrdr] := MonTopTemp[MonNrA_Index]
				Mon.Lft[MonOrdr] := MonLftTemp[MonNrA_Index]
				Mon.Btm[MonOrdr] := MonBtmTemp[MonNrA_Index]
				Mon.Rgt[MonOrdr] := MonRgtTemp[MonNrA_Index]

				; When a Monitor is found at this ROW and COLUMN Position, increment Count for Next Monitor
				MonOrdr += 1
				; Once Matching Monitor Found, Skip to Next Column
				Break
			}
		}
	}
}

OnMessage(0x7E, "WM_DISPLAYCHANGE")

WM_DISPLAYCHANGE(wParam, lParam) {
	SetTimer, Restart, % 5000
}

Restart() {
	Reload
	Sleep % 1000
	ExitApp
}

CreateGUI()
ShowOSD("WindowMappings Ready @ " . WinCurntMon() . "/" . MonQty, 1000)

; NumPad1/End :: Bottom Left 50% / 67% / 80%
#^NumPadEnd::
#^NumPad1::SnapWin(0,50,50,50)
#!NumpadEnd::
#!NumPad1::SnapWin(0,33,67,67)
#^!NumPadEnd::
#^!NumPad1::SnapWin(0,20,80,80)

; NumPad2/Down :: Bottom 50% / 67% / 80%
#^NumPadDown::
#^NumPad2::SnapWin(0,50,100,50)
#!NumPadDown::
#!NumPad2::SnapWin(0,33,100,67)
#^!NumPadDown::
#^!NumPad2::SnapWin(0,20,100,80)

; NumPad3/PgDn :: Bottom Right 50% / 67% / 80%
#^NumPadPgDn::
#^NumPad3::SnapWin(50,50,50,50)
#!NumPadPgDn::
#!NumPad3::SnapWin(33,33,67,67)
#^!NumPadPgDn::
#^!NumPad3::SnapWin(20,20,80,80)

; NumPad4/Left :: Left 50% / 67% / 80%
#^NumPadLeft::
#^NumPad4::SnapWin(0,0,50,100)
#!NumPadLeft::
#!NumPad4::SnapWin(0,0,67,100)
#^!NumPadLeft::
#^!NumPad4::SnapWin(0,0,80,100)

; NumPad5/Del/Dot :: Middle 50% / 80% / 100% (but not maximized)
#^NumPadDel::
#^NumPadDot::
#^NumPad5::SnapWin(25,25,50,50)
#!NumPadDel::
#!NumPadDot::
#!NumPad5::SnapWin(10,10,80,80)
#^!NumPadDel::
#^!NumPadDot::
#^!NumPad5::SnapWin(0,0,100,100)

; NumPad6/Right :: Right 50% / 67% / 80%
#^NumPadRight::
#^NumPad6::SnapWin(50,0,50,100)
#!NumPadRight::
#!NumPad6::SnapWin(33,0,67,100)
#^!NumPadRight::
#^!NumPad6::SnapWin(20,0,80,100)

; NumPad7/Home :: Top Left 50% / 67% / 80%
#^NumPadHome::
#^NumPad7::SnapWin(0,0,50,50)
#!NumPadHome::
#!NumPad7::SnapWin(0,0,67,67)
#^!NumPadHome::
#^!NumPad7::SnapWin(0,0,80,80)

; NumPad8/Up :: Top 50% / 67% / 80%
#^NumPadUp::
#^NumPad8::SnapWin(0,0,100,50)
#!NumPadUp::
#!NumPad8::SnapWin(0,0,100,67)
#^!NumPadUp::
#^!NumPad8::SnapWin(0,0,100,80)

; NumPad9/PgUp :: Top Right 50% / 67% / 80%
#^NumPadPgUp::
#^NumPad9::SnapWin(50,0,50,50)
#!NumPadPgUp::
#!NumPad9::SnapWin(33,0,67,67)
#^!NumPadPgUp::
#^!NumPad9::SnapWin(20,0,80,80)

; Right :: 100% on current monitor plus extend right 125% / 150% / 175%
#^Right::SnapWin(0,0,125,100)
#!Right::SnapWin(0,0,150,100)
#^!Right::SnapWin(0,0,175,100)

#^+Up::
ExtendToTopEdge:
{
	If (IgnorePrgrm())
	{
		Return
	}
	Win := PrepWin()

	TgtTop := Mon.Top[Win.M]
	TgtHgt := Win.Hgt + (Win.Top - Mon.Top[Win.M])
	WinMove, A, , Win.Lft, TgtTop, Win.Wdt, TgtHgt
	Return
}

#^+Down::
ExtendToBtmEdge:
{
	If (IgnorePrgrm())
	{
		Return
	}
	Win := PrepWin()

	TgtHgt := Mon.Btm[Win.M] - Win.Top
	WinMove, A, , Win.Lft, Win.Top, Win.Wdt, TgtHgt
	Return
}

#^+Left::
ExtendToLftEdge:
{
	If (IgnorePrgrm())
	{
		Return
	}
	Win := PrepWin()

	TgtLft := Mon.Lft[Win.M] + Win.CF.Hrz
	TgtWdt := Win.Wdt + Win.Lft - TgtLft
	WinMove, A, , TgtLft, Win.Top, TgtWdt, Win.Hgt
	Return
}

#^+Right::
ExtendToRgtEdge:
{
	If (IgnorePrgrm())
	{
		Return
	}
	Win := PrepWin()

	TgtWdt := Mon.Rgt[Win.M] - Win.Lft
	WinMove, A, , Win.Lft, Win.Top, TgtWdt, Win.Hgt
	Return
}

; Ctrl Alt Shift NumPadDiv :: Reload (and recompute screens)
^!+NumPadDiv::Restart()

; Ctrl Alt Shift NumPadMult :: Toggle Debug OSD
^!+NumPadMult::ToggleDebugOSD()
ToggleDebugOSD() {
	N := GetKeyState("NumLock", "T")
	ShowOSD("Debug off, NumLock " N, 1000)
	DebugOSD := !DebugOSD
	ShowOSD("Debug on, NumLock " N, 1000)
}

#^F1::Run "C:\si\nircmd.exe" setprimarydisplay 1
#^F2::Run "C:\si\nircmd.exe" setprimarydisplay 2
#^F3::Run "C:\si\nircmd.exe" setprimarydisplay 3
#^F4::Run "C:\si\nircmd.exe" setprimarydisplay 4

; Additional symbols on the keyboard with Ctrl+Win
#^'::°
#^.::•
#^[::«
#^]::»
#^-::±
#^=::≠
#^8::∞
#^/::÷
; Additional symbols on the keyboard with Ctrl+Win+Shift
#^+,::≤
#^+.::≥
#^+`::≈
#^+4::¢

;-----------------------------------------------------------------------------
; When activated, NumPadEnter serves as an alternative to the Windows key,
; e.g. for remote sessions that don't recognize or capture the Windows key.
; Simply press Ctrl Alt Shift NumPadEnter to activate.
;
; Be careful when using this AHK on local and remote sessions simultaneously!
; The easiest way to do so:
; - Launch this AHK on the remote session first
; - Activate with Ctrl Alt Shift NumPadEnter
; - Then launch this AHK on the local session
;
; Alternatively:
; - Disable NumPadEnter using Ctrl Win NumPadEnter on the local session
; - Enable NumPadEnter using Ctrl Alt Shift NumPadEnter on the remote session
;-----------------------------------------------------------------------------
#^NumPadEnter::DisableNumPadEnter()
DisableNumPadEnter()
{
	Hotkey, ^!+NumPadEnter, EnableNumPadEnter, Off
	Hotkey, NumPadEnter, SendNumPadEnter, Off
	Hotkey, NumPadEnter & NumpadEnd, SnapWinPad1, Off
	Hotkey, NumPadEnter & Numpad1, SnapWinPad1, Off
	Hotkey, NumPadEnter & NumpadDown, SnapWinPad2, Off
	Hotkey, NumPadEnter & Numpad2, SnapWinPad2, Off
	Hotkey, NumPadEnter & NumpadPgDn, SnapWinPad3, Off
	Hotkey, NumPadEnter & Numpad3, SnapWinPad3, Off
	Hotkey, NumPadEnter & NumpadLeft, SnapWinPad4, Off
	Hotkey, NumPadEnter & Numpad4, SnapWinPad4, Off
	Hotkey, NumPadEnter & NumpadDel, SnapWinPad5, Off
	Hotkey, NumPadEnter & NumpadDot, SnapWinPad5, Off
	Hotkey, NumPadEnter & Numpad5, SnapWinPad5, Off
	Hotkey, NumPadEnter & NumpadRight, SnapWinPad6, Off
	Hotkey, NumPadEnter & Numpad6, SnapWinPad6, Off
	Hotkey, NumPadEnter & NumpadHome, SnapWinPad7, Off
	Hotkey, NumPadEnter & Numpad7, SnapWinPad7, Off
	Hotkey, NumPadEnter & NumpadUp, SnapWinPad8, Off
	Hotkey, NumPadEnter & Numpad8, SnapWinPad8, Off
	Hotkey, NumPadEnter & NumpadPgUp, SnapWinPad9, Off
	Hotkey, NumPadEnter & Numpad9, SnapWinPad9, Off
	Hotkey, NumPadEnter & NumPadSub, SendShiftAltTab, Off
	Hotkey, NumPadEnter & NumPadAdd, SendAltTab, Off
	Hotkey, NumPadEnter & Up, ExtendToTopEdge, Off
	Hotkey, NumPadEnter & Down, ExtendToBtmEdge, Off
	Hotkey, NumPadEnter & Left, ExtendToLftEdge, Off
	Hotkey, NumPadEnter & Right, ExtendToRgtEdge, Off
	ShowOSD("NumPadEnter combinations disabled", 2000)
	Return
}

^!+NumPadEnter::EnableNumPadEnter()
EnableNumPadEnter()
{
	Hotkey, NumPadEnter, SendNumPadEnter
	Hotkey, NumPadEnter & NumpadEnd, SnapWinPad1
	Hotkey, NumPadEnter & Numpad1, SnapWinPad1
	Hotkey, NumPadEnter & NumpadDown, SnapWinPad2
	Hotkey, NumPadEnter & Numpad2, SnapWinPad2
	Hotkey, NumPadEnter & NumpadPgDn, SnapWinPad3
	Hotkey, NumPadEnter & Numpad3, SnapWinPad3
	Hotkey, NumPadEnter & NumpadLeft, SnapWinPad4
	Hotkey, NumPadEnter & Numpad4, SnapWinPad4
	Hotkey, NumPadEnter & NumpadDel, SnapWinPad5
	Hotkey, NumPadEnter & NumpadDot, SnapWinPad5
	Hotkey, NumPadEnter & Numpad5, SnapWinPad5
	Hotkey, NumPadEnter & NumpadRight, SnapWinPad6
	Hotkey, NumPadEnter & Numpad6, SnapWinPad6
	Hotkey, NumPadEnter & NumpadHome, SnapWinPad7
	Hotkey, NumPadEnter & Numpad7, SnapWinPad7
	Hotkey, NumPadEnter & NumpadUp, SnapWinPad8
	Hotkey, NumPadEnter & Numpad8, SnapWinPad8
	Hotkey, NumPadEnter & NumpadPgUp, SnapWinPad9
	Hotkey, NumPadEnter & Numpad9, SnapWinPad9
	Hotkey, NumPadEnter & NumPadSub, SendShiftAltTab
	Hotkey, NumPadEnter & NumPadAdd, SendAltTab
	Hotkey, NumPadEnter & Up, ExtendToTopEdge
	Hotkey, NumPadEnter & Down, ExtendToBtmEdge
	Hotkey, NumPadEnter & Left, ExtendToLftEdge
	Hotkey, NumPadEnter & Right, ExtendToRgtEdge
	ShowOSD("NumPadEnter combinations enabled", 2000)
	Return
}

SendNumPadEnter() {
	Send {NumPadEnter}
}
SendShiftAltTab() {
	Send {ShiftAltTab}
}
SendAltTab() {
	Send {AltTab}
}
SnapWinPad1() {
	SnapWinPad([0,0,0], [50,33,20], [50,67,80], [50,67,80])
}
SnapWinPad2() {
	SnapWinPad([0,0,0], [50,33,20], [100,100,100], [50,67,80])
}
SnapWinPad3() {
	SnapWinPad([50,33,20], [50,33,20], [50,67,80], [50,67,80])
}
SnapWinPad4() {
	SnapWinPad([0,0,0], [0,0,0], [50,67,80], [100,100,100])
}
SnapWinPad5() {
	SnapWinPad([25,10,0], [25,10,0], [50,80,100], [50,80,100])
}
SnapWinPad6() {
	SnapWinPad([50,33,20], [0,0,0], [50,67,80], [100,100,100])
}
SnapWinPad7() {
	SnapWinPad([0,0,0], [0,0,0], [50,67,80], [50,67,80])
}
SnapWinPad8() {
	SnapWinPad([0,0,0], [0,0,0], [100,100,100], [50,67,80])
}
SnapWinPad9() {
	SnapWinPad([50,33,20], [0,0,0], [50,67,80], [50,67,80])
}

; Allow for NumPadEnter to function similar to the Windows key for SnapWin
; in a virtual environment that doesn't detect actual Windows keypresses
SnapWinPad(LeftPct, TopPct, WdtPct, HgtPct)
{
	If (GetKeyState("Control") AND GetKeyState("Alt"))
	{
		Return SnapWin(LeftPct[3], TopPct[3], WdtPct[3], HgtPct[3])
	}
	If (GetKeyState("Alt"))
	{
		Return SnapWin(LeftPct[2], TopPct[2], WdtPct[2], HgtPct[2])
	}
	If (GetKeyState("Control"))
	{
		Return SnapWin(LeftPct[1], TopPct[1], WdtPct[1], HgtPct[1])
	}
}

; Main function to resize and snap a window to a corner or edge
SnapWin(LftPct = 0, TopPct = 0, WdtPct = 100, HgtPct = 100, ExtraKeys = 0)
{
	If (IsObject(ExtraKeys))
	{
		Loop % ExtraKeys.Length()
		{
			If (!GetKeyState(ExtraKeys[A_Index]))
			{
				Return
			}
		}
	}
	If (IgnorePrgrm())
	{
		Return
	}
	Win := PrepWin()

	MonWdt := Mon.Rgt[Win.M] - Mon.Lft[Win.M]
	MonHgt := Mon.Btm[Win.M] - Mon.Top[Win.M]

	TgtLft := Mon.Lft[Win.M] + Floor(MonWdt * LftPct / 100) + Win.CF.Hrz
	TgtTop := Mon.Top[Win.M] + Floor(MonHgt * TopPct / 100)
	TgtWdt := Floor(MonWdt * WdtPct / 100) + Win.CF.Wdt
	TgtHgt := Floor(MonHgt * HgtPct / 100) + Win.CF.Hgt

	WinMove, A, , TgtLft, TgtTop, TgtWdt, TgtHgt
	ShowOSD(Win.Proc " @ " . Win.M . ": (" TgtLft " , " TgtTop ") " TgtWdt " x " TgtHgt, 2000)
	Return
}

PrepWin()
{
	; Retrieve Coordinates, Dimensions, Min/Max State, Process Name and Title of Active Window
	WinGetTitle, WinTitle, A
	WinGetPos, WinLft, WinTop, WinWdt, WinHgt, A
	WinGet, WinMMax, MinMax, A
	WinGet, WinProc, ProcessName, A

	Win := {}
	Win.Lft := WinLft
	Win.Top := WinTop
	Win.Wdt := WinWdt
	Win.Hgt := WinHgt
	Win.Proc := WinProc
	Win.Title := WinTitle

	; Add Correction Factor per Program + Find in which Monitor Active Window is located
	Win.CF := CrctnFctr()
	; Retrieves on which Monitor Number the Active Window is on
	Win.M := WinCurntMon()

	; If Window is Maximized, "UnMaximize" it
	If (WinMMax == 1)
	{
		WinRestore, A
	}
	Return Win
}


;     User Defined Values and Programs
; ****************************************
; Correction Factor to implement for specific Programs
CrctnFctr()
{
	WinGet, PNameWin, ProcessName, A
	If PNameWin in code.exe,spotify.exe,outlook.exe,lync.exe,winword.exe,excel.exe,revu.exe,teams.exe,slack.exe
	{
		If (InStr(A_OSVersion, "10.0.") == 1)
		{
			Return { Hrz: 0, Hgt: 1, Wdt: 0 }
		} Else {
			Return { Hrz: 0, Hgt: 0, Wdt: 0 }
		}
	}
	; For some reason, there is an offset when working with Explorer and Chrome
	Else
	{
		Return { Hrz: -7, Hgt: 7, Wdt: 14 }
	}
}

;     User Defined Values and Programs
; ****************************************
; Exluded Programs, where the HotKeys will NOT WORK
IgnorePrgrm()
{
	WinGetClass, CNameWin, A
	; WorkerW ➔ Desktop
	If (CNameWin == "WorkerW")
	{
		Return True
	}

	WinGet, PNameWin, ProcessName, A
	WinGetTitle, TNameWin, A
	If (PNameWin == "lync.exe" OR (PNameWin == "vlc.exe" AND TNameWin ~= "Playlist") OR (PNameWin == "ApplicationFrameHost.exe" AND TNameWin ~= "Calculator"))
	{
		Return True
	}

	Return False
}

; Retrieves on which Monitor Number the Active Window is on
; Used to Move Window from Right to Left Monitors
WinCurntMon()
{
	SysGet, MonQty, MonitorCount
	WinGetPos, WinHrz, WinVrt, WinWdt, WinHgt, A
	WinHgtCtr := WinVrt + WinHgt / 2
	WinHrzCtr := WinHrz + WinWdt / 2

	Loop, %MonQty%
	{
		; If Center of Active Window is Located between defined Boundaries, Active Window is Located on Monitor #X
		If (WinHgtCtr >= Mon.Top[A_Index] AND WinHgtCtr <= Mon.Btm[A_Index] AND WinHrzCtr >= Mon.Lft[A_Index] AND WinHrzCtr <= Mon.Rgt[A_Index])
		{
			OnMonitor := A_Index
			; Once Matching Monitor Found, Stop the Search
			Break
		}
	}
	Return OnMonitor
}

CreateGUI() {
	global
	Gui, +AlwaysOnTop -Caption +Owner +LastFound +E0x20 +HWNDhGui_OSD
	Gui, Margin, 0, 0
	Gui, Color, 000000
	Gui, Font, c66FF66 s32 w400, Tahoma
	Gui, Add, Text, vOSDText Center Center
	WinSet, Transparent, 160
	Menu, Tray, Tip, WindowMappings
}

ShowOSD(OSDStr, Timeout, M := 0) {
	if (!DebugOSD) {
		Return
	}
	if (M = 0) {
		M := WinCurntMon()
	}

	text_w := Mon.Rgt[M] - Mon.Lft[M]
	text_w := Round( text_w/(A_ScreenDPI/96) )
	ctrlSize = w%text_w% h72
	GuiControl, 1:, OSDText, %OSDStr%
	GuiControl, 1:Move, OSDText, x0 y0 %ctrlSize%
	GuiControl, +0x201, OSDText
	gui_x := Mon.Lft[M]
	gui_y := Mon.Btm[M] - 144
	guiPos = x%gui_x% y%gui_y%
	if (M > 0 && gui_x >= 0 && gui_y >= 0 && text_w > 0) {
		Gui, 1:Show, NoActivate %guiPos% %ctrlSize%
		SetTimer, HideOSD, % Timeout
	} else {
		;SetTimer, Restart, % 5000
	}
}

HideOSD() {
	GuiControl, 1:, OSDText, % ""
	Gui, 1:Hide
}

; *******************************************************************************
; 		Automatic Mapping of All Monitors, Move & Resize Windows  -END-
; *******************************************************************************