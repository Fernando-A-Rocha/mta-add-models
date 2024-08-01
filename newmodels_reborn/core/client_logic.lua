addEvent("newmodels_reborn:receiveCustomModels", true)

loadedModels = {}

local reusableModelElements = {}

local currFreeIdDelay = 9500 -- ms
local FREE_ID_DELAY_STEP = 500 -- ms

local function applyElementCustomModel(element)
    local customModel = tonumber(getElementData(element, getCustomModelDataKey(element)))
    if not customModel then return end
    local loadedModel = loadedModels[customModel]
    if not loadedModel then return end

    if _getElementModel(element) == loadedModel.id then return end

    local upgrades, handling, paintjob
    if getElementType(element) == "vehicle" then
        upgrades = getVehicleUpgrades(element)
        handling = getVehicleHandling(element)
        paintjob = getVehiclePaintjob(element)
    end

    _setElementModel(element, loadedModel.id)

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
    if paintjob then
        setVehiclePaintjob(element, paintjob)
    end
end

local function loadCustomModel(customModel, elementToApply)
    if not tonumber(customModel) then return end

    local customInfo = customModels[customModel]
    if not customInfo then
        outputDebugString("Trying to load custom model " .. customModel .. " that does not exist", 2)
        return
    end

    if loadedModels[customModel] then
        outputDebugString("Trying to load custom model " .. customModel .. " that is already loaded", 1)
        return
    end

    local allocatedModel = engineRequestModel(customInfo.type, customInfo.baseModel)
    if not allocatedModel then
        outputDebugString("Failed to load custom model " .. customModel .. " due to model allocation failure", 1)
        return
    end

    local colPath, txdPath, dffPath = customInfo.col, customInfo.txd, customInfo.dff

    local col, txd, dff
    if colPath then
        col = reusableModelElements[colPath] or engineLoadCOL(colPath)
    end
    if txdPath then
        txd = reusableModelElements[txdPath] or engineLoadTXD(txdPath)
    end
    if dffPath then
        dff = reusableModelElements[dffPath] or engineLoadDFF(dffPath)
    end

    if (colPath and not col)
    or (txdPath and not txd)
    or (dffPath and not dff) then
        if col and isElement(col) then destroyElement(col) end
        if txd and isElement(txd) then destroyElement(txd) end
        if dff and isElement(dff) then destroyElement(dff) end
        engineFreeModel(allocatedModel)
        outputDebugString("Failed to load custom model " .. customModel .. " due to col/txd/dff loading failure", 1)
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
        outputDebugString("Failed to load custom model " .. customModel .. " due to col/txd/dff replacing failure", 1)
        return
    end

    local elementTypes = { "vehicle" }
    if customInfo.type == "ped" then
        elementTypes = { "ped", "player" }
    elseif customInfo.type == "object" then
        elementTypes = { "object", "pickup" }
    end

    if col then
        reusableModelElements[colPath] = col
    end
    if txd then
        reusableModelElements[txdPath] = txd
    end
    if dff then
        reusableModelElements[dffPath] = dff
    end

    -- Set loadedModel info
    loadedModels[customModel] = {
        id = allocatedModel,
        baseModel = customInfo.baseModel,
        name = customInfo.name,
        elementTypes = elementTypes,
        freeAllocatedTimer = nil,
        modelPaths = { txd = txdPath, dff = dffPath, col = colPath }
    }

    if isElement(elementToApply) then
        applyElementCustomModel(elementToApply)
    end
end

local function countStreamedElementsWithCustomModel(elementTypes, customModel)
    local count = 0
    for _, elementType in pairs(elementTypes) do
        for _, v in pairs(getElementsByType(elementType, root, true)) do
            if getElementData(v, getCustomModelDataKey(elementType)) == customModel then
                count = count + 1
            end
        end
    end
    return count
end

local function freeAllocatedModelNow(customModel)
    local loadedModel = loadedModels[customModel]
    if not loadedModel then return end

    if isTimer(loadedModel.freeAllocatedTimer) then
        killTimer(loadedModel.freeAllocatedTimer)
    end
    engineFreeModel(loadedModel.id)

    -- Destroy model elements unless used by another loaded model
    for _, modelType in pairs({"dff", "txd", "col"}) do
        local modelPath = loadedModel.modelPaths[modelType]
        if modelPath and reusableModelElements[modelPath] then
            -- Check if another loaded model uses this model element
            local isUsed = false
            for customModel2, loadedModel2 in pairs(loadedModels) do
                if customModel2 ~= customModel and loadedModel2.modelPaths[modelType] == modelPath then
                    isUsed = true
                    break
                end
            end
            if not isUsed then
                if isElement(reusableModelElements[modelPath]) then
                    destroyElement(reusableModelElements[modelPath])
                end
                reusableModelElements[modelPath] = nil
            end
        end
    end

    -- Unset loadedModel info
    loadedModels[customModel] = nil
