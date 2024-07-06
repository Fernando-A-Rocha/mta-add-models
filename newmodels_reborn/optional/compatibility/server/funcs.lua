-- Backwards compatibility with newmodels 3.3.0
-- Exported functions from old newmodels working with the new system

local resName = getResourceName(resource)

local prevent_addrem_spam = {
    add = {},
    addtimer = nil,
    rem = {},
    remtimer = nil,
}
local SEND_DELAY = 5000

local modList = {
    ped = {},
    vehicle = {},
    object = {},
}

function sendModListAllPlayers()
    for elementType, mods in pairs(modList) do
        for k, mod in pairs(mods) do
            local id = mod.id
            local baseModel = mod.base_id
            local paths = mod.paths
            local customInfo = customModels[id]
            if customInfo then
                customInfo.type = elementType
                customInfo.baseModel = baseModel
                customInfo.col = paths.col or nil
                customInfo.txd = paths.txd or nil
                customInfo.dff = paths.dff or nil
                -- outputDebugString("Updating custom model for ID " .. id .. " with backwards compatible data")
            else
                customModels[id] = {
                    type = elementType,
                    baseModel = baseModel,
                    col = paths.col or nil,
                    txd = paths.txd or nil,
                    dff = paths.dff or nil,
                }
                -- outputDebugString("Adding custom model for ID " .. id .. " with backwards compatible data")
            end
            table.remove(modList[elementType], k)
        end
    end
    triggerClientEvent("newmodels_reborn:receiveCustomModels", resourceRoot, customModels)
end

local function getActualModPaths(folder, id)
    local path = folder

    local lastchar = string.sub(folder, -1)
    if lastchar ~= "/" then
        path = folder .. "/" -- / is missing but I'm nice
    end
    path = path .. id

    return {
        txd = path .. ".txd",
        dff = path .. ".dff",
        col = path .. ".col",
    }
end

function table.copy(tab, recursive)
    local ret = {}
    for key, value in pairs(tab) do
        if (type(value) == "table") and recursive then
            ret[key] = table.copy(value)
        else
            ret[key] = value
        end
    end
    return ret
end

local function fixModList()
    for elementType, mods in pairs(modList) do
        for k, mod in pairs(mods) do
            modList[elementType][k].paths = ((type(mod.path) == "table" and mod.path) or (getActualModPaths(mod.path, mod.id)))
        end
    end
    return true
end

local function verifyOptionalModParameters(modInfo)
    local ignoreTXD = modInfo.ignoreTXD or false
    if (type(ignoreTXD) ~= "boolean") then
        return false, "ignoreTXD passed must be true/false"
    end

    local ignoreDFF = modInfo.ignoreDFF or false
    if (type(ignoreDFF) ~= "boolean") then
        return false, "ignoreDFF passed must be true/false"
    end

    local ignoreCOL = modInfo.ignoreCOL or false
    if (type(ignoreCOL) ~= "boolean") then
        return false, "ignoreCOL passed must be true/false"
    end

    local metaDownloadFalse = modInfo.metaDownloadFalse or false
    if type(metaDownloadFalse) ~= "boolean" then
        return false, "metaDownloadFalse passed must be true/false"
    end

    local disableAutoFree = modInfo.disableAutoFree or false
    if type(disableAutoFree) ~= "boolean" then
        return false, "disableAutoFree passed must be true/false"
    end

    local lodDistance = modInfo.lodDistance or nil
    if (lodDistance ~= nil) and type(lodDistance) ~= "number" then
        return false, "lodDistance passed must be a number"
    end

    local filteringEnabled = modInfo.filteringEnabled or true
    if type(filteringEnabled) ~= "boolean" then
        return false, "filteringEnabled passed must be true/false"
    end

    local alphaTransparency = modInfo.alphaTransparency or false
    if type(alphaTransparency) ~= "boolean" then
        return false, "alphaTransparency passed must be true/false"
    end

    modInfo.ignoreTXD = ignoreTXD
    modInfo.ignoreDFF = ignoreDFF
    modInfo.ignoreCOL = ignoreCOL
    modInfo.metaDownloadFalse = metaDownloadFalse
    modInfo.disableAutoFree = disableAutoFree
    modInfo.lodDistance = lodDistance
    modInfo.filteringEnabled = filteringEnabled
    modInfo.alphaTransparency = alphaTransparency

    return modInfo
