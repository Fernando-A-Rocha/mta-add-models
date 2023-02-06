--[[
	Author: https://github.com/Fernando-A-Rocha

	New-Models Vehicle Manager
]]

addEvent("vehicle_manager:newmodelsFinishedAdding", true)

-- local addedModels = {}
local dbCon = nil

--[[
	May freeze your server in case of DB bugs (only runs once)
]]
local function createDBTables()
	local now = getRealTime().timestamp
	local DEFAULT_OPTIONS = toJSON({
		ignoreTXD = false,
		ignoreDFF = false,
		metaDownloadFalse = true,
		disableAutoFree = false
	})
	local INSERT_MODELS = {
		{-1, 489, "Samoa", "models/samoa.dff", "models/samoa.txd" },
	}
	for i, execCode in ipairs({
        [[
            CREATE TABLE models (
                id INTEGER NOT NULL,
                baseid INTEGER NOT NULL,
                name TEXT NOT NULL,
                dff TEXT NOT NULL,
                txd TEXT NOT NULL,
                options TEXT NOT NULL,
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

		local insertQstr = "INSERT INTO models (id, baseid, name, dff, txd, options, updated_at, updated_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
		for _, row in ipairs(INSERT_MODELS) do
			local query2 = dbQuery(dbCon, insertQstr, row[1], row[2], row[3], row[4], row[5], DEFAULT_OPTIONS, now, "system")
			local result2 = dbPoll(query2, -1)
			if not result2 then
				return false
			end
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
				elseif k == "options" then
					row[k] = fromJSON(v) or {}
				end
			end

			local ignoreTXD, ignoreDFF, metaDownloadFalse, disableAutoFree
			
			ignoreTXD = row.options.ignoreTXD or false
			ignoreDFF = row.options.ignoreDFF or false
			metaDownloadFalse = row.options.metaDownloadFalse or false
			disableAutoFree = row.options.disableAutoFree or false

			listToAdd[#listToAdd+1] = {
				elementType = "vehicle", id = row.id, base_id = row.baseid, name = row.name, path_dff = row.dff, path_txd = row.txd,
				ignoreTXD = ignoreTXD, ignoreDFF = ignoreDFF, metaDownloadFalse = metaDownloadFalse, disableAutoFree = disableAutoFree
			}
			-- addedModels[row.id] = {
			-- 	baseid = row.baseid, name = row.name, dff = row.dff, txd = row.txd
			-- }
        end

		--[[
		This is an async function: mods in the list will be added gradually and if you have too many it may take several seconds
		So don't assume that they've all been added immediately after the function returns true
		Also, please note that if any of your mods has an invalid parameter, an error will be output and it won't get added ]]
		
		local finishedEvent = { name = "vehicle_manager:newmodelsFinishedAdding", source = root }
		local worked, reason = exports[newmodelsResourceName]:addExternalMods_CustomFileNames(listToAdd, finishedEvent)
		if not worked then
			sendDebugMsg("Failed to add models: "..tostring(reason), "ERROR")
			-- addedModels = {}
			return
		end

    end, dbCon, qstr)
end

addEventHandler("vehicle_manager:newmodelsFinishedAdding", root, function()
	outputDebugString("vehicle_manager: all new models have been registered", 3)
	-- proceed ...
end)

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)

	if not initDB() then return end

	addNewModels()
end)
