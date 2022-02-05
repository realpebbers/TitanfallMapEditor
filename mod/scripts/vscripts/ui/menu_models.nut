untyped
// Only way to get Hud_GetPos(sliderButton) working was to use untyped

global function AddModelBrowserMenu
global function ModelUpdateMouseDeltaBuffer
global function OpenModelMenu
global function UpdateCurrentMap

// Stop peeking

const int BUTTONS_PER_PAGE = 15
const float DOUBLE_CLICK_TIME_MS = 0.2 // unsure what the ideal value is

struct {
	int deltaX = 0
	int deltaY = 0
} mouseDeltaBuffer

struct {
	bool useSearch = false
	string searchTerm
} filterArguments

struct modelStruct {
	int modelIndex
	string modelName
}

struct {
	var menu
	int focusedModelIndex = 0
	int scrollOffset = 0
	int lastSelectedModel = 999
	bool modelListRequestFailed = false
	float modelSelectedTime = 0
	float modelSelectedTimeLast = 0
	int modelButtonFocusedID = 0
	bool shouldFocus = true
	bool cancelConnection = false
	string currentMap

	array<modelStruct> modelsArrayFiltered

	array<var> modelButtons
	array<var> modelNames
} file



bool function floatCompareInRange(float arg1, float arg2, float tolerance)
{
	if ( arg1 > arg2 - tolerance && arg1 < arg2 + tolerance) return true
	return false
}


////////////////////////////
// Init
////////////////////////////
void function AddModelBrowserMenu()
{
	AddMenu( "ModelBrowserMenu", $"resource/ui/menus/model_browser.menu", InitModelBrowserMenu, "" )
}

// Sets all possible maps and possible gamemodes for the map and gamemode option
void function UpdatePrivateMatchModesAndMaps()
{
}

void function InitModelBrowserMenu()
{
	file.menu = GetMenu( "ModelBrowserMenu" )

	// Get menu stuff
	file.modelButtons = GetElementsByClassname( file.menu, "ModelButton" )
	file.modelNames = GetElementsByClassname( file.menu, "ModelName" )

	// Event handlers
	AddMenuEventHandler( file.menu, eUIEvent.MENU_CLOSE, OnCloseModelBrowserMenu )
	AddMenuEventHandler( file.menu, eUIEvent.MENU_OPEN, OnModelBrowserMenuOpened )
	AddMenuFooterOption( file.menu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )

	// Setup model buttons
	var width = 1120.0  * (GetScreenSize()[1] / 1080.0)
	foreach ( var button in GetElementsByClassname( file.menu, "ModelButton" ) )
	{
		AddButtonEventHandler( button, UIE_CLICK, OnModelButtonClicked )
		AddButtonEventHandler( button, UIE_GET_FOCUS, OnModelButtonFocused )
		Hud_SetWidth( button , width )
	}

	AddButtonEventHandler( Hud_GetChild( file.menu , "BtnModelDummmyTop" ), UIE_GET_FOCUS, OnHitDummyTop )
	AddButtonEventHandler( Hud_GetChild( file.menu , "BtnModelDummmyBottom" ), UIE_GET_FOCUS, OnHitDummyBottom )

	AddButtonEventHandler( Hud_GetChild( file.menu, "BtnModelListUpArrow"), UIE_CLICK, OnUpArrowSelected )
	AddButtonEventHandler( Hud_GetChild( file.menu, "BtnModelListDownArrow"), UIE_CLICK, OnDownArrowSelected )
	//AddButtonEventHandler( Hud_GetChild( file.menu, "BtnDummyAfterFilterClear"), UIE_GET_FOCUS, OnHitDummyAfterFilterClear )

	// The buttons at the top to start sorting
	// "Servers" (Name), Players", "Map", "Gamemode", "Latency"

	Hud_DialogList_AddListItem( Hud_GetChild( file.menu, "SwtBtnSelectMapSave" ), "Map Save 1", "0" )
	Hud_DialogList_AddListItem( Hud_GetChild( file.menu, "SwtBtnSelectMapSave" ), "Map Save 2", "1" )
	Hud_DialogList_AddListItem( Hud_GetChild( file.menu, "SwtBtnSelectMapSave" ), "Map Save 3", "2" )
	Hud_DialogList_AddListItem( Hud_GetChild( file.menu, "SwtBtnSelectMapLoad" ), "Map Save 1", "0" )
	Hud_DialogList_AddListItem( Hud_GetChild( file.menu, "SwtBtnSelectMapLoad" ), "Map Save 2", "1" )
	Hud_DialogList_AddListItem( Hud_GetChild( file.menu, "SwtBtnSelectMapLoad" ), "Map Save 3", "2" )
	//AddButtonEventHandler( Hud_GetChild( file.menu, "BtnModelNameTab"), UIE_CLICK, SortServerListByName )

	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "SwtBtnSelectMapSave")), "buttonText", "")
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "SwtBtnSelectMapLoad")), "buttonText", "")

	//Buttons at the bottom
    AddButtonEventHandler( Hud_GetChild( file.menu, "BtnSearchLabel"), UIE_CHANGE, FilterAndUpdateList )
    AddButtonEventHandler( Hud_GetChild( file.menu, "BtnSave"), UIE_CLICK, SaveMap )
    AddButtonEventHandler( Hud_GetChild( file.menu, "BtnLoad"), UIE_CLICK, LoadMap )

    // the text entry area
	AddButtonEventHandler( Hud_GetChild( file.menu, "BtnModelSearch"), UIE_CHANGE, FilterAndUpdateList )
}

