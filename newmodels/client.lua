--[[
	Author: Fernando

	client.lua

	Commands:
		/allocatedids
		/selements
	
	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
]]

-- Test setting:
local SEE_ALLOCATED_TABLE = true -- [testing] automatically executes /allocatedids on startup

-- Custom events:
addEvent("newmodels:receiveModList", true)


local allocated_ids = {} -- { [new id] = allocated id }
local model_elements = {} -- { [allocated id] = {dff,txd[,col]} }
local received_modlist -- will be { [element type] = {...} }
local waiting_queue = {} -- [element] = { func num, args }


function getModNameFromID(elementType, id) -- [Exported - Client Version]
	if not elementType then return end
	if not tonumber(id) then return end
	if not received_modlist then return outputDebugString("getModNameFromID: Client hasn't received modList yet", 1) end

	-- iprint(received_modlist)
	local mods = received_modlist[elementType]
	if mods then
		id = tonumber(id)

		for k,v in pairs(mods) do
			if id == v.id then
				return v.name -- found mod
			end
		end
	end
end

function allocateNewMod(element, elementType, id)

	if not isElementStreamedInLibrary(element) then
		return false, elementType.." element not streamed in"
	end

	-- /!\ only this function doesn't accept 'player'
	-- as type so we need to change that to 'ped'
	local elementType2 = elementType
	if elementType2 == "player" then elementType2 = "ped" end

	local allocated_id = engineRequestModel(elementType2)
	if not allocated_id then
		return false, "Failed: engineRequestModel('"..elementType2.."')"
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
		paths = getActualModPaths(elementType, path, id)
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
	
	allocated_ids[id] = allocated_id
	outputDebugString("["..(eventName or "?").."] New "..elementType.." model ID "..id.." allocated to ID "..allocated_id)
	model_elements[allocated_id] = {dffmodel,txdmodel} -- Save model elements for destroying on deallocation
	if isElement(colmodel) then
		table.insert(model_elements[allocated_id], colmodel)
	end
	return true
end

function setElementCustomModel(element, elementType, id)
	local good, reason = verifySetModelArguments(element, elementType, id)
	if not good then
		return false, reason
	end

	id = tonumber(id)
	if setElementStreamLibrary(element, true) then

		-- allocate as it hasn't been done already
		local allocated_id = allocated_ids[id]
		if not allocated_id then
			local success, reason2 = allocateNewMod(element, elementType, id)
			if success then

				-- try setting again
				return setElementCustomModel(element, elementType, id)
			else
				return false, reason2
			end
		end

		-- refresh model so change can actually have an effect
		local currModel = getElementModel(element)
		if currModel == allocated_id then
			local diffModel = 1
			if currModel == 1 then diffModel = 0 end
			setElementModel(element, diffModel)
		end
		setElementModel(element, allocated_id)
	end

	return true
end

local atimers = {}
local adelay = 5000


