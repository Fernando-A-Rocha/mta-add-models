-- Alternative method with loadstring
--   These vehicles will not be destroyed if newmodels_azul stops
--   because the elements are children of this resource on creation.

-- Loads newmodels functions, which allow usage of custom model IDs "as if they were normal IDs"
loadstring(exports.newmodels_azul:import())()

-- Vehicle model, x,y,z, rx,ry,rz, interior,dimension
local VEHICLE_SPAWNS = {
    {525, -938.74, 1034.21, 23.59, 3.42, 2.85, 20.27, 0, 0},
    {-5, -944.88, 1051.90, 24.84, 355.97, 356.23, 198.86, 0, 0},
    {-69, -924.62, 1015.67, 22, 355.97, 0, 0, 0, 0},
}

local function createVehicles()
    for i, data in ipairs(VEHICLE_SPAWNS) do
        local model, x, y, z, rx, ry, rz, interior, dimension = unpack(data)
        local vehicle = createVehicle(model, x, y, z, rx, ry, rz)
        if vehicle then
            setElementInterior(vehicle, interior)
            setElementDimension(vehicle, dimension)
            print("test_vehicles [alt] #" .. i .. " - Created vehicle with ID " .. model .. " at " .. x .. ", " .. y .. ", " .. z)
        end
    end
end
addEventHandler("onResourceStart", resourceRoot, createVehicles, false)
