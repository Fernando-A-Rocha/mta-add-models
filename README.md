# mta-add-models


Simple MTA scripts that make use of [engineRequestModel](https://wiki.multitheftauto.com/wiki/EngineRequestModel) function, syncing added models with all players\
I made this to help someone understand how it works, enjoy <3\
Currently very minimalistic & mainly for testing purposes

## Supported Types

- [x] ped *(skin)*
- [ ] vehicle
- [ ] object

## Commands

- /listmods *lists all defined mods*
- /pedskin [ID] *creates a ped and sets their skin to a default or new ID*
- /myskin [ID] *sets your skin to a default or new ID*
- /allocatedids *lists all allocated mod IDs*

## Quick Tutorial

- place mod files newmodels/models (dff & txd)
- list them in meta.xml like the example
- define them in shared.lua inside modList like the example
- use the commands to test, have fun!
