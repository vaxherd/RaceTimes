local _, RaceTimes = ...
RaceTimes.UI = {}

local _L = RaceTimes._L
local class = RaceTimes.class
local Button = RaceTimes.Button
local Frame = RaceTimes.Frame

local floor = math.floor


local TEXT_SCALE = 1.2
local COLOR_GREY = {0.5, 0.5, 0.5}
local COLOR_BRONZE = {0.6, 0.4, 0.1}
local COLOR_SILVER = {0.9, 0.9, 0.97}
local COLOR_GOLD = {1.0, 0.75, 0.2}
local RANK_COLORS = {COLOR_GREY, COLOR_GOLD, COLOR_SILVER, COLOR_BRONZE}

local CATEGORY_NAMES = {
    [RaceTimes.Category.NORMAL]    = _L("Normal"),
    [RaceTimes.Category.ADVANCED]  = _L("Advanced"),
    [RaceTimes.Category.REVERSE]   = _L("Reverse"),
    [RaceTimes.Category.CHALLENGE] = _L("Challenge"),
    [RaceTimes.Category.REV_CHALL] = _L("R-Challenge"),
    [RaceTimes.Category.STORM]     = _L("Storm"),
}

local BUTTON_LAYOUT = {
    {category = RaceTimes.Category.NORMAL,    x = -1, y = 0},
    {category = RaceTimes.Category.ADVANCED,  x =  0, y = 0},
    {category = RaceTimes.Category.REVERSE,   x =  1, y = 0},

    {category = RaceTimes.Category.STORM,     x = -1, y = 1},
    {category = RaceTimes.Category.CHALLENGE, x =  0, y = 1},
    {category = RaceTimes.Category.REV_CHALL, x =  1, y = 1},
}

------------------------------------------------------------------------

local RaceLabel = class(Button)

local RACE_BUTTON_MARGIN = 2

function RaceLabel:__allocator(parent, race)
    return Button.__allocator("Button", nil, parent)
end

function RaceLabel:__constructor(parent, race)
    self.race = race

    local icon = self:CreateTexture(nil, "ARTWORK")
    self.icon = icon
    icon:SetPoint("LEFT")
    icon:SetSize(13, 13)
    icon:SetAtlas("Waypoint-MapPin-ChatIcon")

    local label = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.label = label
    label:SetPoint("LEFT", icon, "RIGHT", RACE_BUTTON_MARGIN, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.8, 0.8, 0.8)
    label:SetTextScale(TEXT_SCALE)
    label:SetText(race:GetLocalizedName())

    self:SetHeight(label:GetStringHeight())
    self:SetScript("OnClick", self.OnClick)
    self:SetScript("OnSizeChanged", self.OnSizeChanged)
end

function RaceLabel:OnClick(button, down)
    if not InCombatLockdown() then
        if not WorldMapFrame:IsShown() then ToggleWorldMap() end
        WorldMapFrame:SetMapID(self.race.waypoint.uiMapID)
    end
    C_Map.SetUserWaypoint(self.race.waypoint)
end

function RaceLabel:OnSizeChanged(width, height)
    local label = self.label
    local label_width =
        self:GetWidth() - (self.icon:GetWidth() + RACE_BUTTON_MARGIN)
    label:SetWidth(0)
    label:SetTextScale(TEXT_SCALE)
    local text_width = label:GetUnboundedStringWidth()
    if text_width > label_width then
        local scale = label_width / text_width
        -- Simply changing the text scale value doesn't always give us
        -- the expected size result (probably due to font rendering
        -- details like pixel alignment and kerning), so we keep trying
        -- until we actually fit within the desired space.
        local prev = text_width
        label:SetTextScale(TEXT_SCALE * scale)
        text_width = label:GetUnboundedStringWidth(text)
        while text_width > label_width do
            local change = text_width / prev
            -- Avoid getting stuck doing tiny increments over and over.
            if change > 0.97 then change = 0.97 end
            scale = scale * change
            if scale <= 0.8 then
                label:SetTextScale(TEXT_SCALE * 0.8)
                -- Enable line wrapping if needed.
                label:SetWidth(label_width)
                break
            end
            prev = text_width
            label:SetTextScale(TEXT_SCALE * scale)
            text_width = label:GetUnboundedStringWidth(text)
        end
    end
end

------------------------------------------------------------------------

local TimeLabel = class(Frame)

