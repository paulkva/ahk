; WxClockOSD v1.0 (2022-09-17)

#NoEnv
#SingleInstance force
#MaxHotkeysPerInterval 200
#KeyHistory 0
#include JSON.ahk
ListLines, Off
SetBatchLines, -1

global appVersion := "v1.0"
global AutoGuiW, BkColor, Bottom_OffsetX, Bottom_OffsetY, Bottom_Screen, Bottom_Win, DisplaySec, FixedX, FixedY
     , FontColor, FontName, FontSize, FontStyle, GuiHeight, GuiPosition, GuiWidth, SettingsGuiIsOpen
     , ShowModifierKeyCount, ShowMouseButton, ShowSingleKey, ShowSingleModifierKey, ShowStickyModKeyCount
     , Top_OffsetX, Top_OffsetY, Top_Screen, Top_Win, TransN, WxApiToken, WxLat, WxLon, WxUnits
     , oLast := {}, hGui_OSD, hGUI_s

ReadSettings()
CreateTrayMenu()
CreateGUI()
CreateHotkey()
GoSub, UpdateClock
GoSub, UpdateWx
return

#NumPadDiv::
ShowStatus:
{
	GuicontrolGet, WxClockInfo, Pos, WxClockText
	MsgBox Coordinates ( %WxClockInfoX% , %WxClockInfoY% ) Size ( %WxClockInfoW% x %WxClockInfoH% )
}

#^NumPadDiv::Reload

#if !SettingsGuiIsOpen
	UpdateClock:
		try {
			ShowClock()
			SetTimer, UpdateClock, % 100
		}
	return

	UpdateWx:
		try {
			ShowWx()
			SetTimer, UpdateWx, % 300000
		} catch e {
			MsgBox % "Error in " e.What ", line " e.Line " : " e.Message "`n" e.Extra
		}

	OnKeyUp:
	return

	_OnKeyUp:
		tickcount_start := A_TickCount
	return

; ===================================================================================
CreateGUI() {
	global

	Gui, +AlwaysOnTop -Caption +Owner +LastFound +E0x20 +HWNDhGui_OSD
	Gui, Margin, 0, 0
	Gui, Color, %BkColor%
	Gui, Font, c%FontColor% %FontStyle% s%FontSize%, %FontName%
	Gui, Add, Text, vWxClockText r3 Center Center
	Gui, Add, Picture, vWxImg x0 y0 h%GuiHeight% w-1, .\cache\01n.png
	WinSet, TransColor, %BkColor% 192

	GuiStr := "M/d/yyyy | ddd h:mm:ss tt`n100.0'F scattered clouds`nF:100.0 H:100.0 L:60.0"
	GuiControl, 1:, WxClockText, %GuiStr%
	GuiControl, 1:Show, WxClockText
	Gui, 1:Show, AutoSize NoActivate
	GuicontrolGet, WxClockInfo, Pos, WxClockText
	xPos := 50
	yPos := Round((GuiHeight - WxClockInfoH) / 2)
	width := WxClockInfoW - 50
	;MsgBox position is %WxClockInfoW% , %yPos%
	Gui, 1:Hide
	GuiControl, 1:Move, WxClockText, x%xPos% y%yPos% w%width%
	GuiControl, 1:Show, WxClockText
}

CreateHotkey() {
	Loop, 95
	{
		k := Chr(A_Index + 31)
		k := (k = " ") ? "Space" : k

		Hotkey, % "~*" k, UpdateClock
		Hotkey, % "~*" k " Up", _OnKeyUp
	}

	Loop, 24 ; F1-F24
	{
		Hotkey, % "~*F" A_Index, UpdateClock
		Hotkey, % "~*F" A_Index " Up", _OnKeyUp
	}

	Loop, 10 ; Numpad0 - Numpad9
	{
		Hotkey, % "~*Numpad" A_Index - 1, UpdateClock
		Hotkey, % "~*Numpad" A_Index - 1 " Up", _OnKeyUp
	}

	Otherkeys := "WheelDown|WheelUp|WheelLeft|WheelRight|XButton1|XButton2|Browser_Forward|Browser_Back|Browser_Refresh|Browser_Stop|Browser_Search|Browser_Favorites|Browser_Home|Volume_Mute|Volume_Down|Volume_Up|Media_Next|Media_Prev|Media_Stop|Media_Play_Pause|Launch_Mail|Launch_Media|Launch_App1|Launch_App2|Help|Sleep|PrintScreen|CtrlBreak|Break|AppsKey|NumpadDot|NumpadDiv|NumpadMult|NumpadAdd|NumpadSub|NumpadEnter|Tab|Enter|Esc|BackSpace"
	           . "|Del|Insert|Home|End|PgUp|PgDn|Up|Down|Left|Right|ScrollLock|CapsLock|NumLock|Pause|sc145|sc146|sc046|sc123"
	Loop, parse, Otherkeys, |
	{
		Hotkey, % "~*" A_LoopField, UpdateClock
		Hotkey, % "~*" A_LoopField " Up", _OnKeyUp
	}

	If ShowMouseButton {
		Loop, Parse, % "LButton|MButton|RButton", |
			Hotkey, % "~*" A_LoopField, UpdateClock
	}

	for i, mod in ["Ctrl", "Shift", "Alt"] {
		Hotkey, % "~*" mod, UpdateClock
		Hotkey, % "~*" mod " Up", OnKeyUp
	}
	for i, mod in ["LWin", "RWin"]
		Hotkey, % "~*" mod, UpdateClock
}

