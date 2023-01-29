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

---

### **createVehicle**(`id`, `...`)

Creates a new vehicle with the given `id` (default or custom) and returns it.

**Required arguments**:

- `id`: The ID of the vehicle to create. It can be a default vehicle ID or a custom vehicle ID.
- `...`: The arguments to pass to the vehicle constructor. See the [createVehicle (MTA Wiki)](https://wiki.multitheftauto.com/wiki/CreateVehicle) for more info.

**Returns**:

- an `element` corresponding to the created vehicle [**OR**] `false` if the vehicle could not be created (the error is output to the debug console).

---

### **createPed**(`id`, `...`)

Creates a new ped with the given `id` (default or custom) and returns it.

**Required arguments**:

- `id`: The ID of the ped to create. It can be a default ped ID or a custom ped ID.
- `...`: The arguments to pass to the ped constructor. See the [createPed (MTA Wiki)](https://wiki.multitheftauto.com/wiki/CreatePed) for more info.

**Returns**:

- an `element` corresponding to the created ped [**OR**] `false` if the ped could not be created (the error is output to the debug console).

---

### **createPickup**(`id`, `...`)

Creates a new pickup with the given `id` (default or custom) and returns it.

Custom object models are supported by pickups with type 3.

**Required arguments**:

- `id`: The ID of the pickup to create. It can be a default pickup ID or a custom pickup ID.
- `...`: The arguments to pass to the pickup constructor. See the [createPickup (MTA Wiki)](https://wiki.multitheftauto.com/wiki/CreatePickup) for more info.

**Returns**:

- an `element` corresponding to the created pickup [**OR**] `false` if the pickup could not be created (the error is output to the debug console).

---

### **setPickupType**(`pickup`, `theType`, `id`, `ammo`)

Sets the type of a pickup, supporting custom object models for type 3.

**Required arguments**:

- `pickup`: The pickup to set the type of.
- `theType`: The type of the pickup. See the [setPickupType (MTA Wiki)](https://wiki.multitheftauto.com/wiki/SetPickupType) for more info.
- `id`: The ID of the pickup to set. It can be a default object model ID, a custom model ID or amount/weapon for types other than 3.

**Optional arguments**:

- `ammo`: The amount of ammo to set for the pickup. Only used for type 2 (Weapon Pickup).

**Returns**:

- `true` if the pickup type was set successfully [**OR**] `false` if the pickup type could not be set (the error is output to the debug console).

---

### **setElementModel**(`element`, `id`)

Sets the model of an element, supporting custom object models.

**Required arguments**:

- `element`: The element to set the model of, must be ped/player/object/vehicle.
- `id`: The ID of the model to set. It can be a default model ID or a custom model ID.

**Returns**:

- `true` if the model was set successfully [**OR**] `false` if the model could not be set (the error is output to the debug console).

---

### **getElementModel**(`element`)

Gets the model of an element, supporting custom object models.

**Required arguments**:

- `element`: The element to get the model of, must be ped/player/object/vehicle.

**Returns**:

- the model ID of the element [**OR**] `false` if `getElementModel` fails for elements without a custom model (virtually impossible).

---