end

--[[
	Backwards compatibility for old modInfo tables
]]
function addExternalMods_IDFilenames_Legacy(sourceResName, list)
    outputDebugString(
        "You are passing deprecated modInfo tables to addExternalMods_IDFilenames. Update your code to use the new format.",
        2)
    Async:foreach(list, function(modInfo)
        local elementType, id, base_id, name, path, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, disableAutoFree, lodDistance =
            unpack(modInfo)
        local modInfo2 = {
            elementType = elementType,
            id = id,
            base_id = base_id,
            name = name,
            path = path,
            ignoreTXD = ignoreTXD,
            ignoreDFF = ignoreDFF,
            ignoreCOL = ignoreCOL,
            metaDownloadFalse = metaDownloadFalse,
            disableAutoFree = disableAutoFree,
            lodDistance = lodDistance,
        }
        local worked, reason = addExternalMod_IDFilenames(modInfo2, sourceResName)
        if not worked then
            outputDebugString("addExternalMod_IDFilenames failed: " .. tostring(reason), 1)
        end
    end)
    return true
end

--[[
	This function exists to avoid too many exports calls of the function below from
	external resources to add mods from those
	With this one you can just pass a table of mods and it calls that function for you

	This is an async function: mods in the list will be added gradually and if you have too many it may take several seconds.
	So don't assume that they've all been added immediately after the function returns true.
	Also, please note that if any of your mods has an invalid parameter, an error will be output and it won't get added.
]]
function addExternalMods_IDFilenames(list, onFinishEvent) -- [Exported]
    if not sourceResource then
        return false, "This command is meant to be called from outside resource '" .. resName .. "'"
    end
    local sourceResName = getResourceName(sourceResource)
    if sourceResName == resName then
        return false, "This command is meant to be called from outside resource '" .. resName .. "'"
    end
    if type(list) ~= "table" then
        return false, "Missing/Invalid 'list' table passed: " .. tostring(list)
    end
    if type(list[1]) ~= "table" then
        return false, "Missing/Invalid 'list[1]' table passed: " .. tostring(list[1])
    end
    if tonumber(list[1][2]) then
        -- Backwards compatibility for old modInfo tables
        return addExternalMods_IDFilenames_Legacy(sourceResName, list)
    end
    if not list[1].path then
        return false, "list[1] is missing 'path' key"
    end
    if onFinishEvent ~= nil then
        if type(onFinishEvent) ~= "table" then
            return false,
                "Invalid 'onFinishEvent' passed, example: { source = 'eventSource', name = 'eventName', args = {thePlayer} }"
        end
        if not isElement(onFinishEvent.source) then
            return false, "Invalid 'onFinishEvent.source' passed, expected element"
        end
        if type(onFinishEvent.name) ~= "string" then
            return false, "Invalid 'onFinishEvent.name' passed, expected string"
        end
        if (onFinishEvent.args ~= nil) then
            if type(onFinishEvent.args) ~= "table" then
                return false, "Invalid 'onFinishEvent.args' passed, expected table"
            end
        end
    end
    Async:foreach(list, function(modInfo)
        local worked, reason = addExternalMod_IDFilenames(modInfo, sourceResName)
        if not worked then
            outputDebugString("addExternalMod_IDFilenames failed: " .. tostring(reason), 1)
        end
    end, function()
        if (onFinishEvent) then
            if onFinishEvent.args then
                triggerEvent(onFinishEvent.name, onFinishEvent.source, unpack(onFinishEvent.args))
            else
                triggerEvent(onFinishEvent.name, onFinishEvent.source)
            end
        end
    end)
    return true
