--[[             _    _                _
           /\   | |  | |              | |
  _ __    /  \  | |_ | |_  __ _   ___ | |__
 | '_ \  / /\ \ | __|| __|/ _` | / __|| '_ \
 | |_) |/ ____ \| |_ | |_| (_| || (__ | | | |
 | .__//_/    \_\\__| \__|\__,_| \___||_| |_|
 | |
 |_|

 -- https://github.com/Patrick2562/mtasa-pAttach
 -- https://mtasa.com/discord
]]

local sin, cos, rad = math.sin, math.cos, math.rad
local setMatrix     = setElementMatrix
local setPosition   = setElementPosition
local setDimension  = setElementDimension
local getDimension  = getElementDimension
local setInterior   = setElementInterior
local getInterior   = getElementInterior
local setAlpha      = setElementAlpha
local getBoneMatrix = getElementBoneMatrix
local setCollisions = setElementCollisionsEnabled
local isOnScreen    = isElementOnScreen
local isElement     = isElement
local isStreamedIn  = isElementStreamedIn
local getType       = getElementType

pAttach = {
    instances                 = {},
    pedInstances              = {},
    inStreamPeds              = {},
    preparedToRenderInstances = {},
    pedsProcessedAdded        = false,

    attach = function(self, element, ped, _boneid, ox, oy, oz, rx, ry, rz)
        local boneid = boneIDNames[_boneid] or tonumber(_boneid) or false
        assert(isElement(element) and getType(element) ~= "player", "Expected element (except: player) at argument 1, got "..type(element))
        assert(isElement(ped), "Expected element at argument 2, got "..type(ped))
        assert(boneid and boneIDs[boneid], "Expected valid bone-id or bone-name at argument 3, got "..tostring(_boneid)..". Check available bones in README.md")
        if self:isAttached(element) then return false end

        setPosition(element, 0, 0, 10000)
        setDimension(element, getDimension(ped))
        setInterior(element, getInterior(ped))
        setCollisions(element, false)

        local pedIns  = self.pedInstances[ped]
        local pedType = getType(ped)

        if not pedIns then
            pedIns = { count = 1, pedType = pedType, list = {} }
            self.pedInstances[ped] = pedIns

            if ped ~= localPlayer then
                addEventHandler("onClientElementStreamIn",    ped, self.onStreamIn)
                addEventHandler("onClientElementStreamOut",   ped, self.onStreamOut)
                if pedType == "ped" then
                    addEventHandler("onClientElementDestroy", ped, self.onPedDestroy)
                end
            end
            addEventHandler("onClientElementDimensionChange", ped, self.onDimensionChange)
            addEventHandler("onClientElementInteriorChange",  ped, self.onInteriorChange)
        else
            pedIns.count = pedIns.count + 1
        end

        pedIns.list[element] = {
            element = element,
            ped     = ped,
            boneid  = boneid,
            _boneid = _boneid,
            ox      = ox or 0,
            oy      = oy or 0,
            oz      = oz or 0,
            rx      = rx or 0,
            ry      = ry or 0,
            rz      = rz or 0,
            rotMat  = self:calculateRotMat(rx or 0, ry or 0, rz or 0)
        }
        self.instances[element] = ped

        if ped == localPlayer or isStreamedIn(ped) then
            if self.inStreamPeds[ped] then
                self:refreshRender()
            else
                self:addToStream(ped)
            end
        end

        addEventHandler("onClientElementDestroy", element, self.onElementDestroy)
        return true
    end,

    detach = function(self, element)
        if not self:isAttached(element) then return false end

        local ped    = self.instances[element]
        local pedIns = self.pedInstances[ped]

        pedIns.count = pedIns.count - 1

        if pedIns.count == 0 then
            if isElement(ped) then
                removeEventHandler("onClientElementStreamIn",        ped, self.onStreamIn)
                removeEventHandler("onClientElementStreamOut",       ped, self.onStreamOut)
                removeEventHandler("onClientElementDimensionChange", ped, self.onDimensionChange)
                removeEventHandler("onClientElementInteriorChange",  ped, self.onInteriorChange)
                if pedIns.pedType == "ped" then
                    removeEventHandler("onClientElementDestroy",     ped, self.onPedDestroy)
                end
            end
            self.pedInstances[ped] = nil
            self:removeFromStream(ped)

        else
            pedIns.list[element] = nil
            self:refreshRender()
        end

        removeEventHandler("onClientElementDestroy", element, self.onElementDestroy)
        self.instances[element] = nil
        return true
    end,

    detachAll = function(self, ped)
        assert(isElement(ped), "Expected element at argument 1, got "..type(ped))

        if self.pedInstances[ped] then
            for element in pairs(self.pedInstances[ped].list) do
                self:detach(element)
            end
        end
        return true
    end,

    isAttached = function(self, element)
        return (element and self.instances[element]) and true or false
    end,

    getDetails = function(self, element)
        assert(isElement(element), "Expected element at argument 1, got "..type(element))
        if not self:isAttached(element) then return false end
        
        local v = self.pedInstances[self.instances[element]].list[element]
        return v and { v.element, v.ped, v._boneid, v.ox, v.oy, v.oz, v.rx, v.ry, v.rz } or false
    end,

    getAttacheds = function(self, ped)
        assert(isElement(ped), "Expected element at argument 1, got "..type(ped))
        
        local list = {}
        if self.pedInstances[ped] then
            for element in pairs(self.pedInstances[ped].list) do
                list[ #list + 1 ] = element
            end
        end
        return list
    end,

    setPositionOffset = function(self, element, x, y, z)
        assert(isElement(element), "Expected element at argument 1, got "..type(element))
        if not self:isAttached(element) then return false end

        local ped = self.instances[element]
        local ins = self.pedInstances[ped].list[element]

        ins.ox = x or 0
        ins.oy = y or 0
        ins.oz = z or 0
        return true
    end,

    setRotationOffset = function(self, element, x, y, z)
        assert(isElement(element), "Expected element at argument 1, got "..type(element))
        if not self:isAttached(element) then return false end

        local ped = self.instances[element]
        local ins = self.pedInstances[ped].list[element]

        ins.rx = x or 0
        ins.ry = y or 0
        ins.rz = z or 0
        ins.rotMat = self:calculateRotMat(x or 0, y or 0, z or 0)
        return true
    end,

    invisibleAll = function(self, ped, bool)
        assert(isElement(ped), "Expected element at argument 1, got "..type(ped))

        if self.pedInstances[ped] then
            for element in pairs(self.pedInstances[ped].list) do
                setAlpha(element, bool and 0 or 255)
            end
        end
        return true
    end,

    addToStream = function(self, ped)
        if not self.inStreamPeds[ped] then
            self.inStreamPeds[ped] = true
            if self.pedInstances[ped] then
                self:refreshRender()
            end
            return true
        end
        return false
    end,

    removeFromStream = function(self, ped)
        if self.inStreamPeds[ped] then
            if self.pedInstances[ped] then
                for element in pairs(self.pedInstances[ped].list) do
                    setPosition(element, 0, 0, 10000)
                end
            end
            self.inStreamPeds[ped] = nil
            self:refreshRender()
            return true
        end
        return false
    end,


    onStreamIn = function()
        pAttach:addToStream(source)
    end,

    onStreamOut = function()
        pAttach:removeFromStream(source)
    end,

    onDimensionChange = function(old, new)
        if pAttach.pedInstances[source] then
            for element in pairs(pAttach.pedInstances[source].list) do
                setDimension(element, new)
            end
        end
    end,

    onInteriorChange = function(old, new)
        if pAttach.pedInstances[source] then
            for element in pairs(pAttach.pedInstances[source].list) do
                setInterior(element, new)
            end
        end
    end,

    onElementDestroy = function()
        pAttach:detach(source)
    end,

    onPedDestroy = function()
        pAttach:detachAll(source)
    end,


    refreshRender = function(self)
        local tbl = {}
        local len = 0
        for ped in pairs(self.inStreamPeds) do
            for element, data in pairs(self.pedInstances[ped].list) do
                len = len + 1
                tbl[len] = data
            end
        end
        self.preparedToRenderInstances = tbl

        if len > 0 and not self.pedsProcessedAdded then
            addEventHandler("onClientPedsProcessed", root, self.onPedsProcessed)
            self.pedsProcessedAdded = true
        elseif len == 0 and self.pedsProcessedAdded then
            removeEventHandler("onClientPedsProcessed", root, self.onPedsProcessed)
            self.pedsProcessedAdded = false
        end
        return true
    end,

    calculateRotMat = function(self, rx, ry, rz)
        local rx, ry, rz     = rad(rx), rad(ry), rad(rz)
        local syaw,   cyaw   = sin(rx), cos(rx)
        local spitch, cpitch = sin(ry), cos(ry)
        local sroll,  croll  = sin(rz), cos(rz)
        return {
            { sroll  * spitch * syaw + croll * cyaw, sroll * cpitch, sroll * spitch * cyaw - croll * syaw },
            { croll  * spitch * syaw - sroll * cyaw, croll * cpitch, croll * spitch * cyaw + sroll * syaw },
            { cpitch * syaw, -spitch, cpitch * cyaw }
        }
    end,

    -- Modified https://wiki.multitheftauto.com/wiki/AttachElementToBone
    onPedsProcessed = function()
        local boneMatCache = {}

        for i = 1, #pAttach.preparedToRenderInstances do
            local data         = pAttach.preparedToRenderInstances[i]
            local element, ped = data.element, data.ped
            local boneid       = data.boneid
            local ox, oy, oz   = data.ox, data.oy, data.oz

            if isOnScreen(ped) then
                local bMCache = boneMatCache[ped]
                local boneMat = false

                if not bMCache then
                    bMCache = {}
                    boneMatCache[ped] = bMCache
                end
                if not bMCache[boneid] then
                    boneMat = getBoneMatrix(ped, boneid)
                    bMCache[boneid] = boneMat
                else
                    boneMat = bMCache[boneid]
                end

                if boneMat then
                    local bM1X, bM1Y, bM1Z = boneMat[1][1], boneMat[1][2], boneMat[1][3]
                    local bM2X, bM2Y, bM2Z = boneMat[2][1], boneMat[2][2], boneMat[2][3]
                    local bM3X, bM3Y, bM3Z = boneMat[3][1], boneMat[3][2], boneMat[3][3]
                    local bM4X, bM4Y, bM4Z = boneMat[4][1], boneMat[4][2], boneMat[4][3]

                    local rotMat = data.rotMat
                    local rM1X, rM1Y, rM1Z = rotMat[1][1], rotMat[1][2], rotMat[1][3]
                    local rM2X, rM2Y, rM2Z = rotMat[2][1], rotMat[2][2], rotMat[2][3]
                    local rM3X, rM3Y, rM3Z = rotMat[3][1], rotMat[3][2], rotMat[3][3]

                    setMatrix(element, {
                        {
                            bM2X * rM1Y + bM1X * rM1X + rM1Z * bM3X,
                            bM3Y * rM1Z + bM1Y * rM1X + bM2Y * rM1Y,
                            bM2Z * rM1Y + bM3Z * rM1Z + rM1X * bM1Z,
                            0
                        },
                        {
                            rM2Z * bM3X + bM2X * rM2Y + rM2X * bM1X,
                            bM3Y * rM2Z + bM2Y * rM2Y + bM1Y * rM2X,
                            rM2X * bM1Z + bM3Z * rM2Z + bM2Z * rM2Y,
                            0
                        },
                        {
                            bM2X * rM3Y + rM3Z * bM3X + rM3X * bM1X,
                            bM3Y * rM3Z + bM2Y * rM3Y + rM3X * bM1Y,
                            rM3X * bM1Z + bM3Z * rM3Z + bM2Z * rM3Y,
                            0
                        },
                        {
                            oz * bM1X + oy * bM2X - ox * bM3X + bM4X,
                            oz * bM1Y + oy * bM2Y - ox * bM3Y + bM4Y,
                            oz * bM1Z + oy * bM2Z - ox * bM3Z + bM4Z,
                            1
                        }
                    })
                    data.prevOutOfScreen = false
                end

            else
                if not data.prevOutOfScreen then
                    setPosition(element, 0, 0, 10000)
                    data.prevOutOfScreen = true
                end
            end
        end
    end
}

boneIDs = {
    [1]  = true,
    [2]  = true,
    [3]  = true,
    [4]  = true,
    [5]  = true,
    [6]  = true,
    [7]  = true,
    [8]  = true,
    [21] = true,
    [22] = true,
    [23] = true,
    [24] = true,
    [25] = true,
    [26] = true,
    [31] = true,
    [32] = true,
    [33] = true,
    [34] = true,
    [35] = true,
    [36] = true,
    [41] = true,
    [42] = true,
    [43] = true,
    [44] = true,
    [51] = true,
    [52] = true,
    [53] = true,
    [54] = true,
}

boneIDNames = {
    ["pelvis"]            = 1,
    ["pelvis2"]           = 2,
    ["spine"]             = 3,
    ["neck"]              = 4,
    ["neck2"]             = 5,
    ["head2"]             = 6,
    ["head3"]             = 7,
    ["head"]              = 8,
    ["right-upper-torso"] = 21,
    ["right-shoulder"]    = 22,
    ["right-elbow"]       = 23,
    ["right-wrist"]       = 24,
    ["right-hand"]        = 25,
    ["right-thumb"]       = 26,
    ["left-upper-torso"]  = 31,
    ["left-shoulder"]     = 32,
    ["left-elbow"]        = 33,
    ["left-wrist"]        = 34,
    ["left-hand"]         = 35,
    ["left-thumb"]        = 36,
    ["left-hip"]          = 41,
    ["left-knee"]         = 42,
    ["left-tankle"]       = 43,
    ["left-foot"]         = 44,
    ["right-hip"]         = 51,
    ["right-knee"]        = 52,
    ["right-tankle"]      = 53,
    ["right-foot"]        = 54,
    -- extra
    ["backpack"]          = 3,
    ["weapon"]            = 24,
}

addEventHandler("onClientResourceStart", resourceRoot, function()
    triggerServerEvent("pAttach:requestCache", resourceRoot)
end)

addEvent("pAttach:receiveCache", true)
addEventHandler("pAttach:receiveCache", resourceRoot, function(cache)
    for _, data in pairs(cache) do
        pAttach:attach(unpack(data))
    end
end)
