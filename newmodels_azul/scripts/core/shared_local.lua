local isClientsideScript = localPlayer ~= nil

-- NandoCrypt file extension
local NANDOCRYPT_EXT = ".nandocrypt"

function isNandoCryptFileName(fn)
    if type(fn) == "string" then
        if fn:sub(-#NANDOCRYPT_EXT) == NANDOCRYPT_EXT then
            local precedingFileExt = fn:sub(-#NANDOCRYPT_EXT - 3, -#NANDOCRYPT_EXT - 1)
            local precedingNumber = tonumber(fn:sub(1, -#NANDOCRYPT_EXT - 5))
            return true, precedingFileExt, precedingNumber
        end
    end
    return false
end

if isClientsideScript then
    function getNandoDecrypterFunction()
        if type(ncDecrypt) == "function" then
            return ncDecrypt
        end
    end
end

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
        setTimer(function()
            triggerClientEvent(getElementsByType("player"), "newmodels_azul:setElementCustomModel", element, id)
        end, 50, 1)
    else
        triggerEvent("newmodels_azul:setElementCustomModel", element, id)
    end
    return true
end
