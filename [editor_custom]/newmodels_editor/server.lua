--[[
	Author: Fernando

	server.lua
	
	/!\ UNLESS YOU KNOW WHAT YOU ARE DOING, NO NEED TO CHANGE THIS FILE /!\
]]


-- Util
function getModelGroupNames(rootChildrenNodes, theType)
    local groupNames = {} -- [model] = name
    local function getGroupNames(node)
        if xmlNodeGetName(node) == "group" then
            local children = xmlNodeGetChildren(node)
            if children then
                local parentName = xmlNodeGetAttribute(node, "name")
                if parentName then
                    for i, child in ipairs(children) do
                        local model = tonumber(xmlNodeGetAttribute(child, "model"))
                        if model then
                            if groupNames[model] then
                                -- outputDebugString("Model "..model.." is already in group "..groupNames[model]..", skipping.", 2)
                                return
                            end
                            groupNames[model] = parentName
                        end
                        if xmlNodeGetName(child) == "group" then
                            getGroupNames(child)
                        end
                    end
                end
            end
        end
    end
    for i, node in ipairs(rootChildrenNodes) do
        getGroupNames(node)
    end
    return groupNames
end

--[[
    Updates the map editor object, vehicle & skins XML list with thew new models.
    This cannot be done live when editor_gui is running because the XML files are
    loaded as config files in meta.xml and it would be a mess to reload them.
]]
function updateEditorGUIFiles()
    local OBJECTS_PATH = ":editor_gui/client/browser/objects.xml"
    local VEHICLES_PATH = ":editor_gui/client/browser/vehicles.xml"
    local SKINS_PATH = ":editor_gui/client/browser/skins.xml"

    local groupNames = {}
    if not EDITOR_GUI_XML_GROUP_NAMES then
        return false, "The editor GUI group names are not defined."
    end
    if not EDITOR_GUI_XML_GROUP_NAMES["objects"] then
        return false, "The editor GUI object group name is not defined."
    end
    if not EDITOR_GUI_XML_GROUP_NAMES["vehicles"] then
        return false, "The editor GUI vehicles group name is not defined."
    end
    if not EDITOR_GUI_XML_GROUP_NAMES["skins"] then
        return false, "The editor GUI skins group name is not defined."
    end
    groupNames["objects"] = EDITOR_GUI_XML_GROUP_NAMES["objects"]
    groupNames["vehicles"] = EDITOR_GUI_XML_GROUP_NAMES["vehicles"]
    groupNames["skins"] = EDITOR_GUI_XML_GROUP_NAMES["skins"]

    if not (fileExists(OBJECTS_PATH) and fileExists(VEHICLES_PATH) and fileExists(SKINS_PATH)) then
        return false, "The editor GUI files could not be found."
    end

    local newmodelsResource = getResourceFromName("newmodels")
    if not newmodelsResource then
        return false, "The resource 'newmodels' could not be found."
    end

    if getResourceState(newmodelsResource) ~= "running" then
        return false, "The resource 'newmodels' is not running."
    end

    local mods = exports.newmodels:getModList()
    if not mods then
        return false, "Failed to get the newmodels mod list."
    end

    local modsList = {
        ["objects"] = {},
        ["vehicles"] = {},
        ["skins"] = {}
    }

    for elementType, mods in pairs(mods) do
        if type(elementType) ~= "string" or type(mods) ~= "table" then
            return false, "The newmodels mod list is not valid."
        end
        for i, mod in ipairs(mods) do
            if type(mod) ~= "table" then
                return false, "Mod #"..i.." is not a table."
            end
            local modID = mod.id
            local modBaseID = mod.base_id
            local modName = mod.name

            if type(modID) ~= "number" or type(modBaseID) ~= "number" or type(modName) ~= "string" then
                return false, "Mod #"..i.." is not valid."
            end

            if elementType == "object" then
                table.insert(modsList["objects"], {id = modID, base_id = modBaseID, name = modName})
            elseif elementType == "vehicle" then
                table.insert(modsList["vehicles"], {id = modID, base_id = modBaseID, name = modName})
            elseif elementType == "ped" then
                table.insert(modsList["skins"], {id = modID, base_id = modBaseID, name = modName})
            end
        end
    end

    local function addNewModels(theType)
        
        local path = OBJECTS_PATH
        if theType == "vehicles" then
            path = VEHICLES_PATH
        elseif theType == "skins" then
            path = SKINS_PATH
        end

        local xmlRoot = xmlLoadFile(path)
        if not xmlRoot then
            return false, "Failed to load file: "..path
        end
        local groupNodes = xmlNodeGetChildren(xmlRoot)
        if not groupNodes then
            return false, "Failed to get the group nodes from file: "..path
        end
        for i, groupNode in ipairs(groupNodes) do
            local groupName = xmlNodeGetAttribute(groupNode, "name")
            if groupName and groupName == groupNames[theType] then
                xmlDestroyNode(groupNode)
                break
            end
        end
        groupNodes = xmlNodeGetChildren(xmlRoot)
        if not groupNodes then
            return false, "Failed to get the group nodes from file: "..path
        end
        local defaultGroupNames = getModelGroupNames(groupNodes, xmlNodeGetAttribute(xmlRoot, "type"))

        local parentGroupNode = xmlCreateChild(xmlRoot, "group")
        xmlNodeSetAttribute(parentGroupNode, "name", groupNames[theType])
        local usedGroupNames = {}
        local usedModelGroupNames = {}
        for i, mod in ipairs(modsList[theType]) do
            local modelBaseID = mod.base_id
            local groupName = defaultGroupNames[modelBaseID]
            if not groupName then
                groupName = "Other"
            end
            if not usedGroupNames[groupName] then
                usedGroupNames[groupName] = true
            end
            usedModelGroupNames[modelBaseID] = groupName
        end
        local usedGroupNodes = {}
        for groupName, _ in pairs(usedGroupNames) do
            local groupNode = xmlCreateChild(parentGroupNode, "group")
            xmlNodeSetAttribute(groupNode, "name", groupName)
            usedGroupNodes[groupName] = groupNode
        end

        local count = 0
        for i, mod in ipairs(modsList[theType]) do
            local modelID = mod.id
            local modelBaseID = mod.base_id
            local modelName = mod.name
            local groupName = usedModelGroupNames[modelBaseID]
            local groupNode = usedGroupNodes[groupName]
            local tagName = string.sub(theType, 1, -2)
            local modelNode = xmlCreateChild(groupNode, tagName)
            xmlNodeSetAttribute(modelNode, "model", modelID)
            xmlNodeSetAttribute(modelNode, "base_model", modelBaseID)
            xmlNodeSetAttribute(modelNode, "name", modelName)
            xmlNodeSetAttribute(modelNode, "keywords", '')
            count = count + 1
        end

        xmlSaveFile(xmlRoot)
        xmlUnloadFile(xmlRoot)

        return count
    end

    local theTypeCounts = {}
    for theType, _ in pairs(modsList) do
        local count, errorMessage = addNewModels(theType)
        if not count then
            return false, errorMessage
        end

        theTypeCounts[theType] = count
    end

    return theTypeCounts
