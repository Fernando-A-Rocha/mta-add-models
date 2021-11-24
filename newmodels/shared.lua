--[[
	Author: Fernando

	shared.lua

	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
]]

thisRes = getThisResource()
resName = getResourceName(thisRes)

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

dataNames = {
	ped = "skinID",
	player = "skinID",
	vehicle = "vehicleID",

	-- there is currently a bug with engineFreeModel when object streamed out
	-- it is fixed in client.lua with 'prevent_object_bug'
	object = "objectID",
}

function getDataTypeFromName(dataName)
	for elementType, name in pairs(dataNames) do
		if dataName == name then
			return elementType
		end
	end
end

function getDataNameFromType(elementType) -- [Exported]
	if not elementType then return end
	return dataNames[elementType]
end

pedIds = {1, 2, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 66, 67, 68, 69, 70, 71, 72, 73, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312}
vehicleIds = {400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433, 434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565, 566, 567, 568, 569, 570, 571, 572, 573, 574, 575, 576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602, 603, 604, 605, 606, 607, 608, 609, 610, 611}

objectIds = {}--autofill
for id=321,18630 do
	-- skip some ids
	if (id <= 373 or id >= 615)  and  (id < 11682 or id > 12799) then
		table.insert(objectIds, id)
	end
end

function isDefaultID(elementType, id) -- [Exported]
	id = tonumber(id)
	if not id then return end

	if not elementType then -- check all IDs
		return isDefaultID("ped", id) or isDefaultID("object", id) or isDefaultID("vehicle", id)
	else
		if elementType == "ped" or elementType == "player" then
			for k,id2 in pairs(pedIds) do
				if id2 == id then
					return true
				end
			end
		elseif elementType == "object" then
			for k,id2 in pairs(objectIds) do
				if id2 == id then
					return true
				end
			end
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

function verifySetModelArguments(element, elementType, id)
	if not isElement(element) then
		return false, "Invalid element passed"
	end

	local et = getElementType(element)

	local sup,reason = isElementTypeSupported(et)
	if not sup then
		return false, reason
	end

	local dataName = dataNames[et]
	if not dataName then
		return false, et.." mods yet supported"
	end

	if not tonumber(id) then
		return false, "Non-number ID passed"
	end
	id = tonumber(id)

	return true
end

function table.size ( tab )
    local length = 0
    
    for _ in pairs ( tab ) do
        length = length + 1
    end
    
    return length
end