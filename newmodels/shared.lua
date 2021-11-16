--[[
	Author: Fernando

	shared.lua
]]

modsFolder = "models/"

modList = {
	
	-- mod type
	ped = {

		-- file names should be ID.dff ID.txd (ID.col if it's an object)
		{id=20001, name="Mafioso 1"},
		{id=20003, name="Mafioso 2"},
		{id=20002, name="Mafioso 3"},
	}
}


dataNames = {
	ped = "skinID",
	-- vehicle = "vehicleID", -- not yet implemented
	-- object = "objectID", -- not yet implemented
}

function getDataNameType(name)
	for type,name2 in pairs(dataNames) do
		if name2 == name then
			return type
		end
	end
end

function getModNameFromID(modType, id)
	if not modType then return end
	if not tonumber(id) then return end

	local mods = modList[modType]
	if mods then
		id = tonumber(id)

		for k,v in pairs(mods) do
			if id == v.id then
				return v.name -- found mod
			end
		end
	end
end

function verifySetModArguments(element, modType, id)
	if not isElement(element) then
		return false, "Invalid element passed"
	end

	local et = getElementType(element)
	if et == "player" then et = "ped" end--so it can be recognised in the array

	local found
	for type,_ in pairs(dataNames) do
		if et == type then
			found = true
			break
		end
	end

	if not found then
		return false, et.." element type passed: not yet supported"
	end

	local dataName = dataNames[modType]
	if not dataName then
		return false, modType.." mods yet supported"
	end

	if not tonumber(id) then
		return false, "Non-number ID passed"
	end
	id = tonumber(id)

	local name = getModNameFromID(modType, id)
	if not name then
		return false, modType.." mod ID "..id.." is not defined"
	end

	return true
end