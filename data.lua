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
-- We don't currently make use of the quest or aura IDs, but we save them
-- for future reference just in case they become useful.

local function Race(map_x, map_y, times_aura, name, types)
    local race = {name = name, map_x = map_x, map_y = map_y,
                  times_aura = times_aura, types = {}}
    for type, data in pairs(types) do
        race.types[RaceTimes.Type[type]] =
            {quest = data[1], currency = data[2],
             gold = (data[3] or 0) * 1000, silver = (data[4] or 0) * 1000}
    end
    return race
end

local RACES = {
    {"The Waking Shores", 2022, {
        Race(23.25, 84.31, 415640, "Apex Canopy River Run",
                                   {NORMAL = {66732, 2054, 52, 55}}),
        Race(41.96, 67.31, 415639, "Emberflow Flight",
                                   {NORMAL = {66727, 2052, 50, 53}}),
        Race(62.75, 74.02, 415643, "Flashfrost Flyover",
                                   {NORMAL = {66710, 2046, 63, 66}}),
        Race(63.30, 70.91, 415541, "Ruby Lifeshrine Loop",
                                   {NORMAL = {66679, 2042, 53, 56}}),
        Race(55.44, 41.15, 415641, "Uktulut Coaster",
                                   {NORMAL = {66777, 2056, 45, 48}}),
        Race(42.58, 94.46, 415644, "Wild Preserve Circuit",
                                   {NORMAL = {66725, 2050, 40, 43}}),
        Race(47.00, 85.59, 415638, "Wild Preserve Slalom",
                                   {NORMAL = {66721, 2048, 42, 45}}),
        Race(73.18, 33.95, 415642, "Wingrest Roundabout",
                                   {NORMAL = {66786, 2058, 53, 56}}),
    }},

    {"Ohn'ahran Plains", 2023, {
        Race(25.69, 55.10, 415654, "Emerald Garden Ascent",
                                   {NORMAL = {66885, 2066, 63, 66}}),
        Race(86.24, 35.85, 415652, "Fen Flythrough",
                                   {NORMAL = {66877, 2062, 48, 51}}),
        Race(59.92, 35.57, 415656, "Maruukai Dash",
                                   {NORMAL = {66921, 2069, 25, 28}}),
        Race(47.47, 70.65, 415657, "Mirror of the Sky Dash",
                                   {NORMAL = {66933, 2070, 26, 29}}),
        Race(80.87, 72.22, 415653, "Ravine River Run",
                                   {NORMAL = {66880, 2064, 49, 52}}),
        Race(43.73, 66.79, 415658, "River Rapids Route",
                                   {NORMAL = {70710, 2119, 48, 51}}),
        Race(63.72, 30.52, 415650, "Sundapple Copse Circuit",
                                   {NORMAL = {66835, 2060, 49, 52}}),
    }},

    {"Azure Span", 2024, {
        Race(42.26, 56.77, 415664, "Archive Ambit",
                                   {NORMAL = {67741, 2089, 91, 94}}),
        Race(20.94, 22.63, 415660, "Azure Span Slalom",
                                   {NORMAL = {67002, 2076, 58, 61}}),
        Race(47.90, 40.79, 415659, "Azure Span Sprint",
                                   {NORMAL = {66946, 2074, 63, 66}}),
        Race(48.46, 35.80, 415663, "Frostland Flyover",
                                   {NORMAL = {67565, 2085, 76, 79}}),
        Race(16.57, 49.38, 415662, "Iskaara Tour",
                                   {NORMAL = {67296, 2083, 75, 78}}), --68.784
        Race(71.26, 24.66, 415661, "Vakthros Ascent",
                                   {NORMAL = {67031, 2078, 58, 61}}),
    }},

    {"Thaldraszus", 2025, {
        Race(60.28, 41.59, 415669, "Academy Ascent",
                                   {NORMAL = {70059, 2098, 54, 57}}),
        Race(58.04, 33.62, 415671, "Caverns Criss-Cross",
                                   {NORMAL = {70161, 2103, 50, 53}}),
        Race(37.63, 48.94, 415668, "Cliffside Circuit",
                                   {NORMAL = {70051, 2096, 69, 72}}),
        Race(57.76, 75.02, 415665, "Flowing Forest Flight",
                                   {NORMAL = {67095, 2080, 49, 52}}),
        Race(39.50, 76.19, 415670, "Garden Gallivant",
                                   {NORMAL = {70157, 2101, 61, 64}}),
        Race(57.22, 66.91, 415666, "Tyrhold Trial",
                                   {NORMAL = {69957, 2092, 81, 84}}),
    }},

    {"Forbidden Reach", 2151, {
        Race(63.07, 51.97, 415791, "Aerie Chasm Cruise",
                                   {NORMAL = {73025, 2203, 53, 56}}),
        Race(41.33, 14.56, 415793, "Caldera Coaster",
                                   {NORMAL = {73033, 2205, 58, 61}}),
        Race(49.40, 60.08, 415794, "Forbidden Reach Rush",
                                   {NORMAL = {73061, 2206, 59, 62}}),
        Race(31.29, 65.76, 415790, "Morqut Ascent",
                                   {NORMAL = {73020, 2202, 52, 55}}),
        Race(63.63, 84.07, 415792, "Southern Reach Route",
                                   {NORMAL = {73029, 2204, 70, 73}}),
        Race(76.11, 65.65, 415789, "Stormsunder Crater Circuit",
                                   {NORMAL = {73017, 2201, 43, 46}}),
    }},

    {"Zaralek Cavern", 2133, {
        Race(54.48, 23.73, 415797, "Brimstone Scramble",
                                   {NORMAL = {74939, 2248, 69, 72}}),
        Race(39.04, 50.00, 415796, "Caldera Cruise",
                                   {NORMAL = {74889, 2247, 75, 80}}),
        Race(38.74, 60.62, 415795, "Crystal Circuit",
                                   {NORMAL = {74839, 2246, 63, 68}}),
        Race(58.14, 57.61, 415799, "Loamm Roamm",
                                   {NORMAL = {74972, 2250, 55, 60}}),
        Race(58.71, 45.04, 415798, "Shimmering Slalom",
                                   {NORMAL = {74951, 2249, 75, 80}}),
        Race(51.25, 46.68, 415800, "Sulfur Sprint",
                                   {NORMAL = {75035, 2251, 64, 67}}),
    }},

    {"Emerald Dream", 2200, {
        Race(62.79, 88.13, 426030, "Canopy Concours",
                                   {NORMAL = {78102, 2680, 105, 110}}),
        Race(32.35, 48.26, 426031, "Emerald Amble",
                                   {NORMAL = {78115, 2681, 84, 89}}),
        Race(69.61, 52.62, 426029, "Shoreline Switchback",
                                   {NORMAL = {78016, 2679, 73, 78}}),
        Race(37.17, 44.08, 426027, "Smoldering Sprint",
                                   {NORMAL = {77983, 2677, 80, 85}}),
        Race(35.15, 55.23, 426028, "Viridescent Venture",
                                   {NORMAL = {77996, 2678, 78, 83}}),
        Race(59.10, 28.82, 426026, "Ysera Invitational",
                                   {NORMAL = {77841, 2676, 98, 103}}),
    }},
}

