; WxClockOSD v1.0 (2022-09-17)
; Optimized to show in the middle of a 48px-high taskbar at the bottom of the screen
; Make sure to save this file as UTF-8 with BOM, otherwise AHK mangles the ° symbols

#NoEnv
#SingleInstance force
#include JSON.ahk
ListLines, Off
SetBatchLines, -1

global appVersion := "v1.0"
global BkColor, Bottom_OffsetX, Bottom_OffsetY, Bottom_Screen, Bottom_Win, FixedX, FixedY
     , FontColor, FontName, FontSize, FontStyle, GuiHeight, GuiPosition, GuiWidth
     , Top_OffsetX, Top_OffsetY, Top_Screen, Top_Win, TransN, TransBk
	 , WxApiToken, WxLat, WxLon, WxUnits, WxUpdateInterval, WxPrecision, WxOneCall, WxWind
     , oLast := {}, hGui_OSD, hGUI_s

ReadSettings()
CreateTrayMenu()
CreateGUI()
GoSub, ShowClock
GoSub, ShowWx
return

#NumPadDiv::
DebugSize:
{
	GuicontrolGet, WxClockInfo, Pos, WxClockText
	MsgBox Coordinates ( %WxClockInfoX% , %WxClockInfoY% ) Size ( %WxClockInfoW% x %WxClockInfoH% )
}

#^NumPadDiv::Reload

ShowClock:
try {
	if (A_TimeIdle < WxUpdateInterval) {
		UpdateClock()
		SetTimer, UpdateClock, % 100
	} else {
		; When idle: hide the display, don't try to update as often, and
		; mark the weather info with ~ to indicate it might be outdated.
		GuiControl, 1:Hide, WxImg
		Gui, 1:Hide
		if (SubStr(oLast.WxStr1, 1, 1) = "~") {
		} else {
			oLast.WxStr1 := "~ " . oLast.WxStr1 . " ~"
		}
		SetTimer, ShowClock, % 5000
	}
}
return

ShowWx:
try {
	if (WxUpdateInterval < 60000) WxUpdateInterval := 60000
	if (A_TimeIdle < WxUpdateInterval) {
		UpdateWx()
	}
	SetTimer, ShowWx, % WxUpdateInterval
} catch e {
	MsgBox % "Error in " e.What ", line " e.Line " : " e.Message "`n" e.Extra
}
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
	if (TransBk = 1) {
		WinSet, TransColor, %BkColor% %TransN%
	} else {
		WinSet, Transparent, %TransN%
	}

	GuiStr := "h:mm:ss tt | ddd M/d/yyyy`n100.0°F scattered clouds | Feel: 103.0°`nL:60.0° | H:102.0° | W:12.3mph WSW"
	GuiControl, 1:, WxClockText, %GuiStr%
	GuiControl, 1:Show, WxClockText
	Gui, 1:Show, AutoSize NoActivate
	GuicontrolGet, WxClockInfo, Pos, WxClockText
	xPos := GuiHeight
	yPos := Round((GuiHeight - WxClockInfoH) / 2)
	width := WxClockInfoW - GuiHeight
	;MsgBox position is %WxClockInfoW% , %yPos%
	Gui, 1:Hide
	GuiControl, 1:Move, WxClockText, x%xPos% y%yPos% w%width%
	GuiControl, 1:Show, WxClockText
}

UpdateClock() {
	FormatTime, ClockStr,, h:mm:ss tt | ddd M/d/yyyy
	if (ClockStr != oLast.ClockStr) {
		oLast.ClockStr := ClockStr
		UpdateWin()
	}
}

#NumPadMult::
DebugWx:
{
	WxPrefix := "https://api.openweathermap.org/data/"
	WxQueryString = ?lat=%WxLat%&lon=%WxLon%&units=%WxUnits%&appid=%WxApiToken%

	Http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WxUrl = %WxPrefix%2.5/weather%WxQueryString%
	Http.Open("GET", WxUrl)
	Http.Send()
	MsgBox % Http.ResponseText

	Http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WxUrl = %WxPrefix%2.5/forecast%WxQueryString%
	Http.Open("GET", WxUrl)
	Http.Send()
	MsgBox % Http.ResponseText

	Http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WxUrl = %WxPrefix%3.0/onecall%WxQueryString%
	Http.Open("GET", WxUrl)
	Http.Send()
	MsgBox % Http.ResponseText

	Return
}

