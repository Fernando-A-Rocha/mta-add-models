--[[
	Author: https://github.com/Fernando-A-Rocha

	New-Models Vehicle Manager

    Commands:
        - /gethandling
]]

-- If you renamed newmodels, make sure to update "include resource" in meta.xml as well as this variable:
newmodelsResourceName = "newmodels"

newVehModelDataName = exports[newmodelsResourceName]:getDataNameFromType("vehicle")

DEBUG = true

function sendDebugMsg(txt, theType)
    if DEBUG then
        txt = "[New-Models Vehicle Manager] "..txt
        if not theType then theType = "INFO" end
        theType = string.lower(theType)
        if theType == "ERROR" then
            outputDebugString(txt, 4, 255, 25, 25)
        elseif theType == "SUCCESS" then
            outputDebugString(txt, 4, 25, 255, 25)
        elseif theType == "WARN" or theType == "WARNING" then
            outputDebugString(txt, 4, 255, 255, 50)
        else
            outputDebugString(txt, 4, 200, 200, 200)
        end
    end
end