////////////////////////////
// Slider
////////////////////////////
void function ModelUpdateMouseDeltaBuffer(int x, int y)
{
	mouseDeltaBuffer.deltaX += x
	mouseDeltaBuffer.deltaY += y

	SliderBarUpdate()
}

void function FlushMouseDeltaBuffer()
{
	mouseDeltaBuffer.deltaX = 0
	mouseDeltaBuffer.deltaY = 0
}


void function SliderBarUpdate()
{
	if ( file.modelsArrayFiltered.len() <= 15 )
	{
		FlushMouseDeltaBuffer()
		return
	}

	var sliderButton = Hud_GetChild( file.menu , "BtnModelListSlider" )
	var sliderPanel = Hud_GetChild( file.menu , "BtnModelListSliderPanel" )
	var movementCapture = Hud_GetChild( file.menu , "MouseMovementCapture" )

	Hud_SetFocused(sliderButton)

	float minYPos = -40.0 * (GetScreenSize()[1] / 1080.0)
	float maxHeight = 562.0  * (GetScreenSize()[1] / 1080.0)
	float maxYPos = minYPos - (maxHeight - Hud_GetHeight( sliderPanel ))
	float useableSpace = (maxHeight - Hud_GetHeight( sliderPanel ))

	float jump = minYPos - (useableSpace / ( float( file.modelsArrayFiltered.len())))

	// got local from official respaw scripts, without untyped throws an error
	local pos =	Hud_GetPos(sliderButton)[1]
	local newPos = pos - mouseDeltaBuffer.deltaY
	FlushMouseDeltaBuffer()

	if ( newPos < maxYPos ) newPos = maxYPos
	if ( newPos > minYPos ) newPos = minYPos

	Hud_SetPos( sliderButton , 2, newPos )
	Hud_SetPos( sliderPanel , 2, newPos )
	Hud_SetPos( movementCapture , 2, newPos )

	file.scrollOffset = -int( ( (newPos - minYPos) / useableSpace ) * (file.modelsArrayFiltered.len() - 15) )
	UpdateShownPage()
}

void function UpdateListSliderHeight( float models )
{
	var sliderButton = Hud_GetChild( file.menu , "BtnModelListSlider" )
	var sliderPanel = Hud_GetChild( file.menu , "BtnModelListSliderPanel" )
	var movementCapture = Hud_GetChild( file.menu , "MouseMovementCapture" )

	float maxHeight = 562.0 * (GetScreenSize()[1] / 1080.0)

	float height = maxHeight * (30.0 / models )

	if ( height > maxHeight ) height = maxHeight

	Hud_SetHeight( sliderButton , height )
	Hud_SetHeight( sliderPanel , height )
	Hud_SetHeight( movementCapture , height )
}


void function UpdateListSliderPosition( int models )
{
	var sliderButton = Hud_GetChild( file.menu , "BtnModelListSlider" )
	var sliderPanel = Hud_GetChild( file.menu , "BtnModelListSliderPanel" )
	var movementCapture = Hud_GetChild( file.menu , "MouseMovementCapture" )

	float minYPos = -40.0 * (GetScreenSize()[1] / 1080.0)
	float useableSpace = (562.0 * (GetScreenSize()[1] / 1080.0) - Hud_GetHeight( sliderPanel ))

	float jump = minYPos - (useableSpace / ( float( models ) - 15.0 ) * file.scrollOffset)

	//jump = jump * (GetScreenSize()[1] / 1080.0)

	if ( jump > minYPos ) jump = minYPos

	Hud_SetPos( sliderButton , 2, jump )
	Hud_SetPos( sliderPanel , 2, jump )
	Hud_SetPos( movementCapture , 2, jump )
}

