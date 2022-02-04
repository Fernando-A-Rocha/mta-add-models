weapDataName = "new-weapons:equippedWeapons" -- update in onResourceStop as well

function getPedWeapons(ped)
	local playerWeapons = {}
	if ped and isElement(ped) and (getElementType(ped) == "ped" or getElementType(ped) == "player") then
		for i=0,12 do
			local wep = getPedWeapon(ped,i)
			if wep and wep ~= 0 then
				playerWeapons[i] = wep
			end
		end
	else
		return false
	end
	return playerWeapons
end

-- by Fernando
weapTextures = {
    -- Weapon ID = {textures list} -- corresponding Object ID (Name)
    [1] = {"gun_brass_knuckle_texture"}, -- 331 Brassknuckle
    [5] = {"alum_bat"}, -- 336 Bat
    [8] = {"gun_katana"}, -- 339 Katana
    [22] = { "colt45icon", "colt_all", "muzzle_texture4" }, -- 346 Colt45
}

function getWeaponTextures(id)
    return weapTextures[id]
end

-- from pAttach
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