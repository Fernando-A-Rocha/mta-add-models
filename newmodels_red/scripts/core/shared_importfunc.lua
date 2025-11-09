-- Exports the entire shared script to the importing resource, so it can be loaded there

local exportScriptString = nil
function import()
    if not sourceResource or sourceResource == resource then
        return error("This function can only be called from another resource.")
    end
    if not exportScriptString then
        local f = fileOpen("scripts/core/shared_exported.lua", true)
        if not f then
            return error("Failed to open file.")
        end
        exportScriptString = fileGetContents(f, true) -- verifies checksum
        fileClose(f)
        if not exportScriptString or exportScriptString == "" then
            return error("Failed to read file.")
        end
        exportScriptString = exportScriptString:gsub("IS_IMPORTED = false", "IS_IMPORTED = true")
    end
    return exportScriptString
end
