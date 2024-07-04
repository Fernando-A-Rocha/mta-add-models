addEvent("newmodels_reborn:receiveCustomModels", true)

local loadedModels = {}

local function applyElementCustomModel(element)
    local customModel = tonumber(getElementData(element, CUSTOM_MODEL_DATA_KEY))
    if not customModel then return end
    local loadedModel = loadedModels[customModel]
    if not loadedModel then return end

    local upgrades, handling
    if getElementType(element) == "vehicle" then
        upgrades = getVehicleUpgrades(element)
        handling = getVehicleHandling(element)
    end

    setElementModel(element, loadedModel.id) 

    if upgrades then
        for _, v in pairs(upgrades) do
            addVehicleUpgrade(element, v)
        end
    end
    if handling then
        for k, v in pairs(handling) do
            setVehicleHandling(element, k, v)
        end
    end
end

local function loadCustomModel(customModel, elementToApply)
    if not tonumber(customModel) then return end
    local customInfo = customModels[customModel]
    if not customInfo then return end

    if loadedModels[customModel] then return end

    local allocatedModel = engineRequestModel(customInfo.type, customInfo.baseModel)
    if not allocatedModel then return end

    local colPath, txdPath, dffPath = customInfo.col, customInfo.txd, customInfo.dff
    
    local col, txd, dff
    if colPath then
        col = engineLoadCOL(colPath)
    end
    if txdPath then
        txd = engineLoadTXD(txdPath)
    end
    if dffPath then
        dff = engineLoadDFF(dffPath)
    end
    
    if (colPath and not col)
    or (txdPath and not txd)
    or (dffPath and not dff) then
        if col and isElement(col) then destroyElement(col) end
        if txd and isElement(txd) then destroyElement(txd) end
        if dff and isElement(dff) then destroyElement(dff) end
        engineFreeModel(allocatedModel)
        return
    end

    if (col and not engineReplaceCOL(col, allocatedModel))
    or (txd and not engineImportTXD(txd, allocatedModel))
    or (dff and not engineReplaceModel(dff, allocatedModel)) then
        if col and isElement(col) then destroyElement(col) end
        if txd and isElement(txd) then destroyElement(txd) end
        if dff and isElement(dff) then destroyElement(dff) end
        engineRestoreCOL(allocatedModel)
        engineRestoreModel(allocatedModel)
        engineFreeModel(allocatedModel)
        return
    end

    local elementTypes = { "vehicle" }
    if customInfo.type == "ped" then
        elementTypes = { "ped", "player" }
    elseif customInfo.type == "object" then
        elementTypes = { "object", "pickup" }
    end
    
    loadedModels[customModel] = { id = allocatedModel, elements = { txd = txd, dff = dff, col = col }, elementTypes = { elementTypes } }
    
    if isElement(elementToApply) then
        applyElementCustomModel(elementToApply)
    end
end

local function countStreamedElementsWithCustomModel(elementTypes, customModel)
    local count = 0
    for k, elementType in pairs(elementTypes) do
        for _, v in pairs(getElementsByType(elementType, root, true)) do
            if getElementData(v, CUSTOM_MODEL_DATA_KEY) == customModel then
                count = count + 1
            end
        end
    end
    return count
end

local function freeAllocatedModel(customModel)
    local loadedModel = loadedModels[customModel]
    if not loadedModel then return end
    engineRestoreCOL(loadedModel.id)
    engineRestoreModel(loadedModel.id)
    engineFreeModel(loadedModel.id)
    if isElement(loadedModel.elements.col) then destroyElement(loadedModel.elements.col) end
    if isElement(loadedModel.elements.txd) then destroyElement(loadedModel.elements.txd) end
    if isElement(loadedModel.elements.dff) then destroyElement(loadedModel.elements.dff) end
    loadedModels[customModel] = nil
end

local function freeAllocatedModelIfUnused(customModel)
    local loadedModel = loadedModels[customModel]
    if not loadedModel then return end
    if countStreamedElementsWithCustomModel(loadedModel.elementTypes, customModel) == 0 then
        freeAllocatedModel(customModel)
    end
end

local function setElementCustomModel(veh)
    local customModel = getElementData(veh, CUSTOM_MODEL_DATA_KEY)
    if not customModel then return end
    if not loadedModels[customModel] then
        loadCustomModel(customModel, veh)
    else
        applyElementCustomModel(veh)
    end
end

addEventHandler("onClientElementDataChange", root, function(key, oldValue, newValue)
    if not isValidElement(source) then return end
    if key ~= CUSTOM_MODEL_DATA_KEY then return end
    if not newValue then
        local customModel = getElementData(source, CUSTOM_MODEL_DATA_KEY)
        if not customModel then return end
        freeAllocatedModel(customModel)
    else
        setElementCustomModel(source)
    end
    oldValue = tonumber(oldValue)
    if oldValue then
        freeAllocatedModelIfUnused(oldValue)
    end
end)

addEventHandler("onClientElementStreamIn", root, function()
    if not isValidElement(source) then return end
    setElementCustomModel(source)
end)

addEventHandler("onClientElementStreamOut", root, function()
    if not isValidElement(source) then return end
    local customModel = getElementData(source, CUSTOM_MODEL_DATA_KEY)
    if not customModel then return end
    freeAllocatedModelIfUnused(customModel)
end)

addEventHandler("onClientElementDestroy", root, function()
    if not isValidElement(source) then return end
    local customModel = getElementData(source, CUSTOM_MODEL_DATA_KEY)
    if not customModel then return end
    freeAllocatedModelIfUnused(customModel)
end)

local function applyCustomModelsForStreamedElements()
    for _, elementType in pairs(ELEMENT_TYPES) do
        for _, v in pairs(getElementsByType(elementType, root, true)) do
            setElementCustomModel(v)
        end
    end
end

addEventHandler("newmodels_reborn:receiveCustomModels", resourceRoot, function(customModelsFromServer)
    customModels = customModelsFromServer

    applyCustomModelsForStreamedElements()
end, false)
