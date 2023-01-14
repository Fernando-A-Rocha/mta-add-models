local isClient = isElement(localPlayer)
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