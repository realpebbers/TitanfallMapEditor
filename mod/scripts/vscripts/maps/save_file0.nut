global function InitMap0

global const MAP_0_EXISTS = false
global array<string> MAP_0_PROPS

void function InitMap0() {
}

void function AddMapProp( asset a, vector pos, vector ang, bool mantle, int fade)
{
	MAP_0_PROPS.append(SerializeProp(a,pos,ang,mantle,fade))
}