--[[
	Author: Fernando

	server.lua

	Commands:
		/pedskin
		/myskin
		/makeobject
		/listmods
]]


function setElementCustomModel(element, modType, id)
	local good, reason = verifySetModArguments(element, modType, id)
	if not good then
		return false, reason
	end
	
	setElementData(element, dataNames[modType], id)
	return true
end


function pedSkinCmd(thePlayer, cmd, id)

	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Skin ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	if isCustomModID("ped", id) or isDefaultID("ped", id) then


		local x,y,z = getElementPosition(thePlayer)
		local rx,ry,rz = getElementRotation(thePlayer)
		local int,dim = getElementInterior(thePlayer), getElementDimension(thePlayer)

		local thePed = createPed(1, x,y,z)
		if not thePed then
			return outputChatBox("Error spawning ped", thePlayer, 255,0,0)
		end
		setElementInterior(thePed, int)
		setElementDimension(thePed, dim)
		setElementRotation(thePed, rx,ry,rz, "default",true)

		local success, reason = setElementCustomModel(thePed, "ped", id)
		if not success then
			destroyElement(thePed)
			outputChatBox("Failed to set ped custom skin: "..reason, thePlayer, 255,0,0)
		end
	else
		outputChatBox("Ped model ID "..id.." is not defined", thePlayer,255,0,0)
	end
end
addCommandHandler("pedskin", pedSkinCmd, false, false)

function mySkinCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Skin ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	if isCustomModID("ped", id) or isDefaultID("ped", id) then

		local success, reason = setElementCustomModel(thePlayer, "ped", id)
		if not success then
			outputChatBox("Failed to set your custom skin: "..reason, thePlayer, 255,0,0)
		end
	else
		outputChatBox("Ped model ID "..id.." is not defined", thePlayer,255,0,0)
	end
end
addCommandHandler("myskin", mySkinCmd, false, false)

function objectModelCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Object ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	if isCustomModID("object", id) or isDefaultID("object", id) then


		local x,y,z = getElementPosition(thePlayer)
		local rx,ry,rz = getElementRotation(thePlayer)
		local int,dim = getElementInterior(thePlayer), getElementDimension(thePlayer)

		local theObject = createObject(1337, x,y,z)
		if not theObject then
			return outputChatBox("Error spawning object", thePlayer, 255,0,0)
		end
		setElementInterior(theObject, int)
		setElementDimension(theObject, dim)
		setElementRotation(theObject, rx,ry,rz)

		local success, reason = setElementCustomModel(theObject, "object", id)
		if not success then
			destroyElement(theObject)
			outputChatBox("Failed to set object custom ID: "..reason, thePlayer, 255,0,0)
		end

		setElementPosition(thePlayer, x,y,z+4)
	else
		outputChatBox("Object model ID "..id.." is not defined", thePlayer,255,0,0)
	end
end
addCommandHandler("makeobject", objectModelCmd, false, false)

function listModsCmd(thePlayer, cmd)

	outputChatBox("List of defined mods:", thePlayer,255,126,0)
	for modType, mods in pairs(modList) do
		outputChatBox(modType.." mods:", thePlayer,255,194,100)
		for k, mod in pairs(mods) do
			outputChatBox("ID "..mod.id.." - "..mod.name, thePlayer,255,194,14)
		end
	end
end
addCommandHandler("listmods", listModsCmd, false, false)


addEventHandler( "onResourceStart", resourceRoot, -- startup message
function (startedResource)
	local version = getResourceInfo(startedResource, "version") or false
	outputChatBox("#ffc175[mta-add-models] #ffffff"..getResourceName(startedResource)..(version and (" "..version) or ("")).." #ffc175started", root,255,255,255, true)
end)
addEventHandler( "onResourceStop", resourceRoot, -- startup message
function (stoppedResource)
	local version = getResourceInfo(stoppedResource, "version") or false
	outputChatBox("#ffc175[mta-add-models] #ababab"..getResourceName(stoppedResource)..(version and (" "..version) or ("")).." #ffc175stopped", root,255,255,255, true)
end)