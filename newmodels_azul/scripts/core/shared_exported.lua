-- THIS SCRIPT IS ENTIRELY LOADED WHEN import() IS CALLED
-- All non-local functions in this script are also exported and can be used in other resources

-- Variable IS_IMPORTED will be replaced to true
-- when this script is imported by another resource using the import() function
local IS_IMPORTED = false

local VALID_ELEMENT_TYPES = { "vehicle", "ped", "player", "object", "pickup" }

local isClientsideScript = localPlayer ~= nil

local newmodelsUtils = {}

-- MTA Function overrides:

createObjectMTA = createObject
createVehicleMTA = createVehicle
getVehicleTypeMTA = getVehicleType
createPedMTA = createPed
createPickupMTA = createPickup
setPickupTypeMTA = setPickupType

getElementModelMTA = getElementModel
setElementModelMTA = setElementModel

spawnPlayerMTA = spawnPlayer

newmodelsUtils.resources = {}

newmodelsUtils.getSharedCustomModelsTbl = function()
    if IS_IMPORTED then
        return exports["newmodels_azul"]:getCustomModels()
    end
    -- Script is running within this resource, so we can access the table directly
    return customModels
end

newmodelsUtils.getSharedElementModelsTbl = function()
    if IS_IMPORTED then
        return exports["newmodels_azul"]:getElementModels()
    end
    -- Script is running within this resource, so we can access the table directly
    return elementModels
end

newmodelsUtils.setElementCustomModel = function(...)
    if IS_IMPORTED then
        return exports["newmodels_azul"]:setElementCustomModel(...)
    end
    return setElementCustomModel(...)
end

function isCustomModelCompatible(id, elementOrElementType)
    assert(type(id) == "number", "Bad argument @ isCustomModelCompatible [expected number at argument 1, got " .. type(id) .. "]")
    assert(type(elementOrElementType) == "string" or isElement(elementOrElementType), "Bad argument @ isCustomModelCompatible [expected string/element at argument 2, got " .. type(elementOrElementType) .. "]")

    local customInfo = newmodelsUtils.getSharedCustomModelsTbl()[id]
    if not customInfo then return false end

    local elementType = type(elementOrElementType) == "string" and elementOrElementType or getElementType(elementOrElementType)
    if elementType == "object" or elementType == "pickup" then
        return customInfo.type == "object"
    elseif elementType == "ped" or elementType == "player" then
        return customInfo.type == "ped"
    elseif elementType == "vehicle" then
        return customInfo.type == "vehicle"
    end
    return false
end

function getElementCustomModel(element)
    assert(isElement(element), "Invalid element passed: " .. tostring(element))
    assert(isValidElement(element), "Invalid element type passed: " .. getElementType(element))
    local tbl = newmodelsUtils.getSharedElementModelsTbl()
    return tbl[element]
end

local IDS_PEDS = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312 }
local IDS_VEHICLES = { 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433, 434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565, 566, 567, 568, 569, 570, 571, 572, 573, 574, 575, 576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602, 603, 604, 605, 606, 607, 608, 609, 610, 611 }

newmodelsUtils.isDefaultObjectID = function(id)
    -- check if id is clothing component
    --   https://wiki.multitheftauto.com/wiki/Clothing_Component_IDs
    --   https://github.com/multitheftauto/mtasa-blue/blob/master/Client/mods/deathmatch/logic/CModelNames.h#L11
    if id >= 30000 and id <= 30541 then
        return false
    end
    -- check if outside object id range
    if id < 321 or id > 18630 then
        return false
    end
    -- check if ids are unused/reserved for other purposes
    if id >= 374 and id <= 614 then
        return false
    end
    if id >= 11682 and id <= 12799 then
        return false
    end
    if id >= 15065 and id <= 15999 then
        return false
    end
    return true
end

