--[[
	Author: Fernando

	client.lua
	
	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
]]

-- Custom events:
addEvent(resName..":receiveModList", true)
addEvent(resName..":receiveVehicleHandling", true)
addEvent(resName..":onMapListReceived", true)


allocated_ids = {} -- { [new id] = allocated id }
local model_elements = {} -- { [allocated id] = {dff,txd[,col]} }
local received_modlist -- will be { [element type] = {...} }
local waiting_queue = {} -- [element] = { func num, args }
local atimers = {}
local adelay = 5000

-- Vehicle specific
local update_handling = {} -- [element] = timer

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

	local paths
	local path = foundMod.path
	if type(path)=="table" then
		paths = path
	else
		paths = getActualModPaths(path, id)
	end

	local txdpath = paths.txd

	if not txdpath then
		return false, "Failed to get TXD path for mod ID "..id
	end
	if not fileExists(txdpath) then
		return false, "File doesn't exist: "..txdpath
	end

	local dffpath = paths.dff

	if not dffpath then
		return false, "Failed to get DFF path for mod ID "..id
	end
	if not fileExists(dffpath) then
		return false, "File doesn't exist: "..dffpath
	end

	local colpath
	if elementType == "object" then
		colpath = paths.col
		if not colpath then
			return false, "Failed to get COL path for mod ID "..id
		end
		if not fileExists(colpath) then
			return false, "File doesn't exist: "..colpath
		end
	end

	-- /!\ only this function doesn't accept 'player'
	-- as type so we need to change that to 'ped'
	local elementType2 = elementType
	if elementType2 == "player" then elementType2 = "ped" end

	local allocated_id = engineRequestModel(elementType2, getModDataFromID(id).base_id)
	if not allocated_id then
		return false, "Failed: engineRequestModel('"..elementType2.."')"
	end


	local txdworked,dffworked,colworked = false,false,false
	local txdmodel,dffmodel,colmodel = nil,nil,nil

	local txd = engineLoadTXD(txdpath)
	if txd then
		txdmodel = txd
		if engineImportTXD(txd,allocated_id) then
			txdworked = true
		end
	end

	local dff = engineLoadDFF(dffpath, allocated_id)
	if dff then
		dffmodel = dff
		if engineReplaceModel(dff,allocated_id) then
			dffworked = true
		end
	end

	if colpath then
		local col = engineLoadCOL(colpath)
		if col then
			colmodel = col
			if engineReplaceCOL(col, allocated_id) then
				colworked = true
			end
		end
	end

	local allgood = false
	if col then
		allgood = txdworked and dffworked and colworked
	else
		allgood = txdworked and dffworked
	end

	if not (allgood) then
		engineFreeModel(allocated_id)
		if txdmodel then destroyElement(txdmodel) end -- free memory
		if dffmodel then destroyElement(dffmodel) end -- free memory
		if colmodel then destroyElement(colmodel) end -- free memory
		return false, "Failed to load mod ID "..id..": dff ("..tostring(dffworked)..") txd ("..tostring(txdworked)..") "..(col and ("col ("..tostring(colworked)..")") or "")
	end

	if isTimer(atimers[id]) then killTimer(atimers[id]) end

	allocated_ids[id] = allocated_id
	-- outputDebugString("["..(eventName or "?").."] New "..elementType.." model ID "..id.." allocated to ID "..allocated_id)
	model_elements[allocated_id] = {dffmodel,txdmodel} -- Save model elements for destroying on deallocation
	if isElement(colmodel) then
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

function setElementCustomModel(element, elementType, id)
	local good, reason = verifySetModelArguments(element, elementType, id)
	if not good then
		return false, reason
	end

	id = tonumber(id)
	if isElementStreamedIn(element) then

		-- allocate as it hasn't been done already
		local allocated_id = allocated_ids[id]
		if not allocated_id then
			local allocated_id2, reason2 = allocateNewMod(element, elementType, id)
			if allocated_id2 then

				-- try setting again
				return setElementCustomModel(element, elementType, id)
			else
				return false, reason2
			end
		end

		-- refresh model so change can actually have an effect
		local currModel = getElementModel(element)
		if currModel == allocated_id then

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
			if isTimer(update_handling[element]) then killTimer(update_handling[element]) end
			update_handling[element] = setTimer(function()
				if isElement(element) and not wasElementCreatedClientside(element) then
					triggerServerEvent(resName..":updateVehicleHandling", resourceRoot, element)
				end
				update_handling[element] = nil
			end, 1000, 1)
		end
	end

	return true
end

