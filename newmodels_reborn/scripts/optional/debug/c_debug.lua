local enabled = false
local SW = guiGetScreenSize()

local debugTimer = nil
local drawStr = ""
local streamedElements = {}

local function getElementInfoStr(element, level)
    local spaces = string.rep("----- ", level)
    if isValidElement(element) then
        return ("%s%s | model: %s\n"):format(spaces, inspect(element), getElementModel(element))
    else
        return ("%s%s\n"):format(spaces, inspect(element))
    end
end

local function getElementChidrenStr(element, level)
    local str = ""
    local children = getElementChildren(element) or {}
    for i=1, #children do
        str = str .. getElementInfoStr(children[i], level)
        str = str .. getElementChidrenStr(children[i], level + 1)
    end
    return str
end

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
    local customModel = tonumber(getElementData(element, getCustomModelDataKey(element)))
    if customModel and customModels[customModel] then
        local name, baseModel = customModels[customModel].name, customModels[customModel].baseModel
        return ("%d \"%s\" (%d)"):format(customModel, name, baseModel)
    else
        return ("%d"):format(getElementModel(element))
    end
end

local function updateDebugViewInfo()
    local loadedModelsStr = ""
    for customModel, v in pairsByKeys(loadedModels) do
        local str = ("%d \"%s\" (%d)"):format(customModel, v.name, v.baseModel)
        if loadedModelsStr == "" then
            loadedModelsStr = str
        else
            loadedModelsStr = loadedModelsStr .. ", " .. str
        end
    end
    drawStr = getElementChidrenStr(resourceRoot, 0)
    if loadedModelsStr ~= "" then
        drawStr = "Loaded models:\n" .. loadedModelsStr .. "\n\n" .. drawStr
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
    dxDrawText(drawStr, SW/2, 30, SW, 0, 0xFFFFFFFF, 1, "default-bold")

    for element, customModelStr in pairs(streamedElements) do
        local x, y, z = getElementPosition(element)
        local sx, sy = getScreenFromWorldPosition(x, y, z + 0.5)
        if sx and sy then
            dxDrawText(customModelStr, sx, sy, 0, 0, 0xFFFFFFFF, 1, "default")
        end
    end
end

local function toggleDebugView(cmd)
    if not enabled then
        if not (debugTimer) or (not isTimer(debugTimer)) then debugTimer = setTimer(updateDebugViewInfo, 1000, 0) end
        addEventHandler("onClientRender", root, drawDebug, false)
    else
        if debugTimer and isTimer(debugTimer) then killTimer(debugTimer); debugTimer = nil end
        streamedElements = {}
        removeEventHandler("onClientRender", root, drawDebug)
    end
    enabled = not enabled
    outputChatBox(cmd .. " => " .. tostring(enabled))
end
addCommandHandler("newmodelsdebug", toggleDebugView, false)

if (DEBUG_VIEW_ON_BY_DEFAULT) then
    executeCommandHandler("newmodelsdebug")
end