--[[
	Author: Fernando

	client.lua
	
	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
]]

-- Custom events:
addEvent(resName..":receiveModList", true)
addEvent(resName..":receiveVehicleHandling", true)
addEvent(resName..":onModListReceived", true)
addEvent(resName..":onModFileDownloaded", true)


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

						for k2, v2 in pairs(paths2) do
							local t2,path2 = unpack(v2)
							local data2 = nc_waiting[allocated_id][t2]

							local model
							if t2 == "txd" then
								model = engineLoadTXD(data2)
								engineImportTXD(model,allocated_id)
								-- print("Loaded", "TXD", "Path "..path2)
							elseif t2 == "dff" then
								model = engineLoadDFF(data2, allocated_id)
								engineReplaceModel(model,allocated_id)
								-- print("Loaded", "DFF", "Path "..path2)
							elseif t2 == "col" then
								model = engineLoadCOL(data2)
								engineReplaceCOL(model, allocated_id)
								-- print("Loaded", "COL", "Path "..path2)
							end
							table.insert(model_elements[allocated_id], model)
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

				if not model_elements[allocated_id] then model_elements[allocated_id] = {} end
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
	
	if isTimer(freeIdTimers[id]) then killTimer(freeIdTimers[id]) end

	allocated_ids[id] = allocated_id
	
	-- outputDebugString("["..(eventName or "?").."] New "..elementType.." model ID "..id.." allocated to ID "..allocated_id)
	
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

	if allocated_id2 then
		freeElementCustomMod(id)
	end

	return allocated_id2, reason
end

function setElementCustomModel(element, elementType, id, noRefresh)
	local good, reason = verifySetModelArguments(element, elementType, id)
	if not good then
		return false, reason
	end

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
				return setElementCustomModel(element, elementType, id, noRefresh)
			else
				return false, reason2
			end
		end

		-- refresh model so change can actually have an effect
		local currModel = getElementModel(element)
		if (currModel == allocated_id) and not (noRefresh) then

			-- some logic to refresh model
			local diffModel = 9--ped
			if elementType == "vehicle" then
				diffModel = 400
			elseif elementType == "object" then
				diffModel = 1337
			end
			if currModel == diffModel then
				diffModel = diffModel + 1
			end

			if setElementModel(element, diffModel) then
				setElementModel(element, allocated_id)
			end
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

function doFreeAllocatedId(allocated_id)

	local worked = engineFreeModel(allocated_id)
	for k, element in pairs(model_elements[allocated_id] or {}) do
		if isElement(element) then
			destroyElement(element)
		end
	end
	model_elements[allocated_id] = nil

	return worked
end

function freeElementCustomMod(id2)
	
	local _, __, et2 = isCustomModID(id2)
	if not et2 then
		outputDebugString("["..(eventName or "?").."] freeElementCustomMod error for mod ID "..id2.." - missing element type", 1)
		return
	end

	if isTimer(freeIdTimers[id2]) then killTimer(freeIdTimers[id2]) end

	freeIdTimers[id2] = setTimer(function(id, et, en)

		local dataName = dataNames[et]
		local allocated_id = allocated_ids[id]
		if not allocated_id then return end
	
		local oneStreamedIn = false

		-- check if no elements streamed in have that id
		for k, element in ipairs(getElementsByType(et)) do
			local id3 = tonumber(getElementData(element, dataName))
			if id3 and id3 == id then
				if isElementStreamedIn(element) then
					oneStreamedIn = element
					break
				end
			end
		end

		if not oneStreamedIn then

			local worked = doFreeAllocatedId(allocated_id)

			local r,g,b = 227, 255, 117
			if not worked then
				r,g,b = 252, 44, 3
			end

			outputDebugString("["..(en or "?").."] Freed allocated ID "..allocated_id.." for mod ID "..id..": none streamed in", 0,r,g,b)

			allocated_ids[id] = nil
		end

		freeIdTimers[id] = nil

	end, FREE_ID_DELAY, 1, id2, et2, eventName)
end

