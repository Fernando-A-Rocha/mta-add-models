--[[
	Author: https://github.com/Fernando-A-Rocha

	New-Models Vehicle Manager

    Commands:
        - /gethandling
]]

local vehicle

function saveVehicleHandling(cmd)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle then
		outputChatBox("You must be in a vehicle to use this command.", 255,110,61)
		return
	end

    local handling = getVehicleHandling(vehicle)
    if not handling then
        outputChatBox("Error getting vehicle handling.", 255,110,61)
        return
    end

    local customID = getElementData(vehicle, newVehModelDataName)
    if not customID then
        outputChatBox("This vehicle's model ID is not custom.", 255,110,61)
        return
    end

    outputChatBox("Saving vehicle handling on server...", 61,255,61)

    triggerServerEvent("vehicle_manager:saveVehicleHandling", resourceRoot, customID, handling)
end
addCommandHandler("gethandling", saveVehicleHandling, false)
