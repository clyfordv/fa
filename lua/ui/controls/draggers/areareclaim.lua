local UserDecal = import('/lua/user/UserDecal.lua').UserDecal
local Dragger = import('/lua/maui/dragger.lua').Dragger

---@param callbackTable table -- Should be of the form {Func = function, Args = {}} or {Func = "$simCallbackString", Args = {}}
---@param minRadius? number -- Optional radius, smaller than this will cancel the drag
function AreaDragger(callbackTable, minRadius)

    local view = import("/lua/ui/game/worldview.lua").viewLeft
    if not view then
        WARN("AreaReclaimDragger: No view found")
        return
    end
    local targetPos = GetMouseWorldPos()
    local worldPos
    local dragger = Dragger()
    local decal
    local rad = 0

    dragger.OnMove = function(self, x, y)
        worldPos = UnProject(view, {x,y})
        rad = VDist2(targetPos[1], targetPos[3], worldPos[1], worldPos[3])
        if not decal then
            decal = UserDecal()
            -- we could add a texture parameter and use it here
            decal:SetTexture("/textures/ui/common/game/AreaTargetDecal/weapon_icon_small.dds")
        end
        decal:SetScale({ rad * 2, 1, rad * 2 })
        decal:SetPosition(targetPos)
    end

    -- When we release the mouse button, check our radius and do the callback
    dragger.OnRelease = function(self, x, y)
        if rad > (minRadius or 1) then
            -- add our radius to our callback parameter table
            callbackTable.Args.Radius = rad
            if type(callbackTable.Func) == string then
                -- If our function in the callback table is a string, it's a SimCallback
                SimCallback(callbackTable, true)
            else
                -- Otherwise, call the function directly
                callbackTable.Func(callbackTable.Args)
            end
        end
        if decal then decal:Destroy() end
        self:Destroy()
    end

    -- Not sure under what conditions this would be called,
    dragger.OnCancel = function(self)
        if decal then decal:Destroy() end
        self:Destroy()
    end

    -- Whatever this is, it registers the dragger with the engine
    -- event.KeyCode is currently hard coded to '1', but should probably be obtained from the event
    PostDragger(view:GetRootFrame(), '1', dragger)
end