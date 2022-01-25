--[[
	Author: Fernando

	updater_s.lua

	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
--]]

function outputInfo(msg)
	outputServerLog(msg)
	outputDebugString(msg, 0, 255,255,255)
end

addEventHandler("onResourceStart", resourceRoot, function(startedResource)
	fetchRemote("https://api.github.com/repos/Fernando-A-Rocha/mta-add-models/releases/latest", {
		queueName = "newmodels_updater",
		connectionAttempts = 3,
		connectTimeout = 5000,
	}, fetchLatestCallback)
end)

function fetchLatestCallback(data, info)
	if data and info and info.success == true then
		
		local resourceName = string.upper(getResourceName(getThisResource()))

		data = fromJSON(data)
		if not data then
			outputInfo("["..resourceName.." UPDATER] Could not parse data from GitHub")
			return
		end
		
		-- fetch version from data
		local version = data.tag_name
		if not version then
			iprint(data)
			outputInfo("["..resourceName.." UPDATER] Could not get version from GitHub data")
			return
		end

		-- compare versions
		local currentVersion = getResourceInfo(getThisResource(), "version")
		if not currentVersion then
			outputInfo("["..resourceName.." UPDATER] Could not get resource version")
			return
		end

		local foundEqual = false
		local tryStrings = {currentVersion, "v"..currentVersion} -- check for v prefix
		for k, str in pairs(tryStrings) do
			if str == version then
				foundEqual = true
				break
			end
		end

		if not foundEqual then
			outputInfo("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
			outputInfo("["..resourceName.." UPDATER] New version available: " .. version.." (current: "..currentVersion..")")
			outputInfo("["..resourceName.." UPDATER] Get it from: "..data.html_url)
			outputInfo("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
		else
			outputInfo("["..resourceName.." UPDATER] You are running the latest version: "..currentVersion)
		end
	else
		outputInfo("["..resourceName.." UPDATER] Could not get data from GitHub")
	end
end