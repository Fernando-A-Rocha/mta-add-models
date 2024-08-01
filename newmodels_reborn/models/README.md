Model files (ending in `.dff`/`.col`/`.txd`) must be placed in this `models` folder following specific rules

See the example files to visualize the structure of this system

- Vehicles must be placed in the `vehicle` folder, Skins in `ped`, and Objects in `object`

- Inside the type folder, you must create a folder with the base model ID of the new model (e.g. `490`, which is FBI Rancher)

- **Optional:** Inside the base model folder, you must create a folder with the name of the new model (e.g. `2005 Schafter`)

- Then, you must place the model files named as the New ID of the model (e.g. `80001.dff` & `80001.txd`)

- **Optional:** Models can be customized with a `New ID.txt` file with the following settings (any line that doesn't contain these words is ignored):

    - disableAutoFree
    - disableTXDTextureFiltering
    - enableDFFAlphaTransparency
    - txd=PATH_TO_TEXTURE_PATH_INSIDE_models_FOLDER (used for shared textures)
    - dff=PATH_TO_TEXTURE_PATH_INSIDE_models_FOLDER (used for shared models)
    - col=PATH_TO_TEXTURE_PATH_INSIDE_models_FOLDER (used for shared collisions)
