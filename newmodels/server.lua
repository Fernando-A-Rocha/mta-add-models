--[[
	Author: Fernando

	server.lua

	Commands:
		/pedskin
		/myskin
		/makeobject
		/listmods

	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
]]

-- Custom events:
addEvent("newmodels:requestModList", true)


local SERVER_READY = false
local startTickCount

function getModNameFromID(elementType, id) -- [Exported - Server Version]
	if not elementType then return end
	if not tonumber(id) then return end
	if not SERVER_READY then return outputDebugString("getModNameFromID: Server not ready yet", 1) end

	local mods = modList[elementType]
	if mods then
		id = tonumber(id)

		for k,v in pairs(mods) do
			if id == v.id then
				return v.name -- found mod
			end
		end
	end
end

function fixModList()
	-- because ped mods can be applied on players too
	modList.player = modList.ped
	return true
end

function modCheckError(text)
	outputDebugString(text, 1)
	return false
end

-- verifies mapList, because people can fuck up sometimes :)
function doModListChecks()

	for elementType, name in pairs(dataNames) do
		
		if elementType ~= "player" then -- exception
			local mods1 = modList[elementType]
			if not mods1 then
				return modCheckError("Missing from modList: "..elementType.." = {},")
			end
		end
	end

	local used_ids = {}
	for elementType,mods in pairs(modList) do
		for k,mod in pairs(mods) do

			-- 1.  verify IDs
			if not tonumber(mod.id) then
				return modCheckError("Invalid mod ID '"..tostring(mod.id).."'")
			else
				if mod.id == 0 then
					return modCheckError("Invalid mod ID '"..tostring(mod.id).."', must be >0")
				end

				if isDefaultID(mod.id) then
					return modCheckError("Invalid mod ID '"..tostring(mod.id).."', must be out of the default GTA:SA and SAMP ID Range, see shared.lua isDefaultID")
				end

				for k,id in pairs(used_ids) do
					if id == mod.id then
						return modCheckError("Duplicated mod ID '"..id.."'")
					end
				end

				table.insert(used_ids, mod.id)
			end

			-- 2.  verify name
			if not mod.name or type(mod.name)~="string" then

				return modCheckError("Missing/Invalid mod name '"..tostring(mod.name).."' for mod ID "..mod.id)
			end

			-- 3.  verify path
			if not mod.path or type(mod.path)~="string" then

				return modCheckError("Missing/Invalid mod path '"..tostring(mod.path).."' for mod ID "..mod.id)
			end

			-- 4.  verify file exists
			local paths = getActualModPaths(elementType, mod.path, mod.id)
			for k, path in pairs(paths) do
				if not fileExists(path) then

					-- only check .col exists for objects which actually need it
					if (k == "col" and elementType == "object") or (k ~= "col") then

						return modCheckError("File does not exist: '"..tostring(path).."' for mod ID "..mod.id)
					end
				end
			end
		end
	end
	
	fixModList()
	return true
end

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)

	startTickCount = getTickCount()

	-- STARTUP CHECKS
	if doModListChecks() then
		SERVER_READY = true -- all checks passed
	end
end)

function sendModListWhenReady(player)
	if not isElement(player) then return end
	if not SERVER_READY then

		local now = getTickCount()
		if (now - startTickCount) > 10000 then -- waited too long and server still not ready
			outputDebugString("ABORTING - STOPPING RESOURCE as SERVER_READY==false !", 1)
			stopResource(getThisResource())
			return
		end

		-- outputDebugString(getPlayerName(player).." waiting", 0, 222, 184, 255)
		setTimer(sendModListWhenReady, 1000, 1, player)
		return
	end

	startTickCount = nil -- free memory
	triggerClientEvent(player, "newmodels:receiveModList", resourceRoot, modList)
end

function requestModList()
	if not isElement(client) then return end
	sendModListWhenReady(client)
end
addEventHandler("newmodels:requestModList", resourceRoot, requestModList)

function setElementCustomModel(element, elementType, id)
	local good, reason = verifySetModelArguments(element, elementType, id)
	if not good then
		return false, reason
	end
	local dataName = dataNames[elementType]
	setElementData(element, dataName, id)
	return true
end


-- [Optional] Messages:
local resName = getResourceName(getThisResource())

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



---------------------------- TESTING PURPOSES ONLY BELOW ----------------------------
------------------- YOU CAN REMOVE THE FOLLOWING FROM THE RESOURCE ------------------


function pedSkinCmd(thePlayer, cmd, id)

	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Skin ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	local elementType = "ped"
	if isCustomModID(elementType, id) or isDefaultID(elementType, id) then


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

		local success, reason = setElementCustomModel(thePed, elementType, id)
		if not success then
			destroyElement(thePed)
			outputChatBox("Failed to set ped custom skin: "..reason, thePlayer, 255,0,0)
		end
	else
		outputChatBox("Skin ID "..id.." doesn't exist", thePlayer,255,0,0)
	end
end
addCommandHandler("pedskin", pedSkinCmd, false, false)

function mySkinCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Skin ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	local elementType = "player"
	if isCustomModID(elementType, id) or isDefaultID(elementType, id) then

		local success, reason = setElementCustomModel(thePlayer, elementType, id)
		if not success then
			outputChatBox("Failed to set your custom skin: "..reason, thePlayer, 255,0,0)
		end
	else
		outputChatBox("Skin ID "..id.." doesn't exist", thePlayer,255,0,0)
	end
end
addCommandHandler("myskin", mySkinCmd, false, false)

function objectModelCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Object ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	local elementType = "object"
	if isCustomModID(elementType, id) or isDefaultID(elementType, id) then


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

		local success, reason = setElementCustomModel(theObject, elementType, id)
		if not success then
			destroyElement(theObject)
			outputChatBox("Failed to set object custom ID: "..reason, thePlayer, 255,0,0)
		end

		setElementPosition(thePlayer, x,y,z+4)
	else
		outputChatBox("Object ID "..id.." doesn't exist", thePlayer,255,0,0)
	end
end
addCommandHandler("makeobject", objectModelCmd, false, false)

function listModsCmd(thePlayer, cmd)

	outputChatBox("List of defined mods:", thePlayer,255,126,0)
	for elementType, mods in pairs(modList) do
		outputChatBox(elementType.." mods:", thePlayer,255,194,100)
		for k, mod in pairs(mods) do
			outputChatBox("ID "..mod.id.." - "..mod.name, thePlayer,255,194,14)
		end
	end
end
addCommandHandler("listmods", listModsCmd, false, false)

-- test 1: set wrong element data on ped
addCommandHandler("t1", function(thePlayer, cmd)

	local x,y,z = getElementPosition(thePlayer)
	local ped = createPed(0, x,y,z)
	setElementData(ped, "objectID", 20002)

end, false, false)

-- test 2: create ped, set custom skin and destroy it shortly after
addCommandHandler("t2", function(thePlayer, cmd)

	local x,y,z = getElementPosition(thePlayer)
	local ped = createPed(0, x,y,z)
	setElementData(ped, "skinID", 20002)
	outputChatBox("Destroying created ped in 5 secs, observe what happens in debug", thePlayer, 255,194,14)
	setTimer(destroyElement, 5000, 1, ped)

end, false, false)
