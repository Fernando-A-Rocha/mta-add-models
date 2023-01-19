local isClient = isElement(localPlayer)

_getElementModel = getElementModel
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
	if isCustomModID and
		(customElementType == elementType)
		or ((customElementType == "player" and elementType == "ped") or (customElementType == "ped" and elementType == "player"))
		or ((customElementType == "pickup" and elementType == "object") or (customElementType == "object" and elementType == "pickup"))
	then
		return true, mod
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
		if elementType == 'vehicle' or elementType == 'ped' or elementType == 'object' then
			if exports.newmodels:isDefaultID(elementType, modelid) then
				_setElementModel(element, modelid)
			else
				local isCustom, mod = isCustomModID(elementType, modelid)
				if isCustom and mod then
					setElementData(element, newmodelsKey[elementType], modelid)
				else
					outputDebugString('Invalid modelid: '..tostring(modelid)..' on '..elementType, 2)
				end
			end
		else
			_setElementModel(element, modelid)
		end
	end
end

function createObject(modelid, x, y, z, rot, synced)
	if exports.newmodels:isDefaultID('object', modelid) then
		return _createObject(modelid, x, y, z, rot, synced)
	else
		local isCustom, mod = isCustomModID('object', modelid)
		if isCustom and mod  then
			local object = _createObject(mod.base_id or 1343, x, y, z, rot, synced)
			setElementData(object, newmodelsKey['object'], modelid, not isClient)
			return object
		else
			return _createObject(1343, x, y, z, rot, synced)
		end
	end
end

function createPed(modelid, x, y, z, rot, synced)
	if exports.newmodels:isDefaultID('ped', modelid) then
		return _createPed(modelid, x, y, z, rot, synced)
	else
		local isCustom, mod = isCustomModID('ped', modelid)
		if isCustom and mod  then
			local ped = _createPed(mod.base_id or 1, x, y, z, rot, synced)
			setElementData(ped, newmodelsKey['ped'], modelid, not isClient)
			return ped
		else
			return _createPed(0, x, y, z, rot, synced)
		end
	end
end

function createVehicle(modelid, x, y, z, rx, ry, rz, numberplate, bDirection, variant1, variant2)
    if exports.newmodels:isDefaultID('vehicle', modelid) then
        return _createVehicle(modelid, x, y, z, rx, ry, rz, numberplate, bDirection, variant1, variant2)
    else
		local isCustom, mod = isCustomModID('vehicle', modelid)
		if isCustom and mod then
			local veh = _createVehicle(mod.base_id or 400, x, y, z, rx, ry, rz, numberplate, bDirection, variant1, variant2)
			setElementData(veh, newmodelsKey['vehicle'], modelid, not isClient)
			return veh
		else
			return _createVehicle(400, x, y, z, rx, ry, rz, numberplate, bDirection, variant1, variant2)
		end
	end
end