function isDefaultID(elementType, id)
    id = tonumber(id)
    if not id then return false end
    if not elementType then
        -- Check all IDs
        if newmodelsUtils.isDefaultObjectID(id) then
            return true
        end
        for _, id2 in pairs(IDS_PEDS) do
            if id2 == id then
                return true
            end
        end
        for _, id2 in pairs(IDS_VEHICLES) do
            if id2 == id then
                return true
            end
        end
    elseif elementType == "ped" or elementType == "player" then
        for _, id2 in pairs(IDS_PEDS) do
            if id2 == id then
                return true
            end
        end
    elseif elementType == "object" or elementType == "pickup" then
        return newmodelsUtils.isDefaultObjectID(id)
    elseif elementType == "vehicle" then
        for _, id2 in pairs(IDS_VEHICLES) do
            if id2 == id then
                return true
            end
        end
    end
    return false
end

function isValidElement(element)
    local elementType = getElementType(element)
    for _, elementType2 in pairs(VALID_ELEMENT_TYPES) do
        if elementType == elementType2 then
            return true
        end
    end
    return false
end
function getValidElementTypes()
    return VALID_ELEMENT_TYPES
end

newmodelsUtils.setElementResource = function(element, theResource)
    if isElement(element) then
        if not isElement(theResource) then theResource = resource end
        if type(newmodelsUtils.resources[theResource]) ~= "table" then
            newmodelsUtils.resources[theResource] = {}
        end
        table.insert(newmodelsUtils.resources[theResource], element)
        local dynRoot = getResourceDynamicElementRoot(theResource)
        if dynRoot then
            setElementParent(element, dynRoot)
        end
    end
end

function getBaseModelIdFromCustomModelId(id)
    local customInfo = newmodelsUtils.getSharedCustomModelsTbl()[id]
    if customInfo then
        return customInfo.baseModel
    end
    return id
end

newmodelsUtils.createElementWithModel = function(elementType, modelid, ...)
    if elementType == "object" then
        return createObjectMTA(modelid, ...)
    elseif elementType == "vehicle" then
        return createVehicleMTA(modelid, ...)
    elseif elementType == "ped" then
        return createPedMTA(modelid, ...)
    elseif elementType == "pickup" then
        -- Special
        local x, y, z, respawnTime, ammo = unpack({ ... })
        return createPickupMTA(x, y, z, 3, modelid, respawnTime, ammo)
    end
    return false
end

newmodelsUtils.createElementSafe = function(elementType, id, ...)
    local baseModel = getBaseModelIdFromCustomModelId(id)
    local element = newmodelsUtils.createElementWithModel(elementType, baseModel, ...)
    if not element then
        return false
    end
    if id ~= baseModel then
        -- Custom model
        newmodelsUtils.setElementCustomModel(element, id)
    end
    return element
end

function createObject(id, ...)
    assert(type(id) == "number", "Invalid model ID passed: " .. tostring(id))
    local object = newmodelsUtils.createElementSafe("object", id, ...)
    newmodelsUtils.setElementResource(object, sourceResource)
    return object
end

function createVehicle(id, ...)
    assert(type(id) == "number", "Invalid model ID passed: " .. tostring(id))
    local vehicle = newmodelsUtils.createElementSafe("vehicle", id, ...)
    newmodelsUtils.setElementResource(vehicle, sourceResource)
    return vehicle
end

function getVehicleType(id)
    local customModelInfo = newmodelsUtils.getSharedCustomModelsTbl()[id]
    if customModelInfo then
        return getVehicleTypeMTA(customModelInfo.baseModel)
    end
    return getVehicleTypeMTA(id)
end

function createPed(id, ...)
    assert(type(id) == "number", "Invalid model ID passed: " .. tostring(id))
    local ped = newmodelsUtils.createElementSafe("ped", id, ...)
    newmodelsUtils.setElementResource(ped, sourceResource)
    return ped
end

