--[[
	Author: Fernando

	server.lua

	Commands:
		/myskin
		/makeped
		/makeobject
		/makevehicle
		/listmods

	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
--]]

-- Custom events:
addEvent("newmodels:requestModList", true)
addEvent("newmodels:resetElementModel", true)
addEvent("newmodels:updateVehicleHandling", true)

local thisRes = getThisResource()
local resName = getResourceName(thisRes)

local SERVER_READY = false
local startTickCount

 -- Vehicle specific
local savedHandlings = {}
--[[
	Goal: solve the issue of handling resetting every time the vehicle's model is changed serverside/clientside
]]
function onSetVehicleHandling( sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ... )
	if sourceResource == getThisResource() then
		return
	end

    local args = {...}
    local theVehicle, property, var = unpack(args)
    if not isElement(theVehicle) then return end
    	
    local et = getElementType(theVehicle)
    if et ~= "vehicle" then return end

	local dataName = dataNames[et]
	local id = tonumber(getElementData(theVehicle, dataName))
	if not id then
		-- not a custom vehicle
		return
	end

	if not savedHandlings[theVehicle] then
		savedHandlings[theVehicle] = {}
	end
	table.insert(savedHandlings[theVehicle], {property, var})
	-- print(theVehicle, "Added handling: ", tostring(property), tostring(var))

end
addDebugHook( "postFunction", onSetVehicleHandling, { "setVehicleHandling" })

addEventHandler( "onElementDestroy", root, 
function ()
	if getElementType(source) ~= "vehicle" then return end
	if savedHandlings[source] then
		savedHandlings[source] = nil
	end
end)

function updateVehicleHandling(element)
	local handling = savedHandlings[element]
	if handling then
	-- Only saves for custom vehicles because those are the ones that get model changed all the time,
	-- which ends up resetting the handling (everytime on setElementModel)

		local count = 0
		local count2 = 0
		for k,v in pairs(handling) do
			local property,var = unpack(v)
			if setVehicleHandling(element, property, var) then
				count = count + 1
			else
				handling[k] = nil
				count2 = count2 + 1
			end
		end

		-- print(element, "Set "..count..", deleted "..count2.." handling properties")
	end
end
addEventHandler("newmodels:updateVehicleHandling", resourceRoot, updateVehicleHandling)

_setElementModel = setElementModel
function setElementModel(element, id) -- force refresh
	local currModel = getElementModel(element)
	local data_name = dataNames[getElementType(element)]
	if currModel == id and not getElementData(element, data_name) then
		local diffModel = 1
		if currModel == 1 then diffModel = 0 end
		_setElementModel(element, diffModel)
		outputDebugString("refresh setElementModel("..tostring(element)..", "..tostring(id)..")", 3)
	end

	_setElementModel(element, id)

	if getElementType(element) == "vehicle" then -- Vehicle specific
		updateVehicleHandling(element)
	end

	return true
end

--[[
	Goal: solve the issue of element model not setting when it's already the same model serverside
	This makes it so you don't need to use the 'refresh' element model method in any resource
]]
-- OTHER RESOURCES ONLY
function onSetElementModel( sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ... )
	if sourceResource == thisRes then return end

    local args = {...}
    local element,newModel = unpack(args)
    if not isElement(element) then return end
    if not tonumber(newModel) then return end
    newModel = tonumber(newModel)
    
    oldModel = getElementModel(element)
	if oldModel and newModel and oldModel == newModel then -- force refresh
		local diffModel = 1
		if newModel == 1 then diffModel = 0 end
		if _setElementModel(element, diffModel) then
			outputDebugString("[ext] refresh setElementModel("..tostring(element)..", "..tostring(newModel)..")", 3)
			_setElementModel(element, newModel)
		end
	end

	if getElementType(element) == "vehicle" then -- Vehicle specific
		updateVehicleHandling(element)
	end

end
addDebugHook( "preFunction", onSetElementModel, { "setElementModel" })

function getModList() -- [Exported - Server Version]
	if not SERVER_READY then
		-- outputDebugString("getModDataFromID: Server not ready yet", 1)
		return
	end
	return modList
end

