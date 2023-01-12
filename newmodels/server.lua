--[[
	Author: Fernando

	server.lua

	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
--]]

-- Custom events:
addEvent(resName..":requestModList", true)
addEvent(resName..":resetElementModel", true)
addEvent(resName..":updateVehicleProperties", true)
addEvent(resName..":kickOnDownloadsFail", true)

local SERVER_READY = false
local startTickCount

local prevent_addrem_spam = {
	add = {},
	addtimer = {},
	rem = {},
	remtimer = {},
}

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
	if not isCustomVehicle(theVehicle) then return end

	if not savedHandlings[theVehicle] then
		savedHandlings[theVehicle] = {}
	end
	table.insert(savedHandlings[theVehicle], {property, var})
	-- print(theVehicle, "Added handling: ", tostring(property), tostring(var))

end
addDebugHook( "postFunction", onSetVehicleHandling, { "setVehicleHandling" })

local savedUpgrades = {}
--[[
	Goal: solve the issue of upgrades resetting every time the vehicle's model is changed serverside/clientside
]]
function onVehicleUpgradesChanged( sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ... )
	if sourceResource == getThisResource() then
		return 
	end

	local args = {...}
	local theVehicle = unpack(args)
	if not isCustomVehicle(theVehicle) then return end

	savedUpgrades[theVehicle] = getVehicleUpgrades(theVehicle)
end
addDebugHook( "postFunction", onVehicleUpgradesChanged, { "addVehicleUpgrade", "removeVehicleUpgrade" })

addEventHandler( "onElementDestroy", root, 
function ()
	if getElementType(source) ~= "vehicle" then return end
	if savedHandlings[source] then
		savedHandlings[source] = nil
	end
	if savedUpgrades[source] then
		savedUpgrades[source] = nil
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

function updateVehicleUpgrades(element)
	local upgrades = savedUpgrades[element]
	if upgrades then
		for _, upgrade in pairs(upgrades) do
			addVehicleUpgrade(element, upgrade)			
		end
	end
end

function updateVehicleProperties(element)
	updateVehicleHandling(element)
	updateVehicleUpgrades(element)
end
addEventHandler(resName..":updateVehicleProperties", resourceRoot, updateVehicleProperties)

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
		updateVehicleProperties(element)
	end

	return true
end

--[[
	Refreshes the player model (if custom) after spawnPlayer (which you should do with CJ skin 0)
]]
addEventHandler( "onPlayerSpawn", root, 
function()
	local data_name = dataNames[getElementType(source)]
	if not data_name then return end
	local skinID = tonumber(getElementData(source, data_name))
	if skinID then
		-- refresh it
		removeElementData(source, data_name)
		setElementModel(source, 0)
		setElementData(source, data_name, skinID)
	end
end)

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
		updateVehicleProperties(element)
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

function verifyOneMod(mod, elementType, used_ids)
	coroutine.yield()

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

		for _,id in pairs(used_ids) do
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
	if (not mod.path) then

		return modCheckError("Missing mod path '"..tostring(mod.path).."' for mod ID "..mod.id)
	end
	if not (type(mod.path)=="string" or type(mod.path)=="table") then

		return modCheckError("Invalid mod path '"..tostring(mod.path).."' for mod ID "..mod.id)
	end

	-- 4.  verify files exist
	local ignoreTXD, ignoreDFF, ignoreCOL = mod.ignoreTXD, mod.ignoreDFF, mod.ignoreCOL
	local paths
	local path = mod.path
	if type(path)=="table" then
		paths = path
	else
		paths = getActualModPaths(path, mod.id)
	end
	for pathType, path2 in pairs(paths) do
		if type(pathType) ~= "string" then
			return modCheckError("Invalid path type '"..tostring(pathType).."' for mod ID "..mod.id)
		end
		if type(path2) ~= "string" then
			return modCheckError("Invalid file path '"..tostring(pathType).."' for mod ID "..mod.id)
		end
		if (not fileExists(path2)) and ((ENABLE_NANDOCRYPT) and not fileExists(path2..NANDOCRYPT_EXT)) then
			if (not ignoreTXD and pathType == "txd")
			or (not ignoreDFF and pathType == "dff")
			or ((not ignoreCOL) and elementType == "object" and pathType == "col") then

				return modCheckError("File doesn't exist: '"..tostring(path2).."' for mod ID "..mod.id)
			end
		end
	end

	return true
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

			local co = coroutine.create(verifyOneMod)
			coroutine.resume(co, mod, elementType, used_ids)

			local _, result = coroutine.resume(co)
			if not result then
				return result
			end
		end
	end
	
	fixModList()
	return true
end

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)

	startTickCount = getTickCount()

	if (STARTUP_VERIFICATIONS) then

		-- STARTUP CHECKS
		if not doModListChecks() then return end

		SERVER_READY = true -- all checks passed

	else
		SERVER_READY = true -- checks ignored
	end
		
	for k, v in ipairs(OTHER_RESOURCES) do
		local name, start, stop = v.name, v.start, v.stop
		if type(name)=="string" and start == true then
			local res = getResourceFromName(name)
			if res and getResourceState(res) == "loaded" then
				if not startResource(res) then
					outputDebugString("Failed to start resource '"..name.."' on "..resName.." res-start")
				else
					outputDebugString("Started resource '"..name.."' on "..resName.." res-start")
				end
			end
		end
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

	local willStart = {}
	for k, v in ipairs(OTHER_RESOURCES) do
		local name, start, stop = v.name, v.start, v.stop
		if type(name)=="string" then
			if start == true then
				willStart[name] = true
			end
			if stop == true then
				local res = getResourceFromName(name)
				if res and getResourceState(res) == "running" then
					if not stopResource(res) then
						outputDebugString("Failed to stop resource '"..name.."' on "..resName.." res-stop")
					else
						outputDebugString("Stopped resource '"..name.."' on "..resName.." res-stop")
					end
				end
			end
		end
	end

	local notified = {}
	for elementType,mods in pairs(modList) do
		for k,mod in pairs(mods) do
			local srcRes = mod.srcRes
			if srcRes then
				local res = getResourceFromName(srcRes)
				if res and not notified[srcRes] and not willStart[srcRes] then

					outputDebugString("Resource '"..srcRes.."' needs to be restarted because '"..resName.."' stopped", 0, 211, 255, 0)
					notified[srcRes] = true
				end
			end
		end
	end