function freeElementCustomMod(id)
	
	local isCustom, mod, et2 = isCustomModID(id)
	if isTimer(atimers[id]) then killTimer(atimers[id]) end
	atimers[id] = setTimer(function()

		local allocated_id = allocated_ids[id]
		if not allocated_id then return end
	
		local test1, test2
		local foundElement -- try to find an element to track

		for k, element in ipairs(getElementsByType(et2)) do
			local id2 = tonumber(getElementData(element, dataNames[et2]))
			if id2 and id2 == id then
				foundElement = element
				break
			end
		end

		if isElement(foundElement) then
			test1 = ( not isElementStreamedIn(foundElement) )
			test2 = ( isElementStreamedIn(foundElement) and ((not getElementData(foundElement, dataName)) or getElementData(foundElement, dataName) ~= id) )
		end


		if (not isElement(foundElement)) or test1 or test2 then

			local worked = engineFreeModel(allocated_id)

			local r,g,b = 227, 255, 117
			if not worked then
				r,g,b = 252, 44, 3
			end

			if test1 then
				outputDebugString("["..(eventname or "?").."] Freed allocated ID "..allocated_id.." for mod ID "..id..": element not streamed in", 0, r,g,b)
			elseif test2 then
				outputDebugString("["..(eventname or "?").."] Freed allocated ID "..allocated_id.." for mod ID "..id..": element streamed in with different custom model or default model", r,g,b)
			else
				outputDebugString("["..(eventname or "?").."] Freed allocated ID "..allocated_id.." for mod ID "..id..": no element found", 0,r,g,b)
			end

			-- local count = 0
			for k, element in pairs(model_elements[allocated_id] or {}) do
				if isElement(element) then
					if destroyElement(element) then
						-- count = count + 1
					end
				end
			end
			model_elements[allocated_id] = nil
			-- outputDebugString("["..(eventname or "?").."] Destroyed "..count.." dff/txd/col elements of allocated ID "..allocated_id, 0,227, 255, 117)
			
			allocated_ids[id] = nil
		else
			-- outputDebugString("["..(eventname or "?").."] Not freeing allocated ID "..allocated_id.." for mod ID "..id, 0,227, 255, 117)
		end

		atimers[id] = nil
	end, adelay, 1)
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
				else
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

		local allocated_id = allocated_ids[id]
		if allocated_id then
			setElementModel(source, allocated_id)
			return
		end
		-- the model only needs to be set once in onClientElementDataChange
		-- note: when an element is streamed out the model is deallocated/freed

		showElementCoords(source)

		local success, reason = setElementCustomModel(source, et, id)
		if not success then
			outputDebugString("["..(eventName or "?").."] Failed setElementCustomModel(source, '"..et.."', "..id.."): "..reason, 1)
		else
			-- outputDebugString("["..(eventName or "?").."] setElementCustomModel(source, '"..et.."', "..id..") worked", 3)
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

		showElementCoords(source)

		if not hasOtherElementsWithModel(source, id) then
			freeElementCustomMod(id)
		else
			-- outputDebugString("["..(eventName or "?").."] Not freeing allocated ID "..allocated_id.." for new "..et.." model ID "..id,3)
			return
		end
	end
end
addEventHandler( "onClientElementStreamOut", root, function () updateStreamedOutElement(source) end)
addEventHandler( "onClientElementDestroy", root, function () updateStreamedOutElement(source) end) -- same behavior for stream out

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

			showElementCoords(source)

            setElementData(source, dataName, nil)
        	outputDebugString("["..(eventName or "?").."] Clearing model data for "..et.." because ID "..id.." is not custom (previous ID: "..tostring(old_id or oldModel)..")",0,238, 255, 156)

			if old_id and isCustomModID(old_id)
			and not hasOtherElementsWithModel(source, old_id) then
				freeElementCustomMod(old_id)
			end
        end
	end
end
addEventHandler( "onClientElementModelChange", root, function (oldModel, newModel) updateModelChangedElement(source, oldModel, newModel) end)

-- Free waiting_queue memory when player leaves
addEventHandler( "onClientPlayerQuit", root, 
function (reason)
	if waiting_queue[source] then
		waiting_queue[source] = nil
	end
end)

function showElementCoords(element)
	-- local x,y,z = getElementPosition(element)
	-- outputDebugString("["..(eventName or "?").."] "..x..", "..y..", "..z,0, 255,255,255)
end

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

function updateStreamedElements()

	local freed = {}

	for elementType, name in pairs(dataNames) do
		for k,el in ipairs(getElementsByType(elementType, getRootElement(), true)) do
			
			local id = tonumber(getElementData(el, name))
			if id and not freed[id] then

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
	return true
end

function receiveModList(modList)
	received_modlist = modList

	outputDebugString("Received mod list on client", 0, 115, 236, 255)
	triggerEvent(resName..":onMapListReceived", localPlayer) -- for other resources to handle
	-- iprint(modList)

	if updateElementsInQueue() then

		updateStreamedElements()
	end
end
addEventHandler(resName..":receiveModList", resourceRoot, receiveModList)

addEventHandler( "onClientResourceStop", resourceRoot, -- free memory on stop
function (stoppedResource)
	for id, allocated_id in pairs(allocated_ids) do
		freeElementCustomMod(id)
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