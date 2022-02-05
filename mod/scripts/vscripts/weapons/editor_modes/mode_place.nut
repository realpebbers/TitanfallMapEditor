untyped

global function EditorModePlace_Init

#if SERVER
global function CC_Model
#elseif CLIENT
global function ServerCallback_UpdateModel
global function UICallback_SelectModel
#endif

EditorMode function EditorModePlace_Init() 
{
    // save and load functions
    #if SERVER
    AddClientCommandCallback("model", CC_Model)
    AddClientCommandCallback("MoveOffset", CC_MoveOffset)
    #endif

    return NewEditorMode(
        "Place",
        "Place new props on the map.",
        EditorModePlace_Activation,
        EditorModePlace_Deactivation,
        EditorModePlace_Place
    )
}

#if CLIENT
void function RegisterButtonCallbacks() {
    RegisterConCommandTriggeredCallback("+scriptCommand2", OpenModelMenu)

    // (From Icepick)
    // Fine rotation using numpad
    RegisterButtonReleasedCallback( MOUSE_WHEEL_UP, KeyPress_Up );
	RegisterButtonReleasedCallback( MOUSE_WHEEL_DOWN, KeyPress_Down );

	RegisterButtonPressedCallback( KEY_PAD_8, KeyPress_Forward );
	RegisterButtonPressedCallback( KEY_PAD_2, KeyPress_Backward );
	RegisterButtonPressedCallback( KEY_PAD_4, KeyPress_Left );
	RegisterButtonPressedCallback( KEY_PAD_6, KeyPress_Right );
	RegisterButtonPressedCallback( KEY_PAD_5, KeyPress_Reset );
}

void function DeregisterButtonCallbacks() {
    DeregisterConCommandTriggeredCallback("+scriptCommand2", OpenModelMenu)

    DeregisterButtonReleasedCallback( MOUSE_WHEEL_UP, KeyPress_Up );
	DeregisterButtonReleasedCallback( MOUSE_WHEEL_DOWN, KeyPress_Down );

	DeregisterButtonPressedCallback( KEY_PAD_8, KeyPress_Forward );
	DeregisterButtonPressedCallback( KEY_PAD_2, KeyPress_Backward );
	DeregisterButtonPressedCallback( KEY_PAD_4, KeyPress_Left );
	DeregisterButtonPressedCallback( KEY_PAD_6, KeyPress_Right );
	DeregisterButtonPressedCallback( KEY_PAD_5, KeyPress_Reset );
}
#endif

void function EditorModePlace_Activation(entity player)
{
    #if CLIENT
    RegisterButtonCallbacks()
    #endif
    StartNewPropPlacement(player)
}

void function EditorModePlace_Deactivation(entity player)
{
    #if CLIENT
    DeregisterButtonCallbacks()
    #endif
    if(IsValid(GetProp(player)))
    {
        GetProp(player).Destroy()
    }
}

void function EditorModePlace_Place(entity player)
{
    PlaceProp(player)
    StartNewPropPlacement(player)
}

void function StartNewPropPlacement(entity player)
{
    // incoming
    #if SERVER
    SetProp(
        player, 
        CreatePropDynamic( 
            GetAsset(player), 
            player.p.offsetVector, 
            <0, 0, 0>, 
            SOLID_VPHYSICS  
        )
    )

    GetProp(player).NotSolid() // The visual is done by the client
    GetProp(player).Hide()
    
    #elseif CLIENT
	SetProp(
        player, 
        CreateClientSidePropDynamic( 
            player.p.offsetVector, 
            <0, 0, 0>, 
            GetAsset(player)
        )
    )

    DeployableModelHighlight( GetProp(player) )

	GetProp(player).kv.renderamt = 255
	GetProp(player).kv.rendermode = 3
	GetProp(player).kv.rendercolor = "255 255 255 150"

    #endif

    thread PlaceProxyThink(player)
}

void function PlaceProp(entity player)
{
    #if SERVER
    AddProp(GetProp(player))
    if (!player.p.hideProps) {
        GetProp(player).Show()
    }
    GetProp(player).Solid()
    GetProp(player).AllowMantle()
    GetProp(player).kv.solid = SOLID_VPHYSICS
    GetProp(player).SetScriptName("editor_placed_prop")

    // prints prop info to the console to save it
    vector myOrigin = GetProp(player).GetOrigin()
    vector myAngles = GetProp(player).GetAngles()

    printl(serialize("place", string(GetAsset(player)), myOrigin, myAngles))

    #elseif CLIENT
    if(player != GetLocalClientPlayer()) return;

    // Tell the server about the client's position so the delay isnt noticable

    GetProp(player).Destroy()
    SetProp(player, null)
    #endif
}

