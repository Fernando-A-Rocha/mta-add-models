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

local function setElementModelSafe(element, id)
	local elementType = getElementType(element)
	local dataName = dataNames[elementType]

	local baseModel, isCustom = checkModelID(id, elementType)
	if not tonumber(baseModel) then
		return baseModel
	end
	
	local currModel = getElementModel(element)
	if currModel ~= baseModel then
		setElementModel(element, baseModel)
	end

	if isCustom then
		setElementData(element, baseDataName, baseModel)
		setElementData(element, dataName, id)
	
	else
		setElementData(element, baseDataName, nil)
		setElementData(element, dataName, nil)
	end

	return "OK"
end

function mySkinCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Skin ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	local result = setElementModelSafe(thePlayer, id)
	if result == "OK" then
		outputChatBox("Set your skin to ID "..id..(isCustom and " (custom)" or ""), thePlayer, 0,255,0)
	elseif result == "INVALID_MODEL" then
		outputChatBox("Skin ID "..id.." doesn't exist", thePlayer,255,0,0)
	elseif result == "WRONG_MOD" then
		outputChatBox("Mod ID "..id.." is not a player skin", thePlayer,255,0,0)
	end
end
addCommandHandler("myskin", mySkinCmd, false, false)

local function createElementWithModel(elementType, modelid, ...)
	if elementType == "object" then
		return createObject(modelid, ...)
	elseif elementType == "vehicle" then
		return createVehicle(modelid, ...)
	elseif elementType == "ped" then
		return createPed(modelid, ...)
	end
	return false
end

function createTestElement(thePlayer, elementType, id, ...)

	local baseModel, isCustom = checkModelID(id, elementType)
	if tonumber(baseModel) then
		
		local element = createElementWithModel(elementType, baseModel, ...)
		if not isElement(element) then
			outputChatBox("Error spawning "..elementType.."", thePlayer, 255,0,0)
			return
		end

		if isCustom then
			setElementData(element, dataNames[elementType], id)
			setElementData(element, baseDataName, baseModel)
		end
		
		outputChatBox("Created "..elementType.." with ID "..id..(isCustom and " (custom)" or ""), thePlayer, 0,255,0)
		return element

	elseif baseModel == "INVALID_MODEL" then
		outputChatBox("ID "..id.." doesn't exist", thePlayer,255,0,0)
	elseif baseModel == "WRONG_MOD" then
		outputChatBox("Mod ID "..id.." is not a "..elementType.." model", thePlayer,255,0,0)
	end
end

function pedSkinCmd(thePlayer, cmd, id)
	id = tonumber(id)
	if not id then
		return outputChatBox("SYNTAX: /"..cmd.." [Skin ID]", thePlayer, 255,194,14)
	end

	local x,y,z = getElementPosition(thePlayer)
	local rx,ry,rz = getElementRotation(thePlayer)
	local element = createTestElement(thePlayer, "ped", id, x,y,z, rz)
	if element then
		setElementPosition(thePlayer, x+1,y+1,z)
		setElementInterior(element, getElementInterior(thePlayer))
		setElementDimension(element, getElementDimension(thePlayer))
	end
end
addCommandHandler("makeped", pedSkinCmd, false, false)

function objectModelCmd(thePlayer, cmd, id)
	id = tonumber(id)
	if not id then
		return outputChatBox("SYNTAX: /"..cmd.." [Object ID]", thePlayer, 255,194,14)
	end
	local x,y,z = getElementPosition(thePlayer)
	local rx,ry,rz = getElementRotation(thePlayer)
	local element = createTestElement(thePlayer, "object", id, x,y,z, rx,ry,rz)
	if element then
		setElementPosition(thePlayer, x+1,y+1,z+4)
		setElementInterior(element, getElementInterior(thePlayer))
		setElementDimension(element, getElementDimension(thePlayer))
	end
end
addCommandHandler("makeobject", objectModelCmd, false, false)


function makeVehicleCmd(thePlayer, cmd, id)
	id = tonumber(id)
	if not id then
		return outputChatBox("SYNTAX: /"..cmd.." [Vehicle ID]", thePlayer, 255,194,14)
	end
	
	local x,y,z = getElementPosition(thePlayer)
	local rx,ry,rz = getElementRotation(thePlayer)
	local element = createTestElement(thePlayer, "vehicle", id, x,y,z, rx,ry,rz)
	if element then
		setElementPosition(thePlayer, x,y,z+3)
		setElementInterior(element, getElementInterior(thePlayer))
		setElementDimension(element, getElementDimension(thePlayer))
	end
end
addCommandHandler("makevehicle", makeVehicleCmd, false, false)

function listModsCmd(thePlayer, cmd)

	local count = 0
	for elementType, mods in pairs(modList) do
		if not (elementType == "player" or elementType == "pickup") then -- don't repeat
			for k, mod in pairs(mods) do
				count = count + 1
			end
		end
	end

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