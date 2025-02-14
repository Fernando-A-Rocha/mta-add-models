local enabled = false
local SW = guiGetScreenSize()

local debugTimer = nil
local loadedModelsStr = ""
local streamedElements = {}

local function pairsByKeys(t)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a)
    local i = 0
    local iter = function()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

local function getElementCustomModelString(element)
    local customModel = getElementCustomModel(element)
    if customModel and customModels[customModel] then
        local name, baseModel = customModels[customModel].name, customModels[customModel].baseModel
        return {("%d \"%s\" (%d)"):format(customModel, name, baseModel), 0xffffa263}
    else
        return {("%d"):format(getElementModel(element))}
    end
end

local function updateDebugViewInfo()
    local loadedModelsStr_ = ""
    for customModel, v in pairsByKeys(loadedModels) do
        local str = ("%d \"%s\" (%d)"):format(customModel, v.name, v.baseModel)
        if loadedModelsStr_ == "" then
            loadedModelsStr_ = str
        else
            loadedModelsStr_ = str .. ", " .. loadedModelsStr_
        end
    end
    if loadedModelsStr_ ~= "" then
        loadedModelsStr = "Loaded new models:\n" .. loadedModelsStr_
    else
        loadedModelsStr = "No new models loaded."
    end

    streamedElements = {}
    for _, element in pairs(getElementsByType("vehicle", root, true)) do
        streamedElements[element] = getElementCustomModelString(element)
    end
    for _, element in pairs(getElementsByType("object", root, true)) do
        streamedElements[element] = getElementCustomModelString(element)
    end
    for _, element in pairs(getElementsByType("ped", root, true)) do
        streamedElements[element] = getElementCustomModelString(element)
    end
    for _, element in pairs(getElementsByType("player", root, true)) do
        streamedElements[element] = getElementCustomModelString(element)
    end
end

local function drawDebug()
    dxDrawText("Newmodels v5 Azul", SW/2, 15, SW/2, 15, 0xff70e2ff, 1.5, "default-bold", "center", "center")
    dxDrawText(loadedModelsStr, SW/2, 32, SW/2, 32, 0xFFFFFFFF, 1, "default-bold", "center", "top")

    for element, customModelStr in pairs(streamedElements) do
        local x, y, z = getElementPosition(element)
        local sx, sy = getScreenFromWorldPosition(x, y, z + 0.5)
        if sx and sy then
            dxDrawText(customModelStr[1], sx, sy, sx, sy, customModelStr[2] or 0xFFFFFFFF, 1, "default", "center")
        end
    end
end

local function handleElementDestroyed()
    streamedElements[source] = nil
end

local function toggleDebugView(cmd)
    if not enabled then
        if not (debugTimer) or (not isTimer(debugTimer)) then debugTimer = setTimer(updateDebugViewInfo, 1000, 0) end
        addEventHandler("onClientRender", root, drawDebug, false)
        addEventHandler("onClientElementDestroy", root, handleElementDestroyed)
    else
        if debugTimer and isTimer(debugTimer) then killTimer(debugTimer); debugTimer = nil end
        streamedElements = {}
        removeEventHandler("onClientRender", root, drawDebug)
        removeEventHandler("onClientElementDestroy", root, handleElementDestroyed)
    end
    enabled = not enabled
    outputChatBox(cmd .. " => " .. tostring(enabled))
end
addCommandHandler("newmodelsdebug", toggleDebugView, false)

if (DEBUG_VIEW_ON_BY_DEFAULT) then
    executeCommandHandler("newmodelsdebug")
end