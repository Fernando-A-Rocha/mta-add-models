 --[[
	Author: Fernando

	New-Weapons [Serverside]

    -- https://wiki.multitheftauto.com/wiki/Weapons
    -- https://gtaforums.com/topic/917058-slingshot753s-workshop/
]]

addEvent("new-weapons:handlePlayerWeaponSwitch", true)

weapList = {
    {uid=90000, baseobjid=1337, baseweapon=5, name="New Bat", dff="objects/Bat.dff", txd="objects/Bat.txd", col="objects/empty.col", bone="right-hand", ds=false, scale=1,
        pos={ 0, 0.016, -0.043,   0, 0, 0 }
    },
    {uid=90001, baseobjid=1337, baseweapon=8, name="Axe", dff="objects/Axe.dff", txd="objects/Axe.txd", col="objects/empty.col", bone="right-hand", ds=false, scale=1,
        pos={ -0.061, 0.133, 0,   -4, -15, -90 }
    },
    {uid=90002, baseobjid=348, baseweapon=22, name="Glock 25", dff="objects/DesertEagle50.dff", txd="objects/DesertEagle50_Gold.txd", col=nil, bone="right-hand", ds=false, scale=1,
        pos={ -0.061, 0.133, 0,   -4, -15, -90 }
    },
}

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)

	for k,mod in pairs(weapList) do

		local uid = mod.uid
		local baseweapon = mod.baseweapon
        local baseobjid = mod.baseobjid
		local name = mod.name
		local dff = mod.dff
		local txd = mod.txd
		local col = mod.col
        local bone = mod.bone
        local ds = mod.ds
        local scale = mod.scale
        local pos = mod.pos

		if type(baseweapon) == "string" then
            baseweapon = getWeaponIDFromName(baseweapon)
        end
        if not baseweapon then
			outputDebugString("Failed to get weapon model from name: "..tostring(mod.baseweapon), 0, 255,55,55)
        else
            if type(dff)~="string" then
                outputDebugString("Missing DFF path for mod ID "..uid, 0, 255,55,55)
            elseif type(txd)~="string" then
                outputDebugString("Missing TXD path for mod ID "..uid, 0, 255,55,55)
            -- elseif type(col)~="string" then
            --     -- A collision file is mandatory for new weapons (you can use an empty one)
            --     outputDebugString("Missing COL path for mod ID "..uid, 0, 255,55,55)
            else

                if type(bone) == "string" then
                    bone = boneIDNames[bone]
                end
                if not bone then
			        outputDebugString("Failed to get Bone ID from name: "..tostring(mod.bone), 0, 255,55,55)
                else
                    if type(ds)~="boolean" then
                        outputDebugString("Missing/invalid Double-Sided value for mod ID "..uid, 0, 255,55,55)
                    else
                        if type(scale) ~= "number" or (scale < 0) then
                            outputDebugString("Missing/invalid Scale value for mod ID "..uid, 0, 255,55,55)
                        else
                            if type(pos) ~= "table" or (#pos < 6) then
                                outputDebugString("Missing/invalid Bone Position table for mod ID "..uid, 0, 255,55,55)
                            else

                                local worked, reason = exports.newmodels:addExternalMod_CustomFilenames("object", uid, baseobjid, name, dff, txd, col)
                                if not worked then
                                    outputDebugString(reason or "Unknown error", 0, 255,110,61)
                                else
                                    -- outputDebugString("Added new weapon object ID "..uid, 3)
                                    mod.baseid = baseweapon
                                    mod.added = true
                                end
                            end
                        end
                    end
                end
            end
		end
	end
end)

function showWeaponsCmd(thePlayer, cmd)
    outputChatBox("Total weapon mods: "..table.size(weapList), thePlayer, 255,126,0)
    for k,mod in pairs(weapList) do

        local uid = mod.uid
        local baseweapon = mod.baseweapon
        local baseobjid = mod.baseobjid
        local name = mod.name

        outputChatBox(" - #"..uid..": "..name.." (base object: #"..baseobjid..", base weapon: "..getWeaponNameFromID(baseweapon)..")", thePlayer, 255,194,14)
    end
end
addCommandHandler("listweapons", showWeaponsCmd, false, false)