MouseHotkey_On() {
	Loop, Parse, % "LButton|MButton|RButton", |
		Hotkey, % "~*" A_LoopField, UpdateClock, On
}

MouseHotkey_Off() {
	Loop, Parse, % "LButton|MButton|RButton", |
		Hotkey, % "~*" A_LoopField, UpdateClock, Off
}

ShowClock() {
	FormatTime, ClockStr, , M/d/yyyy | ddd h:mm:ss tt
	if (ClockStr != oLast.ClockStr) {
		oLast.ClockStr := ClockStr
		UpdateWin()
	}
}

#^NumPadMult::
DebugWx:
{
	WxPrefix := "https://api.openweathermap.org/data/2.5/"
	WxQueryString = ?lat=%WxLat%&lon=%WxLon%&units=%WxUnits%&appid=%WxApiToken%

	Http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WxCurrentUrl = %WxPrefix%weather%WxQueryString%
	Http.Open("GET", WxCurrentUrl)
	Http.Send()
	MsgBox % Http.ResponseText
}

ShowWx() {
	WxPrefix := "https://api.openweathermap.org/data/2.5/"
	WxQueryString = ?lat=%WxLat%&lon=%WxLon%&units=%WxUnits%&appid=%WxApiToken%

	Http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WxCurrentUrl = %WxPrefix%weather%WxQueryString%
	Http.Open("GET", WxCurrentUrl)
	Http.Send()
	WxCurrent := JSON.Load(Http.ResponseText)
	img := WxCurrent.weather[1].icon
	imgUrl = http://openweathermap.org/img/wn/%img%.png
	imgFile := ".\cache\" . img . ".png"
	;MsgBox %imgUrl% `n %imgFile%

	if (!FileExist(".\cache\" . img . ".png")) {
		URLDownloadToFile, %imgUrl%, %imgFile%
	}
	GuiControl, 1:-Redraw, WxImg
	GuiControl,, WxImg, %imgFile%
	GuiControl, 1:+Redraw, WxImg
	GuiControl, 1:Move, WxImg, x0 y0

	;Http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	;WxForecastUrl = %WxPrefix%forecast%WxQueryString%
	;Http.Open("GET", WxForecastUrl)
	;Http.Send()
	;WxForecast := JSON.Load(Http.ResponseText)

	oLast.WxStr := Round(WxCurrent.main.temp, 1) . "'F " . WxCurrent.weather[1].description
	oLast.WxStr := oLast.WxStr . " | F:" . Round(WxCurrent.main.feels_like, 1)
	oLast.WxStr := oLast.WxStr . "`nL:" . Round(WxCurrent.main.temp_min, 1)
	oLast.WxStr := oLast.WxStr . " | H:" . Round(WxCurrent.main.temp_max, 1)
	oLast.WxStr := oLast.WxStr . " | W:" . Round(WxCurrent.wind.speed, 1) . "mph"

	UpdateWin()
}

UpdateWin() {
	GuiStr := oLast.ClockStr . "`n" . oLast.WxStr

	ActWin_X := (A_ScreenWidth - GuiWidth) / 2
	ActWin_Y := A_ScreenHeight - GuiHeight
	ActWin_W := GuiWidth
	ActWin_H := GuiHeight

	text_w := GuiWidth - 50
	text_w := Round(text_w/(A_ScreenDPI/96))
	text_h := GuiHeight
	text_h := Round(text_h/(A_ScreenDPI/96))
	ctrlSize = w%text_w% h%text_h%
	; ToolTip, % obj_print(oLast) "`n`n" ctrlSize "`n" oLast.ctrlSize
	if (ctrlSize != oLast.ctrlSize) {
		GuiControl, 1:Move, WxClockText, x50 %ctrlSize%
		oLast.ctrlSize := ctrlSize
	}

	text_w := GuiWidth
	text_w := Round(text_w/(A_ScreenDPI/96))
	ctrlSize = w%text_w% h%text_h%
	gui_x := ActWin_X + Bottom_OffsetX
	gui_y := (ActWin_Y+ActWin_H) - GuiHeight - Bottom_OffsetY
	guiPos = y%gui_y%

	GuiControl, 1:, WxClockText, %GuiStr%
	Gui, +AlwaysOnTop
	Gui, 1:Show, NoActivate %guiPos% %ctrlSize%
	oLast.guiPos := guiPos
}

