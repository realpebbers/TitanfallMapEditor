global function InitMap2

global const MAP_2_EXISTS = true
global array<string> MAP_2_PROPS

void function InitMap2() {
}

void function AddMapProp( asset a, vector pos, vector ang, bool mantle, int fade)
{
	MAP_2_PROPS.append(SerializeProp(a,pos,ang,mantle,fade))
}