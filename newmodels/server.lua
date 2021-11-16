--[[
	Author: Fernando

	server.lua
]]


function setElementCustomMod(element, modType, id)
	local good, reason = verifySetModArguments(element, modType, id)
	if not good then
		return false, reason
	end
	
	setElementData(element, dataNames[modType], id)
	return true
end


function customPedCmd(thePlayer, cmd, id)

	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Custom Skin ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

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

	local success, reason = setElementCustomMod(thePed, "ped", id)
	if not success then
		destroyElement(thePed)
		outputChatBox("Failed to set your custom skin: "..reason, thePlayer, 255,0,0)
	end
end
addCommandHandler("pedcustomskin", customPedCmd, false, false)

function customSkinCmd(thePlayer, cmd, id)
	if not tonumber(id) then
		return outputChatBox("SYNTAX: /"..cmd.." [Custom Skin ID]", thePlayer, 255,194,14)
	end
	id = tonumber(id)

	local success, reason = setElementCustomMod(thePlayer, "ped", id)
	if not success then
		outputChatBox("Failed to set your custom skin: "..reason, thePlayer, 255,0,0)
	end
end
addCommandHandler("mycustomskin", customSkinCmd, false, false)

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