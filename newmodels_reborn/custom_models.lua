--[[
    CUSTOM_MODELS format:

    [ID] = {
        type: "vehicle" / "object" / "ped"
        dff: path to DFF file inside 'models' folder
        txd: path to TXD file inside 'models' folder
        col: path to COL file inside 'models' folder
        baseId: base model ID for this custom model (inherits some of its properties)
    },


    HELP / USEFUL LINKS:

    - Vehicle IDs: https://wiki.multitheftauto.com/wiki/Vehicle_IDs
    - Skin IDs: https://wiki.multitheftauto.com/wiki/All_Skins_Page
    - Object IDs: https://dev.prineside.com/gtasa_samp_model_id or https://wiki.multitheftauto.com/wiki/Object_IDs
]]

CUSTOM_MODELS = {

    -- Examples:
    [-1] = { type = "vehicle", dff = "jeep1.dff", txd = "jeep1.txd", baseId = 490 }, -- (Base model is FBI Rancher)
    [-2] = { type = "ped", dff = "my_skins/-2.dff", txd = "my_skins/-2.txd", baseId = 7 },
    [-3] = { type = "ped", dff = "my_skins/-3.dff", txd = "my_skins/-3.txd", baseId = 7 },
    [-4] = { type = "ped", dff = "my_skins/-4.dff", txd = "my_skins/-4.txd", baseId = 7 },
}
