--[[
	Author: https://github.com/Fernando-A-Rocha

	server.lua

	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
--]]

-- Internal events:
addEvent(resName..":onDownloadFailed", true)

local SERVER_READY = false
local startTickCount = nil
local SEND_DELAY = 5000
local clientsWaiting = {}
local loadedPlayers = {}

local prevent_addrem_spam = {
	add = {},
	addtimer = {},
	rem = {},
	remtimer = {},
}

--[[
	Goal: solve the issue of handling resetting every time the vehicle's model is changed serverside/clientside
]]
if DATANAME_VEH_HANDLING then
	function onSetVehicleHandling( sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ... )
		if sourceResource == resource then
			return
		end

		local args = {...}
		local theVehicle, property, value = unpack(args)
		if not isCustomVehicle(theVehicle) then return end

		-- https://wiki.multitheftauto.com/wiki/SetVehicleHandling
		-- Configuration resets not supported, only normal property-value setting
		if not property then return end

		local savedHandling = getElementData(theVehicle, DATANAME_VEH_HANDLING) or {}
		savedHandling[property] = value

		setElementData(theVehicle, DATANAME_VEH_HANDLING, savedHandling, true)
	end
	addDebugHook( "postFunction", onSetVehicleHandling, { "setVehicleHandling" })
end

--[[
	Goal: solve the issue of upgrades resetting every time the vehicle's model is changed serverside/clientside
]]
if DATANAME_VEH_UPGRADES then
	function onVehicleUpgradesChanged( sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ... )
		if sourceResource == resource then
			return 
		end

		local args = {...}
		local theVehicle = unpack(args)
		if not isCustomVehicle(theVehicle) then return end

		setElementData(theVehicle, DATANAME_VEH_UPGRADES, getVehicleUpgrades(theVehicle), true)
	end
	addDebugHook( "postFunction", onVehicleUpgradesChanged, { "addVehicleUpgrade", "removeVehicleUpgrade" })
end

if DATANAME_VEH_PAINTJOB then
	function onVehiclePaintjobChanged( sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ... )
		if sourceResource == resource then
			return 
		end

		local args = {...}
		local theVehicle = unpack(args)
		if not isCustomVehicle(theVehicle) then return end

		setElementData(theVehicle, DATANAME_VEH_PAINTJOB, getVehiclePaintjob(theVehicle), true)
	end
	addDebugHook( "postFunction", onVehiclePaintjobChanged, { "setVehiclePaintjob" })
end

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


function table.copy(tab, recursive)
    local ret = {}
    for key, value in pairs(tab) do
        if (type(value) == "table") and recursive then ret[key] = table.copy(value)
        else ret[key] = value end
    end
    return ret
end

local function fixModList()
	
	for elementType, mods in pairs(modList) do
		for k, mod in pairs(mods) do

			local paths_ = ((type(mod.path)=="table" and mod.path) or (getActualModPaths(mod.path, mod.id)))
			
			modList[elementType][k].paths = {}
			modList[elementType][k].readyPaths = {}

			local ignoreTXD, ignoreDFF, ignoreCOL = mod.ignoreTXD, mod.ignoreDFF, mod.ignoreCOL

			for pathType, path2 in pairs(paths_) do
				
				if (pathType == "txd" and ignoreTXD)
				or (pathType == "dff" and ignoreDFF)
				or (pathType == "col" and (ignoreCOL or elementType ~= "object")) then
					
					modList[elementType][k].paths[pathType] = nil
				else
					modList[elementType][k].paths[pathType] = path2

					if mod.metaDownloadFalse then
						modList[elementType][k].readyPaths[path2] = false
					else
						modList[elementType][k].readyPaths[path2] = true
					end
				end
			end

			if not mod.metaDownloadFalse then
				modList[elementType][k].allReady = true
			end
		end
	end

	modList.player = table.copy(modList.ped, true)
	modList.pickup = table.copy(modList.object, true)
	return true
end

local function modCheckMessage(text)
	outputServerLog("["..resName.."] Startup Verifications: "..text)
	outputDebugString(text, 1)
end

