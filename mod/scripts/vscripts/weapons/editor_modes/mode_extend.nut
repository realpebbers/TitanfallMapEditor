global function EditorModeExtend_Init

#if CLIENT
struct {
    entity highlightedEnt
} file
#endif

EditorMode function EditorModeExtend_Init() 
{
    RegisterSignal("EditorModeExtendExit")

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
    thread EditorModeExtend_Think(player)
    #endif
}

#if CLIENT
void function EditorModeExtend_Think(entity player) {
    player.EndSignal("EditorModeExtendExit")
    
    OnThreadEnd(
        function() : (player) {
            if(IsValid(GetProp(player)))
            {
                file.highlightedEnt.Destroy()
            }
        }
    )
    
    while( true )
    {
        TraceResults result = GetPropLineTrace(player)
        if (IsValid(file.highlightedEnt)) {
            file.highlightedEnt.Destroy()
        }
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
            vector pog = result.hitEnt.GetOrigin() + res

            #if CLIENT
            file.highlightedEnt = CreateClientSidePropDynamic(
                pog,
                result.hitEnt.GetAngles(),
                result.hitEnt.GetModelName()
            )

            DeployableModelHighlight( file.highlightedEnt )
            #endif
        }
        

        WaitFrame()
    }
}
#endif


void function EditorModeExtend_Deactivation(entity player)
{
    Signal(player, "EditorModeExtendExit")
    #if CLIENT
    if (IsValid(file.highlightedEnt)) {
        file.highlightedEnt.Destroy()
    }
    #endif
}

void function EditorModeExtend_Extend(entity player)
{
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
        vector pog = result.hitEnt.GetOrigin() + res

        PlaceProp(player, result.hitEnt.GetModelName(), pog, result.hitEnt.GetAngles())
    }
}

void function PlaceProp(entity player, asset ass, vector origin, vector angles)
{
    #if SERVER
    entity prop = CreatePropDynamicLightweight(ass, origin, angles, SOLID_VPHYSICS, 6000)
    prop.AllowMantle()
    prop.SetScriptName("editor_placed_prop")

    AddProp(prop)

    printl(serialize("place", string(GetAsset(player)), origin, angles))

    #elseif CLIENT
    if(player != GetLocalClientPlayer()) return;

    file.highlightedEnt.Destroy()
    #endif
}
