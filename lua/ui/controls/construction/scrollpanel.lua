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

local Group = import('/lua/maui/group.lua').Group
local IconCheckbox = import('/lua/maui/checkbox.lua').IconCheckbox
local ScrollGrid = import('/lua/ui/controls/construction/scrollgrid.lua').ScrollGrid

---@class ScrollPanel : Group
ScrollPanel = ClassUI(Group) {

    __init = function(self, parent)
        Group.__init(self, parent)
        self.skipBackButton = IconCheckbox(self)
        self.backButton = IconCheckbox(self)
        self.forwardButton = IconCheckbox(self)
        self.skipForwardButton = IconCheckbox(self)

        self.skipBackButton.OnClick = function(checkbox, modifiers)
            self:SkipBack()
        end

        self.backButton.OnClick = function(checkbox, modifiers)
            self:ScrollBack()
        end

        self.forwardButton.OnClick = function(checkbox, modifiers)
            self:ScrollForward()
        end

        self.skipForwardButton.OnClick = function(checkbox, modifiers)
            self:SkipForward()
        end

        self.grid = ScrollGrid(self)

        self.scrollIndex = 1

        -- Set to 10 for testing
        self.maxScroll = 10

        import('/lua/ui/controls/construction/layouts/bottomMini/scrollpanel.lua').InitLayoutFunctions(self)
    end,

    SkipBack = function(self)
        self.scrollIndex = 1
        _ALERT('ScrollPanel:SkipBack called, setting scrollIndex to 1')
    end,

    ScrollBack = function(self)
        if self.scrollIndex > 1 then
            self.scrollIndex = self.scrollIndex - 1
        end
        LOG('ScrollPanel: ScrollBack called, scrollIndex is now ' .. self.scrollIndex)
    end,

    ScrollForward = function(self)
        if self.scrollIndex < self.maxScroll then
            self.scrollIndex = self.scrollIndex + 1
        end
        LOG('ScrollPanel: ScrollForward called, scrollIndex is now ' .. self.scrollIndex)
    end,

    SkipForward = function(self)
        if self.maxScroll then
            self.scrollIndex = self.maxScroll
        else
            WARN('OrderGrid: SkipForward called before maxScroll was set. Did you forget to call layout?')
        end
        LOG('ScrollPanel: SkipForward called, scrollIndex is now ' .. self.scrollIndex)
    end,

    Layout = function(self)
    end,

    -- This is where the processing for displaying the queue occurs
    OnSelection = function(self, data)
    end,

}