-- verifies modList, because people can fuck up sometimes :)
function doModListChecks()

	local corruptedMissing = false
	if (not modList) or (type(modList) ~= "table") then
		corruptedMissing = true
		modList = {}
	end

	for elementType, name in pairs(dataNames) do
		if not (
			elementType == "player"
			or elementType == "pickup"
		) then -- exceptions

			local mods1 = modList[elementType]
			if not mods1 then
				
				if not corruptedMissing then
					modCheckMessage("Missing from modList: "..elementType.." = {}, assuming empty")
				end

				modList[elementType] = {}
			end
		end
	end

	if corruptedMissing then
		modCheckMessage("'modList' is corrupted/missing, assuming empty mod list")
		return true -- Pass checks OK
	end

	-- verify element types
	-- player & pickup mods are synced with ped and object mods respectively
	for elementType, mods in pairs(modList) do
		if elementType == "player" then
			modCheckMessage("Please remove mod from modList: player = {...}, it will be added automatically to match 'ped' mods")
			return false
		end
		if elementType == "pickup" then
			modCheckMessage("Please remove mod from modList: pickup = {...}, it will be added automatically to match 'object' mods")
			return false
		end
	end

	local usedModIds = {}
	local usedFiles = {}

	for elementType, mods in pairs(modList) do
		for _, mod in ipairs(mods) do
			-- 1.  verify IDs
			if not tonumber(mod.id) then
				modCheckMessage("Invalid mod ID '"..tostring(mod.id).."'")
				return false
			end
			if mod.id == 0 then
				modCheckMessage("Invalid mod ID '"..tostring(mod.id).."', must be != 0")
				return false
			end
			if isDefaultID(false, mod.id) then
				modCheckMessage("Invalid mod ID '"..tostring(mod.id).."', must be out of the default GTA:SA ID Range, see shared.lua isDefaultID")
				return false
			end
			if usedModIds[mod.id] then
				modCheckMessage("Duplicated mod ID '"..tostring(mod.id).."'")
				return false
			end
			usedModIds[mod.id] = true

			if not tonumber(mod.base_id) then
				modCheckMessage("Invalid mod base ID '"..tostring(mod.base_id).."'")
				return false
			end
			if not isDefaultID(false, mod.base_id) then
				modCheckMessage("Invalid mod base ID '"..tostring(mod.base_id).."', must be a default GTA:SA ID")
				return false
			end

			-- 2.  verify name
			if not mod.name or type(mod.name)~="string" then

				modCheckMessage("Missing/Invalid mod name '"..tostring(mod.name).."' for mod ID "..mod.id)
				return false
			end

			-- 3.  verify path
			if (not mod.path) then

				modCheckMessage("Missing mod path '"..tostring(mod.path).."' for mod ID "..mod.id)
				return false
			end
			if not (type(mod.path)=="string" or type(mod.path)=="table") then

				modCheckMessage("Invalid mod path '"..tostring(mod.path).."' for mod ID "..mod.id)
				return false
			end

			-- 4.  verify files exist with optional params
			local ignoreTXD, ignoreDFF, ignoreCOL = mod.ignoreTXD, mod.ignoreDFF, mod.ignoreCOL

			if ignoreTXD ~= nil and type(ignoreTXD) ~= "boolean" then
				modCheckMessage("Invalid param ignoreTXD value '"..tostring(ignoreTXD).."' (expected true/false) for mod ID "..mod.id)
				return false
			end
			if ignoreDFF ~= nil and type(ignoreDFF) ~= "boolean" then
				modCheckMessage("Invalid param ignoreDFF value '"..tostring(ignoreDFF).."' (expected true/false) for mod ID "..mod.id)
				return false
			end
			if ignoreCOL ~= nil and type(ignoreCOL) ~= "boolean" then
				modCheckMessage("Invalid param ignoreCOL value '"..tostring(ignoreCOL).."' (expected true/false) for mod ID "..mod.id)
				return false
			end

			local paths
			local path = mod.path
			if type(path)=="table" then
				paths = path
			else
				paths = getActualModPaths(path, mod.id)
			end
			usedFiles[mod.id] = {}
			for pathType, path2 in pairs(paths) do
				if type(pathType) ~= "string" then
					modCheckMessage("Invalid path type '"..tostring(pathType).."' for mod ID "..mod.id)
					return false
				end
				if type(path2) ~= "string" then
					modCheckMessage("Invalid file path '"..tostring(pathType).."' for mod ID "..mod.id)
					return false
				end
				if (not ignoreTXD and pathType == "txd")
				or (not ignoreDFF and pathType == "dff")
				or ((not ignoreCOL) and elementType == "object" and pathType == "col") then
					if (not fileExists(path2)) and ((ENABLE_NANDOCRYPT) and not fileExists(path2..NANDOCRYPT_EXT)) then
						modCheckMessage("File not found: '"..tostring(path2).."' or '"..tostring(path2..NANDOCRYPT_EXT).."' for mod ID "..mod.id)
						return false
					else
						usedFiles[mod.id][pathType] = path2
					end
				end
			end

			-- 5. verify optional param: metaDownloadFalse
			if mod.metaDownloadFalse ~= nil and type(mod.metaDownloadFalse) ~= "boolean" then
				modCheckMessage("Invalid param metaDownloadFalse value '"..tostring(mod.metaDownloadFalse).."' (expected true/false) for mod ID "..mod.id)
				return false
			end

			-- 6. verify optional param: disableAutoFree
			if mod.disableAutoFree ~= nil and type(mod.disableAutoFree) ~= "boolean" then
				modCheckMessage("Invalid param disableAutoFree value '"..tostring(mod.disableAutoFree).."' (expected true/false) for mod ID "..mod.id)
				return false
			end

			-- 7. verify optional param: lodDistance
			if mod.lodDistance ~= nil and type(mod.lodDistance) ~= "number" then
				modCheckMessage("Invalid param lodDistance value '"..tostring(mod.lodDistance).."' (expected number) for mod ID "..mod.id)
				return false
			end

			-- 8. verify optional param: filteringEnabled
			if mod.filteringEnabled ~= nil and type(mod.filteringEnabled) ~= "boolean" then
				modCheckMessage("Invalid param filteringEnabled value '"..tostring(mod.filteringEnabled).."' (expected true/false) for mod ID "..mod.id)
				return false
			end

			-- 9. verify optional param: alphaTransparency
			if mod.alphaTransparency ~= nil and type(mod.alphaTransparency) ~= "boolean" then
				modCheckMessage("Invalid param alphaTransparency value '"..tostring(mod.alphaTransparency).."' (expected true/false) for mod ID "..mod.id)
				return false
			end
		end
	end

	-- 10.  verify file nodes exist in meta.xml
	local metaFile = xmlLoadFile("meta.xml", true)
	if not metaFile then
		outputDebugString("STARTUP MOD CHECK: Failed to open meta.xml file", 2)
	else
		local metaNodes = xmlNodeGetChildren(metaFile) or {}
		local foundFiles = {}
		for i, node in ipairs(metaNodes) do
			if xmlNodeGetName(node)=="file" then
				local src = xmlNodeGetAttribute(node, "src")
				if src then
					if foundFiles[src] then
						outputDebugString("STARTUP MOD CHECK: Duplicate file node in meta.xml: "..src, 2)
					else
						foundFiles[src] = true
					end
				end
			end
		end
		for modId, files in pairs(usedFiles) do
			for pathType, path2 in pairs(files) do
				if (not foundFiles[path2]) and ((ENABLE_NANDOCRYPT) and not foundFiles[path2..NANDOCRYPT_EXT]) then
					xmlUnloadFile(metaFile)
					modCheckMessage("File node not found in meta.xml: '"..tostring(path2).."' or '"..tostring(path2..NANDOCRYPT_EXT).."' for mod ID "..modId)
					return false
				end
			end
		end
		
		xmlUnloadFile(metaFile)
	end
	
	fixModList()
	return true -- Pass checks OK
