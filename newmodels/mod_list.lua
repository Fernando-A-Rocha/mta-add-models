--[[
	Author: Fernando

	mod_list.lua
	
	Default mods are defined here

	You can change the 'modsFolder' and 'modsList' variables
	
	If you don't want to have any mods, and instead add your mods with other resources,
	then use the commented 'modList' array below.
]]

local modsFolder = "models/"

modList = {
	
	-- stored in server only, then sent to client on request
	-- these are the default mods, more than be added via a function
	
	-- element type
	ped = {

		-- ID must be unique and out of the default GTA (& preferrably SA-MP too) ID ranges

		-- Base ID is the model the mod will inherit some properties from
		-- Doesn't have much effect on peds or objects, but has on vehicles

		-- path can be:
		--		a string, in which case it expects files to be named ID.dff or ID.txd in that folder
		-- 		an array, in which case it expects an array of file names like {dff="filepath.dff", txd="filepath.txd"}
		--
		-- 	All paths defined manually in this file need to be local (this resource)
		-- 	To add a mod from another resource see the examples provided in the documentation.

		-- name can be whatever you want (string)

		-- + optional parameters:
		-- 		ignoreTXD, ignoreDFF, ignoreCOL : if true, the script won't try to load TXD/DFF/COL for the mod
		--		metaDownloadFalse : if true, the mod will be only be downloaded when needed (when trying to set model)


		{id=20001, base_id=1, path=modsFolder, name="Mafioso 1"},
		{id=20003, base_id=1, path=modsFolder, name="Mafioso 2"},
		{id=20002, base_id=1, path=modsFolder, name="Mafioso 3", metaDownloadFalse = true},
	},

	vehicle = {
		{id=80001, base_id=507, path=modsFolder, name="Schafter"},
		{id=80002, base_id=489, path=modsFolder, name="02 Landstalker"},
		{id=80003, base_id=400, path=modsFolder, name="86 Landstalker 1"},
		{id=80004, base_id=400, path=modsFolder, name="98 Landstalker 1"},
		{id=80005, base_id=468, path=modsFolder, name="Sanchez Test", ignoreTXD=true},

		-- NandoCrypt test
		{id=80006, base_id=507, path=modsFolder, name="Elegant Test"},
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