function equipCmd(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        outputChatBox("SYNTAX: /"..cmd.." [new unique weapon id]", thePlayer, 255, 255, 255)
        executeCommandHandler("listweapons", thePlayer)
        return
    end

    local foundWeapon
    for k,mod in pairs(weapList) do
        if mod.uid == id then
            foundWeapon = mod
            break
        end
    end

    if not foundWeapon then
        return outputChatBox("No new weapon with ID "..id.." found.", thePlayer, 255, 0, 0)
    end
    if not foundWeapon.added then
        return outputChatBox("New weapon #"..id.." was not added to the server.", thePlayer, 255, 0, 0)
    end

    equipWeapon(thePlayer, foundWeapon)
end
addCommandHandler("equipweapon", equipCmd, false, false)

function unequipCmd(thePlayer, cmd, id)
    id = tonumber(id)
    if not id then
        outputChatBox("SYNTAX: /"..cmd.." [new unique weapon id]", thePlayer, 255, 255, 255)
        executeCommandHandler("listweapons", thePlayer)
        return
    end

    local foundWeapon
    for k,mod in pairs(weapList) do
        if mod.uid == id then
            foundWeapon = mod
            break
        end
    end

    if not foundWeapon then
        return outputChatBox("No new weapon with ID "..id.." found.", thePlayer, 255, 0, 0)
    end
    if not foundWeapon.added then
        return outputChatBox("New weapon #"..id.." was not added to the server.", thePlayer, 255, 0, 0)
    end

    unequipWeapon(thePlayer, foundWeapon.uid)
end
addCommandHandler("unequipweapon", unequipCmd, false, false)

function equipWeapon(player, weap)

    local weapons = getElementData(player, weapDataName) or {}
    if weapons[weap.uid] then
        return outputChatBox("Weapon '"..weap.name.."' is already equipped.", player, 255, 0, 0)
    end
    
    local dataName = exports.newmodels:getDataNameFromType("object")
    local object = createObject(weap.baseobjid, 0, 0, 0)
    setElementData(object, dataName, weap.uid)
    setElementCollisionsEnabled(object, false)
    setElementDoubleSided(object, weap.ds)
    setObjectScale(object, weap.scale)
    setElementInterior(object, getElementInterior(player))
    setElementDimension(object, getElementDimension(player))

    exports.pAttach:attach(object, player, weap.bone, unpack(weap.pos))
    setElementAlpha(object, 0)

    weapons[weap.uid] = {
        object = object,
        weap = weap,
    }
    setElementData(player, weapDataName, weapons)

    outputChatBox("Attached: "..weap.name, player, 0, 255, 0)

    local currWeap = getPedWeapon(player, getPedWeaponSlot(player))
    if currWeap and currWeap == weap.baseid then
        triggerEvent("new-weapons:handlePlayerWeaponSwitch", player, nil, weap.baseid)
    end
end

function unequipWeapon(player, weapUID)

    local weapons = getElementData(player, weapDataName) or {}
    local tab = weapons[weapUID]
    if not tab then
        return outputChatBox("Weapon #'"..weapUID.."' is not equipped.", player, 255, 0, 0)
    end

    local object, weap = tab.object, tab.weap
    if not object or not weap then
        return outputChatBox("Error: Invalid weapon data.", player, 255, 0, 0)
    end

    destroyElement(object)
    weapons[weapUID] = nil

    setElementData(player, weapDataName, weapons)
    outputChatBox("Detached: "..weap.name, player, 255, 255, 0)
end

function handlePlayerWeaponSwitch(prev, new)
    local tab = getElementData(source, weapDataName) or {}
    if tab then
        for weapID, v in pairs(tab) do
            if isElement(v.object) then
                if v.weap.baseid == new then -- show the new weapon
                    setElementAlpha(v.object, 255)
                else
                    setElementAlpha(v.object, 0)
                end
            end
        end
    end
end
addEventHandler("new-weapons:handlePlayerWeaponSwitch", root, handlePlayerWeaponSwitch)
addEventHandler("onPlayerWeaponSwitch", root, handlePlayerWeaponSwitch)

addEventHandler("onResourceStop", resourceRoot, function()
    for k,player in ipairs(getElementsByType("player")) do
        removeElementData(player, "new-weapons:equippedWeapons")
    end
end)