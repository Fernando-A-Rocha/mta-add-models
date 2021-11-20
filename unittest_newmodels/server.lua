--[[
   Resource for Unit Tests
]]

addCommandHandler("bb", function(player) setElementPosition(player, 5,5,3.5) end, false, false)
addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)
   outputChatBox("unittest_newmodels -#ff80d5 use /bb to teleport to center of map ..", root, 255, 255, 255, true)

   -- execute the tests:
   -- test1()
   -- test2()
   -- test3()
   -- test4()
   test5()
   -- test6()


end)


--OK
function test1()
   print("EXAMPLE PED TEST 1")
   local ped = createPed(280, 0, 0, 5)
   setTimer(function()
      if ped then
         local data_name = exports.newmodels:getDataNameFromType("ped")
         if getElementData(ped, data_name) then
            setElementModel(ped, math.random(162,167))
         else
            setElementData(ped, data_name,  math.random(20001, 20003))
         end
      end
   end, 3000, 3)
end

--OK
function test2()
   print("EXAMPLE PED TEST 2")
   local data_name = exports.newmodels:getDataNameFromType("ped")
   local ped = createPed(10, 0, 0, 4)
   setTimer(setElementData, 1000, 1, ped , data_name, 20001)
   setTimer(setElementPosition, 2500, 1, ped , 3000, 3000, 3000)
   setTimer(setElementPosition, 5000, 1, ped , 0, 0, 4)
   setTimer(setElementModel, 8000, 1, ped , 280)
end


--OK
function test3()
   print("EXAMPLE OBJECT TEST 1")
   local data_name = exports.newmodels:getDataNameFromType("object")
   local object = createObject(1271, 0, 10, 4)
   setTimer(setElementData, 1000, 1, object, data_name, 50001)
   setTimer(setElementPosition, 2500, 1, object, 3000, 3000, 3000)
   setTimer(setElementPosition, 5000, 1, object, 0, 0, 4)
end

--OK
function test4()
   print("EXAMPLE OBJECT TEST 2")
   local data_name = exports.newmodels:getDataNameFromType("object")
   local object = createObject(1271, 10, 10, 4)
   setTimer(setElementData, 1000, 1, object, data_name, 50001)
   setTimer(setElementPosition, 2500, 1, object, 3000, 3000, 3000)
   setTimer(setElementPosition, 5000, 1, object, 0, 0, 4)
   setTimer(destroyElement, 7000, 1, object)
end

--[[
--causes recursion (weird behaviour):
   when engineFreeModel happens when element is streamed out
   game force streams the element in
   game sets the model to default 1337
   game force streams the element out
   it triggers the free function again, repeats^

   I have fixed this by detecting the recursion and impeding
   the streaming in from happening when the element is streamed out
   and needs to change its model upon engineFreeModel
--]]
local times = 0
function test5(obj)
   if times == 4 then
      print("You get the idea")
      return
   end
   print("EXAMPLE OBJECT TEST 3")
   local object = obj or createObject(1271, 0, 0, 4)
   local data_name = exports.newmodels:getDataNameFromType("object")
   setTimer(setElementData, 1000, 1, object, data_name, 50001)
   setTimer(setElementPosition, 2500, 1, object, 3000, 3000, 3000)

   setTimer(function()
      setElementPosition(object, 0, 0, 4)
      times = times + 1
      test5(object)
   end, 12000, 1)
end


--OK
function test6()
   print("VEHICLE EXAMPLE TEST")
   local x,y,z, rx,ry,rz, int,dim = 0,0,5, 0,0,0, 0,0
   local handling = { ["engineAcceleration"] = 50, ["brakeBias"] = 1, }
   local data_name = exports.newmodels:getDataNameFromType("vehicle")
   for k,vehID in pairs({80001,80002}) do
      if exports.newmodels:isCustomModID(vehID) then
         local theVehicle = createVehicle(400, x,y,z, rx,ry,rz)
         if theVehicle then
            setElementData(theVehicle, data_name, vehID)
            for property,var in pairs(handling) do
               setVehicleHandling(theVehicle, property, var)
            end
         end
      end
   end
end


-- test 1: set wrong element data on ped
-- expected behavior: it should stay with the skin it spawned with
addCommandHandler("t1", function(thePlayer, cmd)

   local x,y,z = getElementPosition(thePlayer)
   local ped = createPed(0, x,y,z)
   setElementData(ped, "objectID", 20002)

end, false, false)

-- test 2: create ped, set custom skin and destroy it shortly after
-- expected behavior:
   -- frees the model for the client if no other streamed elements are using the same model ID
   -- does nothing if other streamed elements are using the same model ID
addCommandHandler("t2", function(thePlayer, cmd)

   local x,y,z = getElementPosition(thePlayer)
   local ped = createPed(0, x,y,z)
   setElementData(ped, "skinID", 20002)
   outputChatBox("Destroying created ped in 3 secs, observe what happens in debug", thePlayer, 255,194,14)
   setTimer(destroyElement, 3000, 1, ped)

end, false, false)


-- test 3: create ped, set custom skin and remove the model element data
-- expected behavior: model it spawned with should be restored serverside
addCommandHandler("t3", function(thePlayer, cmd)

   local x,y,z = getElementPosition(thePlayer)
   local ped = createPed(280, x,y,z)
   local data_name = exports.newmodels:getDataNameFromType("ped")
   setElementData(ped, data_name, 20001)
   outputChatBox("Removing created ped skin data in 3 secs, observe what happens in debug", thePlayer, 255,194,14)
   setTimer(function(ped, data_name)
      removeElementData(ped, data_name)
   end, 3000, 1, ped, data_name)

end, false, false)

