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
        if not pathIsDirectory(modelTypePath) then
            return false, modelTypePath .. " directory not found"
        end
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
                    local filesForCustomModel = {}
                    for _, fileInside in pairs(filesAndFoldersInside) do
                        local fullPathInside = fullPath .. "/" .. fileInside
                        if pathIsFile(fullPathInside) then
                            local fileType = string.sub(fileInside, -3)
                            if not (fileType == "dff" or fileType == "txd" or fileType == "col") then
                                return false, "invalid " .. modelType .. " file type: " .. fileType
                            end
                            local customModel = tonumber(string.sub(fileInside, 1, -5))
                            if not customModel then
                                return false, "invalid " .. modelType .. " custom model: " .. fileInside
                            end
                            if isDefaultID(modelType, customModel) then
                                return false, "custom " .. modelType .. " model is a default ID: " .. customModel
                            end
                            if customModels[customModel] then
                                return false, "duplicate " .. modelType .. " custom model: " .. customModel
                            end
                            if not filesForCustomModel[customModel] then
                                filesForCustomModel[customModel] = {}
                            end
                            filesForCustomModel[customModel][fileType] = fullPathInside
                        end
                    end
                    for customModel, files in pairs(filesForCustomModel) do
                        customModels[customModel] = {
                            type = modelType,
                            baseModel = baseModel,
                            dff = files.dff,
                            txd = files.txd,
                            col = files.col
                        }
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
    outputDebugString(getResourceName(resource) .. " failed to load models. See server log for details.")
    return
end

addEventHandler("onPlayerResourceStart", root, function(res)
    if res == resource then
        triggerClientEvent(source, "newmodels_reborn:receiveCustomModels", resourceRoot, customModels)
    end
end)

