local temp_datas = {
	vehicle = exports.newmodels:getDataNameFromType("vehicle"),
	player = exports.newmodels:getDataNameFromType("player"),
	ped = exports.newmodels:getDataNameFromType("ped"),
	object = exports.newmodels:getDataNameFromType("object"),
}

addEventHandler( "onClientRender", root, 
function ()
	if not getResourceFromName("newmodels") then return end

	local lx, ly, lz = getCameraMatrix()
	for elementType, dataName in pairs(temp_datas) do
		for k,veh in ipairs(getElementsByType(elementType, getRootElement(), true)) do
			local x,y,z = getElementPosition(veh)
			local collision, cx, cy, cz, element = processLineOfSight(lx, ly, lz, x,y,z,
			false, false, false, false, false, true, true, true, veh)
			if not collision then

		    	local dx, dy, distance = getScreenFromWorldPosition(x,y,z)
		    	if dx and dy then
		    		local data = getElementData(veh, dataName)
		    		local id = tonumber(data)
		    		local text = elementType..": "..tostring(data)
		    		if id then
		    			local worked = false

		    			local mod = exports.newmodels:getModDataFromID(id)
		    			if type(mod)=="table" then
		    				if mod.name then
		    					text = text.." - "..mod.name
		    					worked = true
		    				end
		    			end

		    			if not worked then
		    				dxDrawText(tostring(inspect(mod)), 15,25)
		    			end
		    		end
		    		dxDrawText(text, dx,dy)
		    	end
		    end
	    end
	end
end)