// Shared code for all modes
untyped
globalize_all_functions


entity function GetProp(entity player)
{
    return player.p.currentPropEntity 
}

entity function GetRealProp(entity player) {
    return player.p.currentRealPropEntity
}

void function SetProp(entity player, entity prop)
{
    player.p.currentPropEntity = prop
}

void function SetRealProp(entity player, entity prop) {
    player.p.currentRealPropEntity = prop
}

asset function GetAsset(entity player) {
    return player.p.selectedProp.selectedAsset
}

asset function CastStringToAsset( string val ) {
    // pain
    // no way to do dynamic assets so 
	return expect asset ( compilestring( "return $\"" + val + "\"" )() )
}

float function round(float x) {
    return expect float( RoundToNearestInt(x) )
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

string function serialize(string action, string ass, vector origin, vector angles) {
    string positionSerialized = origin.x.tostring() + "," + origin.y.tostring() + "," + origin.z.tostring()
	string anglesSerialized = angles.x.tostring() + "," + angles.y.tostring() + "," + angles.z.tostring()
    return "[" + action + "]" + ass + ";" + positionSerialized + ";" + anglesSerialized
}