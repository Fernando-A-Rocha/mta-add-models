--
-- Read the documentation for more information on these default settings
--
-- These default values can be overridden in individual model .txt settings files.
--
DEFAULT_AUTO_MODEL_SETTINGS = {

    -- If true, a model will not be freed from memory even if you are no longer near any element using it.
    ["disableAutoFree"] = false,

    -- If true, TXD texture filtering will be disabled for the model.
    ["disableTXDTextureFiltering"] = false,

    -- If true, DFF alpha transparency will be enabled for the model.
    ["enableDFFAlphaTransparency"] = false,

    -- If true, model files (TXD, DFF, COL) will be downloaded on demand instead of all at once on resource start.
    -- On demand means the first time a player gets within streaming distance of an element using the model.
    -- You must set `download="false"` in your meta.xml for model files for this to work.
    ["downloadFilesOnDemand"] = false,
}