function getModDataFromID(id) -- [Exported - Server Version]
	if not tonumber(id) then return end
	if not SERVER_READY then
		-- outputDebugString("getModDataFromID: Server not ready yet", 1)
		return
	end

	id = tonumber(id)
	for elementType, mods in pairs(modList) do
		for k,v in pairs(mods) do
			if id == v.id then
				return v, elementType -- found mod
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


		-- 0. verify element type, can't be player as that's managed automatically (syncs 'ped')
		if elementType == "player" then
			return modCheckError("Please remove mod from modList: player = {...}, it will be added automatically to match 'ped' mods")
		end

		for k,mod in pairs(mods) do

			-- 1.  verify IDs
			if not tonumber(mod.id) then
				return modCheckError("Invalid mod ID '"..tostring(mod.id).."'")
			else
				if mod.id == 0 then
					return modCheckError("Invalid mod ID '"..tostring(mod.id).."', must be >0")
				end

				if isDefaultID(false, mod.id) then
					return modCheckError("Invalid mod ID '"..tostring(mod.id).."', must be out of the default GTA:SA and SAMP ID Range, see shared.lua isDefaultID")
				end

				for k,id in pairs(used_ids) do
					if id == mod.id then
						return modCheckError("Duplicated mod ID '"..id.."'")
					end
				end

				table.insert(used_ids, mod.id)
			end
			if not tonumber(mod.base_id) then
				return modCheckError("Invalid mod base ID '"..tostring(mod.base_id).."'")
			else
				if not isDefaultID(false, mod.base_id) then
					return modCheckError("Invalid mod base ID '"..tostring(mod.base_id).."', must be a default GTA:SA ID")
				end
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
			local paths = getActualModPaths(mod.path, mod.id)
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

addEventHandler( "onResourceStop", resourceRoot, 
function (stoppedResource, wasDeleted)


	for elementType, name in pairs(dataNames) do
		for k,el in ipairs(getElementsByType(elementType)) do
			local id = tonumber(getElementData(el, name))
			if id then
				resetElementModel(el)
			end
		end
	end
end)

addEventHandler( "onResourceStop", root, 
function (stoppedResource, wasDeleted)
	if stoppedResource == thisRes then return end

	local delCount = 0
	for elementType,mods in pairs(modList) do
		for k,mod in pairs(mods) do
			local srcRes = mod.srcRes
			if srcRes then
				local stoppedName = getResourceName(stoppedResource)
				if stoppedName == srcRes then
					-- delete mod added by resource that was just stopped
					outputDebugString("Removed "..elementType.." mod ID "..mod.id.." because resource '"..srcRes.."' stopped", 0, 211, 255, 89)
					modList[elementType][k] = nil
					delCount = delCount + 1
				end
			end
		end
	end

	if delCount > 0 then
			fixModList()
		sendModListWhenReady_ToAllPlayers()
	end
end)

local dontspamPlayers = {}
function sendModListWhenReady(player)
	if not isElement(player) then return end
	if not SERVER_READY then

		local now = getTickCount()
		if (now - startTickCount) > 10000 then -- waited too long and server still not ready
			outputDebugString("ABORTING - STOPPING RESOURCE as SERVER_READY==false !", 1)
			stopResource(thisRes)
			return
		end

		-- outputDebugString(getPlayerName(player).." waiting", 0, 222, 184, 255)
		setTimer(sendModListWhenReady, 1000, 1, player)
		return
	end

	startTickCount = nil -- free memory
	if isTimer(dontspamPlayers[player]) then killTimer(dontspamPlayers[player]) end
	dontspamPlayers[player] = setTimer(function()
		if isElement(player) then
			triggerClientEvent(player, "newmodels:receiveModList", resourceRoot, modList)
		end
		dontspamPlayers[player] = nil -- free memory
	end, 5000, 1)
end

function sendModListWhenReady_ToAllPlayers()
	for k,player in ipairs(getElementsByType("player")) do
		sendModListWhenReady(player)
	end
end

function requestModList()
	if not isElement(client) then return end
	sendModListWhenReady(client)
end
addEventHandler("newmodels:requestModList", resourceRoot, requestModList)


function resetElementModel(element, old_id)
	if not isElement(element) then return end
	local currModel = getElementModel(element)
	setElementModel(element, currModel)
	outputDebugString("Resetting model serverside for "..getElementType(element).." to ID "..currModel.." (previous ID: "..tostring(old_id)..")",0, 59, 160, 255)
end
addEventHandler("newmodels:resetElementModel", resourceRoot, resetElementModel)

