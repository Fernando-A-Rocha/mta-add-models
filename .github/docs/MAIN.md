# Using Newmodels

This library was created with the goal of being usable in any server without breaking most of its scripts. It actually lets you use default GTA model IDs on any elements. Look no further if you want to implement new model IDs and understand how they can be set/fetched.

## Guide

Below is some general information to help you start using this library. It is strongly encouraged to explore the scripts and read the code to understand how it works.

Related:

- [Lua Examples](/.github/docs/EXAMPLES.md)
- [Example Resources/Scripts](/[examples])
- [New-Models in Map Editor](/.github/docs/custom_editor/README.md)
- [newmodels Functions & Events](/.github/docs/newmodels/FUNCS_EVENTS.md)
- [newmodels-engine Functions & Events](/.github/docs/newmodels-engine/FUNCS_EVENTS.md)

### (❗) Adding/Removing Mods

This library lets you load mods stored within the `newmodels` resource, and also add mods stored in other resources to the `modList` that it will load from.

Check the [quick testing](#quick-testing) to understand how to load mods from within the `newmodels` resource (easier).

You have at your disposal the following exported functions:

Adding mods from other resources (ID.dff, ID.txd, ID.col):

- `addExternalMod_IDFilenames(...)`
- `addExternalMods_IDFilenames(list_of_mods)` uses the function above^

Adding mods from other resources (custom filenames):

- `addExternalMod_CustomFilenames(...)`
- `addExternalMods_CustomFileNames(list_of_mods)` uses the function above^

Removing a mod from the `modList` which was added by another resource:

- `removeExternalMod(id)`
- `removeExternalMods(list_of_ids)`

PS: **...** means that this function accepts several variables.

See [the documentation](/.github/docs/newmodels/FUNCS_EVENTS.md) to better understand the functions.

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

### Switching Element Models

If you have an element with a custom model ID and you want to switch it to another custom model ID, do the following:

- Check if model ID you want to set is custom or default using `isDefaultID(modelID)` and `isCustomModID(modelID)`
- If it's a custom ID then do the following:
  - Obtain the base/parent model ID from the mod by accessing `mod.base_id`
  - Set the element's model to the base ID
  - Set the element's custom model ID data with the name you just obtained (`setElementData(element, dataName, modelID)`)
- Otherwise if it's a default ID then do the following:
  - Remove the custom model ID data using `setElementModel(element, dataName, nil)` or `removeElementData(element, dataName)`
  - Set the element's model to the default ID

### Simplified Usage

If you don't want to code your own functions to manage elements with custom model IDs, use the `newmodels-engine` resource.

It provides you with the following functions that you can use in your server (e.g. in a vehicle system):

- `createObject` -- safely create an object with custom/normal model ID
- `createVehicle` -- safely create a vehicle with custom/normal model ID
- `createPed` -- safely create a ped with custom/normal model ID
- `setElementModel` -- safely set a custom/normal model ID on an element
- `getElementModel` -- safely get a custom/normal model ID from an element
- `createPickup` -- safely create a pickup with custom/normal model ID (type 3 is the one that supports object models)
- `setPickupType` -- safely change a pickup type 3's model ID to a custom/normal model ID

## Known Implementations

Feel free to add your own implementations to this list by contributing to the repository via pull requests.

- [OwlGaming Gamemode](https://github.com/OwlGamingCommunity/MTA) - Guide for [Custom Ped Models (Skins)](/.github/docs/implementations/OWL_PEDS.md)
