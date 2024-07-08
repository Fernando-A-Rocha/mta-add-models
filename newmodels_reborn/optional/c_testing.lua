local enabled = false
local SW, SH = guiGetScreenSize()
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

setTimer(function()
    drawStr = getElementChidrenStr(resourceRoot, 0)
end, 1000, 0)

local function drawElements()
    dxDrawText(drawStr, SW/2, 30, SW, 0, 0xFFFFFFFF, 1, "default-bold")
end

addCommandHandler("newmodelstest", function()
    if not enabled then
        addEventHandler("onClientRender", root, drawElements, false)
    else
        removeEventHandler("onClientRender", root, drawElements)
    end
    enabled = not enabled
end, false)
