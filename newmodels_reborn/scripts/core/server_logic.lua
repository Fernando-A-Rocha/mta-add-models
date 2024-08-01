-- Apologies for the excess if statements, I'll clean this up later.

-- Model .txt settings:
local CUSTOM_MODEL_SETTINGS = {
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

local function parseModelSettings(thisFullPath, customModel, customModelInfo, isFromSettingsOption)
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
        if CUSTOM_MODEL_SETTINGS[settingStr] then
            customModelSettings[settingStr] = true
        elseif stringStartswith(settingStr, "lodDistance=") then
            local lodDistance = tonumber(settingStr:sub(13))
            if not lodDistance then
                return false, "invalid lodDistance value: " .. settingStr
            end
            customModelSettings.lodDistance = lodDistance
        elseif stringStartswith(settingStr, "settings=") then
            if isFromSettingsOption then
                return false, "settings option cannot point to a settings file that contains another settings option @ " .. thisFullPath
            end
            local settingsPath = settingStr:sub(10)
            local settingsFullPath = "models/" .. settingsPath
            if not fileExists(settingsFullPath) then
                return false, "settings file not found: " .. settingsPath
            end
            local settingsInfo = parseModelSettings(settingsFullPath, customModel, customModelInfo, true)
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

local function loadModels()
    if not pathIsDirectory("models") then
        return false, "models directory not found"
    end
    local filesAndFolders = pathListDir("models")
    if not filesAndFolders then
        return false, "failed to list models directory"
    end
    for _, modelType in pairs({"vehicle", "object", "ped"}) do
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
                        if not isDefaultID(modelType, baseModel) then
                            return false, "invalid " .. modelType .. " base model: " .. baseModel
                        end
                        local filesAndFoldersInside = pathListDir(fullPath)
                        if not filesAndFoldersInside then
                            return false, "failed to list " .. fullPath .. " directory"
                        end
                        local customModelInfo = {}
                        local function parseOneFile(thisFileName, thisFullPath, name)
                            local fileType = string.sub(thisFileName, -3)
                            if (fileType == "dff" or fileType == "txd" or fileType == "col" or fileType == "txt") then
                                local customModel = tonumber(string.sub(thisFileName, 1, -5))
                                if customModel then
                                    if not customModelInfo[customModel] then
                                        if isDefaultID(modelType, customModel) then
                                            return false, "custom " .. modelType .. " model is a default ID: " .. customModel
                                        end
                                        if customModels[customModel] then
                                            return false, "duplicate " .. modelType .. " custom model: " .. customModel
                                        end
                                        customModelInfo[customModel] = {}
                                    end
                                    if fileType == "txt" then
                                        local customModelSettings, failReason = parseModelSettings(thisFullPath, customModel, customModelInfo)
                                        if not customModelSettings then
                                            return false, failReason
                                        end
                                        customModelInfo[customModel].settings = customModelSettings
                                    else
                                        if customModelInfo[customModel][fileType] then
                                            return false, "duplicate " .. fileType .. " file for custom " .. modelType .. " model: " .. customModel
                                        end
                                        customModelInfo[customModel][fileType] = thisFullPath
                                        if name then
                                            customModelInfo[customModel].name = name
                                        end
                                    end
                                end
                            end
                            return true
                        end
                        for _, fileOrFolderInside in pairs(filesAndFoldersInside) do
                            local fullPathInside = fullPath .. "/" .. fileOrFolderInside
                            if pathIsDirectory(fullPathInside) then
                                local filesAndFoldersInsideThis = pathListDir(fullPathInside)
                                if not filesAndFoldersInsideThis then
                                    return false, "failed to list " .. fullPathInside .. " directory"
                                end
                                for _, fileOrFolderInsideThis in pairs(filesAndFoldersInsideThis) do
                                    local fullPathInsideThis = fullPathInside .. "/" .. fileOrFolderInsideThis
                                    local parsed, failReason = parseOneFile(fileOrFolderInsideThis, fullPathInsideThis, fileOrFolderInside)
                                    if not parsed then
                                        return false, failReason
                                    end
                                end
                            elseif pathIsFile(fullPathInside) then
                                local parsed, failReason = parseOneFile(fileOrFolderInside, fullPathInside)
                                if not parsed then
                                    return false, failReason
                                end
                            end
                        end
                        for customModel, info in pairs(customModelInfo) do
                            customModels[customModel] = {
                                type = modelType,
                                baseModel = baseModel,
                                dff = info.dff,
                                txd = info.txd,
                                col = info.col,
                                name = info.name or "Unnamed",
                                settings = info.settings or {},
                            }
                            if modelType == "object" then iprint(customModel, customModels[customModel]) end
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

addEventHandler("onPlayerResourceStart", root, function(res)
    if res == resource then
        triggerClientEvent(source, "newmodels_reborn:receiveCustomModels", resourceRoot, customModels)
    end
end)