function hasOtherElementsWithModel(element, id)
	for elementType, name in pairs(dataNames) do
		for k,el in ipairs(getElementsByType(elementType, getRootElement(), true)) do --streamed in only
			if el ~= element then
				if getElementData(el, name) == id then
					return true
				end
			end
		end
	end
	return false
end

-- (1) updateElementOnDataChange
function updateElementOnDataChange(source, theKey, oldValue, newValue)
	if not isElement(source) then return end

	local data_et = getDataTypeFromName(theKey)
	local et = getElementType(source)
	if et == "player" and data_et == "ped" then data_et = "player" end
	if et == "ped" and data_et == "player" then data_et = "ped" end

	if data_et ~= et then return end

	if isElementTypeSupported(et) then
		
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
		
		elseif newValue == nil or newValue == false then

			if tonumber(oldValue) then
				-- removing new model id
				if not wasElementCreatedClientside(source) then
					triggerServerEvent(resName..":resetElementModel", resourceRoot, source, tonumber(oldValue))
				end
			end
		end

		if tonumber(oldValue) then
			local old_id = tonumber(oldValue)
			local old_allocated_id = allocated_ids[old_id]
			if not old_allocated_id then return end -- was not allocated

			if not hasOtherElementsWithModel(source, old_id) then
				freeElementCustomMod(old_id)
			else
				-- outputDebugString("["..(eventName or "?").."] Not freeing allocated ID "..old_allocated_id.." for new "..et.." model ID "..old_id,3)
				return
			end
		end
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
		-- else
			-- outputDebugString("["..(eventName or "?").."] setElementCustomModel(source, '"..et.."', "..id..", true) worked", 3)
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

		if not hasOtherElementsWithModel(source, id) then
			freeElementCustomMod(id)
		else
			-- outputDebugString("["..(eventName or "?").."] Not freeing allocated ID "..allocated_id.." for new "..et.." model ID "..id,3)
			return
		end
	end
end
addEventHandler( "onClientElementStreamOut", root, function () updateStreamedOutElement(source) end)

-- (4) updateModelChangedElement
function updateModelChangedElement(source, oldModel, newModel)
	if not isElement(source) then return end
	
	local et = getElementType(source)
	if not isElementTypeSupported(et) then
		return
	end

	if not received_modlist then
		waiting_queue[source] = {num=4, args={oldModel,newModel}}
		return
	end

	-- outputDebugString("MODEL CHANGE: "..tostring(oldModel).." => "..tostring(newModel), 0, 187,187,187)

	local id
	for id2, allocated_id in pairs(allocated_ids) do
		if allocated_id == tonumber(newModel) then
			id = id2
			break
		end
	end

	local old_id
	for id2, allocated_id in pairs(allocated_ids) do
		if tonumber(oldModel) == allocated_id then
			old_id = id2
			break
		end
	end


	id = id or newModel
	local dataName = dataNames[et]
	if getElementData(source, dataName) and not isCustomModID(id) then

		if isElementStreamedIn(source) then

            setElementData(source, dataName, nil)
            setElementData(source, baseDataName, nil)

        	outputDebugString("["..(eventName or "?").."] Clearing model data for "..et.." because ID "..id.." is not custom (previous ID: "..tostring(old_id or oldModel)..")",0,238, 255, 156)

			if old_id and isCustomModID(old_id)
			and not hasOtherElementsWithModel(source, old_id) then
				freeElementCustomMod(old_id)
			end
        end
	end
end
addEventHandler( "onClientElementModelChange", root, function (oldModel, newModel) updateModelChangedElement(source, oldModel, newModel) end)

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

		if not hasOtherElementsWithModel(source, id) then
			freeElementCustomMod(id)
			return
		end
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
		elseif num == 4 then
			local oldModel, newModel = unpack(args)
			updateModelChangedElement(element, oldModel, newModel)
		end

		waiting_queue[element] = nil
		-- outputDebugString("updateElementsInQueue -> "..num.." on a "..getElementType(element), 3)
	end
	return true
end

