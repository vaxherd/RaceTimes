local _, RaceTimes = ...
RaceTimes.Settings = {}

local _L = RaceTimes._L
local class = RaceTimes.class

-- Global settings data (persists across reloads).
RaceTimes_settings = nil

------------------------------------------------------------------------

-- Default settings list.  Anything in here which is missing from
-- RaceTimes_settings after module load is inserted by the init routine.
local DEFAULTS = {
    -- Display best time across all saved characters?
    show_saved_best = false,
}

------------------------------------------------------------------------

-- Abstract base class for config panel elements.  Lua technically
-- doesn't need an explicit abstract base class because everything is
-- resolved dynamically, but this serves as documentation of the shared
-- API for all elements.

local ConfigPanelElement = class()

-- Return the desired vertical spacing between this element and the next.
function ConfigPanelElement:GetSpacing()
    return 0
end

------------------------------------------------------------------------

local CPCheckButton = class(ConfigPanelElement)

-- If setting_or_state is a string, it gives the setting ID to which the
-- button will be linked; otherwise, it gives the initial state of the
-- button, either true (checked) or false (unchecked), and depends_on must
-- be nil.
function CPCheckButton:__constructor(panel, x, y, text, setting_or_state,
                                     on_change, depends_on)
    assert(type(setting_or_state)=="string"
           or setting_or_state==true or setting_or_state==False)
    assert(type(setting_or_state)=="string" or depends_on==nil)

    local initial
    if type(setting_or_state) == "string" then
        self.setting = setting_or_state
        initial = RaceTimes_settings[setting_or_state]
    else
        self.setting = nil
        initial = setting_or_state
    end
    self.on_change = on_change
    self.depends_on = depends_on
    self.dependents = {}

    local indent = depends_on and 1 or 0
    local button = CreateFrame("CheckButton", nil, panel.frame,
                               "UICheckButtonTemplate")
    self.button = button
    button:SetPoint("TOPLEFT", x+30*indent, y)
    button.text:SetTextScale(1.25)
    button.text:SetText(text)
    button:SetChecked(initial)
    button:SetScript("OnClick", function() self:OnClick() end)
    if depends_on then
        depends_on:AddDependent(self)
        self:SetSensitive(RaceTimes_settings[depends_on.setting])
    end
end

function CPCheckButton:GetSpacing()
    return 30
end

function CPCheckButton:AddDependent(dependent)
    tinsert(self.dependents, dependent)
end

