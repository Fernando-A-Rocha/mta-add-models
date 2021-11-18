onClientElementsStream = {}

function isEventHandlerAdded( sEventName, pElementAttachedTo, func )
    if type( sEventName ) == 'string' and isElement( pElementAttachedTo ) and type( func ) == 'function' then
        local aAttachedFunctions = getEventHandlers( sEventName, pElementAttachedTo )
        if type( aAttachedFunctions ) == 'table' and #aAttachedFunctions > 0 then
            for i, v in ipairs( aAttachedFunctions ) do
                if v == func then
                    return true
                end
            end
        end
    end
    return false
end

function onClientElementStreamInLibrary()
	setElementStreamLibrary(source, true)
end

function onClientElementStreamOutLibrary()
	setElementStreamLibrary(source, false)
end

function isElementStreamedInLibrary(el)
	return onClientElementsStream[el] == true and true or false
end

function setElementStreamLibrary(el, switch)
	if isElement(el) then
		print(inspect(el), switch)
		if switch == true and onClientElementsStream[el] == nil then
			onClientElementsStream[el] = true
			if not isEventHandlerAdded("onClientElementStreamOut", el, onClientElementStreamOutLibrary) then
				addEventHandler( "onClientElementStreamOut", el, onClientElementStreamOutLibrary)
			end
			if isEventHandlerAdded("onClientElementStreamIn", el, onClientElementStreamInLibrary) then 
				removeEventHandler("onClientElementStreamIn", el, onClientElementStreamInLibrary)
			end
		elseif switch == false and onClientElementsStream[el] == true then
			onClientElementsStream[el] = nil
			if not isEventHandlerAdded("onClientElementStreamIn", el, onClientElementStreamInLibrary) then
				addEventHandler( "onClientElementStreamIn", el, onClientElementStreamInLibrary)
			end
			if isEventHandlerAdded("onClientElementStreamOut", el, onClientElementStreamOutLibrary) then 
				removeEventHandler( "onClientElementStreamOut", el, onClientElementStreamOutLibrary)
			end
		end
	end
end