--**********************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local NavUtils = import("/lua/sim/navutils.lua")

---@class NavDebugDirectionToState
---@field Layer NavLayers
---@field Distance number
---@field Destination Vector
local State = {}

---@type boolean
local Enabled = false

--- Enables the debugging functionality
function Enable()
    NavUtils.Generate()
    Enabled = true
end

--- Disables the debugging functionality
function Disable()
    Enabled = false
end

--- Updates the state of the debugging functionality
---@param data NavDebugDirectionToState
function Update(data)
    State = data
end

--- Represents the debug functionality, only starts running when the file is imported
function DebugThread()
    while true do
        if Enabled then
            local origin = GetMouseWorldPos()
            local layer = State.Layer
            local distance = State.Distance
            local destination = State.Destination
            if layer and origin and distance and destination then
                local direction, error = NavUtils.DirectionTo(layer, origin, destination, distance)
                DrawCircle(destination, 2, '0000FF')
                if direction then
                    DrawCircle(origin, 2, 'ffffff')
                    DrawLinePop(origin, direction, 'ffffff')
                else
                    DrawCircle(origin, 2, 'ff0000')
                    WARN("NavDirectionTo - " .. error)
                end
            end
        end

        WaitTicks(1)
    end
end

--- Create an instance of the debug thread
local DebugThreadInstance = ForkThread(DebugThread)

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if DebugThreadInstance then
        DebugThreadInstance:Destroy()
    end
end