function freeElementCustomMod(id, trackElement)
	local allocated_id = allocated_ids[id]
	if not allocated_id then
		return
	end

	-- trackElement = the script will only free that ID of the element is no longer streamed in
	--  OR not tracking any element (aka on stop)
	local et, dataName
	if isElement(trackElement) then
		et = getElementType(trackElement)
		dataName = dataNames[et]
	end

	if isTimer(atimers[id]) then killTimer(atimers[id]) end

	atimers[id] = setTimer(function(a,b,c,el)

		local test1 = ( isElement(el) and not isElementStreamedInLibrary(el) )
		local test2 = ( isElement(el) and isElementStreamedInLibrary(el) and ((not getElementData(el, dataName)) or getElementData(el, dataName) ~= id) )
		local test3 = ( not isElement(el) )


		if test1 or test2 or test3 then

			allocated_ids[id] = nil

			local worked = engineFreeModel(a)
			if test1 then
				outputDebugString("["..(c or "?").."] Freed allocated ID "..a.." for mod ID "..b..": element not streamed in"..((not worked) and (" but engineFreeModel returned false") or ""), 3)
			elseif test2 then
				outputDebugString("["..(c or "?").."] Freed allocated ID "..a.." for mod ID "..b..": element streamed in with different custom model or default model"..((not worked) and (" but engineFreeModel returned false") or ""), 3)
			elseif test3 then
				outputDebugString("["..(c or "?").."] Freed allocated ID "..a.." for mod ID "..b..": no element found"..((not worked) and (" but engineFreeModel returned false") or ""), 3)
			end

			local count = 0
			for k, element in pairs(model_elements[a]) do
				if isElement(element) then
					if destroyElement(element) then
						count = count + 1
					end
				end
			end

			outputDebugString("["..(c or "?").."] Destroyed "..count.." dff/txd/col elements of allocated ID "..a, 0,227, 255, 117)
		end

		atimers[b] = nil
	end, adelay, 1, allocated_id, id, eventName, trackElement)
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

			if isCustomModID(et, id) then

				local success, reason = setElementCustomModel(source, et, id)
				if not success then
					outputDebugString("["..(eventName or "?").."] Failed setElementCustomModel(source, '"..et.."', "..id.."): "..reason, 1)
				else
					outputDebugString("["..(eventName or "?").."] setElementCustomModel(source, '"..et.."', "..id..") worked", 3)
				end

			elseif isDefaultID(et, id) then
				outputDebugString("["..(eventName or "?").."] Warning: trying to set "..et.." default ID: "..id, 2)
			else
				outputDebugString("["..(eventName or "?").."] Warning: unknown "..et.." model ID: "..id, 2)
			end
		
		elseif newValue == nil or newValue == false then

			if tonumber(oldValue) then
				-- removing new model id
				triggerServerEvent("newmodels:resetElementModel", resourceRoot, source, tonumber(oldValue))
			end
		end

		if tonumber(oldValue) then
			local old_id = tonumber(oldValue)
			local old_allocated_id = allocated_ids[old_id]
			if not old_allocated_id then return end -- was not allocated

			if not hasOtherElementsWithModel(source, old_id) then
				freeElementCustomMod(old_id, source)
			else
				outputDebugString("["..(eventName or "?").."] Not freeing allocated ID "..old_allocated_id.." for new "..et.." model ID "..old_id,3)
				return
			end
		end
	end
end
addEventHandler( "onClientElementDataChange", root, function (theKey, oldValue, newValue) updateElementOnDataChange(source, theKey, oldValue, newValue) end)


-- (2) updateStreamedInElement
function updateStreamedInElement(source)

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

	if isCustomModID(et, id) then

		local allocated_id = allocated_ids[id]
		if allocated_id then return end -- ignore if already allocated:
		-- the model only needs to be set once in onClientElementDataChange
		-- note: when an element is streamed out the model is deallocated/freed

		showElementCoords(source)

		local success, reason = setElementCustomModel(source, et, id)
		if not success then
			outputDebugString("["..(eventName or "?").."] Failed setElementCustomModel(source, '"..et.."', "..id.."): "..reason, 1)
		else
			outputDebugString("["..(eventName or "?").."] setElementCustomModel(source, '"..et.."', "..id..") worked", 3)
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

	if isCustomModID(et, id) then

		local allocated_id = allocated_ids[id]
		if not allocated_id then return end -- was not allocated

		showElementCoords(source)

		if not hasOtherElementsWithModel(source, id) then
			freeElementCustomMod(id, source)
		else
			outputDebugString("["..(eventName or "?").."] Not freeing allocated ID "..allocated_id.." for new "..et.." model ID "..id,3)
			return
		end
	end
end
addEventHandler( "onClientElementStreamOut", root, function () updateStreamedOutElement(source) end)
addEventHandler( "onClientElementDestroy", root, function () updateStreamedOutElement(source) end) -- same behavior for stream out

