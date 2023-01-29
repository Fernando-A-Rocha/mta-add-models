# newmodels

Below is a list of all exported functions and custom events defined in `newmodels` that you can use as a developer from your own resources.

## Exported Functions (**Client & Server**)

---

### **getModList**()

**Returns:**

- a `table` corresponding to the of mod list [**OR**] `nil` if the table is not ready yet (server hasn't finished startup / client hasn't received it)

---

### **getDataNameFromType**(`elementType`)

**Required arguments**:

- `elementType`: A valid element type from the dataNames table (e.g. "vehicle")

**Returns:**

- a `string` corresponding to the **custom data name for that element type** [**OR**] `nil` if invalid elementType passed

---

### **getBaseModelDataName**()

**Returns:**

- a `string` corresponding to the **custom data name for base/parent model**

---

### **getBaseModel**(`element`)

**Required arguments**:

- `element`: A valid element (e.g. player)

**Returns:**

- a `number` corresponding to the **base/parent model ID** of the element [**OR**] `false` if `getElementModel` on element passed fails

---

### **getModDataFromID**(`id`)

**Required arguments**:

- `id`: A number (e.g. 80001)

**Returns:**

- a `table` corresponding to the **mod** with that ID **OR** `nil` if the mod list table is not ready yet (server hasn't finished startup / client hasn't received it) / invalid number passed
- a `string` corresponding to the mod's **element type** if it was found

---
