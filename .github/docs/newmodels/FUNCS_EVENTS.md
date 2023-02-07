# newmodels

Below is a list of all exported functions and custom events defined in `newmodels` that you can use as a developer from your own resources.

## 🛠 Exported Functions (**Client & Server**)

All shared (clientside & serverside) exported functions are explained here.

---

### **getModList**()

Gets the mod list loaded on the server or received by the client.

**Returns**:

- a `table` corresponding to the of mod list [**OR**] `nil` if the table is not ready yet (server hasn't finished startup / client hasn't received it)

---

### **getDataNameFromType**(`elementType`)

Gets the data name for a given element type.

**Required arguments**:

- `elementType`: A valid element type from the dataNames table (e.g. "vehicle")

**Returns**:

- a `string` corresponding to the **custom data name for that element type** [**OR**] `nil` if invalid elementType passed

---

### **getBaseModelDataName**()

Gets the data name for the base/parent model.

**Returns**:

- a `string` corresponding to the **custom data name for base/parent model**

---

### **getBaseModel**(`element`)

Gets the base/parent model ID for a given element.

**Required arguments**:

- `element`: A valid element (e.g. a player)

**Returns**:

- a `number` corresponding to the **base/parent model ID** of the element [**OR**] `false` if `getElementModel` on element passed fails

---

### **getModDataFromID**(`id`)

Gets the mod data for a given mod ID.

**Required arguments**:

- `id`: A number (e.g. 80001)

**Returns**:

- a `table` corresponding to the **mod** with that ID **OR** `nil` if the mod list table is not ready yet (server hasn't finished startup / client hasn't received it) / invalid number passed
- a `string` corresponding to the mod's **element type** if it was found

---

### **isDefaultID**(`elementType`, `id`)

Checks if a given ID is a default ID for the given element type.

**Required arguments**:

- `id`: A number (e.g. 1337)

**Optional arguments**:

- `elementType`: A valid element type from the dataNames table (e.g. "object") or false/nil to check all element types

**Returns**:

- a `boolean` which is **true** if the id passed is valid for the element type passed [**OR**] **false** if invalid

---

### **isCustomModID**(`id`)

Checks if a given ID is a custom mod ID.

**Required arguments**:

- `id`: A number (e.g. 50001)

**Returns**:

- a `boolean` which is **true** if the id passed is a custom mod ID [**OR**] **false** if invalid
- a `table` corresponding to the **mod** with that ID if it was found
- a `string` corresponding to the mod's **element type** if it was found

---

### **isRightModType**(`elementType`, `modElementType`)

Checks if a given element type is the same as the mod's element type. It matches player to ped and pickup to object types.

**Required arguments**:

- `elementType`: A valid element type from the dataNames table (e.g. "vehicle")
- `modElementType`: A valid element type from the dataNames table (e.g. "vehicle")

**Returns**:

- a `boolean` which is **true** if the element types match [**OR**] **false** if not

### **checkModelID**(`id`, `elementType`)

Checks if a given ID is a valid model ID for the given element type. It calls isDefaultID, isCustomModID and isRightModType for you.

**Required arguments**:

- `id`: A number (e.g. 80002)
- `elementType`: A valid element type from the dataNames table (e.g. "vehicle")

**Returns**:

- a `string` corresponding to invalid reason ("INVALID_MODEL" or "WRONG_MOD") [**OR**] a `number` corresponding to the **base/parent model ID** (which will be the same if the ID is a default ID) if the ID is valid
- a `boolean` which is **true** if the ID is a custom ID [**OR**] **false** if not
- a `string` corresponding to the **element type**'s data name
- a `string` corresponding to the **base/parent model** data name

---

## 🔨 Exported Functions (**Server**)

All server-side only exported functions are explained here.

---

### **addExternalMod_IDFilenames**(`modInfo`, `fromResourceName`)

Adds a new external mod which uses ID file names (e.g. "models/50001.txd") to the mod list.

**Required arguments**:

