--[[
	Author: Fernando

	New-Weapons [Clientside]
]]

addEvent("new-weapons:syncTable", true)

fixWeapModels = { -- in case it's necessary to fix the model of a weapon
    -- {model=336, txd="replace/bat.txd"},
}

local shader = nil
local texture = nil
local currTextures = {}


addEventHandler("onClientResourceStart", resourceRoot,
    function()
        shader = dxCreateShader([[
            texture tex;
            technique replace {
                pass P0 {
                    Texture[0] = tex;
                    // Alpha blending
                    AlphaBlendEnable = true;
                    SrcBlend = SrcAlpha;
                    DestBlend = InvSrcAlpha;
                }
            }
        ]], 0, 0, false, "ped")
        texture = dxCreateTexture("transparent.png")
        dxSetShaderValue(shader, "tex", texture)

        for k, v in pairs(fixWeapModels) do
            local model = v.model
            local txd = v.txd
            local dff = v.dff

            local txdworked,dffworked = false,false
	        local txdmodel,dffmodel = nil,nil

            if txd then
                local txdElement = engineLoadTXD(txd)
                if txdElement then
                    txdmodel = txdElement
                    if engineImportTXD(txdElement,model) then
                        txdworked = true
                    end
                end
            end

            if dff then
                local dffElement = engineLoadDFF(dff, allocated_id)
                if dffElement then
                    dffmodel = dffElement
                    if engineReplaceModel(dffElement,allocated_id) then
                        dffworked = true
                    end
                end
            end

            if txd then
                if not txdworked then
                    outputDebugString("Failed to load and replace TXD '"..txd.."' for object #"..model, 1)
                else
                    outputDebugString("Loaded and replaced TXD '"..txd.."' for object #"..model, 3)
                end
            end
            if dff then
                if not dffworked then
                    outputDebugString("Failed to load and replace DFF '"..dff.."' for object #"..model, 1)
                else
                    outputDebugString("Loaded and replaced DFF '"..txd.."' for object #"..model, 3)
                end
            end
        end
    end
)
function removeAllTextures()
    for weapID, list in pairs(currTextures) do
        for k, texname in pairs(list) do
            engineRemoveShaderFromWorldTexture(shader, texname, source)
        end
    end
    currTextures = {}
    return true
end


addEventHandler("onClientElementDataChange", root, function(key, old, new)
    if key == weapDataName then
        if getElementType(source) == "player" then
            if type(new) == "table" then

                if removeAllTextures() then
                    for weapID, v in pairs(new) do
                        local baseid = v.weap.baseid
                        local textures = getWeaponTextures(baseid)
                        if textures then
                            for k, texname in pairs(textures) do
                                engineApplyShaderToWorldTexture(shader, texname, source)
                            end
                            currTextures[weapID] = textures
                        else
                            print("No textures found for weapon "..baseid)
                        end
                    end
                end
            else
                removeAllTextures()
            end
        end
    end
end)

addCommandHandler("modeltextures", function(cmd, id)
    id = tonumber(id)
    if not id then
        return outputChatBox("SYNTAX: /"..cmd.." [model id]", 255, 255, 255)
    end

    local textures = engineGetModelTextureNames(tostring(id))
    outputChatBox("Textures for model #"..id.." (See debug; copied to clipboard)")
    if textures then
        iprint(textures)
        setClipboard(tostring(inspect(textures)))
    else
        print("None")
    end
end)