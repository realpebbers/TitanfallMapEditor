untyped

global function UI_Editor_Init
global function UI_Editor_ToggleUI
global function UI_Editor_UpdateUI

const asset CONSOLE = $"ui/cockpit_console_text_top_left.rpak"

struct {
    bool enabled

    var titleRUI
    var modeRUI
    var descRUI
} file;

void function UI_Editor_Init() {
    var rui
    

    rui = RuiCreate( CONSOLE, clGlobal.topoCockpitHudPermanent, RUI_DRAW_COCKPIT, 0 )
	RuiSetInt( rui, "maxLines", 1 )
	RuiSetInt( rui, "lineNum", 1 )
	RuiSetFloat2( rui, "msgPos", <0.2, 0.05, 0.0> )
	RuiSetString( rui, "msgText", "Editor Mode" )
	RuiSetFloat( rui, "msgFontSize", 48.0 )
	RuiSetFloat( rui, "msgAlpha", 0.9 )
	RuiSetFloat( rui, "thicken", 0.0 )
	RuiSetFloat3( rui, "msgColor", <1.0, 1.0, 1.0> )
	file.titleRUI = rui;

	rui = RuiCreate( CONSOLE, clGlobal.topoCockpitHudPermanent, RUI_DRAW_COCKPIT, 0 )
	RuiSetInt( rui, "maxLines", 1 )
	RuiSetInt( rui, "lineNum", 1 )
	RuiSetFloat2( rui, "msgPos", <0.2, 0.1, 0.0> )
	RuiSetString( rui, "msgText", "Mode: None" )
	RuiSetFloat( rui, "msgFontSize", 32.0 )
	RuiSetFloat( rui, "msgAlpha", 0.9 )
	RuiSetFloat( rui, "thicken", 0.0 )
	RuiSetFloat3( rui, "msgColor", <1.0, 1.0, 1.0> )
	file.modeRUI = rui

	rui = RuiCreate( CONSOLE, clGlobal.topoCockpitHudPermanent, RUI_DRAW_COCKPIT, 0 )
	RuiSetInt( rui, "maxLines", 2 )
	RuiSetInt( rui, "lineNum", 2 )
	RuiSetFloat2( rui, "msgPos", <0.2, 0.1, 0.0> )
	RuiSetString( rui, "msgText", "Help text" )
	RuiSetFloat( rui, "msgFontSize", 32.0 )
	RuiSetFloat( rui, "msgAlpha", 0.9 )
	RuiSetFloat( rui, "thicken", 0.0 )
	RuiSetFloat3( rui, "msgColor", <1.0, 1.0, 1.0> )
	file.descRUI = rui

    file.enabled = true
}

void function UI_Editor_UpdateUI(EditorMode mode) {
	RuiSetString( file.modeRUI, "msgText", "Mode: " + mode.modeName )
	RuiSetString( file.descRUI, "msgText", mode.modeDesc )
}

void function UI_Editor_ToggleUI() {
    if (file.enabled) {
        file.enabled = false

        RuiSetFloat( file.titleRUI, "msgAlpha", 0.0 );
        RuiSetFloat( file.modeRUI, "msgAlpha", 0.0 );
        RuiSetFloat( file.descRUI, "msgAlpha", 0.0 );
    } else {
        file.enabled = true

        RuiSetFloat( file.titleRUI, "msgAlpha", 0.9 );
        RuiSetFloat( file.modeRUI, "msgAlpha", 0.9 );
        RuiSetFloat( file.descRUI, "msgAlpha", 0.9 );
    }
}