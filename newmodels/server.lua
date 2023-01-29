--[[
	Author: https://github.com/Fernando-A-Rocha

	server.lua

	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
--]]

-- Custom events:
addEvent(resName..":resetElementModel", true)
addEvent(resName..":updateVehicleProperties", true)
addEvent(resName..":kickOnDownloadsFail", true)

local SERVER_READY = false
local startTickCount = nil
local clientsWaiting = {}

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
	if sourceResource == resource then
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
	if sourceResource == resource then
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

--[[
	Goal: solve the issue of element model not setting when it's already the same model serverside
	This makes it so you don't need to use the 'refresh' element model method in any resource
]]
-- OTHER RESOURCES ONLY
function onSetElementModel( sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ... )
	if sourceResource == resource then return end

    local args = {...}
    local element,newModel = unpack(args)
    if not isElement(element) then return end
    if not tonumber(newModel) then return end
    newModel = tonumber(newModel)

    oldModel = getElementModel(element)

	setElementModelRefreshed(element, oldModel, newModel)

	if getElementType(element) == "vehicle" then -- Vehicle specific
		updateVehicleProperties(element)
	end

	return "skip"
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

local function modCheckError(text)
	outputServerLog("["..resName.."] Startup check error: "..text)
	outputDebugString(text, 1)
end

-- verifies modList, because people can fuck up sometimes :)
function doModListChecks()

	if type(modList) ~= "table" then
		modCheckError("Table modList is corrupted/missing")
		return false
	end

	for elementType, name in pairs(dataNames) do
		
		if not (
			elementType == "player"
			or elementType == "pickup"
		) then -- exceptions
			local mods1 = modList[elementType]
			if not mods1 then
				modCheckError("Missing from modList: "..elementType.." = {},")
				return false
			end
		end
	end

	-- verify element types
	-- player & pickup mods are synced with ped and object mods respectively
	for elementType,mods in pairs(modList) do
		if elementType == "player" then
			modCheckError("Please remove mod from modList: player = {...}, it will be added automatically to match 'ped' mods")
			return false
		end
		if elementType == "pickup" then
			modCheckError("Please remove mod from modList: pickup = {...}, it will be added automatically to match 'object' mods")
			return false
		end
	end

	local usedModIds = {}
	local usedFiles = {}

	for elementType,mods in pairs(modList) do
		for _, mod in ipairs(mods) do
			-- 1.  verify IDs
			if not tonumber(mod.id) then
				modCheckError("Invalid mod ID '"..tostring(mod.id).."'")
				return false
			end
			if mod.id == 0 then
				modCheckError("Invalid mod ID '"..tostring(mod.id).."', must be != 0")
				return false
			end
			if isDefaultID(false, mod.id) then
				modCheckError("Invalid mod ID '"..tostring(mod.id).."', must be out of the default GTA:SA ID Range, see shared.lua isDefaultID")
				return false
			end
			if usedModIds[mod.id] then
				modCheckError("Duplicated mod ID '"..id.."'")
				return false
			end
			usedModIds[mod.id] = true

			if not tonumber(mod.base_id) then
				modCheckError("Invalid mod base ID '"..tostring(mod.base_id).."'")
				return false
			end
			if not isDefaultID(false, mod.base_id) then
				modCheckError("Invalid mod base ID '"..tostring(mod.base_id).."', must be a default GTA:SA ID")
				return false
			end

			-- 2.  verify name
			if not mod.name or type(mod.name)~="string" then

				modCheckError("Missing/Invalid mod name '"..tostring(mod.name).."' for mod ID "..mod.id)
				return false
			end

			-- 3.  verify path
			if (not mod.path) then

				modCheckError("Missing mod path '"..tostring(mod.path).."' for mod ID "..mod.id)
				return false
			end
			if not (type(mod.path)=="string" or type(mod.path)=="table") then

				modCheckError("Invalid mod path '"..tostring(mod.path).."' for mod ID "..mod.id)
				return false
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
			usedFiles[mod.id] = {}
			for pathType, path2 in pairs(paths) do
				if type(pathType) ~= "string" then
					modCheckError("Invalid path type '"..tostring(pathType).."' for mod ID "..mod.id)
					return false
				end
				if type(path2) ~= "string" then
					modCheckError("Invalid file path '"..tostring(pathType).."' for mod ID "..mod.id)
					return false
				end
				if (not ignoreTXD and pathType == "txd")
				or (not ignoreDFF and pathType == "dff")
				or ((not ignoreCOL) and elementType == "object" and pathType == "col") then
					if (not fileExists(path2)) and ((ENABLE_NANDOCRYPT) and not fileExists(path2..NANDOCRYPT_EXT)) then
						modCheckError("File not found: '"..tostring(path2).."' or '"..tostring(path2..NANDOCRYPT_EXT).."' for mod ID "..mod.id)
						return false
					else
						usedFiles[mod.id][pathType] = path2
					end
				end
			end
		end
	end

	-- 5.  verify file nodes exist in meta.xml
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
					modCheckError("File node not found in meta.xml: '"..tostring(path2).."' or '"..tostring(path2..NANDOCRYPT_EXT).."' for mod ID "..modId)
					return false
				end
			end
		end
		
		xmlUnloadFile(metaFile)
	end
	
	fixModList()
	return true
