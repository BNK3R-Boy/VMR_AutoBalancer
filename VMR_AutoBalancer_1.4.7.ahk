; #Warn All
#NoEnv
#SingleInstance force
; #Persistent
#InstallMouseHook
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
CoordMode, ToolTip, Screen

OnExit("cleanup_before_exit")

Global allContent:=""
Global lastFileContent:=""

Global ABVersion:="1.4.7"
Global credits:="written by Boris Weinrich (2018-2020) - v" ABVersion
Global apptitle="Autobalancer"
Global GUIhWnd:=""
Global MicOpthWnd:=""
Global Gain:=0
Global Vol:=0, nVol:=0
Global r_noSpeak:=0, r_oneSpeak:=0, r_allSpeak:=0, addonespeak:=0, addallspeak:=0
Global Obergrenze
Global Untergrenze
Global WTFTitle
Global ObereSchwelle
Global untereSchwelle
Global VolumControl1
Global Silence
Global isChangesBlocked:=0
Global isDownBlocked:=0
Global isUpBlocked:=0
Global isTalking:=0, isTalkingOnce:=1, italk:=0, italkonce:=0, TalkState:=0, volStateonce:=1
Global MicThreshold:=0
Global fnRemoveBlockChanges:=Func("RemoveBlockChanges")
Global fnRemoveBlockDown:=Func("RemoveBlockDown")
Global fnRemoveBlockUp:=Func("RemoveBlockUp")
Global menuitemvalue:=1000
Global MyProgress:=1000
Global progressrange:=100000
Global littleprogressrange:=round(progressrange/3.5,0)
Global nprogressrange:=100000
Global ctrlv
Global chgSpeed
Global ctrlspeed
Global SampleLength
Global AddGate
Global miconce:=0
Global cmc:=0
Global CurLev:=0
Global chkup:=0, chkdn:=0
Global Ardytup:=0
Global Ardytdn:=0
Global slideup:=Func("volup_s2")
Global slidedn:=Func("voldown_s2")
Global fnvolstop_s2:=Func("volstop_s2")
Global fncvmrv:=Func("clear_vmr_variable")
Global INIPath:=A_WorkingDir "\VMR.ini"
GLobal BalancedStrip

Global GUIxy, GUIhWnd:=0
Global MOAxy, MOAhWnd:=0
Global OA1xy, OA1hWnd:=0
Global OA2xy, OA2hWnd:=0
Global s0, b3, b4, MicHold
Global MICWARNONCE:=0

Global fnToggleWidgets := func("togglewidgets")
Global fnToggleWidgetsOnOff := func("togglewidgetsOnOff")
Global togglewidgetsOnOff
Global MenuWidgetOO:="Widget on/off"

Global VMR_FUNCTIONS := {}
Global VMR_DLL_DRIVE := "C:"
Global VMR_DLL_DIRPATH := "Program Files (x86)\VB\Voicemeeter"
Global VMR_DLL_FILENAME_32 := "VoicemeeterRemote.dll"
Global VMR_DLL_FILENAME_64 := "VoicemeeterRemote64.dll"
Global VMR_DLL_FULL_PATH := VMR_DLL_DRIVE . "\" . VMR_DLL_DIRPATH . "\"

If (A_Is64bitOS)
	VMR_DLL_FULL_PATH .= VMR_DLL_FILENAME_64
Else
	VMR_DLL_FULL_PATH .= VMR_DLL_FILENAME_32

Global VMR_MODULE := DllCall("LoadLibrary", "Str", VMR_DLL_FULL_PATH, "Ptr")
If (ErrorLevel OR VMR_MODULE == 0)
	die("Attempt to load VoiceMeeter Remote DLL failed.")

add_vmr_function("Login")
add_vmr_function("Logout")
add_vmr_function("RunVoicemeeter")
add_vmr_function("SetParameters")
add_vmr_function("SetParameterFloat")
add_vmr_function("GetParameterFloat")
add_vmr_function("IsParametersDirty")
add_vmr_function("GetLevel")

vmr_login()

vmr_login() {
	login_result := DllCall(VMR_FUNCTIONS["Login"], "Int")
	If (ErrorLevel OR login_result < 0)
		die("VoiceMeeter Remote login failed.")
	If (login_result == 1) {
		die("VoiceMeeter not running.")
	}
}


IniRead, ObereSchwelle, %INIPath%, Config, ObereSchwelle, 65000
IniRead, UntereSchwelle, %INIPath%, Config, UntereSchwelle, 30000
IniRead, Silence, %INIPath%, Config, Deadzone, 10300
IniRead, VolumControl1, %INIPath%, Config, VolumControl1, 4
IniRead, chgSpeed, %INIPath%, Config, chgSpeed, 15
IniRead, ctrlspeed, %INIPath%, Config, ctrlspeed, 40
IniRead, SampleLength, %INIPath%, Config, SampleLength, 15
IniRead, togglewidgetsOnOff, %INIPath%, Config, togglewidgetsOnOff, 1
IniRead, AddGate, %INIPath%, Config, AddGate, 6
IniRead, addonespeak, %INIPath%, Config, addonespeak, -6
IniRead, addallspeak, %INIPath%, Config, addallspeak, -12

hx:=(A_ScreenWidth/2)-10
IniRead, GUIxy, %INIPath%, Position, GUIxy, x300 y200
IniRead, MOAxy, %INIPath%, Position, MOAxy, x%hx% y50
IniRead, OA1xy, %INIPath%, Position, OA1xy, x90 y30
IniRead, OA2xy, %INIPath%, Position, OA2xy, x175 y30

