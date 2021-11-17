--[[
	Author: Fernando

	client.lua
]]

local allocated_ids = {}

function allocatedidsCmd(cmd)
	for allocated_id, v in pairs(allocated_ids) do
		outputChatBox("["..v.modType.."] ID "..v.id.." allocated to ID "..v.allocated_id, 255,194,14)
	end
end
addCommandHandler("allocatedids", allocatedidsCmd, false)

function allocateNewMod(modType, id)

	local allocated_id = engineRequestModel(modType)
	if not allocated_id then
		return false, "Failed: engineRequestModel('"..modType.."')"
	end

	local txdpath = modsFolder..id..".txd"
	local dffpath = modsFolder..id..".dff"
	local colpath

	if modType == "object" then
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
	
	allocated_ids[id] = { -- store info
		modType = modType,
		allocated_id = allocated_id,
	}
	return true
end

addEventHandler( "onClientResourceStop", resourceRoot, -- free memory on stop
function (stoppedResource)
	for id, v in pairs(allocated_ids) do
		freeElementCustomMod(v.modType, id)
	end
end)

function clientSetElementCustomMod(element, modType, id)
	local good, reason = verifySetModArguments(element, modType, id)
	if not good then
		return false, reason
	end

	id = tonumber(id)

	-- allocate as it hasn't been done already
	local allocated_info = allocated_ids[id]
	if not allocated_info then
		local success, reason2 = allocateNewMod(modType, id)
		if success then

			-- try setting again
			return clientSetElementCustomMod(element, modType, id)
		else
			return false, reason2
		end
	end

	setElementModel(element, allocated_info.allocated_id)
	return true
end

function freeElementCustomMod(modType, id)
	local allocated_info = allocated_ids[id]
	if not allocated_info then
		return
	end
	
	local allocated_id = allocated_info.allocated_id
	engineFreeModel(allocated_id)
	allocated_ids[id] = nil
	print("Freed allocated ID "..allocated_id.." for "..modType.." mod ID "..id)
end

addEventHandler( "onClientElementDataChange", root, 
function (theKey, oldValue, newValue)
	
	local modType = getDataTypeFromName(theKey)
	if modType and tonumber(newValue) then
		local id = tonumber(newValue)

		local et = getElementType(source)

		-- Ped support
		if modType == "ped" then
			if not (et == "ped" or et == "player") then
				return
			end
		else
			return
		end
		if et == "player" then et = "ped" end--so it can be recognised in the array

		if isCustomModID(et, id) then

			local success, reason = clientSetElementCustomMod(source, et, id)
			if not success then
				outputChatBox("[onClientElementDataChange] Failed clientSetElementCustomMod(source, '"..et.."', "..id.."): "..reason, 255,0,0)
			else
				outputChatBox("[onClientElementDataChange] clientSetElementCustomMod(source, '"..et.."', "..id..") worked", 0,255,0)
			end

		elseif isDefaultID(et, id) then
			setElementModel(source, id)
		else
			outputChatBox("[onClientElementDataChange] Warning: unknown "..et.." model ID: "..id, 255,255,0)
		end
	end
end)

addEventHandler( "onClientElementStreamIn", root, 
function ()
	local et = getElementType(source)

	-- Ped support
	if not (et == "ped" or et == "player") then
		return
	end
	if et == "player" then et = "ped" end--so it can be recognised in the array

	local id = tonumber(getElementData(source, dataNames[et]))
	if not (id) then return end -- doesn't have a custom model

	if isCustomModID(et, id) then

		local allocated_info = allocated_ids[id]
		if allocated_info then return end -- ignore if already allocated:
		-- the model only needs to be set once in onClientElementDataChange
		-- when a ped/player is streamed out the model is deallocated/freed

		local success, reason = clientSetElementCustomMod(source, "ped", id)
		if not success then
			outputChatBox("[onClientElementStreamIn] Failed clientSetElementCustomMod(source, '"..et.."', "..id.."): "..reason, 255,0,0)
		else
			outputChatBox("[onClientElementStreamIn] clientSetElementCustomMod(source, '"..et.."', "..id..") worked", 0,255,0)
		end

	elseif isDefaultID(et, id) then
		setElementModel(source, id)
	else
		outputChatBox("[onClientElementStreamIn] Warning: unknown "..et.." model ID: "..id, 255,255,0)
	end
end)

addEventHandler( "onClientElementStreamOut", root, 
function ()
	local et = getElementType(source)

	-- Ped support
	if not (et == "ped" or et == "player") then
		return
	end
	if et == "player" then et = "ped" end--so it can be recognised in the array


	local id = tonumber(getElementData(source, dataNames[et]))
	if not (id) then return end -- doesn't have a custom model

	if isCustomModID(et, id) then
		freeElementCustomMod("ped", id)
	end
end)