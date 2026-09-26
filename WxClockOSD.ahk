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
     , FontColor, FontName, FontSize, FontStyle, GuiHeight, GuiPosition, GuiWidth, OutColor
     , OutlineText, Top_OffsetX, Top_OffsetY, Top_Screen, Top_Win, TransN, TransBk, WxEnabled
	 , WxApiToken, WxLat, WxLon, WxUnits, WxUpdateInterval, WxPrecision, WxOneCall, WxWind
     , oLast := {}, hGui_OSD, hGUI_s, ImgIndex := 1, ImgSuffix := "d", LastMinuteSeen := "", LastSeconds := ""

ReadSettings()
CreateTrayMenu()
CreateGUI()
UpdateWx()
GoSub, ShowClock
GoSub, ShowWx

OnMessage(0x7E, "WM_DISPLAYCHANGE")

WM_DISPLAYCHANGE(wParam, lParam) {
	SetTimer, Restart, % 5000
}

Restart() {
	Reload
	Sleep % 1000
	ExitApp
}

return

#NumPadDiv::
DebugSize:
{
	GuicontrolGet, WxClockInfo1, Pos, WxClockText1
	GuicontrolGet, WxClockInfo2, Pos, WxClockText2
	MsgBox 1 Coordinates ( %WxClockInfo1X% , %WxClockInfo1Y% ) 1 Size ( %WxClockInfo1W% x %WxClockInfo1H% ) `n 2 Coordinates ( %WxClockInfo2X% , %WxClockInfo2Y% ) 2 Size ( %WxClockInfo2W% x %WxClockInfo2H% )
}

#^NumPadDiv::Reload

ShowClock:
try {
	if (A_TimeIdle < WxUpdateInterval) {
		NextInterval := UpdateClock(1)
		SetTimer, ShowClock, % NextInterval
	} else {
		; When idle: hide the display, don't try to update as often, and
		; mark the weather info with time frozen to indicate it might be outdated.
		if (!(SubStr(oLast.WxStr1, 1, 1) = "(")) {
			FormatTime, FreezeTime,, h:mm
			oLast.WxStr1 := "(~" . FreezeTime . ") " . oLast.WxStr1
		}
		UpdateClock(0)
		SetTimer, ShowClock, % 10000
	}
}
return

ShowWx:
try {
	if (StrLen(WxApiToken) < 16) {
		; Skip weather if there's no API token
		return
	}
	if (WxUpdateInterval < 120000) {
		; Consider it unreasonable to update weather more often than every 2 minutes
 		WxUpdateInterval := 120000
	}
	if (A_TimeIdle < WxUpdateInterval) {
		UpdateWx()
	}
	SetTimer, ShowWx, % WxUpdateInterval
} catch e {
	; Need to alert when weather fails to prevent issues with API limits
	oLast.WxStr1 := "Error in " e.What ", line " e.Line " : " e.Message
	oLast.WxStr2 := e.Extra
	UpdateWin(0,1)
}
return

; ===================================================================================
CreateGUI() {
	global

	WxEnabled := StrLen(WxApiToken) >= 16 ; openweathermap tokens appear to be 32 characters
	OutlineText := StrLen(OutColor) >= 2 and OutColor != "ERROR"
	WxWind := ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N"]

	Gui, +AlwaysOnTop -Caption +Owner +LastFound +E0x20 +HWNDhGui_OSD
	Gui, Margin, 0, 0
	Gui, Color, %BkColor%
	Gui, Font, c%FontColor% %FontStyle% s%FontSize%, %FontName%
	TextRows := WxEnabled ? 3 : 2
	Gui, Add, Text, vWxClockTemp r%TextRows% Center Center

	if (TransBk = 1) {
		WinSet, TransColor, %BkColor% %TransN%
	} else {
		WinSet, Transparent, %TransN%
	}

	; Put all text together temporarily for size calculations, then hide it and create two separate text controls
	GuiStr := "h:mm:ss tt | ddd M/d/yyyy" . (WxEnabled ? "`n100.0°F scattered clouds | Feel: 103.0°`nL:60.0° | H:102.0° | W:12.3mph WSW" : "")
	GuiControl, 1:, WxClockTemp, %GuiStr%
	GuiControl, 1:Show, WxClockTemp
	Gui, 1:Show, AutoSize NoActivate
	GuicontrolGet, WxClockInfo, Pos, WxClockTemp
	GuiControl, 1:Hide, WxClockTemp
	;MsgBox Coordinates ( %WxClockInfoX% , %WxClockInfoY% ) Size ( %WxClockInfoW% x %WxClockInfoH% )

	rowHeight := Round(WxClockInfoH / 3)
	WxImgSize := GuiHeight < 50 ? GuiHeight : 50
	TextRows := WxEnabled ? 1 : 2

	x := WxEnabled ? WxImgSize : 0
	xa := x - 1
	xb := x + 1
	y1 := Round((GuiHeight - WxClockInfoH) / 2)
	y1a := y1 - 1
	y1b := y1 + 1
	y2 := y1 + rowHeight
	y2a := y2 - 1
	y2b := y2 + 1
	y3 := Round((GuiHeight - WxImgSize) / 2)
	w := GuiWidth - (WxEnabled ? WxImgSize : 0)
	h1 := rowHeight * TextRows
	h2 := rowHeight * 2
	;MsgBox r=%TextRows% x=%x% y1=%y1% y2=%y2% W=%WxClockInfoW% H=%WxClockInfoH% w=%w% h1=%h1% h2=%h2% GW=%GuiWidth% GH=%GuiHeight%

	if (OutlineText) {
		Gui, Add, Text, vWxClockText1aa r%TextRows% Center Center c%OutColor% BackgroundTrans
		Gui, Add, Text, vWxClockText1ab r%TextRows% Center Center c%OutColor% BackgroundTrans
		Gui, Add, Text, vWxClockText1ba r%TextRows% Center Center c%OutColor% BackgroundTrans
		Gui, Add, Text, vWxClockText1bb r%TextRows% Center Center c%OutColor% BackgroundTrans
		Gui, Add, Text, vWxClockText1aasec r%TextRows% Left c%OutColor% BackgroundTrans
		Gui, Add, Text, vWxClockText1absec r%TextRows% Left c%OutColor% BackgroundTrans
		Gui, Add, Text, vWxClockText1basec r%TextRows% Left c%OutColor% BackgroundTrans
		Gui, Add, Text, vWxClockText1bbsec r%TextRows% Left c%OutColor% BackgroundTrans
	}
	Gui, Add, Text, vWxClockText1 r%TextRows% Center Center BackgroundTrans
	Gui, Add, Text, vWxClockText1sec r%TextRows% Left BackgroundTrans
	if (WxEnabled) {
		if (OutlineText) {
			Gui, Add, Text, vWxClockText2aa r2 Center Center c%OutColor% BackgroundTrans
			Gui, Add, Text, vWxClockText2ab r2 Center Center c%OutColor% BackgroundTrans
			Gui, Add, Text, vWxClockText2ba r2 Center Center c%OutColor% BackgroundTrans
			Gui, Add, Text, vWxClockText2bb r2 Center Center c%OutColor% BackgroundTrans
		}
		Gui, Add, Text, vWxClockText2 r2 Center Center BackgroundTrans
		Gui, Add, Picture, vWxImg x0 y%y3% w%WxImgSize% h%WxImgSize%, .\wx\unknown.png
	}

	Gui, 1:Hide
	GuiControl, 1:Move, WxClockText1, x%x% y%y1% w%w% h%h1%
	GuiControl, 1:Move, WxClockText1sec, x%x% y%y1% w%w% h%h1%
	if (OutlineText) {
		GuiControl, 1:Move, WxClockText1aa, x%x% y%y1a% w%w% h%h1%
		GuiControl, 1:Move, WxClockText1ab, x%x% y%y1b% w%w% h%h1%
		GuiControl, 1:Move, WxClockText1ba, x%xa% y%y1% w%w% h%h1%
		GuiControl, 1:Move, WxClockText1bb, x%xb% y%y1% w%w% h%h1%
		GuiControl, 1:Move, WxClockText1aasec, x%x% y%y1a% w%w% h%h1%
		GuiControl, 1:Move, WxClockText1absec, x%x% y%y1b% w%w% h%h1%
		GuiControl, 1:Move, WxClockText1basec, x%xa% y%y1% w%w% h%h1%
		GuiControl, 1:Move, WxClockText1bbsec, x%xb% y%y1% w%w% h%h1%
		GuiControl, 1:Show, WxClockText1aa
		GuiControl, 1:Show, WxClockText1ab
		GuiControl, 1:Show, WxClockText1ba
		GuiControl, 1:Show, WxClockText1bb
		GuiControl, 1:Show, WxClockText1aasec
		GuiControl, 1:Show, WxClockText1absec
		GuiControl, 1:Show, WxClockText1basec
		GuiControl, 1:Show, WxClockText1bbsec
	}
	GuiControl, 1:Show, WxClockText1
	GuiControl, 1:Show, WxClockText1sec
	if (WxEnabled) {
		GuiControl, 1:Move, WxClockText2, x%x% y%y2% w%w% h%h2%
		if (OutlineText) {
			GuiControl, 1:Move, WxClockText2aa, x%x% y%y2a% w%w% h%h2%
			GuiControl, 1:Move, WxClockText2ab, x%x% y%y2b% w%w% h%h2%
			GuiControl, 1:Move, WxClockText2ba, x%xa% y%y2% w%w% h%h2%
			GuiControl, 1:Move, WxClockText2bb, x%xb% y%y2% w%w% h%h2%
			GuiControl, 1:Show, WxClockText2aa
			GuiControl, 1:Show, WxClockText2ab
			GuiControl, 1:Show, WxClockText2ba
			GuiControl, 1:Show, WxClockText2bb
		}
		GuiControl, 1:Show, WxClockText2
	}
}

UpdateClock(ShowSeconds := 1) {
	global LastMinuteSeen, LastSeconds
	Separator := WxEnabled ? " | " : "`n"
	SecondStr := ShowSeconds ? ":    " : ""
	FormatTime, ClockStr,, h:mm%SecondStr% tt%Separator%ddd M/d/yyyy
	FormatTime, CurrentMinute,, h:mm tt M/d/yyyy
	FormatTime, CurrentSeconds,, ss
	if (CurrentMinute != LastMinuteSeen) {
		oLast.ClockStr := ClockStr
		if (ShowSeconds) {
			LastMinuteSeen := CurrentMinute
			; Measure pixel width of "h:mm:" at current font to position seconds overlay
			FormatTime, PreStr,,  h:mm:
			hDC := DllCall("GetDC", "Ptr", 0, "Ptr")
			hFont := DllCall("SendMessage", "Ptr", hGui_OSD, "UInt", 0x31, "Ptr", 0, "Ptr", 0, "Ptr")
			hOldFont := DllCall("SelectObject", "Ptr", hDC, "Ptr", hFont, "Ptr")
			VarSetCapacity(sz, 8, 0)
			DllCall("GetTextExtentPoint32", "Ptr", hDC, "Str", PreStr,  "Int", StrLen(PreStr),  "Ptr", &sz)
			preW := NumGet(sz, 0, "Int")
			DllCall("GetTextExtentPoint32", "Ptr", hDC, "Str", ClockStr, "Int", StrLen(ClockStr), "Ptr", &sz)
			fullW := NumGet(sz, 0, "Int")
			DllCall("GetTextExtentPoint32", "Ptr", hDC, "Str", CurrentSeconds, "Int", StrLen(CurrentSeconds), "Ptr", &sz)
			secW := NumGet(sz, 0, "Int")
			DllCall("SelectObject", "Ptr", hDC, "Ptr", hOldFont)
			DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)
			
			x := WxEnabled ? (GuiHeight < 50 ? GuiHeight : 50) : 0
			w := GuiWidth - x
			textStartX := x + Round((w - fullW) / 2)
			xSec := textStartX + preW
			xaSec := xSec - 1
			xbSec := xSec + 1
			GuiControl, 1:Move, WxClockText1sec, x%xSec% w%secW%
			if (OutlineText) {
				GuiControl, 1:Move, WxClockText1aasec, x%xaSec% w%secW%
				GuiControl, 1:Move, WxClockText1absec, x%xaSec% w%secW%
				GuiControl, 1:Move, WxClockText1basec, x%xbSec% w%secW%
				GuiControl, 1:Move, WxClockText1bbsec, x%xbSec% w%secW%
			}
		}
		UpdateWin(1,0)
	}
	if (ShowSeconds and CurrentSeconds != LastSeconds) {
		LastSeconds := CurrentSeconds
		GuiControl, 1:, WxClockText1sec, %CurrentSeconds%
		GuiControl, 1:Show, WxClockText1sec
		if (OutlineText) {
			GuiControl, 1:, WxClockText1aasec, %CurrentSeconds%
			GuiControl, 1:, WxClockText1absec, %CurrentSeconds%
			GuiControl, 1:, WxClockText1basec, %CurrentSeconds%
			GuiControl, 1:, WxClockText1bbsec, %CurrentSeconds%
			GuiControl, 1:Show, WxClockText1aasec
			GuiControl, 1:Show, WxClockText1absec
			GuiControl, 1:Show, WxClockText1basec
			GuiControl, 1:Show, WxClockText1bbsec
		}
		UpdateWin(0,0)
		Return 800
	}
	Return 80
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

	try {
		Http.Open("GET", WxUrl)
		Http.Send()
		WxResponse := JSON.Load(Http.ResponseText)

		; TODO: consider setting imgFile by weather[1].id which is more granular than icon
		; Reference for both - https://openweathermap.org/weather-conditions
		Wx := {}
		if (WxOneCall = 1) {
			Wx.id := WxResponse.current.weather[1].id
			Wx.icon := WxResponse.current.weather[1].icon
			Wx.cond := WxResponse.current.weather[1].description
			Wx.temp := WxResponse.current.temp
			Wx.feel := WxResponse.current.feels_like
			Wx.min := WxResponse.daily[1].temp.min
			Wx.max := WxResponse.daily[1].temp.max
			Wx.wspeed := WxResponse.current.wind_speed
			Wx.wdir := WxResponse.current.wind_deg
		} else {
			Wx.id := WxResponse.weather[1].id
			Wx.icon := WxResponse.weather[1].icon
			Wx.cond := WxResponse.weather[1].description
			Wx.temp := WxResponse.main.temp
			Wx.feel := WxResponse.main.feels_like
			Wx.min := WxResponse.main.temp_min
			Wx.max := WxResponse.main.temp_max
			Wx.wspeed := WxResponse.wind.speed
			Wx.wdir := WxResponse.wind.deg
		}

		; TODO: change °F and mph based on WxUnits setting
		oLast.WxStr1 := Round(Wx.temp, WxPrecision) . "°F " . Wx.cond
		if (Abs(Wx.temp - Wx.feel) > 1) {
			oLast.WxStr1 := oLast.WxStr1 . " | Feel: " . Round(Wx.feel, WxPrecision) . "°"
		}	
		oLast.WxStr2 := "L:" . Round(Wx.min, WxPrecision)
		oLast.WxStr2 := oLast.WxStr2 . "° | H:" . Round(Wx.max, WxPrecision)
		oLast.WxStr2 := oLast.WxStr2 . "° | W:" . Round(Wx.wspeed, WxPrecision) . "mph "
		wdir := WxWind[Round(Wx.wdir / 22.5) + 1]
		oLast.WxStr2 := oLast.WxStr2 . wdir

		imgFile := ".\wx\code" . Wx.id . SubStr(Wx.icon, 0) . ".png"
		if (!FileExist(imgFile)) {
			imgFile := ".\wx\" . Wx.icon . ".png"
			imgUrl := "http://openweathermap.org/img/wn/" . Wx.icon . ".png"
			URLDownloadToFile, %imgUrl%, %imgFile%
		}
		GuiControl, 1:-Redraw, WxImg
		GuiControl,, WxImg, %imgFile%
		GuiControl, 1:+Redraw, WxImg
		GuiControl, 1:Move, WxImg, x0 y0
		GuiControl, 1:Show, WxImg
	} catch e {
		; Need to alert when weather fails to prevent issues with API limits
		oLast.WxStr1 := "Error in " e.What ", line " e.Line " : " e.Message
		oLast.WxStr2 := e.Extra
	}

	UpdateWin(0,1)
}