- `modInfo`: A table with the following keys:
  - `elementType`: A valid element type from the dataNames table (e.g. "object")
  - `id`: A number (e.g. 50001)
  - `base_id`: A number (e.g. 1337)
  - `name`: A string (e.g. "My Custom Object")
  - `path`: A string (e.g. "models/")
  - (optional) `ignoreTXD`: A boolean (e.g. false)
  - (optional) `ignoreDFF`: A boolean (e.g. false)
  - (optional) `ignoreCOL`: A boolean (e.g. false)
  - (optional) `metaDownloadFalse`: A boolean (e.g. false)
  - (optional) `disableAutoFree`: A boolean (e.g. false)
  - (optional) `lodDistance`: A number (e.g. 300)

**Optional arguments**:

- `fromResourceName`: A string (e.g. "myResource") - where the mod files are located

**Returns**:

- a `boolean` which is **true** if the mod was added successfully [**OR**] **false** if not
- a `string` corresponding to the reason of failure if it was not added successfully

---

### **addExternalMods_IDFilenames**(`list`, `onFinishEvent`)

Adds a list of new external mods which use ID file names to the mod list. See the function above for the arguments.

**NOTE**: This is an async function: mods in the list will be added gradually and if you have too many it may take several seconds. So don't assume that they've all been added immediately after the function returns true. Also, please note that if any of your mods has an invalid parameter, an error will be output and it won't get added.

**Required arguments**:

- `list`: A table (e.g. `{ {elementType = "object", id = 50001, base_id = 1337, name = "My Custom Object", path = "models/"}, {elementType = "vehicle", id = 50002, base_id = 400, name = "My Custom Vehicle", path = "models/"} }`)

**Optional arguments**:

- `onFinishEvent`: A table with the following keys:
  - `source`: An element for the event source (e.g. root)
  - `name`: A string for the event name (e.g. "onExternalModsAdded")
  - (optional) `args`: A table for the event arguments (e.g. `{}`)

**Returns**:

- a `boolean` which is **true** if the mods started being added [**OR**] **false** if not

---

### **addExternalMod_CustomFilenames**(`modInfo`, `fromResourceName`)

Adds a new external mod which uses custom file names (e.g. "models/my_custom_object.dff") to the mod list.

**Required arguments**:

- `modInfo`: A table with the following keys:
  - `elementType`: A valid element type from the dataNames table (e.g. "object")
  - `id`: A number (e.g. 50001)
  - `base_id`: A number (e.g. 1337)
  - `name`: A string (e.g. "My Custom Object")
  - `path`: A string (e.g. "models/")
  - (optional) `ignoreTXD`: A boolean (e.g. false)
  - (optional) `ignoreDFF`: A boolean (e.g. false)
  - (optional) `ignoreCOL`: A boolean (e.g. false)
  - (optional) `metaDownloadFalse`: A boolean (e.g. false)
  - (optional) `disableAutoFree`: A boolean (e.g. false)
  - (optional) `lodDistance`: A number (e.g. 300)

**Optional arguments**:

- `fromResourceName`: A string (e.g. "myResource") - where the mod files are located

**Returns**:

- a `boolean` which is **true** if the mod was added successfully [**OR**] **false** if not

---

### **addExternalMods_CustomFilenames**(`list`, `onFinishEvent`)

Adds a list of new external mods which use custom file names to the mod list. See the function above for the arguments.

**NOTE**: This is an async function: mods in the list will be added gradually and if you have too many it may take several seconds. So don't assume that they've all been added immediately after the function returns true. Also, please note that if any of your mods has an invalid parameter, an error will be output and it won't get added.

**Required arguments**:

- `list`: A table (e.g. `{ {elementType = "vehicle", id = 80001, base_id = 400, name = "My Custom Vehicle", path_dff = "models/my_custom_vehicle.dff", path_txd = "models/my_custom_vehicle.txd"}, {elementType = "object", id = 50001, base_id = 1337, name = "My Custom Object", path_dff = "models/my_custom_object.dff", path_txd = "models/my_custom_object.txd", path_col = "models/my_custom_object.col"} }`)

