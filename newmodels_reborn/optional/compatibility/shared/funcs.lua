-- Backwards compatibility with newmodels 3.3.0
-- Exported functions from old newmodels working with the new system

local isClientsideScript = localPlayer ~= nil

local function convertCustomModelInfoToOldFormat(customModel, customModelInfo)
    local baseModel = customModelInfo.baseModel
    local colPath, txdPath, dffPath, name = customModelInfo.col, customModelInfo.txd, customModelInfo.dff, customModelInfo.name
    local mod = {
        id = customModel,
        base_id = baseModel,
        name = name,
        path = { col = colPath, txd = txdPath, dff = dffPath },
    }
    mod.paths = mod.path
    return mod
end

-- Exported
function getDataNameFromType(elementType)
    if type(elementType) == "string" then
        return OLD_DATA_NAMES[elementType]
    end
end

-- Rewrite this function
_getCustomModelDataKey = getCustomModelDataKey
function getCustomModelDataKey(elementOrElementType)
    if type(elementOrElementType) == "string" then
        return OLD_DATA_NAMES[elementOrElementType]
    elseif isElement(elementOrElementType) then
        local elementType = getElementType(elementOrElementType)
        return OLD_DATA_NAMES[elementType]
    end
    return _getCustomModelDataKey(elementOrElementType)
end

-- Exported
function getBaseModelDataName()
    return OLD_BASE_DATA_NAME
end

-- Exported
function getModDataFromID(id)
    id = tonumber(id)
    if not id then return end
    local customInfo = customModels[id]
    if not customInfo then return end
    local mod = convertCustomModelInfoToOldFormat(id, customInfo)
    return mod, customInfo.type
end

-- Exported
function getModList()
    local modList = {}
    for id, customInfo in pairs(customModels) do
        modList[id] = convertCustomModelInfoToOldFormat(id, customInfo)
    end
    return modList
end

-- Exported
function getBaseModel(element)
    if not isClientsideScript then
        return getElementModel(element)
    else
        local customModel = tonumber(getElementData(element, getCustomModelDataKey(element)))
        if customModel then
            return customModels[customModel] and customModels[customModel].baseModel or nil
        else
            return getElementModel(element)
        end
    end
end

-- Exported
function isCustomModID(id)
    local mod, modType = getModDataFromID(id)
    if not mod then return false end
    return true, mod, modType
end

-- Exported
function isRightModType(et, modEt)
    if et == modEt then
        return true
    end
    if (et == "player" or et == "ped") and (modEt == "player" or modEt == "ped") then
        return true
    end
    if (et == "pickup" or et == "object") and (modEt == "pickup" or modEt == "object") then
        return true
    end
    return false
end

-- Exported
function checkModelID(id, elementType)
    assert(tonumber(id), "Non-number ID passed")
    assert(
        (elementType == "ped" or elementType == "player" or elementType == "object" or elementType == "vehicle" or elementType == "pickup"),
        "Invalid element type passed: " .. tostring(elementType))
    local dataName = OLD_DATA_NAMES[elementType]
    assert(dataName, "No data name for element type: " .. tostring(elementType))
    if elementType == "pickup" then
        elementType = "object"
    end
    local baseModel
    local isCustom, mod, modType = isCustomModID(id)
    if isCustom then
        if not isRightModType(elementType, modType) then
            return "WRONG_MOD"
        end
        if mod then baseModel = mod.base_id end
    elseif isDefaultID(elementType, id) then
        baseModel = id
    else
        return "INVALID_MODEL"
    end

    return baseModel, isCustom, dataName, OLD_BASE_DATA_NAME
end

if isClientsideScript then
    -- Exported
    function isClientReady() return true end -- Now the client is always ready :-)

    -- Exported
    function isModAllocated(id)
        id = tonumber(id)
        if not id then return end
        return loadedModels[id] ~= nil
    end
end
