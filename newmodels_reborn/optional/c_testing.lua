local enabled = false
local SW = guiGetScreenSize()

local debugTimer = nil
local drawStr = ""

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

local function updateDebugStr()
    local loadedModelsStr = ""
    for customModel, v in pairsByKeys(loadedModels) do
        if loadedModelsStr == "" then
            loadedModelsStr = ("%d (%d)"):format(customModel, v.baseModel)
        else
            loadedModelsStr = loadedModelsStr .. (", %d (%d)"):format(customModel, v.baseModel)
        end
    end
    drawStr = getElementChidrenStr(resourceRoot, 0)
    if loadedModelsStr ~= "" then
        drawStr = "Loaded models:\n" .. loadedModelsStr .. "\n\n" .. drawStr
    end
end

local function drawDebug()
    dxDrawText(drawStr, SW/2, 30, SW, 0, 0xFFFFFFFF, 1, "default-bold")
end

addCommandHandler("newmodelsdebug", function(cmd)
    if not enabled then
        if not (debugTimer) or (not isTimer(debugTimer)) then debugTimer = setTimer(updateDebugStr, 1000, 0) end
        addEventHandler("onClientRender", root, drawDebug, false)
    else
        if debugTimer and isTimer(debugTimer) then killTimer(debugTimer); debugTimer = nil end
        removeEventHandler("onClientRender", root, drawDebug)
    end
    enabled = not enabled
    outputChatBox(cmd .. " => " .. tostring(enabled))
end, false)
