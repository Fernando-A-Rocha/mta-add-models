# Custom Map Editor

In this folder you will find the MTA:SA Map Editor resources customized specifically to support new model IDs for vehicles, objects and skins using newmodels.

## Installation

Currently, you cannot install this Map Editor alongside the default Map Editor resources.

1. Get the default MTA:SA Editor resources if you don't have them on your server already:
    * Download all resources [https://mirror.mtasa.com/mtasa/resources/mtasa-resources-latest.zip](https://mirror.mtasa.com/mtasa/resources/mtasa-resources-latest.zip)
    * You only need the default `[editor]` folder containing all Map Editor resources

2. Drag & drop the custom `[editor]` folder into your server's resources, replacing the following resources:
    * `edf`
    * `editor_main`
    * `editor_gui`

3. Drag & drop the `newmodels_editor` resource folder into your server's resources. This is a required toolkit.

## Usage

To use new models in your map, the editor needs to know which models have been added. The `models list` is stored inside XML files for objects, vehicles & skins in the `editor_gui` resource. We opted by not changing how the Map Editor reads these files, so it would be easier to update the Map Editor in the future.

1. Make sure the `editor` resource is stopped.
2. Start the `newmodels_editor` resource.
3. Execute command **/newmodels_editor** in-game.
   * Do this every time you want to update the editor's new models list.
4. Start the `editor` resource.
5. Enjoy.

You can place down new vehicles, objects and skins in your map. The editor script sets the element datas when spawning the elements.
When saving the map, the element datas are saved in the XML file. When a map is loaded, it will set all those datas => setting the correct new model IDs.

This means that the map can be loaded on any server that has the same new models in their `newmodels` resource, not requiring the custom map editor which is just for creating the maps :-)

Be creative and have fun!