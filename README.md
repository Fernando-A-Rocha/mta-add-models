![Banner](https://i.imgur.com/bH2Yuz6.png)

## About

Simple MTA scripts that make use of [engineRequestModel](https://wiki.multitheftauto.com/wiki/EngineRequestModel) function, syncing added models with all players\
Minimalistic & bug free, enjoy!

## Supported Types

- [x] ped *(skin)*
- [ ] vehicle
- [ ] object

## Commands

- /listmods **lists all defined mods**
- /allocatedids **lists all allocated mod IDs**
- /pedskin [ID] **creates a ped and sets their skin to a default or new ID**
- /myskin [ID] **sets your skin to a default or new ID**

## Quick Tutorial

- place mod files newmodels/models (dff & txd)
- list them in meta.xml like the example
- define them in shared.lua inside modList like the example
- use the commands to test, have fun!

## Actual Implementation

### Explanation

- you can create peds & set their skin ID in a serverside script via element data
- same method for setting player skin IDs
- **do not use** `setElementModel` in serverside scripts for setting skin IDs
- **do not use** `getElementModel` in serverside scripts for getting skin IDs
- use the **shared exported functions** in your scripts for **verifications**
	- `getDataNameFromType(modType, id)` returns the correct data name for an element type (e.g. ped)
	- `getModNameFromID(modType, id)` returns a mod's name if defined in modList
	- `isDefaultID(modType, id)` returns true if ID is default GTA ID
	- `isCustomModID(modType, id)` returns true if ID is a new mod ID defined in modList
- use `setElementData` and `getElementData` for setting/getting skin ID (see examples below)

### Implementing in [OwlGaming](https://github.com/OwlGamingCommunity/MTA) Gamemode

In order to have custom new skins, you're going to have to search through all the scripts for **serverside** instances of:
- **getElementModel** `replace with setElementData -> skinID`
- **setElementModel** `replace with getElementData -> skinID`
- **createPed** `use 0 as skinid; use setElementData -> skinID afterwards`
- **spawnPlayer** `use 0 as skinid; use setElementData -> skinID afterwards`

See the proper implementation examples below, they're helpful.\
Example scripts that you need to adapt:
- Clientside peds in character selection screen [account/c_characters.lua](https://github.com/OwlGamingCommunity/MTA/blob/main/mods/deathmatch/resources/account/c_characters.lua)
- Serverside character spawning [account/s_characters.lua](https://github.com/OwlGamingCommunity/MTA/blob/main/mods/deathmatch/resources/account/s_characters.lua)
- Serverside player skin saving [saveplayer-system/s_saveplayer_system.lua](https://github.com/OwlGamingCommunity/MTA/blob/main/mods/deathmatch/resources/saveplayer-system/s_saveplayer_system.lua)

For new skin images used in the inventory, place them in [account/img](https://github.com/OwlGamingCommunity/MTA/tree/main/mods/deathmatch/resources/account/img) as ID.png with a minimum of 3 digits.\
You will find a lot more scripts that need to be changed if you want to use new IDs to the maximum potential, for example:
- Shops/NPCs having custom skin IDs
- Supporting custom skins in the [clothes](https://github.com/OwlGamingCommunity/MTA/tree/main/mods/deathmatch/resources/clothes) system
- ...


## Lua Examples

### Example #1

Spawning a ped with a new skin ID:\
**Before you would use setElementModel serverside, with clientside-set models you can't**
```lua
local skin = 20001 -- valid modded skin ID that you defined
local ped = createPed(1, 0,0,5) -- creates a ped in the center of the map; skin ID 1 is irrelevant
if ped then
   local data_name = exports.newmodels:getDataNameFromType("ped") -- gets the correct data name
   setElementData(ped, data_name, skin) -- sets the skin ID data
   -- clients listening for this data will apply the skin ID on the created ped.
end
````

### Example #2

Spawning a player after login and setting their skin ID:\
**Before you would use setElementModel serverside, with clientside-set models you can't**
```lua
-- fetch player data from database, here we use static values.
local x,y,z = 0,0,5
local rx,ry,rz = 0,0,0
local int,dim = 0,0
local skin = 20001

spawnPlayer(thePlayer, x,y,z, 0, 0, int, dim) -- spawns the player in the center of the map; skin ID 0 is irrelevant
setElementRotation(thePlayer,rx,ry,rz)
local data_name = exports.newmodels:getDataNameFromType("ped") -- gets the correct data name
setElementData(thePlayer, data_name, skin) -- sets the skin ID data
-- clients listening for this data will apply the skin ID on the player.
````


### Example #3

Saving a player's skin ID on disconnect:\
**Before you would use getElementModel serverside, with clientside-set models you can't**
```lua
addEventHandler( "onPlayerQuit", root, 
  function (quitType, reason, responsibleElement)
    local data_name = exports.newmodels:getDataNameFromType("ped") -- gets the correct data name
    local skin = getElementData(source, data_name)
    if skin then
    	-- save skin ID in the database
    end
  end
)
````
