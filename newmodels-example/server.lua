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
		/testvehicles
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

--[[
	Fetches all mods using exported func getModList
	Spawns all added vehicles at the airport
]]
local spawned_vehs = {}
local ix,iy,iz = 2045.732421875, -2493.884765625, 13.546875 -- initial position for vehicle spawn (airport)
local rx,ry,rz = 0,0,90
function testVehiclesCmd(thePlayer, cmd)
	for k,veh in pairs(spawned_vehs) do
		if isElement(veh) then destroyElement(veh) end
	end
	spawned_vehs = {}
	local x,y,z = ix,iy,iz
	if getPedOccupiedVehicle(thePlayer) then
		removePedFromVehicle(thePlayer)
	end
	setElementPosition(thePlayer, x+6,y,z)
	setElementDimension(thePlayer, 0)
	setElementInterior(thePlayer, 0)
	local elementType2 = "vehicle"
	local data_name = exports.newmodels:getDataNameFromType(elementType2)
	local modList = exports.newmodels:getModList()
	for elementType, mods in pairs(modList) do
		if elementType == elementType2 then
			for k,mod in pairs(mods) do
				local veh = createVehicle(400, x,y,z,rx,ry,rz)
				if veh then
					setElementData(veh, data_name, mod.id)
					table.insert(spawned_vehs, veh)
					x = x-12
				end
			end
		end
	end

	outputChatBox("Created "..#spawned_vehs.." new vehicles.", thePlayer, 0,255,0)
end
addCommandHandler("testvehicles", testVehiclesCmd, false, false)
