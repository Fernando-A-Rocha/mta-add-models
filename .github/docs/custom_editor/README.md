![Newmodels Map Editor Banner](https://i.imgur.com/ln6mrLr.png)

The Newmodels Map Editor Project consits of **🧬experimental🧬** customized MTA:SA Map Editor resources to support new model IDs for vehicles, objects and skins using newmodels ([mta-add-models Project](https://github.com/Fernando-A-Rocha/mta-add-models#readme)).

MTA forum thread: [link](https://forum.mtasa.com/topic/133212-rel-add-new-models-library/#comment-1003395)

## Support/Help

If you need help with anything related to this project, please read the corresponding section on the MTA forum thread linked above.

## Showcase Video

Coming soon!

## Installation

Currently, you cannot install this Map Editor alongside the default Map Editor resources. It needs to be replaced.

1. [Download the latest release](https://github.com/Fernando-A-Rocha/mta-add-models/releases/latest) containing newmodels, the custom Map Editor & other resources.
    * Extract the `[editor_custom]` folder to your Desktop, for example, and open it.
    * You should see the folders `[editor_changes]` & `newmodels_editor`.

2. Make sure you've installed `newmodels` in your server properly (tutorial [here](/README.md#install)).

3. Get **this version (*r1553*)** of the default MTA:SA Editor resources :
    * Download link: [https://mirror-cdn.multitheftauto.com/mtasa/resources/mtasa-resources-r1553.zip](https://mirror-cdn.multitheftauto.com/mtasa/resources/mtasa-resources-r1553.zip)
    * ⚠️ Other versions of the default Map Editor resources may not be compatible with the custom changes ⚠️
    * Extract the `[editor]` folder into your server's resources

4. Drag & drop everything in the `[editor_changes]` folder downloaded to your default `[editor]` folder.
    * This will replace files in the following resources: `edf`, `editor_main` & `editor_gui`

5. Drag & drop the `newmodels_editor` resource folder into your server's resources. This is a required toolkit.

6. Use **/refresh** command in your server to find the changes.

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

**Happy mapping!**

## Contributing

Want to help make this project better? See [this note](https://github.com/Fernando-A-Rocha/mta-add-models#final-note).

## Credits

* [Fernando](https://github.com/Fernando-A-Rocha)
* [Rick](https://github.com/httpRick)
* [MTA:SA Resources Contributors](https://github.com/multitheftauto/mtasa-resources)