IniRead, Obergrenze, %INIPath%, HiddenConfig, og, 12
IniRead, Untergrenze, %INIPath%, HiddenConfig, ug, -60
IniRead, WTFTitle, %INIPath%, HiddenConfig, wtf, 0
IniRead, ctrlv, %INIPath%, HiddenConfig, ctrlv, "n"
IniRead, volumetarget, %INIPath%, HiddenConfig, ctrlv, "n"
IniRead, BalancedStrip, %INIPath%, HiddenConfig, BalancedStrip, 6


IniRead, MicThreshold, %INIPath%, Mic Settings, MicThreshold, 5800
IniRead, MicHold, %INIPath%, Mic Settings, MicHold, 500

clear_vmr_variable()
v_Recorder()

If !FileExist(INIPath) {
	save_settings()
	IniWrite, %addonespeak%, %INIPath%, Config, addonespeak
	IniWrite, %addallspeak%, %INIPath%, Config, addallspeak
	IniWrite, %togglewidgetsOnOff%, %INIPath%, Config, togglewidgetsOnOff

	IniWrite, %MicThreshold%, %INIPath%, Mic Settings, MicThreshold
	IniWrite, %MicHold%, %INIPath%, Mic Settings, MicHold
}


Menu, Tray, NoStandard
If (!A_IsCompiled) {
	Menu, Tray, Standard
}
Menu, Tray, Add, GUI, openGUI
Menu, Tray, Add, Mic settings, ToggleMicOptions
Menu, Tray, Add, %menuWidgetOO%, %fnToggleWidgetsOnOff%
Menu, Tray, Add, Widgetlock on/off, %fnToggleWidgets%
Menu, Tray, Add, %A_Space%, dummy
Menu, Tray, Add, Exit, Exit
Menu, Tray, Add, %A_Space%%A_Space%, dummy
Menu, Tray, Click, 1
Menu, Tray, Default, GUI
Menu, Tray, Tip, %apptitle%

Hotkey, *F13, MicToggle

SetTimer, %fncvmrv%, 5
SetTimer, Check_S0, 30
SetTimer, Check_S2, % (ctrlspeed*10)

If !A_IsCompiled {
	checkFolder() {
		fileread newFileContent, %A_ScriptDir%\VMR_AutoBalancer_%ABVersion%.ahk
		If lastFileContent {
			If(newFileContent<>lastFileContent) {
                        lastFileContent:=newFileContent
				Soundbeep, 7500, 60
				Sleep, 50
				Reload
			}
		}
		Else
			lastFileContent:=newFileContent
	}
	fncheckFolder:=Func("checkFolder")
	SetTimer, %fncheckFolder%, 500
}

Gui 99: show, hide, %apptitle% ; hidden "message receiver window"
OnMessage( 0x7760, "ReceiveMessage" )
OnMessage( 0x200, "WM_MOUSEMOVE" )

ReceiveMessage(Message) {
	if (Message = 1) ; exit
		GoSub, Exit
	if (Message = 2) && GUIhWnd ; close 2 tray
		GoSub, openGUI
	if (Message = 4) && !GUIhWnd ; open gui
		GoSub, openGUI
	if (Message = 8) ; widget on
		togglewidgetsOnOff("open")
	if (Message = 16) ; widget off
		togglewidgetsOnOff("close")
}

WM_MOUSEMOVE(wparam, lparam, msg, hwnd)
{
	if (wparam = 1) { ; LButton
		save_settings()
		PostMessage, 0xA1, 2,,, A ; WM_NCLBUTTONDOWN
	}
}

(togglewidgetsOnOff) ? togglewidgetsOnOff("open")
GoTo, openGUI

_GetMute(sob="s", n="0") {
	If ((sob="s") OR (sob="b")) {
		(sob="s") ? sob:="Strip"
		(sob="b") ? sob:="Bus"
		Mute="0.0"
		NumPut(0.0, Mute, 0, "Float")
		statusLvl:=DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", sob "[" n "].Mute", "Ptr", &Mute, "Int")
		ErrorLevel ? die("Failed to get mute (" sob n ")")
		Return (statusLvl < 0) ? "" : round(NumGet(Mute, 0, "Float"),1)
	} Else
		die("Failed to get mute (" sob n ") - no strip or bus -`nuse: s or b")
}

_SetMute(sob="s", n="0", nMute="0") {
	If ((sob="s") OR (sob="b")) {
		(sob="s") ? sob:="Strip"
		(sob="b") ? sob:="Bus"
		DllCall(VMR_FUNCTIONS["SetParameterFloat"], "AStr", sob "[" n "].Mute", "Float", nMute, "Int")
	}
}

_GetLevel(sob="s", n="0", preopost="0") { ; preopost: 0 Prefader, 1 Postfader
	If ((sob="s") OR (sob="b")) {
		If (sob="s") {
			If (n="0") {
				n1:="00", n2:="01"
			}
			If (n="1") {
				n1:="02", n2:="03"
			}
			If (n="2") {
				n1:="04", n2:="05"
			}
			If (n="3") {
				n1:="06", n2:="07"
			}
			If (n="4") {
				n1:="08", n2:="09"
			}
			If (n="5") {
				n1:="10", n2:="11"
			}
			If (n="6") {
				n1:="18", n2:="19"
			}
			If (n="7") {
				n1:="26", n2:="27"
			}
		}
		If (sob="b") {
			If (n="0") {
				n1:="00", n2:="01"
			}
			If (n="1") {
				n1:="08", n2:="09"
			}
			If (n="2") {
				n1:="16", n2:="17"
			}
			If (n="3") {
				n1:="24", n2:="25"
			}
			If (n="4") {
				n1:="32", n2:="33"
			}
		}
		vol1:="0.0"
		vol2:="0.0"
		NumPut(0.0, vol1, 0, "Float"), NumPut(0.0, vol2, 0, "Float")
		statusLvl1:=DllCall(VMR_FUNCTIONS["GetLevel"], "Int", preopost, "Int", n1, "Int", &vol1, "Float")
		ErrorLevel ? die("Failed to get volume 1")
		statusLvl2:=DllCall(VMR_FUNCTIONS["GetLevel"], "Int", preopost, "Int", n2, "Int", &vol2, "Float")
		ErrorLevel ? die("Failed to get volume 2")
		Return ((statusLvl1+statusLvl2) < 0) ? "" : Round(((((NumGet(vol1, 0, "Float")+NumGet(vol2, 0, "Float"))*20000)/2))*(VolumControl1+1),1)
	} Else
		die("Failed to get level (" sob n ") - no strip or bus -`nuse: s or b")
}

