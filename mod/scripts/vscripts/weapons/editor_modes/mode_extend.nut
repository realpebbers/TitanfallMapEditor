global function EditorModeExtend_Init

#if CLIENT
struct {
    array<entity> highlightedEnts
    int distance = 1
} file
#endif

EditorMode function EditorModeExtend_Init() 
{
    RegisterSignal("EditorModeExtendExit")
    #if SERVER
    AddClientCommandCallback("extend_distance", ClientCommand_ExtendDistance)
    #endif

    return NewEditorMode(
        "Extend",
        "Extend props in different directions",
        EditorModeExtend_Activation,
        EditorModeExtend_Deactivation,
        EditorModeExtend_Extend
    )
}

void function EditorModeExtend_Activation(entity player)
{
    #if CLIENT
    RegisterButtonReleasedCallback( MOUSE_WHEEL_UP, IncreaseDistance );
	RegisterButtonReleasedCallback( MOUSE_WHEEL_DOWN, DecreaseDistance );

    thread EditorModeExtend_Think(player)
    #endif
}

void function EditorModeExtend_Deactivation(entity player)
{
    Signal(player, "EditorModeExtendExit")
    #if CLIENT
    DeregisterButtonReleasedCallback( MOUSE_WHEEL_UP, IncreaseDistance );
	DeregisterButtonReleasedCallback( MOUSE_WHEEL_DOWN, DecreaseDistance );

    ClearHighlighted()
    #endif
}

#if CLIENT
void function EditorModeExtend_Think(entity player) {
    player.EndSignal("EditorModeExtendExit")
    
    OnThreadEnd(
        function() : (player) {
            ClearHighlighted()
        }
    )
    
    while( true )
    {
        TraceResults result = GetPropLineTrace(player)
        ClearHighlighted()
        if (!IsValid(result.hitEnt)) {
            WaitFrame()
            continue
        }
        // This checks for it being a prop instead of the map
        array<string> check = split(string(result.hitEnt.GetModelName()), "/")
        if (check.len() > 0 && check[0] == "$\"models")
        {
            vector normal = Normalize(result.surfaceNormal)
            normal.x = expect float(RoundToNearestInt(normal.x))
            normal.y = expect float(RoundToNearestInt(normal.y))
            normal.z = expect float(RoundToNearestInt(normal.z))

            vector min = result.hitEnt.GetBoundingMins() // This is relative
            vector max = result.hitEnt.GetBoundingMaxs() // This is also relative
            vector bounds = max - min
    
            if(fabs(result.hitEnt.GetAngles().y) == 90.0) {
                float l = bounds.x
                bounds.x = bounds.y
                bounds.y = l
            }
            
            vector res = <normal.x * bounds.x, normal.y * bounds.y, normal.z * bounds.z>

            int maxD = file.distance
            for (int i = 0; i < maxD; i++) {
                int mult = i + 1
                vector pos = result.hitEnt.GetOrigin() + < res.x * mult, res.y * mult, res.z * mult >
                entity e = CreateClientSidePropDynamic(pos, result.hitEnt.GetAngles(), result.hitEnt.GetModelName())
                
                file.highlightedEnts.append(e)
                DeployableModelHighlight( e )
            }
        }

        WaitFrame()
    }
}

void function ClearHighlighted() {
    foreach(entity e in file.highlightedEnts) {
        if (IsValid(e)) {
            e.Destroy()
        }
    }

    file.highlightedEnts.clear()
}

#endif

void function EditorModeExtend_Extend(entity player)
{
    #if SERVER
    TraceResults result = GetPropLineTrace(player)
    if (IsValid(result.hitEnt) && result.hitEnt.GetScriptName() == "editor_placed_prop")
    {
        vector normal = Normalize(result.surfaceNormal)
        normal.x = expect float(RoundToNearestInt(normal.x))
        normal.y = expect float(RoundToNearestInt(normal.y))
        normal.z = expect float(RoundToNearestInt(normal.z))

        vector min = result.hitEnt.GetBoundingMins() // This is relative
        vector max = result.hitEnt.GetBoundingMaxs() // This is also relative
        vector bounds = max - min

        if(fabs(result.hitEnt.GetAngles().y) == 90.0) {
            float l = bounds.x
            bounds.x = bounds.y
            bounds.y = l
        }
        
        vector res = <normal.x * bounds.x, normal.y * bounds.y, normal.z * bounds.z>

        int maxD = player.p.extendDistance
        for(int i = 0; i < maxD; i++) {
            int mult = i+1
            vector pos = result.hitEnt.GetOrigin() + < res.x * mult, res.y * mult, res.z * mult >
        
            PlaceProp(player, result.hitEnt.GetModelName(), pos, result.hitEnt.GetAngles())
        }
    }
    #endif
}

#if SERVER
bool function ClientCommand_ExtendDistance(entity player, array<string> args) {
    int a = args[0].tointeger()

    player.p.extendDistance = a
    return true
}
#endif

void function PlaceProp(entity player, asset ass, vector origin, vector angles)
{
    #if SERVER
    entity prop = CreatePropDynamicLightweight(ass, origin, angles, SOLID_VPHYSICS, 6000)
    prop.AllowMantle()
    prop.SetScriptName("editor_placed_prop")

    if (player.p.hideProps) {
        prop.Hide()
    }

    AddProp(prop)

    printl(serialize("place", string(GetAsset(player)), origin, angles))

    #elseif CLIENT
    if(player != GetLocalClientPlayer()) return;

    ClearHighlighted()
    #endif
}


#if CLIENT 
void function IncreaseDistance(var button) {
    file.distance++
    if (file.distance > 7) {
        file.distance = 7
    }

    entity player = GetLocalClientPlayer()
    player.ClientCommand("extend_distance " + file.distance)
}

void function DecreaseDistance(var button) {
    file.distance--
    if (file.distance <= 1) {
        file.distance = 1
    }
    
    entity player = GetLocalClientPlayer()
    player.ClientCommand("extend_distance " + file.distance)
}

#endif