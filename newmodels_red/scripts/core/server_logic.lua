-- Server-side logic for adding new models
local RESOURCE_NAME = getResourceName(resource)
local AUTO_MODELS_FOLDER = "models"
local VALID_MODEL_TYPES = { "vehicle", "object", "ped" }

local baseModelCounts = {}

-- Async:setDebug(true);
Async:setPriority("low");

local function srvLog(str)
    outputServerLog("[" .. RESOURCE_NAME .. "] " .. str)
end

local function stringStartswith(str, start)
    return str:sub(1, #start) == start
end

-- .................................................................
-- ...... Load new models automatically from folder structure ......
-- .................................................................

-- Model settings (from .txt files overriding defaults):
local DECLARATIVE_SETTINGS = { "disableAutoFree", "disableTXDTextureFiltering", "enableDFFAlphaTransparency",
    "loadRawData" }
--   - txd=path
--   - dff=path
--   - col=path
--   - lodDistance=number
--   - settings=path

local function parseFilesFromMeta()
    local mxmlFile = xmlLoadFile("meta.xml", true)
    if not mxmlFile then
        return false, "failed to load meta.xml"
    end
    local nodes = xmlNodeGetChildren(mxmlFile)
    if not nodes then
        xmlUnloadFile(mxmlFile)
        return false, "failed to get meta.xml children nodes"
    end
    local filePaths = {}
    for _, node in pairs(nodes) do
        if xmlNodeGetName(node) == "file" then
            local srcAttr = xmlNodeGetAttribute(node, "src")
            if srcAttr and type(srcAttr) == "string" then
                local downloadAttr = xmlNodeGetAttribute(node, "download")
                filePaths[srcAttr] = { downloadOnDemand = (downloadAttr == "false") }
            end
        end
    end
    xmlUnloadFile(mxmlFile)
    return filePaths
end

local metaFilePaths, metaFailReason = parseFilesFromMeta()
if not metaFilePaths then
    srvLog("[parseFilesFromMeta] " .. metaFailReason)
    outputDebugString("Failed to load new models. See server log for details.", 1)
    return
end

-- Basic glob to Lua pattern conversion
function globToPattern(glob, sep)
    sep = sep or "/"

    local function escape_lua_pattern(s)
        return s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    end

    local pat = ""
    local i = 1
    local len = #glob
    while i <= len do
        local c = glob:sub(i, i)
        if c == "*" then
            if i + 1 <= len and glob:sub(i + 1, i + 1) == "*" then
                pat = pat .. ".*"
                i = i + 2
            else
                pat = pat .. "[^" .. escape_lua_pattern(sep) .. "]*"
                i = i + 1
            end
        elseif c == "?" then
            pat = pat .. "[^" .. escape_lua_pattern(sep) .. "]"
            i = i + 1
        else
            pat = pat .. escape_lua_pattern(c)
            i = i + 1
        end
    end

    pat = "^" .. pat .. "$"
    return pat
end

--- Checks if a given file path matches any glob pattern defined in filePaths
local function matchesMetaFile(filePath, filePaths)
    for src, data in pairs(filePaths) do
        local luaPattern = globToPattern(src)
        -- print("Glob:", src)
        -- print("Pattern:", luaPattern)

        -- The Lua pattern matching function
        if filePath:match(luaPattern) then
            -- print(filePath, "Matched with pattern:", luaPattern)
            return true, data
        end
    end
    -- print(filePath, "No match found")
    return false, nil
end

local function isAnyFileDownloadOnDemand(filePaths)
    for _, filePath in pairs(filePaths) do
        if type(filePath) == "string" then
            local matches, data = matchesMetaFile(filePath, metaFilePaths)
            if matches and data and data.downloadOnDemand then
                return true
            end
        end
    end
    return false
end

local function parseModelSettings(customModel, customModelInfo, thisFullPath, isFromSettingsOption)
    local file = fileOpen(thisFullPath, true)
    if not file then
        return false, "failed to open file: " .. thisFullPath
    end
    local info = fileGetContents(file, false)
    fileClose(file)
    if not info then
        return false, "failed to read file: " .. thisFullPath
    end
    local customModelSettings = {}
    local lines = split(info, "\n")
    for _, settingStr in pairs(lines) do
        settingStr = settingStr:gsub("\r", "")
        for _, declarativeSetting in pairs(DECLARATIVE_SETTINGS) do
            if settingStr == declarativeSetting then
                customModelSettings[declarativeSetting] = true
            end
        end
        if stringStartswith(settingStr, "lodDistance=") then
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
            local settingsFullPath = AUTO_MODELS_FOLDER .. "/" .. settingsPath
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
                    local settingModelFullPath = AUTO_MODELS_FOLDER .. "/" .. settingModelPath
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
    if not pathIsDirectory(AUTO_MODELS_FOLDER) then
        return false, "directory not found: " .. AUTO_MODELS_FOLDER
    end
    local filesAndFolders = pathListDir(AUTO_MODELS_FOLDER)
    if not filesAndFolders then
        return false, "failed to list directory: " .. AUTO_MODELS_FOLDER
    end
    local countLoaded = 0
    for _, modelType in pairs(VALID_MODEL_TYPES) do
        local modelTypePath = AUTO_MODELS_FOLDER .. "/" .. modelType
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
                            local settings = info.settings or {}
                            if isAnyFileDownloadOnDemand({ info.dff, info.txd, info.col }) then
                                settings["downloadFilesOnDemand"] = true
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
                            countLoaded = countLoaded + 1
                        end
                    end
                end
            end
        end
    end
    srvLog("Loaded " .. countLoaded .. " models from auto models folder.")
    return true
end

local result, failReason = loadModels()
if not result then
    srvLog("[loadModels] " .. failReason)
    outputDebugString("Failed to load new models. See server log for details.", 1)
    return
end

-- .................................................................
-- ...... Load new models from modList table .......................
-- .................................................................

-- This function is also used by external function to add models
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
    if modInfo.metaDownloadFalse then
        settings["downloadFilesOnDemand"] = true
    end
    -- New setting from v6
    if modInfo.loadRawData then
        settings["loadRawData"] = true
    end

    local ncExt = NANDOCRYPT_EXT

    -- DFF check
    if dff_path then
        if not fileExists(dff_path) then
            if fileExists(dff_path .. ncExt) then
                dff_path = dff_path .. ncExt
            else
                return false, "DFF file not found for custom model ID " .. customModel .. ": " .. dff_path
            end
        elseif stringStartswith(dff_path, AUTO_MODELS_FOLDER .. "/") then
            -- Disallow using auto models folder for modList entries
            return false,
                "DFF file for custom model ID " .. customModel .. " cannot be in the auto models folder: " .. dff_path
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
        elseif stringStartswith(txd_path, AUTO_MODELS_FOLDER .. "/") then
            -- Disallow using auto models folder for modList entries
            return false,
                "TXD file for custom model ID " .. customModel .. " cannot be in the auto models folder: " .. txd_path
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
        elseif stringStartswith(col_path, AUTO_MODELS_FOLDER .. "/") then
            -- Disallow using auto models folder for modList entries
            return false,
                "COL file for custom model ID " .. customModel .. " cannot be in the auto models folder: " .. col_path
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
    -- Loading modList is optional, so we return nil to ignore if not found
    if type(modList) ~= "table" then
        return nil
    end

    local countLoaded = 0

    -- Iterate over each model type in modList
    for modelType, modelList in pairs(modList) do
        local validType = false
        for _, vType in pairs(VALID_MODEL_TYPES) do
            if modelType == vType then
                validType = true
                break
            end
        end
        if not validType then
            return false, "Invalid model type in modList: " .. tostring(modelType)
        end
        if type(modelList) ~= "table" then
            return false, "Invalid Model list in '" .. modelType .. "' modList"
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

    srvLog("Loaded " .. countLoaded .. " models via modList Lua.")
    return true
end
local result2, failReason2 = loadModelsViaModList()
if result2 == false then
    srvLog("[loadModelsViaModList] " .. failReason2)
    outputDebugString("Failed to load models via modList. See server log for details.", 1)
    return
end

baseModelCounts = {}

-- .................................................................
-- ...... Logic for syncing custom models with clients .............
-- .................................................................

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



-- .......................................................................
-- ...... Exported functions for adding/removing models dynamically ......
-- .......................................................................

local function sendListToAllPlayers()
    for _, player in pairs(getElementsByType("player")) do
        sendCustomModelsToPlayer(player)
    end
    srvLog("Sent updated customModels table to online players.")
end

-- The following 2 add & remove functions were inspired by their newmodels v3 versions.

function addExternalModels(listToAdd, asyncLoad)
    if type(listToAdd) ~= "table" then
        return false, "invalid arg 1: not a table"
    end
    if #listToAdd == 0 then
        return false, "invalid arg 1: empty table"
    end
    if type(listToAdd[1]) ~= "table" then
        return false, "invalid arg 1: first entry is not a table"
    end
    local srcResName = sourceResource and getResourceName(sourceResource) or "unknown"
    local function parseOneListEntry(modInfo)
        if type(modInfo) ~= "table" then
            return false, "Found a modInfo entry that is not a table in listToAdd"
        end
        local modelType = modInfo.type
        local validType = false
        for _, vType in pairs(VALID_MODEL_TYPES) do
            if modelType == vType then
                validType = true
                break
            end
        end
        if not validType then
            return false, "Invalid model type in modInfo entry: " .. tostring(modelType)
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
        return true
    end
    if (asyncLoad == true) then
        srvLog("Beginning async addition of new models from '" .. srcResName .. "' via addExternalModels...")
        Async:foreach(listToAdd, function(modInfo)
                local parsed, parsingFailReason = parseOneListEntry(modInfo)
                if not parsed then
                    srvLog("Failed to add one external model via addExternalModels (async): " .. parsingFailReason)
                end
            end,
            function()
                srvLog("Finished adding new models from '" .. srcResName .. "' via addExternalModels (async).")
                sendListToAllPlayers()
            end)
        return true
    else
        local countLoaded = 0
        for _, modInfo in pairs(listToAdd) do
            local parsed, parsingFailReason = parseOneListEntry(modInfo)
            if not parsed then
                return false, parsingFailReason
            end
            countLoaded = countLoaded + 1
        end
        srvLog("Added " .. countLoaded .. " new models from '" .. srcResName .. "' via addExternalModels.")
        sendListToAllPlayers()
        return true
    end
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