UpdateWx() {
	WxPrefix := "https://api.openweathermap.org/data/"
	WxQueryString = ?lat=%WxLat%&lon=%WxLon%&units=%WxUnits%&appid=%WxApiToken%

	Http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	if (WxOneCall = 1) {
		WxUrl = %WxPrefix%3.0/onecall%WxQueryString%
	} else {
		WxUrl = %WxPrefix%2.5/weather%WxQueryString%
	}
	Http.Open("GET", WxUrl)
	Http.Send()
	WxResponse := JSON.Load(Http.ResponseText)

	Wx := {}
	if (WxOneCall = 1) {
		Wx.img := WxResponse.current.weather[1].icon
		Wx.cond := WxResponse.current.weather[1].description
		Wx.temp := WxResponse.current.temp
		Wx.feel := WxResponse.current.feels_like
		Wx.min := WxResponse.daily[1].temp.min
		Wx.max := WxResponse.daily[1].temp.max
		Wx.wspeed := WxResponse.current.wind_speed
		Wx.wdir := WxResponse.current.wind_deg
	} else {
		Wx.img := WxResponse.weather[1].icon
		Wx.cond := WxResponse.weather[1].description
		Wx.temp := WxResponse.main.temp
		Wx.feel := WxResponse.main.feels_like
		Wx.min := WxResponse.main.temp_min
		Wx.max := WxResponse.main.temp_max
		Wx.wspeed := WxResponse.wind.speed
		Wx.wdir := WxResponse.wind.deg
	}

	;MsgBox % JSON.Dump(Wx) " OneCall=" WxOneCall "`n" JSON.Dump(WxResponse)

	; TODO: change °F and mph based on WxUnits setting
	; TODO: var by onecall
	oLast.WxStr1 := Round(Wx.temp, WxPrecision) . "°F " . Wx.cond
	if (Abs(Wx.temp - Wx.feel) > 1) {
		oLast.WxStr1 := oLast.WxStr1 . " | Feel: " . Round(Wx.feel, WxPrecision) . "°"
	}	
	oLast.WxStr2 := "L:" . Round(Wx.min, WxPrecision)
	oLast.WxStr2 := oLast.WxStr2 . "° | H:" . Round(Wx.max, WxPrecision)
	oLast.WxStr2 := oLast.WxStr2 . "° | W:" . Round(Wx.wspeed, WxPrecision) . "mph "
	wdir := WxWind[Round(Wx.wdir / 22.5) + 1]
	oLast.WxStr2 := oLast.WxStr2 . wdir

	imgFile := ".\cache\" . Wx.img . ".png"
	if (!FileExist(".\cache\" . Wx.img . ".png")) {
		imgUrl := "http://openweathermap.org/img/wn/" . Wx.img . ".png"
		URLDownloadToFile, %imgUrl%, %imgFile%
	}
	GuiControl, 1:-Redraw, WxImg
	GuiControl,, WxImg, %imgFile%
	GuiControl, 1:+Redraw, WxImg
	GuiControl, 1:Move, WxImg, x0 y0
	GuiControl, 1:Show, WxImg

	UpdateWin()
}

UpdateWin() {
	GuiStr := oLast.ClockStr . "`n" . oLast.WxStr1 . "`n" . oLast.WxStr2

	; TODO: re-introduce positioning other than bottom center
	ActWin_X := (A_ScreenWidth - GuiWidth) / 2
	ActWin_Y := A_ScreenHeight - GuiHeight
	ActWin_W := GuiWidth
	ActWin_H := GuiHeight

	text_w := GuiWidth - GuiHeight
	text_w := Round(text_w/(A_ScreenDPI/96))
	text_h := GuiHeight
	text_h := Round(text_h/(A_ScreenDPI/96))
	ctrlSize = w%text_w% h%text_h%
	; ToolTip, % obj_print(oLast) "`n`n" ctrlSize "`n" oLast.ctrlSize
	if (ctrlSize != oLast.ctrlSize) {
		GuiControl, 1:Move, WxClockText, x%GuiHeight% %ctrlSize%
		oLast.ctrlSize := ctrlSize
	}

	text_w := GuiWidth
	text_w := Round(text_w/(A_ScreenDPI/96))
	ctrlSize = w%text_w% h%text_h%
	gui_x := ActWin_X + Bottom_OffsetX
	gui_y := (ActWin_Y+ActWin_H) - GuiHeight - Bottom_OffsetY
	guiPos = x%gui_x% y%gui_y%

	GuiControl, 1:, WxClockText, %GuiStr%
	Gui, +AlwaysOnTop
	Gui, 1:Show, NoActivate %guiPos% %ctrlSize%
	oLast.guiPos := guiPos
}

HideGUI() {
	Gui, Hide
	oLast := {}
}

; -------------------------------------------------------------------

ReadSettings() {
	IniFile := SubStr(A_ScriptFullPath, 1, -4) ".ini"

	IniRead, TransBk              , %IniFile%, Settings, TransBk              , 1
	IniRead, TransN               , %IniFile%, Settings, TransN               , 200
	IniRead, GuiPosition          , %IniFile%, Settings, GuiPosition          , Bottom
	IniRead, FontSize             , %IniFile%, Settings, FontSize             , 50
	IniRead, GuiWidth             , %IniFile%, Settings, GuiWidth             , %A_ScreenWidth%
	IniRead, GuiHeight            , %IniFile%, Settings, GuiHeight            , 115
	IniRead, BkColor              , %IniFile%, Settings, BkColor              , Black
	IniRead, FontColor            , %IniFile%, Settings, FontColor            , White
	IniRead, FontStyle            , %IniFile%, Settings, FontStyle            , w400
	IniRead, FontName             , %IniFile%, Settings, FontName             , Calibri
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
	IniRead, WxUpdateInterval     , %IniFile%, Settings, WxUpdateInterval     , 300000
	IniRead, WxPrecision          , %IniFile%, Settings, WxPrecision          , 0
	IniRead, WxOneCall            , %IniFile%, Settings, WxOneCall            , 1

	WxWind := ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N"]
}

CreateTrayMenu() {
	Menu, Tray, Add
	Menu, Tray, Add, About, ShowAboutGUI
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
	Gui, a:Add, Link, gOpenUrl, WxClockOSD, based on <a>https://github.com/tmplinshi/KeypressOSD</a>
	Gui, a:Show,, About
	Return

	OpenUrl:
		Run, https://github.com/tmplinshi/KeypressOSD
	return
}

_ExitApp() {
	ExitApp
}