function updateStreamedElements(thisId)

	local freed = {}

	for elementType, name in pairs(dataNames) do
		for k,el in ipairs(getElementsByType(elementType, getRootElement(), true)) do

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
						freeElementCustomMod(id)
					else
						updateStreamedInElement(el)
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
					triggerEvent(resName..":onModFileDownloaded", root, mod.id)
					
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

	if (not KICK_ON_DOWNLOAD_FAILS) then return end

	if not fileDLTries[path] then
		fileDLTries[path] = 0
	end
	fileDLTries[path] = fileDLTries[path] + 1

	if fileDLTries[path] == DOWNLOAD_MAX_TRIES then
		triggerServerEvent(resName..":kickOnDownloadsFail", resourceRoot, modId, path)
		return true
	end
	return false
end

function handleDownloadFinish(fileName, success, requestRes)
	if requestRes ~= getThisResource() then return end
	if not currDownloading then return end
	local modId, path = unpack(currDownloading)

	currDownloading = nil

	local waitDelay = 50

	if not success then

		outputDebugString("Failed to download mod file: "..tostring(fileName), 1)
		if onDownloadFailed(modId, path) then
			return -- Kicked
		end

		-- place back in queue
		table.insert(fileDLQueue, 1, {modId, path})
		waitDelay = 1000
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

	table.remove(fileDLQueue, 1)

	local modId, path = unpack(first)

	currDownloading = {modId, path}

	if not downloadFile(path) then
		outputDebugString("Error trying to download file: "..tostring(path), 1)
		if onDownloadFailed(modId, path) then
			return -- Kicked
		end

		-- retry after a bit:
		setTimer(downloadFile, 1000, 1, path)
	end
end

function forceDownloadMod(id) -- [Exported]
	id = tonumber(id)
	if not id then return false, "id not number" end
	local isCustom, mod, elementType2 = isCustomModID(id)
	if not isCustom then
		return false, id.." not a custom mod ID"
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

	-- Clientside optimisation
	for elementType, mods in pairs(modList) do
		for k, mod in pairs(mods) do

			-- Get actual paths table and set it
			local paths_ = ((type(mod.path)=="table" and mod.path) or (getActualModPaths(mod.path, mod.id)))
			local readyPaths_ = {}

			-- Ignore certain files
			local ignoreTXD, ignoreDFF, ignoreCOL = mod.ignoreTXD, mod.ignoreDFF, mod.ignoreCOL
			for pathType, path2 in pairs(paths_) do
				if (pathType == "txd" and ignoreTXD)
				or (pathType == "dff" and ignoreDFF)
				or (pathType == "col" and (ignoreCOL or elementType ~= "object")) then
					paths_[pathType] = nil
				else
					if mod.metaDownloadFalse then
						readyPaths_[path2] = false
					else
						readyPaths_[path2] = true
					end
				end
			end

			modList[elementType][k].paths = paths_
			modList[elementType][k].readyPaths = readyPaths_

			if not mod.metaDownloadFalse then
				modList[elementType][k].allReady = true
			end
		end
	end

	received_modlist = modList

	outputDebugString("Received mod list on client", 0, 115, 236, 255)

	-- for other resources to handle
	triggerEvent(resName..":onModListReceived", localPlayer)

	if updateElementsInQueue() then
		updateStreamedElements()
	end
end
addEventHandler(resName..":receiveModList", resourceRoot, receiveModList)

addEventHandler( "onClientResourceStop", resourceRoot, -- free memory on stop
function (stoppedResource)
	for id, allocated_id in pairs(allocated_ids) do
		engineFreeModel(allocated_id)
	end
end)

addEventHandler( "onClientResourceStart", resourceRoot,
function (startedResource)
	-- search for streamed in elements with custom model ID datas
	-- these were spawned in another resource and set to using custom model ID
	-- we need to apply the model on them

	for elementType, name in pairs(dataNames) do
		for k,el in ipairs(getElementsByType(elementType, getRootElement(), true)) do
			updateStreamedInElement(el)
		end
	end

	triggerLatentServerEvent(resName..":requestModList", resourceRoot)
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
