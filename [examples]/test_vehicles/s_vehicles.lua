-- Loads newmodels functions, which allow usage of custom model IDs "as if they were normal IDs"
loadstring(exports.newmodels_reborn:import())()

-- Vehicle model, x,y,z, rx,ry,rz, interior,dimension
local VEHICLE_SPAWNS = {
    {525, -938.74, 1034.21, 23.59, 3.42, 2.85, 20.27, 0, 0},
    {490, -941.95, 1043.03, 24.25, 355.90, 356.51, 199.00, 0, 0},
    {-1, -951.79, 1069.05, 25.96, 356.28, 356.34, 204.01, 0, 0},
    {-5, -944.88, 1051.90, 24.84, 355.97, 356.23, 198.86, 0, 0},
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
