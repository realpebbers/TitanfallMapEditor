global function InitMap1

global const MAP_1_EXISTS = false
global array<string> MAP_1_PROPS

void function InitMap1() {
}

void function AddMapProp( asset a, vector pos, vector ang, bool mantle, int fade)
{
	MAP_1_PROPS.append(SerializeProp(a,pos,ang,mantle,fade))
}