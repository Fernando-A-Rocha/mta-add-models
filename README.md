![Banner](https://i.imgur.com/bH2Yuz6.png)

# Introduction

## About

**mta-add-models** is a MTA resource that acts as a library, making use of [engineRequestModel](https://wiki.multitheftauto.com/wiki/EngineRequestModel) function to add new models
- syncs all added models with all players
- minimalistic, optimized and bug free

MTA forum topic: [here](https://forum.mtasa.com/topic/133212-rel-add-new-models-library/#comment-1003395)

Contact (author): Nando#7736 **(Discord)**


## Supported Types

- [x] players
- [x] peds
- [x] objects
- [ ] vehicles  *[coming soon]*

# Getting Started

## Install

- Get the latest release: [here](https://github.com/Fernando-A-Rocha/mta-add-models/releases/latest)
- Download the source code Zip and extract it
- Place the `newmodels` folder in your server's resources
- Use command `start newmodels` in server console

## Quick Tutorial

- Place mod files [newmodels/models](/newmodels/models) (dff & txd (& col for objects))
- List them in [newmodels/meta.xml](/newmodels/meta.xml) like the example
- Define them in [newmodels/mod_list.lua](/newmodels/mod_list.lua) inside `modList` like the example
- Use the [commands](#commands) to test, have fun!

## Commands

- /listmods **lists all defined mods**
- /allocatedids **shows all allocated mod IDs in realtime**
- /selements **lists all streamed in elements for debugging purposes**
- /t1 **creates a ped and sets an incorrect element model ID data**
- /t2 **creates a ped and sets an element model ID data, then destroys it**
- /pedskin [ID] **creates a ped and sets their skin to a default or new ID**
- /myskin [ID] **sets your skin to a default or new ID**

# Implementing

Click [here](#gamemode-implementations) for specific gamemode implementations like OwlGaming.

## (❗) Explanation

### Adding Custom Element Models

This library lets you load mods stored within the `newmodels` resource, and also add mods stored in other resources to the `modList` that it will load from.

Check the [quick tutorial](#quick-tutorial) to understand how to load mods from within the `newmodels` resource (easier).

You have at your disposal the following exported functions, [see code to understand](/newmodels/server.lua):
- `addExternalMod_IDFilenames(elementType, id, name, path)`
- `addExternalMod_CustomFilenames(elementType, id, name, path_dff, path_txd, path_col)`
- `removeExternalMod(id)`

### Using Custom Element Models

This applies to elements created **serverside** with the following functions:
- `createPed` (use a placeholder ID when creating, e.g. 1)
- `createObject` (use a placeholder ID when creating, e.g. 1337)
- `createVehicle` (use a placeholder ID when creating, e.g. 400)
- `spawnPlayer` (use a placeholder ID when spawning the player, e.g. 1)

After creating these elements, you have to:
- **(Important)** Check if model ID is custom or default using `isDefaultID(elementType, modelID)` and `isCustomModID(elementType, modelID)`
- If it's custom you then have to do the following:
  - Fetch element data name from this resouce using `getDataNameFromType(elementType)`
  - Set their model ID via element data with the name you just obtained
  - **(Optional)** You can fetch element model name using `getModNameFromID(elementType, modelID)`
- Otherwise if it's a default model just use `setElementModel` as usual

This resource makes the clients listen to the set element datas in order to apply custom model IDs accordingly on their game.

**Remember**: You cannot use the new added model IDs serverside.

**See examples below** to understand how what's been described can be put in place.

# Lua Examples

## Example #1

(**serverside**) Spawning a ped with a new skin ID:
```lua
local skin = 20001 -- valid modded skin ID that you defined
local ped = createPed(0, 0,0,5) -- creates a ped in the center of the map; skin ID 0 is irrelevant
if ped then
   -- setElementModel(ped, skin) -- wrong because custom model ID is only valid clientside
   local data_name = exports.newmodels:getDataNameFromType("ped") -- gets the correct data name
   setElementData(ped, data_name, skin) -- sets the skin ID data; clients listening for this data will apply their corresponding allocated model ID on the created ped
end
```

## Example #2

(**serverside**) Spawning an object with a new model ID:
```lua
local model = 50001 -- valid modded object ID that you defined
local object = createObject(1337, 0,0,8) -- creates an object in the center of the map; model ID 1337 is irrelevant
if object then
   -- setElementModel(object, model) -- wrong because custom model ID is only valid clientside
   local data_name = exports.newmodels:getDataNameFromType("object") -- gets the correct data name
   setElementData(object, data_name, model) -- sets the model ID data; clients listening for this data will apply their corresponding allocated model ID on the created object
end
```

## Example #3

(**serverside**) Spawning a player after login and setting their skin ID (custom or not):
```lua
-- TODO: fetch player data from database, here we use static values:
local x,y,z = 0,0,5
local rx,ry,rz = 0,0,0
local int,dim = 0,0
local skin = 20001 -- or can be default ID

spawnPlayer(thePlayer, x,y,z, 0, 0, int, dim) -- spawns the player in the center of the map; skin ID 0 is irrelevant
setElementRotation(thePlayer,rx,ry,rz)

if exports.newmodels:isCustomModID("player", skin) then -- skin ID is custom

   -- setElementModel(thePlayer, skin) -- wrong because custom model ID is only valid clientside
   local data_name = exports.newmodels:getDataNameFromType("player") -- gets the correct data name
   setElementData(thePlayer, data_name, skin) -- sets the skin ID data; clients listening for this data will apply their corresponding allocated model ID on the player

else -- skin ID is default, handled by script normally without calling newmodels functions
   setElementModel(thePlayer, skin)
end
```

## Example #4

(**serverside**) Saving a player's skin ID on disconnect:
```lua
addEventHandler( "onPlayerQuit", root, 
  function (quitType, reason, responsibleElement)
    -- get the custom skin ID (if any) or the default skin ID defined serverside
    local skin = exports.newmodels:getDataNameFromType("player") or getElementModel(source)
    if skin then
    	-- TODO: save skin ID in the database
    end
  end
)
```

# Gamemode Implementations

## [OwlGaming Gamemode](https://github.com/OwlGamingCommunity/MTA) - Custom Peds

Example scripts that you need to adapt:
- Clientside peds in character selection screen [account/c_characters.lua](https://github.com/OwlGamingCommunity/MTA/blob/main/mods/deathmatch/resources/account/c_characters.lua)
- Serverside character spawning [account/s_characters.lua](https://github.com/OwlGamingCommunity/MTA/blob/main/mods/deathmatch/resources/account/s_characters.lua)
- Serverside player skin saving [saveplayer-system/s_saveplayer_system.lua](https://github.com/OwlGamingCommunity/MTA/blob/main/mods/deathmatch/resources/saveplayer-system/s_saveplayer_system.lua)

For new skin images used in the inventory, place them in [account/img](https://github.com/OwlGamingCommunity/MTA/tree/main/mods/deathmatch/resources/account/img) as ID.png with a minimum of 3 digits.

You will find a lot more scripts that need to be changed if you want to use new IDs to the maximum potential, for example:
- Shops/NPCs having custom skin IDs
- Supporting custom skins in the [clothes](https://github.com/OwlGamingCommunity/MTA/tree/main/mods/deathmatch/resources/clothes) system
- ...

# Final Note

Feel free to update this README.md if you wish to provide tutorial(s) for other implementations, or generally improve the current documentation.

Thank you for reading, have fun!