function setCustomElementModel(element, et, id)

	local good, reason = verifySetModelArguments(element, et, id)
	if not good then
		return false, reason
	end

	local elementType = getElementType(element)

	local isCustom, mod, elementType2 = isCustomModID(id)
	if isCustom then

		if elementType ~= elementType2 then
			return false, "Mod ID "..id.." is not a "..elementType.." mod"
		end

		if setElementModel(element, mod.base_id) then

			local dataName = dataNames[et]
			setElementData(element, dataName, id)
		end
		
		return true
	
	else
		return false, "Not a custom model ID: "..id
	end
end

--[[
	The difference between this function and addExternalMod_CustomFilenames is that
	you pass a folder path in 'path' and it will search for ID.dff ID.txd etc
]]
function addExternalMod_IDFilenames(elementType, id, base_id, name, path) -- [Exported]

	local sourceResName = getResourceName(sourceResource)
	if sourceResName == resName then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end

	if not (type(elementType) == "string") then
		return false, "Missing/Invalid 'elementType' passed: "..tostring(elementType)
	end
	local sup,reason = isElementTypeSupported(elementType)
	if not sup then
		return false, "Invalid 'elementType' passed: "..reason
	end

	if elementType == "player" then
		elementType = "ped" -- so it can be fixed later
	end

	if not tonumber(id) then
		return false, "Missing/Invalid 'id' passed: "..tostring(id)
	end
	id = tonumber(id)

	if not tonumber(base_id) then
		return false, "Missing/Invalid 'base_id' passed: "..tostring(base_id)
	end
	base_id = tonumber(base_id)

	if not (type(name) == "string") then
		return false, "Missing/Invalid 'name' passed: "..tostring(name)
	end
	if not (type(path) == "string") then
		return false, "Missing/Invalid 'path' passed: "..tostring(path)
	end

	if string.sub(path, 1,1) ~= ":" then
		path = ":"..sourceResName.."/"..path
	end

	if isDefaultID(false, id) then
		return false, "'id' passed is a default GTA:SA ID, needs to be a new one!"
	end

	if not isDefaultID(false, base_id) then
		return false, "'base_id' passed is not a default GTA:SA ID, it needs to be!"
	end

	for elementType,mods in pairs(modList) do
		for k,mod in pairs(mods) do
			if mod.id == id then
				return false, "Duplicated 'id' passed, already exists in modList"
			end
		end
	end

	local paths = getActualModPaths(path, id)
	for k, path2 in pairs(paths) do
		if not fileExists(path2) then

			-- only check .col exists for objects which actually need it
			if (k == "col" and elementType == "object") or (k ~= "col") then

				return false, "File does not exist: '"..tostring(path2).."', check folder: '"..path.."'"
			end
		end
	end

	-- Save mod in list
	table.insert(modList[elementType], {
		id=id, base_id=base_id, path=path, name=name, srcRes=sourceResName
	})

	fixModList()
	sendModListWhenReady_ToAllPlayers()

	outputDebugString("Added "..elementType.." mod ID "..id.." located in: "..path, 0, 136, 255, 89)
	return true
end

