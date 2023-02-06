--[[
	Author: https://github.com/Fernando-A-Rocha

	client.lua
	
	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
]]

-- Events other resources can handle:
addEvent(resName..":onModListReceived", true)
addEvent(resName..":onModFileDownloaded", true)

-- Internal events:
addEvent(resName..":receiveModList", true)
addEvent(resName..":receiveVehicleHandling", true)


allocated_ids = {} -- [new id] = allocated id
local model_elements = {} -- [allocated id] = {dff,txd[,col]}
local received_modlist -- [element type] = {...}
local waiting_queue = {} -- [element] = { func num, args }
local freeIdTimers = {} -- [new id] = timer
local FREE_ID_DELAY = 5000 -- ms

-- downloadFile queue
local fileDLQueue = {}
local fileDLTries = {}
local currDownloading -- current downloading file info
local busyDownloading = false
local awaitingSetModel = {}

-- Nandocrypt specific
local nc_waiting = {}

-- Vehicle specific
local update_properties = {} -- [element] = timer

function getExtension(fn)
	return "."..(fn:match "[^.]+$")
end

function isClientReady() -- [Exported]
	return received_modlist ~= nil
end

function getModList() -- [Exported - Client Version]
	if not received_modlist then
		-- outputDebugString("getModDataFromID: Client hasn't received modList yet", 1)
		return
	end
	return received_modlist
end

function getModDataFromID(id) -- [Exported - Client Version]
	if not tonumber(id) then return end
	if not received_modlist then
		-- outputDebugString("getModDataFromID: Client hasn't received modList yet", 1)
		return
	end

	id = tonumber(id)
	for elementType, mods in pairs(received_modlist) do
		for k,v in pairs(mods) do
			if id == v.id then
				return v, elementType -- found mod
			end
		end
	end
end

function wasElementCreatedClientside(element, elementType)
	return isElementLocal(element)
end