end

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)

	Async:setPriority(ASYNC_PRIORITY)

	startTickCount = getTickCount()

	if (STARTUP_VERIFICATIONS) then
		if not doModListChecks() then
			cancelEvent()
			return
		end
	end

	outputDebugString(resName.." startup lasted "..(getTickCount() - startTickCount).."ms, sending mod list to clients", 0, 255, 0, 255)

	for player, _ in pairs(clientsWaiting) do
		if isElement(player) then
			sendModList(player, "clientsWaiting")
		end
	end

	clientsWaiting = nil
	startTickCount = nil

	SERVER_READY = true

	if (START_STOP_MESSAGES) then
		local version = getResourceInfo(startedResource, "version") or false
		local name = getResourceInfo(startedResource, "name") or false
		outputChatBox((name and "#ffc175["..name.."] " or "").."#ffffff"..resName..(version and (" "..version) or ("")).." #ffc175started", root, 255,255,255, true)
	end

	if #LINKED_RESOURCES > 0 then

		outputDebugString(resName.." will try to start "..#LINKED_RESOURCES.." resources in "..(SEND_DELAY/1000).."s", 0, 255, 100, 255)

		setTimer(function()

			for k, v in ipairs(LINKED_RESOURCES) do
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

		end, SEND_DELAY, 1)
	end
end)

addEventHandler( "onResourceStop", resourceRoot, 
function (stoppedResource, wasDeleted)

	local willStart = {}
	for k, v in ipairs(LINKED_RESOURCES) do
		local name, start, stop = v.name, v.start, v.stop
		if type(name)=="string" then
			local res = getResourceFromName(name)
			if res and getResourceState(res) == "running" then
				if start == true then
					willStart[name] = true
				end
				if stop == true then
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

	if (START_STOP_MESSAGES) then
		local version = getResourceInfo(stoppedResource, "version") or false
		local name = getResourceInfo(stoppedResource, "name") or false
		outputChatBox((name and "#ffc175["..name.."] " or "").."#ababab"..resName..(version and (" "..version) or ("")).." #ffc175stopped", root, 255,255,255, true)
	end
end)