void function OnScrollDown( var button )
{
	if (file.modelsArrayFiltered.len() <= 15) return
	file.scrollOffset += 5
	if (file.scrollOffset + BUTTONS_PER_PAGE > file.modelsArrayFiltered.len()) {
		file.scrollOffset = file.modelsArrayFiltered.len() - BUTTONS_PER_PAGE
	}
	UpdateShownPage()
	UpdateListSliderPosition( file.modelsArrayFiltered.len() )
}

void function OnScrollUp( var button )
{
	file.scrollOffset -= 5
	if (file.scrollOffset < 0) {
		file.scrollOffset = 0
	}
	UpdateShownPage()
	UpdateListSliderPosition( file.modelsArrayFiltered.len() )
}

////////////////////////////
// Open/close callbacks
////////////////////////////
void function OnCloseModelBrowserMenu()
{
	UI_SetPresentationType( ePresentationType.INACTIVE )
}

void function OnModelBrowserMenuOpened()
{
	// Menu Title
	Hud_SetText( Hud_GetChild( file.menu, "Title" ), "Model Browser" )
	UI_SetPresentationType( ePresentationType.KNOWLEDGEBASE_MAIN )

	file.scrollOffset = 0

	thread ThreadedFilterAndUpdateList()
}

void function ThreadedFilterAndUpdateList() {
	wait 0.1
	FilterAndUpdateList(0)
	UpdateShownPage()
	UpdateListSliderPosition( file.modelsArrayFiltered.len() )
}

////////////////////////////
// Arrow navigation fuckery
////////////////////////////
bool function IsFilterPanelElementFocused() {
	// get name of focused element
	var focusedElement = GetFocus();
	var name = Hud_GetHudName(focusedElement);

	// kinda sucks but just check if any of the filter elements
	// has focus. would be nice to have tags or sth here
	bool match = (name == "FilterPanel") ||
				 (name == "BtnSearchLabel") ||
				 (name == "BtnModelSearch")

	return match;
}

void function OnKeyTabPressed(var button) {
	// toggle focus between server list and filter panel
	if (IsFilterPanelElementFocused()) {
		// print("Switching focus from filter panel to server list")
		Hud_SetFocused(Hud_GetChild(file.menu, "BtnModel1"))
	}
	else {
		// print("Switching focus from server list to filter panel")
		Hud_SetFocused(Hud_GetChild(file.menu, "BtnModelSearch"))
        // HIDE MODEL BEING RENDERED
	}
}

void function OnHitDummyTop(var button) {
	file.scrollOffset -= 1
	if (file.scrollOffset < 0)	{
		// was at top already
		file.scrollOffset = 0
		Hud_SetFocused(Hud_GetChild(file.menu, "BtnModelNameTab"))
	} else {
		// only update if list position changed
		UpdateShownPage()
		UpdateListSliderPosition( file.modelsArrayFiltered.len() )
		DisplayFocusedModelInfo(file.modelButtonFocusedID)
		Hud_SetFocused(Hud_GetChild(file.menu, "BtnModel1"))
	}
}

void function OnHitDummyBottom(var button) {
	file.scrollOffset += 1
	if (file.scrollOffset + BUTTONS_PER_PAGE > file.modelsArrayFiltered.len())
	{
		// was at bottom already
		file.scrollOffset = file.modelsArrayFiltered.len() - BUTTONS_PER_PAGE
		Hud_SetFocused(Hud_GetChild(file.menu, "BtnModelSearch"))
	} else {
		// only update if list position changed
		UpdateShownPage()
		UpdateListSliderPosition( file.modelsArrayFiltered.len() )
		DisplayFocusedModelInfo(file.modelButtonFocusedID)
		Hud_SetFocused(Hud_GetChild(file.menu, "BtnModel15"))
	}
}

void function OnHitDummyAfterFilterClear(var button) {
	Hud_SetFocused(Hud_GetChild(file.menu, "BtnModel1"))
}

void function UpdateCurrentMap(string map) {
	file.currentMap = map
}

void function OnDownArrowSelected( var button )
{
	if (file.modelsArrayFiltered.len() <= 15) return
	file.scrollOffset += 1
	if (file.scrollOffset + BUTTONS_PER_PAGE > file.modelsArrayFiltered.len()) {
		file.scrollOffset = file.modelsArrayFiltered.len() - BUTTONS_PER_PAGE
	}
	UpdateShownPage()
	UpdateListSliderPosition( file.modelsArrayFiltered.len() )
}


void function OnUpArrowSelected( var button )
{
	file.scrollOffset -= 1
	if (file.scrollOffset < 0) {
		file.scrollOffset = 0
	}
	UpdateShownPage()
	UpdateListSliderPosition( file.modelsArrayFiltered.len() )
}

