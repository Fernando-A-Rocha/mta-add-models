addEvent("newmodels_azul:receiveCustomModels", true)
addEvent("newmodels_azul:setElementCustomModel", true)

loadedModels = {}

local reusableModelElements = {}

local currFreeIdDelay = 9500   -- ms
local FREE_ID_DELAY_STEP = 500 -- ms

local function applyElementCustomModel(element)
    local customModel = getElementCustomModel(element)
    if not customModel then return end
    local loadedModel = loadedModels[customModel]
    if not loadedModel then return end

    if getElementModelMTA(element) == loadedModel.id then return end

    local upgrades, handling, paintjob
    if getElementType(element) == "vehicle" then
        upgrades = getVehicleUpgrades(element)
        handling = getVehicleHandling(element)
        paintjob = getVehiclePaintjob(element)
    end

    setElementModelMTA(element, loadedModel.id)

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

    local disableTXDTextureFiltering = customInfo.settings.disableTXDTextureFiltering

    local col, txd, dff
    if colPath then
        col = reusableModelElements[colPath] or engineLoadCOL(colPath)
    end
    if txdPath then
        txd = reusableModelElements[txdPath] or engineLoadTXD(txdPath, disableTXDTextureFiltering and false or nil)
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

    local enableDFFAlphaTransparency = customInfo.settings.enableDFFAlphaTransparency

    if (col and not engineReplaceCOL(col, allocatedModel))
        or (txd and not engineImportTXD(txd, allocatedModel))
        or (dff and not engineReplaceModel(dff, allocatedModel, enableDFFAlphaTransparency or nil)) then
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

    local disableAutoFree = customInfo.settings.disableAutoFree
    local lodDistance = customInfo.settings.lodDistance
    if lodDistance then
        engineSetModelLODDistance(allocatedModel, lodDistance)
    end

    -- Set loadedModel info
    loadedModels[customModel] = {
        id = allocatedModel,
        baseModel = customInfo.baseModel,
        name = customInfo.name,
        elementTypes = elementTypes,
        freeAllocatedTimer = nil,
        modelPaths = { txd = txdPath, dff = dffPath, col = colPath },
        disableAutoFree = disableAutoFree or false,
    }

    if isElement(elementToApply) then
        applyElementCustomModel(elementToApply)
    end
end

local function isCustomModelInUse(customModel)
    local loadedModel = loadedModels[customModel]
    if loadedModel then
        for _, elementType in pairs(loadedModel.elementTypes) do
            for _, element in pairs(getElementsByType(elementType, root, true)) do
                if getElementCustomModel(element) == customModel then
                    return true
                end
            end
        end
    end
    return false
end

local function freeAllocatedModelNow(customModel)
    local loadedModel = loadedModels[customModel]
    if not loadedModel then return end

    if isTimer(loadedModel.freeAllocatedTimer) then
        killTimer(loadedModel.freeAllocatedTimer)
    end
    engineResetModelLODDistance(loadedModel.id)
    engineFreeModel(loadedModel.id)

    -- Destroy model elements unless used by another loaded model
    for _, modelType in pairs({ "dff", "txd", "col" }) do
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

local function freeAllocatedModel(customModel)
    local loadedModel = loadedModels[customModel]
    if not loadedModel then return end
    if loadedModel.disableAutoFree then
        return
    end
    -- Do not free all models at once, delay each model by a bit
    currFreeIdDelay = currFreeIdDelay + FREE_ID_DELAY_STEP

    if isTimer(loadedModel.freeAllocatedTimer) then
        killTimer(loadedModel.freeAllocatedTimer)
    end
    loadedModel.freeAllocatedTimer = setTimer(function()
        if not isCustomModelInUse(customModel) then
            freeAllocatedModelNow(customModel)
        end
        currFreeIdDelay = currFreeIdDelay - FREE_ID_DELAY_STEP
    end, currFreeIdDelay, 1)
end

local function attemptApplyElementCustomModel(element)
    local customModel = getElementCustomModel(element)
    if not customModel then return end
    if not isCustomModelCompatible(customModel, element) then return end
    if not loadedModels[customModel] then
        loadCustomModel(customModel, element)
    else
        applyElementCustomModel(element)
    end
end

addEventHandler("newmodels_azul:setElementCustomModel", root, function(id)
    if not isValidElement(source) then return end
    id = tonumber(id) or nil
    local oldCustomModel = elementModels[source]
    if oldCustomModel then
        freeAllocatedModel(oldCustomModel)
    end
    elementModels[source] = id

    if not isElementStreamedIn(source) then return end
    attemptApplyElementCustomModel(source)
end)

addEventHandler("onClientElementStreamIn", root, function()
    if not isValidElement(source) then return end
    attemptApplyElementCustomModel(source)
end)

addEventHandler("onClientElementStreamOut", root, function()
    if not isValidElement(source) then return end
    local customModel = getElementCustomModel(source)
    if not customModel then return end
    freeAllocatedModel(customModel)
end)

addEventHandler("onClientElementDestroy", root, function()
    if not isValidElement(source) then return end
    local customModel = getElementCustomModel(source)
    if not customModel then return end
    freeAllocatedModel(customModel)
end)

local function restoreElementBaseModels()
    -- Restore the base models of all elements with custom models
    for _, elementType in pairs(getValidElementTypes()) do
        for _, element in pairs(getElementsByType(elementType, root, true)) do
            local model = getElementModelMTA(element)
            for _, loadedModel in pairs(loadedModels) do
                if loadedModel.id == model then
                    setElementModelMTA(element, loadedModel.baseModel)
                    break
                end
            end
        end
    end
end

addEventHandler("newmodels_azul:receiveCustomModels", resourceRoot, function(customModelsFromServer, elementModelsFromServer)
    restoreElementBaseModels()

    -- Unload all loaded models
    for customModel, _ in pairs(loadedModels) do
        freeAllocatedModelNow(customModel)
    end

    customModels = customModelsFromServer

    elementModels = elementModelsFromServer

    for _, elementType in pairs(getValidElementTypes()) do
        for _, element in pairs(getElementsByType(elementType, root, true)) do
            attemptApplyElementCustomModel(element)
        end
    end
end, false)

addEventHandler("onClientResourceStop", resourceRoot, function()
    restoreElementBaseModels()
    -- Free all allocated models instantly
    for customModel, _ in pairs(loadedModels) do
        freeAllocatedModelNow(customModel)
    end
end, false)
