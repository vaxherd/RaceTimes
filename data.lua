local _, RaceTimes = ...
RaceTimes.Data = {}

-- Type constants for race types.
RaceTimes.Type = {
    NORMAL    = 1,  -- Normal race (always available)
    ADVANCED  = 2,  -- Advanced race
    REVERSE   = 3,  -- Reverse race
    CHALLENGE = 4,  -- Challenge race
    REV_CHALL = 5,  -- Reverse challenge race
    STORM     = 6,  -- Storm Gryphon race
}

------------------------------------------------------------------------

-- Ordered list of all known races, broken down by zone.
-- We don't currently make use of the quest ID, but we save it for
-- future reference just in case it becomes useful.

local function Race(name, types)
    local race = {name = name, types = {}}
    for type, data in pairs(types) do
        race.types[RaceTimes.Type[type]] =
            {quest = data[1], currency = data[2],
             gold = (data[3] or 0) * 1000, silver = (data[4] or 0) * 1000}
    end
    return race
end

local RACES = {
    {"The Waking Shores", {
        Race("Apex Canopy River Run", {NORMAL = {66732, 2054, 52, 55}}),
        Race("Emberflow Flight",      {NORMAL = {66727, 2052, 50, 53}}),
        Race("Flashfrost Flyover",    {NORMAL = {66710, 2046, 63, 66}}),
        Race("Ruby Lifeshrine Loop",  {NORMAL = {66679, 2042, 53, 56}}),
        Race("Uktulut Coaster",       {NORMAL = {66777, 2056, 45, 48}}),
        Race("Wild Preserve Circuit", {NORMAL = {66725, 2050, 40, 43}}),
        Race("Wild Preserve Slalom",  {NORMAL = {66721, 2048, 42, 45}}),
        Race("Wingrest Roundabout",   {NORMAL = {66786, 2058, 53, 56}}),
    }},

    {"Ohn'ahran Plains", {
        Race("Emerald Garden Ascent",   {NORMAL = {66885, 2066, 63, 66}}),
        Race("Fen Flythrough",          {NORMAL = {66877, 2062, 48, 51}}),
        Race("Maruukai Dash",           {NORMAL = {66921, 2069, 25, 28}}),
        Race("Mirror of the Sky Dash",  {NORMAL = {66933, 2070, 26, 29}}),
        Race("Ravine River Run",        {NORMAL = {66880, 2064, 49, 52}}),
        Race("River Rapids Route",      {NORMAL = {70710, 2119, 48, 51}}),
        Race("Sundapple Copse Circuit", {NORMAL = {66835, 2060, 49, 52}}),
    }},

    {"Azure Span", {
        Race("Archive Ambit",     {NORMAL = {67741, 2089, 91, 94}}),
        Race("Azure Span Slalom", {NORMAL = {67002, 2076, 58, 61}}),
        Race("Azure Span Sprint", {NORMAL = {66946, 2074, 63, 66}}),
        Race("Frostland Flyover", {NORMAL = {67565, 2085, 76, 79}}),
        Race("Iskaara Tour",      {NORMAL = {67296, 2083, 75, 78}}),
        Race("Vakthros Ascent",   {NORMAL = {67031, 2078, 58, 61}}),
    }},

    {"Thaldraszus", {
        Race("Academy Ascent",        {NORMAL = {70059, 2098, 54, 57}}),
        Race("Caverns Criss-Cross",   {NORMAL = {70161, 2103, 50, 53}}),
        Race("Cliffside Circuit",     {NORMAL = {70051, 2096, 69, 72}}),
        Race("Flowing Forest Flight", {NORMAL = {67095, 2080, 49, 52}}),
        Race("Garden Gallivant",      {NORMAL = {70157, 2101, 61, 64}}),
        Race("Tyrhold Trial",         {NORMAL = {69957, 2092, 81, 84}}),
    }},

    {"Forbidden Reach", {
        Race("Aerie Chasm Cruise",         {NORMAL = {73025, 2203, 53, 56}}),
        Race("Caldera Coaster",            {NORMAL = {73033, 2205, 58, 61}}),
        Race("Forbidden Reach Rush",       {NORMAL = {73061, 2206, 59, 62}}),
        Race("Morqut Ascent",              {NORMAL = {73020, 2202, 52, 55}}),
        Race("Southern Reach Route",       {NORMAL = {73029, 2204, 70, 73}}),
        Race("Stormsunder Crater Circuit", {NORMAL = {73017, 2201, 43, 46}}),
    }},

    {"Zaralek Cavern", {
        Race("Brimstone Scramble", {NORMAL = {74939, 2248, 69, 72}}),
        Race("Caldera Cruise",     {NORMAL = {74889, 2247, 75, 80}}),
        Race("Crystal Circuit",    {NORMAL = {74839, 2246, 63, 68}}),
        Race("Loamm Roamm",        {NORMAL = {74972, 2250, 55, 60}}),
        Race("Shimmering Slalom",  {NORMAL = {74951, 2249, 75, 80}}),
        Race("Sulfur Sprint",      {NORMAL = {75035, 2251, 64, 67}}),
    }},

    {"Emerald Dream", {
        Race("Canopy Concours",      {NORMAL = {78102, 2680, 105, 110}}),
        Race("Emerald Amble",        {NORMAL = {78115, 2681, 84, 89}}),
        Race("Shoreline Switchback", {NORMAL = {78016, 2679, 73, 78}}),
        Race("Smoldering Sprint",    {NORMAL = {77983, 2677, 80, 85}}),
        Race("Viridescent Venture",  {NORMAL = {77996, 2678, 78, 83}}),
        Race("Ysera Invitational",   {NORMAL = {77841, 2676, 98, 103}}),
    }},
}

