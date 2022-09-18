; *********************************************************************************
; 		Automatic Mapping of All Monitors, Move & Resize Windows  -START-
; *********************************************************************************

; Initialization of Arrays used
; Variables used for Temporary Monitor Number used to later organize Monitors in Ascending Order
; (1D Arrays)
MonTopTemp := []
MonBtmTemp := []
MonLftTemp := []
MonRgtTemp := []

; Variables used for Definitive Monitor Number in Ascending Order
; (1D Arrays)
Mon := {}
Mon.Top := []
Mon.Btm := []
Mon.Lft := []
Mon.Rgt := []

; Variables used for Row Alignment with Bottom of Monitors
MonDIMBtmT := []

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
	; Options to Define Rows with Bottom of Monitors are Indicated Further in the Script
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
	; ******************************************************************
; Option ➔ Bottom of Row Alignment / Put in Comments the Line above
; Loop, %RowBtmQty%
; ******************************************************************
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
				; *********************************************************************************************************************
			; Option ➔ Bottom of Row Alignment / Put in Comments the Line above
			; If (ColValues[ColPosA_Index] == MonLftTemp[MonNrA_Index] AND RowBtmValues[RowPosA_Index] == MonDIMBtmT[MonNrA_Index])
			; *********************************************************************************************************************
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

;MsgBox, Ready!

; NumPad1 :: Bottom Left 50% / 67% / 80%
#^NumPad1::SnapWin(Mon,0,50,50,50)
#!NumPad1::SnapWin(Mon,0,33,67,67)
#^!NumPad1::SnapWin(Mon,0,20,80,80)
NumPadEnter & Numpad1::SnapWinPad(Mon, [0,0,0], [50,33,20], [50,67,80], [50,67,80])

; NumPad2 :: Bottom 50% / 67% / 80%
#^NumPad2::SnapWin(Mon,0,50,100,50)
#!NumPad2::SnapWin(Mon,0,33,100,67)
#^!NumPad2::SnapWin(Mon,0,20,100,80)
NumPadEnter & Numpad2::SnapWinPad(Mon, [0,0,0], [50,33,20], [100,100,100], [50,67,80])

; NumPad3 :: Bottom Right 50% / 67% / 80%
#^NumPad3::SnapWin(Mon,50,50,50,50)
#!NumPad3::SnapWin(Mon,33,33,67,67)
#^!NumPad3::SnapWin(Mon,20,20,80,80)
NumPadEnter & Numpad3::SnapWinPad(Mon, [50,33,20], [50,33,20], [50,67,80], [50,67,80])

; NumPad4 :: Left 50% / 67% / 80%
#^NumPad4::SnapWin(Mon,0,0,50,100)
#!NumPad4::SnapWin(Mon,0,0,67,100)
#^!NumPad4::SnapWin(Mon,0,0,80,100)
NumPadEnter & Numpad4::SnapWinPad(Mon, [0,0,0], [0,0,0], [50,67,80], [100,100,100])

; NumPad5 :: Middle 50% / 80% / 100% (but not maximized)
#^NumPad5::SnapWin(Mon,25,25,50,50)
#!NumPad5::SnapWin(Mon,10,10,80,80)
#^!NumPad5::SnapWin(Mon,0,0,100,100)
NumPadEnter & Numpad5::SnapWinPad(Mon, [25,10,0], [25,10,0], [50,80,100], [50,80,100])

; NumPad6 :: Right 50% / 67% / 80%
#^NumPad6::SnapWin(Mon,50,0,50,100)
#!NumPad6::SnapWin(Mon,33,0,67,100)
#^!NumPad6::SnapWin(Mon,20,0,80,100)
NumPadEnter & Numpad6::SnapWinPad(Mon, [50,33,20], [0,0,0], [50,67,80], [100,100,100])

; NumPad7 :: Top Left 50% / 67% / 80%
#^NumPad7::SnapWin(Mon,0,0,50,50)
#!NumPad7::SnapWin(Mon,0,0,67,67)
#^!NumPad7::SnapWin(Mon,0,0,80,80)
NumPadEnter & Numpad7::SnapWinPad(Mon, [0,0,0], [0,0,0], [50,67,80], [50,67,80])

; NumPad8 :: Top 50% / 67% / 80%
#^NumPad8::SnapWin(Mon,0,0,100,50)
#!NumPad8::SnapWin(Mon,0,0,100,67)
#^!NumPad8::SnapWin(Mon,0,0,100,80)
NumPadEnter & Numpad8::SnapWinPad(Mon, [0,0,0], [0,0,0], [100,100,100], [50,67,80])

; NumPad9 :: Top Right 50% / 67% / 80%
#^NumPad9::SnapWin(Mon,50,0,50,50)
#!NumPad9::SnapWin(Mon,33,0,67,67)
#^!NumPad9::SnapWin(Mon,20,0,80,80)
NumPadEnter & Numpad9::SnapWinPad(Mon, [50,33,20], [0,0,0], [50,67,80], [50,67,80])

