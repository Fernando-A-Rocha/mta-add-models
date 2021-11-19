--[[
	Author: Fernando

	server.lua

	Test Implementation #1
	
	What it does:
		Adds a new skin by reading the myMods array,
		with mod files stored in this resource by calling addExternalMod_CustomFilenames
		To try this skin use /myskin -1 (a newmodels test command)

	Commands:
		/removemod
		/testhandling
]]

local auto_id = -1

local modelsFolder = "mymodels/"

local myMods = {
	-- this is completely a personal choice, you can have your own way of loading mods
	-- type, baseid, name, 			dff path, 	txd path, 	col path,   auto assigned id

	{"ped", 1, "American Biker", "biker.dff", "biker.txd",    nil,           nil         },
	{"vehicle", 489, "Samoa", 	  "samoa.dff", "samoa.txd",    nil,           nil         },
}

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)

	local resName = getResourceName(startedResource)

	for k,mod in pairs(myMods) do

		local et = mod[1]
		local baseid = mod[2]
		local name = mod[3]
		local dff = mod[4]
		local txd = mod[5]
		local col = mod[6]

		local worked, reason = exports.newmodels:addExternalMod_CustomFilenames(
			et, auto_id, baseid, name,
			modelsFolder..dff, modelsFolder..txd, col and modelsFolder..col or nil
		)

		if not worked then
			outputDebugString(reason, 0,255, 110, 61)
		else
			mod[7] = auto_id
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
		if v[7] == id then
			local worked, reason = exports.newmodels:removeExternalMod(id)
			if not worked then
				outputDebugString(reason, 0,255, 110, 61)
			end
			return
		end
	end

	outputChatBox("Mod ID "..id.." not found in myMods because it wasn't added.", thePlayer,255,0,0)
end
addCommandHandler("removemod", removeModCmd, false, false)

function testHandling(thePlayer, cmd)
	local theVehicle = getPedOccupiedVehicle(thePlayer)
	if not theVehicle then
		return outputChatBox("Get inside a vehicle", thePlayer,255,200,0)
	end

	local properties = {
		-- name => min,max that I want
		["engineAcceleration"] = {10, 100},
		["maxVelocity"] = {50, 500},
		["brakeDeceleration"] = {1, 100},
	}
	local randomProperty
	local randomVal
	while not randomVal do
		for k,v in pairs(properties) do
			if math.random(1,2) == 1 then
				randomProperty = k
				randomVal = math.random(v[1], v[2])
				break
			end
		end
	end

	if setVehicleHandling(theVehicle, randomProperty, randomVal) then
		outputChatBox("Set "..randomProperty.." to "..randomVal, thePlayer, 0,255,100)
	else
		outputChatBox("Failed to set "..randomProperty.." to "..randomVal, thePlayer, 255,0,0)
	end
end
addCommandHandler("testhandling", testHandling, false, false)
