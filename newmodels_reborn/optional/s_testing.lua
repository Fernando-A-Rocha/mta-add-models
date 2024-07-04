addCommandHandler("testveh", function(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("Syntax: /"..cmd.." <default or custom id>")
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
    outputChatBox("Vehicle created with ID "..id..".")
end, false, false)

addCommandHandler("testobj", function(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("Syntax: /"..cmd.." <default or custom id>")
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
    outputChatBox("Object created with ID "..id..".")
end, false, false)

addCommandHandler("testped", function(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("Syntax: /"..cmd.." <default or custom id>")
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
    outputChatBox("Ped created with ID "..id..".")
end, false, false)

addCommandHandler("testskin", function(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("Syntax: /"..cmd.." <default or custom id>")
    end
    if not setElementModel(thePlayer, id) then
        return outputChatBox("Failed to set skin.")
    end
    outputChatBox("Skin set to ID "..id..".")
end, false, false)
