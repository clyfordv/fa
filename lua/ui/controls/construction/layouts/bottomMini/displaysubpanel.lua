--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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
--******************************************************************************************************

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Layouter = LayoutHelpers.ReusedLayoutFor
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local SkinnableFile = import('/lua/ui/uiutil.lua').SkinnableFile

local backgroundTextures = {
    left = SkinnableFile('/game/construct-panel/que-panel_bmp_l.dds'),
    middle = SkinnableFile('/game/construct-panel/que-panel_bmp_m.dds'),
    right = SkinnableFile('/game/construct-panel/que-panel_bmp_r.dds'),
}

local buttonTextures = {
    middle = {
        up = SkinnableFile('/game/construct-sm_btn/mid_btn_up.dds'),
        selected = SkinnableFile('/game/construct-sm_btn/mid_btn_selected.dds'),
        down = SkinnableFile('/game/construct-sm_btn/mid_btn_over.dds'),
        over = SkinnableFile('/game/construct-sm_btn/mid_btn_over.dds'),
        dis = SkinnableFile('/game/construct-sm_btn/mid_btn_dis.dds')
    },
    left = {
        up = SkinnableFile('/game/construct-sm_btn/left_btn_up.dds'),
        down = SkinnableFile('/game/construct-sm_btn/left_btn_over.dds'),
        over = SkinnableFile('/game/construct-sm_btn/left_btn_over.dds'),
        dis = SkinnableFile('/game/construct-sm_btn/left_btn_dis.dds')
    },
    right = {
        up = SkinnableFile('/game/construct-sm_btn/right_btn_up.dds'),
        down = SkinnableFile('/game/construct-sm_btn/right_btn_over.dds'),
        over = SkinnableFile('/game/construct-sm_btn/right_btn_over.dds'),
        dis = SkinnableFile('/game/construct-sm_btn/right_btn_dis.dds')
    },
}

local iconTextures = {
    back = '/game/construct-sm_btn/back_',
    forward = '/game/construct-sm_btn/forward_',
    skipBack = '/game/construct-sm_btn/rewind_',
    skipForward = '/game/construct-sm_btn/fforward_',
}

local GetIconTextures = function(iconId)
    if iconTextures[iconId] then
        local pre = iconTextures[iconId]
        return SkinnableFile(pre..'on.dds'),
            SkinnableFile(pre..'off.dds')
    end
end

InitLayoutFunctions = function(control)
    control.OnLayout = OnLayout
    control.Layout = Layout
end

OnLayout = function(self)

    if not self.initialized then
        self.bgCapLeft = Bitmap(self)
        self.bgCapRight = Bitmap(self)
        self.bgMiddle = Bitmap(self)
    end
end

Layout = function(self)
end