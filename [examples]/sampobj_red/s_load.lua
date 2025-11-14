--[[
	Author: https://github.com/Fernando-A-Rocha

	SA-MP Objects [Red] for Newmodels v6

	Adds all SA-MP objects to the game using the newmodels system
]]

addEventHandler("onResourceStart", resourceRoot, function()
	local MODELS_FOLDER = "models/"
	local folderPath = ":" .. getResourceName(resource) .. "/" .. MODELS_FOLDER
	local listToAdd = {}

	for id, modelInfo in pairs(getSAMPObjectModels()) do
		listToAdd[#listToAdd + 1] = {
			type = "object",
			base_id = 1337,
			id = id,
			name = modelInfo[1]:gsub(".dff", ""),
			path = {
				dff = folderPath .. id .. ".dff",
				txd = folderPath .. id .. ".txd",
				col = folderPath .. id .. ".col",
			},
			metaDownloadFalse = true,
		}
	end

	-- Async loading
	exports["newmodels_red"]:addExternalModels(listToAdd, true)
end, false)
