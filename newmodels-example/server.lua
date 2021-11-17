--[[
	Author: Fernando

	server.lua

	Test Implementation #1
	
	What it does:
		Adds a new skin from by reading the myMods array,
		with the files stored in this resource by calling addExternalMod_CustomFilenames
		To try this skin use /myskin -1

	Commands:
		/removemod
]]

local auto_id = -1

local modelsFolder = "mymodels/"

local myMods = {
	-- this is completely a personal choice, you can have your own way of loading mods
	-- type, 	name, 			dff path, 	txd path, 	col path,   auto assigned id
	{"ped", "American Biker", "biker.dff", "biker.txd",    nil,           nil         },
}

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)

	local resName = getResourceName(startedResource)
	local resPrefix = ":"..resName.."/"

	for k,mod in pairs(myMods) do

		local et = mod[1]
		local name = mod[2]
		local dff = mod[3]
		local txd = mod[4]
		local col = mod[5]

		-- format paths
		if dff then
			dff = resPrefix..modelsFolder..dff
		end
		if txd then
			txd = resPrefix..modelsFolder..txd
		end
		if col then
			col = resPrefix..modelsFolder..col
		end


		local worked, reason = exports.newmodels:addExternalMod_CustomFilenames(
			et, auto_id, name,
			dff, txd, col
		)

		if not worked then
			outputDebugString(reason, 0,255, 110, 61)
		else
			mod[6] = auto_id
			auto_id = auto_id -1
		end
	end
end)

function removeModCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [ID from myMods]", thePlayer,255,194,14)
	end
	id = tonumber(id)

	for k,v in pairs(myMods) do
		if v[6] == id then
			local worked, reason = exports.newmodels:removeExternalMod(id)
			if not worked then
				outputDebugString(reason, 0,255, 110, 61)
			end
			return
		end
	end

	outputChatBox("Mod ID "..id.." not found in myMods, maybe it wasn't added.", thePlayer,255,0,0)
end
addCommandHandler("removemod", removeModCmd, false, false)