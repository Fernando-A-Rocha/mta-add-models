# newmodels-engine

Below is a list of all exported functions and custom events defined in `newmodels-engine` that you can use as a developer from your own resources.

Reminder: `newmodels-engine` is an utility resource that uses `newmodels` to manage elements with custom models. It is not a standalone resource and it is not meant to be used directly by players.

## 🛠 Exported Functions (**Client & Server**)

All shared (clientside & serverside) exported functions are explained here.

---

### **createObject**(`id`, `...`)

Creates a new object with the given `id` (default or custom) and returns it.

**Required arguments**:

- `id`: The ID of the object to create. It can be a default object ID or a custom object ID.
- `...`: The arguments to pass to the object constructor. See the [createObject (MTA Wiki)](https://wiki.multitheftauto.com/wiki/CreateObject) for more info.

**Returns**:

- an `element` corresponding to the created object [**OR**] `false` if the object could not be created (the error is output to the debug console).

### **createVehicle**(id, ...)

Creates a new vehicle with the given `id` (default or custom) and returns it.

**Required arguments**:

- `id`: The ID of the vehicle to create. It can be a default vehicle ID or a custom vehicle ID.
- `...`: The arguments to pass to the vehicle constructor. See the [createVehicle (MTA Wiki)](https://wiki.multitheftauto.com/wiki/CreateVehicle) for more info.

**Returns**:

- an `element` corresponding to the created vehicle [**OR**] `false` if the vehicle could not be created (the error is output to the debug console).

### **createPed**(id, ...)

Creates a new ped with the given `id` (default or custom) and returns it.

**Required arguments**:

- `id`: The ID of the ped to create. It can be a default ped ID or a custom ped ID.
- `...`: The arguments to pass to the ped constructor. See the [createPed (MTA Wiki)](https://wiki.multitheftauto.com/wiki/CreatePed) for more info.

**Returns**:

- an `element` corresponding to the created ped [**OR**] `false` if the ped could not be created (the error is output to the debug console).

---