end

--[[
    Runs the tool
]]
function newModelsEditor(thePlayer, cmd)
    if not canUseTool(thePlayer) then
        return outputChatBox("You don't have permission to use /"..cmd..".", thePlayer, 255, 22, 22)
    end

    local editor_gui = getResourceFromName("editor_gui")
    if not editor_gui then
        return outputChatBox("The resource 'editor_gui' could not be found.", thePlayer, 255, 22, 22)
    end

    if getResourceState(editor_gui) == "running" then
        outputChatBox("The resource 'editor_gui' is running.", thePlayer, 255, 22, 22)
        outputChatBox("  Stop the Map Editor before using this tool (/stop editor).", thePlayer, 222, 222, 222)

        local play = getResourceFromName("play")
        if play and getResourceState(play) == "loaded" then
            outputChatBox("  You can go into freeroam mode by starting Play (/start play).", thePlayer, 222, 222, 222)
        end
        return
    end

    local result, reason = updateEditorGUIFiles()
    if not result then
        return outputChatBox("Failed to update the editor GUI files: "..reason, thePlayer, 255, 22, 22)
    end

    outputChatBox("The editor GUI files have been updated.", thePlayer, 22, 255, 22)

    for theType, count in pairs(result) do
        outputChatBox("  "..count.." "..theType.." have been added to the list.", thePlayer, 222, 222, 222)
    end

    outputChatBox("  Start the Map Editor to enjoy the updated new models (/start editor).", thePlayer, 222, 222, 222)
end
addCommandHandler(COMMAND_NAME, newModelsEditor, false, false)