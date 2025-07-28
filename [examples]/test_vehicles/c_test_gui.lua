local screenW, screenH = guiGetScreenSize()

local windowW, windowH = 300, 200
local windowX, windowY = (screenW - windowW) / 2, (screenH - windowH) / 2
local window = guiCreateWindow(windowX, windowY, windowW, windowH, "Vehicle Spawner", false)

local label = guiCreateLabel(20, 40, 260, 30, "Enter Vehicle ID:", false, window)
guiLabelSetHorizontalAlign(label, "center")

local input = guiCreateEdit(50, 70, 200, 30, "", false, window)

local spawnButton = guiCreateButton(50, 120, 200, 40, "Spawn Vehicle", false, window)

guiSetVisible(window, false)

function spawnVehicleByID(vehicleID)
    if not vehicleID then
        outputChatBox("Error: Please enter a valid number!", 255, 0, 0)
        return
    end

    local x, y, z = getElementPosition(localPlayer)
    local rot = getPedRotation(localPlayer)
    local offsetDistance = 5
    local spawnX = x + offsetDistance * math.sin(math.rad(-rot))
    local spawnY = y + offsetDistance * math.cos(math.rad(-rot))
    
    triggerServerEvent("newmodels-test_vehicles:requestVehicleSpawn", resourceRoot, localPlayer, vehicleID, spawnX, spawnY, z, rot)
end

function requestVehicleSpawn()
    local vehicleID = tonumber(guiGetText(input))
    spawnVehicleByID(vehicleID)
    guiSetVisible(window, false)
    showCursor(false)
    guiSetText(input, "")
end

addEventHandler("onClientGUIClick", spawnButton, requestVehicleSpawn, false)

addEvent("newmodels-test_vehicles:vehicleSpawnResponse", true)
addEventHandler("newmodels-test_vehicles:vehicleSpawnResponse", localPlayer, function(success, message)
    if success then
        outputChatBox(message, 0, 255, 0)
    else
        outputChatBox(message, 255, 0, 0)
    end
end)

function onInputEnter()
    if source == input then
        requestVehicleSpawn()
    end
end

addEventHandler("onClientGUIAccepted", input, onInputEnter)

function toggleSpawnerGUI()
    local visible = guiGetVisible(window)
    guiSetVisible(window, not visible)
    showCursor(not visible)

    if not visible then
        guiBringToFront(input)
        guiFocus(input)
    end
end

bindKey("F4", "down", toggleSpawnerGUI)
addCommandHandler("vspawner", toggleSpawnerGUI, false)
addCommandHandler("spawnveh", function(cmd, id) spawnVehicleByID(tonumber(id)) end, false)
