-- !! THIS SCRIPT IS ENTIRELY EXPORTED !!

local isClientsideScript = localPlayer ~= nil

VALID_ELEMENT_TYPES = { "vehicle", "ped", "player", "object", "pickup" }

local resources = {}

_createObject = createObject
_createVehicle = createVehicle
_getVehicleType = getVehicleType
_createPed = createPed
_createPickup = createPickup
_setPickupType = setPickupType

_getElementModel = getElementModel
_setElementModel = setElementModel

local IDS_PEDS = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312 }
local IDS_VEHICLES = { 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433, 434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565, 566, 567, 568, 569, 570, 571, 572, 573, 574, 575, 576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602, 603, 604, 605, 606, 607, 608, 609, 610, 611 }

local function isDefaultObjectID(id)
    if id < 321 or id > 18630 then
        return false
    end
    -- exclude unused/reserved for other purposes IDs
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
    if not elementType then -- check all IDs
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
        return isDefaultObjectID(id)
    else
        if elementType == "ped" or elementType == "player" then
            for _, id2 in pairs(IDS_PEDS) do
                if id2 == id then
                    return true
                end
            end
        elseif elementType == "object" or elementType == "pickup" then
            return isDefaultObjectID(id)
        elseif elementType == "vehicle" then
            for _, id2 in pairs(IDS_VEHICLES) do
                if id2 == id then
                    return true
                end
            end
        end
    end
    return false
end

-- Variable is unused, it is only necessary for backwards compatibility
function getCustomModelDataKey(elementOrElementType)
    return "newmodels_reborn:customModel"
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

local function setElementResource(element, theResource)
    if isElement(element) then
        theResource = theResource or resource
        if type(resources[theResource]) ~= "table" then
            resources[theResource] = {}
        end
        table.insert(resources[theResource], element)
        local dynRoot = getResourceDynamicElementRoot(theResource)
        if dynRoot then
            setElementParent(element, dynRoot)
        end
    end
end

function getBaseModelIdFromCustomModelId(id)
    local customInfo = customModels[id]
    if customInfo then
        return customInfo.baseModel
    end
    return id
end

local function createElementWithModel(elementType, modelid, ...)
    if elementType == "object" then
        return _createObject(modelid, ...)
    elseif elementType == "vehicle" then
        return _createVehicle(modelid, ...)
    elseif elementType == "ped" then
        return _createPed(modelid, ...)
    elseif elementType == "pickup" then
        -- Special
        local x, y, z, respawnTime, ammo = unpack({ ... })
        return _createPickup(x, y, z, 3, modelid, respawnTime, ammo)
    end
    return false
end

local function createElementSafe(elementType, id, ...)
    local baseModel = getBaseModelIdFromCustomModelId(id)
    local element = createElementWithModel(elementType, baseModel, ...)
    if not element then
        return false
    end
    if baseModel ~= id then
        setElementData(element, getCustomModelDataKey(elementType), id, not isClientsideScript)
    end
    return element
end

function createObject(id, ...)
    assert(type(id) == "number", "Invalid model ID passed: " .. tostring(id))
    local object = createElementSafe("object", id, ...)
    setElementResource(object, sourceResource)
    return object
end

function createVehicle(id, ...)
    assert(type(id) == "number", "Invalid model ID passed: " .. tostring(id))
    local vehicle = createElementSafe("vehicle", id, ...)
    setElementResource(vehicle, sourceResource)
    return vehicle
end

function getVehicleType(id)
    if customModels[id] then
        return _getVehicleType(customModels[id].baseModel)
    end
    return _getVehicleType(id)
end

function createPed(id, ...)
    assert(type(id) == "number", "Invalid model ID passed: " .. tostring(id))
    local ped = createElementSafe("ped", id, ...)
    setElementResource(ped, sourceResource)
    return ped
end

-- Special behavior for pickups
function createPickup(x, y, z, theType, id, respawnTime, ammo)
    local pickup
    theType = tonumber(theType)
    if theType and theType == 3 then
        assert(type(id) == "number", "Invalid model ID passed: " .. tostring(id))
        pickup = createElementSafe("pickup", id, x, y, z, respawnTime, ammo)
    else
        pickup = _createPickup(x, y, z, theType, id, respawnTime, ammo)
    end
    setElementResource(pickup, sourceResource)
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
        if baseModel ~= id then
            setElementData(thePickup, getCustomModelDataKey("pickup"), id, not isClientsideScript)
            return true
        end
    end

    setElementData(thePickup, getCustomModelDataKey("pickup"), nil, not isClientsideScript)
    return _setPickupType(thePickup, theType, id, ammo)
end

-- Returns a custom model ID (if custom) or a default model ID (if default)
function getElementModel(element)
    assert(isElement(element), "Invalid element passed: " .. tostring(element))
    assert(isValidElement(element), "Invalid element type passed: " .. getElementType(element))
    return getElementData(element, getCustomModelDataKey(element)) or _getElementModel(element)
end

-- PS. You can't set element model on a pickup
function setElementModel(element, id)
    assert(isElement(element), "Invalid element passed: " .. tostring(element))
    assert(isValidElement(element), "Invalid element type passed: " .. getElementType(element))
    assert(tonumber(id), "Non-number ID passed")
    local baseModel = getBaseModelIdFromCustomModelId(id)
    local currModel = _getElementModel(element)
    if currModel ~= baseModel then
        _setElementModel(element, baseModel)
    end

    if baseModel ~= id then
        setElementData(element, getCustomModelDataKey(element), id, not isClientsideScript)
    else
        setElementData(element, getCustomModelDataKey(element), nil, not isClientsideScript)
    end

    return true
end

local function handleResourceStop(stoppedRes)
    if resources[stoppedRes] then
        for i = 1, #resources[stoppedRes] do
            local element = resources[stoppedRes][i]
            if isElement(element) then
                destroyElement(element)
            end
        end
    end
end
if isClientsideScript then
    addEventHandler("onClientResourceStop", root, handleResourceStop)
else
    addEventHandler("onResourceStop", root, handleResourceStop)
end
