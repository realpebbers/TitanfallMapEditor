untyped

global function EditorModeBulkPlace_Init

#if CLIENT
global function ServerCallback_UpdateModelBB
#endif

struct {
    vector last = <69,0,0>
    bool preview = false
} file;

EditorMode function EditorModeBulkPlace_Init() 
{
    // save and load functions
    return NewEditorMode(
        "Bulk Place",
        "Place multiple probs quick af (Experimental)",
        EditorModeBulkPlace_Activation,
        EditorModeBulkPlace_Deactivation,
        EditorModeBulkPlace_Place
    )
}

#if CLIENT
void function RegisterButtonCallbacks() {
}

void function DeregisterButtonCallbacks() {
}
#endif

void function EditorModeBulkPlace_Activation(entity player)
{
    StartNewPropPlacement(player)
    thread Preview()
}

void function Preview() {
    wait 5
    file.preview = true
}

void function EditorModeBulkPlace_Deactivation(entity player)
{
    if(IsValid(GetProp(player)))
    {
        GetProp(player).Destroy()
    }
}

void function EditorModeBulkPlace_Place(entity player)
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
            SOLID_VPHYSICS // physics for bounding box
        )
    )

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
    if (file.last.x == 69)  {
        file.last = GetProp(player).GetOrigin()
        return
    }

    vector new = GetProp(player).GetOrigin()


    thread FillSpots(player, GetBB(player), new.z, file.last, new)
    GetProp(player).Destroy()
    SetProp(player, null)
    file.last = <69, 0, 0>

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

        GetProp(player).SetAngles( angles )
        GetProp(player).SetOrigin( origin )

        if (file.last.x != 69) {
            if (file.preview) {
                //thread FillSpots(player, origin.z, file.last, origin)
                file.preview = false
            }
        }

        WaitFrame()
    }
}

// Fill 2 points with the current model
// Returns origins of the places where the props should be
void function FillSpots(entity player, vector bb, float z, vector min, vector max) {
    if (bb.x == 0 || bb.y == 0 || bb.z == 0) return
    vector center

    int i = 0
    int per = 5

    if (fabs(player.GetViewForward().x) > fabs(player.GetViewForward().y)) {
        float h = bb.y
        bb.y = bb.x
        bb.x = h
    }
    vector ang = GetProp(player).GetAngles()

    float x = minf(min.x, max.x)
    while(x <= maxf(min.x, max.x)) {
        float y = minf(min.y, max.y)
        while(y <= maxf(min.y, max.y)) {
            vector origin = <x, y, z>
            #if SERVER
            entity prop = CreatePropDynamicLightweight( 
                GetAsset(player), 
                origin, 
                ang, 
                SOLID_VPHYSICS
            )
            prop.SetScriptName("editor_placed_prop")
            #endif
            i++
            if ( i % per == 0) {
                WaitFrame()
            }
            if (i >= 940) {
                // ok too much end it
                print("Halting")
                wait 5
            }
            y += bb.y
        }
        x += bb.x
    }
}

float function minf(float min, float max) {
    if (max >= min) return min
    return max
}
float function maxf(float min, float max) {
    if (max >= min) return max
    return min
}

vector function GetBB(entity player) {
    #if SERVER
    return GetProp(player).GetBoundingMaxs() - GetProp(player).GetBoundingMins()
    #elseif CLIENT
    return player.p.bbMaxs - player.p.bbMins
    #endif
    unreachable
}

vector function GetPropCenter(entity player) {
    #if CLIENT
    return player.p.center
    #elseif SERVER
    return GetProp(player).GetCenter()
    #endif
    unreachable
}

// Cant calculate bounding box in client
#if CLIENT
void function ServerCallback_UpdateModelBB(float minX, float minY, float minZ, float maxX, float maxY, float maxZ) {
    vector mins = <minX, minY, minZ>
    vector maxs = <maxX, maxY, maxZ>
    vector center = (mins + maxs) / 2

    entity player = GetLocalClientPlayer()

    player.p.bbMins = mins
    player.p.bbMaxs = maxs
    player.p.center = center
}
#endif