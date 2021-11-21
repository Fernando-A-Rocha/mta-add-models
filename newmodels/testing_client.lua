--[[
	Author: Fernando

	testing_client.lua

	Commands:
		/allocatedids
		/selements
]]


---------------------------- TESTING PURPOSES ONLY BELOW ----------------------------
------------------- YOU CAN REMOVE THE FOLLOWING FROM THE RESOURCE ------------------

addEvent(resName..":openTestWindow", true)

addEventHandler( "onClientResourceStart", resourceRoot, 
function (startedResource)

	if SEE_ALLOCATED_TABLE then
		togSeeAllocatedTable("-", true)
	end
end)

local sx,sy = guiGetScreenSize()
local win = nil

function createTestWindow(version, title, data)
	destroyTestWindow()
	showCursor(true)

	local w,h = sx/1.5, sy/1.5
	local x,y = sx/2-w/2, sy/2-h/2
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
			if elementType ~= "player" then
				if not tabs1[elementType] then
					tabs1[elementType] = guiCreateTab(elementType, panel11)
					local ww,hh = guiGetSize(tabs1[elementType], false)
					local grid = guiCreateGridList(0, 5, ww,hh, false, tabs1[elementType])
					setElementData(tabs1[elementType], "modsgrid", grid)

					cols1.id = guiGridListAddColumn(grid, "ID", 0.07)
					cols1.name = guiGridListAddColumn(grid, "Name", 0.2)
					cols1.base_id = guiGridListAddColumn(grid, "Base ID", 0.1)
					cols1.path = guiGridListAddColumn(grid, "Folder Path", 0.4)

					addEventHandler( "onClientGUIDoubleClick", grid, 
					function (button)
						if button == "left" then
							local row,col = guiGridListGetSelectedItem(source)
							if row ~= -1 then
								local id,name,base_id,path = guiGridListGetItemText(source, row, cols1.id), guiGridListGetItemText(source, row, cols1.name), guiGridListGetItemText(source, row, cols1.base_id), guiGridListGetItemText(source, row, cols1.path)
								if id then
									local text = elementType.." ID "..id.." ('"..name.."') with base ID "..base_id.." in folder: "..path
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

					cols2.res = guiGridListAddColumn(grid, "Resource", 0.18)
					cols2.id = guiGridListAddColumn(grid, "ID", 0.07)
					cols2.name = guiGridListAddColumn(grid, "Name", 0.15)
					cols2.base_id = guiGridListAddColumn(grid, "Base ID", 0.07)
					cols2.paths = guiGridListAddColumn(grid, "File Paths", 0.4)

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
							local formattedPaths = tostring(inspect(mod.path)):gsub("[\n\r]", " ")
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
							guiGridListSetItemText(grid, row, cols1.path, mod.path, false, true)
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

			cols0.id = guiGridListAddColumn(grid, "ID", 0.2)
			cols0.aid = guiGridListAddColumn(grid, "Allocated ID", 0.2)
			cols0.pos = guiGridListAddColumn(grid, "Position", 0.5)

			addEventHandler( "onClientGUIDoubleClick", grid, 
			function (button)
				if button == "left" then
					local row,col = guiGridListGetSelectedItem(source)
					if row ~= -1 then
						local id,allocted_id,pos = guiGridListGetItemText(source, row, cols0.id), guiGridListGetItemText(source, row, cols0.aid), guiGridListGetItemText(source, row, cols0.pos)
						if id then
							local text = elementType.." ID "..id..(allocted_id~="-" and " [Allocated ID "..allocted_id.."]" or "").." at: "..pos
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
					local allocted_id = allocated_ids[id]
					if allocated_id then
						guiGridListSetItemText(grid, row, cols0.aid, allocted_id, false, true)
					end
				else
					guiGridListSetItemText(grid, row, cols0.id, getElementModel(element), false, true)
					guiGridListSetItemText(grid, row, cols0.aid, "-", false, true)
				end


				local x,y,z = getElementPosition(element)
				local int,dim = getElementInterior(element), getElementDimension(element)
				local pos = "("..x..", "..y..", "..z.." | int: "..int..", dim: "..dim..")"
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

local drawing = false

function togSeeAllocatedTable(cmd, dontspam)
	if not drawing then
		addEventHandler( "onClientRender", root, drawAllocatedTable)
		drawing = true
	else
		removeEventHandler( "onClientRender", root, drawAllocatedTable)
		drawing = false
	end
	if not (type(dontspam)=="boolean") then
		outputChatBox("Displaying allocated_ids on screen: "..(drawing and "Yes" or "No"))
	end
end
addCommandHandler("allocatedids", togSeeAllocatedTable, false)

local sx,sy = guiGetScreenSize()
local dfontsize = 1
local dfont = "default-bold"

function drawAllocatedTable()
	local text = inspect(allocated_ids)
	local width = dxGetTextWidth(text, dfontsize, dfont)
	local x,y = sx/2 - width/2, 20
	dxDrawText(text, x,y,x,y, "0xffffffff", dfontsize, dfont)
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

	-- outputChatBox("TOTAL: "..total,255,126,0)
	for elementType, elements in pairs(tab) do
			
		-- outputChatBox(elementType..": "..table.size(elements))
		local dataName = dataNames[elementType]

		for k, element in pairs(elements) do
			local id = tonumber(getElementData(element, dataName))
			if id then
				local extra = ""
				local allocted_id = allocated_ids[id]
				if allocated_id then
					extra = " allocated to ID "..alocated_id
				end
				local x,y,z = getElementPosition(element)
				local int,dim = getElementInterior(element), getElementDimension(element)
				-- outputChatBox(" - Model ID "..id..extra.." ("..x..", "..y..", "..z.." | int: "..int..", dim: "..dim..")",255,194,14)
			end
		end
	end

	triggerEvent(resName..":openTestWindow", resourceRoot, "selements", "Total "..total.." streamed mod-compatible elements", tab)
end
addCommandHandler("selements", outputStreamedInElements, false)