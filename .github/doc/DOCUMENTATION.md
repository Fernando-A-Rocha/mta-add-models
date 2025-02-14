# Quick Start

There are **2 things** you need to worry about.

## 1. Adding new models (DFF/TXD/COL)

The main concept of this system is that you can add new arbitrary numerical IDs that represent new models.

- e.g. `ID -3` for a new gangster skin
- e.g. `ID -2` for a new SUV vehicle model

The new IDs can be any number (positive or negative) as long as it does not conflict with existing or reserved game IDs. The script will warn you if you use incorrect numbers.

A game model can be added with up to **3 different files** for a certain entity type. The supported model types:

- `ped` (skins): DFF and TXD files
- `vehicle`: DFF and TXD files
- `object`: DFF, COL and TXD files

The files must be placed in the [models](/newmodels_azul/models/) folder. The system will automatically load them.

### File & Folder Structure

- **Possibility #1** (the new models do not have names): `models/<model_type>/<base_model_id>/<new_model_id>.<file_extension>`

e.g. `models/ped/7/-3.txd`
e.g. `models/ped/7/-3.dff`

- **Possibility #2** (the new models have custom names for organization purposes): `models/<model_type>/<base_model_id>/<new_model_name>/<new_model_id>.<file_extension>`

e.g. `models/ped/7/Mafioso 1/-2.txd`
e.g. `models/ped/7/Mafioso 1/-2.dff`

### Additional customization

Models can be customized with `<new_model_id>.txt` files. Check [this README](/newmodels_azul/models/README.md) for more information.

## 2. Using the new models

MTA allocates unused IDs **clientside** to load the new models (thanks to [`engineRequestModel`](https://wiki.multitheftauto.com/engineRequestModel)). These IDs are unpredictable and you can not depend on them.

Remember, the model allocation happens only clientside, so the server has no concept of any new IDs. As a developer, you have 2 options to be able to **use the new IDs you defined in your scripts**.

See the [example resources](/[examples]/) to understand how to use the following methods.

### Importing functions

The easiest way is to use the following method in the beginning of your script to load the necessary functions.

```lua
loadstring( exports['newmodels_azul']:import() )()
```

This modifies MTA functions such as `createVehicle` or `setElementModel` to work with the new IDs, and adds new functions such as `getElementBaseModel` and `getElementCustomModel` that you can use.

Check the [`shared_exported.lua`](/newmodels_azul/core/shared_exported.lua) script to know what gets imported.

Example usage:

```lua
-- This custom function will work with IDs such as -2 because it was imported
local vehicle = createVehicle(id, x, y, z, rx, ry, rz, numberplate)
```

### Calling exported functions

If you do not wish to use `loadstring` to import the functions, you can call them directly.

Check the [`meta.xml`](/newmodels_azul/meta.xml) file to see the exported functions.

Example usage:

```lua
-- The normal createVehicle would not work invented IDs such as -2
local vehicle = exports['newmodels_azul']:createVehicle(id, x, y, z, rx, ry, rz, numberplate)
```