GetKeyStr() {
	static modifiers := ["Ctrl", "Shift", "Alt", "LWin", "RWin"]
	static repeatCount := 1

	for i, mod in modifiers {
		if GetKeyState(mod)
			prefix .= mod " + "
	}

	if (!prefix && !ShowSingleKey)
		throw

	key := SubStr(A_ThisHotkey, 3)

	if (key ~= "i)^(Ctrl|Shift|Alt|LWin|RWin)$") {
		if !ShowSingleModifierKey {
			throw
		}
		key := ""
		prefix := RTrim(prefix, "+ ")

		if ShowModifierKeyCount {
			if !InStr(prefix, "+") && IsDoubleClickEx() {
				if (A_ThisHotKey != A_PriorHotKey) || ShowStickyModKeyCount {
					if (++repeatCount > 1) {
						prefix .= " ( * " repeatCount " )"
					}
				} else {
					repeatCount := 0
				}
			} else {
				repeatCount := 1
			}
		}
	} else {
		if ( StrLen(key) = 1 ) {
			key := GetKeyChar(key, "A")
		} else if ( SubStr(key, 1, 2) = "sc" ) {
			key := SpecialSC(key)
		} else if (key = "LButton") && IsDoubleClick() {
			key := "Double-Click"
		}
		_key := (key = "Double-Click") ? "LButton" : key

		static pre_prefix, pre_key, keyCount := 1
		global tickcount_start
		if (prefix && pre_prefix) && (A_TickCount-tickcount_start < 300) {
			if (prefix != pre_prefix) {
				result := pre_prefix pre_key ", " prefix key
			} else {
				keyCount := (key=pre_key) ? (keyCount+1) : 1
				key := (keyCount>2) ? (key " (" keyCount ")") : (pre_key ", " key)
			}
		} else {
			keyCount := 1
		}

		pre_prefix := prefix
		pre_key := _key

		repeatCount := 1
	}
	return result ? result : prefix . key
}

SpecialSC(sc) {
	static k := {sc046: "ScrollLock", sc145: "NumLock", sc146: "Pause", sc123: "Genius LuxeMate Scroll"}
	return k[sc]
}

; by Lexikos -- https://autohotkey.com/board/topic/110808-getkeyname-for-other-languages/#entry682236
GetKeyChar(Key, WinTitle:=0) {
	thread := WinTitle=0 ? 0
		: DllCall("GetWindowThreadProcessId", "ptr", WinExist(WinTitle), "ptr", 0)
	hkl := DllCall("GetKeyboardLayout", "uint", thread, "ptr")
	vk := GetKeyVK(Key), sc := GetKeySC(Key)
	VarSetCapacity(state, 256, 0)
	VarSetCapacity(char, 4, 0)
	n := DllCall("ToUnicodeEx", "uint", vk, "uint", sc
		, "ptr", &state, "ptr", &char, "int", 2, "uint", 0, "ptr", hkl)
	return StrGet(&char, n, "utf-16")
}

IsDoubleClick(MSec = 300) {
	Return (A_ThisHotKey = A_PriorHotKey) && (A_TimeSincePriorHotkey < MSec)
}

IsDoubleClickEx(MSec = 300) {
	preHotkey := RegExReplace(A_PriorHotkey, "i) Up$")
	Return (A_ThisHotKey = preHotkey) && (A_TimeSincePriorHotkey < MSec)
}

HideGUI() {
	if !SettingsGuiIsOpen {
		Gui, Hide
	}
	oLast := {}
}

; -------------------------------------------------------------------

