--[[
	Author: https://github.com/Fernando-A-Rocha

	_config.lua

	All global config variables are in this file:
]]

----------- GENERAL SCRIPT CONFIGURATION -----------

COMMAND_NAME = "newmodelseditor"

-- You can customize this for your mapping server
function canUseTool(player)
    return hasObjectPermissionTo(player, "command.start", false) and hasObjectPermissionTo(player, "command.stop", false)
end

-- In case you decide to customize objects.xml etc in editor_gui
-- you may change this:
EDITOR_GUI_XML_GROUP_NAMES = {
    ["objects"] = "New Models",
    ["vehicles"] = "New Models",
    ["skins"] = "New Models",
}