end

--[[
	The difference between this function and addExternalMod_CustomFilenames is that
	you pass a folder path in 'path' and it will search for ID.dff ID.txd etc
]]
-- [Exported]
function addExternalMod_IDFilenames(...)
    -- Backwards compatibility for old arguments
    local args = { ... }
    local modInfo
    local fromResourceName
    if type(args[1]) == "string" then
        outputDebugString(
            "You are passing deprecated variables to addExternalMod_IDFilenames. Update your code to use the new format.",
            2)
        --[[
			BEFORE:

			elementType, id, base_id, name, path,
			ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, disableAutoFree, lodDistance,
			fromResourceName
		]]
        modInfo = {
            elementType = args[1],
            id = args[2],
            base_id = args[3],
            name = args[4],
            path = args[5],
            ignoreTXD = args[6],
            ignoreDFF = args[7],
            ignoreCOL = args[8],
            metaDownloadFalse = args[9],
            disableAutoFree = args[10],
            lodDistance = args[11]
        }
        fromResourceName = args[12]
    else
        modInfo = args[1]
        fromResourceName = args[2]
    end

    local sourceResName
    if type(fromResourceName) ~= "string" then
        if (not sourceResource) or (getResourceName(sourceResource) == resName) then
            return false, "This command is meant to be called from outside resource '" .. resName .. "'"
        end
        sourceResName = getResourceName(sourceResource)
    else
        sourceResName = fromResourceName
    end

    local elementType = modInfo.elementType
    if type(elementType) ~= "string" then
        return false, "Missing/Invalid 'elementType' passed: " .. tostring(elementType)
    end
    local sup, reason = isElementTypeSupported(elementType)
    if not sup then
        return false, "Invalid 'elementType' passed: " .. reason
    end
    if elementType == "player" or elementType == "pickup" then
        return false, "'player' or 'pickup' mods have to be added with type 'ped' or 'object' respectively"
    end

    local id = modInfo.id
    if not tonumber(id) then
        return false, "Missing/Invalid 'id' passed: " .. tostring(id)
    end
    id = tonumber(id)

    local base_id = modInfo.base_id
    if not tonumber(base_id) then
        return false, "Missing/Invalid 'base_id' passed: " .. tostring(base_id)
    end
    base_id = tonumber(base_id)

    local name = modInfo.name
    if type(name) ~= "string" then
        return false, "Missing/Invalid 'name' passed: " .. tostring(name)
    end

    local path = modInfo.path
    if type(path) ~= "string" then
        return false, "Missing/Invalid 'path' passed: " .. tostring(path)
    end

    local modInfo2, optionalReason = verifyOptionalModParameters(modInfo)
    if not modInfo2 then
        return false, optionalReason
    end
    modInfo = modInfo2

    if string.sub(path, 1, 1) ~= ":" then
        path = ":" .. sourceResName .. "/" .. path
    end

    if isDefaultID(false, id) then
        return false, "'id' passed is a default GTA:SA ID, needs to be a new one!"
    end

    if not isDefaultID(false, base_id) then
        return false, "'base_id' passed is not a default GTA:SA ID, it needs to be!"
    end

    for _, mods in pairs(modList) do
        for _, mod in pairs(mods) do
            if mod.id == id then
                return false, "Duplicated 'id' passed, already exists in modList"
            end
        end
    end

    local paths = getActualModPaths(path, id)
    for k, path2 in pairs(paths) do
        if (not fileExists(path2)) and ((ENABLE_NANDOCRYPT) and not fileExists(path2 .. NANDOCRYPT_EXT)) then
            if ((not modInfo.ignoreTXD) and k == "txd")
                or ((not modInfo.ignoreDFF) and k == "dff")
                or ((not modInfo.ignoreCOL) and elementType == "object" and k == "col") then
                return false, "File doesn't exist: '" .. tostring(path2) .. "', check folder: '" .. path .. "'"
            end
        end
    end

    -- Save mod in list
    modList[elementType][#modList[elementType] + 1] = {
        id = id,
        base_id = base_id,
        path = path,
        name = name,
        metaDownloadFalse = modInfo.metaDownloadFalse,
        disableAutoFree = modInfo.disableAutoFree,
        lodDistance = modInfo.lodDistance,
        filteringEnabled = modInfo.filteringEnabled,
        alphaTransparency = modInfo.alphaTransparency,
        srcRes = sourceResName
    }

    fixModList()

    -- Don't spam chat/debug when mass adding/removing mods
    if isTimer(prevent_addrem_spam.addtimer) then killTimer(prevent_addrem_spam.addtimer) end

    if not prevent_addrem_spam.add[sourceResName] then prevent_addrem_spam.add[sourceResName] = {} end
    table.insert(prevent_addrem_spam.add[sourceResName], true)

    prevent_addrem_spam.addtimer = setTimer(function()
        for rname, mods in pairs(prevent_addrem_spam.add) do
            outputDebugString("Added " .. #mods .. " mods from " .. rname, 0, 136, 255, 89)
            prevent_addrem_spam.add[rname] = nil
            sendModListAllPlayers()
        end
    end, SEND_DELAY, 1)

    return true
end

--[[
	Backwards compatibility for old modInfo tables
]]
function addExternalMods_CustomFileNames_Legacy(sourceResName, list)
    outputDebugString(
        "You are passing deprecated modInfo tables to addExternalMods_CustomFileNames. Update your code to use the new format.",
        2)
    Async:foreach(list, function(modInfo)
        local elementType, id, base_id, name, path_dff, path_txd, path_col, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, disableAutoFree, lodDistance =
            unpack(modInfo)
        local modInfo2 = {
            elementType = elementType,
            id = id,
            base_id = base_id,
            name = name,
            path_dff = path_dff,
            path_txd = path_txd,
            path_col = path_col,
            ignoreTXD = ignoreTXD,
            ignoreDFF = ignoreDFF,
            ignoreCOL = ignoreCOL,
            metaDownloadFalse = metaDownloadFalse,
            disableAutoFree = disableAutoFree,
            lodDistance = lodDistance
        }
        local worked, reason = addExternalMod_CustomFilenames(modInfo2, sourceResName)
        if not worked then
            outputDebugString("addExternalMods_CustomFileNames failed: " .. tostring(reason), 1)
        end
    end)
    return true
end

--[[
	This function exists to avoid too many exports calls of the function below from
	external resources to add mods from those
	With this one you can just pass a table of mods and it calls that function for you

	This is an async function: mods in the list will be added gradually and if you have too many it may take several seconds.
	So don't assume that they've all been added immediately after the function returns true.
	Also, please note that if any of your mods has an invalid parameter, an error will be output and it won't get added.
]]
function addExternalMods_CustomFileNames(list, onFinishEvent) -- [Exported]
    if not sourceResource then
        return false, "This command is meant to be called from outside resource '" .. resName .. "'"
    end
    local sourceResName = getResourceName(sourceResource)
    if sourceResName == resName then
        return false, "This command is meant to be called from outside resource '" .. resName .. "'"
    end
    if type(list) ~= "table" then
        return false, "Missing/Invalid 'list' table passed: " .. tostring(list)
    end
    if type(list[1]) ~= "table" then
        return false, "Missing/Invalid 'list[1]' table passed: " .. tostring(list[1])
    end
    if tonumber(list[1][2]) then
        -- Backwards compatibility for old modInfo tables
        return addExternalMods_CustomFileNames_Legacy(sourceResName, list)
    end
    if list[1].path then
        return false, "list[1] has 'path' key, this can only be used in addExternalMods_IDFilenames"
    end
    if onFinishEvent ~= nil then
        if type(onFinishEvent) ~= "table" then
            return false,
                "Invalid 'onFinishEvent' passed, example: { source = 'eventSource', name = 'eventName', args = {thePlayer} }"
        end
        if not isElement(onFinishEvent.source) then
            return false, "Invalid 'onFinishEvent.source' passed, expected element"
        end
        if type(onFinishEvent.name) ~= "string" then
            return false, "Invalid 'onFinishEvent.name' passed, expected string"
        end
        if (onFinishEvent.args ~= nil) then
            if type(onFinishEvent.args) ~= "table" then
                return false, "Invalid 'onFinishEvent.args' passed, expected table"
            end
        end
    end
    Async:foreach(list, function(modInfo)
        local worked, reason = addExternalMod_CustomFilenames(modInfo, sourceResName)
        if not worked then
            outputDebugString("addExternalMods_CustomFileNames failed: " .. tostring(reason), 1)
        end
    end, function()
        if (onFinishEvent) then
            if onFinishEvent.args then
                triggerEvent(onFinishEvent.name, onFinishEvent.source, unpack(onFinishEvent.args))
            else
                triggerEvent(onFinishEvent.name, onFinishEvent.source)
            end
        end
    end)
    return true
end

--[[
	The difference between this function and addExternalMod_IDFilenames is that
	you pass directly individual file paths for dff, txd and col files
]]
-- [Exported]
function addExternalMod_CustomFilenames(...)
    -- Backwards compatibility for old arguments
    local args = { ... }
    local modInfo
    local fromResourceName
    if type(args[1]) == "string" then
        outputDebugString(
            "You are passing deprecated variables to addExternalMod_CustomFilenames. Update your code to use the new format.",
            2)
        --[[
			BEFORE:

			elementType, id, base_id, name, path_dff, path_txd, path_col,
			ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, disableAutoFree, lodDistance,
			fromResourceName
		]]
        modInfo = {
            elementType = args[1],
            id = args[2],
            base_id = args[3],
            name = args[4],
            path_dff = args[5],
            path_txd = args[6],
            path_col = args[7],
            ignoreTXD = args[8],
            ignoreDFF = args[9],
            ignoreCOL = args[10],
            metaDownloadFalse = args[11],
            disableAutoFree = args[12],
            lodDistance = args[13]
        }
        fromResourceName = args[14]
    else
        modInfo = args[1]
        fromResourceName = args[2]
    end

    if type(modInfo) ~= "table" then
        return false, "Missing/Invalid 'modInfo' table passed: " .. tostring(modInfo)
    end

    local sourceResName
    if type(fromResourceName) ~= "string" then
        if (not sourceResource) or (getResourceName(sourceResource) == resName) then
            return false, "This command is meant to be called from outside resource '" .. resName .. "'"
        end
        sourceResName = getResourceName(sourceResource)
    else
        sourceResName = fromResourceName
    end

    local elementType = modInfo.elementType
    if type(elementType) ~= "string" then
        return false, "Missing/Invalid 'elementType' passed: " .. tostring(elementType)
    end
    local sup, reason = isElementTypeSupported(elementType)
    if not sup then
        return false, "Invalid 'elementType' passed: " .. reason
    end
    if elementType == "player" or elementType == "pickup" then
        return false, "'player' or 'pickup' mods have to be added with type 'ped' or 'object' respectively"
    end

    local id = modInfo.id
    if not tonumber(id) then
        return false, "Missing/Invalid 'id' passed: " .. tostring(id)
    end
    id = tonumber(id)

    local base_id = modInfo.base_id
    if not tonumber(base_id) then
        return false, "Missing/Invalid 'base_id' passed: " .. tostring(base_id)
    end
    base_id = tonumber(base_id)

    local name = modInfo.name
    if type(name) ~= "string" then
        return false, "Missing/Invalid 'name' passed: " .. tostring(name)
    end

    local modInfo2, optionalReason = verifyOptionalModParameters(modInfo)
    if not modInfo2 then
        return false, optionalReason
    end
    modInfo = modInfo2

    local paths = {}

    if (modInfo.ignoreDFF == false) then
        local path_dff = modInfo.path_dff or modInfo.dff
        if type(path_dff) ~= "string" then
            return false, "Missing/Invalid 'path_dff' passed: " .. tostring(path_dff)
        end
        if string.sub(path_dff, 1, 1) ~= ":" then
            path_dff = ":" .. sourceResName .. "/" .. path_dff
        end
        paths.dff = path_dff
    end

    if (modInfo.ignoreTXD == false) then
        local path_txd = modInfo.path_txd or modInfo.txd
        if type(path_txd) ~= "string" then
            return false, "Missing/Invalid 'path_txd' passed: " .. tostring(path_txd)
        end
        if string.sub(path_txd, 1, 1) ~= ":" then
            path_txd = ":" .. sourceResName .. "/" .. path_txd
        end
        paths.txd = path_txd
    end

    if (modInfo.ignoreCOL == false and elementType == "object") then
        local path_col = modInfo.path_col or modInfo.col
        if type(path_col) ~= "string" then
            return false, "Missing/Invalid 'path_col' passed: " .. tostring(path_col)
        end
        if string.sub(path_col, 1, 1) ~= ":" then
            path_col = ":" .. sourceResName .. "/" .. path_col
        end

        paths.col = path_col
    end

    if isDefaultID(false, id) then
        return false, "'id' passed is a default GTA:SA ID, needs to be a new one!"
    end

    if not isDefaultID(false, base_id) then
        return false, "'base_id' passed is not a default GTA:SA ID, it needs to be!"
    end

    for elementType2, mods in pairs(modList) do
        for k, mod in pairs(mods) do
            if mod.id == id then
                return false, "Duplicated 'id' passed, already exists in modList"
            end
        end
    end
    for k, path2 in pairs(paths) do
        if (not fileExists(path2)) and ((ENABLE_NANDOCRYPT) and not fileExists(path2 .. NANDOCRYPT_EXT)) then
            if ((not modInfo.ignoreTXD) and k == "txd")
                or ((not modInfo.ignoreDFF) and k == "dff")
                or ((not modInfo.ignoreCOL) and elementType == "object" and k == "col") then
                return false, "File doesn't exist: '" .. tostring(path2) .. "'"
            end
        end
    end

    -- Save mod in list
    modList[elementType][#modList[elementType] + 1] = {
        id = id,
        base_id = base_id,
        path = paths,
        name = name,
        metaDownloadFalse = modInfo.metaDownloadFalse,
        disableAutoFree = modInfo.disableAutoFree,
        lodDistance = modInfo.lodDistance,
        filteringEnabled = modInfo.filteringEnabled,
        alphaTransparency = modInfo.alphaTransparency,
        srcRes = sourceResName
    }

    fixModList()

    -- Don't spam chat/debug when mass adding/removing mods
    if isTimer(prevent_addrem_spam.addtimer) then killTimer(prevent_addrem_spam.addtimer) end

    if not prevent_addrem_spam.add[sourceResName] then prevent_addrem_spam.add[sourceResName] = {} end
    table.insert(prevent_addrem_spam.add[sourceResName], true)

    prevent_addrem_spam.addtimer = setTimer(function()
        for rname, mods in pairs(prevent_addrem_spam.add) do
            outputDebugString("Added " .. #mods .. " mods from " .. rname, 0, 136, 255, 89)
            prevent_addrem_spam.add[rname] = nil
            sendModListAllPlayers()
        end
    end, SEND_DELAY, 1)
    return true
end

--[[
	This is an async function: mods in the list of IDs will be removed gradually and if you have too many it may take several seconds.
	So don't assume that they've all been removed immediately after the function returns true.
]]
function removeExternalMods(list, onFinishEvent) -- [Exported]
    if not sourceResource then
        return false, "This command is meant to be called from outside resource '" .. resName .. "'"
    end
    local sourceResName = getResourceName(sourceResource)
    if sourceResName == resName then
        return false, "This command is meant to be called from outside resource '" .. resName .. "'"
    end
    if type(list) ~= "table" then
        return false, "Missing/Invalid 'list' table passed: " .. tostring(list)
    end
    if type(list[1]) ~= "number" then
        return false, "list[1] is not a number: " .. tostring(list[1])
    end
    if onFinishEvent ~= nil then
        if type(onFinishEvent) ~= "table" then
            return false,
                "Invalid 'onFinishEvent' passed, example: { source = 'eventSource', name = 'eventName', args = {thePlayer} }"
        end
        if not isElement(onFinishEvent.source) then
            return false, "Invalid 'onFinishEvent.source' passed, expected element"
        end
        if type(onFinishEvent.name) ~= "string" then
            return false, "Invalid 'onFinishEvent.name' passed, expected string"
        end
        if (onFinishEvent.args ~= nil) then
            if type(onFinishEvent.args) ~= "table" then
                return false, "Invalid 'onFinishEvent.args' passed, expected table"
            end
        end
    end
    Async:foreach(list, function(id)
        local worked, reason = removeExternalMod(id)
        if not worked then
            outputDebugString("removeExternalMod(" .. tostring(id) .. ") failed: " .. tostring(reason), 1)
        end
    end, function()
        if (onFinishEvent) then
            if onFinishEvent.args then
                triggerEvent(onFinishEvent.name, onFinishEvent.source, unpack(onFinishEvent.args))
            else
                triggerEvent(onFinishEvent.name, onFinishEvent.source)
            end
        end
    end)
    return true
end

function removeExternalMod(id) -- [Exported]
    if not tonumber(id) then
        return false, "Missing/Invalid 'id' passed: " .. tostring(id)
    end
    id = tonumber(id)

    for elementType, mods in pairs(modList) do
        for k, mod in pairs(mods) do
            if mod.id == id then
                local sourceResName = mod.srcRes
                if sourceResName then
                    table.remove(modList[elementType], k)
                    fixModList()

                    -- Don't spam chat/debug when mass adding/removing mods
                    if isTimer(prevent_addrem_spam.remtimer) then killTimer(prevent_addrem_spam.remtimer) end

                    if not prevent_addrem_spam.rem[sourceResName] then prevent_addrem_spam.rem[sourceResName] = {} end
                    table.insert(prevent_addrem_spam.rem[sourceResName], true)

                    prevent_addrem_spam.remtimer = setTimer(function()
                        for rname, mods2 in pairs(prevent_addrem_spam.rem) do
                            outputDebugString("Removed " .. #mods2 .. " mods from " .. rname, 0, 211, 255, 89)
                            prevent_addrem_spam.rem[rname] = nil
                            sendModListAllPlayers()
                        end
                    end, SEND_DELAY, 1)

                    return true
                else
                    return false, "Mod with ID " .. id .. " doesn't have a source resource"
                end
            end
        end
    end

    return false, "No mod with ID " .. id .. " found in modList"
end

addEventHandler("onResourceStop", root, function(stoppedResource, wasDeleted)
    if stoppedResource == resource then return end
    local stoppedResName = getResourceName(stoppedResource)
    local delCount = 0
    for elementType, mods in pairs(modList) do
        for k, mod in pairs(mods) do
            local srcRes = mod.srcRes
            if srcRes and stoppedResName == srcRes then
                -- delete mod added by resource that was just stopped
                table.remove(modList[elementType], k)
                delCount = delCount + 1
            end
        end
    end

    if delCount > 0 then
        outputDebugString("Removed " .. delCount .. " mods because resource '" .. stoppedResName .. "' stopped", 0,
            211, 255, 89)
        fixModList()
        sendModListAllPlayers()
    end
end)

addCommandHandler(string.lower(resName), function(thePlayer)
    local version = getResourceInfo(resource, "version") or false
    local name = getResourceInfo(resource, "name") or false
    outputChatBox(
        (name and "#ffc175[" .. name .. "] " or "") ..
        "#ffffff" .. resName .. (version and (" " .. version) or ("")) .. " #ffc175is loaded", thePlayer, 255, 255, 255,
        true)
end, false, false)