end

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)

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
			sendModList(player)
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

	if #OTHER_RESOURCES > 0 then

		outputDebugString(resName.." will start "..#OTHER_RESOURCES.." resources in 5s", 0, 255, 100, 255)

		setTimer(function()

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

		end, 5000, 1)
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

		setTimer(function()
			sendModListAllPlayers()
		end, 1000, 1)
	end
end)

function sendModList(player)
	triggerClientEvent(player, resName..":receiveModList", resourceRoot, modList)
end

function sendModListAllPlayers()

	if SERVER_READY then
		for k,player in ipairs(getElementsByType("player")) do
			sendModList(player)
		end
	else
		for k,player in ipairs(getElementsByType("player")) do
			clientsWaiting[player] = true
		end
	end
end

function requestModList(res)
	if res ~= resource then return end
	if SERVER_READY then
		sendModList(source)
	else
		clientsWaiting[source] = true
	end
end
addEventHandler("onPlayerResourceStart", root, requestModList)

function resetElementModel(element, old_id)
	local currModel = getElementModel(element)
	setElementModelRefreshed(element, currModel, currModel)
	outputDebugString("Resetting model serverside for "..getElementType(element).." to ID "..currModel.." (previous ID: "..tostring(old_id)..")",0, 59, 160, 255)
end
addEventHandler(resName..":resetElementModel", resourceRoot, resetElementModel)


--[[
	This function exists to avoid too many exports calls of the function below from
	external resources to add mods from those
	With this one you can just pass a table of mods and it calls that function for you
]]
function addExternalMods_IDFilenames(list) -- [Exported]
	if type(list) ~= "table" then
		return false, "Missing/Invalid 'list' table passed: "..tostring(list)
	end

	if not sourceResource then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end
	local sourceResName = getResourceName(sourceResource)
	if sourceResName == resName then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end

	Async:foreach(list, function(modInfo)
		
		if type(modInfo) ~= "table" then
			return false, "Missing/Invalid 'modInfo' table passed: "..tostring(modInfo)
		end
		local elementType, id, base_id, name, path, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse = unpack(modInfo)
		addExternalMod_IDFilenames(
			elementType, id, base_id, name, path, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, sourceResName
		)
	end)

	return true
end

