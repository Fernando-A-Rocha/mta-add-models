local function outputInfo(msg, isOK)
    outputServerLog("[" .. getResourceName(resource) .. "] " .. msg)
    if not isOK then
        outputDebugString(msg, 2)
    end
end

local function fetchLatestCallback(data, info)
    if not (data and info and info.success == true) then
        outputInfo("Could not get data from GitHub")
        return
    end

    data = fromJSON(data)
    if not data then
        outputInfo("Could not parse data from GitHub")
        return
    end

    -- fetch version from data
    local version = data.tag_name
    if not version then
        outputInfo("Could not get version from GitHub data")
        outputInfo(inspect(data))
        return
    end

    -- compare versions
    local currentVersion = getResourceInfo(resource, "version")
    if not currentVersion then
        outputInfo("Could not get resource version")
        return
    end

    local foundEqual = false
    local tryStrings = { currentVersion, "v" .. currentVersion } -- check for v prefix
    for _, str in pairs(tryStrings) do
        if str == version then
            foundEqual = true
            break
        end
    end

    if foundEqual then
        outputInfo("You are running the latest version: " .. currentVersion, true)
        return
    end

    -- check if version is superior than currentVersion
    local currentVersionParts = split(currentVersion, ".")
    local currentVersionPartsCount = #currentVersionParts
    local versionParts = split(version, ".")
    local versionPartsCount = #versionParts

    versionParts[1] = versionParts[1]:gsub("v", "")

    if currentVersionPartsCount > versionPartsCount then
        versionPartsCount = currentVersionPartsCount
    end

    -- check if version is inferior than currentVersion
    local inferior = true
    for i = 1, versionPartsCount do
        if tonumber(currentVersionParts[i]) > tonumber(versionParts[i]) then
            inferior = false
            break
        end
    end

    if inferior then
        outputInfo("You are running an inferior version of this resource (" .. currentVersion .. ")")
        outputInfo("Get the latest from: " .. data.html_url)
        return
    end

    outputInfo("You are running an unknown version of this resource (" .. currentVersion .. ")")
end

addEventHandler("onResourceStart", resourceRoot, function()
    fetchRemote("https://api.github.com/repos/Fernando-A-Rocha/mta-add-models/releases/latest", {
        queueName = "newmodels_updater",
        connectionAttempts = 3,
        connectTimeout = 5000,
    }, fetchLatestCallback)
end, false)
