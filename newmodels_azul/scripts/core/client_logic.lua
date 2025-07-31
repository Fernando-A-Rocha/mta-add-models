addEvent("newmodels_azul:receiveCustomModels", true)
addEvent("newmodels_azul:setElementCustomModel", true)

loadedModels = {}

local loadingQueue = {}

local reusableModelElements = {}

local currFreeIdDelay = 9500   -- ms
local FREE_ID_DELAY_STEP = 500 -- ms

local function applyElementCustomModel(element)
    local customModel = elementModels[element]
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

local function finishLoadCustomModel(customModel)
    local queuedInfo = loadingQueue[customModel]
    if not queuedInfo then return end

    local customInfo = customModels[customModel]
    if not customInfo then return end

    local allocatedModel = queuedInfo.allocatedModel
    local col, txd, dff = queuedInfo.col, queuedInfo.txd, queuedInfo.dff
    local elementToApply = queuedInfo.elementToApply

    local enableDFFAlphaTransparency = customInfo.settings.enableDFFAlphaTransparency

    if (col and not engineReplaceCOL(col.element, allocatedModel))
    or (txd and not engineImportTXD(txd.element, allocatedModel))
    or (dff and not engineReplaceModel(dff.element, allocatedModel, enableDFFAlphaTransparency or nil)) then
        -- Destroy all non-reused col/txd/dff elements
        for _, modType in pairs({"col", "txd", "dff"}) do
            local mod = queuedInfo[modType]
            if mod and (not mod.isReused) and isElement(mod.element) then
                destroyElement(mod.element)
            end
        end
        engineRestoreCOL(allocatedModel)
        engineRestoreModel(allocatedModel)

        engineFreeModel(allocatedModel)

        loadingQueue[customModel] = nil
        outputDebugString("Failed to load custom model " .. customModel .. " due to col/txd/dff replacing failure", 1)
        return
    end

    local elementTypes = { "vehicle" }
    if customInfo.type == "ped" then
        elementTypes = { "ped", "player" }
    elseif customInfo.type == "object" then
        elementTypes = { "object", "pickup" }
    end

    if col and not col.isReused then
        reusableModelElements[col.path] = col.element
    end
    if txd and not txd.isReused then
        reusableModelElements[txd.path] = txd.element
    end
    if dff and not dff.isReused then
        reusableModelElements[dff.path] = dff.element
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
        modelPaths = {
            txd = txd and txd.path or nil,
            dff = dff and dff.path or nil,
            col = col and col.path or nil,
        },
        disableAutoFree = disableAutoFree or false,
    }

    if isElement(elementToApply) then
        applyElementCustomModel(elementToApply)
    end

    loadingQueue[customModel] = nil
end

local function onFailedToLoadModFile(customModel, filePath, fileType)
    local queuedInfo = loadingQueue[customModel]
    if queuedInfo then
        engineFreeModel(queuedInfo.allocatedModel)
        outputDebugString("Failed to load " .. fileType .. " file for custom model " .. customModel..": "..filePath, 1)

        loadingQueue[customModel] = nil
    end
end

local function onLoadedModFile(customModel, fileType, filePath, modElement, isReused)
    local queuedInfo = loadingQueue[customModel]
    if not queuedInfo then
        -- Loaded successfully but loading has already been cancelled
        -- due to another failure that happened before
        if isElement(modElement) and (not isReused) then
            destroyElement(modElement)
        end
        return
    end

    loadingQueue[customModel][fileType] = {
        path = filePath,
        element = modElement,
        isReused = isReused,
    }

    local expectingAmount = queuedInfo.expectingAmount - 1
    if expectingAmount == 0 then
        finishLoadCustomModel(customModel)
    else
        loadingQueue[customModel].expectingAmount = expectingAmount
    end
end

