![Newmodels Map Editor Banner](https://i.imgur.com/ln6mrLr.png)

The Newmodels Map Editor Project consits of **🧬experimental🧬** customized MTA:SA Map Editor resources to support new model IDs for vehicles, objects and skins using newmodels ([mta-add-models Project](https://github.com/Fernando-A-Rocha/mta-add-models#readme)).

MTA forum thread: [link](https://forum.mtasa.com/topic/133212-rel-add-new-models-library/#comment-1003395)

## Support/Help

If you need help with anything related to this project, please read the corresponding section on the MTA forum thread linked above.

## Installation

1. Follow the instructions on the [New-Models Editor v2.2.0 release page](https://github.com/Fernando-A-Rocha/mtasa-resources/releases/tag/v2.2.0-newmodels-editor).

2. Make sure you've installed `newmodels` in your server properly (tutorial [here](/README.md#install)).

3. Make sure you have installed the `newmodels` & `newmodels-engine` resources included which you can obtain from the [mta-add-models v2.2.0 release page](https://github.com/Fernando-A-Rocha/mta-add-models/releases/tag/v2.2.0).
    * Both of these are required for the New-Models Map Editor to work.
    * Make sure you have the right compatible versions of both resources installed.

4. Use **/refresh** command in your server to find the changes.

## Usage

To use new models in your map, the editor needs to know which models have been added. The `models list` is stored inside XML files for objects, vehicles & skins in the `editor_gui` resource. We opted by not changing how the Map Editor reads these files, so it would be easier to update the Map Editor in the future.

The resource `editor_newmodels` is responsible for applying the new models to the editor GUI. It reads them from `newmodels` and adds the new models to the `models list` XML files.

This happens automatically when `editor_newmodels` is started. You can also use the command `/editor_newmodels` to force-update the models list.

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
