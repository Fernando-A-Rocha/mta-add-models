# newmodels

Below is a list of all exported functions and custom events defined in `newmodels` that you can use as a developer from your own resources.

## Exported Functions (Shared)

### **getModList**()

**Returns:** Returns a table of mods OR nil if the table is not ready yet (server hasn't finished startup / client hasn't received it)

### **getDataNameFromType**(`elementType`)

**Required arguments**:

- `elementType`: A valid element type from the dataNames table (e.g. "vehicle")

**Returns:** Returns a string corresponding to the custom data name for that element type OR nil if invalid elementType passed