; Right :: 100% on current monitor plus extend right 125% / 150% / 175%
#^Right::SnapWin(Mon,0,0,125,100)
#!Right::SnapWin(Mon,0,0,150,100)
#^!Right::SnapWin(Mon,0,0,175,100)
NumPadEnter & Right::SnapWinPad(Mon, [0,0,0], [0,0,0], [125,150,175], [100,100,100])

NumPadEnter & NumPadSub::ShiftAltTab
NumPadEnter & NumPadAdd::AltTab

NumPadEnter & NumPadDiv::Reload

; Let NumPadEnter by itself still work
NumPadEnter::Send {NumPadEnter}

; Ability to disable NumPadEnter combinations
NumPadEnter & NumPad0::
ToggleNumPadEnter:
{
	Hotkey, NumPadEnter & NumPad1, Toggle
	Hotkey, NumPadEnter & NumPad2, Toggle
	Hotkey, NumPadEnter & NumPad3, Toggle
	Hotkey, NumPadEnter & NumPad4, Toggle
	Hotkey, NumPadEnter & NumPad5, Toggle
	Hotkey, NumPadEnter & NumPad6, Toggle
	Hotkey, NumPadEnter & NumPad7, Toggle
	Hotkey, NumPadEnter & NumPad8, Toggle
	Hotkey, NumPadEnter & NumPad9, Toggle
	Hotkey, NumPadEnter & Right, Toggle
	Hotkey, NumPadEnter & NumPadSub, Toggle
	Hotkey, NumPadEnter & NumPadAdd, Toggle
	Return
}

; Additional symbols on the keyboard with Ctrl+Win
#^'::°
#^.::•
#^[::«
#^]::»
#^-::±
#^=::≠
#^+,::≤
#^+.::≥
#^+`::≈
#^8::∞
#^/::÷
#^+4::¢

; Allow for NumPadEnter to function similar to the Windows key for SnapWin
; in a virtual environment that doesn't detect actual Windows keypresses
SnapWinPad(Mon, LeftPct, TopPct, WdtPct, HgtPct)
{
	If (GetKeyState("Control") AND GetKeyState("Alt"))
	{
		Return SnapWin(Mon, LeftPct[3], TopPct[3], WdtPct[3], HgtPct[3])
	}
	If (GetKeyState("Alt"))
	{
		Return SnapWin(Mon, LeftPct[2], TopPct[2], WdtPct[2], HgtPct[2])
	}
	If (GetKeyState("Control"))
	{
		Return SnapWin(Mon, LeftPct[1], TopPct[1], WdtPct[1], HgtPct[1])
	}
}

; Main function to resize and snap a window to a corner or edge
SnapWin(Mon, LftPct = 0, TopPct = 0, WdtPct = 100, HgtPct = 100, ExtraKeys = 0)
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
	Win := PrepWin(Mon)

	MonWdt := Mon.Rgt[Win.M] - Mon.Lft[Win.M]
	MonHgt := Mon.Btm[Win.M] - Mon.Top[Win.M]

	TgtLft := Mon.Lft[Win.M] + Floor(MonWdt * LftPct / 100) + Win.CF.Hrz
	TgtTop := Mon.Top[Win.M] + Floor(MonHgt * TopPct / 100)
	TgtWdt := Floor(MonWdt * WdtPct / 100) + Win.CF.Wdt
	TgtHgt := Floor(MonHgt * HgtPct / 100) + Win.CF.Hgt

	WinMove, A, , TgtLft, TgtTop, TgtWdt, TgtHgt
	Return
}

#^+Up::
ExtendToTopEdge:
{
	If (IgnorePrgrm())
	{
		Return
	}
	Win := PrepWin(Mon)

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
	Win := PrepWin(Mon)

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
	Win := PrepWin(Mon)

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
	Win := PrepWin(Mon)

	TgtWdt := Mon.Rgt[Win.M] - Win.Lft
	WinMove, A, , Win.Lft, Win.Top, TgtWdt, Win.Hgt
	Return
}

PrepWin(Mon)
{
	; Retrieve Coordinates, Dimensions, Min/Max State, Process Name and Title of Active Window
	WinGetPos, WinLft, WinTop, WinWdt, WinHgt, A
	WinGet, WinMMax, MinMax, A

	Win := {}
	Win.Lft := WinLft
	Win.Top := WinTop
	Win.Wdt := WinWdt
	Win.Hgt := WinHgt

	; Add Correction Factor per Program + Find in which Monitor Active Window is located
	Win.CF := CrctnFctr()
	; Retrieves on which Monitor Number the Active Window is on
	Win.M := WinCurntMon(Mon)

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
	If PNameWin in code.exe,spotify.exe,outlook.exe,lync.exe,winword.exe,excel.exe,revu.exe,teams.exe
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
WinCurntMon(Mon)
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

; *******************************************************************************
; 		Automatic Mapping of All Monitors, Move & Resize Windows  -END-
; *******************************************************************************