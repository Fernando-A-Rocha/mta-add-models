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

function allocateNewMod(elementType, id)


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

	local paths = getActualModPaths(elementType, foundMod.path, id)


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

	-- allocate as it hasn't been done already
	local allocated_id = allocated_ids[id]
	if not allocated_id then
		local success, reason2 = allocateNewMod(elementType, id)
		if success then

			-- try setting again
			return setElementCustomModel(element, elementType, id)
		else
			return false, reason2
		end
	end

	setElementModel(element, allocated_id)
	return true
end

function freeElementCustomMod(id)
	local allocated_id = allocated_ids[id]
	if not allocated_id then
		return
	end
	
	allocated_ids[id] = nil
	if engineFreeModel(allocated_id) then
		outputDebugString("["..(eventName or "?").."] Freed allocated ID "..allocated_id.." for mod ID "..id, 3)
	else
		outputDebugString("["..(eventName or "?").."] Freed allocated ID "..allocated_id.." for mod ID "..id.." but engineFreeModel returned false", 2)
	end

	local count = 0
	for k, element in pairs(model_elements[allocated_id]) do
		if isElement(element) then
			if destroyElement(element) then
				count = count + 1
			end
		end
	end
	outputDebugString("["..(eventName or "?").."] Destroyed "..count.." dff/txd/col elements of allocated ID "..allocated_id, 0,227, 255, 117)
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

	if isElementTypeSupported(et) and tonumber(newValue) then
		
		local id = tonumber(newValue)

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
			setElementModel(source, id)
		else
			outputDebugString("["..(eventName or "?").."] Warning: unknown "..et.." model ID: "..id, 2)
		end

		if tonumber(oldValue) then
			local old_id = tonumber(oldValue)
			local old_allocated_id = allocated_ids[old_id]
			if not old_allocated_id then return end -- was not allocated

			if not hasOtherElementsWithModel(source, old_id) then
				freeElementCustomMod(old_id)
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

		local success, reason = setElementCustomModel(source, et, id)
		if not success then
			outputDebugString("["..(eventName or "?").."] Failed setElementCustomModel(source, '"..et.."', "..id.."): "..reason, 1)
		else
			outputDebugString("["..(eventName or "?").."] setElementCustomModel(source, '"..et.."', "..id..") worked", 3)
		end

	elseif isDefaultID(et, id) then
		outputDebugString("["..(eventName or "?").."] default ID: setElementModel(source, "..id..") worked", 3)
		setElementModel(source, id)
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

		if not hasOtherElementsWithModel(source, id) then
			freeElementCustomMod(id)
		else
			outputDebugString("["..(eventName or "?").."] Not freeing allocated ID "..allocated_id.." for new "..et.." model ID "..id,3)
			return
		end
	end
end
addEventHandler( "onClientElementStreamOut", root, function () updateStreamedOutElement(source) end)
addEventHandler( "onClientElementDestroy", root, function () updateStreamedOutElement(source) end) -- same behavior for stream out


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
		outputDebugString("updateElementsInQueue -> "..num.." on a "..getElementType(element), 3)
	end
end

function receiveModList(modList)
	received_modlist = modList
	outputDebugString("Received mod list on client", 0, 115, 236, 255)
	-- iprint(modList)

	updateElementsInQueue()
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
		togSeeAllocatedTable()
	end

	triggerLatentServerEvent("newmodels:requestModList", resourceRoot)
end)


---------------------------- TESTING PURPOSES ONLY BELOW ----------------------------
------------------- YOU CAN REMOVE THE FOLLOWING FROM THE RESOURCE ------------------

local drawing = false

function togSeeAllocatedTable(cmd)
	if not drawing then
		addEventHandler( "onClientRender", root, drawAllocatedTable)
		drawing = true
	else
		removeEventHandler( "onClientRender", root, drawAllocatedTable)
		drawing = false
	end
	outputChatBox("Displaying allocated_ids on screen: "..(drawing and "Yes" or "No"))
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
