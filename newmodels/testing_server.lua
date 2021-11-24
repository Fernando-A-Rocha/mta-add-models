--[[
	Author: Fernando

	testing_server.lua

	Commands:
		/myskin
		/makeped
		/makeobject
		/makevehicle
		/listmods
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


function mySkinCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Skin ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	local elementType = "player"
	if isCustomModID(id) then

		local success, reason = setCustomElementModel(thePlayer, elementType, id)
		if not success then
			outputChatBox("Failed to set your custom skin: "..reason, thePlayer, 255,0,0)
		else
			outputChatBox("Set your skin to custom ID "..id, thePlayer, 0,255,0)
		end

	elseif isDefaultID(elementType, id) then
		outputChatBox("Set your skin to default ID "..id, thePlayer, 0,255,0)
		setElementModel(thePlayer, id)
	else
		outputChatBox("Skin ID "..id.." doesn't exist", thePlayer,255,0,0)
	end
end
addCommandHandler("myskin", mySkinCmd, false, false)

function pedSkinCmd(thePlayer, cmd, id)

	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Skin ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	local elementType = "ped"
	if isCustomModID(id) or isDefaultID(elementType, id) then


		local x,y,z = getElementPosition(thePlayer)
		local rx,ry,rz = getElementRotation(thePlayer)
		local int,dim = getElementInterior(thePlayer), getElementDimension(thePlayer)

		local thePed = createPed(1, x,y,z)
		if not thePed then
			return outputChatBox("Error spawning ped", thePlayer, 255,0,0)
		end
		setElementInterior(thePed, int)
		setElementDimension(thePed, dim)
		setElementRotation(thePed, rx,ry,rz, "default",true)

		if isDefaultID(elementType, id) then
			outputChatBox("Created ped with default ID "..id, thePlayer, 0,255,0)
			setElementModel(thePed, id)
			return
		end

		local success, reason = setCustomElementModel(thePed, elementType, id)
		if not success then
			destroyElement(thePed)
			return outputChatBox("Failed to set ped custom skin: "..reason, thePlayer, 255,0,0)
		end

		outputChatBox("Created ped with custom ID "..id, thePlayer, 0,255,0)
	else
		outputChatBox("Skin ID "..id.." doesn't exist", thePlayer,255,0,0)
	end
end
addCommandHandler("makeped", pedSkinCmd, false, false)

function objectModelCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Object ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	local elementType = "object"
	if isCustomModID(id) or isDefaultID(elementType, id) then

		local x,y,z = getElementPosition(thePlayer)
		local rx,ry,rz = getElementRotation(thePlayer)
		local int,dim = getElementInterior(thePlayer), getElementDimension(thePlayer)

		local theObject = createObject(1337, x,y,z)
		if not theObject then
			return outputChatBox("Error spawning object", thePlayer, 255,0,0)
		end
		setElementInterior(theObject, int)
		setElementDimension(theObject, dim)
		setElementRotation(theObject, rx,ry,rz)

		if isDefaultID(elementType, id) then
			outputChatBox("Created object with default ID "..id, thePlayer, 0,255,0)
			setElementModel(theObject, id)
			return
		end

		local success, reason = setCustomElementModel(theObject, elementType, id)
		if not success then
			destroyElement(theObject)
			return outputChatBox("Failed to set object custom ID: "..reason, thePlayer, 255,0,0)
		end

		outputChatBox("Created object with custom ID "..id, thePlayer, 0,255,0)
		setElementPosition(thePlayer, x,y,z+4)
	else
		outputChatBox("Object ID "..id.." doesn't exist", thePlayer,255,0,0)
	end
end
addCommandHandler("makeobject", objectModelCmd, false, false)


function makeVehicleCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Vehicle ID]", thePlayer, 255,194,14)
	end
	
	id = tonumber(id)

	local elementType = "vehicle"
	if isCustomModID(id) or isDefaultID(elementType, id) then

		local x,y,z = getElementPosition(thePlayer)
		local rx,ry,rz = getElementRotation(thePlayer)
		local int,dim = getElementInterior(thePlayer), getElementDimension(thePlayer)

		local theVehicle = createVehicle(400, x,y,z)
		if not theVehicle then
			return outputChatBox("Error spawning vehicle", thePlayer, 255,0,0)
		end
		setElementInterior(theVehicle, int)
		setElementDimension(theVehicle, dim)
		setElementRotation(theVehicle, rx,ry,rz)

		if isDefaultID(elementType, id) then
			outputChatBox("Created vehicle with default ID "..id, thePlayer, 0,255,0)
			setElementModel(theVehicle, id)
			return
		end

		local success, reason = setCustomElementModel(theVehicle, elementType, id)
		if not success then
			destroyElement(theVehicle)
			return outputChatBox("Failed to set vehicle custom ID: "..reason, thePlayer, 255,0,0)
		end

		outputChatBox("Created vehicle with custom ID "..id, thePlayer, 0,255,0)
		
		setTimer(function()
			if getPedOccupiedVehicle(thePlayer) then
				removePedFromVehicle(thePlayer)
				setTimer(warpPedIntoVehicle, 500, 1, thePlayer, theVehicle)
			else
				warpPedIntoVehicle(thePlayer, theVehicle)
			end
		end, 1000, 1)

	elseif base_id then
		outputChatBox("Vehicle ID "..base_id.." doesn't exist (for base ID)", thePlayer,255,0,0)
	else
		outputChatBox("Vehicle ID "..id.." doesn't exist", thePlayer,255,0,0)
	end
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