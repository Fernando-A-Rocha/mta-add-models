-- Outputs, for example:
-- This vehicle has the custom model ID 80001, which is based on the default model ID 507 (Elegant)
addCommandHandler("myvehicle", function(player)
    local vehicle = getPedOccupiedVehicle(player)
    if not vehicle then
        outputChatBox("You are not in a vehicle", player, 255, 0, 0)
        return
    end
    local serversideModel = getElementModel(vehicle)
    local customModel = exports["newmodels_red"]:getElementCustomModel(vehicle)
    if not customModel then
        outputChatBox(
            "This vehicle has the default model ID " ..
            serversideModel .. " (" .. (tostring(getVehicleNameFromModel(serversideModel)) or "") .. ")", player, 0, 255,
            0)
    else
        local baseModel = exports["newmodels_red"]:getElementBaseModel(vehicle)
        if not baseModel then
            outputChatBox(
                "This vehicle has the custom model ID " ..
                customModel .. ", but the base model ID could not be determined",
                player, 255, 0, 0)
            return
        end
        outputChatBox(
            "This vehicle has the custom model ID " ..
            customModel ..
            ", which is based on the default model ID " ..
            baseModel .. " (" .. (tostring(getVehicleNameFromModel(baseModel)) or "") .. ")", player, 0, 255, 0)
    end
end, false, false)

addEvent("newmodels-test_vehicles:requestVehicleSpawn", true)
addEventHandler("newmodels-test_vehicles:requestVehicleSpawn", resourceRoot, function(vehicleID, x, y, z, rot)
    if not client then return end
    local customModels = exports['newmodels_red']:getCustomModels()
    local isValidCustomModel = customModels[vehicleID] and true or false
    local isValidDefaultID = exports['newmodels_red']:isDefaultID("vehicle", vehicleID)

    if not isValidCustomModel and not isValidDefaultID then
        outputChatBox("Invalid ID", client, 255, 0, 0)
        return
    end

    local vehicle = exports['newmodels_red']:createVehicle(vehicleID, x, y, z, 0, 0, rot)
    if isElement(vehicle) then
        outputChatBox("Vehicle created with ID " .. vehicleID, client, 0, 255, 0)
    else
        outputChatBox("Failed to create vehicle", client, 255, 0, 0)
    end
end, false)
