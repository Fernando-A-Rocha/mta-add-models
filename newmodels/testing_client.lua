--[[
	Author: https://github.com/Fernando-A-Rocha

	testing_client.lua

	Commands:
		/allocatedids
		/selements
		/checkskin
]]


---------------------------- TESTING PURPOSES ONLY BELOW ----------------------------
------------------- YOU CAN REMOVE THE FOLLOWING FROM THE RESOURCE ------------------

local SW, SH = guiGetScreenSize()
local win = nil

local drawing = false
local D_FONTSIZE = 1
local D_FONT = "default-bold"

addEvent(resName..":openTestWindow", true)

addEventHandler( "onClientResourceStart", resourceRoot, 
function (startedResource)

	if SEE_ALLOCATED_TABLE then
		togSeeAllocatedTable("-", true)
	end
end)

function createTestWindow(version, title, data)
	destroyTestWindow()
	showCursor(true)

	local w,h = SW/1.5, SH/1.5
	local x,y = SW/2-w/2, SH/2-h/2
	win = guiCreateWindow(x,y, w,h, (title or "?").."  -  Double click a line to copy", false)

	if version == "listmods" then

		local panel0 = guiCreateTabPanel(0, 25, w-15, h-25*2 - 30, false, win)

		local tab1 = guiCreateTab("Predefined Mods", panel0)
		local panel11 = guiCreateTabPanel(5, 5, w-28, h-120, false, tab1)

		local tab2 = guiCreateTab("External Mods", panel0)
		local panel22 = guiCreateTabPanel(5, 5, w-28, h-120, false, tab2)

		local tabs1 = {}
		local tabs2 = {}

		local cols1 = {}
		local cols2 = {}

		for elementType,_ in pairs(dataNames) do
			if not (elementType=="player" or elementType=="pickup") then
				if not tabs1[elementType] then
					tabs1[elementType] = guiCreateTab(elementType, panel11)
					local ww,hh = guiGetSize(tabs1[elementType], false)
					local grid = guiCreateGridList(0, 5, ww,hh, false, tabs1[elementType])
					setElementData(tabs1[elementType], "modsgrid", grid)

					cols1.id = guiGridListAddColumn(grid, "ID", 0.2)
					cols1.name = guiGridListAddColumn(grid, "Name", 0.2)
					cols1.base_id = guiGridListAddColumn(grid, "Base ID", 0.1)
					cols1.paths = guiGridListAddColumn(grid, "File Paths", 0.8)

					addEventHandler( "onClientGUIDoubleClick", grid, 
					function (button)
						if button == "left" then
							local row,col = guiGridListGetSelectedItem(source)
							if row ~= -1 then
								local id,name,base_id,paths = guiGridListGetItemText(source, row, cols1.id), guiGridListGetItemText(source, row, cols1.name), guiGridListGetItemText(source, row, cols1.base_id), guiGridListGetItemText(source, row, cols1.paths)
								if id then
									local text = elementType.." ID "..id.." ('"..name.."') with base ID "..base_id..": "..paths
									if setClipboard(text) then
										outputChatBox("Copied to clipboard: "..text,0,255,0)
									end
								end
							end
						end
					end, false)
				end
				if not tabs2[elementType] then
					tabs2[elementType] = guiCreateTab(elementType, panel22)
					local ww,hh = guiGetSize(tabs2[elementType], false)
					local grid = guiCreateGridList(0, 5, ww,hh, false, tabs2[elementType])
					setElementData(tabs2[elementType], "modsgrid", grid)

					cols2.res = guiGridListAddColumn(grid, "Resource", 0.2)
					cols2.id = guiGridListAddColumn(grid, "ID", 0.1)
					cols2.name = guiGridListAddColumn(grid, "Name", 0.15)
					cols2.base_id = guiGridListAddColumn(grid, "Base ID", 0.1)
					cols2.paths = guiGridListAddColumn(grid, "File Paths", 0.9)

					addEventHandler( "onClientGUIDoubleClick", grid, 
					function (button)
						if button == "left" then
							local row,col = guiGridListGetSelectedItem(source)
							if row ~= -1 then
								local res,id,name,base_id,paths = guiGridListGetItemText(source, row, cols2.res), guiGridListGetItemText(source, row, cols2.id), guiGridListGetItemText(source, row, cols2.name), guiGridListGetItemText(source, row, cols2.base_id), guiGridListGetItemText(source, row, cols2.paths)
								if id then
									local text = "["..res.."] "..elementType.." ID "..id.." ('"..name.."') with base ID "..base_id..": "..paths
									if setClipboard(text) then
										outputChatBox("Copied to clipboard: "..text,0,255,0)
									end
								end
							end
						end
					end, false)
				end
			end
		end

		for elementType, mods in pairs(data) do
			for k, mod in pairs(mods) do
				local srcRes = mod.srcRes
				if srcRes then
					local tab = tabs2[elementType]
					if tab then
						local grid = getElementData(tab, "modsgrid")
						if grid then
							local row = guiGridListAddRow(grid)
							guiGridListSetItemText(grid, row, cols2.res, tostring(srcRes), false, false)
							guiGridListSetItemText(grid, row, cols2.id, mod.id, false, true)
							guiGridListSetItemText(grid, row, cols2.name, mod.name, false, false)
							guiGridListSetItemText(grid, row, cols2.base_id, mod.base_id, false, true)
							local formattedPaths = tostring(inspect(mod.paths)):gsub("[\n\r]", " ")
							guiGridListSetItemText(grid, row, cols2.paths, formattedPaths, false, true)
						end
					end
				else
					local tab = tabs1[elementType]
					if tab then
						local grid = getElementData(tab, "modsgrid")
						if grid then
							local row = guiGridListAddRow(grid)
							guiGridListSetItemText(grid, row, cols1.id, mod.id, false, true)
							guiGridListSetItemText(grid, row, cols1.name, mod.name, false, false)
							guiGridListSetItemText(grid, row, cols1.base_id, mod.base_id, false, true)
							local formattedPaths = tostring(inspect(mod.paths)):gsub("[\n\r]", " ")
							guiGridListSetItemText(grid, row, cols1.paths, formattedPaths, false, true)
						end
					end
				end
			end
		end

	elseif version == "selements" then
		local panel0 = guiCreateTabPanel(0, 25, w-15, h-25*2 - 30, false, win)

		local cols0 = {}

		for elementType, elements in pairs(data) do

			local tab = guiCreateTab(elementType, panel0)
			local ww,hh = guiGetSize(tab, false)
			local grid = guiCreateGridList(0, 5, ww,hh, false, tab)

			cols0.id = guiGridListAddColumn(grid, "Custom ID", 0.2)
			cols0.modelid = guiGridListAddColumn(grid, "Model", 0.2)
			cols0.pos = guiGridListAddColumn(grid, "Position", 0.55)

			addEventHandler( "onClientGUIDoubleClick", grid, 
			function (button)
				if button == "left" then
					local row,col = guiGridListGetSelectedItem(source)
					if row ~= -1 then
						local id,allocated_id,pos = guiGridListGetItemText(source, row, cols0.id), guiGridListGetItemText(source, row, cols0.aid), guiGridListGetItemText(source, row, cols0.pos)
						if id then
							local text = elementType.." ID "..id..(allocated_id~="-" and " [Allocated ID "..allocated_id.."]" or "").." at: "..pos
							if setClipboard(text) then
								outputChatBox("Copied to clipboard: "..text,0,255,0)
							end
						end
					end
				end
			end, false)

			local dataName = dataNames[elementType]

			for k, element in pairs(elements) do

				local row = guiGridListAddRow(grid)

				local id = tonumber(getElementData(element, dataName))
				if id then
					guiGridListSetItemText(grid, row, cols0.id, id, false, true)
					guiGridListSetItemColor(grid, row, cols0.id, 0,255,0)
					local allocated_id = allocated_ids[id]
					if allocated_id then
						guiGridListSetItemText(grid, row, cols0.modelid, allocated_id, false, true)
					else
						guiGridListSetItemText(grid, row, cols0.modelid, "Not allocated", false, false)
					end
				else
					guiGridListSetItemText(grid, row, cols0.id, "-", false, true)
					guiGridListSetItemText(grid, row, cols0.modelid, getElementModel(element), false, true)
				end


				local ex,ey,ez = getElementPosition(element)
				local int,dim = getElementInterior(element), getElementDimension(element)
				local pos = "("..ex..", "..ey..", "..ez.." | int: "..int..", dim: "..dim..")"
				guiGridListSetItemText(grid, row, cols0.pos, pos, false, false)
			end
		end
	end

	local close = guiCreateButton(0, h-40, w, 32, "Close", false, win)
	addEventHandler( "onClientGUIClick", close, destroyTestWindow, false)
