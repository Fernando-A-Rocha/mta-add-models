local function outputError(msg)
    outputServerLog("[CUSTOM_MODELS] " .. msg)
end
local function passVerifications()
    if type(CUSTOM_MODELS) ~= "table" then
        return false, outputError("CUSTOM_MODELS is not a table. Check if models.lua failed to load.")
    end
    for newId, v in pairs(CUSTOM_MODELS) do
        if type(newId) ~= "number" then
            return false, outputError("Invalid new ID type for model " .. inspect(newId))
        end
        if type(v) ~= "table" then
            return false, outputError("Invalid data type for model " .. newId)
        end
        if type(v.type) ~= "string" then
            return false, outputError("Invalid type for model " .. newId)
        end
        if not (v.type == "vehicle" or v.type == "ped" or v.type == "object") then
            return false, outputError("Invalid type for model " .. newId)
        end
        if isDefaultID(v.type, newId) then
            return false, outputError("Model " .. newId .. " is already a default model")
        end
        if type(v.baseId) ~= "number" then
            return false, outputError("Invalid base ID for model " .. newId)
        end
        if not isDefaultID(v.type, v.baseId) then
            return false, outputError("Base ID for model " .. newId .. " is not a default model")
        end
        if v.dff ~= nil and type(v.dff) ~= "string" then
            return false, outputError("Invalid DFF path for model " .. newId)
        end
        if v.txd ~= nil and type(v.txd) ~= "string" then
            return false, outputError("Invalid TXD path for model " .. newId)
        end
        if v.col ~= nil and type(v.col) ~= "string" then
            return false, outputError("Invalid COL path for model " .. newId)
        end
    end
    return true
end
addEventHandler("onResourceStart", resourceRoot, function()
    local result = passVerifications()
    if not result then
        cancelEvent(true, "CUSTOM_MODELS verification failed. Check server log for more information.")
    end
end, false)
