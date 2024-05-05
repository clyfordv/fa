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

--------------------------------------------------------------------------------
-- Layout Terminology
--------------------------------------------------------------------------------

-- Body: the main part of a background element, generally has a cap on each end
-- Cap: end element, generally bookends a body. L/R/T/B == left/right/top/bottom
-- Alternate forms are denoted with $ORIGINALNAME_$ALTFORM (ex: bgMainCapL_TechTab)

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

local textures = {
    bgMainBody = SkinnableFile('/game/construct-panel/construct-panel_bmp_m3.dds'),
    bgMainCapL = SkinnableFile('/game/construct-panel/construct-panel_s_bmp_l.dds'),
    bgMainCapL_TechTab = SkinnableFile('/game/construct-panel/construct-panel_bmp_l.dds'),
    bgMainCapR = SkinnableFile('/game/construct-panel/construct-panel_s_bmp_r.dds'),

    bgTechTabBody = SkinnableFile('/game/construct-panel/construct-panel_bmp_m1.dds'),
    bgTechTabCapR = SkinnableFile('/game/construct-panel/construct-panel_bmp_m2.dds'),

    rightBracketLower = SkinnableFile('/game/bracket-right/bracket_bmp_t.dds'),
    rightBracketUpper = SkinnableFile('/game/bracket-right/bracket_bmp_b.dds'),
    rightBracketMiddle = SkinnableFile('/game/bracket-right/bracket_bmp_m.dds'),
}

---@class ConstructionPanel
---@field bgMainBody Bitmap
---@field bgMainCapL Bitmap
---@field bgMainCapR Bitmap
---@field bgTechTabBody Bitmap
---@field bgTechTabCapR Bitmap
---@field rightBracketLower Bitmap
---@field rightBracketUpper Bitmap
---@field rightBracketMiddle Bitmap
---@field subLayouts table<string, function>

-- Calling this applies the Layout functions in this file to the given control
-- It adds the OnLayout and Layout functions, and the SubLayout table
InitLayoutFunctions = function(control)
    control.OnLayout = OnLayout
    control.Layout = Layout
    control.subLayouts = subLayouts
end

local subLayouts = {
    construction = ConstructionTabLayout,
    selection = SelectionTabLayout,
    enhancement = EnhancementTabLayout
}

local OnLayout = function(self)

    -- Because these are visual elements that don't interact outside
    -- of the layout, we can initialize them here if they are not already
    if not self.bgMainCapL then self.bgMainCapL = Bitmap(self) end -- Left cap bitmap, under the pause/repeat build buttons
    if not self.bgMainCapR then self.bgMainCapR = Bitmap(self) end -- Right cap bitmap, at the rightmost edge of the panel
    if not self.bgTechTabBody then self.bgTechTabBody = Bitmap(self) end -- Background element that pops up behind the tech level radio buttons
    if not self.bgTechTabCapR then self.bgTechTabCapR = Bitmap(self) end-- Rightside cap for the tech tab background (bgMainCapL is the left cap)
    if not self.bgMainBody then self.bgMainBody = Bitmap(self) end-- Main body of our background

    if not self.rightBracketLower then self.rightBracketLower = Bitmap(self) end -- Brackets at the right edge of the panel
    if not self.rightBracketUpper then self.rightBracketUpper = Bitmap(self) end
    if not self.rightBracketMiddle then self.rightBracketMiddle = Bitmap(self) end

    -- We're expecting these elements to already be initialized
    -- If they are not, we should throw a warning
    if not self.constructionTabCluster then
        WARN('layouts/bottomMini/constructionpanel.lua Layout: ConstructionTabCluster not initialized!')
    end
    
    if not self.selectionTabCluster then
        WARN('layouts/bottomMini/constructionpanel.lua Layout: SelectionTabCluster not initialized!')
    end

    if not self.enhancementTabCluster then
        WARN('layouts/bottomMini/constructionpanel.lua Layout: EnhancementTabCluster not initialized!')
    end
end

