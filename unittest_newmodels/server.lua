--[[
   Resource for Unit Tests
]]

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)
   for k, player in ipairs(getElementsByType("player")) do
      setElementPosition(player, 5,5,5)
      outputChatBox("unittest_newmodels -#ff80d5 teleported to center of map", player, 255, 255, 255, true)
   end
end)

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
   NOT OK: causes recursion
engineFreeModel happens when element is streamed out
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