addEventHandler( "onResourceStop", root, 
function (stoppedResource, wasDeleted)
	if stoppedResource == resource then return end
	
	local stoppedResName = getResourceName(stoppedResource)
	local delCount = 0
	for elementType,mods in pairs(modList) do
		if not (elementType=="player" or elementType=="pickup") then
			for k,mod in pairs(mods) do
				local srcRes = mod.srcRes
				if srcRes and stoppedResName == srcRes then
					-- delete mod added by resource that was just stopped
					table.remove(modList[elementType], k)
					delCount = delCount + 1
				end
			end
		end
	end

	if delCount > 0 then
		outputDebugString("Removed "..delCount.." mods because resource '"..stoppedResName.."' stopped", 0, 211, 255, 89)
		fixModList()
		setTimer(sendModListAllPlayers, 1000, 1, "onResourceStop")
	end
end)

function sendModList(player, fromName)
	triggerClientEvent(player, resName..":receiveModList", resourceRoot, modList)
	-- outputDebugString("Sent mod list to "..getPlayerName(player).." | "..fromName, 0, 211, 255, 89)
end

function sendModListAllPlayers(fromName)

	if SERVER_READY then
		for k,player in ipairs(getElementsByType("player")) do
			sendModList(player, fromName)
		end
	else
		for k,player in ipairs(getElementsByType("player")) do
			clientsWaiting[player] = true
		end
	end
end

function requestModList(res)
	if res ~= resource then return end

	for i, v in ipairs(loadedPlayers) do
		if v == source then
			return
		end
	end

	if SERVER_READY then
		sendModList(source, "requestModList")
	else
		clientsWaiting[source] = true
	end

	table.insert(loadedPlayers, source)
end
addEventHandler("onPlayerResourceStart", root, requestModList)

addEventHandler("onPlayerQuit", root, 
	function()
		for i, v in ipairs(loadedPlayers) do
			if v == source then
				table.remove(loadedPlayers, i)

				break
			end
		end	
	end
)

local function verifyOptionalModParameters(modInfo)

	local ignoreTXD = modInfo.ignoreTXD or false
	if (type(ignoreTXD) ~= "boolean") then
		return false, "ignoreTXD passed must be true/false"
	end

	local ignoreDFF = modInfo.ignoreDFF or false
	if (type(ignoreDFF) ~= "boolean") then
		return false, "ignoreDFF passed must be true/false"
	end

	local ignoreCOL = modInfo.ignoreCOL or false
	if (type(ignoreCOL) ~= "boolean") then
		return false, "ignoreCOL passed must be true/false"
	end

	local metaDownloadFalse = modInfo.metaDownloadFalse or false
	if type(metaDownloadFalse) ~= "boolean" then
		return false, "metaDownloadFalse passed must be true/false"
	end

	local disableAutoFree = modInfo.disableAutoFree or false
	if type(disableAutoFree) ~= "boolean" then
		return false, "disableAutoFree passed must be true/false"
	end

	local lodDistance = modInfo.lodDistance or nil
	if (lodDistance ~= nil) and type(lodDistance) ~= "number" then
		return false, "lodDistance passed must be a number"
	end

	local filteringEnabled = modInfo.filteringEnabled or true
	if type(filteringEnabled) ~= "boolean" then
		return false, "filteringEnabled passed must be true/false"
	end

	local alphaTransparency = modInfo.alphaTransparency or false
	if type(alphaTransparency) ~= "boolean" then
		return false, "alphaTransparency passed must be true/false"
	end

	modInfo.ignoreTXD = ignoreTXD
	modInfo.ignoreDFF = ignoreDFF
	modInfo.ignoreCOL = ignoreCOL
	modInfo.metaDownloadFalse = metaDownloadFalse
	modInfo.disableAutoFree = disableAutoFree
	modInfo.lodDistance = lodDistance
	modInfo.filteringEnabled = filteringEnabled
	modInfo.alphaTransparency = alphaTransparency

	return modInfo
end

--[[
	Backwards compatibility for old modInfo tables
]]
function addExternalMods_IDFilenames_Legacy(sourceResName, list)
	_outputDebugString("You are passing deprecated modInfo tables to addExternalMods_IDFilenames. Update your code to use the new format.", 2)
	Async:foreach(list, function(modInfo)
		local elementType, id, base_id, name, path, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, disableAutoFree, lodDistance = unpack(modInfo)
		local modInfo2 = {
			elementType = elementType,
			id = id,
			base_id = base_id,
			name = name,
			path = path,
			ignoreTXD = ignoreTXD,
			ignoreDFF = ignoreDFF,
			ignoreCOL = ignoreCOL,
			metaDownloadFalse = metaDownloadFalse,
			disableAutoFree = disableAutoFree,
			lodDistance = lodDistance,
		}
		local worked, reason = addExternalMod_IDFilenames(modInfo2, sourceResName)
		if not worked then
			outputDebugString("addExternalMod_IDFilenames failed: "..tostring(reason), 1)
		end
	end)
	return true
end

