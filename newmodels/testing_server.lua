--[[
	Author: https://github.com/Fernando-A-Rocha

	testing_server.lua

	Commands:
		/myskin
		/makeped
		/makeobject
		/makevehicle
		/listmods
		/newmodels
]]

---------------------------- TESTING PURPOSES ONLY BELOW ----------------------------
------------------- YOU CAN REMOVE THE FOLLOWING FROM THE RESOURCE ------------------

-- [Optional] Start/Stop Messages:
if START_STOP_MESSAGES then

	addEventHandler( "onResourceStart", resourceRoot, -- startup message
	function (startedResource)
		local version = getResourceInfo(startedResource, "version") or false
		outputChatBox("#ffc175[mta-add-models] #ffffff"..resName..(version and (" "..version) or ("")).." #ffc175started", root,255,255,255, true)
	end)
	addEventHandler( "onResourceStop", resourceRoot, -- startup message
	function (stoppedResource)
		local version = getResourceInfo(stoppedResource, "version") or false
		outputChatBox("#ffc175[mta-add-models] #ababab"..resName..(version and (" "..version) or ("")).." #ffc175stopped", root,255,255,255, true)
	end)
end

addCommandHandler("newmodels", function(thePlayer)
		local version = getResourceInfo(getThisResource(), "version") or false
		outputChatBox("#ffc175[mta-add-models] #ffffff"..resName..(version and (" "..version) or ("")).." #ffc175is loaded", thePlayer, 255, 255, 255, true)
end, false,false)

function mySkinCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Skin ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	local elementType = "ped"

	local baseModel = id
	local isCustom, mod, modType = isCustomModID(id)
	if isCustom then
		if not (modType == "ped" or modType == "player") then
			return outputChatBox("Mod ID "..id.." is not a ped skin", thePlayer,255,0,0)
		end
		baseModel = mod.base_id
	elseif isDefaultID(elementType, id) then
		baseModel = id
	else
		return outputChatBox("Skin ID "..id.." doesn't exist", thePlayer,255,0,0)
	end

	setElementModel(thePlayer, baseModel)

	if isCustom then

		setElementData(thePlayer, dataNames[elementType], id)
		setElementData(thePlayer, baseDataName, mod.base_id)
	end

	outputChatBox("Set your skin to ID "..id..(isCustom and " (custom)" or ""), thePlayer, 0,255,0)
end
addCommandHandler("myskin", mySkinCmd, false, false)

function pedSkinCmd(thePlayer, cmd, id)

	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Skin ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	local elementType = "ped"

	local baseModel = id
	local isCustom, mod, modType = isCustomModID(id)
	if isCustom then
		if not (modType == "ped" or modType == "player") then
			return outputChatBox("Mod ID "..id.." is not a ped skin", thePlayer,255,0,0)
		end
		baseModel = mod.base_id
	elseif isDefaultID(elementType, id) then
		baseModel = id
	else
		return outputChatBox("Skin ID "..id.." doesn't exist", thePlayer,255,0,0)
	end

	local x,y,z = getElementPosition(thePlayer)
	local rx,ry,rz = getElementRotation(thePlayer)
	local int,dim = getElementInterior(thePlayer), getElementDimension(thePlayer)

	local element = createPed(baseModel, x,y,z)
	if not element then
		return outputChatBox("Error spawning ped", thePlayer, 255,0,0)
	end
	setElementInterior(element, int)
	setElementDimension(element, dim)
	setElementRotation(element, rx,ry,rz, "default",true)

	if isCustom then

		setElementData(element, dataNames[elementType], id)
		setElementData(element, baseDataName, mod.base_id)
	end

	outputChatBox("Created ped with ID "..id..(isCustom and " (custom)" or ""), thePlayer, 0,255,0)
end
addCommandHandler("makeped", pedSkinCmd, false, false)

function objectModelCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Object ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	local elementType = "object"
	
	local isCustom, mod, modType = isCustomModID(id)
	if isCustom then
		if not (modType == elementType) then
			return outputChatBox("Mod ID "..id.." is not an object model", thePlayer,255,0,0)
		end
		baseModel = mod.base_id
	elseif isDefaultID(elementType, id) then
		baseModel = id
	else
		return outputChatBox("Object ID "..id.." doesn't exist", thePlayer,255,0,0)
	end

	local x,y,z = getElementPosition(thePlayer)
	local rx,ry,rz = getElementRotation(thePlayer)
	local int,dim = getElementInterior(thePlayer), getElementDimension(thePlayer)

	local element = createObject(baseModel, x,y,z)
	if not element then
		return outputChatBox("Error spawning object", thePlayer, 255,0,0)
	end
	setElementInterior(element, int)
	setElementDimension(element, dim)
	setElementRotation(element, rx,ry,rz)
	
	setElementPosition(thePlayer, x,y,z+4)

	if isCustom then

		setElementData(element, dataNames[elementType], id)
		setElementData(element, baseDataName, mod.base_id)
	end

	outputChatBox("Created object with ID "..id..(isCustom and " (custom)" or ""), thePlayer, 0,255,0)
end
addCommandHandler("makeobject", objectModelCmd, false, false)


function makeVehicleCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Vehicle ID]", thePlayer, 255,194,14)
	end
	
	id = tonumber(id)

	local elementType = "vehicle"

	local isCustom, mod, modType = isCustomModID(id)
	if isCustom then
		if not (modType == elementType) then
			return outputChatBox("Mod ID "..id.." is not an vehicle model", thePlayer,255,0,0)
		end
		baseModel = mod.base_id
	elseif isDefaultID(elementType, id) then
		baseModel = id
	else
		return outputChatBox("Vehicle ID "..id.." doesn't exist", thePlayer,255,0,0)
	end

	local rx,ry,rz = getElementRotation(thePlayer)
	local int,dim = getElementInterior(thePlayer), getElementDimension(thePlayer)

	local x,y,z = getPositionFromElementOffset(thePlayer, 0,4,0.5)
	rz = rz + 90

	local element = createVehicle(baseModel, x,y,z)
	if not element then
		return outputChatBox("Error spawning vehicle", thePlayer, 255,0,0)
	end
	setElementInterior(element, int)
	setElementDimension(element, dim)
	setElementRotation(element, rx,ry,rz)

	if isCustom then

		setElementData(element, dataNames[elementType], id)
		setElementData(element, baseDataName, mod.base_id)
	end

	outputChatBox("Created vehicle with ID "..id..(isCustom and " (custom)" or ""), thePlayer, 0,255,0)
end
addCommandHandler("makevehicle", makeVehicleCmd, false, false)

function listModsCmd(thePlayer, cmd)

	-- outputChatBox("List of defined mods:", thePlayer,255,126,0)
	local count = 0

	for elementType, mods in pairs(modList) do
		
		if elementType ~= "player" then -- don't repeat

			-- outputChatBox(elementType.." mods:", thePlayer,255,194,100)

			for k, mod in pairs(mods) do
				-- outputChatBox("ID "..mod.id.." - "..mod.name, thePlayer,255,194,14)
				count = count + 1
			end
		end
	end

	-- outputChatBox("Total: "..count, thePlayer,255,255,255)

	triggerClientEvent(thePlayer, resName..":openTestWindow", resourceRoot, "listmods", "Total "..count.." Mods", modList)
end
addCommandHandler("listmods", listModsCmd, false, false)

-- For /makevehicle
function getPositionFromElementOffset(element,offX,offY,offZ)
	local m = getElementMatrix ( element )  -- Get the matrix
	local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]  -- Apply transform
	local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
	local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
	return x, y, z                               -- Return the transformed point
end