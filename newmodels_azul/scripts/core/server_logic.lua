-- Loading of custom models from the "models" directory.

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
        elseif stringStartswith(settingStr, "settings=") then
            if isFromSettingsOption then -- prevent inception and recursion
                return false, "settings option cannot point to a settings file that contains another settings option @ " .. thisFullPath
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
            for _, settingModelType in pairs({"txd", "dff", "col"}) do
                if stringStartswith(settingStr, settingModelType.."=") then
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
    local baseModelCounts = {}
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
                                    local parsed, failReason = parseOneFile(customModelInfo, fileOrFolderInsideThis, fullPathInsideThis, fileOrFolderInside)
                                    if not parsed then
                                        return false, failReason
                                    end
                                end
                            elseif pathIsFile(fullPathInside) then
                                local parsed, failReason = parseOneFile(customModelInfo, fileOrFolderInside, fullPathInside)
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
    outputServerLog("[loadModels] " .. failReason)
    outputDebugString("Failed to load models. See server log for details.", 1)
    return
end

-- Save elementModels in root element data to restore on next startup
addEventHandler("onResourceStop", resourceRoot, function()
    if next(elementModels) then
        setElementData(root, "newmodels_azul:elementModels_backup", elementModels, false)
    end
end, false)

-- Restore elementModels from root element data on startup if any
local elementModelsBackup = getElementData(root, "newmodels_azul:elementModels_backup")
if type(elementModelsBackup) == "table" then
    for element, id in pairs(elementModelsBackup) do
        if isElement(element) then
            elementModels[element] = id
        end
    end
end


addEventHandler("onPlayerResourceStart", root, function(res)
    if res == resource then
        triggerClientEvent(source, "newmodels_azul:receiveCustomModels", resourceRoot, customModels, elementModels)
    end
end)

-- Handle element destroy (clear any custom model ID from the table)
-- Syncing with clients is not necessary as they already handle onClientElementDestroy
addEventHandler("onElementDestroy", root, function()
    if elementModels[source] then
        elementModels[source] = nil
    end
end)