_GetGain(sob="s", n="0") {
	If ((sob="s") OR (sob="b") OR (sob="r")) {
		(sob="s") ? sob:="Strip[" n "]"
		(sob="b") ? sob:="Bus[" n "]"
		(sob="r") ? sob:="Recorder"
		nGain="0"
		NumPut(0.0, nGain, 0, "Float")
		statusLvl:=DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", sob ".Gain", "Ptr", &nGain, "Int") ;calls dll and set passed memory address to current gain/volume note we are passing the memory address as a pointer of volLvlB0 by adding & in front of it
		Return NumGet(nGain, 0, "Float")  ;get data from the memory address as float (according to VoicemeeterRemote.h it is a float)
	} Else
		die("Failed to get gain (" sob n ") - no strip, bus or recorder -`nuse: s,b or r")
}

_SetGain(sob="s", n="0", nGain="0") {
	If ((sob="s") OR (sob="b") OR (sob="r")) {
		gainis:=_GetGain(sob, n)
		(sob="s") ? sob:="Strip[" n "]"
		(sob="b") ? sob:="Bus[" n "]"
		(sob="r") ? sob:="Recorder"
		If !(gainis==nGain) {
			DllCall(VMR_FUNCTIONS["SetParameterFloat"], "AStr", sob ".Gain", "Float", nGain, "Int")
			ErrorLevel ? die("Failed to set gain")
		}
	} Else
		die("Failed to set gain (" sob n ") - no strip or bus -`nuse: s or b")
}

_GetGate(n="0") {
  gate:="0.0"
	NumPut(0.0, gate, 0, "Float")
	statusLvl:=DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[" n "].gate", "Ptr", &gate, "Int") ;calls dll and set passed memory address to current gain/volume note we are passing the memory address as a pointer of volLvlB0 by adding & in front of it
	Return NumGet(gate, 0, "Float")  ;get data from the memory address as float (according to VoicemeeterRemote.h it is a float)
}

_SetGate(n="0", gate="0.0") {
	gateis:=round(_getgate(n), 1)
	gate:=round(gate, 1)
	!(gateis == gate) ? SetRecorder("Strip(" n ").gate=" gate)
}

_GetComp(n="0") {
	comp:="0.0"
	NumPut(0.0, comp, 0, "Float")
	statusLvl:=DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[" n "].comp", "Ptr", &comp, "Int") ;calls dll and set passed memory address to current gain/volume note we are passing the memory address as a pointer of volLvlB0 by adding & in front of it
	Return NumGet(comp, 0, "Float")  ;get data from the memory address as float (according to VoicemeeterRemote.h it is a float)
}

_SetComp(n="0", comp="0.0") {
	compis:=round(_GetComp(n), 1)
	comp:=round(comp, 1)
	!(compis == comp) ? SetRecorder("Strip(" n ").comp=" comp)
}

volup_s2() {
	Critical
	/*
	a^\Sgain:=\wound(s2_GetGain(),1)
	ngain:=round(acgain+(ctrlspeed/10),1)
	(ngain>round(Obergrenze,1)) ? ngain:=Obergrenze
	SetRecorder("Strip(2).FadeTo=(" ngain ", " chgSpeed*30 ");") ; s2_SetGain(acgain+0.1)
	*/
	SetRecorder("Strip(" BalancedStrip ").FadeTo=(" Obergrenze ", " chgSpeed*500 ");") ; s2_SetGain(acgain+0.1)
	SetTimer, %fnvolstop_s2%, % (chgSpeed*50*-1)
}

voldown_s2() {
	Critical
	/*
	acgain:=round(s2_GetGain(),1)
	ngain:=round(acgain-(ctrlspeed/10),1)
	(ngain<round(Untergrenze,1)) ? ngain:=Untergrenze
	SetRecorder("Strip(2).FadeTo=(" ngain ", " chgSpeed*30 ");") ; s2_SetGain(acgain-0.1)
	*/
	SetRecorder("Strip(" BalancedStrip ").FadeTo=(" Untergrenze ", " chgSpeed*500 ");") ; s2_SetGain(acgain-0.1)
	SetTimer, %fnvolstop_s2%, % (chgSpeed*50*-1)
}

volstop_s2() {
	Critical
	acgain:=round(_GetGain("s", BalancedStrip),1)
	SetRecorder("Strip(" BalancedStrip ").FadeTo=(" acgain ", 0);")
}

