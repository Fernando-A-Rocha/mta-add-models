--[[
	Author: https://github.com/Fernando-A-Rocha

	New-Models Vehicle Manager
]]

local addedModels = {}
local dbCon = nil

local function createDBTables()
	for i, execCode in ipairs({
        [[
            CREATE TABLE models (
                id INTEGER NOT NULL,
                baseid INTEGER NOT NULL,
                name TEXT NOT NULL,
                dff TEXT NOT NULL,
                txd TEXT NOT NULL,
                options TEXT NOT NULL,
				handling TEXT NOT NULL,
                updated_at INTEGER NOT NULL,
                updated_by TEXT NOT NULL
            )
        ]]
    }) do
        local query = dbQuery(dbCon, execCode)
        local result = dbPoll(query, -1)
        if not result then
            return false
        end
    end
    return true
end

local function initDB()
    if not dbCon then
        local newDB = not fileExists("custom_models.db")
        dbCon = dbConnect("sqlite", "custom_models.db")
        if not dbCon then
            sendDebugMsg("Erro na conexão ao banco de dados", "ERROR")
            return false
        end
        if newDB then
			if not createDBTables() then
				sendDebugMsg("Erro ao criar tabelas no banco de dados", "ERROR")
				return false
			end
			sendDebugMsg("SQLite database successfully created", "SUCCESS")
		end
	end
    return true
end

function addNewModels()

	local qstr = "SELECT * FROM models"
    local query = dbQuery(function(qh)

        local result = dbPoll(qh, 0)
        if not result then
            sendDebugMsg("Error loading models from DB", "ERROR")
            return
        end

		local listToAdd = {}

        for _, row in ipairs(result) do
            for k, v in pairs(row) do
                if tonumber(v) then
                    row[k] = tonumber(v)
				elseif k == "options" or k == "handling" then
					row[k] = fromJSON(v) or {}
				end
			end

			local ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, disableAutoFree
			
			ignoreTXD = row.options.ignoreTXD or false
			ignoreDFF = row.options.ignoreDFF or false
			ignoreCOL = row.options.ignoreCOL or false
			metaDownloadFalse = row.options.metaDownloadFalse or false
			disableAutoFree = row.options.disableAutoFree or false

			listToAdd[#listToAdd+1] = {
				"vehicle", row.id, row.baseid, row.name, row.dff, row.txd, false,
				ignoreTXD, ignoreDFF, ignoreCOL, metaDownloadFalse, disableAutoFree
			}
			addedModels[row.id] = {
				baseid = row.baseid, name = row.name, dff = row.dff, txd = row.txd, handling = row.handling
			}
        end

		--[[
		This is an async function: mods in the list will be added gradually and if you have too many it may take several seconds
		So don't assume that they've all been added immediately after the function returns true
		Also, please note that if any of your mods has an invalid parameter, an error will be output and it won't get added ]]
		
		local worked, reason = exports[newmodelsResourceName]:addExternalMods_CustomFileNames(listToAdd)
		if not worked then
			sendDebugMsg("Failed to add models: "..tostring(reason), "ERROR")
			addedModels = {}
			return
		end

		updateVehicleHandlings()

    end, dbCon, qstr)
end

function updateVehicleHandlings()

	for k, vehicle in ipairs(getElementsByType("vehicle")) do
    	local customID = getElementData(vehicle, newVehModelDataName)
		if customID then
			local modelInfo = addedModels[customID]
			if modelInfo then
				local handling = modelInfo.handling
				local c = 0
				for k, v in pairs(handling) do
					if setVehicleHandling(vehicle, k, v) then
						c = c + 1
					end
				end
				if c > 0 then
					sendDebugMsg("Updated "..c.." handling properties for vehicle with ID "..customID, "SUCCESS")
				end
			end
		end
	end
end

addEvent("vehicle_manager:saveVehicleHandling", true)
addEventHandler("vehicle_manager:saveVehicleHandling", resourceRoot, function(model, list)
	local f
	if not fileExists("handling/"..model..".json") then
		f = fileCreate("handling/"..model..".json")
	else
		f = fileOpen("handling/"..model..".json")
	end
	if not f then return end
	fileWrite(f, toJSON(list))
	fileClose(f)
end)

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)

	if not initDB() then return end

	addNewModels()
end)
