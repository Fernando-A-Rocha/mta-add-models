--[[
	Author: Fernando

	mod_list.lua
	
	Default mods are defined here

	You can change the 'modsFolder' and 'modsList' variables
	
	If you don't want to have any mods, and instead add your mods with other resources,
	then use the commented 'modList' array below.
]]


modsFolder = "models/"

modList = {
	
	-- stored in server only, then sent to client on request
	-- these are the default mods, more than be added via a function
	
	-- element type
	ped = {

		-- ID must be unique and out of the default GTA & SA-MP ID ranges

		-- Base ID is the model the mod will inherit some properties from
		-- doesn't have much effect on peds or objects, but has on vehicles

		-- file names should be ID.dff ID.txd (ID.col if it's an object)
		-- path can be:
		-- 		local (this resource) when it doesn't start with :
		-- 		external (other resource) when it starts with :

		-- name can be whatever you want

		{id=20001, base_id=1, path=modsFolder, name="Mafioso 1"},
		{id=20003, base_id=1, path=modsFolder, name="Mafioso 2"},
		{id=20002, base_id=1, path=modsFolder, name="Mafioso 3"},
	},

	vehicle = {
		{id=80001, base_id=507, path=modsFolder, name="Schafter"},
		{id=80002, base_id=489, path=modsFolder, name="02 Landstalker"},
		{id=80003, base_id=400, path=modsFolder, name="86 Landstalker 1"},
		{id=80004, base_id=400, path=modsFolder, name="98 Landstalker 1"},
	},

	object = {
		{id=50001, base_id=1337, path=modsFolder, name="Engine Hoist"},
	},
}


-- NO DEFAULT MODS CONFIG:

--[[
	modList = {
		ped = {},
		object = {},
		vehicle = {},
	}
]]