ReadSettings() {
	IniFile := SubStr(A_ScriptFullPath, 1, -4) ".ini"

	IniRead, TransN               , %IniFile%, Settings, TransN               , 200
	IniRead, ShowSingleKey        , %IniFile%, Settings, ShowSingleKey        , 1
	IniRead, ShowMouseButton      , %IniFile%, Settings, ShowMouseButton      , 1
	IniRead, ShowSingleModifierKey, %IniFile%, Settings, ShowSingleModifierKey, 1
	IniRead, ShowModifierKeyCount , %IniFile%, Settings, ShowModifierKeyCount , 1
	IniRead, ShowStickyModKeyCount, %IniFile%, Settings, ShowStickyModKeyCount, 0
	IniRead, DisplaySec           , %IniFile%, Settings, DisplaySec           , 2
	IniRead, GuiPosition          , %IniFile%, Settings, GuiPosition          , Bottom
	IniRead, FontSize             , %IniFile%, Settings, FontSize             , 50
	IniRead, GuiWidth             , %IniFile%, Settings, GuiWidth             , %A_ScreenWidth%
	IniRead, GuiHeight            , %IniFile%, Settings, GuiHeight            , 115
	IniRead, BkColor              , %IniFile%, Settings, BkColor              , Black
	IniRead, FontColor            , %IniFile%, Settings, FontColor            , White
	IniRead, FontStyle            , %IniFile%, Settings, FontStyle            , w400
	IniRead, FontName             , %IniFile%, Settings, FontName             , Calibri
	IniRead, AutoGuiW             , %IniFile%, Settings, AutoGuiW             , 1
	IniRead, Bottom_Win           , %IniFile%, Settings, Bottom_Win           , 1
	IniRead, Bottom_Screen        , %IniFile%, Settings, Bottom_Screen        , 0
	IniRead, Bottom_OffsetX       , %IniFile%, Settings, Bottom_OffsetX       , 0
	IniRead, Bottom_OffsetY       , %IniFile%, Settings, Bottom_OffsetY       , 50
	IniRead, Top_Win              , %IniFile%, Settings, Top_Win              , 1
	IniRead, Top_Screen           , %IniFile%, Settings, Top_Screen           , 0
	IniRead, Top_OffsetX          , %IniFile%, Settings, Top_OffsetX          , 0
	IniRead, Top_OffsetY          , %IniFile%, Settings, Top_OffsetY          , 0
	IniRead, FixedX               , %IniFile%, Settings, FixedX               , 100
	IniRead, FixedY               , %IniFile%, Settings, FixedY               , 200
	IniRead, WxApiToken           , %IniFile%, Settings, WxApiToken           , 
	IniRead, WxLat                , %IniFile%, Settings, WxLat                , 38.89
	IniRead, WxLon                , %IniFile%, Settings, WxLon                , -77.01
	IniRead, WxUnits              , %IniFile%, Settings, WxUnits              , imperial
}

SaveSettings() {
	IniFile := SubStr(A_ScriptFullPath, 1, -4) ".ini"

	IniWrite, %TransN%               , %IniFile%, Settings, TransN
	IniWrite, %ShowSingleKey%        , %IniFile%, Settings, ShowSingleKey
	IniWrite, %ShowMouseButton%      , %IniFile%, Settings, ShowMouseButton
	IniWrite, %ShowSingleModifierKey%, %IniFile%, Settings, ShowSingleModifierKey
	IniWrite, %ShowModifierKeyCount% , %IniFile%, Settings, ShowModifierKeyCount
	IniWrite, %ShowStickyModKeyCount%, %IniFile%, Settings, ShowStickyModKeyCount
	IniWrite, %DisplaySec%           , %IniFile%, Settings, DisplaySec
	IniWrite, %GuiPosition%          , %IniFile%, Settings, GuiPosition
	IniWrite, %FontSize%             , %IniFile%, Settings, FontSize
	IniWrite, %GuiWidth%             , %IniFile%, Settings, GuiWidth
	IniWrite, %GuiHeight%            , %IniFile%, Settings, GuiHeight
	IniWrite, %BkColor%              , %IniFile%, Settings, BkColor
	IniWrite, %FontColor%            , %IniFile%, Settings, FontColor
	IniWrite, %FontStyle%            , %IniFile%, Settings, FontStyle
	IniWrite, %FontName%             , %IniFile%, Settings, FontName
	IniWrite, %AutoGuiW%             , %IniFile%, Settings, AutoGuiW
	IniWrite, %Bottom_Win%           , %IniFile%, Settings, Bottom_Win
	IniWrite, %Bottom_Screen%        , %IniFile%, Settings, Bottom_Screen
	IniWrite, %Bottom_OffsetX%       , %IniFile%, Settings, Bottom_OffsetX
	IniWrite, %Bottom_OffsetY%       , %IniFile%, Settings, Bottom_OffsetY
	IniWrite, %Top_Win%              , %IniFile%, Settings, Top_Win
	IniWrite, %Top_Screen%           , %IniFile%, Settings, Top_Screen
	IniWrite, %Top_OffsetX%          , %IniFile%, Settings, Top_OffsetX
	IniWrite, %Top_OffsetY%          , %IniFile%, Settings, Top_OffsetY
	IniWrite, %FixedX%               , %IniFile%, Settings, FixedX
	IniWrite, %FixedY%               , %IniFile%, Settings, FixedY
	IniWrite, %WxApiTokenm%          , %IniFile%, Settings, WxApiToken
	IniWrite, %WxLat%                , %IniFile%, Settings, WxLat
	IniWrite, %WxLon%                , %IniFile%, Settings, WxLon
	IniWrite, %WxUnits%              , %IniFile%, Settings, WxUnits
}