--[[
	The difference between this function and addExternalMod_CustomFilenames is that
	you pass a folder path in 'path' and it will search for ID.dff ID.txd etc
]]
function addExternalMod_IDFilenames(elementType, id, base_id, name, path, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, fromResourceName) -- [Exported]

	local sourceResName
	if not fromResourceName then
		sourceResName = getResourceName(sourceResource)
		if sourceResName == resName then
			return false, "This command is meant to be called from outside resource '"..resName.."'"
		end
	else
		sourceResName = fromResourceName
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

	-- Don't spam chat/debug when mass adding/removing mods
	if isTimer(prevent_addrem_spam.addtimer) then killTimer(prevent_addrem_spam.addtimer) end
	
	if not prevent_addrem_spam.add[sourceResName] then prevent_addrem_spam.add[sourceResName] = {} end
	table.insert(prevent_addrem_spam.add[sourceResName], true)

	prevent_addrem_spam.addtimer = setTimer(function()
		for rname,mods in pairs(prevent_addrem_spam.add) do
			outputDebugString("Added "..#mods.." mods from "..rname, 0, 136, 255, 89)
			prevent_addrem_spam.add[rname] = nil
			sendModListAllPlayers()
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
	if not sourceResource then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end
	local sourceResName = getResourceName(sourceResource)
	if sourceResName == resName then
		return false, "This command is meant to be called from outside resource '"..resName.."'"
	end

	Async:foreach(list, function(modInfo)

		if type(modInfo) ~= "table" then
			return false, "Missing/Invalid 'modInfo' table passed: "..tostring(modInfo)
		end
		local elementType, id, base_id, name, path_dff, path_txd, path_col, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse = unpack(modInfo)
		addExternalMod_CustomFilenames(
			elementType, id, base_id, name, path_dff, path_txd, path_col, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, sourceResName
		)
	end)

	return true
end

--[[
	The difference between this function and addExternalMod_IDFilenames is that
	you pass directly individual file paths for dff, txd and col files
]]
function addExternalMod_CustomFilenames(elementType, id, base_id, name, path_dff, path_txd, path_col, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, fromResourceName) -- [Exported]

	local sourceResName
	if not fromResourceName then
		sourceResName = getResourceName(sourceResource)
		if sourceResName == resName then
			return false, "This command is meant to be called from outside resource '"..resName.."'"
		end
	else
		sourceResName = fromResourceName
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

	-- Don't spam chat/debug when mass adding/removing mods
	if isTimer(prevent_addrem_spam.addtimer) then killTimer(prevent_addrem_spam.addtimer) end
	
	if not prevent_addrem_spam.add[sourceResName] then prevent_addrem_spam.add[sourceResName] = {} end
	table.insert(prevent_addrem_spam.add[sourceResName], true)

	prevent_addrem_spam.addtimer = setTimer(function()
		for rname,mods in pairs(prevent_addrem_spam.add) do
			outputDebugString("Added "..#mods.." mods from "..rname, 0, 136, 255, 89)
			prevent_addrem_spam.add[rname] = nil
			sendModListAllPlayers()
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
				local sourceResName = mod.srcRes
				if sourceResName then
				
					outputDebugString("Removed "..elementType.." mod ID "..id, 0, 211, 255, 89)
				
					modList[elementType][k] = nil	
					
					fixModList()

					-- Don't spam chat/debug when mass adding/removing mods
					if isTimer(prevent_addrem_spam.remtimer) then killTimer(prevent_addrem_spam.remtimer) end
					
					if not prevent_addrem_spam.rem[sourceResName] then prevent_addrem_spam.rem[sourceResName] = {} end
					table.insert(prevent_addrem_spam.rem[sourceResName], true)

					prevent_addrem_spam.remtimer = setTimer(function()
						for rname,mods2 in pairs(prevent_addrem_spam.rem) do
							outputDebugString("Removed "..#mods2.." mods from "..rname, 0, 211, 255, 89)
							prevent_addrem_spam.rem[rname] = nil
							sendModListAllPlayers()
						end
					end, 1000, 1)
					
					return true
				else
					return false, "Mod with ID "..id.." doesn't have a source resource"
				end
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

addCommandHandler(string.lower(resName), function(thePlayer)
		local version = getResourceInfo(resource, "version") or false
		local name = getResourceInfo(resource, "name") or false
		outputChatBox((name and "#ffc175["..name.."] " or "").."#ffffff"..resName..(version and (" "..version) or ("")).." #ffc175is loaded", thePlayer, 255, 255, 255, true)
end, false,false)
