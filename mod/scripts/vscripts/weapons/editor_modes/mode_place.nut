untyped

global function EditorModePlace_Init

global function ServerCallback_NextProp
global function ServerCallback_OpenModelMenu
#if SERVER
global function GetPlacedProps
#endif
#if SERVER
global function ClientCommand_Model

global function ClientCommand_UP_Server
global function ClientCommand_DOWN_Server
#elseif CLIENT
global function ClientCommand_UP_Client
global function ClientCommand_DOWN_Client
global function ServerCallback_UpdateModel
global function ServerCallback_UpdateModelBB
global function UICallback_SelectModel
#endif

#if SERVER
struct {
    float offsetZ = 0
    asset currAsset = $"models/error.mdl" // Temporary
    int currIdx = 0
    entity currProp
    entity currPropReal
    
    table<entity, float> snapSizes
    table<entity, float> pitches
    table<entity, float> offsets
    array<entity> allProps

} file
#elseif CLIENT
struct {
    float offsetZ = 0
    asset currAsset = $"models/error.mdl" // Temporary
    entity currProp
    entity currPropReal

    float snapSize = 1
    float pitch = 0
    vector currMin
    vector currMax
    vector currCenter
} file
#endif

#if SERVER
array<entity> function GetPlacedProps()
{
    return file.allProps
}
#endif

EditorMode function EditorModePlace_Init() 
{
    // save and load functions
    #if SERVER
    AddClientCommandCallback("model", ClientCommand_Model)
    
    #elseif CLIENT
    RegisterConCommandTriggeredCallback("+scriptCommand2", OpenModelMenu)
    #endif

    return NewEditorMode(
        "Place",
        "Place new props on the map.",
        EditorModePlace_Activation,
        EditorModePlace_Deactivation,
        EditorModePlace_Place
    )
}

void function EditorModePlace_Activation(entity player)
{
    #if SERVER
    if( !(player in file.snapSizes) )
    {
        file.snapSizes[player] <- 1
    }
    if( !(player in file.pitches) )
    {
        file.pitches[player] <- 0
    }
    if( !(player in file.offsets) )
    {
        file.offsets[player] <- 0
    }
    #endif
    
    StartNewPropPlacement(player)
}