-- Accepts a time in milliseconds and returns two values:
-- minutes_seconds_string, milliseconds_string
local function FormatTime(time)
    local ms = time % 1000
    local sec = floor(time / 1000) % 60
    local min = floor(time / (60*1000))
    return string.format(_L("%d:%02d"), min, sec),
           string.format(_L(".%03d"), ms)
end

function TimeLabel:__allocator(parent, race)
    return Frame.__allocator("Frame", nil, parent)
end

function TimeLabel:__constructor(parent, race)
    self.race = race

    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)

    local text_label = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.text_label = text_label
    text_label:SetPoint("RIGHT")
    text_label:SetTextScale(TEXT_SCALE)
    text_label:SetJustifyH("CENTER")

    local ms_label = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.ms_label = ms_label
    ms_label:SetPoint("RIGHT")
    ms_label:SetTextScale(TEXT_SCALE)
    ms_label:SetJustifyH("LEFT")
    ms_label:Hide()

    local sec_label = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.sec_label = sec_label
    sec_label:SetPoint("RIGHT", ms_label, "LEFT")
    sec_label:SetTextScale(TEXT_SCALE)
    sec_label:SetJustifyH("RIGHT")
    sec_label:Hide()

    if not TimeLabel.width then
        local zero_sec, zero_ms = FormatTime(0)
        text_label:SetText("0"..zero_sec..zero_ms)
        TimeLabel.width = text_label:GetStringWidth() + 4
        TimeLabel.height = text_label:GetStringHeight()
        text_label:SetText(zero_ms)
        TimeLabel.ms_width = text_label:GetStringWidth() + 2
        text_label:SetText("")
    end
    self:SetSize(TimeLabel.width, TimeLabel.height)
    text_label:SetWidth(TimeLabel.width)
    ms_label:SetWidth(TimeLabel.ms_width)
    sec_label:SetWidth(TimeLabel.width - TimeLabel.ms_width)
end

function TimeLabel:OnEnter()
    if GameTooltip:IsForbidden() then return end
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("LEFT", self, "RIGHT")
    if self:UpdateTooltip() then
        GameTooltip:Show()
    end
end

function TimeLabel:OnLeave()
    if GameTooltip:GetOwner() == self then
        GameTooltip:Hide()
    end
end

function TimeLabel:UpdateTooltip()
    local instance = self.race.instances[RaceTimes.UI.active_category]
    if not instance then
        return false
    end
    GameTooltip:ClearLines()
    local gold_sec, gold_ms = FormatTime(instance.gold)
    local gold_str = _L("Gold:").." "..gold_sec..gold_ms
    GameTooltip:AddLine(gold_str, unpack(COLOR_GOLD))
    local silver_sec, silver_ms = FormatTime(instance.silver)
    local silver_str = _L("Silver:").." "..silver_sec..silver_ms
    GameTooltip:AddLine(silver_str, unpack(COLOR_SILVER))
    return true
end

function TimeLabel:SetSinglePoint(...)
    self:ClearAllPoints()
    self:SetPoint(...)
end

-- Expects values returned from Race:GetTime().
function TimeLabel:SetTime(time, rank)
    local text_label = self.text_label
    local sec_label = self.sec_label
    local ms_label = self.ms_label

    if not time then
        text_label:SetTextColor(unpack(COLOR_GREY))
        text_label:SetText("—")
        text_label:Show()
        sec_label:Hide()
        ms_label:Hide()

    elseif time == 0 then
        text_label:SetTextColor(unpack(COLOR_GREY))
        text_label:SetText("(No time)")
        text_label:Show()
        sec_label:Hide()
        ms_label:Hide()

    else
        local sec_str, ms_str = FormatTime(time)
        local color = RANK_COLORS[rank+1]
        sec_label:SetTextColor(unpack(color))
        sec_label:SetText(sec_str)
        ms_label:SetTextColor(unpack(color))
        ms_label:SetText(ms_str)
        text_label:Hide()
        sec_label:Show()
        ms_label:Show()

    end
end

------------------------------------------------------------------------

local CategoryButton = class(Button)

function CategoryButton:__allocator(parent, category)
    return Button.__allocator("Button", nil, parent,
                              "RaceTimesCategoryButtonTemplate")
end

function CategoryButton:__constructor(parent, category)
    self:SetID(category)
    self.Text:SetText(CATEGORY_NAMES[category])
end

function CategoryButton:SetSinglePoint(...)
    self:ClearAllPoints()
    self:SetPoint(...)
