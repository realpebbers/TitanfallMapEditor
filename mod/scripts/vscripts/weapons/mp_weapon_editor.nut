global function Editor_Init
global function RegisterEditorRemoteCallbacks
global function NewEditorMode
global function GetEditorModes
#if SERVER
global function GetAllProps
global function AddProp
global function RemoveProp
#elseif CLIENT
global function UICallback_SaveMap
global function UICallback_LoadMap
global function UICallback_DeleteMap
#endif

global function OnWeaponActivate_editor
global function OnWeaponDeactivate_editor
global function OnWeaponPrimaryAttack_editor

#if SERVER
struct {
    array<EditorMode> editorModes
    array<entity> allProps
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
    RegisterEditorMode(EditorModeExtend_Init())
    RegisterEditorMode(EditorModeDelete_Init())
//    RegisterEditorMode(EditorModeBulkPlace_Init())

    #if CLIENT
    RegisterConCommandTriggeredCallback("+use", ChangeEditorMode)

    RunUIScript("UpdateCurrentMap", GetMapName())
    UI_Editor_Init()
    UI_Editor_ToggleUI()
    #elseif SERVER
    AddClientCommandCallback("editor_mode", ClientCommand_EditorMode)
    AddClientCommandCallback("savemap", ClientCommand_Save)
    AddClientCommandCallback("loadmap", ClientCommand_Load)
    AddClientCommandCallback("deletemap", ClientCommand_DeleteMap)
    AddClientCommandCallback("hide_props", ClientCommand_HideProp)
    #endif
}

void function OnWeaponActivate_editor(entity weapon) {
    entity player = weapon.GetOwner()

    #if CLIENT
    UI_Editor_ToggleUI()
    #endif
    if(player.p.selectedEditorMode.activateCallback == null) {
        #if CLIENT
        UI_Editor_UpdateUI( GetEditorModes()[0] )
        #endif
        player.p.selectedEditorMode = GetEditorModes()[0]
        player.p.selectedEditorModeIndex = 0
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


void function SetCurrentEditorMode(entity player, int idx)
{
    if(!IsValid( player )) return
    
    if( idx == player.p.selectedEditorModeIndex )
        return

    if(player.p.selectedEditorMode.deactivateCallback != null)
    {
        player.p.lastEditorMode = player.p.selectedEditorMode
        player.p.selectedEditorMode.deactivateCallback(player)
    }

    player.p.selectedEditorMode = GetEditorModes()[idx]
    player.p.selectedEditorModeIndex = idx

    #if CLIENT
    UI_Editor_UpdateUI( GetEditorModes()[idx] )
    #endif

    player.p.selectedEditorMode.activateCallback(player)
}

void function RegisterEditorMode(EditorMode mode) {
    file.editorModes.append(mode)
}

#if CLIENT
void function UICallback_SaveMap( int map ) {
    entity player = GetLocalClientPlayer()

    player.ClientCommand("savemap " + map)
}

void function UICallback_LoadMap( int map ) {
    entity player = GetLocalClientPlayer()

    player.ClientCommand("loadmap " + map)
}

void function UICallback_DeleteMap( int map ) {
    entity player = GetLocalClientPlayer()

    player.ClientCommand("deletemap")
}

void function ChangeEditorMode( var button ) {
    entity player = GetLocalClientPlayer()

    NextEditorMode(player)
    player.ClientCommand("editor_mode")
}

#elseif SERVER
bool function ClientCommand_EditorMode(entity player, array<string> args) {
    NextEditorMode(player)
    return true
}

bool function ClientCommand_Save(entity player, array<string> args) {
    if (args.len() == 0) return false

    int map = args[0].tointeger()
    SavePropMap(map)

    return true
}

bool function ClientCommand_Load(entity player, array<string> args) {
    if (args.len() == 0) return false

    int map = args[0].tointeger()
    thread LoadPropMap(map)

    return true
}

bool function ClientCommand_DeleteMap(entity player, array<string> args) {
    thread ClearPropMap()
}
#endif

void function NextEditorMode(entity player) {
    int length = GetEditorModes().len()
    int i = player.p.selectedEditorModeIndex + 1

    if (i >= length) i = 0
    
    SetCurrentEditorMode(player, i)
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

#if SERVER
array<entity> function GetAllProps() {
    return file.allProps
}

void function AddProp(entity prop) {
    file.allProps.append(prop)
}

void function RemoveProp(entity prop) {
    file.allProps.remove(file.allProps.find(prop))
}

bool function ClientCommand_HideProp(entity player, array<string> args) {
    player.p.hideProps = !player.p.hideProps
    return true
}
#endif