void function PlaceProxyThink(entity player)
{
    float gridSize = 16

    while( IsValid( GetProp(player) ) )
    {
        if(!IsValid( player )) return
        if(!IsAlive( player )) return

        GetProp(player).SetModel( GetAsset(player) )

	    TraceResults result = TraceLine(
            player.EyePosition() + 5 * player.GetViewForward(),
            player.GetOrigin() + 200 * player.GetViewForward(), 
            [player, GetProp(player)], // exclude the prop too
            TRACE_MASK_SHOT, TRACE_COLLISION_GROUP_PLAYER
        )

        vector origin = result.endPos

        origin.x = round(origin.x / gridSize) * gridSize
        origin.y = round(origin.y / gridSize) * gridSize
        origin.z = round(origin.z / gridSize) * gridSize

        vector offset = player.GetViewForward()
        vector ang = VectorToAngles(player.GetViewForward())

        // convert offset to -1 if value it's less than -0.5, 0 if it's between -0.5 and 0.5, and 1 if it's greater than 0.5

        float functionref(float val, float x, float y) smartClamp = float function(float val, float x, float y)
        {
            // clamp val circularly between x and y, which can be negative
            if(val < x)
            {
                return val + (y - x)
            }
            else if(val > y)
            {
                return val - (y - x)
            }
            return val
        }

        origin = origin + offset + player.p.offsetVector

        vector angles = -1 * VectorToAngles(player.GetViewVector() )

        angles.x = 0
        angles.y = floor(smartClamp((angles.y - 45), -360, 360) / 90) * 90
        angles.z = floor(smartClamp(ang.z + 45, -360, 360) / 90) * 90
        
        GetProp(player).SetOrigin( origin )
        GetProp(player).SetAngles( angles )

        WaitFrame()
    }
}

void function RotationThink() {

}

vector function GetSafeGrid(vector grid) {
    grid.x = fabs(grid.x)
    grid.y = fabs(grid.y)
    grid.z = fabs(grid.z)

    //planes please dont fuck me
    if (grid.x == 0) grid.x = 0.01
    if (grid.y == 0) grid.y = 0.01
    if (grid.z == 0) grid.z = 0.01

    return grid
}


#if SERVER
bool function CC_Model(entity player, array<string> args) {
    if (args.len() == 0) return false
    SetModel(player, indexOf(GetAssets(), CastStringToAsset(args[0])))
	return true
}
#endif



void function SetModel(entity player, int idx) {
    player.p.selectedProp.selectedAsset = GetAssets()[idx]
    
    #if SERVER
    Remote_CallFunction_NonReplay(player, "ServerCallback_UpdateModel", idx)
    #endif
}

// INPUT HANDLER
#if CLIENT
void function KeyPress_Up( var button ) {
	MoveOffset(GetLocalClientPlayer(), 0, 0, 1 );
}
void function KeyPress_Down( var button ) {
	MoveOffset(GetLocalClientPlayer(), 0, 0, -1 );
}

void function KeyPress_Left( var button ) {
	MoveOffset(GetLocalClientPlayer(), 0, -1, 0 );
}
void function KeyPress_Right( var button ) {
	MoveOffset(GetLocalClientPlayer(), 0, 1, 0 );
}

void function KeyPress_Forward( var button ) {
	MoveOffset(GetLocalClientPlayer(), -1, 0, 0 );
}
void function KeyPress_Backward( var button ) {
	MoveOffset(GetLocalClientPlayer(), 1, 0, 0 );
}

void function KeyPress_Reset( var button ) {
	MoveOffset(GetLocalClientPlayer(), -1, -1, -1 );
}

#elseif SERVER
bool function CC_MoveOffset(entity player, array<string> args) {
    MoveOffset(player, args[0].tofloat(), args[1].tofloat(), args[2].tofloat())
    return true
}
#endif

void function MoveOffset(entity player, float x, float y, float z) {
    if (x == -1 && y == -1 && z == -1) {
        player.p.offsetVector = <0,0,0>

        #if CLIENT
        player.ClientCommand("MoveOffset " + x + " " + y + " " + z)
        #endif
        return
    }

    float sensitivity = 16.0
    vector vec = <x, y, z> * sensitivity
    
    #if CLIENT
    player.ClientCommand("MoveOffset " + x + " " + y + " " + z)
    #endif

    player.p.offsetVector = player.p.offsetVector + vec
}

// CALLBACKS
#if CLIENT
void function ServerCallback_UpdateModel( int idx ) {
    if(idx == -1) {
        print("-1 bruh")
        return
    }
    entity player = GetLocalClientPlayer()

    player.p.selectedProp.selectedAsset = GetAssets()[idx]
}

void function OpenModelMenu( var button ) {
    RunUIScript("OpenModelMenu")
}

void function UICallback_SelectModel(string name) {
    GetLocalClientPlayer().ClientCommand("model models/" + name + ".mdl")
}
#endif
