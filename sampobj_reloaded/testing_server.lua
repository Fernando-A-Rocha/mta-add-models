--[[
	Author: Fernando

	testing_server.lua

	Commands:
		- /rsampobj: Spawns a random SA-MP object at your position
]]

addCommandHandler("rsampobj", function(thePlayer)
	local x,y,z = getElementPosition(thePlayer)
	local rx,ry,rz = getElementRotation(thePlayer)
	local int,dim = getElementInterior(thePlayer), getElementDimension(thePlayer)

	local obj = createObject(1337, x,y,z,rx,ry,rz)
	if not obj then
		return outputChatBox("Error spawning object", thePlayer,255,0,0)
	end
	setElementInterior(obj, int)
	setElementDimension(obj, dim)
	local data_name = exports.newmodels:getDataNameFromType("object")
	if data_name then
		local rid = ids[math.random(1,#ids)]
		setElementData(obj, data_name, rid)
		outputChatBox("Created SA-MP object ID "..rid, thePlayer, 0,255,0)
	end
end, false, false)