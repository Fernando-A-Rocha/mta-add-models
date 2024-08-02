-- Backwards compatibility with newmodels 3.3.0

-- Rewrite the import feature to include the shared_exported.lua file

local exportScriptString = nil
_import = import
function import()
    local str = _import()
    if not exportScriptString then
        local f = fileOpen("scripts/optional/compatibility/shared_exported.lua", true)
        if not f then
            return error("Failed to open file.")
        end
        exportScriptString = fileGetContents(f, true) -- verifies checksum
        fileClose(f)
        if not exportScriptString or exportScriptString == "" then
            return error("Failed to read file.")
        end
    end
    return str .. "\n" .. exportScriptString
end