function allocateNewMod(element, elementType, id)

	if isElement(element) and not isElementStreamedIn(element) then
		return false, elementType.." element not streamed in"
	end

	local foundMod
	for k, mod in pairs(received_modlist[elementType]) do
		if mod.id == id then
			foundMod = mod
			break
		end
	end
	if not foundMod then
		return false, "Failed to retrieve "..elementType.." mod ID "..id.." from list stored in client"
	end

	-- /!\ only this function doesn't accept 'player'
	-- as type so we need to change that to 'ped'
	local elementType2 = elementType
	if elementType2 == "player" then elementType2 = "ped" end
	if elementType2 == "pickup" then elementType2 = "object" end

	local paths = foundMod.paths
	if type(paths) ~= "table" then
		return false, "Failed: paths is not a table"
	end

	local baseId = getModDataFromID(id).base_id

	local allocated_id = engineRequestModel(elementType2, baseId)
	if not allocated_id then
		return false, "Failed: engineRequestModel('"..elementType2.."', "..tostring(baseId)..")"
	end

	-- Do the mod loading magic
	local txdmodel,dffmodel,colmodel = nil,nil,nil

	local txdPath = paths.txd or nil
	if txdPath then
		if not fileExists(txdPath) then
			if (ENABLE_NANDOCRYPT) then
				if (not fileExists(txdPath..NANDOCRYPT_EXT)) then
					return false, "File doesn't exist: "..txdPath
				else
					txdPath = txdPath..NANDOCRYPT_EXT
				end
			else
				return false, "File doesn't exist: "..txdPath
			end
		end
	end


	local dffPath = paths.dff or nil
	if dffPath then
		if not fileExists(dffPath) then
			if (ENABLE_NANDOCRYPT) then
				if (not fileExists(dffPath..NANDOCRYPT_EXT)) then
					return false, "File doesn't exist: "..dffPath
				else
					dffPath = dffPath..NANDOCRYPT_EXT
				end
			else
				return false, "File doesn't exist: "..dffPath
			end
		end
	end


	local colPath = paths.col or nil
	if colPath then
		if not fileExists(colPath) then
			if (ENABLE_NANDOCRYPT) then
				if (not fileExists(colPath..NANDOCRYPT_EXT)) then
					return false, "File doesn't exist: "..colPath
				else
					colPath = colPath..NANDOCRYPT_EXT
				end
			else
				return false, "File doesn't exist: "..colPath
			end
		end
	end

	local lodDistance = foundMod.lodDistance

	if (ENABLE_NANDOCRYPT) then
		-- Inspired by https://github.com/Fernando-A-Rocha/mta-nandocrypt/tree/main/nando_crypt-example

		if type(ncDecrypt) ~= "function" then
			return false, "Failed: NandoCrypt decrypt function is not loaded"
		end

		local hasOneNandoCrypted = false

		local paths2 = {}
		if txdPath and getExtension(txdPath) == NANDOCRYPT_EXT then
			table.insert(paths2, {"txd", txdPath})
		end
		if dffPath and getExtension(dffPath) == NANDOCRYPT_EXT  then
			table.insert(paths2, {"dff", dffPath})
		end
		if colPath and getExtension(colPath) == NANDOCRYPT_EXT  then
			table.insert(paths2, {"col", colPath})
		end

		for k, v in pairs(paths2) do
			local t,path_ = unpack(v)

			if not nc_waiting[allocated_id] then
				nc_waiting[allocated_id] = {}
				nc_waiting[allocated_id]["total"] = #paths2
				nc_waiting[allocated_id]["count"] = 0
			end
			nc_waiting[allocated_id][t] = true
			-- print("Staging", "A-ID "..allocated_id, "Type "..t, "Path "..path_)

			local worked = ncDecrypt(path_,
				function(data)
					-- No verifications, make sure ur nandocrypted models work

					if not allocated_ids[id] then
						nc_waiting[allocated_id] = nil
						return
					end
					if not nc_waiting[allocated_id] then
						return
					end

					nc_waiting[allocated_id][t] = data
					-- print("Decrypted", "A-ID "..allocated_id, "Type "..t, "Path "..path_)

					nc_waiting[allocated_id]["count"] = nc_waiting[allocated_id]["count"] + 1
					if (nc_waiting[allocated_id]["count"] == nc_waiting[allocated_id]["total"]) then

						local oneFailed = false

						for k2, v2 in pairs(paths2) do
							local t2,path2 = unpack(v2)
							local data2 = nc_waiting[allocated_id][t2]

							local model
							if t2 == "txd" then
								model = engineLoadTXD(data2)
								if model then
									if not engineImportTXD(model,allocated_id) then
										oneFailed = true
									end
								else
									oneFailed = true
								end
							elseif t2 == "dff" then
								model = engineLoadDFF(data2, allocated_id)
								if model then
									if not engineReplaceModel(model,allocated_id) then
										oneFailed = true
									end
								else
									oneFailed = true
								end
							elseif t2 == "col" then
								model = engineLoadCOL(data2)
								if model then
									if not engineReplaceCOL(model, allocated_id) then
										oneFailed = true
									end
								else
									oneFailed = true
								end
							end
							if model then
								if not model_elements[allocated_id] then model_elements[allocated_id] = {} end
								table.insert(model_elements[allocated_id], model)
							end
						end

						if oneFailed then

							for _, model in ipairs(model_elements[allocated_id]) do
								if isElement(model) then
									destroyElement(model) -- free memory
								end
							end
							model_elements[allocated_id] = nil

							outputDebugString("Failed to apply TXD/DFF/COL of NandoCrypted mod ID "..id, 1)
						else

							-- Lod Distance
							if lodDistance then
								engineSetModelLODDistance(allocated_id, lodDistance)
							end

						end
						
						-- print("Finished", "A-AID "..allocated_id, "Total files "..nc_waiting[allocated_id]["total"])
						nc_waiting[allocated_id] = nil
					end
				end
			)
			if not worked then
				nc_waiting[allocated_id] = nil
				return false, "Failed: NandoCrypt failed to decrypt '"..path_.."'"
			else

				allocated_ids[id] = allocated_id
				
				hasOneNandoCrypted = true
			end
		end

		if (hasOneNandoCrypted) then
			return allocated_id -- loading is done async
		end
	end
	
	
	local txdworked,dffworked,colworked = false,false,false

	if txdPath then
		local txd = engineLoadTXD(txdPath)
		if txd then
			txdmodel = txd
			if engineImportTXD(txd,allocated_id) then
				txdworked = true
			end
		end
	end

	if dffPath then
		local dff = engineLoadDFF(dffPath, allocated_id)
		if dff then
			dffmodel = dff
			if engineReplaceModel(dff,allocated_id) then
				dffworked = true
			end
		end
	end

	if colPath then
		local col = engineLoadCOL(colPath)
		if col then
			colmodel = col
			if engineReplaceCOL(col, allocated_id) then
				colworked = true
			end
		end
	end

	if(((txdPath) and (not txdworked))
	or ((dffPath) and (not dffworked))
	or ((colPath) and (not colworked))
	)
	then
		engineResetModelLODDistance(allocated_id)
		engineFreeModel(allocated_id)
		if txdmodel then destroyElement(txdmodel) end -- free memory
		if dffmodel then destroyElement(dffmodel) end -- free memory
		if colmodel then destroyElement(colmodel) end -- free memory

		local reason = ""
		if (txdPath) then
			reason = "TXD: "..(txdworked and "success" or "fail").." "
		end
		if (dffPath) then
			reason = reason.."DFF: "..(dffworked and "success" or "fail").." "
		end
		if (colPath) then
			reason = reason.."COL: "..(colworked and "success" or "fail").." "
		end

		return false, reason
	end

	-- Lod Distance
	if lodDistance then
		print(id, "lodDistance", lodDistance)
		engineSetModelLODDistance(allocated_id, lodDistance)
	end
	
	if isTimer(freeIdTimers[id]) then killTimer(freeIdTimers[id]) end

	allocated_ids[id] = allocated_id
	
	model_elements[allocated_id] = {} -- Save model elements for destroying on deallocation
	
	if dffmodel and isElement(dffmodel) then
		table.insert(model_elements[allocated_id], dffmodel)
	end
	if txdmodel and isElement(txdmodel) then
		table.insert(model_elements[allocated_id], txdmodel)
	end
	if colmodel and isElement(colmodel) then
		table.insert(model_elements[allocated_id], colmodel)
	end

	return allocated_id
