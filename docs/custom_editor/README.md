# Custom Map Editor

In this folder you will find the MTA:SA Map Editor resources customized specifically to support new model IDs for vehicles, objects and skins using newmodels.

## Installation

Currently, you cannot install this Map Editor alongside the default Map Editor resources.

1. Drag & drop the `[editor]` folder into your server's resources, replacing the following resources:
    * `[edf]`
    * `[editor_main]`
    * `[editor_gui]`

2. Drag & drop the `newmodels_editor` resource folder into your server's resources. This is a required toolkit.

## Usage

To use new models in your map, the editor needs to know which models have been added. The `models list` is stored inside XML files for objects, vehicles & skins in the `editor_gui` resource. We opted by not changing how the Map Editor reads these files, so it would be easier to update the Map Editor in the future.

1. Make sure the `editor` resource is stopped.
2. Start the `newmodels_editor` resource.
3. Execute command **/newmodels_editor** in-game.
   * Do this every time you want to update the editor's new models list.
4. Start the `editor` resource.
5. Enjoy.