void function EditorModePlace_Deactivation(entity player)
{
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

// TODO: Model selection
void function ServerCallback_OpenModelMenu( entity player ) {
    #if SERVER
        //Remote_CallFunction_Replay( player, "ServerCallback_OpenModelMenu", player )
    #elseif CLIENT
    if(player != GetLocalClientPlayer()) return;
    player = GetLocalClientPlayer()
    
    if (!IsValid(player)) return
    if (!IsAlive(player)) return
    
    //RunUIScript("OpenModelMenu", player.p.selectedProp.section)
    #endif
}

void function ServerCallback_NextProp( entity player )
{
}


void function StartNewPropPlacement(entity player)
{
    // incoming
    #if SERVER
    SetProp(
        player, 
        CreatePropDynamic( 
            file.currAsset, 
            <0, 0, file.offsets[player]>, 
            <0, 0, 0>, 
            SOLID_VPHYSICS // It has physics to calculate the bounding box
        )
    )
    SetRealProp(
        player, 
        CreatePropDynamic( 
            file.currAsset, 
            <0, 0, file.offsets[player]>, 
            <0, 0, 0>, 
            SOLID_VPHYSICS // It has physics to calculate the bounding box
        )
    )

    GetProp(player).NotSolid() // The visual is done by the client
    GetProp(player).Hide()
    GetRealProp(player).Hide()
    
    #elseif CLIENT
	SetProp(
        player, 
        CreateClientSidePropDynamic( 
            <0, 0, file.offsetZ>, 
            <0, 0, 0>, 
            file.currAsset
        )
    )
    SetRealProp(
        player,
        CreateClientSidePropDynamic(
            <0, 0, file.offsetZ>, 
            <0, 0, 0>, 
            file.currAsset
        )
    )

    DeployableModelHighlight( GetProp(player) )

	GetProp(player).kv.renderamt = 255
	GetProp(player).kv.rendermode = 3
	GetProp(player).kv.rendercolor = "255 255 255 150"

    GetRealProp(player).Hide()

    #endif

    thread PlaceProxyThink(player)
}

void function PlaceProp(entity player)
{
    #if SERVER
    file.allProps.append(GetProp(player))
    GetProp(player).Show()
    GetProp(player).Solid()
    GetProp(player).AllowMantle()
    GetProp(player).SetScriptName("editor_placed_prop")

    GetRealProp(player).Destroy()
    SetRealProp(player, null)
    
    // prints prop info to the console to save it
    vector myOrigin = GetProp(player).GetOrigin()
    vector myAngles = GetProp(player).GetAngles()

    string positionSerialized = myOrigin.x.tostring() + "," + myOrigin.y.tostring() + "," + myOrigin.z.tostring()
	string anglesSerialized = myAngles.x.tostring() + "," + myAngles.y.tostring() + "," + myAngles.z.tostring()
    //printl("[editor]" + string(GetAssetFromPlayer(player)) + ";" + positionSerialized + ";" + anglesSerialized)
    printl("[editor] " + file.currAsset )

    #elseif CLIENT
    if(player != GetLocalClientPlayer()) return;

    // Tell the server about the client's position so the delay isnt noticable

    GetProp(player).Destroy()
    GetRealProp(player).Destroy()
    SetProp(player, null)
    SetRealProp(player, null)
    #endif
}


void function PlaceProxyThink(entity player)
{
    float gridSize = 32

    while( IsValid( GetProp(player) ) )
    {
        if(!IsValid( player )) return
        if(!IsAlive( player )) return

        GetProp(player).SetModel( file.currAsset )
        GetRealProp(player).SetModel( file.currAsset )

	    TraceResults result = TraceLine(
            player.EyePosition() + 5 * player.GetViewForward(),
            player.GetOrigin() + 200 * player.GetViewForward(), 
            [player, GetRealProp(player), GetProp(player)], // exclude the prop too
            TRACE_MASK_SHOT, TRACE_COLLISION_GROUP_PLAYER
        )

        vector origin = result.endPos

        // Uses bounding boxes as a grid instead of a set size
        vector smartGrid
        #if SERVER
        smartGrid = GetRealProp(player).GetBoundingMaxs() - GetRealProp(player).GetBoundingMins()
        #elseif CLIENT
        smartGrid = file.currMax - file.currMin
        #endif

        smartGrid = GetSafeGrid(smartGrid)

        origin.x = round(origin.x / smartGrid.x) * smartGrid.x
        origin.y = round(origin.y / smartGrid.y) * smartGrid.y
        origin.z = round(origin.z / smartGrid.z) * smartGrid.z

        vector offset = player.GetViewForward()
        
        // convert offset to -1 if value it's less than -0.5, 0 if it's between -0.5 and 0.5, and 1 if it's greater than 0.5

        vector ang = VectorToAngles(player.GetViewForward())

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

        ang.x = 0
        ang.y = floor(smartClamp(ang.y + 45, -360, 360) / 90) * 90
        ang.z = floor(smartClamp(ang.z + 45, -360, 360) / 90) * 90

        origin = origin + offset

        vector angles = VectorToAngles( -1 * player.GetViewVector() )

        angles.x = GetProp(player).GetAngles().x
        angles.y = floor(smartClamp(angles.y - 45, -360, 360) / 90) * 90
        #if CLIENT
        angles.z += file.pitch
        #elseif SERVER
        angles.z += file.pitches[player]
        #endif

        GetRealProp(player).SetOrigin( origin )
        GetRealProp(player).SetAngles( angles )

        #if SERVER
        // Tell client about the BB
        vector mins = GetProp(player).GetBoundingMins()
        vector maxs = GetProp(player).GetBoundingMaxs()

        Remote_CallFunction_NonReplay(
            player, 
            "ServerCallback_UpdateModelBB",
            mins.x,
            mins.y,
            mins.z,
            maxs.x,
            maxs.y,
            maxs.z
        )
        #endif

        /*
        This makes sure that the spot the prop is actually spawned in is at the boundingbox min
        so the offset that respawn may have added isnt applied
        */
        #if CLIENT
        vector relMins = file.currMin
        vector absMins = relMins + GetRealProp(player).GetOrigin()
        vector offsetC = -(absMins - origin)

        GetProp(player).SetOrigin(origin + offsetC)
        #elseif SERVER
        // i did the math on paper
        // converted it to this
        // and it actually worked????? wtf
        vector relMins = GetRealProp(player).GetBoundingMins()
        vector absMins = relMins + GetRealProp(player).GetOrigin()
        vector offsetC = -(absMins - origin)

        GetProp(player).SetOrigin(origin + offsetC)
        #endif
        GetProp(player).SetAngles( angles )

        
        #if SERVER
        wait 0.001
        #elseif CLIENT
        // wait kind of long so client has time to recieve
        wait 0.15
        #endif
    }
}

vector function GetSafeGrid(vector grid) {
    grid.x = fAbs(grid.x)
    grid.y = fAbs(grid.y)
    grid.z = fAbs(grid.z)

    //planes please dont fuck me
    if (grid.x == 0) grid.x = 0.01
    if (grid.y == 0) grid.y = 0.01
    if (grid.z == 0) grid.z = 0.01

    return grid
}

entity function GetProp(entity player)
{
    return file.currProp 
}

entity function GetRealProp(entity player) {
    return file.currPropReal
}

void function SetProp(entity player, entity prop)
{
    file.currProp = prop // TODO: Per player curr prop
}

void function SetRealProp(entity player, entity prop) {
    file.currPropReal = prop
}

/*PropInfo function NewPropInfo(string section, int index)
{
    PropInfo prop
    prop.section = section
    prop.index = index
    return prop
}*/

#if SERVER
bool function ClientCommand_UP_Server(entity player, array<string> args)
{
    file.offsets[player] += 64
    return true
}

bool function ClientCommand_DOWN_Server(entity player, array<string> args)
{
    file.offsets[player] -= 64
    return true
}

bool function ChangeSnapSize( entity player, array<string> args )
{
    if (args[0] == "") return true
    
    if( !(player in file.snapSizes) )
    {
        file.snapSizes[player] <- args[0].tofloat()
    }
    file.snapSizes[player] = args[0].tofloat()

    return true
}

bool function ClientCommand_Section(entity player, array<string> args) {
    return false
}

bool function ChangeRotation( entity player, array<string> args )
{
    if (args[0] == "") return true
    
    printl(args[0].tofloat())
    if( !(player in file.pitches) )
    {
        file.pitches[player] <- args[0].tofloat()
    }
    file.pitches[player] = args[0].tofloat()

    return true
}

#elseif CLIENT
bool function ClientCommand_UP_Client(entity player)
{
    GetLocalClientPlayer().ClientCommand("moveUp")
    file.offsetZ += 64
    return true
}

bool function ClientCommand_DOWN_Client(entity player)
{
    GetLocalClientPlayer().ClientCommand("moveDown")
    file.offsetZ -= 64
    return true
}
#endif

#if SERVER
bool function ClientCommand_Model(entity player, array<string> args) {
    if(args.len() > 0 && args[0] == "-") {
        file.currIdx--
    } else {
        file.currIdx++
    }

    if (args.len() > 0 && args[0] != "-") {
        if (args[0] == "start") {
            file.currIdx = 0
            thread IncrementIdx(player)
        } else {
            file.currIdx = indexOf(GetAssets(), CastStringToAsset(args[0]))
        }
    }

    SetModel(player, file.currIdx)
	return true
}

void function IncrementIdx(entity player) {
    while(file.currIdx < GetAssets().len() - 1) {
        file.currIdx++
        SetModel(player, file.currIdx)
        wait 0.5
    }
}
#endif

void function SetModel(entity player, int idx) {
    file.currAsset = GetAssets()[idx]
    
    #if SERVER
    Remote_CallFunction_NonReplay(player, "ServerCallback_UpdateModel", idx)
    #endif
}

asset function CastStringToAsset( string val ) {
    // pain
    // no way to do dynamic assets so 
	return expect asset ( compilestring( "return $\"" + val + "\"" )() )
}

#if SERVER
bool function ClientCommand_Next(entity player, array<string> args) {
    ServerCallback_NextProp(player)
    return true
}
#endif


// util funcs
// O(n) might need to be improved
float function round(float x) {
    return expect float( RoundToNearestInt(x) )
}

bool function contains(array<string> sec, string val) {
    foreach(p in sec) {
        if (val == p) {
            return true
        }
    }
    return false
}

int function indexOf(array<asset> arr, asset val) {
    int idx = 0
    foreach(p in arr) {
        if (val == p) {
            return idx
        }
        idx++
    }
    return -1
}

float function fAbs(float x) {
    float res = 0.0;
    if (x < 0) {
        res = -x
    } else {
        res = x;
    }
    return res
}


// CALLBACKS
#if CLIENT
void function ServerCallback_UpdateModel( int idx ) {
    if(idx == -1) {
        print("-1 bruh")
        return
    }
    file.currAsset = GetAssets()[idx]
}

// Cant calculate bounding box in client
void function ServerCallback_UpdateModelBB(float minX, float minY, float minZ, float maxX, float maxY, float maxZ) {
    vector mins = <minX, minY, minZ>
    vector maxs = <maxX, maxY, maxZ>
    vector center = (mins + maxs) / 2

    file.currMin = mins
    file.currMax = maxs
    file.currCenter = center
}

void function OpenModelMenu( var button ) {
    RunUIScript("OpenModelMenu")
}

void function UICallback_SelectModel(string name) {
    GetLocalClientPlayer().ClientCommand("model models/" + name + ".mdl")
}
#endif
