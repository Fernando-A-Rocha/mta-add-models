--[[
   Resource for Unit Tests
]]

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)
   outputChatBox("unittest_newmodels -#ff80d5 use /bb to teleport to center of map ..", root, 255, 255, 255, true)
end)
addCommandHandler("bb", function(player) setElementPosition(player, 5,5,3.5) end, false, false)

-- Example #4 from documentation
addCommandHandler("testquit", function(thePlayer, cmd)
   -- get the custom skin ID (if any) or the default skin ID defined serverside
   local data_name = exports.newmodels:getDataNameFromType("player")
   local skin = getElementData(thePlayer, data_name) or getElementModel(thePlayer)
   if skin then
      -- TODO: save skin ID in the database
      outputChatBox("Your skin ID: "..skin, thePlayer, 255,126,0)
   end
end, false, false)

--OK
-- print("EXAMPLE PED TEST 1")

-- local ped = createPed(280, 0, 0, 5)
-- setTimer(function()
--    if ped then
--       local data_name = exports.newmodels:getDataNameFromType("ped")
--       if getElementData(ped, data_name) then
--          setElementModel(ped, math.random(162,167))
--       else
--          setElementData(ped, data_name,  math.random(20001, 20003))
--       end
--    end
-- end, 3000, 3)

--OK
-- print("EXAMPLE PED TEST 2")

-- local data_name = exports.newmodels:getDataNameFromType("ped")
-- local ped = createPed(0, 0, 0, 4)
-- setTimer(setElementData, 1000, 1, ped , data_name, 20001)
-- setTimer(setElementPosition, 2500, 1, ped , 3000, 3000, 3000)
-- setTimer(setElementPosition, 5000, 1, ped , 0, 0, 4)
-- setTimer(setElementModel, 8000, 1, ped , 280)


--OK
-- print("EXAMPLE OBJECT TEST 1")

-- local data_name = exports.newmodels:getDataNameFromType("object")
-- local object = createObject(1271, 0, 0, 4)
-- setTimer(setElementData, 1000, 1, object, data_name, 50001)
-- setTimer(setElementPosition, 2500, 1, object, 3000, 3000, 3000)
-- setTimer(setElementPosition, 5000, 1, object, 0, 0, 4)

--OK
-- print("EXAMPLE OBJECT TEST 2")

-- local data_name = exports.newmodels:getDataNameFromType("object")
-- local object = createObject(1271, 0, 0, 4)
-- setTimer(setElementData, 1000, 1, object, data_name, 50001)
-- setTimer(setElementPosition, 2500, 1, object, 3000, 3000, 3000)
-- setTimer(setElementPosition, 5000, 1, object, 0, 0, 4)
-- setTimer(destroyElement, 7000, 1, object)


--[[
--NOT OK: causes recursion (weird behaviour):
   when engineFreeModel happens when element is streamed out
   game force streams the element in
   game sets the model to default 1337
   game force streams the element out
   it triggers the free function again, repeats^
--]]
-- print("EXAMPLE OBJECT TEST")

-- local data_name = exports.newmodels:getDataNameFromType("object")
-- local object = createObject(1271, 0, 0, 4)
-- setTimer(setElementData, 1000, 1, object, data_name, 50001)
-- setTimer(setElementPosition, 2500, 1, object, 3000, 3000, 3000)


--OK
-- print("VEHICLE EXAMPLE TEST")

-- local x,y,z, rx,ry,rz, int,dim = 0,0,5, 0,0,0, 0,0
-- local handling = { ["engineAcceleration"] = 50, ["brakeBias"] = 1, }
-- local data_name = exports.newmodels:getDataNameFromType("vehicle")
-- for k,vehID in pairs({80001,80002}) do
--    if exports.newmodels:isCustomModID(vehID) then
--       local theVehicle = createVehicle(400, x,y,z, rx,ry,rz)
--       if theVehicle then
--          setElementData(theVehicle, data_name, vehID)
--          for property,var in pairs(handling) do
--             setVehicleHandling(theVehicle, property, var)
--          end
--       end
--    end
-- end