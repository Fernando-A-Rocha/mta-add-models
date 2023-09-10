--[[
	Author: https://github.com/Fernando-A-Rocha

	shared.lua

	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
]]

resName = getResourceName(resource)

_outputDebugString = outputDebugString
function outputDebugString(text, mode, r,g,b)
	if not ENABLE_DEBUG_MESSAGES then return end
	if not CHAT_DEBUG_MESSAGES then
		_outputDebugString(text, mode, r,g,b)
	else

		if not mode then mode = 3 end

		if mode == 1 then
			r,g,b = 255,25,25
		elseif mode == 2 then
			r,g,b = 255,194,14
		elseif mode == 3 then
			r,g,b = 25,255,25
		end

		if not r then r = 255 end
		if not g then g = 255 end
		if not b then b = 255 end

		if isElement(localPlayer) then
			outputChatBox(text, r,g,b)
		else
			outputChatBox("((server)) "..text, root, r,g,b)
		end
	end
end

function getBaseModel(element) -- [Exported]
	return (getElementData(element, baseDataName) or getElementModel(element))
end

function getBaseModelDataName()
	return baseDataName
end

function getDataNameFromType(elementType) -- [Exported]
	if not elementType then return end
	return dataNames[elementType]
end

local pedIds = {1,  2,    3,   4,   5,   6,  7,    8,   9,	10,  11,  12,  13,  14,  15,  16,  17,  18,  19,20,  21,  22,  23,  24,  25,  26,  27,  28,  29,30,  31,  32,  33,  34,  35,  36,  37,  38,  39,40,  41,  42,  43,  44,  45,  46,  47,  48,  49,50,  51,  52,  53,  54,  55,  56,  57,  58,  59,60,  61,  62,  63,  64,  65,  66,  67,  68,  69,70,  71,  72,  73,       75,  76,  77,  78,  79,     80,  81,  82,  83,  84,  85,  86,  87,  88,  89,90,  91,  92,  93,  94,  95,  96,  97,  98,  99,100, 101, 102, 103, 104, 105, 106, 107, 108, 109,110, 111, 112, 113, 114, 115, 116, 117, 118, 119,120, 121, 122, 123, 124, 125, 126, 127, 128, 129,130, 131, 132, 133, 134, 135, 136, 137, 138, 139,140, 141, 142, 143, 144, 145, 146, 147, 148,     150, 151, 152, 153, 154, 155, 156, 157, 158, 159,160, 161, 162, 163, 164, 165, 166, 167, 168, 169,170, 171, 172, 173, 174, 175, 176, 177, 178, 179,180, 181, 182, 183, 184, 185, 186, 187, 188, 189,190, 191, 192, 193, 194, 195, 196, 197, 198, 199,200, 201, 202, 203, 204, 205, 206, 207,      209,210, 211, 212, 213, 214, 215, 216, 217, 218, 219,220, 221, 222, 223, 224, 225, 226, 227, 228, 229,230, 231, 232, 233, 234, 235, 236, 237, 238, 239,240, 241, 242, 243, 244, 245, 246, 247, 248, 249,250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269,270, 271, 272, 273, 274, 275, 276, 277, 278, 279,280, 281, 282, 283, 284, 285, 286, 287, 288, 289,290, 291, 292, 293, 294, 295, 296, 297, 298, 299,300, 301, 302, 303, 304, 305, 306, 307, 308, 309,310, 311, 312}
local vehicleIds = {400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433, 434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565, 566, 567, 568, 569, 570, 571, 572, 573, 574, 575, 576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602, 603, 604, 605, 606, 607, 608, 609, 610, 611}
local function isDefaultObjectID(id)
	if id < 321 or id > 18630 then
		return false
	end
	-- exclude unused/reserved for other purposes IDs
	if id >= 374 and id <= 614 then
		return false
	end
	if id >= 11682 and id <= 12799 then
		return false
	end
	if id >= 15065 and id <= 15999 then
		return false
	end
	return true
end

function isDefaultID(elementType, id) -- [Exported]
	id = tonumber(id)
	if not id then return false end

	if not elementType then -- check all IDs
		for k,id2 in pairs(pedIds) do
			if id2 == id then
				return true
			end
		end
		for k,id2 in pairs(vehicleIds) do
			if id2 == id then
				return true
			end
		end
		return isDefaultObjectID(id)
	else
		if elementType == "ped" or elementType == "player" then
			for k,id2 in pairs(pedIds) do
				if id2 == id then
					return true
				end
			end
		elseif elementType == "object" or elementType == "pickup" then
			return isDefaultObjectID(id)
		elseif elementType == "vehicle" then
			for k,id2 in pairs(vehicleIds) do
				if id2 == id then
					return true
				end
			end
		end
	end
	return false
end

function getActualModPaths(folder, id)
	local path = folder

	local lastchar = string.sub(folder, -1)
	if lastchar ~= "/" then
		path = folder.."/" -- / is missing but I'm nice
	end
	path = path..id

	return {
		txd = path..".txd",
		dff = path..".dff",
		col = path..".col",
	}
end

function isCustomModID(id) -- [Exported]

	local mod, elementType = getModDataFromID(id)
	if not mod then
		return false
	end
	return true, mod, elementType
end

-- [Exported]
function isRightModType(et, modEt)

	if et == modEt then
		return true
	end

	if (et == "player" or et == "ped") and (modEt == "player" or modEt == "ped") then
		return true
	end
	if (et == "pickup" or et == "object") and (modEt == "pickup" or modEt == "object") then
		return true
	end
	
	return false
end

function isElementTypeSupported(et)
	local found
	for type,_ in pairs(dataNames) do
		if et == type then
			found = true
			break
		end
	end

	if not found then
		return false, "added "..et.." mods are not yet supported"
	end
	return true
end

function isCustomVehicle( theVehicle )	
	if not isElement(theVehicle) then return false end
		
	local et = getElementType(theVehicle)
	if et ~= "vehicle" then return false end

	local dataName = dataNames[et]
	local id = tonumber(getElementData(theVehicle, dataName))
	if not id then
		-- not a custom vehicle
		return false
	end

	return true
end

--[[
	Useful function: checks if any given ID is valid
	by doing the appropriate checks

	Three possible return values:
		- "INVALID_MODEL": invalid model ID
		- "WRONG_MOD": the mod is not for the element type
		- baseModel, isCustom, dataName, baseDataName: model ID ok for element type
]]
-- [Exported]
function checkModelID(id, elementType)
	assert(tonumber(id), "Non-number ID passed")
	assert((elementType == "ped" or elementType == "player" or elementType == "object" or elementType == "vehicle" or elementType == "pickup"),
		"Invalid element type passed: "..tostring(elementType))
	local dataName = dataNames[elementType]
	assert(dataName, "No data name for element type: "..tostring(elementType))

	if elementType == "pickup" then
		elementType = "object"
	end

	local baseModel
	local isCustom, mod, modType = isCustomModID(id)
	if isCustom then
		if not isRightModType(elementType, modType) then
			return "WRONG_MOD"
		end
		baseModel = mod.base_id
	elseif isDefaultID(elementType, id) then
		baseModel = id
	else
		return "INVALID_MODEL"
	end

	return baseModel, isCustom, dataName, baseDataName
end
