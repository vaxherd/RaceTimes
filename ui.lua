local _, RaceTimes = ...

local class = RaceTimes.class

RaceTimes.UI = {}

local TEXT_SCALE = 1.2
local COLOR_GREY = {0.5, 0.5, 0.5}
local COLOR_BRONZE = {0.6, 0.4, 0.1}
local COLOR_SILVER = {0.9, 0.9, 0.97}
local COLOR_GOLD = {1.0, 0.75, 0.2}
local RANK_COLORS = {COLOR_GREY, COLOR_GOLD, COLOR_SILVER, COLOR_BRONZE}

local CATEGORY_NAMES = {
    [RaceTimes.Category.NORMAL]    = "Normal",
    [RaceTimes.Category.ADVANCED]  = "Advanced",
    [RaceTimes.Category.REVERSE]   = "Reverse",
    [RaceTimes.Category.CHALLENGE] = "Challenge",
    [RaceTimes.Category.REV_CHALL] = "R-Challenge",
    [RaceTimes.Category.STORM]     = "Storm",
}

local BUTTON_LAYOUT = {
    {category = RaceTimes.Category.NORMAL,    x = -1, y = 0},
    {category = RaceTimes.Category.ADVANCED,  x =  0, y = 0},
    {category = RaceTimes.Category.CHALLENGE, x =  1, y = 0},

    {category = RaceTimes.Category.STORM,     x = -1, y = 1},
    {category = RaceTimes.Category.REVERSE,   x =  0, y = 1},
    {category = RaceTimes.Category.REV_CHALL, x =  1, y = 1},
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
    if not InCombatLockdown() then
        if not WorldMapFrame:IsShown() then ToggleWorldMap() end
        WorldMapFrame:SetMapID(self.race.waypoint.uiMapID)
    end
    C_Map.SetUserWaypoint(self.race.waypoint)
end

------------------------------------------------------------------------

local TimeLabel = class()

function TimeLabel:__constructor(parent, race)
    self.race = race

    local f = CreateFrame("Frame", nil, parent)
    self.frame = f
    f:SetScript("OnEnter", function() self:OnEnter() end)
    f:SetScript("OnLeave", function() self:OnLeave() end)

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

function TimeLabel:OnEnter()
    if GameTooltip:IsForbidden() then return end
    GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")
    GameTooltip:SetPoint("LEFT", self.frame, "RIGHT")
    if self:UpdateTooltip() then
        GameTooltip:Show()
    end
end

function TimeLabel:OnLeave()
    if GameTooltip:IsForbidden() then return end
    GameTooltip:Hide()
end

function TimeLabel:UpdateTooltip()
    local instance = self.race.instances[RaceTimes.UI.active_category]
    if not instance then
        return false
    end
    GameTooltip:ClearLines()
    local gold_str = ("Gold: %d.%03d sec"):format(
        math.floor(instance.gold/1000), instance.gold%1000)
    GameTooltip:AddLine(gold_str, unpack(COLOR_GOLD))
    local silver_str = ("Silver: %d.%03d sec"):format(
        math.floor(instance.silver/1000), instance.silver%1000)
    GameTooltip:AddLine(silver_str, unpack(COLOR_SILVER))
    return true
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

local CategoryButton = class()

function CategoryButton:__constructor(parent, category)
    local f = CreateFrame("Button", nil, parent, "RaceTimesCategoryButtonTemplate")
    self.frame = f
    f:SetID(category)
    f.Text:SetText(CATEGORY_NAMES[category])
end

function CategoryButton:SetSinglePoint(arg1, arg2, ...)
    local f = self.frame
    if type(arg2) == "table" then  -- assumed to be another CategoryButton
        arg2 = arg2.frame
    end
    f:ClearAllPoints()
    f:SetPoint(arg1, arg2, ...)
end

function CategoryButton:GetID()
    return self.frame:GetID()
end

function CategoryButton:SetCurrent(current)
    local color = current and HIGHLIGHT_FONT_COLOR or NORMAL_FONT_COLOR
    self.frame.Text:SetTextColor(color:GetRGB())
end

------------------------------------------------------------------------

local function RaceTag(zone, race)
    return zone .. "/" .. race
end

local function AddRace(frame, zone, race)
    frame.race_anchors[RaceTag(zone.name, race.name)] = -(frame.yofs)

    local f = frame.scroll.content

    local time_label = TimeLabel(f, race)
    frame.time_labels[RaceTag(zone.name, race.name)] = time_label
    time_label:SetSinglePoint("TOPRIGHT", -5, frame.yofs)

    local race_label = RaceLabel(f, race)
    race_label:SetPoint("TOPLEFT", 30, frame.yofs)
    race_label:SetPoint("TOPRIGHT", time_label:GetFrame(), "TOPLEFT", -5, 0)

    frame.yofs = frame.yofs - 25
end

local function AddZone(frame, zone)
    frame.zone_anchors[zone.map_id] = -(frame.yofs)

    local label = frame.scroll.content:CreateFontString(
        nil, "ARTWORK", "GameFontHighlightLarge")
    label:SetPoint("TOPLEFT", 10, frame.yofs-20)
    label:SetTextScale(TEXT_SCALE)
    label:SetText(zone.name)
    frame.yofs = frame.yofs - 50

    for _, race in ipairs(zone.races) do
        AddRace(frame, zone, race)
    end
end

function RaceTimes_LoadData(frame)  -- referenced by XML
    local time_labels = frame.time_labels
    if not time_labels then return end  -- when called from XML load
    local category = RaceTimes.UI.active_category
    for _, zone, race in RaceTimes.Data.EnumerateRaces() do
        local label = time_labels[RaceTag(zone.name, race.name)]
        local time, rank = race:GetTime(category)
        label:SetTime(time, rank)
    end
end

function RaceTimes_ChangeCategory(category)  -- referenced by XML
    RaceTimes.UI.active_category = category
    local frame = RaceTimesFrame
    for _, button in ipairs(frame.buttons) do
        button:SetCurrent(button:GetID() == category)
    end
    if frame:IsShown() then
        RaceTimes_LoadData(frame)
    end
 end

------------------------------------------------------------------------

local SPELLID_RaceStarting = 409799

local active_race = nil
local active_race_label = nil
local active_race_start = nil
local active_race_gold = nil
local active_race_silver = nil

local function ActiveRaceTimer_OnUpdate()
    assert(active_race)
    if not active_race_start then
        for i = 1, 40 do
            local data = C_UnitAuras.GetBuffDataByIndex("player", i)
            if not data then break end
            if data.spellId == SPELLID_RaceStarting then
                return  -- Race hasn't started yet
            end
        end
        -- "Race Starting" buff is gone, so race has started
        active_race_start = GetTime()
    end
    local msec = math.floor((GetTime() - active_race_start) * 1000 + 0.5)
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
                local yofs = RaceTimesFrame.race_anchors[tag]
                yofs = yofs + active_race_label.frame:GetHeight()/2
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

    -- Allow ourselves to be cleanly closed via CloseAllWindows().
    tinsert(UISpecialFrames, "RaceTimesFrame")

    local category_select = frame.category_select
    frame.buttons = {}
    local layout = {}
    for _, button_setup in ipairs(BUTTON_LAYOUT) do
        local button = CategoryButton(category_select, button_setup.category)
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
    frame.zone_anchors = {}
    frame.race_anchors = {}
    frame.yofs = 0
    for _, zone in RaceTimes.Data.EnumerateZones() do
        AddZone(frame, zone)
    end
    frame.scroll.content:SetSize(frame.scroll:GetWidth(), -(frame.yofs)+10)

    RaceTimes_ChangeCategory(RaceTimes.Category.NORMAL)

    InitActiveRaceTimer()
end

-- Helper for Open().
local function ScrollToCurrentMap()
    local map_id = C_Map.GetBestMapForUnit("player")
    -- The top-level ("Cosmic") map has a parent ID of 0, but we play
    -- it safe and check for nil as well.
    while map_id and map_id > 0 do
        local yofs = RaceTimesFrame.zone_anchors[map_id]
        if yofs then
            RaceTimesFrame.scroll:SetVerticalScroll(yofs)
            break
        end
        local info = C_Map.GetMapInfo(map_id)
        map_id = info and info.parentMapID
    end
end

function RaceTimes.UI.Open()
    RaceTimesFrame:Show()

    -- Scroll to the user's current zone if it has any races.
    -- If this is the first time the frame has been opened since login or
    -- /reload, delay until the next game frame to work around a bug in
    -- ScrollFrame causing the content and scroll handle to not be set
    -- properly.  (FIXME: see whether the newer options-window style of
    -- scroll frame also has this bug)
    if RaceTimesFrame.scroll:GetVerticalScrollRange() == 0 then
        C_Timer.After(0, ScrollToCurrentMap)
    else
        ScrollToCurrentMap()
    end
end
