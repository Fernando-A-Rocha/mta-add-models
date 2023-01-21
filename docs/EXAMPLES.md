
# New-Models Lua Examples

Remember to check [Example Resources/Scripts](/[examples]) and the [implementations README](/docs/implementations/README.md).

## Spawning an object outside of newmodels (any ID)

****Serverside code:**
 code:**

```lua
local theID = 50001
local baseModel, isCustom, dataName, baseDataName = exports.newmodels:checkModelID("object", theID)
if tonumber(baseModel) then
  local obj = createObject(baseModel, 0,0,3)
  if not isElement(obj) then
    outputDebugString("Error spawning object", 1)
  else
    if isCustom then
      setElementData(obj, dataName, theID)
      setElementData(obj, baseDataName, baseModel)
    end
    outputDebugString("Created object with ID "..theID..(isCustom and " (custom)" or ""), 3)
  end
elseif obj == "INVALID_MODEL" then
  outputDebugString("Invalid model ID", 1)
elseif obj == "WRONG_MOD" then
  outputDebugString("Mod ID is not a valid object model", 1)
else
  outputDebugString("Error calling newmodels:checkModelID", 1)
end
```

## Setting a player's skin (any ID)

**Serverside code:**

```lua
local theID = 20001
local result = exports.newmodels:setElementModelSafe(thePlayer, theID)
if result == true then
  outputDebugString("Set player's skin to "..theID, 3)
elseif result == "INVALID_MODEL" then
  outputDebugString("Invalid model ID", 1)
elseif result == "WRONG_MOD" then
  outputDebugString("Mod ID is not a valid player skin", 1)
else
  outputDebugString("Error calling newmodels:setElementModelSafe", 1)
end
```

## Check if an object has a custom ID

**Client/Server code:**

```lua
local data_name = exports.newmodels:getDataNameFromType("object")
local theID = getElementData(theObject, data_name)
if theID then
  print("the object has a custom model ID")
else
  print("the object has a default model ID")
end
```

## Getting any element's base model ID (custom or default)

**Client/Server code:**

```lua
local baseModel = exports.newmodels:getBaseModel(theVehicle)
print(baseModel)

-- ALTERNATIVE:
local baseDN = exports.newmodels:getBaseModelDataName()
local baseModel = getElementData(theVehicle, baseDN) or getElementModel(theVehicle)
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

**Serverside code:**

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
