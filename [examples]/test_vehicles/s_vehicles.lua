-- Method with exports
--   These vehicles will be destroyed if newmodels_azul stops
--   because they are children of that resource.

-- Vehicle model, x,y,z, rx,ry,rz, interior,dimension
local VEHICLE_SPAWNS = {
    {490, -941.95, 1043.03, 24.25, 355.90, 356.51, 199.00, 0, 0},
    {-1, -947.94, 1060.05, 25.96, 356.28, 356.34, 204.01, 0, 0},
}

local function createVehicles()
    for i, data in ipairs(VEHICLE_SPAWNS) do
        local model, x, y, z, rx, ry, rz, interior, dimension = unpack(data)
        local vehicle = exports["newmodels_azul"]:createVehicle(model, x, y, z, rx, ry, rz)
        if vehicle then
            setElementInterior(vehicle, interior)
            setElementDimension(vehicle, dimension)
            print("test_vehicles #" .. i .. " - Created vehicle with ID " .. model .. " at " .. x .. ", " .. y .. ", " .. z)
        end
    end
end
addEventHandler("onResourceStart", resourceRoot, createVehicles, false)