#^F1::
CycleWxImg:
{
	WxImgs := StrSplit("200,201,202,210,211,212,221,230,231,232,300,301,302,310,311,312,313,314,321,500,501,502,503,504,511,520,521,522,531,600,601,602,611,612,613,615,616,620,621,622,701,711,721,731,741,751,761,762,771,781,800,801,802,803,804", ",")
	imgFile := ".\wx\code" . WxImgs[ImgIndex] . ImgSuffix . ".png"
	oLast.wxStr2 := imgFile . " (" . ImgIndex . ")"
	GuiControl, 1:-Redraw, WxImg
	GuiControl,, WxImg, %imgFile%
	GuiControl, 1:+Redraw, WxImg
	GuiControl, 1:Move, WxImg, x0 y0
	GuiControl, 1:Show, WxImg

	if (ImgSuffix = "d") {
		ImgSuffix := "n"
	} else {
		ImgSuffix := "d"
		ImgIndex := ImgIndex + 1
	}
	if (ImgIndex > WxImgs.MaxIndex()) {
		ImgIndex := 1
	}
	UpdateWin(0,0)
	Return
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

UpdateWin(ClockText := 0, WxText := 0) {
	GuiStr1 := oLast.ClockStr
	GuiStr2 := oLast.WxStr1 . "`n" . oLast.WxStr2

	; TODO: re-introduce positioning other than bottom center
	ActWin_X := (A_ScreenWidth - GuiWidth) / 2
	ActWin_Y := A_ScreenHeight - GuiHeight
	ActWin_W := GuiWidth
	ActWin_H := GuiHeight

	text_w := GuiWidth
	text_w := Round(text_w/(A_ScreenDPI/96))
	text_h := GuiHeight
	text_h := Round(text_h/(A_ScreenDPI/96))
	ctrlSize = w%text_w% h%text_h%
	gui_x := ActWin_X + Bottom_OffsetX
	gui_y := (ActWin_Y+ActWin_H) - GuiHeight - Bottom_OffsetY
	guiPos = x%gui_x% y%gui_y%

	if (ClockText == 1) {
		if (OutlineText) {
			GuiControl, 1:, WxClockText1aa, %GuiStr1%
			GuiControl, 1:, WxClockText1ab, %GuiStr1%
			GuiControl, 1:, WxClockText1ba, %GuiStr1%
			GuiControl, 1:, WxClockText1bb, %GuiStr1%
		}
		GuiControl, 1:, WxClockText1, %GuiStr1%
		GuiControl, 1:, WxClockText1sec, %CurrentSeconds%
	}
	if (WxEnabled and WxText == 1) {
		if (OutlineText) {
			GuiControl, 1:, WxClockText2aa, %GuiStr2%
			GuiControl, 1:, WxClockText2ab, %GuiStr2%
			GuiControl, 1:, WxClockText2ba, %GuiStr2%
			GuiControl, 1:, WxClockText2bb, %GuiStr2%
		}
		GuiControl, 1:, WxClockText2, %GuiStr2%
	}
	Gui, +AlwaysOnTop
	Gui, 1:Show, NoActivate %guiPos% %ctrlSize%
	oLast.guiPos := guiPos
}

HideGUI() {
	Gui, Hide
	oLast := {}
}

;-----------------------------------------------------------------------------
; All settings are optional. Notes on default settings:
;
; GuiHeight 48, FontSize 9 works well for Windows 11's default taskbar
; GuiHeight 40, FontSize 7 or 8 works well for Windows 10's default taskbar
;
; Weather display is designed to work with openweathermap.org
;
; Using their OneCall API, you can update 3 computers every 5 minutes, or
; 10 computers every 15 minutes, and stay under the free 1000/day threshold
;
; Using the other free API, daily H/L might not be as accurate, but it
; supports up to 60 calls/minute and 1,000,000 calls/month, which means you
; could update 46 computers every 2 minutes and still be under the threshold
;
; Excluding WxApiToken prevents all attempts at displaying/updating weather
;
; Default lat/lon is the US Capitol building in Washington DC
;-----------------------------------------------------------------------------
ReadSettings() {
	IniFile := SubStr(A_ScriptFullPath, 1, -4) ".ini"

	IniRead, TransBk         , %IniFile%, Settings, TransBk         , 1
	IniRead, TransN          , %IniFile%, Settings, TransN          , 200
	IniRead, GuiPosition     , %IniFile%, Settings, GuiPosition     , Bottom
	IniRead, FontSize        , %IniFile%, Settings, FontSize        , 9
	IniRead, GuiWidth        , %IniFile%, Settings, GuiWidth        , %A_ScreenWidth%
	IniRead, GuiHeight       , %IniFile%, Settings, GuiHeight       , 48
	IniRead, BkColor         , %IniFile%, Settings, BkColor         , 0x333333
	IniRead, OutColor        , %IniFile%, Settings, OutColor        , 
	IniRead, FontColor       , %IniFile%, Settings, FontColor       , White
	IniRead, FontStyle       , %IniFile%, Settings, FontStyle       , w400
	IniRead, FontName        , %IniFile%, Settings, FontName        , Verdana
	IniRead, Bottom_Win      , %IniFile%, Settings, Bottom_Win      , 1
	IniRead, Bottom_Screen   , %IniFile%, Settings, Bottom_Screen   , 0
	IniRead, Bottom_OffsetX  , %IniFile%, Settings, Bottom_OffsetX  , 0
	IniRead, Bottom_OffsetY  , %IniFile%, Settings, Bottom_OffsetY  , 50
	IniRead, Top_Win         , %IniFile%, Settings, Top_Win         , 1
	IniRead, Top_Screen      , %IniFile%, Settings, Top_Screen      , 0
	IniRead, Top_OffsetX     , %IniFile%, Settings, Top_OffsetX     , 0
	IniRead, Top_OffsetY     , %IniFile%, Settings, Top_OffsetY     , 0
	IniRead, FixedX          , %IniFile%, Settings, FixedX          , 100
	IniRead, FixedY          , %IniFile%, Settings, FixedY          , 200
	IniRead, WxApiToken      , %IniFile%, Settings, WxApiToken      , 
	IniRead, WxLat           , %IniFile%, Settings, WxLat           , 38.89
	IniRead, WxLon           , %IniFile%, Settings, WxLon           , -77.01
	IniRead, WxUnits         , %IniFile%, Settings, WxUnits         , imperial
	IniRead, WxUpdateInterval, %IniFile%, Settings, WxUpdateInterval, 300000
	IniRead, WxPrecision     , %IniFile%, Settings, WxPrecision     , 0
	IniRead, WxOneCall       , %IniFile%, Settings, WxOneCall       , 1
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