volcontrol_s(vol, gain) {
	Critical
	vol_1p:=(progressrange/100)
	vol_p:=vol/vol_1p

	vol_target_p:=((progressrange/2)/vol_1p)
	dif_p:=vol_target_p-vol_p

	gain_1p:=(72/100) ; 72 = 12 to -60 gai
	gain_dif:=dif_p/gain_1p

	ngain:=gain+(gain_dif/10)

	(ngain>=Obergrenze) ? ngain:=Obergrenze
	(ngain<=Untergrenze) ? ngain:=Untergrenze

	; tooltip, %A_space%%Obergrenze%`nchging_percent: %chging_percent%`n vol_dif: %vol_dif%`n gain: %gain%`n ngain: %ngain%`n ngain_percent: %ngain_percent%`n gain_percent: %gain_percent%`n%Untergrenze%

	changetime:=(chgSpeed*gain_dif)
	(changetime<0) ? changetime*=-1

	; tooltip, %gain% %vol_target_p%
	SetRecorder("Strip(" BalancedStrip ").FadeTo=(" ngain ", " changetime ");")
	SetTimer, %fnvolstop_s2%, % ((chgSpeed*500*/2)-1)

}

save_settings() {
	Critical
	IniWrite, %ObereSchwelle%, %INIPath%, Config, ObereSchwelle
	IniWrite, %UntereSchwelle%, %INIPath%, Config, UntereSchwelle
	IniWrite, %Silence%, %INIPath%, Config, Deadzone
	IniWrite, %VolumControl1%, %INIPath%, Config, VolumControl1
	IniWrite, %chgSpeed%, %INIPath%, Config, chgSpeed
	IniWrite, %ctrlspeed%, %INIPath%, Config, ctrlspeed
	IniWrite, %SampleLength%, %INIPath%, Config, SampleLength
	IniWrite, %MicHold%, %INIPath%, Mic Settings, MicHold
	(GUIhWnd) ? iniwrite_xy(GUIhWnd, "GUI")
	(MOAhWnd) ? iniwrite_xy(MOAhWnd, "MOA")
	(OA1hWnd) ? iniwrite_xy(OA1hWnd, "OA1")
	(OA2hWnd) ? iniwrite_xy(OA2hWnd, "OA2")
	IniWrite, %togglewidgetsOnOff%, %INIPath%, Config, togglewidgetsOnOff
	IniWrite, %AddGate%, %INIPath%, Config, AddGate
	IniWrite, %MicThreshold%, %INIPath%, Mic Settings, MicThreshold
}

iniwrite_xy(hWnd, name) {
	Critical
	WinGet MMX, MinMax, ahk_id %hWnd%
	If WinExist("ahk_id " hWnd) && !(MMX=-1) {
		WinGetPos, GUIx, GUIy,,, ahk_id %hWnd%
		str := "x" GUIx " y" GUIy
		IniWrite, %str%, %INIPath%, Position, %name%xy
		%name%xy:=str
	}
}

BlockDown() {
	isDownBlocked:=1
	SetTimer, %fnRemoveBlockDown%, -100
}

RemoveBlockDown() {
	isDownBlocked:=0
}

BlockChanges() {
	isChangesBlocked:=1
	SetTimer, %fnRemoveBlockChanges%, -100
}

RemoveBlockChanges() {
	isChangesBlocked:=0
}

BlockUp() {
	isUpBlocked:=1
	SetTimer, %fnRemoveBlockUp%, -100
}

RemoveBlockUp() {
	isUpBlocked:=0
}

WTFTitle() {
	WTFTitle++
	If (WTFTitle=5) {
		Titelcolor:=FHex(vol*10000)
		GuiControl, htu: +c%Titelcolor% +Redraw, Titel
		WTFTitle:=0
	}
}

SetRecorder(str) {
	DllCall(VMR_FUNCTIONS["SetParameters"], "AStr", str)
	ErrorLevel ? die("Failed to set recorder")
}

ClickTroughWidgetToggle(hWnd) {
	WinGet, ExStyle, ExStyle, ahk_id %hWnd%
	If (ExStyle = 0x000800A8) {
		WinSet, ExStyle, -0x80020, ahk_id %hWnd%
		WinSet, Transparent, 255, ahk_id %hWnd%
	}
	If (ExStyle = 0x00080088) {
		WinSet, ExStyle, +0x80020, ahk_id %hWnd%
		WinSet, Transparent, 80, ahk_id %hWnd%
	}
}

togglewidgets() {
	ClickTroughWidgetToggle(MOAhWnd)
	ClickTroughWidgetToggle(OA1hWnd)
	ClickTroughWidgetToggle(OA2hWnd)
}

togglewidgetsOnOff(opt = "toggle") {
	(opt==MenuWidgetOO) ? opt:="toggle"
	If (!togglewidgetsOnOff && (opt=="toggle")) || (opt=="open") {
  	togglewidgetsOnOff:=1
		Gui, MicOnAir: +hwndMOAhWnd -Caption -Border -Disabled +AlwaysOnTop +ToolWindow
		Gui, MicOnAir:Margin, 0, 0
		Gui, MicOnAir:Color, cFFFF00
		Gui, MicOnAir:Font, s14, Segoe UI
		Gui, MicOnAir:Add, Text, Center x0 y0 w40 +BackgroundTrans, Mic
		Gui, MicOnAir:Show, %MOAxy% w40 h26 NoActivate, %apptitle% Mic
		WinSet, ExStyle, +0x80020,ahk_id %MOAhWnd%
		WinSet, Transparent, 80, ahk_id %MOAhWnd%
		s0:=-1

		Gui, OnAir1: +hwndOA1hWnd -Caption -Border -Disabled +AlwaysOnTop +ToolWindow
		Gui, OnAir1:Margin, 0, 0
		Gui, OnAir1:Color, cFFFF00
		Gui, OnAir1:Font, s7, Segoe UI
		Gui, OnAir1:Add, Text, Center x0 y0 w45 +BackgroundTrans, V. On Air
		Gui, OnAir1:Show, %OA1xy% w45 h13 NoActivate, %apptitle% Voice On Air
		WinSet, ExStyle, +0x80020,ahk_id %OA1hWnd%
		WinSet, Transparent, 80, ahk_id %OA1hWnd%
		b3:=-1

		Gui, OnAir2: +hwndOA2hWnd -Caption -Border -Disabled +AlwaysOnTop +ToolWindow
		Gui, OnAir2:Margin, 0, 0
		Gui, OnAir2:Color, cFFFF00
		Gui, OnAir2:Font, s7, Segoe UI
		Gui, OnAir2:Add, Text, Center x0 y0 w45 +BackgroundTrans, S. On Air
		Gui, OnAir2:Show, %OA2xy% w45 h13 NoActivate, %apptitle% Stream On Air
		WinSet, ExStyle, +0x80020,ahk_id %OA2hWnd%
		WinSet, Transparent, 80, ahk_id %OA2hWnd%
		b4:=-1

		GetAllMutes()
		IniWrite, %togglewidgetsOnOff%, %INIPath%, Config, togglewidgetsOnOff
		SetTimer, Mutes, 10
		Return
	}
	If (togglewidgetsOnOff && (opt=="toggle")) || (opt=="close") {
  	togglewidgetsOnOff:=0
		Gui, MicOnAir: Destroy
		Gui, OnAir1: Destroy
		Gui, OnAir2: Destroy
		MOAhWnd:=0
		OA1hWnd:=0
		OA2hWnd:=0

		IniWrite, %togglewidgetsOnOff%, %INIPath%, Config, togglewidgetsOnOff
		SetTimer, Mutes, Off
		Return
	}
}

GetAllMutes() {
	green:="c00ff00"
	red:="cff0000"
	c0:=_GetMute("s", 0)
	c3:=_GetMute("b", 3)
	c4:=_GetMute("b", 4)
	If (s0<>c0) AND MOAhWnd {
		Gui, MicOnAir:Color, % ((c0) ? red : green)
		s0:=c0
		}
	If (b3<>c3) AND OA1hWnd {
		Gui, OnAir1:Color, % ((c3) ? red : green)
		b3:=c3
	}
	If (b4<>c4) AND OA2hWnd {
		Gui, OnAir2:Color, % ((c4) ? red : green)
		b4:=c4
	}
}

clear_vmr_variable() {
	DLLCall(VMR_FUNCTIONS["IsParametersDirty"])
	ErrorLevel ? die("Failed to clear vmr variables")
}

add_vmr_function(func_name) {
	VMR_FUNCTIONS[func_name] := DllCall("GetProcAddress", "Ptr", VMR_MODULE, "AStr", "VBVMR_" . func_name, "Ptr")
	(ErrorLevel OR !VMR_FUNCTIONS[func_name]) ? die("Failed to register VMR function " . func_name . ".")
}

FHex( int, pad=8 ) { ; Function by [VxE]. Formats an integer (decimals are truncated) as hex.
; "Pad" may be the minimum number of digits that should appear on the right of the "0x".
	Static hx := "0123456789ABCDEF"
	If !( 0 < int |= 0 )
		Return !int ? "0x0" : "-" FHex( -int, pad )
	s := 1 + Floor( Ln( int ) / Ln( 16 ) )
	h := SubStr( "0x0000000000000000", 1, pad := pad < s ? s + 2 : pad < 16 ? pad + 2 : 18 )
	u := A_IsUnicode = 1
	Loop % s
		NumPut( *( &hx + ( ( int & 15 ) << u ) ), h, pad - A_Index << u, "UChar" ), int >>= 4
	Return h
}

vmr_logoff() {
	DllCall(VMR_FUNCTIONS["Logout"], "Int")
}

cleanup_before_exit(exit_reason, exit_code) {
	SetTimer, Check_s2, Off
	SetTimer, RefreshGUI_s2, Off
	SetTimer, %slideup%, Off
	SetTimer, %slidedn%, Off
	SetTimer, %fncvmrv%, Off
	SetTimer, mutes, Off
	sleep, 300
	return vmr_logoff()
}

die(die_string:="UNSPECIFIED FATAL ERROR.", exit_status:=254) {
	MsgBox 16, FATAL ERROR, %die_string%
	ExitApp exit_status
}

MicToggle() {
	If !_GetMute("s", "0") {
		_SetMute("s", "0", "1")
		_SetComp(0, "0.6")
		_SetGate(0, "1.2")
		_SetGain("s", "0", "-60")
	}
	Else
		_SetMute("s", "0", "0")
}

v_Recorder() {
	r_noSpeak:=_GetGain("r")
	r_oneSpeak:=r_noSpeak+addonespeak
	r_allSpeak:=r_noSpeak+addallspeak
	; msgbox, r_noSpeak %r_noSpeak%`nr_oneSpeak %r_oneSpeak%`nr_allSpeak %r_allSpeak%
}

openGUI:
	If GUIhWnd {
		save_settings()
		Gui, htu: Destroy
		GUIhWnd:=""
		SetTimer, RefreshGUI_s2, Off
	} Else {
		Gui, htu: +hwndGUIhWnd -MaximizeBox ; -MinimizeBox ; +AlwaysOnTop
		Gui, htu: font, s16 c70C399, Segoe UI
		Gui, htu: Add, Text, 			x82 y0 +BackgroundTrans vTitel, %apptitle%
		Gui, htu: font, s8 c728395 w700
		Gui, htu: Add, Text, 			x10 y35 +BackgroundTrans, Obere Schwelle
		Gui, htu: Add, Slider, 		x23 y50 w260 vObereSchwelle gSlide +BackgroundTrans +Range0-%progressrange% tickinterval1-1000 AltSubmit, %ObereSchwelle%
		Gui, htu: Add, Text, 			x10 y85 +BackgroundTrans, Untere Schwelle
		Gui, htu: Add, Slider, 		x20 y100 w260 vUntereSchwelle gSlideB +BackgroundTrans +Range0-%progressrange% tickinterval1-1000 AltSubmit, %untereSchwelle%
		Gui, htu: Add, Text, 			x10 y135 +BackgroundTrans, Deadzone
		Gui, htu: Add, Slider, 		x17 y150 w260 vSilence gSlideC +BackgroundTrans +Range0-%progressrange% tickinterval0-1000 AltSubmit, %Silence%
		Gui, htu: Add, Progress, 	x29 y186 w242 h20 c86B1B7 +Background003300 Range0-%progressrange% vMyProgress -Smooth, %progressrange%
		Gui, htu: Add, Text, 			x285 y7 +BackgroundTrans, Balanced
		Gui, htu: Add, Text, 			x302 y20 +BackgroundTrans, Vol.
		Gui, htu: Add, Text, 			xp80 y7 +BackgroundTrans, Speeds
		Gui, htu: Add, Slider, 		x298 y40 h165 vVolumControl1 gSlideD +BackgroundTrans Vertical +range1-20 tickinterval1-20 AltSubmit, %VolumControl1%
		Gui, htu: Add, Slider, 		xp50 y40 h165 vchgspeed gSlideE +BackgroundTrans Vertical +range1-100 tickinterval1-100 AltSubmit, %chgspeed%
		Gui, htu: Add, Slider, 		xp40 y40 h165 vctrlspeed gSlideF +BackgroundTrans Vertical +range1-100 tickinterval1-100 AltSubmit, %ctrlspeed%
		Gui, htu: Add, Slider, 		xp40 y40 h165 vSampleLength gSlideG +BackgroundTrans Vertical +range1-100 tickinterval1-100 AltSubmit, %SampleLength%
		Gui, htu: font, s6 w400
		Gui, htu: Add, Text, 			x354 y23 +BackgroundTrans, up
		Gui, htu: Add, Text, 			x382 y23 +BackgroundTrans, Sampling
		Gui, htu: Add, Text, 			x426 y23 +BackgroundTrans, Sample
		Gui, htu: Add, Text, 			x349 y31 +BackgroundTrans, down
		Gui, htu: Add, Text, 			x390 y31 +BackgroundTrans, rate
		Gui, htu: Add, Text, 			x428 y31 +BackgroundTrans, lenght
		Gui, htu: font, s7 w700
		Gui, htu: Add, Text, 			x271 y207 +BackgroundTrans c000000, %credits%
		Gui, htu: Add, Text, 			x270 y206 +BackgroundTrans c728395 gOPP, %credits%
		Gui, htu: Color, 2C3D4D
		Gui, htu: Show, 					%GUIxy% w470 h220, %apptitle%

		SetTimer, RefreshGUI_s2, %ctrlspeed%
	}
Return

ToggleMicOptions:
	If MicOpthWnd {
  	GoSub, GuiCloseHtuMicOpthWnd
	} Else {
		Gui, htuMicOpthWnd: +hwndMicOpthWnd -MaximizeBox -MinimizeBox ; +AlwaysOnTop
		Gui, htuMicOpthWnd: font, s16 c70C399, Segoe UI
		Gui, htuMicOpthWnd: Add, Text, 			x82 y0 +BackgroundTrans vTitel, Mic settings
		Gui, htuMicOpthWnd: font, s8 c728395 w700
		Gui, htuMicOpthWnd: Add, Text, 			x10 y35 +BackgroundTrans, Mic threshold
		Gui, htuMicOpthWnd: font, s7 c94a5b7 w350
		Gui, htuMicOpthWnd: Add, Text, 			 y35 x150 +BackgroundTrans, current level: (
		Gui, htuMicOpthWnd: Add, Text, 			 y35 xp55 w30 Center vCurLev +BackgroundTrans, 00000
		Gui, htuMicOpthWnd: Add, Text, 			 y35 xp30 +BackgroundTrans, )
		Gui, htuMicOpthWnd: font, s8 c728395 w700
		Gui, htuMicOpthWnd: Add, Slider, 		x23 y50 w430 vMicThreshold gMicThresholdSlide +BackgroundTrans +Range0-%littleprogressrange% tickinterval1-1000 Line1 Page10 AltSubmit, %MicThreshold%
		Gui, htuMicOpthWnd: Add, Text, 			x10 y95 +BackgroundTrans, Mic hold
		Gui, htuMicOpthWnd: Add, Slider, 		x23 y110 w430 vMicHold gMicHoldSlide +BackgroundTrans +Range0-5000 tickinterval0-1000 Line1 Page10 AltSubmit, %MicHold%
		Gui, htuMicOpthWnd: Add, Text, 			x10 y150 +BackgroundTrans, thx to Wummsienator (Æ-beta-tester)
		/*
		Gui, htuMicOpthWnd: Add, Slider, 		x20 y100 w260 vUntereSchwelle gSlideB +BackgroundTrans +Range0-%progressrange% tickinterval1-1000 AltSubmit, %untereSchwelle%
		Gui, htuMicOpthWnd: Add, Text, 			x10 y135 +BackgroundTrans, Deadzone
		Gui, htuMicOpthWnd: Add, Slider, 		x17 y150 w260 vSilence gSlideC +BackgroundTrans +Range0-%progressrange% tickinterval0-1000 AltSubmit, %Silence%
		Gui, htuMicOpthWnd: Add, Progress, 	x29 y186 w242 h20 c86B1B7 +Background003300 Range0-%progressrange% vMyProgress -Smooth, %progressrange%
		Gui, htuMicOpthWnd: Add, Text, 			x285 y7 +BackgroundTrans, Balanced
		Gui, htuMicOpthWnd: Add, Text, 			x302 y20 +BackgroundTrans, Vol.
		Gui, htuMicOpthWnd: Add, Text, 			xp80 y7 +BackgroundTrans, Speeds
		Gui, htuMicOpthWnd: Add, Slider, 		x298 y40 h165 vVolumControl1 gSlideD +BackgroundTrans Vertical +range1-20 tickinterval1-20 AltSubmit, %VolumControl1%
		Gui, htuMicOpthWnd: Add, Slider, 		xp50 y40 h165 vchgspeed gSlideE +BackgroundTrans Vertical +range1-100 tickinterval1-100 AltSubmit, %chgspeed%
		Gui, htuMicOpthWnd: Add, Slider, 		xp40 y40 h165 vctrlspeed gSlideF +BackgroundTrans Vertical +range1-100 tickinterval1-100 AltSubmit, %ctrlspeed%
		Gui, htuMicOpthWnd: Add, Slider, 		xp40 y40 h165 vSampleLength gSlideG +BackgroundTrans Vertical +range1-100 tickinterval1-100 AltSubmit, %SampleLength%
		Gui, htuMicOpthWnd: font, s6 w400
		Gui, htuMicOpthWnd: Add, Text, 			x354 y23 +BackgroundTrans, up
		Gui, htuMicOpthWnd: Add, Text, 			x382 y23 +BackgroundTrans, Sampling
		Gui, htuMicOpthWnd: Add, Text, 			x426 y23 +BackgroundTrans, Sample
		Gui, htuMicOpthWnd: Add, Text, 			x349 y31 +BackgroundTrans, down
		Gui, htuMicOpthWnd: Add, Text, 			x390 y31 +BackgroundTrans, rate
		Gui, htuMicOpthWnd: Add, Text, 			x428 y31 +BackgroundTrans, lenght
		*/
		Gui, htuMicOpthWnd: font, s7 w700
		Gui, htuMicOpthWnd: Add, Text, 			x271 y207 +BackgroundTrans c000000, %credits%
		Gui, htuMicOpthWnd: Add, Text, 			x270 y206 +BackgroundTrans c728395 gOPP, %credits%
		Gui, htuMicOpthWnd: Color, 2C3D4D
		Gui, htuMicOpthWnd: Show, 					w470 h220, %apptitle% - Mic settings
	}
Return

MicThresholdSlide:  ; obere schwelle
	save_settings()
	Gui,Submit,NoHide
	tooltip %MicThreshold%
	SetTimer, RemoveToolTip, 500
return

MicHoldSlide:  ; obere schwelle
	save_settings()
	Gui,Submit,NoHide
	tooltip %MicHold%
	SetTimer, RemoveToolTip, 500
return

Slide:  ; obere schwelle
	If (ObereSchwelle<=UntereSchwelle) {
		UntereSchwelle:=ObereSchwelle-1
		GuiControl, htu:, UntereSchwelle, %UntereSchwelle%
	}
	If (ObereSchwelle<=Silence) {
		Silence:=ObereSchwelle-2
		GuiControl, htu:, Silence, %Silence%
	}
	save_settings()
	Gui,Submit,NoHide
	tooltip %ObereSchwelle%
	SetTimer, RemoveToolTip, 500
return

SlideB: ; untere schwelle
	If (UntereSchwelle>=ObereSchwelle) {
		ObereSchwelle:=UntereSchwelle+1
		GuiControl, htu:, ObereSchwelle, %ObereSchwelle%
	}
	If (UntereSchwelle<=Silence) {
		Silence:=UntereSchwelle-1
		GuiControl, htu:, Silence, %Silence%
	}
	save_settings()
	Gui,Submit,NoHide
	tooltip %untereSchwelle%
	SetTimer, RemoveToolTip, 500
return

SlideC: ; deadzone aka silence
	If (Silence>=UntereSchwelle) {
		UntereSchwelle:=Silence+1
		GuiControl, htu:, UntereSchwelle, %UntereSchwelle%
	}
	If (Silence>=ObereSchwelle) {
		ObereSchwelle:=Silence+2
		GuiControl, htu:, ObereSchwelle, %ObereSchwelle%
	}
	save_settings()
	Gui,Submit,NoHide
	tooltip %Silence%
	SetTimer, RemoveToolTip, 500
return

SlideD: ; balance
	save_settings()
	Gui,Submit,NoHide
	tooltip %VolumControl1%
	SetTimer, RemoveToolTip, 500
return

SlideE: ; up down
	(chgspeed>85) ? chgspeed:=85
	((chgspeed+15)>ctrlspeed) ? ctrlspeed:=chgspeed+15
	save_settings()
	Gui,Submit,NoHide
	tooltip %chgSpeed%
	SetTimer, RemoveToolTip, 500
return

SlideF: ; Sampling rate
	((ctrlspeed-15)<chgSpeed) ? chgSpeed:=ctrlspeed-15
	(ctrlspeed<16) ? ctrlspeed:=16
	save_settings()
	Gui,Submit,NoHide
	tooltip %ctrlspeed%
	ctrlspeedn:=ctrlspeed*10
	SetTimer, RemoveToolTip, 500
	SetTimer, Check_s2, %ctrlspeedn%
return

SlideG: ; SampleLength
	save_settings()
	Gui,Submit,NoHide
	tooltip %SampleLength%
	SetTimer, RemoveToolTip, 500
return

RemoveToolTip:
	SetTimer, RemoveToolTip, Off
	ToolTip
return

RefreshGUI_s2:
	Thread, Interrupt, 15, 20
	vol:=_GetLevel("s", BalancedStrip, 1)
	vol*=(VolumControl1+1)
	;nprogressrange:=(progressrange*(VolumControl1+1))*5
	If (menuitemvalue<>vol) OR !vol {
		;GuiControl, htu:, MyProgress, Range0-%nprogressrange%
		GuiControl, htu:, MyProgress, %vol%
		If (vol>=Silence) and (vol<=untereSchwelle)
			GuiControl, htu: +cFFFF00 +Redraw, MyProgress
		If (vol>=ObereSchwelle)
			GuiControl, htu: +cff0000 +Redraw, MyProgress
		If (vol<=Silence)
			GuiControl, htu: +c70C399 +Redraw, MyProgress
		If (vol<=ObereSchwelle) and (vol>=untereSchwelle)
			GuiControl, htu: +c00FF00 +Redraw, MyProgress

		(WTFTitle>=0) ? WTFTitle()
		menuitemvalue:=vol
	}
Return

Mutes:
	GetAllMutes()
Return

Check_S0:
	Thread, Interrupt, 15, 20
	micvol:=_GetLevel("s", 0, 0)
	micmute:=_GetMute("s", 0)

	If (MicOpthWnd) {
		cmv:=Round(micvol,0)
		If (cmc=5) {
			GuiControl, htuMicOpthWnd:, CurLev, %cmv%
			cmc:=0
		} Else
			cmc+=1
	}

	If (!micmute) {
		; tooltip, %micvol%
		If (micvol<MicThreshold) AND (miconce) {
			ms:=MicHold*-1
			SetTimer, mic_off, %ms%
			miconce:=0
		} Else If (micvol>MicThreshold) AND (!miconce) {
			italk:=1
			SetTimer, mic_off, off
			_SetGain("s", 0, 0)
			miconce:=1
		}
	}
	IF (micvol>=(Silence/10)) && !MICWARNONCE {
            MICWARNONCE:=1
		SetTimer, Mutes, Off
            s0:=-1
		Gui, MicOnAir:Color, cffff00
	} Else {
		SetTimer, Mutes, 10
            MICWARNONCE:=0
	}

Return

mic_off:
	_SetGain("s", 0, -60)
	italk:=0
Return

Check_S2:
	Critical
	Gain:=_GetGain("s", BalancedStrip)
	nvol:=0
	loops:=SampleLength*1000
	Loop, %loops%
		nvol+=_GetLevel("s", BalancedStrip, 1)

	nvol/=loops
	volStateOnce:=(vol<>nvol) ? 1 : 0
	vol:=nvol
	vol*=(VolumControl1+1)

	If !vol {
		If isDownBlocked
			volstop_s2()
		isDownBlocked:=0
		isTalking:=0
	} Else
		isTalking:=1

	isTalkingOnce:=(TalkState<>(isTalking+italk)) ? 1 : 0
	TalkState:=isTalking+italk

	If isTalkingOnce {
		If !TalkState { ; nobody is talking
			_SetComp(0, "0.6")
			_SetGate(0, "1.2")
			_SetGain("r",,r_noSpeak)
		}
		If (isTalking=1) { ; somebody is talking
			_SetComp(0, 0)
			_SetGate(0, AddGate)
			_SetGain("r",,r_oneSpeak)
		}
		If (italk=1) { ; i talk
			_SetComp(0, "2.1")
			_SetGate(0, "0.6")
			_SetGain("r",,r_oneSpeak)
		}
		If (TalkState=2) { ; we are talking
			_SetComp(0, "2.1")
			_SetGate(0, AddGate-1)
			_SetGain("r",,r_allSpeak)
		}
	}

	(vol<=Silence) ? volState:=0 ; nothing
	((vol>=Silence) AND (vol<=untereSchwelle)) ? volState:=1 ; up
	((vol<=ObereSchwelle) AND (vol>=untereSchwelle)) ? volState:=2 ; nothing
	(vol>=ObereSchwelle) ? volState:=3 ; down

	If volStateonce {
		If !isChangesBlocked {
			If (ctrlv="n") {
				If !volState {
					volstop_s2()
			    BlockUp()
				}
				If (volState=1) {
			  	volcontrol_s(vol, gain) ; hit up
					BlockDown()
				}
				If (volState=2) {
					volstop_s2()
					BlockChanges()
					BlockUp()
				}
				If (volState=3) {
			  	volcontrol_s(vol, gain) ; hit dn
				}
			}
			Else {
				If !volState {
					volstop_s2()
			    BlockUp()
				}
				If (volState=1) {
					SetTimer, %slidedn%, Off
					SetTimer, %slideup%, -1 ; hit up
					BlockDown()
				}
				If (volState=2) {
					volstop_s2()
					BlockDown()
				}
				If (volState=3) {
					SetTimer, %slideup%, Off
					SetTimer, %slidedn%, -1 ; hit dn
				}
			}
		}
	}
	; ToolTip, %vol%`n%Untereschwelle%`n%obereschwelle%`n%nprogressrange%
	menuitemvalue:=vol
Return

Dummy:
Return

OPP:
	Run, http://paypal.me/BorisWeinrich
Return

htuGUIClose:
GuiCloseHtu:
	save_settings()
	Gui, htu: Destroy
	GUIhWnd:=""
	SetTimer, RefreshGUI_s2, Off
	cleanup_before_exit("Exit App",0)
	ExitApp
Return

htuMicOpthWndGUIClose:
GuiCloseHtuMicOpthWnd:
	MicOpthWnd:=""
	Gui, htuMicOpthWnd: Destroy
Return

Exit:
	_SetGain("r",,r_noSpeak)
	save_settings()
	Gui, htu: Destroy
	GUIhWnd:=""
	cleanup_before_exit("Exit App",0)
	ExitApp
Return

MicToggle:
	MicToggle()
Return
; vk7C::MicToggle()