--[[
	Author: https://github.com/Fernando-A-Rocha

	mod_list.lua

	
	Default mods are defined here in 'modList'.
	
	If you to add your mods with other resources (recommended) then you can delete this file.
		The server will assume an empty modList.
]]

-- ....................................... modList explained .......................................
	
-- The following mod list is stored in server only, then sent to client on request
-- These are the default mods, more than be added via functions from other resources

-- 'id' must be unique and out of the default GTA (& preferrably SA-MP too) ID ranges

-- 'base_id' is the model the mod will inherit some properties from
--	Doesn't make much difference on peds(skins), but it does on vehicles & objects

-- 'path' can be:
--		a string, in which case it expects files to be named ID.dff or ID.txd in that folder
-- 		an array(table), in which case it expects an array of file names like {dff="filepath.dff", txd="filepath.txd", col="filepath.col"}
--  		For files encrypted using NandoCrypt, don't add the .nandocrypt extension, it's defined by the 'NANDOCRYPT_EXT' setting
-- 	All paths defined manually in this file need to be local (this resource)
--		To add a mod from another resource see the examples provided in the documentation.

-- 'name' can be whatever you want (string)

-- + optional parameters:

-- 		'lodDistance' : custom LOD distance in GTA units (number), see possible values https://wiki.multitheftauto.com/wiki/EngineSetModelLODDistance
-- 		'ignoreTXD', 'ignoreDFF', 'ignoreCOL' : if true, the script won't try to load TXD/DFF/COL for the mod
--		'metaDownloadFalse' : if true, the mod will be only be downloaded when needed (when trying to set model)
-- 		'disableAutoFree' : if true, the allocated mod ID will not be freed when no element streamed in is no longer using the mod ID
--  		This causes the mod to stay in memory, be careful when enabling for big mods
-- 		'filteringEnabled' (engineLoadTXD)
-- 		'alphaTransparency' (engineReplaceModel)

modList = {
	
	ped = {

		{id=20001, base_id=1, path="models/peds/", name="Mafioso 1"},
		{id=20003, base_id=1, path="models/peds/", name="Mafioso 2"},
		{id=20002, base_id=1, path="models/peds/", name="Mafioso 3", metaDownloadFalse = true},
	},

	vehicle = {
		{id=80001, base_id=507, path="models/vehicles/", name="Schafter", disableAutoFree=true},
		{id=80002, base_id=489, path="models/vehicles/", name="02 Landstalker"},
		{id=80003, base_id=400, path="models/vehicles/", name="86 Landstalker 1"},
		{id=80004, base_id=400, path="models/vehicles/", name="98 Landstalker 1"},
		{id=80005, base_id=468, path="models/vehicles/", name="Sanchez Test", ignoreTXD=true},
		{id=80006, base_id=507, path={dff="models/vehicles/elegant.dff", txd="models/vehicles/elegant.txd"}, name="Elegant Test"},
	},

	object = {
		{id=50001, base_id=1337, path="models/objects/", name="Engine Hoist"},
		{id=50002, base_id=3594, lodDistance=300, path={txd="models/objects/wrecked_car.txd", dff="models/objects/wrecked_car1.dff", col="models/objects/wrecked_car1.col"}, name="Wrecked Car 1"},
		{id=50003, base_id=3593, lodDistance=300, path={txd="models/objects/wrecked_car.txd", dff="models/objects/wrecked_car2.dff", col="models/objects/wrecked_car2.col"}, name="Wrecked Car 2"},
	},
}