end
addEventHandler(resName..":openTestWindow", resourceRoot, createTestWindow)

function destroyTestWindow()
	if isElement(win) then destroyElement(win) end
	win = nil
	showCursor(false)
end
local function pairsByKeys(t)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, f)
    local i = 0
    local iter = function()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function togSeeAllocatedTable(cmd, dontspam)
	if not drawing then
		addEventHandler( "onClientRender", root, drawAllocatedTable)
		drawing = true
	else
		removeEventHandler( "onClientRender", root, drawAllocatedTable)
		drawing = false
	end
	if type(dontspam) ~= "boolean" then
		outputChatBox("Displaying allocated_ids on screen: "..(drawing and "Yes" or "No"))
	end
end
addCommandHandler("allocatedids", togSeeAllocatedTable, false)

function drawAllocatedTable()
	local text = "["..(string.upper(resName)).." DEBUG]\n"
	local count = table.size(allocated_ids)
	if count > 0 then
		text=text.."Allocated new models (total "..count.."):\n"
		for aid, id in pairsByKeys(allocated_ids) do
			text = text..id.." : "..aid.."\n"
		end
	else
		text=text.."There are 0 new models currently allocated."
	end
	dxDrawText(text, 0,10, SW,SH, 0xffffffff, D_FONTSIZE, D_FONT, "center", "top")
end


function outputStreamedInElements(cmd)
	local tab = {}
	local total = 0

	for elementType, name in pairs(dataNames) do
		local elements = getElementsByType(elementType, getRootElement(), true)
		local count = table.size(elements)
		if count > 0 then
			tab[elementType] = elements
			total = total + count
		end
	end

	triggerEvent(resName..":openTestWindow", resourceRoot, "selements", "Total "..total.." streamed mod-compatible elements", tab)
end
addCommandHandler("selements", outputStreamedInElements, false)

function table.size ( tab )
    local length = 0
    for _ in pairs ( tab ) do
        length = length + 1
    end
    return length
end

addCommandHandler("checkskin", function(cmd, name)
	if not name then
		return outputChatBox("SYNTAX: /"..cmd.." [partial or full player name]", 255,194,14)
	end
	local foundPlayer = nil
	for k, player in ipairs(getElementsByType("player")) do
		if string.find(string.lower(getPlayerName(player)), string.lower(name)) then
			foundPlayer = player
			break
		end
	end
	if not foundPlayer then
		return outputChatBox("No player found with that name", 255,0,0)
	end
	outputChatBox("Clientside skin model of #ffff00'"..getPlayerName(foundPlayer).."'#ffffff is#ffff00 "..getElementModel(foundPlayer), 255, 255, 255, true)
end, false, false)
