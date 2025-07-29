-- Outputs, for example:
-- This vehicle has the custom model ID -1, which is based on the default model ID 490 (FBI Rancher)
addCommandHandler("myvehicle", function(player)
    local vehicle = getPedOccupiedVehicle(player)
    if not vehicle then
        outputChatBox("You are not in a vehicle", player, 255, 0, 0)
        return
    end
    local serversideModel = getElementModel(vehicle)
    local customModel = exports["newmodels_azul"]:getElementCustomModel(vehicle)
    if not customModel then
        outputChatBox("This vehicle has the default model ID " .. serversideModel .. " ("..(tostring(getVehicleNameFromModel(serversideModel)) or "")..")", player, 0, 255, 0)
    else
        local baseModel = exports["newmodels_azul"]:getElementBaseModel(vehicle)
        if not baseModel then
            outputChatBox("This vehicle has the custom model ID " .. customModel .. ", but the base model ID could not be determined", player, 255, 0, 0)
            return
        end
        outputChatBox("This vehicle has the custom model ID " .. customModel .. ", which is based on the default model ID " .. baseModel .. " ("..(tostring(getVehicleNameFromModel(baseModel)) or "")..")", player, 0, 255, 0)
    end
end, false, false)

addEvent("newmodels-test_vehicles:requestVehicleSpawn", true)
addEventHandler("newmodels-test_vehicles:requestVehicleSpawn", resourceRoot, function(player, vehicleID, x, y, z, rot)
    
    local customModels = exports['newmodels_azul']:getCustomModels()
    local isValidCustomModel = customModels[vehicleID] and true or false
    local isValidDefaultID = exports['newmodels_azul']:isDefaultID("vehicle", vehicleID)
    
    if not isValidCustomModel and not isValidDefaultID then
        triggerClientEvent(player, "newmodels-test_vehicles:vehicleSpawnResponse", player, false, "Invalid ID")
        return
    end
    
    local vehicle = exports['newmodels_azul']:createVehicle(vehicleID, x, y, z, 0, 0, rot)
    
    if isElement(vehicle) then
        triggerClientEvent(player, "newmodels-test_vehicles:vehicleSpawnResponse", player, true, "Vehicle spawned")
    else
        triggerClientEvent(player, "newmodels-test_vehicles:vehicleSpawnResponse", player, false, "Failed")
    end
end)
