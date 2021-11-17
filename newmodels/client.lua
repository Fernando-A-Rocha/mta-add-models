--[[
	Author: Fernando

	client.lua

	Commands:
		/allocatedids
		/selements
]]

local SEE_ALLOCATED_TABLE = true -- automatically executes /allocatedids on startup

local allocated_ids = {}

function allocateNewMod(elementType, id)

	-- /!\ doesn't take 'player' as type so we need to force that to 'ped'
	local elementType2 = elementType
	if elementType2 == "player" then elementType2 = "ped" end

	local allocated_id = engineRequestModel(elementType2)
	if not allocated_id then
		return false, "Failed: engineRequestModel('"..elementType2.."')"
	end

	local txdpath = modsFolder..id..".txd"
	local dffpath = modsFolder..id..".dff"
	local colpath

	if elementType == "object" then
		colpath = modsFolder..id..".col"
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

addEventHandler( "onClientElementDataChange", root, 
function (theKey, oldValue, newValue)
	
	local et = getElementType(source)
	if isElementTypeSupported(et) and tonumber(newValue) then
		
		local id = tonumber(newValue)

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
end)

function updateStreamedInElement(source)
	local et = getElementType(source)

	if not isElementTypeSupported(et) then
		return
	end

	local id = tonumber(getElementData(source, dataNames[et]))
	if not (id) then return end -- doesn't have a custom model

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

function updateStreamedOutElement(source)
	local et = getElementType(source)

	if not isElementTypeSupported(et) then
		return
	end

	local id = tonumber(getElementData(source, dataNames[et]))
	if not (id) then return end -- doesn't have a custom model

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
end)