--[[
	This function exists to avoid too many exports calls of the function below from
	external resources to add mods from those
	With this one you can just pass a table of mods and it calls that function for you

	This is an async function: mods in the list will be added gradually and if you have too many it may take several seconds.
	So don't assume that they've all been added immediately after the function returns true.
	Also, please note that if any of your mods has an invalid parameter, an error will be output and it won't get added.
]]
function addExternalMods_IDFilenames(list, onFinishEvent) -- [Exported]
	if not sourceResource then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end
	local sourceResName = getResourceName(sourceResource)
	if sourceResName == resName then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end
	if type(list) ~= "table" then
		return false, "Missing/Invalid 'list' table passed: "..tostring(list)
	end
	if type(list[1]) ~= "table" then
		return false, "Missing/Invalid 'list[1]' table passed: "..tostring(list[1])
	end
	if tonumber(list[1][2]) then
		-- Backwards compatibility for old modInfo tables
		return addExternalMods_IDFilenames_Legacy(sourceResName, list)
	end
	if not list[1].path then
		return false, "list[1] is missing 'path' key"
	end
	if onFinishEvent ~= nil then
		if type(onFinishEvent) ~= "table" then
			return false, "Invalid 'onFinishEvent' passed, example: { source = 'eventSource', name = 'eventName', args = {thePlayer} }"
		end
		if not isElement(onFinishEvent.source) then
			return false, "Invalid 'onFinishEvent.source' passed, expected element"
		end
		if type(onFinishEvent.name) ~= "string" then
			return false, "Invalid 'onFinishEvent.name' passed, expected string"
		end
		if (onFinishEvent.args ~= nil) then
			if type(onFinishEvent.args) ~= "table" then
				return false, "Invalid 'onFinishEvent.args' passed, expected table"
			end
		end
	end
	Async:foreach(list, function(modInfo)
		local worked, reason = addExternalMod_IDFilenames(modInfo, sourceResName)
		if not worked then
			outputDebugString("addExternalMod_IDFilenames failed: "..tostring(reason), 1)
		end
	end, function()
		if (onFinishEvent) then
			if onFinishEvent.args then
				triggerEvent(onFinishEvent.name, onFinishEvent.source, unpack(onFinishEvent.args))
			else
				triggerEvent(onFinishEvent.name, onFinishEvent.source)
			end
		end
	end)
	return true
end

