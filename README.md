![Banner](https://i.imgur.com/bH2Yuz6.png)

# Introduction

## About

**mta-add-models** is a MTA resource that acts as a library, making use of [engineRequestModel](https://wiki.multitheftauto.com/wiki/EngineRequestModel) function to add new models
- syncs all added models with all players
- minimalistic, optimized and bug free

In simpler terms, with this resource you can make scripts/change your scripts to add new skins, vehicles and objects to your server! For example we can now add all SA-MP objects whilst keeping their IDs.

MTA forum topic: [here](https://forum.mtasa.com/topic/133212-rel-add-new-models-library/#comment-1003395)

Contact (author): Nando#7736 **(Discord)**


## Supported Types

- [x] players / peds
- [x] vehicles
- [x] objects

## Your opinion matters!

Click the button to check the project's feedback page:

[<img src="https://i.imgur.com/x19GaN1.png?1">](https://github.com/Fernando-A-Rocha/mta-add-models/issues/7)


# Getting Started

## Prerequisites

You'll need to update your MTA Client to a certain nightly (experimental) [version](https://buildinfo.mtasa.com/):
- Get the **Windows nightly installer** - *r21026* from [nightly.mtasa.com](https://nightly.mtasa.com/)
- Update your current MTA installation, type `ver` in F8 in-game to verifiy: `Multi Theft Auto v1.5.9-release-21026`

You'll also need to get a specific MTA Server nightly (experimental) [version](https://buildinfo.mtasa.com/):
- If updating a server, you need to install it on a separate folder, then move all your settings & resources to it
- Get the **Windows/Linux server** - *r21026* from [nightly.mtasa.com](https://nightly.mtasa.com/)
- To check the server's version type `ver` on the console: `MTA:SA Server v1.5.9-release-21026`

## Includes

- [newmodels](/newmodels): main library resource
- (optional) [newmodels-example](/newmodels-example): an example implementation to add new objects/skins/etc to your server
- (optional) [sampobj_reloaded](/sampobj_reloaded): a resource that adds all SA-MP objects to your server
  - 👉 [Download](https://www.mediafire.com/file/mgqrk0rq7jrgsuc/models.zip/file) `models.zip` containing all dff/txd/col files required
- (optional) [unittest_newmodels](/unittest_newmodels): a resource for testing the main scripts

## Install

- Get the latest release: [here](https://github.com/Fernando-A-Rocha/mta-add-models/releases/latest)
- Download the source code Zip and extract it
- Place the `newmodels` folder in your server's resources
- Use command `start newmodels` in server console

## Quick Testing

- Place mod files [newmodels/models](/newmodels/models) (dff & txd (& col for objects))
- List them in [newmodels/meta.xml](/newmodels/meta.xml) like the example
- Define them in [newmodels/mod_list.lua](/newmodels/mod_list.lua) inside `modList` like the example
- Use the [commands](#commands) to test, have fun!

## Commands

- /listmods **lists all defined mods**
- /allocatedids **shows all allocated mod IDs in realtime**
- /selements **lists all streamed in elements for debugging purposes**
- /myskin [ID] **sets your skin to a default or new ID**
- /makeped [ID] **creates a ped and sets its model to a default or new ID**
- /makeobject [ID] **creates an object and sets its model to a default or new ID**
- /makevehicle [ID] **creates a vehicle and sets its model to a default or new ID**

# Implementing

## Note

This library was created with the goal of being usable in any server without breaking most of its scripts. It actually lets you use default GTA model IDs on any elements serverside, without issues. However, look no further if you want to implement new model IDs and how they can be set/fetched.

Click [here](#gamemode-implementations) for specific gamemode implementations like OwlGaming.

## (❗) How it works

### Adding Custom Element Models

This library lets you load mods stored within the `newmodels` resource, and also add mods stored in other resources to the `modList` that it will load from.

Check the [quick testing](#quick-testing) to understand how to load mods from within the `newmodels` resource (easier).

You have at your disposal the following exported functions, [see code to understand](/newmodels/server.lua):
- `addExternalMod_IDFilenames(elementType, id, base_id, name, path)`
- `addExternalMod_CustomFilenames(elementType, id, base_id, name, path_dff, path_txd, path_col)`
- `removeExternalMod(id)`

### Using Custom Element Models

To create elements with custom IDs **serverside**, do the following with these functions:
- `createPed` (use a placeholder ID when creating, e.g. 1)
- `createObject` (use a placeholder ID when creating, e.g. 1337)
- `createVehicle` (use a placeholder ID when creating, e.g. 400)
- `spawnPlayer` (use a placeholder ID when spawning the player, e.g. 1)

After creating these elements, you have to:
- **(Important)** Check if model ID is custom or default using `isDefaultID(modelID)` and `isCustomModID(modelID)`
- If it's custom you then have to do the following:
  - Fetch element data name from this resouce using `getDataNameFromType(elementType)`
  - Set their custom model ID via element data with the name you just obtained
  - **(Optional)** You can fetch all data of the mod using `getModDataFromID(modelID)`
- Otherwise if it's a default model just use `setElementModel` as usual

This resource makes the clients listen to the set element datas in order to apply custom model IDs accordingly on their game.

**Remember**: You cannot use the new added model IDs serverside.

**Special**: When doing `setVehicleHandling` (only on serverside vehicles) on a vehicle with custom ID data, the handling is stored intelligently by the library and it will make sure the vehicle keeps it each time `setElementModel` happens (serverside and clientside), because this triggers MTA to reset the vehicle's handling. Example #6 below showcases this.

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
   setElementData(ped, data_name, skin) -- sets the skin ID data;
   -- clients listening for this data will apply their corresponding allocated model ID on the created ped
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
   setElementData(object, data_name, model) -- sets the model ID data;
   -- clients listening for this data will apply their corresponding allocated model ID on the created object
end
```

## Example #3

(**serverside**) Spawning a player after login and setting their skin ID (custom or not):
```lua
-- you could fetch player data from database, here we use static values:
local x,y,z, rx,ry,rz, int,dim = 0,0,5, 0,0,0, 0,0
local skin = 20001 -- or can be default ID

spawnPlayer(thePlayer, x,y,z, 0, 0, int, dim) -- spawns the player in the center of the map; skin ID 0 is irrelevant
setElementRotation(thePlayer,rx,ry,rz)

if exports.newmodels:isCustomModID(skin) then -- skin ID is custom

   -- setElementModel(thePlayer, skin) -- wrong because custom model ID is only valid clientside
   local data_name = exports.newmodels:getDataNameFromType("player") -- gets the correct data name
   setElementData(thePlayer, data_name, skin) -- sets the skin ID data;
   -- clients listening for this data will apply their corresponding allocated model ID on the player

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
    local data_name = exports.newmodels:getDataNameFromType("player")
    local skin = getElementData(source, data_name) or getElementModel(source)
    if skin then
      print("save skin ID in the database")
    end
  end
)
```

## Example #5

(**serverside**) Adding a mod from your own resource:
```lua
-- make sure the main library resource is started before executing this code

-- (you could fetch the values from a table or database)
-- we suppose that you have a script with the following files in the root of your resource:
--     mymod.dff and mymod.txd

-- we assign custom ID 90001 to this skin mod by calling:
local worked, reason = exports.newmodels:addExternalMod_CustomFilenames(
  "ped", 90001, 1, "My skin mod", "mymod.dff", "mymod.txd" )

if not worked then -- show why it failed to add
  return outputDebugString(reason, 0,255, 110, 61)
else
  -- it means you can now use this ID to spawn custom peds or set custom player skins
  -- like showcased in Example #1
end
```

## Example #6

(**serverside**) Spawning a vehicle and setting its handling
```lua
-- you could fetch this data from database, here we use static values:
local x,y,z, rx,ry,rz, int,dim = 0,0,5, 0,0,0, 0,0
local handling = { ["engineAcceleration"] = 15, ["brakeBias"] = 0.8, }
local vehID = 90001 -- or can be default ID

local theVehicle = createVehicle(400, x,y,z, rx,ry,rz)

if exports.newmodels:isCustomModID(vehID) then -- veh ID is custom

   -- setElementModel(theVehicle, vehID) -- wrong because custom model ID is only valid clientside
   local data_name = exports.newmodels:getDataNameFromType("vehicle") -- gets the correct data name
   setElementData(theVehicle, data_name, vehID) -- sets the veh ID data;
   -- clients listening for this data will apply their corresponding allocated model ID on the player

else -- veh ID is default, handled by script normally without calling newmodels functions
   setElementModel(theVehicle, vehID)
end
for property,var in pairs(handling) do
   setVehicleHandling(theVehicle, property, var)
end
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