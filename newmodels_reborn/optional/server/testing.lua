addCommandHandler("testveh", function(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("Syntax: /"..cmd.." <custom id>")
    end
    local data = CUSTOM_MODELS[id]
    if not data then
        return outputChatBox("Invalid custom ID.")
    end
    local x,y,z = getElementPosition(thePlayer)
    local rx,ry,rz = getElementRotation(thePlayer)
    local veh = createVehicle(id, x, y, z, rx, ry, rz)
    if not veh then
        return outputChatBox("Failed to create vehicle.")
    end
    setElementDimension(veh, getElementDimension(thePlayer))
    setElementInterior(veh, getElementInterior(thePlayer))
    setElementPosition(thePlayer, x+2, y, z)
    outputChatBox("Vehicle created with custom ID "..id..".")
end, false, false)

addCommandHandler("testobj", function(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("Syntax: /"..cmd.." <custom id>")
    end
    local data = CUSTOM_MODELS[id]
    if not data then
        return outputChatBox("Invalid custom ID.")
    end
    local x,y,z = getElementPosition(thePlayer)
    local rx,ry,rz = getElementRotation(thePlayer)
    local veh = createObject(id, x, y, z, rx, ry, rz)
    if not veh then
        return outputChatBox("Failed to create object.")
    end
    setElementDimension(veh, getElementDimension(thePlayer))
    setElementInterior(veh, getElementInterior(thePlayer))
    setElementPosition(thePlayer, x+2, y, z)
    outputChatBox("Object created with custom ID "..id..".")
end, false, false)

addCommandHandler("testped", function(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("Syntax: /"..cmd.." <custom id>")
    end
    local data = CUSTOM_MODELS[id]
    if not data then
        return outputChatBox("Invalid custom ID.")
    end
    local x,y,z = getElementPosition(thePlayer)
    local rx,ry,rz = getElementRotation(thePlayer)
    local veh = createPed(id, x, y, z, rz)
    if not veh then
        return outputChatBox("Failed to create ped.")
    end
    setElementDimension(veh, getElementDimension(thePlayer))
    setElementInterior(veh, getElementInterior(thePlayer))
    setElementPosition(thePlayer, x+2, y, z)
    outputChatBox("Ped created with custom ID "..id..".")
end, false, false)