end


function forceAllocate(id) -- [Exported]
	id = tonumber(id)
	if not id then return false, "id not number" end
	local isCustom, mod, elementType2 = isCustomModID(id)
	if not isCustom then
		return false, id.." not a custom mod ID"
	end
	local allocated_id = allocated_ids[id]
	if allocated_id then
		return allocated_id
	end
	
	-- allocate as it hasn't been done already
	local allocated_id2, reason = allocateNewMod(nil, elementType2, id)

	-- free instantly if it was allocated
	if allocated_id2 then
		freeAllocatedID(allocated_id2, id, "forceAllocate")
	end

	return allocated_id2, reason
end

function setElementCustomModel(element, elementType, id)
	id = tonumber(id)
	if isElementStreamedIn(element) then

		-- allocate as it hasn't been done already
		local allocated_id = allocated_ids[id]
		if not allocated_id then

			local mod = getModDataFromID(id)
			if not mod.allReady then
				local notReady = {}
				for path, isReady in pairs(mod.readyPaths) do
					if not isReady then
						notReady[#notReady+1] = path
					end
				end

				if #notReady > 0 then
					-- Mod not ready, download files ...

					awaitingSetModel[element] = id

					for i, path in ipairs(notReady) do
						downloadModFile(id, path)
					end
					return true
				end
			end

			local allocated_id2, reason2 = allocateNewMod(element, elementType, id)
			if allocated_id2 then

				-- try setting again
				return setElementCustomModel(element, elementType, id)
			else
				return false, reason2
			end
		end

		if getElementType(element) == "pickup" then
			setPickupType(element, 3, allocated_id)
		else
			setElementModel(element, allocated_id)
		end

		if getElementType(element)=="vehicle" then
			if isTimer(update_properties[element]) then killTimer(update_properties[element]) end
			update_properties[element] = setTimer(function()
				if isElement(element) and not wasElementCreatedClientside(element) then
					triggerServerEvent(resName..":updateVehicleProperties", resourceRoot, element)
				end
				update_properties[element] = nil
			end, 1000, 1)
		end
	end

	return true
end

function freeAllocatedID(allocated_id, id, theEvent)

	engineResetModelLODDistance(allocated_id)
	local worked = engineFreeModel(allocated_id)
	for k, element in pairs(model_elements[allocated_id] or {}) do
		if isElement(element) then
			destroyElement(element)
		end
	end
	model_elements[allocated_id] = nil
	allocated_ids[id] = nil

	outputDebugString("["..theEvent.."] Freed allocated ID "..allocated_id.." (engineFreeModel '"..tostring(worked).."') for mod ID "..id, 3)
	return worked
end

function startFreeingMod(id2, checkStreamedIn, theEvent)
	
	if isTimer(freeIdTimers[id2]) then killTimer(freeIdTimers[id2]) end

	freeIdTimers[id2] = setTimer(function(id, en)

		local allocated_id = allocated_ids[id]
		if not allocated_id then return end
	
		if (checkStreamedIn == true) then

			local oneStreamedIn = false
			for elementType, name in pairs(dataNames) do
				for k,el in ipairs(getElementsByType(elementType)) do
					if isElementStreamedIn(el) then
						local id_ = tonumber(getElementData(el, name))
						if id_ == id then
							oneStreamedIn = true
							break
						end
					end
				end
			end
			if not oneStreamedIn then
				freeAllocatedID(allocated_id, id, en)
			end
		else
			freeAllocatedID(allocated_id, id, en)
		end

		freeIdTimers[id] = nil

	end, FREE_ID_DELAY, 1, id2, theEvent)
end

function freeModIfUnused(id2)

	local mod, et2 = getModDataFromID(id2)
	if mod and mod.disableAutoFree == true then
		outputDebugString("["..(eventName or "?").."] Not freeing mod "..id2.." as it has disableAutoFree set to true", 2)
		return
	end

	startFreeingMod(id2, true, "freeModIfUnused")
end

-- [Exported]
function isModAllocated(id)
	id = tonumber(id)
	if not id then
		return
	end
	return allocated_ids[id]
end

-- [Exported]
function forceFreeAllocated(id, immediate)
	id = tonumber(id)
	if not id then
		return "INVALID_ID"
	end
	local allocated_id = allocated_ids[id]
	if not allocated_id then
		return "NOT_ALLOCATED"
	end

	if (immediate) == true then
		return "FREED", freeAllocatedID(allocated_id, id, "forceFreeAllocated")
	end

	startFreeingMod(id, false, "forceFreeAllocated")
	return "FREED_LATER"
end

-- (1) updateElementOnDataChange
function updateElementOnDataChange(source, theKey, oldValue, newValue)
	if not isElement(source) then return end
	
	local et = getElementType(source)

	local modEt
	for modEt2, dataName2 in pairs(dataNames) do
		if dataName2 == theKey then
			modEt = modEt2
			break
		end
	end
	if not modEt then
		-- Invalid data name
		return
	end
	
	if not isRightModType(et, modEt) then
		outputDebugString("["..(eventName or "?").."] updateElementOnDataChange: "..et.." is not a valid mod type for "..theKey, 1)
		return
	end

	local id = tonumber(newValue)
	if id then -- setting a new model id

		if not received_modlist then
			waiting_queue[source] = {num=1, args={theKey, oldValue, newValue}}
			return
		end

		if isCustomModID( id) then

			local success, reason = setElementCustomModel(source, et, id)
			if not success then
				outputDebugString("["..(eventName or "?").."] Failed setElementCustomModel(source, '"..et.."', "..id.."): "..reason, 1)
			-- else
				-- outputDebugString("["..(eventName or "?").."] setElementCustomModel(source, '"..et.."', "..id..") worked", 3)
			end

		elseif isDefaultID(et, id) then
			outputDebugString("["..(eventName or "?").."] Warning: trying to set "..et.." default ID: "..id, 2)
		else
			outputDebugString("["..(eventName or "?").."] Warning: unknown "..et.." model ID: "..id, 2)
		end
	end

	if tonumber(oldValue) then
		local old_id = tonumber(oldValue)
		local old_allocated_id = allocated_ids[old_id]
		if not old_allocated_id then return end -- was not allocated

		freeModIfUnused(old_id)
	end
end
addEventHandler( "onClientElementDataChange", root, function (theKey, oldValue, newValue) updateElementOnDataChange(source, theKey, oldValue, newValue) end)


-- (2) updateStreamedInElement
function updateStreamedInElement(source)
	if not isElement(source) then return end

	local et = getElementType(source)

	if not isElementTypeSupported(et) then
		return
	end

	local id = tonumber(getElementData(source, dataNames[et]))
	if not (id) then return end -- doesn't have a custom model

	if not received_modlist then
		waiting_queue[source] = {num=2}
		return
	end

	if isCustomModID(id) then

		local success, reason = setElementCustomModel(source, et, id, true)
		if not success then
			outputDebugString("["..(eventName or "?").."] Failed setElementCustomModel(source, '"..et.."', "..id..", true): "..reason, 1)
		end

	elseif isDefaultID(et, id) then
		outputDebugString("["..(eventName or "?").."] Warning: trying to set "..et.." default ID: "..id, 2)
	else
		outputDebugString("["..(eventName or "?").."] Warning: unknown "..et.." model ID: "..id, 2)
	end
end
addEventHandler( "onClientElementStreamIn", root, function () updateStreamedInElement(source) end)


-- (3) updateStreamedOutElement
function updateStreamedOutElement(source)
	if not isElement(source) then return end

	local et = getElementType(source)
	if not isElementTypeSupported(et) then
		return
	end

	local id = tonumber(getElementData(source, dataNames[et]))
	if not (id) then return end -- doesn't have a custom model

	if not received_modlist then
		waiting_queue[source] = {num=3}
		return
	end

	if isCustomModID(id) then

		local allocated_id = allocated_ids[id]
		if not allocated_id then return end -- was not allocated

		freeModIfUnused(id)
	end
end
addEventHandler( "onClientElementStreamOut", root, function () updateStreamedOutElement(source) end)

function handleDestroyedElement()
	if not received_modlist then return end
	local et = getElementType(source)
	if not isElementTypeSupported(et) then
		return
	end

	local id = tonumber(getElementData(source, dataNames[et]))
	if not (id) then return end -- doesn't have a custom model

	if isCustomModID(id) then

		local allocated_id = allocated_ids[id]
		if not allocated_id then return end -- was not allocated

		freeModIfUnused(id)
	end
end
addEventHandler( "onClientElementDestroy", root, handleDestroyedElement)


-- Free waiting_queue memory when player leaves
addEventHandler( "onClientPlayerQuit", root, 
function (reason)
	if waiting_queue[source] then
		waiting_queue[source] = nil
	end
end)

function updateElementsInQueue()
	for element, v in pairs(waiting_queue) do
		local num = v.num
		local args = v.args

		if num == 1 then
			local theKey, oldValue, newValue = unpack(args)
			updateElementOnDataChange(element, theKey, oldValue, newValue)
		elseif num == 2 then
			updateStreamedInElement(element)
		elseif num == 3 then
			updateStreamedOutElement(element)
		end

		waiting_queue[element] = nil
		-- outputDebugString("updateElementsInQueue -> "..num.." on a "..getElementType(element), 3)
	end
	return true
end

function updateStreamedElements(thisId)

	local freed = {}

	for elementType, name in pairs(dataNames) do
		for k,el in ipairs(getElementsByType(elementType)) do
			if isElementStreamedIn(el) then

				local id = tonumber(getElementData(el, name))
				if id and not freed[id] then

					if (not thisId) or (id == thisId) then

						local found = false

						for j,mod in pairs(received_modlist[elementType]) do
							if mod.id == id then
								found = true
								break
							end
						end
						if not found then -- means the mod was removed by a serverside script

							freed[id] = true
							startFreeingMod(id, false, "updateStreamedElements => mod gone")
						else
							local success, reason = setElementCustomModel(el, elementType, id)
							if not success then
								outputDebugString("[updateStreamedElements] Failed setElementCustomModel(source, '"..et.."', "..id.."): "..reason, 1)
							end
						end
					end
				end
			end
		end
	end
	return true
end

function isBusyDownloading() -- [Exported]
	return (busyDownloading == true)
end

function setModFileReady(modId, path)
	for elementType, mods in pairs(received_modlist or {}) do
		for k, mod in pairs(mods) do
			if mod.id == modId then
				received_modlist[elementType][k].readyPaths[path] = true

				local all = true
				for _, path2 in pairs(mod.paths) do
					if not received_modlist[elementType][k].readyPaths[path2] then
						all = false
						break
					end
				end
				if all then
					
					received_modlist[elementType][k].allReady = true
					triggerEvent(resName..":onModFileDownloaded", localPlayer, mod.id)
					
					-- For set element custom model waiting:
					for element, id in pairs(awaitingSetModel) do
						if id == modId then
							if isElement(element) then
								local et = getElementType(element)
								local worked, reason = setElementCustomModel(element, et, id)
								if not worked then
									outputDebugString("[setModFileReady] Failed setElementCustomModel(element, '"..et.."', "..id.."): "..reason, 1)
								end
							end
							awaitingSetModel[element] = nil
						end
					end
				end
			end
		end
	end
end

function onDownloadFailed(modId, path)

	if not fileDLTries[path] then
		fileDLTries[path] = 0
	end
	fileDLTries[path] = fileDLTries[path] + 1

	if fileDLTries[path] == DOWNLOAD_MAX_TRIES then
		if KICK_ON_DOWNLOAD_FAILS then
			triggerServerEvent(resName..":onDownloadFailed", resourceRoot, true, fileDLTries[path], modId, path)
			return "KICKED"
		end
    else
        triggerServerEvent(resName..":onDownloadFailed", resourceRoot, false, fileDLTries[path], modId, path)
    end
	return fileDLTries[path]
end

function handleDownloadFinish(fileName, success, requestRes)
	if requestRes ~= resource then return end
	if not currDownloading then return end
	local modId, path = unpack(currDownloading)

	currDownloading = nil

	local waitDelay = 50
	if not success then

		outputDebugString("Failed to download mod file: "..tostring(fileName), 1)
		
		local result = onDownloadFailed(modId, path)
		if result == "KICKED" then
			return
        elseif result < DOWNLOAD_MAX_TRIES then

            -- place back in queue
            table.insert(fileDLQueue, 1, {modId, path})
            waitDelay = 1000
        end
	else
		setModFileReady(modId, path)
	end

	if #fileDLQueue >= 1 then
		setTimer(downloadFirstInQueue, waitDelay, 1)
	elseif busyDownloading then
		if (SHOW_DOWNLOADING) then removeEventHandler("onClientRender", root, showDownloadingDialog) end
		busyDownloading = false
	end
end
addEventHandler("onClientFileDownloadComplete", root, handleDownloadFinish)

function downloadFirstInQueue()
	local first = fileDLQueue[1]
	if not first then
		outputDebugString("Error getting first in DL queue", 1)
		return
	end

	if (not busyDownloading) then
		busyDownloading = true
		if (SHOW_DOWNLOADING) then addEventHandler("onClientRender", root, showDownloadingDialog) end
	end

	local modId, path = unpack(first)

	currDownloading = {modId, path}

	table.remove(fileDLQueue, 1)

	if not downloadFile(path) then
		outputDebugString("Error trying to download file: "..tostring(path), 1)
		
		local result = onDownloadFailed(modId, path)
		if result == "KICKED" then
			return
        elseif result < DOWNLOAD_MAX_TRIES then

            -- place back in queue
            table.insert(fileDLQueue, 1, {modId, path})
            -- retry after a bit:
            setTimer(function()

                currDownloading = nil

                downloadFirstInQueue() 
            end, 1000, 1)
        end
	end
end

function forceDownloadMod(id) -- [Exported]
	id = tonumber(id)
	if not id then
		return false, "INVALID_ID"
	end
	local isCustom, mod, elementType2 = isCustomModID(id)
	if not isCustom then
		return false, "NOT_CUSTOM_ID"
	end

	if not mod.allReady then
		local notReady = {}
		for path, isReady in pairs(mod.readyPaths) do
			if not isReady then
				notReady[#notReady+1] = path
			end
		end

		if #notReady > 0 then
			-- Mod not ready, download files ...
			for i, path in ipairs(notReady) do
				downloadModFile(id, path)
			end

			return true
		end
	end

	return "MOD_READY"
end

function downloadModFile(modId, path)

	for _, v in ipairs(fileDLQueue) do
		if v[1] == modId and v[2] == path then
			return
		end
	end

	fileDLQueue[#fileDLQueue+1] = {modId, path}

	if busyDownloading then
		return
	end

	if #fileDLQueue >= 1 then
		downloadFirstInQueue()
	end
end

function receiveModList(modList)

	received_modlist = modList

	-- local count = 0
	-- for elementType, mods in pairs(modList) do
	-- 	if not (elementType=="player" or elementType=="pickup") then
	-- 		for _, mod in ipairs(mods) do
	-- 			count = count + 1
	-- 		end
	-- 	end
	-- end
	-- outputDebugString("Received mod list on client ("..count..")", 0, 115, 236, 255)

	outputDebugString("Received mod list on client", 0, 115, 236, 255)

	-- for other resources to handle
	triggerEvent(resName..":onModListReceived", localPlayer, modList)

	if updateElementsInQueue() then
		updateStreamedElements()
	end
end
addEventHandler(resName..":receiveModList", resourceRoot, receiveModList)

addEventHandler( "onClientResourceStop", resourceRoot, -- free memory on stop
function (stoppedResource)
	for id, allocated_id in pairs(allocated_ids) do
		engineResetModelLODDistance(allocated_id)
		engineFreeModel(allocated_id)
	end
end)

addEventHandler( "onClientResourceStart", resourceRoot,
function (startedResource)
	-- search for streamed in elements with custom model ID datas
	-- these were spawned in another resource and set to using custom model ID
	-- we need to apply the model on them

	for elementType, name in pairs(dataNames) do
		for k,el in ipairs(getElementsByType(elementType)) do
			if isElementStreamedIn(el) then
				updateStreamedInElement(el)
			end
		end
	end
end)

local sw, sh = guiGetScreenSize()
function showDownloadingDialog()
	local queueSize = #fileDLQueue
	local text = "Downloading... (".. (queueSize == 1 and "last one" or (queueSize.." left")) ..")\n "
	local curr = currDownloading
	if curr then
		local modId, path = unpack(curr)
		text = text..""..path.." (Mod #"..modId..")"
	end
	dxDrawText(text, 0, 0, sw, 45, tocolor(255, 255, 0, 255), 1.00, "default-bold", "right", "center", false, false, false, false, false)
end
