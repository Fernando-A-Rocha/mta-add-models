
# New-Models Lua Examples

**Recommended**: install the [newmodels-engine](/[examples]/newmodels-engine) resource to use some of the functions below.

Remember to check the [General Information/Guide](/.github/docs/MAIN.md) and [Example Resources/Scripts](/[examples]).

For more advanced developers, check the [newmodels exported functions](/newmodels/meta.xml) and explore the code which should be readable and easy to understand.

## Adding a mod from your own resource

**Server code:**

```lua
-- (You could fetch the values from a table or database)
-- We suppose that you have a script with the following files in the root of your resource:
--     mymod.dff and mymod.txd

-- We assign custom ID 90001 to this skin mod by calling:
local worked, reason = exports.newmodels:addExternalMod_CustomFilenames(
  "ped", 90001, 1, "My skin mod", "mymod.dff", "mymod.txd" )

if not worked then -- show why it failed to add
  return outputDebugString(reason, 0,255, 110, 61)
else
  -- You can now use this ID to spawn custom peds or set custom player skins
end
```

## Spawning an object outside of newmodels (any ID)

**Server code:**

```lua
-- Use resource newmodels-engine
local theID = 50001
local object = exports["newmodels-engine"]:createObject(theID, 0,0,3)
if object then
  -- Continue
end
```

## Setting a player's skin (any ID)

**Server code:**

```lua
-- Use resource newmodels-engine
local theID = 20001
local result = exports["newmodels-engine"]:setElementModel(thePlayer, theID)
if result then
  -- Continue
end
```

## Getting a vehicle's model ID (custom or default)

**Client/Server code:**

```lua
-- Use resource newmodels-engine
local theID = exports["newmodels-engine"]:getElementModel(theVehicle)
print(theID)
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

## Fetching a mod's information by ID

**Client/Server code:**

Disclaimer: The client only loads the mod list from the server a few seconds after it's updated.

```lua
local mod = exports.newmodels:getModDataFromID(theID)
```