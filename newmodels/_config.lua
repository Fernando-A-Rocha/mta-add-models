--[[
	Author: https://github.com/Fernando-A-Rocha

	_config.lua

	All global config variables are in this file:
]]

----------- GENERAL SCRIPT CONFIGURATION -----------

-- saves custom element model ID in its element data under the following names
dataNames = {
	ped = "skinID",
	vehicle = "vehicleID",
	object = "objectID",
}

dataNames.player = dataNames.ped -- must be the same

-- support pickups with custom object models
dataNames.pickup = dataNames.object -- must be the same

-- saves the element's custom model's base model ID
-- useful for getting a vehicle's base model to fetch its original handling, etc
baseDataName = "baseID"

-- If you are 100% sure that the mods in mod_list.lua are valid, you can disable initial checks
-- for faster startup time
STARTUP_VERIFICATIONS = true

-- Newmodels will try to start these resources (identified by their names) after newmodels has started,
-- as well as stop them when newmodels is stopped
-- Usually these are resources that use newmodels and you want them to start only after newmodels,
-- and they can be stopped when newmodels stops
LINKED_RESOURCES = {
	-- { name = "sampobj_reloaded", start = true, stop = true },
	{ name = "vehicle_manager", start = true, stop = true },
}

-- Mod file download feature
SHOW_DOWNLOADING = true -- display the downloading progress dxDraw
KICK_ON_DOWNLOAD_FAILS = true -- kick player if failed to download a file more than X times
DOWNLOAD_MAX_TRIES = 3 -- Kicked if failed to download a file 3 times, won't happen if above setting is false


-- NandoCrypt | https://github.com/Fernando-A-Rocha/mta-nandocrypt
-- The decrypt function needs to be named ncDecrypt inside a decrypter script (named nando_decrypter by default)
ENABLE_NANDOCRYPT = true
NANDOCRYPT_EXT = ".nandocrypt"

-- Debugging
START_STOP_MESSAGES = true -- enable resouce start/stop automatic chat messages
SEE_ALLOCATED_TABLE = true -- automatically executes /allocatedids on startup
ENABLE_DEBUG_MESSAGES = true -- toggle all debug console messages
CHAT_DEBUG_MESSAGES = true -- make debug console messages to go chatbox (better readability imo)

--[[
	MTA:SA Async library Settings

	Async:setPriority("low");    -- better fps
	Async:setPriority("normal"); -- medium
	Async:setPriority("high");   -- better perfomance
]]
ASYNC_PRIORITY = "normal"

DATANAME_VEH_HANDLING = "newmodels:savedHandling" -- element data name for saved vehicle handling
DATANAME_VEH_UPGRADES = "newmodels:savedUpgrades" -- element data name for saved vehicle upgrades
DATANAME_VEH_PAINTJOB = "newmodels:savedPaintjob" -- element data name for saved vehicle paintjob
