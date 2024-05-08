local _, RaceTimes = ...

local class = RaceTimes.class

RaceTimes.UI = {}

local TEXT_SCALE = 1.2
local COLOR_GREY = {0.5, 0.5, 0.5}
local COLOR_BRONZE = {0.6, 0.4, 0.1}
local COLOR_SILVER = {0.9, 0.9, 0.97}
local COLOR_GOLD = {1.0, 0.75, 0.2}
local RANK_COLORS = {COLOR_GREY, COLOR_GOLD, COLOR_SILVER, COLOR_BRONZE}

local TYPE_NAMES = {
    [RaceTimes.Type.NORMAL]    = "Normal",
    [RaceTimes.Type.ADVANCED]  = "Advanced",
    [RaceTimes.Type.REVERSE]   = "Reverse",
    [RaceTimes.Type.CHALLENGE] = "Challenge",
    [RaceTimes.Type.REV_CHALL] = "R-Challenge",
    [RaceTimes.Type.STORM]     = "Storm",
}

local BUTTON_LAYOUT = {
    {type = RaceTimes.Type.NORMAL,    x = -1, y = 0},
    {type = RaceTimes.Type.ADVANCED,  x =  0, y = 0},
    {type = RaceTimes.Type.CHALLENGE, x =  1, y = 0},

    {type = RaceTimes.Type.STORM,     x = -1, y = 1},
    {type = RaceTimes.Type.REVERSE,   x =  0, y = 1},
    {type = RaceTimes.Type.REV_CHALL, x =  1, y = 1},
}

------------------------------------------------------------------------

local RaceLabel = class()

function RaceLabel:__constructor(parent, race)
    self.race = race

    local f = CreateFrame("Button", nil, parent)
    self.frame = f

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT")
    icon:SetSize(13, 13)
    icon:SetAtlas("Waypoint-MapPin-ChatIcon")

    local label = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", icon, "RIGHT", 2, 0)
    label:SetTextColor(0.8, 0.8, 0.8)
    label:SetTextScale(TEXT_SCALE)
    label:SetText(race.name)

    f:SetHeight(label:GetStringHeight())
    f:SetScript("OnClick", function(_,...) self:OnClick(...) end)
end

function RaceLabel:SetPoint(...)
    self.frame:SetPoint(...)
end

function RaceLabel:OnClick(button, down)
    C_Map.SetUserWaypoint(self.race.waypoint)
    if not WorldMapFrame:IsShown() then ToggleWorldMap() end
    WorldMapFrame:SetMapID(self.race.waypoint.uiMapID)
end

------------------------------------------------------------------------

local TimeLabel = class()

function TimeLabel:__constructor(parent)
    local f = CreateFrame("Frame", nil, parent)
    self.frame = f

    local text_label = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.text_label = text_label
    text_label:SetPoint("RIGHT")
    text_label:SetTextScale(TEXT_SCALE)
    text_label:SetJustifyH("CENTER")

    local ms_label = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.ms_label = ms_label
    ms_label:SetPoint("RIGHT")
    ms_label:SetTextScale(TEXT_SCALE)
    ms_label:SetJustifyH("LEFT")
    ms_label:Hide()

    local sec_label = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.sec_label = sec_label
    sec_label:SetPoint("RIGHT", ms_label, "LEFT")
    sec_label:SetTextScale(TEXT_SCALE)
    sec_label:SetJustifyH("RIGHT")
    sec_label:Hide()

    if not TimeLabel.width then
        text_label:SetText("00:00.000")
        TimeLabel.width = text_label:GetStringWidth() + 4
        TimeLabel.height = text_label:GetStringHeight()
        text_label:SetText(".000")
        TimeLabel.ms_width = text_label:GetStringWidth() + 2
        text_label:SetText("")
    end
    f:SetSize(TimeLabel.width, TimeLabel.height)
    text_label:SetWidth(TimeLabel.width)
    ms_label:SetWidth(TimeLabel.ms_width)
    sec_label:SetWidth(TimeLabel.width - TimeLabel.ms_width)
end

function TimeLabel:GetFrame()
    return self.frame
end

function TimeLabel:SetSinglePoint(...)
    local f = self.frame
    f:ClearAllPoints()
    f:SetPoint(...)
end

-- Expects values returned from Race:GetTime().
function TimeLabel:SetTime(time, rank)
    local text_label = self.text_label
    local ms_label = self.ms_label
    local sec_label = self.sec_label

    if not time then
        text_label:SetTextColor(unpack(COLOR_GREY))
        text_label:SetText("—")
        text_label:Show()
        ms_label:Hide()
        sec_label:Hide()

    elseif time == 0 then
        text_label:SetTextColor(unpack(COLOR_GREY))
        text_label:SetText("(No time)")
        text_label:Show()
        ms_label:Hide()
        sec_label:Hide()

    else
        local ms = time % 1000
        local sec = math.floor(time / 1000) % 60
        local min = math.floor(time / (60*1000))
        local color = RANK_COLORS[rank+1]
        ms_label:SetTextColor(unpack(color))
        ms_label:SetText((".%03d"):format(ms))
        sec_label:SetTextColor(unpack(color))
        sec_label:SetText(("%d:%02d"):format(min, sec))
        text_label:Hide()
        ms_label:Show()
        sec_label:Show()

    end