end

function CategoryButton:SetCurrent(current)
    local color = current and HIGHLIGHT_FONT_COLOR or NORMAL_FONT_COLOR
    self.Text:SetTextColor(color:GetRGB())
    self:SetButtonState(current and "PUSHED" or "NORMAL", current)
    -- UIPanelButton implements its own "pushed" texture swapping, so we
    -- have to call that logic as appropriate.
    if current then
        UIPanelButton_OnMouseDown(self)
    else
        UIPanelButton_OnMouseUp(self)
    end
end

------------------------------------------------------------------------

local ZoneButton = class(Button)

function ZoneButton:__allocator(parent, group)
    return Button.__allocator("Button", nil, parent,
                              "RaceTimesZoneButtonTemplate")
end

function ZoneButton:__constructor(parent, group)
    self.group = group
    self:SetID(group.group_map)
    if type(group.icon_texture) == "number" then
        SetPortraitTextureFromCreatureDisplayID(self.icon, group.icon_texture)
    else
        self.icon:SetTexture(group.icon_texture)
    end
    self.background:Hide()
end

function ZoneButton:SetCurrent(current)
    self.background:SetShown(current)
end

function ZoneButton:OnEnter()
    if GameTooltip:IsForbidden() then return end
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("RIGHT", self, "LEFT")
    GameTooltip:AddLine(self.group:GetLocalizedName(),
                        WHITE_FONT_COLOR:GetRGB())
    GameTooltip:Show()
end

function ZoneButton:OnLeave()
    if GameTooltip:GetOwner() == self then
        GameTooltip:Hide()
    end
end

------------------------------------------------------------------------

local function RaceTag(zone, race)
    return zone .. "/" .. race
end

local function AddRace(frame, zone, race)
    frame.race_anchors[RaceTag(zone.name, race.name)] = -(frame.yofs)

    local time_label = TimeLabel(frame, race)
    RaceTimesFrame.time_labels[RaceTag(zone.name, race.name)] = time_label
    time_label:SetSinglePoint("TOPRIGHT", -5, frame.yofs)

    local race_label = RaceLabel(frame, race)
    race_label:SetPoint("TOPLEFT", 30, frame.yofs)
    race_label:SetPoint("TOPRIGHT", time_label, "TOPLEFT", -5, 0)

    frame.yofs = frame.yofs - 25
end

local function AddZone(frame, zone)
    frame.zone_anchors[zone.map_id] = -(frame.yofs)

    local label = frame:CreateFontString(
        nil, "ARTWORK", "GameFontHighlightLarge")
    label:SetPoint("TOPLEFT", 10, frame.yofs-20)
    label:SetTextScale(TEXT_SCALE)
    label:SetText(zone:GetLocalizedName())
    frame.yofs = frame.yofs - 50

    for _, race in ipairs(zone.races) do
        AddRace(frame, zone, race)
    end
end

function RaceTimes_LoadData(frame)  -- referenced by XML
    local time_labels = frame.time_labels
    if not time_labels then return end  -- when called from XML load
    local category = RaceTimes.UI.active_category
    local show_saved_best = RaceTimes_settings["show_saved_best"]
    for _, zone, race in RaceTimes.Data.EnumerateRaces() do
        local label = time_labels[RaceTag(zone.name, race.name)]
        local time, rank = race:GetTime(category, show_saved_best)
        label:SetTime(time, rank)
    end
end

function RaceTimes_ChangeCategory(category)  -- referenced by XML
    RaceTimes.UI.active_category = category
    local frame = RaceTimesFrame
    for _, button in ipairs(frame.category_buttons) do
        button:SetCurrent(button:GetID() == category)
    end
    if frame:IsShown() then
        RaceTimes_LoadData(frame)
    end
 end

