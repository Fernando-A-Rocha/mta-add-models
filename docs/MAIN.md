# Using Newmodels

This library was created with the goal of being usable in any server without breaking most of its scripts. It actually lets you use default GTA model IDs on any elements serverside, without issues. However, look no further if you want to implement new model IDs and how they can be set/fetched.

## Guide

Below is some general information to help you start using this library. It is strongly encouraged to explode the scripts and read the code to understand how it works.

Remember to check [Lua Examples](/docs/EXAMPLES.md).

### (❗) Adding/Removing Mods

This library lets you load mods stored within the `newmodels` resource, and also add mods stored in other resources to the `modList` that it will load from.

Check the [quick testing](#quick-testing) to understand how to load mods from within the `newmodels` resource (easier).

You have at your disposal the following exported functions, [see code to understand](/newmodels/server.lua) and [example to see implementation](/[examples]/newmodels-example/server.lua):

Adding mods from other resources (ID.dff, ID.txd, ID.col):

- `addExternalMod_IDFilenames(elementType, id, base_id, name, path, ignoreTXD, ignoreDFF, ignoreCOL)`
- `addExternalMods_IDFilenames(list)` uses the function above^

Adding mods from other resources (custom filenames):

- `addExternalMod_CustomFilenames(elementType, id, base_id, name, path_dff, path_txd, path_col, ignoreTXD, ignoreDFF, ignoreCOL)`
- `addExternalMods_CustomFileNames(list)` uses the function above^

Removing a mod from the `modList` which was added by another resource:

- `removeExternalMod(id)`

### Applying New Model IDs

Creating elements with custom IDs **serverside** is usually done with these functions: `createPed`, `createObject`, `createVehicle`, `spawnPlayer`.

Before creating the element, it's important to follow the following steps:

- Fetch element data name from this resouce using `getDataNameFromType(elementType)`
- Check if model ID you want to set is custom or default using `isDefaultID(modelID)` and `isCustomModID(modelID)`
- If it's a custom ID then do the following:
  - Obtain the base/parent model ID from the mod by accessing `mod.base_id`
  - Create the element using the functions listed above with the base ID
  - Set the element's custom model ID data with the name you just obtained (`setElementData(element, dataName, modelID)`)
- Otherwise if it's a default ID then just create the element as usual, and feel free to also use `setElementModel`

This resource makes the clients listen to the set element datas in order to apply custom model IDs accordingly on their game (automatic sync).

- You cannot `setElementModel` a custom ID.
- **Clientside**: `getElementModel` will return an arbitrary ID (that MTA generates) on elements with custom model IDs that you set. To get the actual custom ID, use `getElementData(dataName, element)` instead.
- **Serverside**: `getElementModel` will return always return base model of any element.

### Simplified Usage

If you don't want to code your own functions to manage elements with custom model IDs, use the `newmodels-engine` resource.

It provides you with the following functions that you can use in your server (e.g. in a vehicle system):

- `createObject` -- safely create an object with custom/normal model ID
- `createVehicle` -- safely create a vehicle with custom/normal model ID
- `createPed` -- safely create a ped with custom/normal model ID
- `createPickup` -- safely create a pickup with custom/normal model ID (type 3 is the one that supports object models)
- `setElementModel` -- safely set a custom/normal model ID on an element
- `setPickupType` -- safely change a pickup type 3's model ID to a custom/normal model ID
- `getElementModel` -- safely get a custom/normal model ID from an element

## Known Implementations

Feel free to add your own implementations to this list by contributing to the repository via pull requests.

- [OwlGaming Gamemode](https://github.com/OwlGamingCommunity/MTA) - Guide for [Custom Ped Models (Skins)](/docs/implementations/OWL_PEDS.md)
