global function SavePropMap

// a script that writes scripts..
const string HEADER = "global function InitMap%n\n\nglobal const MAP_%n_EXISTS = true\nglobal array<string> MAP_%n_PROPS\n\n" +
                    "void function InitMap%n() {\n"

const string FOOTER = "}\n\nvoid function AddMapProp( asset a, vector pos, vector ang, bool mantle, int fade)\n{\n" +
                    "	MAP_%n_PROPS.append(SerializeProp(a,pos,ang,mantle,fade))\n}"

void function SavePropMap( int map ) {
    array<string> code = []

    foreach(entity prop in GetAllProps()) {
        code.append(GenerateCode(prop))
    }
    string path = "../R2Northstar/mods/Pebbers.MapEditor/mod/scripts/vscripts/maps/save_file" + map + ".nut"
    WriteOut(path, map, code)
}

void function WriteOut(string filename, int map, array<string> code) {
    string repHeader = Replace(HEADER, "%n", string(map), 4)
    string repFooter = Replace(FOOTER, "%n", string(map), 1)
    printl("yo")

    DevTextBufferClear()

    DevTextBufferWrite(repHeader)
    foreach(string line in code) {
        DevTextBufferWrite("	" + line + "\n")
    }
    DevTextBufferWrite(repFooter)

    DevP4Checkout( filename )
	DevTextBufferDumpToFile( filename )
	DevP4Add( filename )
	printt( "Wrote " + filename )
}

string function Replace(string toReplace, string placeholder, string to, int times) {
    string res = toReplace

    for (int i = 0; i < times; i++) {
        res = StringReplace(res, placeholder, to)
    }

    return res
}

string function GenerateCode( entity prop ) {
    vector origin = prop.GetOrigin()
    vector angles = prop.GetOrigin()

    float x = origin.x
    float y = origin.y
    float z = origin.z

    float x1 = angles.x
    float y1 = angles.y
    float z1 = angles.z

    string pos = "< " + x + ", " + y + ", " + z + " >"
    string ang = "< " + x1 + ", " + y1 + ", " + z1 + " >"

    return "AddMapProp( " + prop.GetModelName() + ",  " + pos + ", " + ang + ", true, 6000)"
}