------------------------------------------------------------------------

-- Return the data for the given race, or nil if not known.
local function GetRace(zone, race)
    for _, zone_data in ipairs(RACES) do
        if zone_data[1] == zone then
            for _, race_data in ipairs(zone_data[3]) do
                if race_data.name == race then
                    return race_data
                end
            end
        end
    end
    return nil
end

------------------------------------------------------------------------

-- Calls callback(zone, map_id) for each zone with races.
function RaceTimes.Data.EnumerateZones(callback)
    for _, data in ipairs(RACES) do
        callback(data[1], data[2])
    end
end

-- Calls callback(race, map_x, map_y) for each race in the given zone.
function RaceTimes.Data.EnumerateRaces(zone, callback)
    for _, zone_data in ipairs(RACES) do
        if zone_data[1] == zone then
            for _, race in ipairs(zone_data[3]) do
                callback(race.name, race.map_x, race.map_y)
            end
        end
    end
end

-- Calls callback(zone, map_id, race, map_x, map_y) for each race in each zone
function RaceTimes.Data.EnumerateAllRaces(callback)
    for _, zone_data in ipairs(RACES) do
        local zone, map_id, zone_races = unpack(zone_data)
        for _, race in ipairs(zone_races) do
            callback(zone, map_id, race.name, race.map_x, race.map_y)
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

-- Debugging / data collection convenience function: prints the quest ID,
-- completion time, and gold/silver times for the most recently run race.
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