-- Special behavior for pickups
function createPickup(x, y, z, theType, id, respawnTime, ammo)
    local pickup
    theType = tonumber(theType)
    if theType and theType == 3 then
        assert(type(id) == "number", "Invalid model ID passed: " .. tostring(id))
        pickup = newmodelsUtils.createElementSafe("pickup", id, x, y, z, respawnTime, ammo)
    else
        pickup = createPickupMTA(x, y, z, theType, id, respawnTime, ammo)
    end
    newmodelsUtils.setElementResource(pickup, sourceResource)
    return pickup
end

-- Special behavior for pickups
-- PS. You can't set element model on a pickup
function setPickupType(thePickup, theType, id, ammo)
    assert(isElement(thePickup), "Invalid element passed: " .. tostring(thePickup))
    local elementType = getElementType(thePickup)
    assert(elementType == "pickup", "Invalid element type passed: " .. tostring(elementType))
    assert(type(id) == "number", "Invalid model ID passed: " .. tostring(id))
    theType = tonumber(theType)
    if theType and theType == 3 then
        local baseModel = getBaseModelIdFromCustomModelId(id)
        if id ~= baseModel then
            -- Custom model
            newmodelsUtils.setElementCustomModel(thePickup, id)
            return true
        end
    end

    newmodelsUtils.setElementCustomModel(thePickup, nil)
    return setPickupTypeMTA(thePickup, theType, id, ammo)
end

-- Returns a custom model ID (if custom) or a default model ID (if default)
function getElementModel(element)
    assert(isElement(element), "Invalid element passed: " .. tostring(element))
    assert(isValidElement(element), "Invalid element type passed: " .. getElementType(element))
    return getElementCustomModel(element) or getElementModelMTA(element)
end

function getElementBaseModel(element)
    if not isClientsideScript then
        return getElementModelMTA(element)
    end
    local customModel = getElementCustomModel(element)
    if not customModel then
        return getElementModelMTA(element)
    end
    local customModelInfo = newmodelsUtils.getSharedCustomModelsTbl()[customModel]
    return customModelInfo and customModelInfo.baseModel or nil
end

function getCustomModelName(id)
    assert(type(id) == "number", "Bad argument @ getCustomModelName [expected number at argument 1, got " .. type(id) .. "]")
    local customInfo = newmodelsUtils.getSharedCustomModelsTbl()[id]
    return customInfo and customInfo.name or nil
end

-- PS. You can't set element model on a pickup
function setElementModel(element, id)
    assert(isElement(element), "Invalid element passed: " .. tostring(element))
    assert(isValidElement(element), "Invalid element type passed: " .. getElementType(element))
    assert(tonumber(id), "Non-number ID passed")

    local baseModel = getBaseModelIdFromCustomModelId(id)
    local currBaseModel = getElementModelMTA(element)
    if currBaseModel ~= baseModel then
        -- Change modal normally
        setElementModelMTA(element, baseModel)
    else
        -- Force a refresh
        setElementModelMTA(element, 0)
        setElementModelMTA(element, baseModel)
    end

    return newmodelsUtils.setElementCustomModel(element, (id ~= baseModel) and id or nil)
end

if not isClientsideScript then
    -- Sets the skin ID after spawning to re-apply custom model on player
    function spawnPlayer(thePlayer, x, y, z, rotation, skinId, ...)
        local success = spawnPlayerMTA(thePlayer, x, y, z, rotation, getBaseModelIdFromCustomModelId(skinId), ...)
        if success then
            setElementModel(thePlayer, skinId)
        end
        return success
    end
end

newmodelsUtils.handleResourceStop = function(stoppedRes)
    if newmodelsUtils.resources[stoppedRes] then
        for i = 1, #newmodelsUtils.resources[stoppedRes] do
            local element = newmodelsUtils.resources[stoppedRes][i]
            if isElement(element) then
                destroyElement(element)
            end
        end
    end
end
if isClientsideScript then
    addEventHandler("onClientResourceStop", root, newmodelsUtils.handleResourceStop)
else
    addEventHandler("onResourceStop", root, newmodelsUtils.handleResourceStop)
end
