--[[
	Author: Fernando

	server.lua

	Test Implementation #1
	
	What it does:
		Adds a new skin & vehicle by reading the myMods array,
		with mod files stored in this resource by calling addExternalMod_CustomFilenames
		See documentation for the newmodels test commands

	Commands:
		/removemod
		/testhandling
		/testvehicles
]]

local myMods = {
	-- this is completely a personal choice, you can have your own way of loading mods
	-- unique ID, type, base model ID or Name, Mod Name, dff path, txd path, col path

	-- https://wiki.multitheftauto.com/wiki/Vehicle_IDs

	{-1, "ped", 1, "American Biker", "mymodels/biker.dff", "mymodels/biker.txd", nil},
	{-2, "vehicle", "Rancher", "Samoa", "mymodels/samoa.dff", "mymodels/samoa.txd", nil},
}

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)

    if not startUpChecks() then return end

	local listToAdd = {}

	for k,mod in pairs(myMods) do

		local uid = mod[1]
		local et = mod[2]
		local baseid = mod[3]
		local name = mod[4]
		local dff = mod[5]
		local txd = mod[6]
		local col = mod[7]

		if type(baseid) == "string" then
            baseid = getVehicleModelFromName(baseid)
        end

        if not baseid then
			outputDebugString("Failed to get vehicle model from name: "..tostring(mod[2]), 0, 255,55,55)
        else
			-- ARGS: elementType, id, base_id, name, path_dff, path_txd, path_col, ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse
			listToAdd[#listToAdd+1] = {et, uid, baseid, name, dff, txd, col, false, false, false, false}
		end
	end

	local count, reason = exports.newmodels:addExternalMods_CustomFileNames(listToAdd)
	if not count then
		outputDebugString("[newmodels-example] Failed to add models: "..tostring(reason), 0, 255,110,61)
		return
	end


	checkPossibleExistingElements()
end)

--[[
	This function makes sure the mods you define in myMods exist & are in the meta.xml (automatically adds/removes in the file)
]]
function startUpChecks()
    print("STARTUP", "Starting scan")  -- You can comment this out to not have startup spam

    local metaXML = xmlLoadFile("meta.xml")
    if not metaXML then
        print("Failed to open meta.xml")
        return false
    end
	local addedAny = false

    local nodes = xmlNodeGetChildren(metaXML)

    -- Check if any of the listed mod files no longer exist in the meta.xml
	for i, node in pairs(nodes) do
		if xmlNodeGetName(node) == "file" then
            local src = xmlNodeGetAttribute(node, "src")
            if not fileExists(src) then
                xmlDestroyNode(node)
                print("AUTO-META","Destroyed XML node coz file not found:", src)
            end
		end
	end

	nodes = xmlNodeGetChildren(metaXML)

    local existing_filenames = {}

    for k,mod in pairs(myMods) do

		local uid = mod[1]
		local et = mod[2]
		local baseid = mod[3]
		local name = mod[4]
		local dff = mod[5]
		local txd = mod[6]
		local col = mod[7]

        local filenames = {dff,txd}
        if col then
            table.insert(filenames, col)
        end

        for _, filename in pairs(filenames) do

            if not fileExists(filename) then
                local found = nil

                for i, node in pairs(nodes) do
                    if node and xmlNodeGetName(node) == "file" then
                        local src = xmlNodeGetAttribute(node, "src")
                        if string.lower(src) == string.lower(filename) then
                            found = node
                            break
                        end
                    end
                end

                if found then
                    xmlDestroyNode(found)
                    print("AUTO-META","Mod #"..k.." "..name, "Destroyed XML node coz file not found:", filename)
                end

                print("AUTO-META", "Mod #"..k.." "..name, "CANCELLING | File not found:", filename)
                return false
            else

                local found = nil

                for i, node in pairs(nodes) do
                    if node and xmlNodeGetName(node) == "file" then
                        local src = xmlNodeGetAttribute(node, "src")
                        if string.lower(src) == string.lower(filename) then
                            found = node
                            break
                        end
                    end
                end

                if not found then
                    local node = xmlCreateChild(metaXML, "file")
                    xmlNodeSetAttribute(node, "src", filename)
                    print("AUTO-META","Mod #"..k.." "..name, "Saved in XML:", filename)
                    addedAny = true
                end

                existing_filenames[filename] = true
            end
        end
    end

	nodes = xmlNodeGetChildren(metaXML)

    -- Purge any files listed in meta.xml that are no longer used in mods
    for i, node in pairs(nodes) do
        if node and xmlNodeGetName(node) == "file" then
            local src = xmlNodeGetAttribute(node, "src")
            if not existing_filenames[src] then
                xmlDestroyNode(node)
                print("AUTO-META","Destroyed XML node coz file no longer used:", src)
            end
        end
    end

    xmlSaveFile(metaXML)
    xmlUnloadFile(metaXML)

    if addedAny then
		
		print("AUTO-META", "Added at least 1 mod file to meta.xml, restarting...")
        restartResource(getThisResource())
		return false
	end

    print("STARTUP", "All checks passed") -- You can comment this out to not have startup spam
    return true
end


--[[
	Checks for existing elements (peds, vehicles) spawned in the server with these mods' unique IDs
]]
local fixDelay = 15000
function checkPossibleExistingElements()

	local check = {}

	for k,mod in pairs(myMods) do

		local uid = mod[1]
		local et = mod[2]
		local baseid = mod[3]
		local name = mod[4]
		local dff = mod[5]
		local txd = mod[6]
		local col = mod[7]

		if not check[et] then check[et] = {} end
		check[et][uid] = true
	end

	-- hack
	check["player"] = check["ped"]

	local fix = {}
	local count = 0

	for type,ids in pairs(check) do
		local dataName = exports.newmodels:getDataNameFromType(type)
		for i,e in pairs(getElementsByType(type)) do
			local uid = tonumber(getElementData(e, dataName))
			if uid and check[type][uid] then
				check[type][uid] = nil

				removeElementData(e, dataName)

				fix[e] = {dataName, uid}
				count = count + 1
			end
		end
	end

	if count > 0 then
		-- Reset after a certain delay (all players need to free the old bugged elements to receive the refresh)
		print("Fixing "..count.." existing leftover modded elements in "..(fixDelay/1000).." seconds")
		setTimer(function()
			for element,v in pairs(fix) do
				-- iprint("FIXED", element, v[1], v[2])
				setElementData(element, v[1], v[2])
			end
		end, fixDelay, 1)
	end
end

--[[
	Some testing commands below
]]

function removeModCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [ID from myMods]", thePlayer,255,194,14)
	end
	id = tonumber(id)

	for k,v in pairs(myMods) do
		if v[1] == id then
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
	math.randomseed(getRealTime().timestamp)
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
				local veh = createVehicle(mod.base_id, x,y,z,rx,ry,rz)
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