**Optional arguments**:

- `onFinishEvent`: A table with the following keys:
  - `source`: An element for the event source (e.g. root)
  - `name`: A string for the event name (e.g. "onExternalModsAdded")
  - (optional) `args`: A table for the event arguments (e.g. `{}`)

**Returns**:

- a `boolean` which is **true** if the mods started being added [**OR**] **false** if not

---

### **removeExternalMod**(`id`)

Removes an external mod from the mod list.

**Required arguments**:

- `id`: A number (e.g. 50001)

**Returns**:

- a `boolean` which is **true** if the mod was removed successfully [**OR**] **false** if not

---

### **removeExternalMods**(`list`, `onFinishEvent`)

Removes a list of external mods from the mod list.

**NOTE**: This is an async function: mods in the list of IDs will be removed gradually and if you have too many it may take several seconds. So don't assume that they've all been removed immediately after the function returns true.

**Required arguments**:

- `list`: A table (e.g. `{50001, 50002, 50003}`)

**Optional arguments**:

- `onFinishEvent`: A table with the following keys:
  - `source`: An element for the event source (e.g. root)
  - `name`: A string for the event name (e.g. "onExternalModsAdded")
  - (optional) `args`: A table for the event arguments (e.g. `{}`)

**Returns**:

- a `boolean` which is **true** if the mods started being removed [**OR**] **false** if not

---

## 🔧 Exported Functions (**Client**)

All client-side only exported functions are explained here.

---

### **isClientReady**()

Checks if the client has received the mod list from the server.

**Returns**:

- a `boolean` which is **true** if the client has received the mod list [**OR**] **false** if not

---

### **isModAllocated**(`id`)

Checks if the client has allocated the mod.

**Required arguments**:

- `id`: A number (e.g. 50001)

**Returns**:

- a `number` corresponding to the **allocated model ID** if the mod is allocated [**OR**] **nil** if not or invalid id was provided

---

### **forceAllocate**(`id`)

Forces the client to allocate the mod.

**Required arguments**:

- `id`: A number (e.g. 50001)

**Returns**:

- a `number` corresponding to the **allocated model ID** if the mod was successfully allocated [**OR**] **nil** if not or invalid id was provided
- a `string` corresponding to the reason of failure if it was not allocated successfully or invalid id was provided

---

### **forceFreeAllocated**(`id`, `immediate`)

Forces the client to free the allocated mod.

**Required arguments**:

- `id`: A number (e.g. 50001)

**Optional arguments**:

- `immediate`: A boolean (e.g. false)

**Returns**:

- a `string` corresponding to the result message ("INVALID_ID", "NOT_ALLOCATED", "FREED", "FREED_LATER")
- a `boolean` which is **true** when `engineFreeModel` works if the mod was freed immediately [**OR**] **nil** otherwise

---

### **forceDownloadMod**(`id`)

Forces the client to download the mod.

**Required arguments**:

- `id`: A number (e.g. 50001)

**Returns**:

- a `mixed type variable` which is **true** if the mod started downloading [**OR**] **false** if not or invalid id was provided [**OR**] **"MOD_READY"** if the mod is already downloaded

---

### **isBusyDownloading**()

Checks if the client is busy downloading a mod.

**Returns**:

- a `boolean` which is **true** if the client is busy downloading a mod [**OR**] **false** if not

---

## 🧲 Custom Events (**Client**)

All client-side only custom events **intended for other resources to handle** are explained here.

All event names are prefixed with `resourceName` (e.g. `"newmodels"`) + `":"` which results in `"newmodels:onModListReceived"` for example. This allows you to change the resource name without having to change the event names in your scripts.

---

### **onModListReceived**

This event is triggered when the client receives the mod list from the server.

**Source**: `localPlayer`

**Arguments**:

- `list`: A table containing the mod list

---

### **onModFileDownloaded**

This event is triggered when the client finishes downloading a mod file (e.g. "mycar.dff")

**Source**: `localPlayer`

**Arguments**:

- `id`: A number (e.g. 50001)

---
