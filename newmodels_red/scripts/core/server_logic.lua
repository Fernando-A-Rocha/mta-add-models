-- Loading of custom models from the "models" directory.

local baseModelCounts = {}

local RESOURCE_NAME = getResourceName(resource)
local function srvLog(str)
    outputServerLog("[" .. RESOURCE_NAME .. "] " .. str)
end

local VALID_MODEL_TYPES = { "vehicle", "object", "ped" }

-- Model .txt settings:
local CUSTOM_MODEL_BOOL_SETTINGS = {
    ["disableAutoFree"] = true,
    ["disableTXDTextureFiltering"] = true,
    ["enableDFFAlphaTransparency"] = true,
}
--   - txd=path
--   - dff=path
--   - col=path
--   - lodDistance=number
--   - settings=path

local function stringStartswith(str, start)
    return str:sub(1, #start) == start
end

local function parseModelSettings(customModel, customModelInfo, thisFullPath, isFromSettingsOption)
    local customModelSettings = {}
    local file = fileOpen(thisFullPath, true)
    if not file then
        return false, "failed to open file: " .. thisFullPath
    end
    local info = fileGetContents(file, false)
    fileClose(file)
    if not info then
        return false, "failed to read file: " .. thisFullPath
    end
    local lines = split(info, "\n")
    for _, settingStr in pairs(lines) do
        settingStr = settingStr:gsub("\r", "")
        if CUSTOM_MODEL_BOOL_SETTINGS[settingStr] then
            customModelSettings[settingStr] = true
        elseif stringStartswith(settingStr, "lodDistance=") then
            local lodDistance = tonumber(settingStr:sub(13))
            if not lodDistance then
                return false, "invalid lodDistance value: " .. settingStr
            end
            customModelSettings.lodDistance = lodDistance
        elseif stringStartswith(settingStr, "physicalPropsGroup=") then
            local physicalPropsGroup = tonumber(settingStr:sub(20))
            if not physicalPropsGroup then
                return false, "invalid physicalPropsGroup value: " .. settingStr
            end
            customModelSettings.physicalPropsGroup = physicalPropsGroup
        elseif stringStartswith(settingStr, "settings=") then
            if isFromSettingsOption then -- prevent inception and recursion
                return false,
                    "settings option cannot point to a settings file that contains another settings option @ " ..
                    thisFullPath
            end
            local settingsPath = settingStr:sub(10)
            local settingsFullPath = "models/" .. settingsPath
            if not fileExists(settingsFullPath) then
                return false, "settings file not found: " .. settingsPath
            end
            local settingsInfo = parseModelSettings(customModel, customModelInfo, settingsFullPath, true)
            if not settingsInfo then
                return false, "failed to parse settings file: " .. settingsPath
            end
            return settingsInfo
        else
            for _, settingModelType in pairs({ "txd", "dff", "col" }) do
                if stringStartswith(settingStr, settingModelType .. "=") then
                    local settingModelPath = settingStr:sub(#settingModelType + 2)
                    local settingModelFullPath = "models/" .. settingModelPath
                    if not fileExists(settingModelFullPath) then
                        return false, "setting " .. settingModelType .. " file not found: " .. settingModelPath
                    end
                    if customModelInfo[customModel][settingModelType] then
                        return false, "duplicate " .. settingModelType .. " file for custom model: " .. customModel
                    end
                    customModelInfo[customModel][settingModelType] = settingModelFullPath
                end
            end
        end
    end
    return customModelSettings
end

local function parseOneFile(customModelInfo, thisFileName, thisFullPath, name)
    local isNandoCrypted, fileExt, customModel = isNandoCryptFileName(thisFileName)
    if not isNandoCrypted then
        fileExt = string.sub(thisFileName, -3)
        customModel = tonumber(string.sub(thisFileName, 1, -5))
    end
    if (fileExt == "dff" or fileExt == "txd" or fileExt == "col" or fileExt == "txt") and customModel then
        if not customModelInfo[customModel] then
            if isDefaultID(false, customModel) then
                return false, "custom model is a default ID: " .. customModel
            end
            if customModels[customModel] then
                return false, "duplicate custom model: " .. customModel
            end
            customModelInfo[customModel] = {}
        end
        if fileExt == "txt" then
            local customModelSettings, failReason = parseModelSettings(customModel, customModelInfo, thisFullPath)
            if not customModelSettings then
                return false, failReason
            end
            customModelInfo[customModel].settings = customModelSettings
        else
            if customModelInfo[customModel][fileExt] then
                return false, "duplicate " .. fileExt .. " file for custom model: " .. customModel
            end
            customModelInfo[customModel][fileExt] = thisFullPath
            if name then
                customModelInfo[customModel].name = name
            end
        end
    end
    return true
end

local function loadModels()
    if not pathIsDirectory("models") then
        return false, "models directory not found"
    end
    local filesAndFolders = pathListDir("models")
    if not filesAndFolders then
        return false, "failed to list models directory"
    end
    for _, modelType in pairs(VALID_MODEL_TYPES) do
        local modelTypePath = "models/" .. modelType
        if pathIsDirectory(modelTypePath) then
            local filesAndFoldersHere = pathListDir(modelTypePath)
            if not filesAndFoldersHere then
                return false, "failed to list " .. modelTypePath .. " directory"
            end
            for _, fileOrFolder in pairs(filesAndFoldersHere) do
                local fullPath = modelTypePath .. "/" .. fileOrFolder
                if pathIsDirectory(fullPath) then
                    local baseModel = tonumber(fileOrFolder)
                    if baseModel then
                        if not isDefaultID(false, baseModel) then
                            return false, "invalid " .. modelType .. " base model: " .. baseModel
                        end
                        local filesAndFoldersInside = pathListDir(fullPath)
                        if not filesAndFoldersInside then
                            return false, "failed to list " .. fullPath .. " directory"
                        end
                        local customModelInfo = {}
                        for _, fileOrFolderInside in pairs(filesAndFoldersInside) do
                            local fullPathInside = fullPath .. "/" .. fileOrFolderInside
                            if pathIsDirectory(fullPathInside) then
                                local filesAndFoldersInsideThis = pathListDir(fullPathInside)
                                if not filesAndFoldersInsideThis then
                                    return false, "failed to list " .. fullPathInside .. " directory"
                                end
                                for _, fileOrFolderInsideThis in pairs(filesAndFoldersInsideThis) do
                                    local fullPathInsideThis = fullPathInside .. "/" .. fileOrFolderInsideThis
                                    local parsed, failReason = parseOneFile(customModelInfo, fileOrFolderInsideThis,
                                        fullPathInsideThis, fileOrFolderInside)
                                    if not parsed then
                                        return false, failReason
                                    end
                                end
                            elseif pathIsFile(fullPathInside) then
                                local parsed, failReason = parseOneFile(customModelInfo, fileOrFolderInside,
                                    fullPathInside)
                                if not parsed then
                                    return false, failReason
                                end
                            end
                        end
                        for customModel, info in pairs(customModelInfo) do
                            if not info.name then
                                baseModelCounts[baseModel] = (baseModelCounts[baseModel] or 0) + 1
                            end
                            customModels[customModel] = {
                                type = modelType,
                                baseModel = baseModel,
                                dff = info.dff,
                                txd = info.txd,
                                col = info.col,
                                name = info.name or ("%d#%d"):format(baseModel, baseModelCounts[baseModel]),
                                settings = info.settings or {},
                            }
                        end
                    end
                end
            end
        end
    end
    return true
end

local result, failReason = loadModels()
if not result then
    srvLog("[loadModels] " .. failReason)
    outputDebugString("Failed to load models. See server log for details.", 1)
    return
end

local function parseModListEntry(modelType, modInfo)
    if (type(modInfo.id) ~= "number") or (type(modInfo.base_id) ~= "number") or (not modInfo.path) then
        return false,
            "Invalid modInfo entry (missing/wrong type for id, base_id, or path) in modList for model type: " ..
            modelType
    end

    local customModel = modInfo.id
    if isDefaultID(false, customModel) then
        return false, "custom model is a default ID: " .. customModel
    end
    if customModels[customModel] then
        return false, "duplicate custom model: " .. customModel
    end

    local baseModel = modInfo.base_id
    if not isDefaultID(false, baseModel) then
        return false, "invalid " .. modelType .. " base model: " .. baseModel
    end

    local dff_path, txd_path, col_path
    local settings = {}
    local ignoreDFF, ignoreTXD, ignoreCOL = modInfo.ignoreDFF, modInfo.ignoreTXD, modInfo.ignoreCOL

    if modelType ~= "object" then
        ignoreCOL = true -- COL not used for peds & vehicles
    end

    if type(modInfo.path) == "string" then
        local folder = modInfo.path

        if not ignoreDFF then
            dff_path = folder .. customModel .. ".dff"
        end
        if not ignoreTXD then
            txd_path = folder .. customModel .. ".txd"
        end
        if not ignoreCOL then
            col_path = folder .. customModel .. ".col"
        end
    elseif type(modInfo.path) == "table" then
        if not ignoreDFF and modInfo.path["dff"] then
            dff_path = modInfo.path["dff"]
        end
        if not ignoreTXD and modInfo.path["txd"] then
            txd_path = modInfo.path["txd"]
        end
        if not ignoreCOL and modInfo.path["col"] then
            col_path = modInfo.path["col"]
        end
    else
        -- Invalid path type
        return false, "Invalid path type for custom model ID: " .. customModel
    end

    -- Optional: Update baseModelCounts if no name is provided
    local modName = modInfo.name
    if not modName then
        baseModelCounts[baseModel] = (baseModelCounts[baseModel] or 0) + 1
        modName = string.format("%d#%d", baseModel, baseModelCounts[baseModel])
    end

    -- Apply optional settings
    if type(modInfo.lodDistance) == "number" then
        settings["lodDistance"] = modInfo.lodDistance
    end
    if modInfo.disableAutoFree then
        settings["disableAutoFree"] = true
    end
    if not modInfo.filteringEnabled then
        settings["disableTXDTextureFiltering"] = true
    end
    if modInfo.alphaTransparency then
        settings["enableDFFAlphaTransparency"] = true
    end
    -- Note: 'metaDownloadFalse' handling is omitted as per original code comment

    local ncExt = getNandoCryptExtension()

    -- DFF check
    if dff_path then
        if not fileExists(dff_path) then
            if fileExists(dff_path .. ncExt) then
                dff_path = dff_path .. ncExt
            else
                return false, "DFF file not found for custom model ID " .. customModel .. ": " .. dff_path
            end
        end
    end

    -- TXD check
    if txd_path then
        if not fileExists(txd_path) then
            if fileExists(txd_path .. ncExt) then
                txd_path = txd_path .. ncExt
            else
                return false, "TXD file not found for custom model ID " .. customModel .. ": " .. txd_path
            end
        end
    end

    -- COL check
    if col_path then
        if not fileExists(col_path) then
            if fileExists(col_path .. ncExt) then
                col_path = col_path .. ncExt
            else
                return false, "COL file not found for custom model ID " .. customModel .. ": " .. col_path
            end
        end
    end

    return {
        customModel = customModel,
        modelType = modelType,
        baseModel = baseModel,
        dff_path = dff_path,
        txd_path = txd_path,
        col_path = col_path,
        modName = modName,
        settings = settings,
    }
end
local function loadModelsViaModList()
    if type(modList) ~= "table" then
        return false, "modList is not a table"
    end

    local countLoaded = 0
    local validModelTypes = { ped = true, vehicle = true, object = true }

    -- Iterate over each model type (ped, vehicle, object) in modList
    for modelType, modelList in pairs(modList) do
        if not validModelTypes[modelType] or type(modelList) ~= "table" then
            return false, "Invalid model type or model list in modList: Index " .. tostring(modelType)
        end

        -- Iterate over each individual model entry in the list
        for _, modInfo in ipairs(modelList) do
            if type(modInfo) ~= "table" then
                return false, "Found a modInfo entry that is not a table in modList for model type: " .. modelType
            end
            local parsedInfo, parsingFailReason = parseModListEntry(modelType, modInfo)
            if not parsedInfo then
                return false, parsingFailReason
            end
            customModels[parsedInfo.customModel] = {
                type = modelType,
                baseModel = parsedInfo.baseModel,
                dff = parsedInfo.dff_path or nil,
                txd = parsedInfo.txd_path or nil,
                col = parsedInfo.col_path or nil,
                name = parsedInfo.modName,
                settings = parsedInfo.settings,
            }
            countLoaded = countLoaded + 1
        end
    end

    srvLog("Loaded " .. countLoaded .. " models via modList.")
    return true
end
local result2, failReason2 = loadModelsViaModList()
if result2 == false then
    srvLog("[loadModelsViaModList] " .. failReason2)
    outputDebugString("Failed to load models via modList. See server log for details.", 1)
    return
end

-- Save elementModels in root element data to restore on next startup
addEventHandler("onResourceStop", resourceRoot, function()
    if next(elementModels) then
        setElementData(root, "newmodels_red:elementModels_backup", elementModels, false)
    end
end, false)

-- Restore elementModels from root element data on startup if any
local elementModelsBackup = getElementData(root, "newmodels_red:elementModels_backup")
if type(elementModelsBackup) == "table" then
    for element, id in pairs(elementModelsBackup) do
        if isElement(element) then
            elementModels[element] = id
        end
    end
end

local function sendCustomModelsToPlayer(player)
    triggerClientEvent(player, "newmodels_red:receiveCustomModels", resourceRoot, customModels, elementModels)
end

addEventHandler("onPlayerResourceStart", root, function(res)
    if res == resource then
        sendCustomModelsToPlayer(source)
    end
end)

-- Handle element destroy (clear any custom model ID from the table)
-- Syncing with clients is not necessary as they already handle onClientElementDestroy
addEventHandler("onElementDestroy", root, function()
    if elementModels[source] then
        elementModels[source] = nil
    end
end)

--
-- The following 2 add & remove functions were inspired by their newmodels v3 versions.
--

function addExternalModels(listToAdd)
    if type(listToAdd) ~= "table" then
        return false, "invalid arg 1: not a table"
    end
    local countLoaded = 0
    for _, modInfo in pairs(listToAdd) do
        if type(modInfo) ~= "table" then
            return false, "Found a modInfo entry that is not a table in listToAdd"
        end
        local modelType = modInfo.type
        if not (modelType == "ped" or modelType == "vehicle" or modelType == "object") then
            return false, "Invalid or missing model type in modInfo entry in listToAdd"
        end
        local parsedInfo, parsingFailReason = parseModListEntry(modelType, modInfo)
        if not parsedInfo then
            return false, parsingFailReason
        end
        customModels[parsedInfo.customModel] = {
            type = parsedInfo.modelType,
            baseModel = parsedInfo.baseModel,
            dff = parsedInfo.dff_path or nil,
            txd = parsedInfo.txd_path or nil,
            col = parsedInfo.col_path or nil,
            name = parsedInfo.modName,
            settings = parsedInfo.settings,
        }
        countLoaded = countLoaded + 1
    end

    srvLog("Added " .. countLoaded .. " external models via addExternalModels.")
    srvLog("Sending new customModels to online players...")
    for _, player in pairs(getElementsByType("player")) do
        sendCustomModelsToPlayer(player)
    end
    return true
end

function removeExternalModels(listToRemove)
    if type(listToRemove) ~= "table" then
        return false, "invalid arg 1: not a table"
    end
    local countRemoved = 0
    for _, customModel in pairs(listToRemove) do
        if type(customModel) ~= "number" then
            return false, "Found a custom model ID that is not a number in listToRemove"
        end
        if customModels[customModel] then
            customModels[customModel] = nil
            countRemoved = countRemoved + 1
        end
    end

    srvLog("Removed " .. countRemoved .. " external models via removeExternalModels.")
    srvLog("Sending new customModels to online players...")
    for _, player in pairs(getElementsByType("player")) do
        sendCustomModelsToPlayer(player)
    end
    return true
end
