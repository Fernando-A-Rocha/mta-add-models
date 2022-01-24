--[[
   Resource for Unit Tests

   other tests
]]

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