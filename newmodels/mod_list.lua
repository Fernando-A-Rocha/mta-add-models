--[[
	Author: Fernando

	server_mods.lua
	
	Default mods are defined here

	You can change the 'modsFolder' and 'modsList' variables
	
	If you don't want to have any, and instead add your mods with other resources,
	then use the commented 'modList' array below.
]]


modsFolder = "models/"

modList = {
	
	-- stored in server only, then sent to client on request
	-- these are the default mods, more than be added via a function
	
	-- element type
	ped = {

		-- ID must be unique and out of the default GTA & SA-MP ID ranges

		-- file names should be ID.dff ID.txd (ID.col if it's an object)
		-- path can be:
		-- 		local (this resource) when it doesn't start with :
		-- 		external (other resource) when it starts with :

		-- name can be whatever you want

		{id=20001, path=modsFolder, name="Mafioso 1"},
		{id=20003, path=modsFolder, name="Mafioso 2"},
		{id=20002, path=modsFolder, name="Mafioso 3"},
	},

	object = {
		{id=50001, path=modsFolder, name="Engine Hoist"},
	},

	vehicle = {},
}


-- NO DEFAULT MODS CONFIG:
--[[
	modList = {
		ped = {},
		object = {},
		vehicle = {},
	}
]]