function RaceTimes_ChangeZoneGroup(group)  -- referenced by XML
    RaceTimes.UI.active_zone_group = group
    local frame = RaceTimesFrame
    for _, button in ipairs(frame.zone_buttons) do
        button:SetCurrent(button:GetID() == group)
    end

    -- Only show Storm/Challenge/R-Challenge buttons when viewing
    -- Dragon Isles races (since those categories only exist there).
    local is_dragon_isles = (group == 1978)
    local yofs = is_dragon_isles and 10 or 0
    for _, button in ipairs(frame.category_buttons) do
        local id = button:GetID()
        local is_unique_cat = (id >= RaceTimes.Category.CHALLENGE)
        local is_center = (id == RaceTimes.Category.ADVANCED or
                           id == RaceTimes.Category.CHALLENGE)
        button:SetShown(not is_unique_cat or is_dragon_isles)
        if is_center then
            button:ClearPointsOffset()
            button:AdjustPointsOffset(0, is_unique_cat and -yofs or yofs)
        end
    end
    if not is_dragon_isles
    and RaceTimes.UI.active_category >= RaceTimes.Category.CHALLENGE
    then
        RaceTimes_ChangeCategory(RaceTimes.Category.NORMAL)
    end

    local active_group_frame
    for group_map, group_frame in pairs(frame.group_frames) do
        if group_map == group then
            frame.scroll.content:SetSize(group_frame:GetWidth(),
                                         group_frame:GetHeight())
            frame.scroll:SetVerticalScroll(0)
            group_frame:Show()
            active_group_frame = group_frame
        else
            group_frame:Hide()
        end
    end
    return active_group_frame
 end

------------------------------------------------------------------------

local active_race = nil
local active_race_label = nil
local active_race_start = nil
local active_race_gold = nil
local active_race_silver = nil

local function ActiveRaceTimer_OnUpdate()
    assert(active_race)
    for i = 1, 40 do
        local data = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not data then break end
        if data.name == _L("Race Starting") then
            -- Race hasn't started yet.  Reset state in case we're
            -- restarting with the Bronze Timepiece.
            active_race_start = nil
            active_race_label:SetTime(0.001, 0)
            return
        end
    end
    -- "Race Starting" buff is gone, so race has started.
    if not active_race_start then
        active_race_start = GetTime()
    end
    local msec = floor((GetTime() - active_race_start) * 1000 + 0.5)
    active_race_label:SetTime(msec, (msec < active_race_gold and 1 or
                                     msec < active_race_silver and 2 or 3))
end

local function ActiveRaceTimer_OnEvent(event, ...)
    if event == "UNIT_QUEST_LOG_CHANGED" then
        local new_zone, new_race, new_category, new_instance
        for _, zone, race in RaceTimes.Data.EnumerateRaces() do
            for category, instance in pairs(race.instances) do
                if C_QuestLog.IsOnQuest(instance.quest) then
                    new_zone = zone
                    new_race = race
                    new_category = category
                    new_instance = instance
                    break
                end
            end
            if new_race then break end
        end
        if new_race then
            if RaceTimesFrame:IsShown() and active_race ~= new_race then
                local tag = RaceTag(new_zone.name, new_race.name)
                active_race = new_race
                active_race_label = RaceTimesFrame.time_labels[tag]
                assert(active_race_label)
                active_race_start = nil
                active_race_gold = new_instance.gold
                active_race_silver = new_instance.silver
                RaceTimes_ChangeCategory(new_category)
                local group_frame = RaceTimes_ChangeZoneGroup(RaceTimes.Data.FindZoneGroupForMap(new_zone.map_id).group_map)
                local yofs = group_frame.race_anchors[tag]
                yofs = yofs + active_race_label:GetHeight()/2
                yofs = yofs - RaceTimesFrame.scroll:GetHeight()/2
                if yofs < 0 then yofs = 0 end
                RaceTimesFrame.scroll:SetVerticalScroll(yofs)
                active_race_label:SetTime(0.001, 0)  -- force "0:00.000"
                RaceTimesFrame:SetScript("OnUpdate", ActiveRaceTimer_OnUpdate)
            end
        else
            active_race = nil
            active_race_start = nil
            RaceTimesFrame:SetScript("OnUpdate", nil)
            RaceTimes_LoadData(RaceTimesFrame)
        end
    end
end

local function InitActiveRaceTimer()
    RaceTimesFrame:RegisterUnitEvent("UNIT_QUEST_LOG_CHANGED", "player")
    RaceTimesFrame:SetScript("OnEvent", function(self,...) ActiveRaceTimer_OnEvent(...) end)
end

------------------------------------------------------------------------