--[[
	The difference between this function and addExternalMod_CustomFilenames is that
	you pass a folder path in 'path' and it will search for ID.dff ID.txd etc
]]
-- [Exported]
function addExternalMod_IDFilenames(...)

	-- Backwards compatibility for old arguments
	local args = {...}
	local modInfo
	local fromResourceName
	if type(args[1]) == "string" then
		_outputDebugString("You are passing deprecated variables to addExternalMod_IDFilenames. Update your code to use the new format.", 2)
		--[[
			BEFORE:

			elementType, id, base_id, name, path,
			ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, disableAutoFree, lodDistance,
			fromResourceName
		]]
		modInfo = {
			elementType = args[1], id = args[2], base_id = args[3], name = args[4],
			path = args[5], ignoreTXD = args[6], ignoreDFF = args[7], ignoreCOL = args[8],
			metaDownloadFalse = args[9], disableAutoFree = args[10], lodDistance = args[11]
		}
		fromResourceName = args[12]
	else
		modInfo = args[1]
		fromResourceName = args[2]
	end

	local sourceResName
	if type(fromResourceName) ~= "string" then
		if (not sourceResource) or (getResourceName(sourceResource) == resName) then
			return false, "This command is meant to be called from outside resource '"..resName.."'"
		end
		sourceResName = getResourceName(sourceResource)
	else
		sourceResName = fromResourceName
	end

	local elementType = modInfo.elementType
	if type(elementType) ~= "string" then
		return false, "Missing/Invalid 'elementType' passed: "..tostring(elementType)
	end
	local sup, reason = isElementTypeSupported(elementType)
	if not sup then
		return false, "Invalid 'elementType' passed: "..reason
	end
	if elementType == "player" or elementType == "pickup" then
		return false, "'player' or 'pickup' mods have to be added with type 'ped' or 'object' respectively"
	end

	local id = modInfo.id
	if not tonumber(id) then
		return false, "Missing/Invalid 'id' passed: "..tostring(id)
	end
	id = tonumber(id)

	local base_id = modInfo.base_id
	if not tonumber(base_id) then
		return false, "Missing/Invalid 'base_id' passed: "..tostring(base_id)
	end
	base_id = tonumber(base_id)

	local name = modInfo.name
	if type(name) ~= "string" then
		return false, "Missing/Invalid 'name' passed: "..tostring(name)
	end

	local path = modInfo.path
	if type(path) ~= "string" then
		return false, "Missing/Invalid 'path' passed: "..tostring(path)
	end

	local modInfo2, optionalReason = verifyOptionalModParameters(modInfo)
	if not modInfo2 then
		return false, optionalReason
	end
	modInfo = modInfo2

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
			if ((not modInfo.ignoreTXD) and k == "txd")
			or ((not modInfo.ignoreDFF) and k == "dff")
			or ((not modInfo.ignoreCOL) and elementType == "object" and k == "col") then
				return false, "File doesn't exist: '"..tostring(path2).."', check folder: '"..path.."'"
			end
		end
	end

	-- Save mod in list
	modList[elementType][#modList[elementType]+1] = {
		id=id, base_id=base_id, path=path, name=name,
		metaDownloadFalse=modInfo.metaDownloadFalse, disableAutoFree=modInfo.disableAutoFree, lodDistance=modInfo.lodDistance,
		filteringEnabled=modInfo.filteringEnabled, alphaTransparency=modInfo.alphaTransparency,
		srcRes=sourceResName
	}

	fixModList()

	-- Don't spam chat/debug when mass adding/removing mods
	if isTimer(prevent_addrem_spam.addtimer) then killTimer(prevent_addrem_spam.addtimer) end
	
	if not prevent_addrem_spam.add[sourceResName] then prevent_addrem_spam.add[sourceResName] = {} end
	table.insert(prevent_addrem_spam.add[sourceResName], true)

	prevent_addrem_spam.addtimer = setTimer(function()
		for rname,mods in pairs(prevent_addrem_spam.add) do
			outputDebugString("Added "..#mods.." mods from "..rname, 0, 136, 255, 89)
			prevent_addrem_spam.add[rname] = nil
			sendModListAllPlayers("addExternalMod_IDFilenames")
		end
	end, SEND_DELAY, 1)

	return true
end

--[[
	Backwards compatibility for old modInfo tables
]]
function addExternalMods_CustomFileNames_Legacy(sourceResName, list)
	_outputDebugString("You are passing deprecated modInfo tables to addExternalMods_CustomFileNames. Update your code to use the new format.", 2)
	Async:foreach(list, function(modInfo)
		local elementType, id, base_id, name, path_dff, path_txd, path_col, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, disableAutoFree, lodDistance = unpack(modInfo)
		local modInfo2 = {
			elementType=elementType, id=id, base_id=base_id, name=name,
			path_dff = path_dff, path_txd = path_txd, path_col = path_col,
			ignoreTXD=ignoreTXD, ignoreDFF=ignoreDFF, ignoreCOL=ignoreCOL,
			metaDownloadFalse=metaDownloadFalse, disableAutoFree=disableAutoFree, lodDistance=lodDistance
		}
		local worked, reason = addExternalMod_CustomFilenames(modInfo2, sourceResName)
		if not worked then
			outputDebugString("addExternalMods_CustomFileNames failed: "..tostring(reason), 1)
		end
	end)
	return true
end	

--[[
	This function exists to avoid too many exports calls of the function below from
	external resources to add mods from those
	With this one you can just pass a table of mods and it calls that function for you

	This is an async function: mods in the list will be added gradually and if you have too many it may take several seconds.
	So don't assume that they've all been added immediately after the function returns true.
	Also, please note that if any of your mods has an invalid parameter, an error will be output and it won't get added.
]]
function addExternalMods_CustomFileNames(list, onFinishEvent) -- [Exported]
	if not sourceResource then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end
	local sourceResName = getResourceName(sourceResource)
	if sourceResName == resName then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end
	if type(list) ~= "table" then
		return false, "Missing/Invalid 'list' table passed: "..tostring(list)
	end
	if type(list[1]) ~= "table" then
		return false, "Missing/Invalid 'list[1]' table passed: "..tostring(list[1])
	end
	if tonumber(list[1][2]) then
		-- Backwards compatibility for old modInfo tables
		return addExternalMods_CustomFileNames_Legacy(sourceResName, list)
	end
	if list[1].path then
		return false, "list[1] has 'path' key, this can only be used in addExternalMods_IDFilenames"
	end
	if onFinishEvent ~= nil then
		if type(onFinishEvent) ~= "table" then
			return false, "Invalid 'onFinishEvent' passed, example: { source = 'eventSource', name = 'eventName', args = {thePlayer} }"
		end
		if not isElement(onFinishEvent.source) then
			return false, "Invalid 'onFinishEvent.source' passed, expected element"
		end
		if type(onFinishEvent.name) ~= "string" then
			return false, "Invalid 'onFinishEvent.name' passed, expected string"
		end
		if (onFinishEvent.args ~= nil) then
			if type(onFinishEvent.args) ~= "table" then
				return false, "Invalid 'onFinishEvent.args' passed, expected table"
			end
		end
	end
	Async:foreach(list, function(modInfo)
		local worked, reason = addExternalMod_CustomFilenames(modInfo, sourceResName)
		if not worked then
			outputDebugString("addExternalMods_CustomFileNames failed: "..tostring(reason), 1)
		end
	end, function()
		if (onFinishEvent) then
			if onFinishEvent.args then
				triggerEvent(onFinishEvent.name, onFinishEvent.source, unpack(onFinishEvent.args))
			else
				triggerEvent(onFinishEvent.name, onFinishEvent.source)
			end
		end
	end)
	return true
end

--[[
	The difference between this function and addExternalMod_IDFilenames is that
	you pass directly individual file paths for dff, txd and col files
]]
-- [Exported]
function addExternalMod_CustomFilenames(...)

	-- Backwards compatibility for old arguments
	local args = {...}
	local modInfo
	local fromResourceName
	if type(args[1]) == "string" then
		_outputDebugString("You are passing deprecated variables to addExternalMod_CustomFilenames. Update your code to use the new format.", 2)
		--[[
			BEFORE:

			elementType, id, base_id, name, path_dff, path_txd, path_col,
			ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, disableAutoFree, lodDistance,
			fromResourceName
		]]
		modInfo = {
			elementType = args[1], id = args[2], base_id = args[3], name = args[4],
			path_dff = args[5], path_txd = args[6], path_col = args[7],
			ignoreTXD = args[8], ignoreDFF = args[9], ignoreCOL = args[10],
			metaDownloadFalse = args[11], disableAutoFree = args[12], lodDistance = args[13]
		}
		fromResourceName = args[14]
	else
		modInfo = args[1]
		fromResourceName = args[2]
	end

	if type(modInfo) ~= "table" then
		return false, "Missing/Invalid 'modInfo' table passed: "..tostring(modInfo)
	end

	local sourceResName
	if type(fromResourceName) ~= "string" then
		if (not sourceResource) or (getResourceName(sourceResource) == resName) then
			return false, "This command is meant to be called from outside resource '"..resName.."'"
		end
		sourceResName = getResourceName(sourceResource)
	else
		sourceResName = fromResourceName
	end

	local elementType = modInfo.elementType
	if type(elementType) ~= "string" then
		return false, "Missing/Invalid 'elementType' passed: "..tostring(elementType)
	end
	local sup, reason = isElementTypeSupported(elementType)
	if not sup then
		return false, "Invalid 'elementType' passed: "..reason
	end
	if elementType == "player" or elementType == "pickup" then
		return false, "'player' or 'pickup' mods have to be added with type 'ped' or 'object' respectively"
	end

	local id = modInfo.id
	if not tonumber(id) then
		return false, "Missing/Invalid 'id' passed: "..tostring(id)
	end
	id = tonumber(id)

	local base_id = modInfo.base_id
	if not tonumber(base_id) then
		return false, "Missing/Invalid 'base_id' passed: "..tostring(base_id)
	end
	base_id = tonumber(base_id)

	local name = modInfo.name
	if type(name) ~= "string" then
		return false, "Missing/Invalid 'name' passed: "..tostring(name)
	end

	local modInfo2, optionalReason = verifyOptionalModParameters(modInfo)
	if not modInfo2 then
		return false, optionalReason
	end
	modInfo = modInfo2

	local paths = {}

	if (modInfo.ignoreDFF == false) then

		local path_dff = modInfo.path_dff or modInfo.dff
		if type(path_dff) ~= "string" then
			return false, "Missing/Invalid 'path_dff' passed: "..tostring(path_dff)
		end
		if string.sub(path_dff, 1,1) ~= ":" then
			path_dff = ":"..sourceResName.."/"..path_dff
		end
		paths.dff = path_dff

	end

	if (modInfo.ignoreTXD == false) then

		local path_txd = modInfo.path_txd or modInfo.txd
		if type(path_txd) ~= "string" then
			return false, "Missing/Invalid 'path_txd' passed: "..tostring(path_txd)
		end
		if string.sub(path_txd, 1,1) ~= ":" then
			path_txd = ":"..sourceResName.."/"..path_txd
		end
		paths.txd = path_txd

	end

	if (modInfo.ignoreCOL == false and elementType == "object") then

		local path_col = modInfo.path_col or modInfo.col
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
			if ((not modInfo.ignoreTXD) and k == "txd")
			or ((not modInfo.ignoreDFF) and k == "dff")
			or ((not modInfo.ignoreCOL) and elementType == "object" and k == "col") then

				return false, "File doesn't exist: '"..tostring(path2).."'"
			end
		end
	end

	-- Save mod in list
	modList[elementType][#modList[elementType]+1] = {
		id=id, base_id=base_id, path=paths, name=name,
		metaDownloadFalse=modInfo.metaDownloadFalse, disableAutoFree=modInfo.disableAutoFree, lodDistance=modInfo.lodDistance,
		filteringEnabled=modInfo.filteringEnabled, alphaTransparency=modInfo.alphaTransparency,
		srcRes=sourceResName
	}

	fixModList()

	-- Don't spam chat/debug when mass adding/removing mods
	if isTimer(prevent_addrem_spam.addtimer) then killTimer(prevent_addrem_spam.addtimer) end
	
	if not prevent_addrem_spam.add[sourceResName] then prevent_addrem_spam.add[sourceResName] = {} end
	table.insert(prevent_addrem_spam.add[sourceResName], true)

	prevent_addrem_spam.addtimer = setTimer(function()
		for rname,mods in pairs(prevent_addrem_spam.add) do
			outputDebugString("Added "..#mods.." mods from "..rname, 0, 136, 255, 89)
			prevent_addrem_spam.add[rname] = nil
			sendModListAllPlayers("addExternalMod_CustomFilenames")
		end
	end, SEND_DELAY, 1)
	return true
end


--[[
	This is an async function: mods in the list of IDs will be removed gradually and if you have too many it may take several seconds.
	So don't assume that they've all been removed immediately after the function returns true.
]]
function removeExternalMods(list, onFinishEvent) -- [Exported]
	if not sourceResource then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end
	local sourceResName = getResourceName(sourceResource)
	if sourceResName == resName then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end
	if type(list) ~= "table" then
		return false, "Missing/Invalid 'list' table passed: "..tostring(list)
	end
	if type(list[1]) ~= "number" then
		return false, "list[1] is not a number: "..tostring(list[1])
	end
	if onFinishEvent ~= nil then
		if type(onFinishEvent) ~= "table" then
			return false, "Invalid 'onFinishEvent' passed, example: { source = 'eventSource', name = 'eventName', args = {thePlayer} }"
		end
		if not isElement(onFinishEvent.source) then
			return false, "Invalid 'onFinishEvent.source' passed, expected element"
		end
		if type(onFinishEvent.name) ~= "string" then
			return false, "Invalid 'onFinishEvent.name' passed, expected string"
		end
		if (onFinishEvent.args ~= nil) then
			if type(onFinishEvent.args) ~= "table" then
				return false, "Invalid 'onFinishEvent.args' passed, expected table"
			end
		end
	end
	Async:foreach(list, function(id)
		local worked, reason = removeExternalMod(id)
		if not worked then
			outputDebugString("removeExternalMod("..tostring(id)..") failed: "..tostring(reason), 1)
		end
	end, function()
		if (onFinishEvent) then
			if onFinishEvent.args then
				triggerEvent(onFinishEvent.name, onFinishEvent.source, unpack(onFinishEvent.args))
			else
				triggerEvent(onFinishEvent.name, onFinishEvent.source)
			end
		end
	end)
	return true
end

function removeExternalMod(id) -- [Exported]

	if not tonumber(id) then
		return false, "Missing/Invalid 'id' passed: "..tostring(id)
	end
	id = tonumber(id)

	for elementType,mods in pairs(modList) do
		if not (elementType=="player" or elementType=="pickup") then
			for k,mod in pairs(mods) do
				if mod.id == id then
					local sourceResName = mod.srcRes
					if sourceResName then
					
						table.remove(modList[elementType], k)
						fixModList()

						-- Don't spam chat/debug when mass adding/removing mods
						if isTimer(prevent_addrem_spam.remtimer) then killTimer(prevent_addrem_spam.remtimer) end
						
						if not prevent_addrem_spam.rem[sourceResName] then prevent_addrem_spam.rem[sourceResName] = {} end
						table.insert(prevent_addrem_spam.rem[sourceResName], true)

						prevent_addrem_spam.remtimer = setTimer(function()
							for rname,mods2 in pairs(prevent_addrem_spam.rem) do
								outputDebugString("Removed "..#mods2.." mods from "..rname, 0, 211, 255, 89)
								prevent_addrem_spam.rem[rname] = nil
								sendModListAllPlayers("removeExternalMod")
							end
						end, SEND_DELAY, 1)
						
						return true
					else
						return false, "Mod with ID "..id.." doesn't have a source resource"
					end
				end
			end
		end
	end

	return false, "No mod with ID "..id.." found in modList"
end

addEventHandler(resName..":onDownloadFailed", resourceRoot, function(kick, times, modId, path)
    if not client then return end

	outputServerLog("["..resName.."] "..getPlayerName(client).." failed to download '"..path.."' (#"..modId..") "..times.." times"..(kick and ", kicking." or "."))

    if kick == true then
	    kickPlayer(client, "System", "Failed to download '"..path.."' (#"..modId..") "..times.." times.")
    end
end)


addCommandHandler(string.lower(resName), function(thePlayer)
		local version = getResourceInfo(resource, "version") or false
		local name = getResourceInfo(resource, "name") or false
		outputChatBox((name and "#ffc175["..name.."] " or "").."#ffffff"..resName..(version and (" "..version) or ("")).." #ffc175is loaded", thePlayer, 255, 255, 255, true)
end, false,false)