---comment
---@param self ConstructionPanel
---@param key? string -- Pass a key here to apply a layout from the SubLayout table instead (the main layout function is skipped)
local Layout = function(self, key)

    LOG('background.lua/ConstructionPanel:Layout')

    -- SubLayout check, will skip if key is nil
    if self.subLayouts and self.subLayouts[key] then
        self.subLayouts[key](self)
        return
    elseif key then
        WARN('layouts/bottomMini/constructionpanel Layout: No SubLayout for key passed to Layout!')
    end

    -- Initial layout and texture setup
    Layouter(self.bgMainCapR)
        :Texture(textures.bgMainCapR)
        :AtRightBottomIn(self, 2, 5)

    Layouter(self.bgMainCapL)
        :Texture(textures.bgMainCapL)
        :AtLeftIn(self, 69)
        :AtBottomIn(self.bgMainCapR)

    Layouter(self.bgTechTabBody)
        :Texture(textures.bgTechTabBody)
        :AnchorToRight(self.bgMainCapL)
        :FillVertically(self.bgMainCapL)

    Layouter(self.bgTechTabCapR)
        :Texture(textures.bgTechTabCapR)
        :RightOf(self.bgTechTabBody)

    Layouter(self.bgMainBody)
        :Texture(textures.bgMainBody)
        :AnchorToRight(self.bgTechTabCapR)
        :AnchorToLeft(self.bgMainCapR)
        :FillVertically(self.bgMainCapR)

    -- Brackets on the right side
    Layouter(self.rightBracketLower) -- bottom
        :Texture(textures.rightBracketLower)
        :AtRightIn(self.bgMainCapR, -21)
        :AtTopIn(self.bgMainCapR, -6)
    Layouter(self.rightBracketUpper) -- upper
        :Texture(textures.rightBracketUpper)
        :AtRightIn(self.bgMainCapR, -21)
        :AtBottomIn(self.bgMainCapR, -5)
    Layouter(self.rightBracketMiddle) -- middle that fills the gap
        :Texture(textures.rightBracketMiddle)
        :AtRightIn(self.bgMainCapR, -14)
        :Bottom(self.rightBracketUpper.Top)
        :Top(self.rightBracketLower.Bottom)

    Layouter(self.constructionTabCluster)
        :AnchorToLeft(self.bgMainCapL, -7)
        :AtBottomIn(self.bgMainBody, -11)
        :End()
    Layouter(self.techTabCluster)
        :RightOf(self.bgMainCapL)
        :End()
    Layouter(self.enhancementTabCluster)
        :RightOf(self.bgMainCapL)
        :End()
end

local ConstructionTabLayout = function(self)

    -- Hide and show the elements need/don't need
    self.bgTechTabBody:Show()
    self.bgTechTabCapR:Show()
    self.techTabCluster:Show()
    self.enhancementTabCluster:Hide()
    self.bgTechTabBody.Right:Set(self.techTabCluster.Right)

    ExpandedTechTabBgLayout(self)
end

local EnhancementTabLayout = function(self)
    self.bgTechTabBody:Show()
    self.bgTechTabBody:Show()
    self.enhancementTabCluster:Show()
    self.techTabCluster:Hide()
    self.bgTechTabBody.Right:Set(self.enhancementTabCluster.Right)

    ExpandedTechTabBgLayout(self)
end

local ExpandedTechTabBgLayout = function(self)
    Layouter(self.bgMainCapL) -- Change our left cap texture to the tall tech tab version
        :Texture(textures.bgMainCapL_TechTab)
        :DimensionsFromTexture(textures.bgMainCapL_TechTab) -- We get taller/wider, so we need to update our size
        :AtBottomIn(self.bgMainCapR, -1) -- Textures align differently (ouch) so we also need to adjust our offset
        :AtLeftIn(self, 67)
    Layouter(self.bgMainBody) -- Anchor the left edge of our main background, to end of the cap, on the right of the tech tab
        :AnchorToRight(self.bgTechTabCapR)
    Layouter(self.constructionTabCluster) -- Reanchor the construction tab, because the textures don't align properly otherwise
        :AnchorToLeft(self.bgMainCapL, -7)
end

local SelectionTabLayout = function(self)
    self.bgTechTabBody:Hide()
    self.bgTechTabCapR:Hide()
    self.techTabCluster:Hide()
    self.enhancementTabCluster:Hide()

    -- This is the inverse of ExpandedTechTabBgLayout, but we only need it once
    Layouter(self.bgMainCapL) -- Change our left cap texture to the short version
        :Texture(textures.bgMainCapL)
        :DimensionsFromTexture(textures.bgMainCapL) -- We need to update our size, because we got shorter/narrower
        :AtBottomIn(self.bgMainCapR)
        :AtLeftIn(self, 69)
    Layouter(self.bgMainBody) -- Anchor our main background to the left cap, bypassing the tech tab elements
        :AnchorToRight(self.bgMainCapL)
    Layouter(self.constructionTabCluster)
        :AnchorToLeft(self.bgMainCapL, -5)
end