--[[
	The difference between this function and addExternalMod_IDFilenames is that
	you pass directly individual file paths for dff, txd and col files
]]
function addExternalMod_CustomFilenames(elementType, id, base_id, name, path_dff, path_txd, path_col) -- [Exported]

	local sourceResName = getResourceName(sourceResource)
	if sourceResName == resName then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end

	if not (type(elementType) == "string") then
		return false, "Missing/Invalid 'elementType' passed: "..tostring(elementType)
	end
	local sup,reason = isElementTypeSupported(elementType)
	if not sup then
		return false, "Invalid 'elementType' passed: "..reason
	end

	if elementType == "player" then
		elementType = "ped" -- so it can be fixed later
	end

	if not tonumber(id) then
		return false, "Missing/Invalid 'id' passed: "..tostring(id)
	end
	id = tonumber(id)

	if not tonumber(base_id) then
		return false, "Missing/Invalid 'base_id' passed: "..tostring(base_id)
	end
	base_id = tonumber(base_id)

	if not (type(name) == "string") then
		return false, "Missing/Invalid 'name' passed: "..tostring(name)
	end

	local paths = {}

	if not (type(path_dff) == "string") then
		return false, "Missing/Invalid 'path_dff' passed: "..tostring(path_dff)
	end
	if string.sub(path_dff, 1,1) ~= ":" then
		path_dff = ":"..sourceResName.."/"..path_dff
	end
	paths.dff = path_dff

	if not (type(path_txd) == "string") then
		return false, "Missing/Invalid 'path_txd' passed: "..tostring(path_txd)
	end
	if string.sub(path_txd, 1,1) ~= ":" then
		path_txd = ":"..sourceResName.."/"..path_txd
	end
	paths.txd = path_txd

	if path_col then
		if (type(path_col) ~= "string") then
			return false, "Missing/Invalid 'path_col' passed: "..tostring(path_col)
		end
		if not string.sub(path_col, 1,1) ~= ":" then
			path_col = ":"..sourceResName.."/"..path_col
		end

		paths.col = path_col
	end

	if isDefaultID(false, id) then
		return false, "'id' passed is a default GTA:SA ID, needs to be a new one!"
	end

	if not isDefaultID(false, base_id) then
		return false, "'base_id' passed is not a default GTA:SA ID, it needs to be!"
	end

	for elementType,mods in pairs(modList) do
		for k,mod in pairs(mods) do
			if mod.id == id then
				return false, "Duplicated 'id' passed, already exists in modList"
			end
		end
	end
	for k, path2 in pairs(paths) do
		if not fileExists(path2) then

			-- only check .col exists for objects which actually need it
			if (k == "col" and elementType == "object") or (k ~= "col") then

				return false, "File does not exist: '"..tostring(path2).."'"
			end
		end
	end

	-- Save mod in list
	table.insert(modList[elementType], {
		-- path will be a table here, interpreted by the client differently
		id=id, base_id=base_id, path=paths, name=name, srcRes=sourceResName
	})

	fixModList()
	sendModListWhenReady_ToAllPlayers()

	outputDebugString("Added "..elementType.." mod ID "..id..": "..toJSON(paths), 0, 136, 255, 89)
	return true
end

function removeExternalMod(id) -- [Exported]

	if not tonumber(id) then
		return false, "Missing/Invalid 'id' passed: "..tostring(id)
	end
	id = tonumber(id)

	for elementType,mods in pairs(modList) do
		for k,mod in pairs(mods) do
			if mod.id == id then
				
				outputDebugString("Removed "..elementType.." mod ID "..id.." located in: "..mod.path, 0, 211, 255, 89)
			
				modList[elementType][k] = nil	
				
				fixModList()
				sendModListWhenReady_ToAllPlayers()
				
				return true
			end
		end
	end

	return false, "No mod with ID "..id.." found in modList"
end


-- [Optional] Messages:
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



---------------------------- TESTING PURPOSES ONLY BELOW ----------------------------
------------------- YOU CAN REMOVE THE FOLLOWING FROM THE RESOURCE ------------------


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

	outputChatBox("List of defined mods:", thePlayer,255,126,0)
	local count = 0

	for elementType, mods in pairs(modList) do
		
		if elementType ~= "player" then -- don't repeat

			outputChatBox(elementType.." mods:", thePlayer,255,194,100)

			for k, mod in pairs(mods) do
				outputChatBox("ID "..mod.id.." - "..mod.name, thePlayer,255,194,14)
				count = count + 1
			end
		end
	end

	outputChatBox("Total: "..count, thePlayer,255,255,255)
end
addCommandHandler("listmods", listModsCmd, false, false)

--[[
-- Get all valid default object IDs
addEventHandler( "onResourceStart", resourceRoot,
function (startedResource)

	local text = "{ "
	for i=1,20000 do
		local o = createObject(i,0,0,5)
		if o then
			text = text..i..", "
		end
	end
	local f = fileCreate("object_ids.lua")
	fileWrite(f, text)
	fileClose(f)
end)
--]]

--[[
-- Get all valid default vehicle IDs
addEventHandler( "onResourceStart", resourceRoot,
function (startedResource)

	local text = "{ "
	for i=1,20000 do
		local o = createVehicle(i,0,0,5)
		if o then
			text = text..i..", "
		end
	end
	local f = fileCreate("vehicle_ids.lua")
	fileWrite(f, text)
	fileClose(f)
end)
--]]

--[[
-- Get all valid default ped IDs (skins)
addEventHandler( "onResourceStart", resourceRoot,
function (startedResource)

	local text = "{ "
	for i=1,20000 do
		local o = createPed(i,0,0,5)
		if o then
			text = text..i..", "
		end
	end
	local f = fileCreate("ped_ids.lua")
	fileWrite(f, text)
	fileClose(f)
end)
--]]
