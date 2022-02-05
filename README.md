# TitanfallMapEditor BETA

For any bugs please DM Pebbers#9558 on discord, or create an issue in this repo.
This is a fork of R5Reloaded's map editor with alot of modifications.
Mantained by Pebbers and JANU

[Tutorial](https://www.youtube.com/watch?v=lu1X-1ufKbc)

# FAQ:
## How to download the map editor?
Go to the releases tab then download the latest version and put it in your mods folder.

## How to download a map?
Get the map file and replace it in your save files folder (mod/scripts/vscripts/maps) <br/>
Load it via a script or the ingame menu.

## I cant find the asset I want!
Every map has a different set of assets, we are working on improving it so you can use any props but look in different maps for now. <br/>
Also not everything has a prop, it can be something in the map .bsp

## How to use the map editor?
1. Enable sv_cheats in console by doing "sv_cheats 1"
2. Give your self the editor by doing "give mp_weapon_editor"
3. Start editing!

To change the model or the mode go to your controls settings and modify the keys
1. The place mode is used to place new props (Use the num pad and scroll wheel for precise positioning)
2. The extend mode is to repeat a prop in a certain direction (Use the scroll wheel to increase duplication count, this is the fastest way for building many props rn)
3. The delete mode deletes existing props
4. The bulk place mode is currently broken pls dont use it

## Exporting
Open the model menu (tab), select which save file you want then press save.

## Loading
Loading maps to continue building on them is done via the model menu, select the map of choice then press on the Load button. <br/>
If you are a modder all you need to do to load a map at any given time is to run LoadPropMap(mapIndex), this can be done whenever and it will delete all already spawned props.