////////////////////////////
// model list; filter,update,...
////////////////////////////

void function FilterAndUpdateList( var n )
{
	filterArguments.searchTerm = Hud_GetUTF8Text( Hud_GetChild( file.menu, "BtnModelSearch" ) )
	if ( filterArguments.searchTerm == "" ) filterArguments.useSearch = false else filterArguments.useSearch = true

	file.scrollOffset = 0
	UpdateListSliderPosition( file.modelsArrayFiltered.len() )

	FilterModelList()
	UpdateShownPage()

	if ( file.shouldFocus )
	{
		file.shouldFocus = false
		Hud_SetFocused( Hud_GetChild( file.menu, "BtnModel1" ) )
	}
}

void function FilterModelList()
{
	file.modelsArrayFiltered.clear()
	int totalPlayers = 0

	for ( int i = 0; i < GetAssets(file.currentMap).len(); i++ )
	{
		modelStruct tempModel

		tempModel.modelIndex = i

		string name = string( GetAssets(file.currentMap)[i] )
		// yeet useless text
		name = StringReplace(name, "\"",      "")
		name = StringReplace(name, "\"",      "")
		name = StringReplace(name, "$",       "")
		name = StringReplace(name, "models/", "")
		name = StringReplace(name, ".mdl",    "")

		tempModel.modelName = name

		// Branchless programming ;)
		
        if ( filterArguments.useSearch )
        {
            string sName = tempModel.modelName.tolower()
            string sTerm = filterArguments.searchTerm.tolower()

            if ( sName.find(sTerm) != null)
            {
                file.modelsArrayFiltered.append( tempModel )
            }
        }
        else
        {
            file.modelsArrayFiltered.append( tempModel )
        }
		
	}
}

void function UpdateShownPage()
{

	for ( int i = 0; i < 15; i++)
	{
		Hud_SetVisible( file.modelButtons[ i ], false )
		Hud_SetText( file.modelNames[ i ], "" )
	}

	int j = file.modelsArrayFiltered.len() > 15 ? 15 : file.modelsArrayFiltered.len()

	for ( int i = 0; i < j; i++ )
	{
		int buttonIndex = file.scrollOffset + i
		int modelIndex = file.modelsArrayFiltered[ buttonIndex ].modelIndex

		Hud_SetEnabled( file.modelButtons[ i ], true )
		Hud_SetVisible( file.modelButtons[ i ], true )

		Hud_SetText( file.modelNames[ i ], file.modelsArrayFiltered[ buttonIndex ].modelName )
	}

	UpdateListSliderHeight( float( file.modelsArrayFiltered.len() ) )
}

void function OnModelButtonFocused( var button )
{
	int scriptID = int (Hud_GetScriptID(button))
	file.modelButtonFocusedID = scriptID
	DisplayFocusedModelInfo(scriptID);
}

void function OnModelButtonClicked(var button)
{
	int scriptID = int (Hud_GetScriptID(button))

	DisplayFocusedModelInfo(scriptID)
	CheckDoubleClick(scriptID, true)
}

void function CheckDoubleClick(int scriptID, bool wasClickNav)
{
	file.focusedModelIndex = file.modelsArrayFiltered[ file.scrollOffset + scriptID ].modelIndex
	int modelIndex = file.scrollOffset + scriptID

	bool sameModel = false
	if (file.lastSelectedModel == modelIndex) sameModel = true


	file.modelSelectedTimeLast = file.modelSelectedTime
	file.modelSelectedTime = Time()

	printt(file.modelSelectedTime - file.modelSelectedTimeLast, file.lastSelectedModel, modelIndex)

	file.lastSelectedModel = modelIndex


	if (wasClickNav && (file.modelSelectedTime - file.modelSelectedTimeLast < DOUBLE_CLICK_TIME_MS) && sameModel)
	{
		OnModelSelected(0)
	}
}
 
// TODO: Replace with 3D Model preview
void function DisplayFocusedModelInfo( int scriptID)
{
}

// On Double Click On List Member
void function OnModelSelected( var button )
{
	int idx = file.lastSelectedModel
	string name = file.modelsArrayFiltered[idx].modelName

	RunClientScript("UICallback_SelectModel", name)
}

void function LoadMap( var button ) {
	int load = GetConVarInt( "load_map" )

	RunClientScript( "UICallback_LoadMap", load )
}

void function SaveMap( var button ) {
	int save = GetConVarInt( "save_map" )

	RunClientScript( "UICallback_SaveMap", save)
}

void function OpenModelMenu() {
	AdvanceMenu( GetMenu( "ModelBrowserMenu" ) )
}