-- (4) updateModelChangedElement
function updateModelChangedElement(source, oldModel, newModel)
	local et = getElementType(source)
	if not isElementTypeSupported(et) then
		return
	end

	if not received_modlist then
		waiting_queue[source] = {num=4, args={oldModel,newModel}}
		return
	end

	outputDebugString("MODEL CHANGE: "..tostring(oldModel).." => "..tostring(newModel), 0, 187,187,187)

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
	if getElementData(source, dataName) and not isCustomModID(et, id) then

		if isElementStreamedInLibrary(source) then
			showElementCoords(source)

            setElementData(source, dataName, nil)
        	outputDebugString("["..(eventName or "?").."] Clearing model data for "..et.." because ID "..id.." is not custom (previous ID: "..tostring(old_id or oldModel)..")",0,238, 255, 156)

			if old_id and isCustomModID(et, old_id)
			and not hasOtherElementsWithModel(source, old_id) then
				freeElementCustomMod(old_id, source)
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
	local x,y,z = getElementPosition(element)
	outputDebugString("["..(eventName or "?").."] "..x..", "..y..", "..z,0, 255,255,255)
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
					-- triggerServerEvent("newmodels:resetElementModel", resourceRoot, source, tonumber(oldValue))
				
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
	-- iprint(modList)

	if updateElementsInQueue() then

		updateStreamedElements()
	end
end
addEventHandler("newmodels:receiveModList", resourceRoot, receiveModList)

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

	if SEE_ALLOCATED_TABLE then
		togSeeAllocatedTable("-", true)
	end

	triggerLatentServerEvent("newmodels:requestModList", resourceRoot)
end)


---------------------------- TESTING PURPOSES ONLY BELOW ----------------------------
------------------- YOU CAN REMOVE THE FOLLOWING FROM THE RESOURCE ------------------

local drawing = false

function togSeeAllocatedTable(cmd, dontspam)
	if not drawing then
		addEventHandler( "onClientRender", root, drawAllocatedTable)
		drawing = true
	else
		removeEventHandler( "onClientRender", root, drawAllocatedTable)
		drawing = false
	end
	if not (type(dontspam)=="boolean") then
		outputChatBox("Displaying allocated_ids on screen: "..(drawing and "Yes" or "No"))
	end
end
addCommandHandler("allocatedids", togSeeAllocatedTable, false)

local sx,sy = guiGetScreenSize()
local dfontsize = 1
local dfont = "default-bold"

function drawAllocatedTable()
	local text = toJSON(allocated_ids)
	local width = dxGetTextWidth(text, dfontsize, dfont)
	local x,y = sx/2 - width/2, 20
	dxDrawText(text, x,y,x,y, "0xffffffff", dfontsize, dfont)
end


function outputStreamedInElements(cmd)
	local tab = {}
	local total = 0

	for elementType, name in pairs(dataNames) do
		local elements = getElementsByType(elementType, getRootElement(), true)
		local count = table.size(elements)
		if count > 0 then
			tab[elementType] = elements
			total = total + count
		end
	end

	outputChatBox("TOTAL: "..total,255,126,0)
	for elementType, elements in pairs(tab) do
			
		outputChatBox(elementType..": "..table.size(elements))
		local dataName = dataNames[elementType]

		for k, element in pairs(elements) do
			local id = tonumber(getElementData(element, dataName))
			if id then
				local extra = ""
				local allocted_id = allocated_ids[id]
				if allocated_id then
					extra = " allocated to ID "..alocated_id
				end
				local x,y,z = getElementPosition(element)
				local int,dim = getElementInterior(element), getElementDimension(element)
				outputChatBox(" - Model ID "..id..extra.." ("..x..", "..y..", "..z.." | int: "..int..", dim: "..dim..")",255,194,14)
			end
		end
	end
end
addCommandHandler("selements", outputStreamedInElements, false)