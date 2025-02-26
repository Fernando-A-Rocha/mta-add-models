addCommandHandler("testveh", function(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("Syntax: /"..cmd.." <default or custom id>", thePlayer)
    end
    local x,y,z = getElementPosition(thePlayer)
    local rx,ry,rz = getElementRotation(thePlayer)
    local element = createVehicle(id, x, y, z, rx, ry, rz)
    if not element then
        return outputChatBox("Failed to create vehicle.", thePlayer)
    end
    setElementDimension(element, getElementDimension(thePlayer))
    setElementInterior(element, getElementInterior(thePlayer))
    setElementPosition(thePlayer, x+2, y, z)
    outputChatBox("Vehicle created with ID "..id..".", thePlayer)
end, false, false)

addCommandHandler("testobj", function(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("Syntax: /"..cmd.." <default or custom id>", thePlayer)
    end
    local x,y,z = getElementPosition(thePlayer)
    local rx,ry,rz = getElementRotation(thePlayer)
    local element = createObject(id, x, y, z, rx, ry, rz)
    if not element then
        return outputChatBox("Failed to create object.", thePlayer)
    end
    setElementDimension(element, getElementDimension(thePlayer))
    setElementInterior(element, getElementInterior(thePlayer))
    setElementPosition(thePlayer, x+2, y, z)
    outputChatBox("Object created with ID "..id..".", thePlayer)
end, false, false)

addCommandHandler("testped", function(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("Syntax: /"..cmd.." <default or custom id>", thePlayer)
    end
    local x,y,z = getElementPosition(thePlayer)
    local _,_,rz = getElementRotation(thePlayer)
    local element = createPed(id, x, y, z, rz)
    if not element then
        return outputChatBox("Failed to create ped.", thePlayer)
    end
    setElementDimension(element, getElementDimension(thePlayer))
    setElementInterior(element, getElementInterior(thePlayer))
    setElementPosition(thePlayer, x+2, y, z)
    outputChatBox("Ped created with ID "..id..".", thePlayer)
end, false, false)

addCommandHandler("testskin", function(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("Syntax: /"..cmd.." <default or custom id>", thePlayer)
    end
    if not setElementModel(thePlayer, id) then
        return outputChatBox("Failed to set skin.", thePlayer)
    end
    outputChatBox("Skin set to ID "..id..".", thePlayer)
end, false, false)

addCommandHandler("testspawn", function(thePlayer)
    local x,y,z = getElementPosition(thePlayer)
    local _, _, rz = getElementRotation(thePlayer)
    spawnPlayer(thePlayer, x,y,z, rz, getElementModel(thePlayer), getElementInterior(thePlayer), getElementDimension(thePlayer))
    outputChatBox("Player spawned at current location with skin ID "..getElementModel(thePlayer)..".", thePlayer)
end, false, false)

addCommandHandler("testvehtemp", function(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("Syntax: /"..cmd.." <default or custom id>", thePlayer)
    end
    local x,y,z = getElementPosition(thePlayer)
    local rx,ry,rz = getElementRotation(thePlayer)
    local element = createVehicle(id, x, y, z, rx, ry, rz)
    if not element then
        return outputChatBox("Failed to create vehicle.", thePlayer)
    end
    setElementDimension(element, getElementDimension(thePlayer))
    setElementInterior(element, getElementInterior(thePlayer))
    setElementPosition(thePlayer, x+2, y, z)
    outputChatBox("TEMPORARY Vehicle created with ID "..id..". It will be destroyed in 5 seconds.", thePlayer)
    setTimer(destroyElement, 5000, 1, element)
end, false, false)
