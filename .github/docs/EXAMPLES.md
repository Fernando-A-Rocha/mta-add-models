
# New-Models Lua Examples

**Recommended**: install the [newmodels-engine](/[examples]/newmodels-engine) resource to use some of the functions below.

Related:

- [General Information/Guide](/.github/docs/MAIN.md)
- [newmodels Functions & Events](/.github/docs/newmodels/FUNCS_EVENTS.md)
- [newmodels-engine Functions & Events](/.github/docs/newmodels-engine/FUNCS_EVENTS.md)
- [New-Models in Map Editor](/.github/docs/custom_editor/README.md)

## Adding a mod from your own resource

See the [sampobj_reloaded](/[examples]/sampobj_reloaded/) and [vehicle_manager](/[examples]/vehicle_manager/) resources for examples.

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

## Spawning a player properly

You always need to pass a model ID to the `spawnPlayer` function, which it sets.

If you want to re-spawn a player and keep its custom skin ID, you need to unset it then set it again, in order for the changes to take effect.

**Server code:**

```lua
local data_name = exports.newmodels:getDataNameFromType("player")
local id = tonumber(getElementData(thePlayer, data_name))
if id then
  removeElementData(thePlayer, data_name)
  setElementData(thePlayer, data_name, id)
end
```
