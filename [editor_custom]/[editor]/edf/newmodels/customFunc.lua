local isClient = isElement(localPlayer)

_createObject = createObject
_createPed = createPed
_createVehicle = createVehicle
_getElementModel = getElementModel
_setElementModel = setElementModel

newmodelsKey = {}
newmodelsKey['vehicle'] = exports.newmodels:getDataNameFromType('vehicle')
newmodelsKey['object'] = exports.newmodels:getDataNameFromType('object')
newmodelsKey['ped'] = exports.newmodels:getDataNameFromType('ped')

function isCustomModID(elementType, modelid)
	local isCustom, mod, customElementType = exports.newmodels:isCustomModID(modelid)
	if isCustomModID and customElementType == elementType then
		return true
	elseif isCustomModID and customElementType == "player" and elementType == "ped" then
		return true
	else
		return false
	end
end

function getElementModel(element)
	if isElement(element) then
		return exports.newmodels:getBaseModel(element)
	end
	return false
end

function setElementModel(element, modelid)
	if isElement(element) then
		local elementType = getElementType(element)
		if elementType == 'vehicle' then
			if exports.newmodels:isDefaultID(elementType, modelid) then
				_setElementModel(element, modelid)
			elseif isCustomModID(elementType, modelid) then
				setElementData(element, newmodelsKey[elementType], modelid)
			end
		elseif elementType == 'ped' then
			if exports.newmodels:isDefaultID(elementType, modelid) then
				_setElementModel(element, modelid)
			elseif isCustomModID(elementType, modelid) then
				setElementData(element, newmodelsKey[elementType], modelid)
			end
		elseif elementType == 'object' then
			if exports.newmodels:isDefaultID(elementType, modelid) then
				_setElementModel(element, modelid)
			elseif isCustomModID(elementType, modelid) then
				setElementData(element, newmodelsKey[elementType], modelid)
			end
		end
	end
end

function createObject(modelid, x, y, z, rot, synced)
	if exports.newmodels:isDefaultID('object', modelid) then
		return _createObject(modelid, x, y, z, rot, synced)
	elseif isCustomModID('object', modelid) then
		local object = _createObject(1343, x, y, z, rot, synced)
		setElementData(object, newmodelsKey['object'], modelid, not isClient)
		return object
	else
		return _createObject(1343, x, y, z, rot, synced)
	end
end

function createPed(modelid, x, y, z, rot, synced)
	if exports.newmodels:isDefaultID('ped', modelid) then
		return _createPed(modelid, x, y, z, rot, synced)
	elseif isCustomModID('ped', modelid) then
		local ped = _createPed(0, x, y, z, rot, synced)
		setElementData(ped, newmodelsKey['ped'], modelid, not isClient)
		return ped
	else
		return _createPed(0, x, y, z, rot, synced)
	end
end

function createVehicle(modelid, x, y, z, rx, ry, rz, numberplate, bDirection, variant1, variant2)
	if exports.newmodels:isDefaultID('vehicle', modelid) then
		return _createVehicle(modelid, x, y, z, rx, ry, rz, numberplate, bDirection, variant1, variant2)
	elseif isCustomModID('vehicle', modelid) then
		local veh = _createVehicle(400, x, y, z, rx, ry, rz, numberplate, bDirection, variant1, variant2)
		setElementData(veh, newmodelsKey['vehicle'], modelid, not isClient)
		return veh
	else
		return _createVehicle(400, x, y, z, rx, ry, rz, numberplate, bDirection, variant1, variant2)
	end
end