function RaceTimes.UI.Init()
    local frame = RaceTimesFrame  -- from XML
    frame:Hide()
    frame:SetFrameLevel(frame:GetParent():GetFrameLevel()+5)
    -- Allow ourselves to be cleanly closed via CloseAllWindows().
    tinsert(UISpecialFrames, "RaceTimesFrame")

    frame.header.Text:SetText(_L("Skyriding Race Times"))
    frame.header:SetWidth(frame.header.Text:GetUnboundedStringWidth() + 50)

    local category_select = frame.category_select
    frame.category_buttons = {}
    local layout = {}
    for _, button_setup in ipairs(BUTTON_LAYOUT) do
        local button = CategoryButton(category_select, button_setup.category)
        tinsert(frame.category_buttons, button)
        layout[button_setup.y] = layout[button_setup.y] or {}
        layout[button_setup.y][button_setup.x] = button
    end
    for y, row in pairs(layout) do
        for x, button in pairs(row) do
            if x == 0 then
                button:SetSinglePoint("CENTER", 0, 10 - 20*y)
            elseif x < 0 then
                button:SetSinglePoint("RIGHT", layout[y][0], "LEFT", -15, 0)
            else  -- x > 0
                button:SetSinglePoint("LEFT", layout[y][0], "RIGHT", 15, 0)
            end
        end
    end

    local zone_select = frame.zone_select
    frame.zone_buttons = {}
    for _, group_data in RaceTimes.Data.EnumerateZoneGroups() do
        local button = ZoneButton(zone_select, group_data)
        tinsert(frame.zone_buttons, button)
        if #frame.zone_buttons > 1 then
            button:SetPoint(
                "TOP", frame.zone_buttons[#frame.zone_buttons-1], "BOTTOM")
        else
            button:SetPoint("TOP")
        end
    end

    frame.time_labels = {}
    frame.group_frames = {}
    local zone_group_mapping = {}
    for _, group_data in RaceTimes.Data.EnumerateZoneGroups() do
        local group_frame = CreateFrame("Frame", nil, frame.scroll.content)
        frame.group_frames[group_data.group_map] = group_frame
        group_frame:SetPoint("TOPLEFT")
        group_frame:SetWidth(frame.scroll:GetWidth())
        group_frame:Hide()
        group_frame.yofs = 0
        group_frame.zone_anchors = {}
        group_frame.race_anchors = {}
        for _, zone in ipairs(group_data.zone_maps) do
            zone_group_mapping[zone] = group_data.group_map
        end
    end
    for _, zone in RaceTimes.Data.EnumerateZones() do
        local group_frame = frame.group_frames[zone_group_mapping[zone.map_id]]
        assert(group_frame)
        AddZone(group_frame, zone)
        group_frame:SetHeight(-(group_frame.yofs)+10)
    end

    RaceTimes_ChangeCategory(RaceTimes.Category.NORMAL)
    RaceTimes_ChangeZoneGroup(2274)  -- Khaz Algar

    InitActiveRaceTimer()
end

-- Helper for Open().
local function ScrollToCurrentMap()
    local map_id = C_Map.GetBestMapForUnit("player")
    -- The top-level ("Cosmic") map has a parent ID of 0, but we play
    -- it safe and check for nil as well.
    while map_id and map_id > 0 do
        local group = RaceTimes.Data.FindZoneGroupForMap(map_id)
        if group then
            local group_frame = RaceTimes_ChangeZoneGroup(group.group_map)
            local yofs = group_frame.zone_anchors[map_id]
            if yofs then
                RaceTimesFrame.scroll:SetVerticalScroll(yofs)
            end
            break
        end
        local info = C_Map.GetMapInfo(map_id)
        map_id = info and info.parentMapID
    end
end

function RaceTimes.UI.Open()
    RaceTimesFrame:Show()

    -- Refresh the "pressed" state of all buttons (since it seems to get
    -- reset whenever the frame is re-opened).
    RaceTimes_ChangeCategory(RaceTimes.UI.active_category)

    -- Scroll to the user's current zone if it has any races.
    -- If this is the first time the frame has been opened since login or
    -- /reload, delay until the next game frame to work around a bug in
    -- ScrollFrame causing the content and scroll handle to not be set
    -- properly.
    if RaceTimesFrame.scroll:GetVerticalScrollRange() == 0 then
        C_Timer.After(0, ScrollToCurrentMap)
    else
        ScrollToCurrentMap()
    end
end

function RaceTimes.UI.RefreshTimes()
    RaceTimes_LoadData(RaceTimesFrame)
end

function RaceTimes.UI.Recenter()
    local frame = RaceTimesFrame
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", 0, 100)
    -- Fake a drag start/stop to update the saved position.
    frame:StartMoving()
    frame:StopMovingOrSizing()
end
