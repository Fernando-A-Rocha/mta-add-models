# Newmodels v5 `Azul💙`

This MTA resource makes use of the clientside allocated models ([engineRequestModel](https://wiki.multitheftauto.com/wiki/EngineRequestModel) and related features) to add new peds (skins), vehicles and objects:

- place your mods (dff/txd/col files) in designated folders that are automatically detected
- the system syncs all added models with all players
- use a simple trick in your existing scripts to work with the new model IDs
- it's minimalistic, optimized and robust

With this resource you can make scripts or change your existing scripts to add new skin, vehicle and object IDs to your server! For example, you may add all SA-MP object models!

## Docs/Tutorial

🚀 **Are you new to this resource?** Start here: [Documentation file](/.github/doc/DOCUMENTATION.md)

## Requirements

⚠️ **Before you download and install this resource**, make sure you have the following:

- MTA 1.6 Nightly server (most recent version recommended from [nightly.multitheftauto.com](https://nightly.multitheftauto.com/))
- Up to date MTA client to play on the server
- Some scripting knowledge to use the new models in your scripts
- Basic understanding of GTA:SA and how game mods work

## Download

Get the [Latest Version](https://github.com/Fernando-A-Rocha/mta-add-models/releases/latest) from the **Releases** section.

## Older versions

It is easy to migrate to v5 from newmodels v4 (not from v3; the architecture of that version is no longer used). The **models folder structure remains the same**, but the scripts have changed in the way models are applied to elements.

This resource no longer uses and relies on the **MTA Element Data system** (`setElementData`) to sync the models to all clients! Instead, newmodels makes use of Lua tables and MTA events. This major change was made to **improve performance** and control the sync of models more efficiently.

## Community

Visit the [Thread on the MTA Forum](https://forum.mtasa.com/topic/133212-rel-add-new-models-library/) to get in touch with fellow users and developers.

## Media

![Screenshot 1](/.github/img/ss1.png)

## Final Note

Feel free to update the documentation in this repository, and contribute to the code via pull requests.

Thank you for reading. Have fun! 🎉