end

------------------------------------------------------------------------

local TypeButton = class()

function TypeButton:__constructor(parent, type)
    local f = CreateFrame("Button", nil, parent, "RaceTimesTypeButtonTemplate")
    self.frame = f
    f:SetID(type)
    f.Text:SetText(TYPE_NAMES[type])
end

function TypeButton:SetSinglePoint(arg1, arg2, ...)
    local f = self.frame
    if type(arg2) == "table" then  -- assumed to be another TypeButton
        arg2 = arg2.frame
    end
    f:ClearAllPoints()
    f:SetPoint(arg1, arg2, ...)
end

function TypeButton:GetID()
    return self.frame:GetID()
end

function TypeButton:SetCurrent(current)
    local color = current and HIGHLIGHT_FONT_COLOR or NORMAL_FONT_COLOR
    self.frame.Text:SetTextColor(color:GetRGB())
end

------------------------------------------------------------------------

local function RaceTag(zone, race)
    return zone .. "/" .. race
end

local function AddRace(frame, zone, race)
    local f = frame.scroll.content

    local time_label = TimeLabel(f)
    frame.time_labels[RaceTag(zone.name, race.name)] = time_label
    time_label:SetSinglePoint("TOPRIGHT", -5, frame.yofs)

    local race_label = RaceLabel(f, race)
    race_label:SetPoint("TOPLEFT", 30, frame.yofs)
    race_label:SetPoint("TOPRIGHT", time_label:GetFrame(), "TOPLEFT", -5, 0)

    frame.yofs = frame.yofs - 25
end

local function AddZone(frame, zone, map_id)
    local f = frame.scroll.content

    local label = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    label:SetPoint("TOPLEFT", 10, frame.yofs-20)
    label:SetTextScale(TEXT_SCALE)
    label:SetText(zone.name)
    frame.yofs = frame.yofs - 50

    zone:EnumerateRaces(function(race) AddRace(frame,zone,race) end)
end

function RaceTimes_LoadData(frame)  -- referenced by XML
    local time_labels = frame.time_labels
    if not time_labels then return end  -- when called from XML load
    local type = RaceTimes.UI.active_type
    RaceTimes.Data.EnumerateRaces(function(zone, race)
        local label = time_labels[RaceTag(zone.name, race.name)]
        local time, rank = race:GetTime(type)
        label:SetTime(time, rank)
    end)
end

function RaceTimes_ChangeType(type)  -- referenced by XML
    RaceTimes.UI.active_type = type
    local frame = RaceTimesFrame
    for _, button in ipairs(frame.buttons) do
        button:SetCurrent(button:GetID() == type)
    end
    if frame:IsShown() then
        RaceTimes_LoadData(frame)
    end
 end

------------------------------------------------------------------------

function RaceTimes.UI.Init()
    local frame = RaceTimesFrame  -- from XML
    frame:Hide()

    -- Allow ourselves to be cleanly closed via CloseAllWindows()
    tinsert(UISpecialFrames, "RaceTimesFrame")

    local type_select = frame.type_select
    frame.buttons = {}
    local layout = {}
    for _, button_setup in ipairs(BUTTON_LAYOUT) do
        local button = TypeButton(type_select, button_setup.type)
        tinsert(frame.buttons, button)
        layout[button_setup.y] = layout[button_setup.y] or {}
        layout[button_setup.y][button_setup.x] = button
    end
    for y, row in pairs(layout) do
        for x, button in pairs(row) do
            if x == 0 then
                button:SetSinglePoint("CENTER", 0, 13 - 26*y)
            elseif x < 0 then
                button:SetSinglePoint("RIGHT", layout[y][0], "LEFT", -8, 0)
            else  -- x > 0
                button:SetSinglePoint("LEFT", layout[y][0], "RIGHT", 8, 0)
            end
        end
    end

    frame.time_labels = {}
    frame.yofs = 0
    RaceTimes.Data.EnumerateZones(
        function(zone,map_id) AddZone(frame,zone,map_id) end)
    frame.scroll.content:SetSize(frame.scroll:GetWidth(), -(frame.yofs)+10)

    RaceTimes_ChangeType(RaceTimes.Type.NORMAL)
end

function RaceTimes.UI.Open()
    RaceTimesFrame:Show()
end
