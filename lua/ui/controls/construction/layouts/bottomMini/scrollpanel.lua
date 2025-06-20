--******************************************************************************************************
--** Copyright (c) 2025 FAForever
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

local bgTextures = {
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
        self.bgCapL = Bitmap(self)
        self.bgMid = Bitmap(self)
        self.bgCapR = Bitmap(self)
        self.initialized = true
    end
end

Layout = function(self, key)

    Layouter(self.bgCapL)
        :Texture(bgTextures.left)
        :AtLeftTopIn(self, 1)
        :WidthFromTexture(bgTextures.left)
        :FillVertically(self)
        :End()

    Layouter(self.bgCapR)
        :Texture(bgTextures.right)
        :AtRightTopIn(self, 1)
        :WidthFromTexture(bgTextures.right)
        :FillVertically(self)
        :End()

    Layouter(self.bgMid)
        :Texture(bgTextures.middle)
        :RightOf(self.bgCapL)
        :LeftOf(self.bgCapR)
        :FillVertically(self)
        :End()

    local txtr = buttonTextures.left
    self.skipBackButton:SetNewTextures(txtr.up, txtr.down, txtr.over, txtr.dis)
    self.skipBackButton:SetIconTextures(GetIconTextures('skipBack'))

    txtr = buttonTextures.right
    self.skipForwardButton:SetNewTextures(txtr.up, txtr.down, txtr.over, txtr.dis)
    self.skipForwardButton:SetIconTextures(GetIconTextures('skipForward'))

    txtr = buttonTextures.middle
    self.backButton:SetNewTextures(txtr.up, txtr.down, txtr.over, txtr.dis)
    self.backButton:SetIconTextures(GetIconTextures('back'))

    self.forwardButton:SetNewTextures(txtr.up, txtr.down, txtr.over, txtr.dis)
    self.forwardButton:SetIconTextures(GetIconTextures('forward'))

    Layouter(self.skipBackButton)
        :AtLeftTopIn(self)
        :DimensionsFromTexture(buttonTextures.left.up)
        :End()

    Layouter(self.skipForwardButton)
        :AtRightTopIn(self)
        :DimensionsFromTexture(buttonTextures.right.up)
        :End()

    Layouter(self.backButton)
        :RightOf(self.skipBackButton)
        :DimensionsFromTexture(buttonTextures.middle.up)
        :End()

    Layouter(self.forwardButton)
        :LeftOf(self.skipForwardButton)
        :DimensionsFromTexture(buttonTextures.middle.up)
        :End()

end