local function beginLoadCustomModel(customModel, elementToApply)
    local customInfo = customModels[customModel]
    if not customInfo then
        outputDebugString("Trying to load custom model " .. customModel .. " that does not exist", 2)
        return
    end

    if loadedModels[customModel] then
        outputDebugString("Trying to load custom model " .. customModel .. " that is already loaded", 1)
        return
    end

    local colPath, txdPath, dffPath = customInfo.col, customInfo.txd, customInfo.dff

    local decryptFunc = getNandoDecrypterFunction()

    local encryptedFiles = {
        col = isNandoCryptFileName(colPath),
        txd = isNandoCryptFileName(txdPath),
        dff = isNandoCryptFileName(dffPath),
    }

    if (encryptedFiles.col or encryptedFiles.txd or encryptedFiles.dff) and not decryptFunc then
        -- Cancel as we cannot decrypt the files
        outputDebugString("Failed to load custom model " .. customModel .. " due to missing NandoCrypt decrypter function", 1)
        return
    end

    local expectingAmount = 0
    if colPath then expectingAmount = expectingAmount + 1 end
    if txdPath then expectingAmount = expectingAmount + 1 end
    if dffPath then expectingAmount = expectingAmount + 1 end

    local allocatedModel = engineRequestModel(customInfo.type, customInfo.baseModel)
    if not allocatedModel then
        outputDebugString("Failed to load custom model " .. customModel .. " due to model allocation failure", 1)
        return
    end

    loadingQueue[customModel] = {
        allocatedModel = allocatedModel,
        elementToApply = elementToApply,
        expectingAmount = expectingAmount,
        -- These will be set to { path=string, element=col/txd/dff, isReused=true/false } when loaded
        col = nil,
        txd = nil,
        dff = nil,
    }
    local disableTXDTextureFiltering = customInfo.settings.disableTXDTextureFiltering

    local function loadModElement(modType, modPath, modData)
        local modElement
        if modType == "col" then
            modElement = engineLoadCOL(modData or modPath)
        elseif modType == "txd" then
            modElement = engineLoadTXD(modData or modPath, disableTXDTextureFiltering and false or nil)
        elseif modType == "dff" then
            modElement = engineLoadDFF(modData or modPath)
        end
        if not modElement then
            onFailedToLoadModFile(customModel, modPath, modType)
            return false
        end
        onLoadedModFile(customModel, modType, modPath, modElement)
        return true
    end

    local function loadOneMod(modType, modPath)
        local reusedElement = reusableModelElements[modPath]
        if reusedElement then
            onLoadedModFile(customModel, modType, modPath, reusedElement, true)
        elseif encryptedFiles[modType] then
            if not decryptFunc(modPath, function(data)
                loadModElement(modType, modPath, data)
            end) then
                onFailedToLoadModFile(customModel, modPath, modType)
                return
            end
        else
            if not loadModElement(modType, modPath) then
                return
            end
        end
    end

    if colPath then
        loadOneMod("col", colPath)
    end
    if txdPath then
        loadOneMod("txd", txdPath)
    end
    if dffPath then
        loadOneMod("dff", dffPath)
    end
end

local function isCustomModelInUse(customModel)
    local loadedModel = loadedModels[customModel]
    if loadedModel then
        for _, elementType in pairs(loadedModel.elementTypes) do
            for _, element in pairs(getElementsByType(elementType, root, true)) do
                if elementModels[element] == customModel then
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
    local customModel = elementModels[element]
    if not customModel then return end
    if not isCustomModelCompatible(customModel, element) then return end
    if not loadedModels[customModel] then
        beginLoadCustomModel(customModel, element)
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
    local customModel = elementModels[source]
    if not customModel then return end
    freeAllocatedModel(customModel)
end)

addEventHandler("onClientElementDestroy", root, function()
    if not isValidElement(source) then return end
    local customModel = elementModels[source]
    elementModels[source] = nil
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
    -- Free all allocated models instantly
    for customModel, _ in pairs(loadedModels) do
        freeAllocatedModelNow(customModel)
    end
end, false)
