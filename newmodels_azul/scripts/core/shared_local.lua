local isClientsideScript = localPlayer ~= nil

-- Shared custom models table:
customModels = {}

-- Shared element models table:
elementModels = {}

function getCustomModels()
    return customModels
end

function getElementModels()
    return elementModels
end

-- Passing nil id resets the element's custom model
function setElementCustomModel(element, id)
    assert(isElement(element), "Invalid element passed: " .. tostring(element))
    assert(isValidElement(element), "Invalid element type passed: " .. getElementType(element))
    id = tonumber(id) or nil
    if id then
        -- Check if valid custom model ID
        local customModelInfo = customModels[id]
        if not customModelInfo then
            outputDebugString("Invalid custom model ID passed: " .. tostring(id), 1)
            return false
        end
        if not isCustomModelCompatible(id, element) then
            outputDebugString("Custom model ID " .. id .. " is not compatible with element type " .. getElementType(element), 1)
            return false
        end
    end
    if not isClientsideScript then
        elementModels[element] = id -- Set serverside
        triggerClientEvent(getElementsByType("player"), "newmodels_azul:setElementCustomModel", element, id)
    else
        triggerEvent("newmodels_azul:setElementCustomModel", element, id)
    end
    return true
end