end

local function freeAllocatedModel(customModel, loadedModel)
    if isTimer(loadedModel.freeAllocatedTimer) then
        killTimer(loadedModel.freeAllocatedTimer)
    end
    -- Do not free all models at once, delay each model by a bit
    currFreeIdDelay = currFreeIdDelay + FREE_ID_DELAY_STEP
    loadedModel.freeAllocatedTimer = setTimer(function()
        freeAllocatedModelNow(customModel)
        currFreeIdDelay = currFreeIdDelay - FREE_ID_DELAY_STEP
    end, currFreeIdDelay, 1)
end

local function freeAllocatedModelIfUnused(customModel)
    local loadedModel = loadedModels[customModel]
    if not loadedModel then return end
    if countStreamedElementsWithCustomModel(loadedModel.elementTypes, customModel) == 0 then
        freeAllocatedModel(customModel, loadedModel)
    end
end

local function setElementCustomModel(element)
    local customModel = getElementData(element, getCustomModelDataKey(element))
    if not customModel then return end
    if not loadedModels[customModel] then
        loadCustomModel(customModel, element)
    else
        applyElementCustomModel(element)
    end
end

addEventHandler("onClientElementDataChange", root, function(key, prevCustomModel, newCustomModel)
    if not isValidElement(source) then return end
    if key ~= getCustomModelDataKey(source) then return end
    prevCustomModel = tonumber(prevCustomModel)

    -- Get the base model of the previous custom model the element has
    local prevLoadedModelBaseModel
    if prevCustomModel then
        local prevLoadedModel = loadedModels[prevCustomModel]
        if prevLoadedModel then
            prevLoadedModelBaseModel = prevLoadedModel.baseModel
        end
    end

    if not newCustomModel then
        -- If resetting the custom model, free the allocated model if it's not used by any other element
        local loadedModel = loadedModels[newCustomModel]
        if loadedModel then
            freeAllocatedModel(newCustomModel, loadedModel)
        end
    else
        setElementCustomModel(source)
    end
    if prevCustomModel then
        -- Force-set the base model of the previous custom model if resetting the custom model
        if (not newCustomModel) and prevLoadedModelBaseModel then
            _setElementModel(source, prevLoadedModelBaseModel)
        end

        -- Free the previous custom model if it's not used by any other element
        freeAllocatedModelIfUnused(prevCustomModel)
    end
end)

addEventHandler("onClientElementStreamIn", root, function()
    if not isValidElement(source) then return end
    setElementCustomModel(source)
end)

addEventHandler("onClientElementStreamOut", root, function()
    if not isValidElement(source) then return end
    local customModel = getElementData(source, getCustomModelDataKey(source))
    if not customModel then return end
    freeAllocatedModelIfUnused(customModel)
end)

addEventHandler("onClientElementDestroy", root, function()
    if not isValidElement(source) then return end
    local customModel = getElementData(source, getCustomModelDataKey(source))
    if not customModel then return end
    freeAllocatedModelIfUnused(customModel)
end)

local function restoreElementBaseModels()
    -- Restore the base models of all elements with custom models
    for _, elementType in pairs(VALID_ELEMENT_TYPES) do
        for _, element in pairs(getElementsByType(elementType, root, true)) do
            local model = _getElementModel(element)
            for _, loadedModel in pairs(loadedModels) do
                if loadedModel.id == model then
                    _setElementModel(element, loadedModel.baseModel)
                    break
                end
            end
        end
    end
end

addEventHandler("newmodels_reborn:receiveCustomModels", resourceRoot, function(customModelsFromServer)
    restoreElementBaseModels()

    -- Unload all loaded models
    for customModel, _ in pairs(loadedModels) do
        freeAllocatedModelNow(customModel)
    end

    customModels = customModelsFromServer

    for _, elementType in pairs(VALID_ELEMENT_TYPES) do
        for _, element in pairs(getElementsByType(elementType, root, true)) do
            setElementCustomModel(element)
        end
    end
end, false)

addEventHandler("onClientResourceStop", resourceRoot, function()
    restoreElementBaseModels()
end, false)