end)

addEventHandler( "onResourceStop", root, 
function (stoppedResource, wasDeleted)
	if stoppedResource == thisRes then return end
	local stoppedResName = getResourceName(stoppedResource)
	local delCount = 0
	for elementType,mods in pairs(modList) do
		for k,mod in pairs(mods) do
			local srcRes = mod.srcRes
			if srcRes then
				if stoppedResName == srcRes then
					-- delete mod added by resource that was just stopped
					modList[elementType][k] = nil
					delCount = delCount + 1
				end
			end
		end
	end

	if delCount > 0 then
		outputDebugString("Removed "..delCount.." mods because resource '"..stoppedResName.."' stopped", 0, 211, 255, 89)
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
			triggerClientEvent(player, resName..":receiveModList", resourceRoot, modList)
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
addEventHandler(resName..":requestModList", resourceRoot, requestModList)


function resetElementModel(element, old_id)
	if not isElement(element) then return end
	local currModel = getElementModel(element)
	setElementModel(element, currModel)
	outputDebugString("Resetting model serverside for "..getElementType(element).." to ID "..currModel.." (previous ID: "..tostring(old_id)..")",0, 59, 160, 255)
end
addEventHandler(resName..":resetElementModel", resourceRoot, resetElementModel)

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
			setElementData(element, baseDataName, mod.base_id)
		end
		
		return true
	
	else
		return false, "Not a custom model ID: "..id
	end
end



--[[
	This function exists to avoid too many exports calls of the function below from
	external resources to add mods from those
	With this one you can just pass a table of mods and it calls that function for you
]]
function addExternalMods_IDFilenames(list) -- [Exported]
	if type(list) ~= "table" then
		return false, "Missing/Invalid 'list' table passed: "..tostring(list)
	end
	local countWorked = 0
	for _, modInfo in ipairs(list) do
		if type(modInfo) ~= "table" then
			return false, "Missing/Invalid 'modInfo' table passed: "..tostring(modInfo)
		end
		local elementType, id, base_id, name, path, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse = unpack(modInfo)
		
		local co = coroutine.create(addExternalMod_IDFilenames)
		coroutine.resume(co, elementType, id, base_id, name, path, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, true)
		local _, worked, reason = coroutine.resume(co)
		if worked then
			countWorked = countWorked + 1
		else
			return false, "Aborting, one failed, reason: "..tostring(reason)
		end
	end
	return countWorked
end

--[[
	The difference between this function and addExternalMod_CustomFilenames is that
	you pass a folder path in 'path' and it will search for ID.dff ID.txd etc
]]
function addExternalMod_IDFilenames(elementType, id, base_id, name, path, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, usingCoroutine) -- [Exported]
	if (usingCoroutine == true) then
		coroutine.yield()
	end

	local sourceResName = getResourceName(sourceResource)
	if sourceResName == resName then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end

	if type(elementType) ~= "string" then
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

	if type(name) ~= "string" then
		return false, "Missing/Invalid 'name' passed: "..tostring(name)
	end
	if type(path) ~= "string" then
		return false, "Missing/Invalid 'path' passed: "..tostring(path)
	end
	if (ignoreTXD ~= nil and type(ignoreTXD) ~= "boolean") then
		return false, "ignoreTXD passed must be true/false"
	end
	if (ignoreDFF ~= nil and type(ignoreDFF) ~= "boolean") then
		return false, "ignoreDFF passed must be true/false"
	end
	if (ignoreCOL ~= nil and type(ignoreCOL) ~= "boolean") then
		return false, "ignoreCOL passed must be true/false"
	end
	if (metaDownloadFalse ~= nil) and (not (metaDownloadFalse == true or metaDownloadFalse == false)) then
		return false, "Incorrect 'metaDownloadFalse' passed, must be true/false"
	end
	if not metaDownloadFalse then
		metaDownloadFalse = false
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

	for elementType2,mods in pairs(modList) do
		for k,mod in pairs(mods) do
			if mod.id == id then
				return false, "Duplicated 'id' passed, already exists in modList"
			end
		end
	end

	local paths = getActualModPaths(path, id)
	for k, path2 in pairs(paths) do
		if (not fileExists(path2)) and ((ENABLE_NANDOCRYPT) and not fileExists(path2..NANDOCRYPT_EXT)) then
			if (not ignoreTXD and k == "txd")
			or (not ignoreDFF and k == "dff")
			or ((not ignoreCOL) and elementType == "object" and k == "col") then
				return false, "File doesn't exist: '"..tostring(path2).."', check folder: '"..path.."'"
			end
		end
	end

	-- Save mod in list
	modList[elementType][#modList[elementType]+1] = {
		id=id, base_id=base_id, path=path, name=name, metaDownloadFalse=metaDownloadFalse, srcRes=sourceResName
	}

	fixModList()
	sendModListWhenReady_ToAllPlayers()

	-- Don't spam chat/debug when mass adding/removing mods
	if isTimer(prevent_addrem_spam.addtimer) then killTimer(prevent_addrem_spam.addtimer) end
	
	if not prevent_addrem_spam.add[sourceResName] then prevent_addrem_spam.add[sourceResName] = {} end
	table.insert(prevent_addrem_spam.add[sourceResName], true)

	prevent_addrem_spam.addtimer = setTimer(function()
		for rname,mods in pairs(prevent_addrem_spam.add) do
			outputDebugString("Added "..#mods.." mods from "..rname, 0, 136, 255, 89)
			prevent_addrem_spam.add[rname] = nil
		end
	end, 1000, 1)

	return true
end

--[[
	This function exists to avoid too many exports calls of the function below from
	external resources to add mods from those
	With this one you can just pass a table of mods and it calls that function for you
]]
function addExternalMods_CustomFileNames(list) -- [Exported]
	if type(list) ~= "table" then
		return false, "Missing/Invalid 'list' table passed: "..tostring(list)
	end
	local countWorked = 0
	for _, modInfo in ipairs(list) do
		if type(modInfo) ~= "table" then
			return false, "Missing/Invalid 'modInfo' table passed: "..tostring(modInfo)
		end
		local elementType, id, base_id, name, path_dff, path_txd, path_col, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse = unpack(modInfo)
		
		local co = coroutine.create(addExternalMod_CustomFilenames)
		coroutine.resume(co, elementType, id, base_id, name, path_dff, path_txd, path_col, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, true)
		local _, worked, reason = coroutine.resume(co)
		if worked then
			countWorked = countWorked + 1
		else
			return false, "Aborting, one failed, reason: "..tostring(reason)
		end
	end
	return countWorked
end

--[[
	The difference between this function and addExternalMod_IDFilenames is that
	you pass directly individual file paths for dff, txd and col files
]]
function addExternalMod_CustomFilenames(elementType, id, base_id, name, path_dff, path_txd, path_col, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, usingCoroutine) -- [Exported]
	if (usingCoroutine == true) then
		coroutine.yield()
	end

	local sourceResName = getResourceName(sourceResource)
	if sourceResName == resName then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end

	if type(elementType) ~= "string" then
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

	if type(name) ~= "string" then
		return false, "Missing/Invalid 'name' passed: "..tostring(name)
	end

	if (ignoreTXD ~= nil and type(ignoreTXD) ~= "boolean") then
		return false, "ignoreTXD passed must be true/false"
	end
	if (ignoreDFF ~= nil and type(ignoreDFF) ~= "boolean") then
		return false, "ignoreDFF passed must be true/false"
	end
	if (ignoreCOL ~= nil and type(ignoreCOL) ~= "boolean") then
		return false, "ignoreCOL passed must be true/false"
	end

	if (metaDownloadFalse ~= nil) and (not (metaDownloadFalse == true or metaDownloadFalse == false)) then
		return false, "Incorrect 'metaDownloadFalse' passed, must be true/false"
	end
	if not metaDownloadFalse then
		metaDownloadFalse = false
	end


	local paths = {}

	if (ignoreDFF ~= true) then

		if type(path_dff) ~= "string" then
			return false, "Missing/Invalid 'path_dff' passed: "..tostring(path_dff)
		end
		if string.sub(path_dff, 1,1) ~= ":" then
			path_dff = ":"..sourceResName.."/"..path_dff
		end
		paths.dff = path_dff

	end

	if (ignoreTXD ~= true) then

		if type(path_txd) ~= "string" then
			return false, "Missing/Invalid 'path_txd' passed: "..tostring(path_txd)
		end
		if string.sub(path_txd, 1,1) ~= ":" then
			path_txd = ":"..sourceResName.."/"..path_txd
		end
		paths.txd = path_txd

	end

	if (ignoreCOL ~= true and elementType == "object") then

		if type(path_col) ~= "string" then
			return false, "Missing/Invalid 'path_col' passed: "..tostring(path_col)
		end
		if string.sub(path_col, 1,1) ~= ":" then
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

	for elementType2,mods in pairs(modList) do
		for k,mod in pairs(mods) do
			if mod.id == id then
				return false, "Duplicated 'id' passed, already exists in modList"
			end
		end
	end
	for k, path2 in pairs(paths) do
		if (not fileExists(path2)) and ((ENABLE_NANDOCRYPT) and not fileExists(path2..NANDOCRYPT_EXT)) then
			if (not ignoreTXD and k == "txd")
			or (not ignoreDFF and k == "dff")
			or ((not ignoreCOL) and elementType == "object" and k == "col") then

				return false, "File doesn't exist: '"..tostring(path2).."'"
			end
		end
	end

	-- Save mod in list
	modList[elementType][#modList[elementType]+1] = {
		-- path will be a table here, interpreted by the client differently
		id=id, base_id=base_id, path=paths, name=name, metaDownloadFalse=metaDownloadFalse, srcRes=sourceResName
	}

	fixModList()
	sendModListWhenReady_ToAllPlayers()

	-- Don't spam chat/debug when mass adding/removing mods
	if isTimer(prevent_addrem_spam.addtimer) then killTimer(prevent_addrem_spam.addtimer) end
	
	if not prevent_addrem_spam.add[sourceResName] then prevent_addrem_spam.add[sourceResName] = {} end
	table.insert(prevent_addrem_spam.add[sourceResName], true)

	prevent_addrem_spam.addtimer = setTimer(function()
		for rname,mods in pairs(prevent_addrem_spam.add) do
			outputDebugString("Added "..#mods.." mods from "..rname, 0, 136, 255, 89)
			prevent_addrem_spam.add[rname] = nil
		end
	end, 1000, 1)
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
				
				outputDebugString("Removed "..elementType.." mod ID "..id, 0, 211, 255, 89)
			
				modList[elementType][k] = nil	
				
				fixModList()
				sendModListWhenReady_ToAllPlayers()

				-- Don't spam chat/debug when mass adding/removing mods
				if isTimer(prevent_addrem_spam.remtimer) then killTimer(prevent_addrem_spam.remtimer) end
				
				if not prevent_addrem_spam.rem[sourceResName] then prevent_addrem_spam.rem[sourceResName] = {} end
				table.insert(prevent_addrem_spam.rem[sourceResName], true)

				prevent_addrem_spam.remtimer = setTimer(function()
					for rname,mods2 in pairs(prevent_addrem_spam.rem) do
						outputDebugString("Removed "..#mods2.." mods from "..rname, 0, 211, 255, 89)
						prevent_addrem_spam.rem[rname] = nil
					end
				end, 1000, 1)
				
				return true
			end
		end
	end

	return false, "No mod with ID "..id.." found in modList"
end

addEventHandler(resName..":kickOnDownloadsFail", resourceRoot, function(modId, path)
	if not client then return end

	outputServerLog("["..resName.."] "..getPlayerName(client).." failed to download '"..path.."' (#"..modId..") too many times (kicked).")
	kickPlayer(client, "System", "Failed to download '"..path.."' (#"..modId..") too many times.")
end)
