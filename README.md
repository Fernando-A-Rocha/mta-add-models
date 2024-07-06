⚠️ This is the old version of `newmodels`. Visit the [main branch](https://github.com/Fernando-A-Rocha/mta-add-models/tree/main) for the newest version.

![Banner](https://i.imgur.com/R1Gno6b.png)

**mta-add-models** is an MTA resource (library) which makes use of the [engineRequestModel](https://wiki.multitheftauto.com/wiki/EngineRequestModel) features to add new peds (skins), vehicles and objects:

- syncs all added models with all players
- minimalistic, optimized and bug free

In simpler terms, with this resource you can make scripts/change your scripts to add new skin, vehicle and object IDs to your server! For example we can now add all SA-MP objects *whilst keeping their intended IDs*.

MTA forum thread: [link](https://forum.mtasa.com/topic/133212-rel-add-new-models-library/#comment-1003395)

## Getting Started

[General Information/Guide](/.github/docs/MAIN.md): It should help you understand how the newmodels resource works and how to use it.

### Prerequisites

- Required minimum MTA Server & Client version `1.6.0-9.22204.0` (MTA 1.6) ⚠️
- Get the installers from [nightly.mtasa.com](https://nightly.mtasa.com/)
- Client should auto-update upon joining the server
- *Find out what the build numbers mean here: [buildinfo.mtasa.com](https://buildinfo.mtasa.com/)*
- **If you don't have the right version these resources will not work correctly**

### Includes

[newmodels](/newmodels): main library resource

- (debugging) [unittest_newmodels](/[examples]/unittest_newmodels): a resource for testing the main scripts
- (recommended) [newmodels-engine](/[examples]/newmodels-engine): a resource that uses the main scripts (useful)
- (optional) [sampobj_reloaded](/[examples]/sampobj_reloaded): a resource that adds all SA-MP object models to your server
  - 👉 [Download](https://www.mediafire.com/file/mgqrk0rq7jrgsuc/models.zip/file) `models.zip` containing all dff/txd/col files required
- (optional) [vehicle_manager](/[examples]/vehicle_manager): a basic resource that adds some vehicle models to your server with custom properties
- (optional) [editor_custom](/.github/docs/custom_editor/README.md): modified MTA:SA Map Editor resources to support using new model IDs

### Install

- Get the latest release: [here](https://github.com/Fernando-A-Rocha/mta-add-models/releases/latest)
- Download the source code Zip and extract it
- Place the `newmodels` folder in your server's resources
- Use command `start newmodels` in server console

### Quick Testing

- Place mod files [newmodels/models](/newmodels/models) (dff & txd (& col for objects))
- List them in [newmodels/meta.xml](/newmodels/meta.xml) like the example
- As of version 2.0, files have the `download="false"` attribute, causing newmodels to handle downloading them later only when needed
- Define them in [newmodels/mod_list.lua](/newmodels/mod_list.lua) inside `modList` like the example
- Use the [commands](#commands) to test, have fun!

### Commands

Main testing commands in `newmodels`:

- /listmods **lists all defined mods**
- /allocatedids **shows all allocated mod IDs in realtime**
- /selements **lists all streamed in elements for debugging purposes**
- /myskin [ID] **sets your skin to a default or new ID**
- /makeped [ID] **creates a ped and sets its model to a default or new ID**
- /makeobject [ID] **creates an object and sets its model to a default or new ID**
- /makevehicle [ID] **creates a vehicle and sets its model to a default or new ID**

## NandoCrypt

There is support for encrypted model files using the [NandoCrypt](https://github.com/Fernando-A-Rocha/mta-nandocrypt) resource.

This is useful for those who want to keep the models private & prevent people from stealing them.

## Credits

The resources `newmodels`, `vehicle_manager` and `sampobj_reloaded` include mods from the following sources:

- [SA-MP](https://dev.prineside.com/en/gtasa_samp_model_id/tag/2-sa-mp/)
- [SA Proper Fixes (MixMods)](https://www.mixmods.com.br/2022/08/sa-proper-fixes/)
