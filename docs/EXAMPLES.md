
# New-Models Lua Examples

## Spawning an object with any ID

**Client/Server code:**

```lua
local theID = 50001

local baseModel -- the base model that we will obtain

local isCustom, mod, customElementType = exports.newmodels:isCustomModID(theID)
if isCustom then
  if customElementType ~= "object" then
    -- the ID is valid but it's not for the element type that we want to check it for
    -- for example, the ID is valid for a ped but we want to check it for an object
    -- or the ID is valid for an object but we want to check it for a ped
    -- in this case, we can't use the ID
    return false
  end
  -- the ID is valid for the element type that we want to check it for
  -- we can use the ID
  baseModel = mod.base_id

elseif exports.newmodels:isDefaultID(theID, "object") then
  -- the ID is valid for the element type that we want to check it for
  -- we can use the ID
  baseModel = theID

else
  -- the ID is invalid
  -- we can't use the ID
  baseModel = 1
  outputDebugString("Invalid object ID ".. theID .." found!", 1)
end

local obj = createObject(baseModel, 0,0,5)
if isCustom then
  local data_name = exports.newmodels:getDataNameFromType("object")
  setElementData(obj, data_name, theID)
end
```

## Getting an object's model ID

**Client/Server code:**

```lua
local data_name = exports.newmodels:getDataNameFromType("object")
local theID = getElementData(theObject, data_name)
if theID then
  -- the object has a custom model ID
else
  -- the object has a default model ID
  theID = getElementModel(theObject)
end
```

## Getting a vehicle's base model ID

**Client/Server code:**

```lua
exports.newmodels:getBaseModel(theVehicle)
```

## Fetching a mod's information by ID

**Client/Server code:**

Disclaimer: The client only loads the mod list from the server a few seconds after it's updated.

```lua
local mod = exports.newmodels:getModDataFromID(theID)
```

## Saving a player's skin ID on disconnect

**Serverside code:**

```lua
addEventHandler( "onPlayerQuit", root, 
  function (quitType, reason, responsibleElement)
    -- get the custom skin ID (if any) or the default skin ID defined serverside
    local data_name = exports.newmodels:getDataNameFromType("player")
    local skin = getElementData(source, data_name) or getElementModel(source)
    if skin then
      print("save skin ID in the database here")
    end
  end
)
```

## Adding a mod from your own resource

(**serverside**) :

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
