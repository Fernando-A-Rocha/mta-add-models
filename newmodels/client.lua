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
		id = id,
		allocated_id = allocated_id,
	}
	return true
end

function setElementCustomMod(element, modType, id)
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
			return setElementCustomMod(element, modType, id)
		else
			return false, reason2
		end
	end

	return setElementModel(element, allocated_info.allocated_id)
end

addEventHandler( "onClientElementDataChange", root, 
function (theKey, oldValue, newValue)
	
	local modType = getDataNameType(theKey)
	if modType and tonumber(newValue) then

		local et = getElementType(source)

		-- Ped support
		if modType == "ped" then
			if not (et == "ped" or et == "player") then
				return
			end
		else
			return
		end
		
		local success, reason = setElementCustomMod(source, modType, newValue)
		if not success then
			outputChatBox("Failed setElementCustomMod(source, '"..modType.."', "..newValue.."): "..reason, 255,0,0)
		else
			outputChatBox("setElementCustomMod(source, '"..modType.."', "..newValue..") worked", 0,255,0)
		end
	end
end)