function CPCheckButton:SetSensitive(sensitive) -- SetEnable() plus color change
    local button = self.button
    self.button:SetEnabled(sensitive)
    -- SetEnabled() doesn't change the text color, so we have to do
    -- that manually.
    self.button.text:SetTextColor(
        (sensitive and NORMAL_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
end

function CPCheckButton:SetChecked(checked)
    checked = checked and true or false  -- Force to boolean type.
    self.button:SetChecked(checked)
    self:OnClick()
end

function CPCheckButton:OnClick()
    -- This is called _after_ the UIButton state has been toggled, so we
    -- only need to perform appropriate updates.
    local checked = self.button:GetChecked()
    for _, dep in ipairs(self.dependents) do
        dep:SetSensitive(checked)
    end
    if self.setting then
        RaceTimes_settings[self.setting] = checked
    end
    if self.on_change then
        self.on_change(checked)
    end
end

------------------------------------------------------------------------

-- This class is not a visible element, but serves to group all radio
-- buttons for a single setting to ensure that only one is checked.
local CPRadioGroup = class()

function CPRadioGroup:__constructor(setting, on_change)
    self.setting = setting
    self.on_change = on_change
    self.buttons = {}
end

-- button must be a CPRadioButton.
function CPRadioGroup:AddButton(button)
    self.buttons[button.value] = button
end

function CPRadioGroup:SetValue(value)
    local value_button = self.buttons[value]
    if not value_button then
        error(("Invalid value for radio group %s: %s"):format(
                  self.setting, value))
        return
    end
    value_button:SetChecked(true)
    for _, button in pairs(self.buttons) do
        if button ~= value_button then
            button:SetChecked(false)
        end
    end
    RaceTimes_settings[self.setting] = value
    if self.on_change then
        self.on_change(value)
    end
end

------------------------------------------------------------------------

local CPRadioButton = class(ConfigPanelElement)

-- Automatically adds the button to the given CPRadioGroup.
function CPRadioButton:__constructor(panel, x, y, text, group, value)
    self.group = group
    self.value = value

    self.on_change = on_change
    self.depends_on = depends_on
    self.dependents = {}

    local button = CreateFrame("CheckButton", nil, panel.frame,
                               "UIRadioButtonTemplate")
    self.button = button
    button:SetPoint("TOPLEFT", x, y)
    button.text:SetTextScale(1.25)
    button.text:SetText(text)
    button:SetChecked(RaceTimes_settings[group.setting] == value)
    button:SetScript("OnClick", function() self:OnClick() end)

    group:AddButton(self)
end

function CPRadioButton:GetSpacing()
    return 20
end

function CPRadioButton:SetChecked(checked)
    self.button:SetChecked(checked)
end

function CPRadioButton:OnClick()
    self.group:SetValue(self.value)
end

------------------------------------------------------------------------

local ConfigPanel = class()

function ConfigPanel:__constructor()
    self.buttons = {}

    local f = CreateFrame("Frame", "RaceTimes_SettingsPanel")
    self.frame = f
    self.x = 10
    self.y = 0

    self:AddHeader(_L("Time display settings"))
    self:AddCheckButton(_L("Show best time across all saved characters"),
                        "show_saved_best", RaceTimes.UI.RefreshTimes)
    self:AddComment(_L("When unchecked, the best time for the current character is shown."))

    self:AddDivider()
    self:AddHeader(_L("Saved character management"))
    self.y = self.y - 5
    self:AddComment(_L("Unchecking a character causes that character's times to be deleted on the next login or UI reload."))
    self:AddComment(_L("The logged-in character's times are always recorded."))
    local player_name =
        UnitNameUnmodified("player").."-"..select(2, UnitFullName("player"))
    self:AddCharacterCheckButton(player_name, true)
    for _, name in ipairs(RaceTimes.SavedTimes.GetSavedChars()) do
        if name ~= player_name then
            self:AddCharacterCheckButton(name)
        end
    end

    self:AddDivider()
    self:AddHeader(_L("About RaceTimes"))
    self:AddText(_L("RaceTimes is a simple addon to record and display best times for each skyriding race, optionally across multiple characters.") .. "|n|n" ..
                 _L("The best time list can be opened with the |cFFFFFF00/racetimes|r (or |cFFFFFF00/rt|r) command.") .. "|n|n" ..
                 _L("Author: ").."vaxherd|n" ..
                 _L("Version: ")..RaceTimes.VERSION)

    f:SetHeight(-self.y + 10)
end

function ConfigPanel:AddHeader(text)
    local f = self.frame
    local label = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    self.y = self.y - 20
    label:SetPoint("TOPLEFT", self.x, self.y)
    label:SetTextScale(1.2)
    label:SetText(text)
    self.y = self.y - 25
    return label
end

function ConfigPanel:AddText(text)
    local f = self.frame
    local label = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.y = self.y - 15
    label:SetPoint("TOPLEFT", self.x, self.y)
    label:SetPoint("TOPRIGHT", -self.x, self.y)
    label:SetJustifyH("LEFT")
    label:SetSpacing(3)
    label:SetTextScale(1.1)
    label:SetText(text)
    -- FIXME: This is fundamentally broken because we don't know how wide
    -- the frame will be until it's sized when the options window is first
    -- opened, and therefore we don't know how tall it will end up being.
    -- We can get away with this for now because this is only used once
    -- and at the very bottom of the config frame (for the about text).
    self.y = self.y - 100
    return label
end

function ConfigPanel:AddComment(text)
    local f = self.frame
    local label = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", self.x+40, self.y+4)
    label:SetTextColor(1, 0.5, 0)
    label:SetText(text)
    self.y = self.y - 16
    return label
end

function ConfigPanel:AddDivider(text)
    self.y = self.y - 20
    local f = self.frame
    local texture = f:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("LEFT", f, "TOPLEFT", self.x, self.y)
    texture:SetPoint("RIGHT", f, "TOPRIGHT", 0, self.y)
    texture:SetHeight(1.5)
    texture:SetAtlas("Options_HorizontalDivider")
    self.y = self.y - 10
    return texture
end

function ConfigPanel:AddCheckButton(text, setting, on_change, depends_on)
    depends_on = depends_on and self.buttons[depends_on]
    local button = CPCheckButton(self, self.x+10, self.y,
                                 text, setting, on_change, depends_on)
    self.y = self.y - button:GetSpacing()
    self.buttons[setting] = button
end

function ConfigPanel:AddCharacterCheckButton(name, is_player)
    local function OnChange(checked)
        RaceTimes.SavedTimes.SetSaveChar(name, checked)
    end
    local checked = is_player or RaceTimes.SavedTimes.GetSaveChar(name)
    local button = CPCheckButton(self, self.x+10, self.y,
                                 name, checked, OnChange, nil)
    if is_player then
        button:SetSensitive(false)
    end
    self.y = self.y - button:GetSpacing()
end

-- Call as: AddRadioGroup(header, setting, on_change,
--                        text1, value1, [text2, value2...])
function ConfigPanel:AddRadioGroup(header, setting, on_change, ...)
    local f = self.frame
    local label = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.y = self.y - 10
    label:SetPoint("TOPLEFT", self.x+15, self.y)
    label:SetText(header)
    self.y = self.y - 20

    local group = CPRadioGroup(setting, on_change)
    for i = 1, select("#",...), 2 do
        local text, value = select(i,...)
        local button = CPRadioButton(self, self.x+35, self.y,
                                     text, group, value)
        self.y = self.y - button:GetSpacing()
    end
end

------------------------------------------------------------------------

function RaceTimes.Settings.Init()
    RaceTimes_settings = RaceTimes_settings or {}
    for k, v in pairs(DEFAULTS) do
        if RaceTimes_settings[k] == nil then
            RaceTimes_settings[k] = v
        end
    end

    local config_panel = ConfigPanel()
    RaceTimes.Settings.panel = config_panel
    local f = config_panel.frame

    local container = CreateFrame("ScrollFrame", "RaceTimes_SettingsScroller",
                                  nil, "ScrollFrameTemplate")
    container:SetScrollChild(f)

    local root = CreateFrame("Frame", "RaceTimes_SettingsRoot")
    container:SetParent(root)
    -- Required by the settings API:
    function root:OnCommit()
    end
    function root:OnDefault()
        -- Currently unimplemented because we don't have a defaults button.
    end
    function root:OnRefresh()
        container:ClearAllPoints()
        container:SetPoint("TOPLEFT")
        container:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -29, 6)
        f:SetWidth(container:GetWidth())
    end
    local category = Settings.RegisterCanvasLayoutCategory(root, "RaceTimes")
    RaceTimes.Settings.category = category
    category.ID = "RaceTimes"
    Settings.RegisterAddOnCategory(category)
end

function RaceTimes.Settings.Open()
    Settings.OpenToCategory(RaceTimes.Settings.category.ID)
end
