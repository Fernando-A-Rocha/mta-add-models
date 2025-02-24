# `Newmodels Azul` Documentation

## Frequently Asked Questions (FAQ)

⚠️ Do not forget to check the [Basics](#basics) section below.

| **Question**                                                                                     | **Answer**                                                                                                                                                                                                 |
|--------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **What do I need to know to use this system?**                                                   | Basic knowledge of MTA scripting (Lua) and how MTA servers and game clients work.                                                                                                                         |
| **Who is this system intended for?**                                                            | Server owners and developers who want to add new models to their MTA server for custom skins, vehicles, objects, etc.                                                                                     |
| **Will players download the files (DFF/TXD/COL) of the added models automatically?**            | Yes, the [`meta.xml`](/newmodels_azul/meta.xml) configuration includes all of these files in the [models folder](/newmodels_azul/models/) so they are automatically downloaded by players when they join the server. |
| **Why not use the `download="false"` attribute in the `meta.xml` so they are not downloaded by players, then download them on demand?** | This feature is currently not implemented due to common complaints about `downloadFile` sometimes being unreliable and causing server lag. It is better to serve all files to the player at once.            |
| **Can I encrypt my model files and hide the decryption key so players cannot steal them?**       | Yes, you can use the **NandoCrypt** which is natively supported by this system.                                                                                                                           |
| **How are added models identified?**                                                            | New models are identified by numerical IDs that you define. These IDs can be any number (positive or negative) as long as they do not conflict with existing or reserved game IDs. They are purely arbitrary and do not have to be sequential. |
| **Why new model IDs and not strings/names for identification?**                                 | MTA uses numerical IDs to identify models, so this system follows the same convention. It is more efficient and easier to work with numbers than strings.                                                  |
| **How do I add models using this system?**                                                      | Essentially, you add new models by placing the DFF/TXD/COL files in the [models folder](/newmodels_azul/models/) with specific file and folder names.                                                       |
| **How do I use the new models in my scripts?**                                                  | You can use the exported functions provided by this system in your own scripts.                                                                                                                            |
| **Can I use the new models in my existing scripts without modifying them?**                      | In theory, yes. You can use the `loadstring` method to import the functions at the beginning of your script. This will modify the MTA functions to work with the new IDs. However, always be careful and verify if you do not break any feature in your scripts. |
| **Can I use the new models in my existing scripts by calling the exported functions directly?**  | Yes, you can call the exported functions directly in your scripts, without using `loadstring`.                                                                                                             |
| **Can I use the new models in both server-side and client-side scripts?**                        | Yes, the exported functions are shared, meaning you can use them in both client and server side scripts. However, their behaviors are different.                                                           |
| **Why is are new models added client-side in MTA and this logic doesn't exist server-side?**                      | MTA model allocation happens client-side, so the server has no concept of any new IDs. Server-side model allocation is still not implemented on MTA (but may be in the future 😉), so this system provides a way to work around this limitation. |
| **Are there any premade modpacks for new models that I can drag & drop to my server?**                      | Sure, the community has created many new object, vehicle and skin mods over the years. You can search for these models online. [You can find more information here about adding all of SA-MP's objects.](/newmodels_azul/models/object/1337/SAMP/README.md) |

## Basics

There are **2 things** you need to worry about.

### 1. Adding new models (DFF/TXD/COL)

The main concept of this system is that you can add new arbitrary numerical IDs that represent new models.

- e.g. `ID -3` for a new gangster skin
- e.g. `ID -2` for a new SUV vehicle model

The new IDs can be any number (positive or negative) as long as it does not conflict with existing or reserved game IDs. The script will warn you if you use incorrect numbers.

A game model can be added with up to **3 different files** for a certain entity type. The supported model types:

- `ped` (skins): DFF and TXD files
- `vehicle`: DFF and TXD files
- `object`: DFF, COL and TXD files

The files must be placed in the [models](/newmodels_azul/models/) folder. The system will automatically load them.

#### File & Folder Structure

- **Possibility #1** (the new models do not have names): `models/<model_type>/<base_model_id>/<new_model_id>.<file_extension>`

e.g. `models/ped/7/-3.txd`
e.g. `models/ped/7/-3.dff`

- **Possibility #2** (the new models have custom names for organization purposes): `models/<model_type>/<base_model_id>/<new_model_name>/<new_model_id>.<file_extension>`

e.g. `models/ped/7/Mafioso 1/-2.txd`
e.g. `models/ped/7/Mafioso 1/-2.dff`

#### NandoCrypt Support (Optional)

You may use [NandoCrypt](https://github.com/Fernando-A-Rocha/mta-nandocrypt) to encrypt your mod files. Place them with file extension `.nandocrypt` so they are automatically recognised. You may customize the file extension in [`shared_local.lua`](/newmodels_azul/scripts/core/shared_local.lua).

A test `nando_decrypter` script is included with the resource, as well as a mod consisting of 2 encrypted files (`-5.dff.nandocrypt` and `-5.txd.nandocrypt`). To use your own mods, you will have to replace `nando_decrypter` with your own decrypter script generated by the NandoCrypt tool.

#### Additional customization

Models can be customized with `<new_model_id>.txt` files. Check [this README](/newmodels_azul/models/README.md) for more information.

### 2. Using the new models

MTA allocates unused IDs **clientside** to load the new models (thanks to [`engineRequestModel`](https://wiki.multitheftauto.com/engineRequestModel)). These IDs are unpredictable and you can not depend on them.

Remember, the model allocation happens only clientside, so the server has no concept of any new IDs. As a developer, you have 2 options to be able to **use the new IDs you defined in your scripts**.

See the [example resources](/[examples]/) to understand how to use the following methods.

#### Server VS Client

All newmodels exported functions are shared, meaning you can use them in both client and server side scripts. Their behaviors are different.

The **server-side** functions, specifically for setting a custom model (or creating an element with a custom model) will save the custom models of elements present in your server in a `table`, then sync them using `triggerClientEvent` to all clients online. This means that, for example, creating a vehicle that is a new Helicopter, will automatically make it that model for all players in your server.

In contrast, **client-side** functions do not perform any synchronization of data with other clients. Custom models set by client-side scripts are only applied to the client that is running those scripts. This means that, for example, in a clothing store scenario you can change the player's model to any custom models using client-side functions, and only that player will see the model change in their game.

#### Importing functions

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

#### Calling exported functions

If you do not wish to use `loadstring` to import the functions, you can call them directly.

Check the [`meta.xml`](/newmodels_azul/meta.xml) file to see the exported functions.

Example usage:

```lua
-- The normal createVehicle would not work with invented IDs such as -2,
-- so we call the available exported function
local vehicle = exports['newmodels_azul']:createVehicle(id, x, y, z, rx, ry, rz, numberplate)
```

### Important Tips ⚠️

These are good practices and general advice.

- Remember that your models must work well with GTA: San Andreas in terms of optimization.
- Always test with several players and different PC specifications.
- An element created serverside with a custom model will sync its custom model to all clients.
  - Useful for spawning vehicles, setting player and NPC skins.
- An element created clientside with a custom model will not sync to other clients, meaning only the client that ran the code will see the custom model.
  - Useful for model previewing and object spawning which works best clientside.
