--[[
	Author: https://github.com/Fernando-A-Rocha

	shared.lua

	TODO
]]

_getElementModel = getElementModel
_setElementModel = setElementModel
_createObject = createObject
_createVehicle = createVehicle
_createPed = createPed
_createPickup = createPickup
_setPickupType = setPickupType
local thisResource = getThisResource()
local resources = {}
local isClientFile = isElement(localPlayer)
local dataNames = {
	['object'] = exports.newmodels:getDataNameFromType('object'),
	['vehicle'] = exports.newmodels:getDataNameFromType('vehicle'),
	['ped'] = exports.newmodels:getDataNameFromType('ped'),
	['player'] = exports.newmodels:getDataNameFromType('player'),
	['pickup'] = exports.newmodels:getDataNameFromType('pickup'),
}
local baseDataName = exports.newmodels:getBaseModelDataName()

function setElementResource(element, resource)
	if isElement(element) then
		resource = resource or thisResource
		if type(resources[resource]) ~= "table" then
			resources[resource] = {}
		end
		table.insert(resources[resource], element)
		setElementParent(element, getResourceDynamicElementRoot(resource) )
	end
end

local function outputCustomError(errorCode)
	if errorCode == "INVALID_MODEL" then
		outputDebugString("[newmodels-engine] ID "..id.." doesn't exist", 4, 255,200,0)
	elseif errorCode == "WRONG_MOD" then
		outputDebugString("[newmodels-engine] Mod ID "..id.." is not a "..elementType.." model", 4, 255,200,0)
	else
		outputDebugString("[newmodels-engine] Unknown error", 4, 255,200,0)
	end
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
		local x, y, z, respawnTime, ammo = unpack({...})
		return _createPickup(x, y, z, 3, modelid, respawnTime, ammo)
	end
	return false
end

local function createElementSafe(elementType, id, ...)

	local baseModel, isCustom = exports.newmodels:checkModelID(id, elementType)
	if tonumber(baseModel) then
		
		local element = createElementWithModel(elementType, baseModel, ...)
		if not isElement(element) then
			return false
		end

		if isCustom then
			setElementData(element, dataNames[elementType], id, not isClientFile)
			setElementData(element, baseDataName, baseModel, not isClientFile)
		end
		
		return element
	end

	outputCustomError(baseModel)
	return false
end

function createObject(id, ...)
	assert(type(id)=="number", "Invalid model ID passed: "..tostring(id))
	local object = createElementSafe("object", id, ...)
	setElementResource(object, sourceResource)
	return object
end

function createVehicle(id, ...)
	assert(type(id)=="number", "Invalid model ID passed: "..tostring(id))
	local vehicle = createElementSafe("vehicle", id, ...)
	setElementResource(vehicle, sourceResource)
	return vehicle
end

function createPed(id, ...)
	assert(type(id)=="number", "Invalid model ID passed: "..tostring(id))
	local ped = createElementSafe("ped", id, ...)
	setElementResource(ped, sourceResource)
	return ped
end

-- Special behavior for pickups
-- PS. You can't set & get element model on a pickup
function createPickup(x, y, z, theType, id, respawnTime, ammo)
	local pickup
	theType = tonumber(theType)
	if theType and theType == 3 then
		assert(type(id)=="number", "Invalid model ID passed: "..tostring(id))
		pickup = createElementSafe("pickup", id, x, y, z, respawnTime, ammo)
	else
		pickup = _createPickup(x, y, z, theType, id, respawnTime, ammo)
	end
	setElementResource(pickup, sourceResource)
	return pickup
end

-- Special behavior for pickups
-- PS. You can't set & get element model on a pickup
function setPickupType(thePickup, theType, id, ammo)
    assert(isElement(thePickup), "Invalid element passed: "..tostring(thePickup))
    local elementType = getElementType(thePickup)
    assert(elementType == "pickup",
        "Invalid element type passed: "..tostring(elementType))
	assert(type(id)=="number", "Invalid model ID passed: "..tostring(id))
	local dataName = dataNames["pickup"]
	theType = tonumber(theType)
	if theType and theType == 3 then
		setElementData(thePickup, dataName, id, not isClientFile)
		return true
	else
		setElementData(element, dataName, nil, not isClientFile)
		return _setPickupType(thePickup, theType, id, ammo)
	end
end

-- Returns a custom model ID (if custom) or a default model ID (if default)
-- PS. You can't set & get element model on a pickup
function getElementModel(element)
	assert(isElement(element), "Invalid element passed: "..tostring(element))
	local et = getElementType(element)
	assert((et == "object" or et == "vehicle" or et == "ped" or et == "player"),
		"Invalid element type passed: "..tostring(et))
	return getElementData(element, dataNames[getElementType(element)]) or _getElementModel(element)
end

-- PS. You can't set & get element model on a pickup
function setElementModel(element, id)
	assert(isElement(element), "Invalid element passed: "..tostring(element))
	local elementType = getElementType(element)
	assert((elementType == "ped" or elementType == "player" or elementType == "object" or elementType == "vehicle"),
		"Invalid element type passed: "..tostring(elementType))
	assert(tonumber(id), "Non-number ID passed")
	local dataName = dataNames[elementType]

	local baseModel, isCustom = exports.newmodels:checkModelID(id, elementType)
	if not tonumber(baseModel) then
		outputCustomError(baseModel)
		return false
	end
	
	local currModel = _getElementModel(element)
	if currModel ~= baseModel then
		_setElementModel(element, baseModel)
	end

	local syncData = not isElement(localPlayer)

	if isCustom then
		setElementData(element, baseDataName, mod.base_id, syncData)
		setElementData(element, dataName, id, syncData)
	
	elseif currModel == baseModel then
		setElementData(element, baseDataName, nil, syncData)
		setElementData(element, dataName, nil, syncData)
	end

	return true
end

function handleResourceStop(stoppedRes)
	if resources[stoppedRes] then
		for i=1,#resources[stoppedRes] do
			local element = resources[stoppedRes][i]
			if isElement(element) then
				destroyElement(element)
			end
		end
	end
end

if isClientFile then
	addEventHandler("onClientResourceStop", root, handleResourceStop)
else
	addEventHandler("onResourceStop", root, handleResourceStop)
end
