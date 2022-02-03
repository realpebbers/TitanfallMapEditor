global function EditorModeDelete_Init

#if CLIENT
struct {
    entity highlightedEnt
} file
#endif

EditorMode function EditorModeDelete_Init() 
{
    RegisterSignal("EditorModeDeleteExit")

    return NewEditorMode(
        "Delete",
        "Delete props already placed",
        EditorModeDelete_Activation,
        EditorModeDelete_Deactivation,
        EditorModeDelete_Delete
    )
}

void function EditorModeDelete_Activation(entity player)
{
    #if CLIENT
    thread EditorModeDelete_Think(player)
    #endif
}

#if CLIENT
void function EditorModeDelete_Think(entity player) {
    player.EndSignal("EditorModeDeleteExit")
    
    OnThreadEnd(
        function() : (player) {
            if(IsValid(file.highlightedEnt))
            {
                file.highlightedEnt.Destroy()
            }
        }
    )
    
    while( true )
    {
        TraceResults result = GetPropLineTrace(player)
        if (!IsValid(result.hitEnt)) {
            WaitFrame()
            continue
        }

        array<string> check = split(string(result.hitEnt.GetModelName()), "/")
        if (check.len() > 0 && check[0] == "$\"models")
        {
            if( IsValid( file.highlightedEnt ) && IsValid( result.hitEnt ) )
            {
                if( IsValid(file.highlightedEnt.e.svCounterpart) && file.highlightedEnt.e.svCounterpart == result.hitEnt ) {
                    WaitFrame()
                    continue   
                }
            }
            
            if(IsValid(file.highlightedEnt))
            {
                file.highlightedEnt.Destroy()
            }
            
            if( IsValid(result.hitEnt) )
            {
                #if CLIENT
                print("data: " + result.hitEnt.GetOrigin())
                print("data2: " + result.hitEnt.GetAngles())
                print("data3: " + result.hitEnt.GetModelName())
                file.highlightedEnt = CreateClientSidePropDynamic(
                    result.hitEnt.GetOrigin(),
                    result.hitEnt.GetAngles(), 
                    result.hitEnt.GetModelName()
                )
                file.highlightedEnt.e.svCounterpart = result.hitEnt
                file.highlightedEnt.Show()
                DeployableModelInvalidHighlight( file.highlightedEnt )
                #endif
            }

        }
        else
        {
            if(IsValid(file.highlightedEnt))
            {
                file.highlightedEnt.Destroy()
            }
        }

        WaitFrame()
    }
}
#endif


void function EditorModeDelete_Deactivation(entity player)
{
    Signal(player, "EditorModeDeleteExit")
}

void function EditorModeDelete_Delete(entity player)
{
    DeleteProp(player)
}

void function DeleteProp(entity player)
{
    #if SERVER
    TraceResults result = GetPropLineTrace(player)
    if (IsValid(result.hitEnt))
    {
        if (result.hitEnt.GetScriptName() == "editor_placed_prop")
        {
            result.hitEnt.NotSolid()
            result.hitEnt.Dissolve( ENTITY_DISSOLVE_NORMAL, <0,0,0>, 0 )

            // prints prop info to the console to let the parse know to delete it
            vector myOrigin = result.hitEnt.GetOrigin()
            vector myAngles = result.hitEnt.GetAngles()

            printl(serialize("delete", string(result.hitEnt.GetModelName()), myOrigin, myAngles))
        }
    }
    #endif
}