CreateTrayMenu() {
	Menu, Tray, Add
	Menu, Tray, Add, Settings, ShowSettingsGUI
	Menu, Tray, Add, About, ShowAboutGUI
	Menu, Tray, Default, Settings
	Menu, Tray, Tip, WxClockOSD
}

ToggleSuspend() {
	Suspend, Toggle
	Menu, Tray, ToggleCheck, Suspend
	Menu, Tray, Tip, % "WxClockOSD" (A_IsSuspended ? " - Suspended" : "")
}

ShowAboutGUI() {
	Gui, a:Font, s12 bold
	Gui, a:Add, Text, , WxClockOSD %appVersion%
	Gui, a:Add, Link, gOpenUrl, Based on <a>https://github.com/tmplinshi/KeypressOSD</a>
	Gui, a:Show,, About
	Return

	OpenUrl:
		Run, https://github.com/tmplinshi/KeypressOSD
	return
}

_ExitApp() {
	ExitApp
}

sGuiAddTitleText(text) {
	Gui, s:Font, s16
	Gui, s:Add, Text, xm y+20, %text%
	Gui, s:Font, s12
}

ShowSettingsGUI() {
	global

	SettingsGuiIsOpen := true

	Gui, s:Destroy
	Gui, s:+HWNDhGUI_s
	Gui, s:Font, s12

	Gui, s:Add, Text, xm, Transparency:
	Gui, s:Add, Text, x+10 w100 vTransNVal, %TransN%
	Gui, s:Add, Slider, xm+10 vTransN Range0-255 ToolTip gUpdateTransVal, %TransN%


	Gui, s:Add, Text, xm, Display
	Gui, s:Add, Edit, x+10 w80 Center vDisplaySec, %DisplaySec%
	Gui, s:Add, Text, x+10, Seconds

	Gui, s:Add, Checkbox, xm h24 vShowSingleKey Checked%ShowSingleKey%, Show Single Key
	Gui, s:Add, Checkbox, xm h24 vShowMouseButton Checked%ShowMouseButton%, Show Mouse Button
	Gui, s:Add, Checkbox, xm h24 vShowSingleModifierKey Checked%ShowSingleModifierKey%, Show Single Modifier Key
	Gui, s:Add, Checkbox, xm h24 vShowModifierKeyCount Checked%ShowModifierKeyCount%, Show Modifier Key Count
	Gui, s:Add, Checkbox, xm h24 vShowStickyModKeyCount Checked%ShowStickyModKeyCount%, Show Sticky Modifier Key Count

	sGuiAddTitleText("Window Position")
		Gui, s:Add, Tab3, xm y+10 Buttons vGuiPosition gUpdateGuiPosition, Bottom|Top|Fixed Position
		GuiControl, s:ChooseString, GuiPosition, |%GuiPosition%
		Gui, s:Tab, 1
			Gui, s:Add, Text, Section y+20, Relative To:
			Gui, s:Add, Radio, x+10 vBottom_Win Checked%Bottom_Win%, Active Window
			Gui, s:Add, Radio, x+20 vBottom_Screen Checked%Bottom_Screen%, Screen
			Gui, s:Add, Text, xs y+20, OffsetX
			Gui, s:Add, Edit, x+10 w80 vBottom_OffsetX Number gUpdateOSD, %Bottom_OffsetX%
			Gui, s:Add, UpDown, Range0-%A_ScreenWidth% 0x80 gUpdateOSD, %Bottom_OffsetX%
			Gui, s:Add, Text, x+50, OffsetY
			Gui, s:Add, Edit, x+10 w80 vBottom_OffsetY Number gUpdateOSD, %Bottom_OffsetY%
			Gui, s:Add, UpDown, Range0-%A_ScreenHeight% 0x80 gUpdateOSD, %Bottom_OffsetY%
		Gui, s:Tab, 2
			Gui, s:Add, Text, Section y+20, Relative To:
			Gui, s:Add, Radio, x+10 vTop_Win Checked%Top_Win%, Active Window
			Gui, s:Add, Radio, x+20 vTop_Screen Checked%Top_Screen%, Screen
			Gui, s:Add, Text, xs y+20, OffsetX
			Gui, s:Add, Edit, x+10 w80 vTop_OffsetX Number gUpdateOSD, 
			Gui, s:Add, UpDown, Range0-%A_ScreenWidth% 0x80 gUpdateOSD, %Top_OffsetX%
			Gui, s:Add, Text, x+50, OffsetY
			Gui, s:Add, Edit, x+10 w80 vTop_OffsetY Number gUpdateOSD, 
			Gui, s:Add, UpDown, Range0-%A_ScreenHeight% 0x80 gUpdateOSD, %Top_OffsetY%
		Gui, s:Tab, 3
			Gui, s:Add, Text, y+20, X
			Gui, s:Add, Edit, x+10 w80 vFixedX Number gUpdateOSD, %FixedX%
			Gui, s:Add, UpDown, Range0-%A_ScreenWidth% 0x80 gUpdateOSD, %FixedX%
			Gui, s:Add, Text, x+50, Y
			Gui, s:Add, Edit, x+10 w80 vFixedY Number gUpdateOSD, %FixedY%
			Gui, s:Add, UpDown, Range0-%A_ScreenHeight% 0x80 gUpdateOSD, %FixedY%
			Gui, s:Font, s10
			Gui, s:Add, Text, xs cGray, Input or drag the OSD window.
			Gui, s:Font, s12
		Gui, s:Tab

	sGuiAddTitleText("Window Size")
		Gui, s:Add, Text, xm, % " Width:"

		Gui, s:Add, Edit, x+10 w85 Center Number vGuiWidth gUpdateGuiWidth, %GuiWidth%
		Gui, s:Add, UpDown, Range10-4000 gUpdateGuiWidth 0x80 vGuiWUD, %GuiWidth%
		Gui, s:Add, Checkbox, x+30 vAutoGuiW Checked%AutoGuiW% g_AutoGuiW, Same As Active Window
		Gosub, _AutoGuiW

		Gui, s:Add, Text, xm, Height:
		Gui, s:Add, Edit, x+10 w85 Number Center vGuiHeight gUpdateGuiHeight, %GuiHeight%
		Gui, s:Add, UpDown, Range5-2000 gUpdateGuiHeight 0x80, %GuiHeight%

	Gui, s:Add, Button, xm y+20 gChangeBkColor, Change Background Color

	Gui, s:Add, Button, xm gChangeFont, Change Font
	Gui, s:Add, Button, x+50 gChangeFontColor, Change Font Color

	Gui, s:Add, Text, xm, Font Size:
	Gui, s:Add, Edit, x+10 w100 Number Center vFontSize gUpdateFontSize, %FontSize%
	Gui, s:Add, UpDown, Range1-1000 gUpdateFontSize 0x80, %fontSize%

	if (GuiPosition = "Fixed Position")
		OSD_EnableDrag()
	Gui, s:Show,, Settings - WxClockOSD

	ShowClock()
	SetTimer, HideGUI, Off
	return

	UpdateOSD:
		Gui, Submit, NoHide
		Gosub, _CheckValues
		ShowClock()
	return

	_CheckValues:
		Loop, Parse, % "Bottom_OffsetX,Bottom_OffsetY,Top_OffsetX,Top_OffsetY,FixedX,FixedY", `,
		{
			if (%A_LoopField% = "") {
				%A_LoopField% := 0
			}
		}
	return

	_AutoGuiW:
		; GuiControlGet, AutoGuiW, s:
		Gui, Submit, NoHide
		GuiControl, % "s:Enable" !AutoGuiW, GuiWidth
		GuiControl, % "s:Enable" !AutoGuiW, GuiWUD
		ShowClock()
		GuiControl, 1:+Redraw, WxClockText
	return

	UpdateGuiPosition:
		oLast := {}
		Gui, Submit, NoHide
		ShowClock()

		if (GuiPosition = "Fixed Position")
			OSD_EnableDrag()
		else
			OSD_DisableDrag()
	return

	UpdateGuiWidth:
		GuiControlGet, newW,, GuiWidth
		if newW {
			GuiWidth := newW
			ShowClock()
		}
	return

	UpdateGuiHeight:
		GuiControlGet, newH,, GuiHeight
		if newH {
			GuiHeight := newH
			ShowClock()
		}
	return

	UpdateTransVal:
		GuiControlGet, TransN
		GuiControl,, TransNVal, % TransN

		Gui, 1:+LastFound
		WinSet, Transparent, %TransN%
	return

	UpdateFontSize:
		GuiControlGet, FontSize
		Gui, 1:Font, s%FontSize%
		GuiControl, 1:Font, WxClockText
	return

	sGuiClose:
	sGuiEscape:
		FontSize_pre := FontSize

		Gui, s:Submit
		Gosub, _CheckValues

		ShowMouseButton ? MouseHotkey_On() : MouseHotkey_Off()

		if (FontSize_pre != FontSize) {
			Gui, 1:Font, s%FontSize%
			GuiControl, 1:Font, WxClockText
		}

		if !GuiHeight
			GuiHeight := 115

		SaveSettings()
		Gui, s:Destroy
		Gui, 1:Hide
		OSD_DisableDrag()
		SettingsGuiIsOpen := ""
	return

	ChangeBkColor:
		newColor := BkColor
		if Select_Color(hGUI_s, newColor) {
			Gui, 1:Color, %newColor%
			ShowClock()
			SetTimer, HideGUI, Off
			BkColor := newColor
		}
	return

	ChangeFontColor:
		newColor := FontColor
		if Select_Color(hGUI_s, newColor) {
			Gui, 1:Font, c%newColor%
			GuiControl, 1:Font, WxClockText
			ShowClock()
			SetTimer, HideGUI, Off
			FontColor := newColor
		}
	return

	ChangeFont:
		fStyle := FontStyle " s" FontSize
		fName  := FontName
		fColor := FontColor

		if Select_Font(hGUI_s, fStyle, fName, fColor) {
			FontStyle := fStyle
			FontName := fName
			FontColor := fColor
			if RegExMatch(FontStyle, "\bs\K\d+", FontSize) {
				FontStyle := RegExReplace(FontStyle, "\bs\d+")
				GuiControl,, FontSize, %FontSize%
			}

			Gui, 1:Font
			Gui, 1:Font, %fStyle% c%FontColor%, %fName%
			GuiControl, 1:Font, WxClockText
			ShowClock()
			SetTimer, HideGUI, Off
		}
	return
}


WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
	static hCursor := DllCall("LoadCursor", "Uint", 0, "Int", 32646, "Ptr") ; SizeAll = 32646

	if (hwnd = hGui_OSD) {
		PostMessage, 0xA1, 2
		DllCall("SetCursor", "ptr", hCursor)
	}
}

WM_MOVE(wParam, lParam, msg, hwnd) {
	if (hwnd = hGui_OSD) && GetKeyState("LButton", "P")
	{
		GuiControl, s:, FixedX, % lParam << 48 >> 48
		GuiControl, s:, FixedY, % lParam << 32 >> 48
	}
}

OSD_EnableDrag() {
	OnMessage(0x0201, "WM_LBUTTONDOWN")
	OnMessage(0x0003, "WM_MOVE")
	Gui, 1:-E0x20
}

OSD_DisableDrag() {
	OnMessage(0x0201, "")
	OnMessage(0x0003, "")
	Gui, 1:+E0x20
}


; https://autohotkey.com/boards/viewtopic.php?p=112730#p112730
;-------------------------------------------------------------------------------
Select_Font(hGui, ByRef Style, ByRef Name, ByRef Color) { ; using comdlg32.dll
;-------------------------------------------------------------------------------
    static SubKey := "SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontDPI"


    ;-----------------------------------
    ; LOGFONT structure
    ;-----------------------------------
    VarSetCapacity(LOGFONT, 128, 0)

    If RegExMatch(Style, "s\K\d+", s) {
        RegRead, LogPixels, HKLM, %SubKey%, LogPixels
        NumPut(s * LogPixels // 72, LOGFONT, 0, "Int")
    }

    If RegExMatch(Style, "w\K\d+", w)
        NumPut(w, LOGFONT, 16, "Int")

    If InStr(Style, "italic")
        NumPut(255, LOGFONT, 20, "Int")

    If InStr(Style, "underline")
        NumPut(1, LOGFONT, 21, "Int")

    If InStr(Style, "strikeout")
        NumPut(1, LOGFONT, 22, "Int")

    StrPut(Name, &LOGFONT + 28, StrLen(Name) + 1)


    ;-----------------------------------
    ; CHOOSEFONT structure
    ;-----------------------------------

    ; CHOOSEFONT structure expects text color in BGR format
    BGR := convert_Color(Color)

    If (A_PtrSize = 8) { ; 64 bit
        VarSetCapacity(CHOOSEFONT, 104, 0)
        NumPut(     104, CHOOSEFONT,  0, "UInt") ; StructSize
        NumPut(    hGui, CHOOSEFONT,  8, "UInt") ; hwndOwner
        NumPut(&LOGFONT, CHOOSEFONT, 24, "UInt") ; lpLogFont
        NumPut(   0x141, CHOOSEFONT, 36, "UInt") ; Flags
        NumPut(     BGR, CHOOSEFONT, 40, "UInt") ; bgrColor
    }

    Else { ; 32 bit
        VarSetCapacity(CHOOSEFONT, 60, 0)
        NumPut(      60, CHOOSEFONT,  0, "UInt") ; StructSize
        NumPut(    hGui, CHOOSEFONT,  4, "UInt") ; hwndOwner
        NumPut(&LOGFONT, CHOOSEFONT, 12, "UInt") ; lpLogFont
        NumPut(   0x141, CHOOSEFONT, 20, "UInt") ; Flags
        NumPut(     BGR, CHOOSEFONT, 24, "UInt") ; bgrColor
    }


    ;-----------------------------------
    ; call ChooseFont function
    ;-----------------------------------
    FuncName := "comdlg32\ChooseFont" (A_IsUnicode ? "W" : "A")
    If Not DllCall(FuncName, "UInt", &CHOOSEFONT)
        Return, False


    ;-----------------------------------
    ; results to return
    ;-----------------------------------

    ; style
    Style := "s" NumGet(CHOOSEFONT, A_PtrSize = 8 ? 32 : 16, "Int") // 10
    Style .= " w" NumGet(LOGFONT, 16)
    If NumGet(LOGFONT, 20, "UChar")
        Style .= " italic"
    If NumGet(LOGFONT, 21, "UChar")
        Style .= " underline"
    If NumGet(LOGFONT, 22, "UChar")
        Style .= " strikeout"

    ; name
    Name := StrGet(&LOGFONT + 28)

    ; chosen color
    RGB := convert_Color(NumGet(CHOOSEFONT, A_PtrSize = 8 ? 40 : 24, "UInt"))
    Color := SubStr("0x00000", 1, 10 - StrLen(RGB)) SubStr(RGB, 3)
    Return, True
}



;-------------------------------------------------------------------------------
Select_Color(hGui, ByRef Color) { ; using comdlg32.dll
;-------------------------------------------------------------------------------

    ; CHOOSECOLOR structure expects text color in BGR format
    BGR := convert_Color(Color)

    ; unused, but a valid pointer to the structure
    VarSetCapacity(CUSTOM, 64, 0)


    ;-----------------------------------
    ; CHOOSECOLOR structure
    ;-----------------------------------

    If (A_PtrSize = 8) { ; 64 bit
        VarSetCapacity(CHOOSECOLOR, 72, 0)
        NumPut(     72, CHOOSECOLOR,  0) ; StructSize
        NumPut(   hGui, CHOOSECOLOR,  8) ; hwndOwner
        NumPut(    BGR, CHOOSECOLOR, 24) ; bgrColor
        NumPut(&CUSTOM, CHOOSECOLOR, 32) ; lpCustColors
        NumPut(  0x103, CHOOSECOLOR, 40) ; Flags
    }

    Else { ; 32 bit
        VarSetCapacity(CHOOSECOLOR, 36, 0)
        NumPut(     36, CHOOSECOLOR,  0) ; StructSize
        NumPut(   hGui, CHOOSECOLOR,  4) ; hwndOwner
        NumPut(    BGR, CHOOSECOLOR, 12) ; bgrColor
        NumPut(&CUSTOM, CHOOSECOLOR, 16) ; lpCustColors
        NumPut(  0x103, CHOOSECOLOR, 20) ; Flags
    }


    ;-----------------------------------
    ; call ChooseColorA function
    ;-----------------------------------

    If Not DllCall("comdlg32\ChooseColorA", "UInt", &CHOOSECOLOR)
        Return, False


    ;-----------------------------------
    ; result to return
    ;-----------------------------------

    ; chosen color
    RGB := convert_Color(NumGet(CHOOSECOLOR, A_PtrSize = 8 ? 24 : 12, "UInt"))
    Color := SubStr("0x00000", 1, 10 - StrLen(RGB)) SubStr(RGB, 3)
    Return, True
}



;-------------------------------------------------------------------------------
convert_Color(Color) { ; convert RGB <--> BGR
;-------------------------------------------------------------------------------
    $_FormatInteger := A_FormatInteger
    SetFormat, Integer, Hex
    Result := (Color & 0xFF) << 16 | Color & 0xFF00 | (Color >> 16) & 0xFF
    SetFormat, Integer, % $_FormatInteger
    Return, Result
}

JsonToAHK(json, rec := false) {
   static doc := ComObjCreate("htmlfile")
         , __ := doc.write("<meta http-equiv=""X-UA-Compatible"" content=""IE=9"">")
         , JS := doc.parentWindow
   if !rec
      obj := JsonToAHK(JS.eval("(" . json . ")"), true)
   else if !IsObject(json)
      obj := json
   else if json.toString() != "[object Object]" {
      obj := []
      Loop % json.length
         obj.Push( JsonToAHK(json[A_Index - 1], true) )
   }
   else {
      obj := {}
      keys := JS.Object.keys(json)
      Loop % keys.length {
         k := keys[A_Index - 1]
         obj[k] := JsonToAHK(json[k], true)
      }
   }
   Return obj
}