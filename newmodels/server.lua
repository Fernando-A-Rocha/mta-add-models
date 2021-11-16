--[[
	Author: Fernando

	server.lua
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
			outputChatBox("Failed to set your custom skin: "..reason, thePlayer, 255,0,0)
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