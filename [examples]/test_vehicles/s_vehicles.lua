-- Loads newmodels functions, which allow usage of custom model IDs "as if they were normal IDs"
exports.newmodels_azul:import()

-- Vehicle model, x,y,z, rx,ry,rz, interior,dimension
local VEHICLE_SPAWNS = {
    { 525, -938.74, 1034.21, 23.59, 3.42,   2.85,   20.27,  0, 0 },
    { 490, -941.95, 1043.03, 24.25, 355.90, 356.51, 199.00, 0, 0 },
    { -1,  -951.79, 1069.05, 25.96, 356.28, 356.34, 204.01, 0, 0 },
    { -5,  -944.88, 1051.90, 24.84, 355.97, 356.23, 198.86, 0, 0 },
}

local function createVehicles()
    for i, data in ipairs(VEHICLE_SPAWNS) do
        local model, x, y, z, rx, ry, rz, interior, dimension = unpack(data)
        local vehicle = createVehicle(model, x, y, z, rx, ry, rz)
        if vehicle then
            setElementInterior(vehicle, interior)
            setElementDimension(vehicle, dimension)
            print("#" .. i .. " - Created vehicle with ID " .. model .. " at " .. x .. ", " .. y .. ", " .. z)
        end
    end
end
addEventHandler("onResourceStart", resourceRoot, createVehicles, false)

-- Outputs, for example:
-- This vehicle has the custom model ID -1, which is based on the default model ID 490 (FBI Rancher)
addCommandHandler("myvehicle", function(player)
    local vehicle = getPedOccupiedVehicle(player)
    if not vehicle then
        outputChatBox("You are not in a vehicle", player, 255, 0, 0)
        return
    end
    local model = getElementModel(vehicle)
    local baseModel = getElementBaseModel(vehicle)
    if model == baseModel then
        outputChatBox(
            "This vehicle has the default model ID " .. model .. " (" ..
            (tostring(getVehicleNameFromModel(model)) or "") .. ")", player, 0, 255, 0)
    else
        if not baseModel then
            outputChatBox(
                "This vehicle has the custom model ID " .. model .. ", but the base model ID could not be determined",
                player,
                255, 0, 0)
            return
        end
        outputChatBox(
            "This vehicle has the custom model ID " ..
            model ..
            ", which is based on the default model ID " ..
            baseModel .. " (" .. (tostring(getVehicleNameFromModel(baseModel)) or "") .. ")", player, 0, 255, 0)
    end
end, false, false)


addEvent("spawnVehicleServer", true)
addEventHandler("spawnVehicleServer", root, function(vehicleID, x, y, z, rot)
    if not vehicleID then
        triggerClientEvent(source, "vehicleSpawnResponse", source, false, "Invalid vehicle ID!")
        return
    end

    -- Get the list of all custom models from newmodels_azul
    local customModels = exports['newmodels_azul']:getCustomModels()

    -- Check if this is a valid vehicle ID (either custom model or default vehicle ID)
    local isValidCustomModel = customModels[vehicleID] and true or false
    local isValidDefaultID = exports['newmodels_azul']:isDefaultID("vehicle", vehicleID)

    -- If it's neither a valid custom model nor a default vehicle ID.. reject it
    if not isValidCustomModel and not isValidDefaultID then
        triggerClientEvent(source, "vehicleSpawnResponse", source, false, "Invalid vehicle ID: " .. vehicleID)
        outputServerLog("Rejected invalid vehicle ID: " .. vehicleID)
        return
    end

    -- now create the vehicle with the verified ID
    local vehicle = exports['newmodels_azul']:createVehicle(vehicleID, x, y, z, 0, 0, rot)

    if isElement(vehicle) then
        local actualModel = getElementModel(vehicle)
        triggerClientEvent(source, "vehicleSpawnResponse", source, true, "Vehicle spawned successfully!")
        outputServerLog("Created vehicle with ID: " .. vehicleID .. ", actual model: " .. actualModel)
    else
        triggerClientEvent(source, "vehicleSpawnResponse", source, false, "Failed to spawn vehicle!")
        outputServerLog("Failed to create vehicle with ID: " .. vehicleID)
    end
end)
