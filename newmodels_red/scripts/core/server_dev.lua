-- Useful dev commands
-- Only usable from server console

local function msg(str)
    outputServerLog(("[%s] %s"):format(getResourceName(resource), str))
end

local function cmdCheckModelId(executor, cmd, modelId)
    if getElementType(executor) ~= "console" then return end

    modelId = tonumber(modelId)
    if not modelId then
        msg(("Usage: %s <modelId>"):format(cmd))
        return
    end

    local isDef, elementType = isDefaultID(false, modelId)
    if isDef then
        msg(("Model ID %d is a default '%s' GTA model."):format(modelId, elementType))
        return
    end

    local customInfo = customModels[modelId]
    if not customInfo then
        msg(("Model ID %d is NOT loaded as a custom model."):format(modelId))
        return
    end

    local customModelName = customInfo.name or "<unnamed>"
    local baseModel = customInfo.baseModel
    local baseModelName = ""
    if customInfo.type == "vehicle" then
        local vehName = getVehicleNameFromModel(baseModel)
        if vehName then
            baseModelName = (" ('%s')"):format(vehName)
        end
    end

    msg(("Model ID %d is loaded as custom model '%s' (%s), based on model ID %d%s."):format(
        modelId, customModelName, customInfo.type, baseModel, baseModelName
    ))
end
addCommandHandler("checkmodelid", cmdCheckModelId)
