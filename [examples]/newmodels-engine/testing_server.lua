--[[
	Author: https://github.com/Fernando-A-Rocha

	testing_server.lua
]]

-- This works if you have the default newmodels mods
addCommandHandler("testnewmodelsengine", function(thePlayer)

    setElementPosition(thePlayer, 5,5, 3)
    setElementDimension(thePlayer, 0)
    setElementInterior(thePlayer, 0)

    local obj1 = createObject(50001, 0, 0, 3)
    print("obj2: " .. tostring(getElementModel(obj1)))
    
    local obj2 = createObject(50001, 0, 3, 3)
    print("obj2 before: " .. tostring(getElementModel(obj1)))
    if obj2 then
        setTimer(function()
            print("obj2 set model 1338:", setElementModel(obj2, 1338))
            print("obj2 after: " .. tostring(getElementModel(obj2)))
        end, 2000, 1)
    end

    local pck1 = createPickup(0, 6, 3, 3, 1337)
    print("pck1: " .. tostring(getElementModel(pck1)))

    local pck2 = createPickup(0, 9, 3, 3, 50001)
    print("pck2 before: " .. tostring(getElementModel(pck2)))
    if pck2 then
        setTimer(function()
            print("pck2 set type-model 1569:", setPickupType(pck2, 3, 1569))
            print("pck2 after: " .. tostring(getElementModel(pck2)))
        end, 2000, 1)
    end
    addEventHandler("onPickupHit", resourceRoot, function() cancelEvent() end)

    local ped1 = createPed(20001, 0, 12, 3)
    print("ped1: " .. tostring(getElementModel(ped1)))

    local veh1 = createVehicle(80001, 0, 15, 3)
    print("veh1: " .. tostring(getElementModel(veh1)))
end)