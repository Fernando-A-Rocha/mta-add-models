local trailers = {
	[606]="Baggage Trailer (Covered)", [607]="Baggage Trailer (Uncovered)", [610]="Farm Trailer", [611]="Street Clean - Trailer",
	[584]="Petrol Trailer", [608]="Stairs", [435]="Cargo Trailer 1", [450]="Cargo Trailer 2", [591]="Cargo Trailer 3"
}

local getVehicleNameFromModelMTA = getVehicleNameFromModel
function getVehicleNameFromModel(id, element)
	id = getElementData(element, newmodelsKey['vehicle']) or id
	if not id then return "" end
	local isCustom, mod, customElementType = exports.newmodels:isCustomModID(id)
	if isCustom then
		return mod.name
	end
	local name = getVehicleNameFromModelMTA(id) or ""
	if #name > 0 then return name end
	return trailers[id] or ""
end

-- gets a friendly name from a category ID
local nameFromCategoryID = {
	skinID = function(ID, element)
		return getPedNameFromModel(tonumber(ID), element)
	end,
	objectID = function(ID, element)
		return getObjectNameFromModel ( tonumber(ID), element)
	end,
	vehicleID = function(ID, element)
		return getVehicleNameFromModel(tonumber(ID), element)
	end,
	weaponID = function(ID)
		return getWeaponNameFromID ( tonumber(ID) )
	end,
	markerType = function(ID)
		return ID
	end,
	pickupType = function(ID)
		local IDAsNumber = tonumber(ID)
		if IDAsNumber then
			return getWeaponNameFromID(IDAsNumber)
		else
			return ID
		end
	end,
}

-- assigns a new unique ID to an element
function assignID ( theElement )
	local creatorResource = edf.edfGetCreatorResource(theElement)
	if creatorResource == edf.res then
		creatorResource = resource
	end

	local elementType = getElementType( theElement )
	local elementDefinition = loadedEDF[creatorResource].elements[elementType]
	local elementID = getElementID( theElement )

	-- if it doesn't have an ID or it isn't unique,
	if not ( elementID and getElementByID( elementID ) == theElement ) then
		-- prepare the ID string. Append the element type first,
		local idString = elementType

		-- then all category-based properties' values' names,
		if elementDefinition then
			for dataField, dataDefinition in pairs( elementDefinition.data ) do
				local nameGetter = nameFromCategoryID[dataDefinition.datatype]
				if nameGetter then
					local dataValue = edf.edfGetElementProperty(theElement, dataField)
					local valueName = nameGetter(dataValue, theElement)
					if valueName then
						idString = idString .. " ("..tostring(valueName)..")"
					end
				end
			end
		end

		-- and lastly, find an unused index, and set the ID
		local i = 1
		while true do
			local newID = idString .. " ("..i..")"
			if getElementByID ( newID ) == false then
				setElementID( theElement, newID )
				setElementData( theElement, "id", newID )
				setElementData( theElement, "me:ID", newID )
				setElementData( theElement, "me:autoID", true )
				break
			else
				i = i + 1
			end
		end
	end
end
