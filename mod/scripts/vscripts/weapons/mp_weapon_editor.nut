global function Editor_Init
global function RegisterEditorRemoteCallbacks
global function NewEditorMode
global function GetEditorModes

global function OnWeaponActivate_editor
global function OnWeaponDeactivate_editor
global function OnWeaponPrimaryAttack_editor

#if SERVER
struct {
    array<EditorMode> editorModes

    
} file;
#elseif CLIENT
struct {
    array<EditorMode> editorModes

    var rui
} file;
#endif

void function Editor_Init() {
    PrecacheWeapon( "mp_weapon_editor" )
    
    RegisterEditorMode(EditorModePlace_Init())

    #if CLIENT
    UI_Editor_Init()
    UI_Editor_ToggleUI()
    #endif
}

void function OnWeaponActivate_editor(entity weapon) {
    entity player = weapon.GetOwner()

    #if CLIENT
    UI_Editor_ToggleUI()
    #endif
    if(player.p.selectedEditorMode.activateCallback == null) {
        player.p.selectedEditorMode = GetEditorModes()[0]
    }

    player.p.selectedEditorMode.activateCallback( player )
}

void function OnWeaponDeactivate_editor(entity weapon) {
    entity player = weapon.GetOwner()
    
    #if CLIENT
    UI_Editor_ToggleUI()
    #endif
    player.p.selectedEditorMode.deactivateCallback(player)
}

var function OnWeaponPrimaryAttack_editor( entity weapon, WeaponPrimaryAttackParams attackParams ) {
    if (! IsValid(weapon.GetOwner())) return
    if (! weapon.GetOwner().IsPlayer()) return

    entity player = weapon.GetOwner()

    player.p.selectedEditorMode.attackCallback( player )
}

void function RegisterEditorRemoteCallbacks() {
    AddCallback_OnRegisteringCustomNetworkVars( RegisterRemoteFunctions )
}

void function RegisterRemoteFunctions() {
    Remote_RegisterFunction( "ServerCallback_UpdateModel" )
    Remote_RegisterFunction( "ServerCallback_UpdateModelBB" )
}


void function SetCurrentEditorMode(entity player, EditorMode mode)
{
    if(!IsValid( player )) return
    
    if( GetEditorModes().find(mode) == GetEditorModes().find(player.p.selectedEditorMode) )
        return

    if(player.p.selectedEditorMode.deactivateCallback != null)
    {
        player.p.lastEditorMode = player.p.selectedEditorMode
        player.p.selectedEditorMode.deactivateCallback(player)
    }

    player.p.selectedEditorMode = mode

    #if CLIENT
    UI_Editor_UpdateUI( mode )
    #endif

    player.p.selectedEditorMode.activateCallback(player)
}

void function RegisterEditorMode(EditorMode mode) {
    file.editorModes.append(mode)
}

array<EditorMode> function GetEditorModes()
{
    return file.editorModes
}

EditorMode function NewEditorMode(
    string modeName,
    string modeDesc,
    void functionref( entity player ) activateCallback,
    void functionref( entity player ) deactivateCallback,
    void functionref( entity player ) attackCallback
) {
    EditorMode mode

    mode.modeName = modeName
    mode.modeDesc = modeDesc
    mode.activateCallback = activateCallback
    mode.deactivateCallback = deactivateCallback
    mode.attackCallback = attackCallback

    return mode
}