------------------------------------------------------------------------

-- Return the data for the given race, or nil if not known.
local function GetRace(zone, race)
    for _, zone_data in ipairs(RACES) do
        if zone_data[1] == zone then
            for _, race_data in ipairs(zone_data[2]) do
                if race_data.name == race then
                    return race_data
                end
            end
        end
    end
    return nil
end

------------------------------------------------------------------------

-- Calls callback(zone) for each zone with races.
function RaceTimes.Data.EnumerateZones(callback)
    for _, data in ipairs(RACES) do
        callback(data[1])
    end
end

-- Calls callback(race) for each race in the given zone.
function RaceTimes.Data.EnumerateRaces(zone, callback)
    for _, zone_data in ipairs(RACES) do
        if zone_data[1] == zone then
            for _, race in ipairs(zone_data[2]) do
                callback(race.name)
            end
        end
    end
end

-- Calls callback(zone, race) for each race in each zone
function RaceTimes.Data.EnumerateAllRaces(callback)
    for _, zone_data in ipairs(RACES) do
        local zone, zone_races = unpack(zone_data)
        for _, race in ipairs(zone_races) do
            callback(zone, race.name)
        end
    end
end

-- Returns the recorded best time for the given race and type, in milliseconds,
-- and the time rank (1 = gold, 2 = silver, 3 = bronze).
-- Returns time 0 and rank 0 if no time has been recorded for the given
-- race and type.
-- Returns nil if the zone/race combination is invalid or the type is
-- not available for that race (such as Reverse for the free-order races).
function RaceTimes.Data.GetTime(zone, race, type)
    local race_data = GetRace(zone, race)
    if not race_data or not race_data.types[type] then return nil end
    local type_data = race_data.types[type]
    local currency = type_data.currency
    local time = C_CurrencyInfo.GetCurrencyInfo(currency).quantity
    local rank = (time == 0 and 0 or
                  time <= type_data.gold and 1 or
                  time <= type_data.silver and 2 or 3)
    return time, rank
end

-- Debugging / data collection convenience function: prints the gold and
-- silver times for the most recently run race.
function RaceTimes.Data.DumpLastTimes()
    local function Read(currency)
        return C_CurrencyInfo.GetCurrencyInfo(currency).quantity
    end
    local function ReadTime(unit, f10, f100, f1000)
        return ("%d.%d%d%d"):format(Read(unit), Read(f10), Read(f100), Read(f1000))
    end
    print("Race: " .. Read(2018))
    print("Race time: " .. ReadTime(2016, 2017, 2124, 2125))
    print("Gold: " .. ReadTime(2020, 2038, 2129, 2130))
    print("Silver: " .. ReadTime(2019, 2037, 2126, 2128))
end
