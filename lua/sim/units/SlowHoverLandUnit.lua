--**********************************************************************************
--** Copyright (c) 2023 FAForever
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

local HoverLandUnit = import("/lua/sim/units/hoverlandunit.lua").HoverLandUnit

---@class SlowHoverLandUnit : HoverLandUnit
SlowHoverLandUnit = ClassUnit(HoverLandUnit) {

    ---@param self SlowHoverLandUnit
    ---@param new string
    ---@param old string
    OnLayerChange = function(self, new, old)

        -- call base class to make sure self.layer is set
        HoverLandUnit.OnLayerChange(self, new, old)

        -- Slow these units down when they transition from land to water
        -- The mult is applied twice thanks to an engine bug, so careful when adjusting it
        -- Newspeed = oldspeed * mult * mult

        local mult = (self.Blueprint or self:GetBlueprint()).Physics.WaterSpeedMultiplier
        if new == 'Water' then
            self:SetSpeedMult(mult)
        else
            self:SetSpeedMult(1)
        end
    end,
}
