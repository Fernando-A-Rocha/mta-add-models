# `models` folder explained

Model files (ending in `.dff`/`.col`/`.txd`) must be placed in this `models` folder **following specific rules**.

See the [example files](/newmodels_azul/models/) to visualize the structure of this system.

- **Required:** Vehicles must be placed in the `vehicle` folder, Skins in `ped`, and Objects in `object`

- **Required:** Inside the type folder, you must create a folder with the base model ID of the new model (e.g. `490`, which is FBI Rancher)

- *Optional:* Inside the base model folder, you can create a folder with the name of the new model (e.g. `2005 Schafter`)

- **Required:** Then, you must place the model files named as the New ID of the model (e.g. `80001.dff` & `80001.txd`)


*Optionally*, models can be customized with a `New ID.txt` file with the following settings (any line that doesn't contain these words is ignored):

  - `disableAutoFree`
  - `disableTXDTextureFiltering`
  - `enableDFFAlphaTransparency`
  - `txd=PATH_TO_TXD_FILE_INSIDE_models_FOLDER` (used for shared textures)
  - `dff=PATH_TO_DFF_FILE_INSIDE_models_FOLDER` (used for shared models)
  - `col=PATH_TO_COL_FILE_INSIDE_models_FOLDER` (used for shared collisions)
  - `lodDistance=NUMBER` (used for setting https://wiki.multitheftauto.com/wiki/EngineSetModelLODDistance)
  - `settings=PATH_TO_ANOTHER_SETTINGS_FILE_INSIDE_models_FOLDER` (in case you want to share the same settings between multiple models)
