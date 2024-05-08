local _, RaceTimes = ...
RaceTimes.Data = {}

local class = RaceTimes.class

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

local RaceInstance = class()
function RaceInstance:__constructor(quest, currency, gold, silver)
    self.quest = quest
    self.currency = currency
    self.gold = math.floor((gold or 0) * 1000 + 0.5)
    self.silver = math.floor((silver or 0) * 1000 + 0.5)
end

local Race = class()
function Race:__constructor(name, waypoint, times_aura, instances)
    self.name = name
    self.waypoint = waypoint
    self.times_aura = times_aura
    self.instances = instances
end
-- Returns the recorded best time for the given race and type, in milliseconds,
-- and the time rank (1 = gold, 2 = silver, 3 = bronze).
-- Returns time 0 and rank 0 if no time has been recorded for the given
-- race and type.
-- Returns nil if the type is not available for that race (such as Reverse
-- for the free-order races).
function Race:GetTime(type)
    local instance = self.instances[type]
    if not instance then return nil end
    local currency = instance.currency
    local time = C_CurrencyInfo.GetCurrencyInfo(currency).quantity
    local rank = (time == 0 and 0 or
                  time <= instance.gold and 1 or
                  time <= instance.silver and 2 or 3)
    return time, rank
end

local Zone = class()
function Zone:__constructor(name, map_id, race_list)
    self.name = name
    self.map_id = map_id
    self.races = {}
    for _, race_data in ipairs(race_list) do
        local map_x, map_y, times_aura, race_name, type_list = unpack(race_data)
        local waypoint =
            UiMapPoint.CreateFromCoordinates(map_id, map_x/100, map_y/100)
        local instances = {}
        for type, data in pairs(type_list) do
            instances[RaceTimes.Type[type]] = RaceInstance(unpack(data))
        end
        tinsert(self.races, Race(race_name, waypoint, times_aura, instances))
    end
end
-- Calls callback(race) for each race in the zone.
function Zone:EnumerateRaces(callback)
    for _, race in ipairs(self.races) do
        callback(race)
    end
end

local ZONES = {
    Zone("The Waking Shores", 2022, {
         {23.25, 84.31, 415640, "Apex Canopy River Run",
                                {NORMAL = {66732, 2054, 52, 55}}},
         {41.96, 67.31, 415639, "Emberflow Flight",
                                {NORMAL = {66727, 2052, 50, 53}}},
         {62.75, 74.02, 415643, "Flashfrost Flyover",
                                {NORMAL = {66710, 2046, 63, 66}}},
         {63.30, 70.91, 415541, "Ruby Lifeshrine Loop",
                                {NORMAL = {66679, 2042, 53, 56}}},
         {55.44, 41.15, 415641, "Uktulut Coaster",
                                {NORMAL = {66777, 2056, 45, 48}}},
         {42.58, 94.46, 415644, "Wild Preserve Circuit",
                                {NORMAL = {66725, 2050, 40, 43}}},
         {47.00, 85.59, 415638, "Wild Preserve Slalom",
                                {NORMAL = {66721, 2048, 42, 45}}},
         {73.18, 33.95, 415642, "Wingrest Roundabout",
                                {NORMAL = {66786, 2058, 53, 56}}},
    }),

    Zone("Ohn'ahran Plains", 2023, {
         {25.69, 55.10, 415654, "Emerald Garden Ascent",
                                {NORMAL = {66885, 2066, 63, 66}}},
         {86.24, 35.85, 415652, "Fen Flythrough",
                                {NORMAL = {66877, 2062, 48, 51}}},
         {59.92, 35.57, 415656, "Maruukai Dash",
                                {NORMAL = {66921, 2069, 25, 28}}},
         {47.47, 70.65, 415657, "Mirror of the Sky Dash",
                                {NORMAL = {66933, 2070, 26, 29}}},
         {80.87, 72.22, 415653, "Ravine River Run",
                                {NORMAL = {66880, 2064, 49, 52}}},
         {43.73, 66.79, 415658, "River Rapids Route",
                                {NORMAL = {70710, 2119, 48, 51}}},
         {63.72, 30.52, 415650, "Sundapple Copse Circuit",
                                {NORMAL = {66835, 2060, 49, 52}}},
    }),

    Zone("Azure Span", 2024, {
         {42.26, 56.77, 415664, "Archive Ambit",
                                {NORMAL = {67741, 2089, 91, 94}}},
         {20.94, 22.63, 415660, "Azure Span Slalom",
                                {NORMAL = {67002, 2076, 58, 61}}},
         {47.90, 40.79, 415659, "Azure Span Sprint",
                                {NORMAL = {66946, 2074, 63, 66}}},
         {48.46, 35.80, 415663, "Frostland Flyover",
                                {NORMAL = {67565, 2085, 76, 79}}},
         {16.57, 49.38, 415662, "Iskaara Tour",
                                {NORMAL = {67296, 2083, 75, 78}}},
         {71.26, 24.66, 415661, "Vakthros Ascent",
                                {NORMAL = {67031, 2078, 58, 61}}},
    }),

    Zone("Thaldraszus", 2025, {
         {60.28, 41.59, 415669, "Academy Ascent",
                                {NORMAL = {70059, 2098, 54, 57}}},
         {58.04, 33.62, 415671, "Caverns Criss-Cross",
                                {NORMAL = {70161, 2103, 50, 53}}},
         {37.63, 48.94, 415668, "Cliffside Circuit",
                                {NORMAL = {70051, 2096, 69, 72}}},
         {57.76, 75.02, 415665, "Flowing Forest Flight",
                                {NORMAL = {67095, 2080, 49, 52}}},
         {39.50, 76.19, 415670, "Garden Gallivant",
                                {NORMAL = {70157, 2101, 61, 64}}},
         {57.22, 66.91, 415666, "Tyrhold Trial",
                                {NORMAL = {69957, 2092, 81, 84}}},
    }),

    Zone("Forbidden Reach", 2151, {
         {63.07, 51.97, 415791, "Aerie Chasm Cruise",
                                {NORMAL = {73025, 2203, 53, 56}}},
         {41.33, 14.56, 415793, "Caldera Coaster",
                                {NORMAL = {73033, 2205, 58, 61}}},
         {49.40, 60.08, 415794, "Forbidden Reach Rush",
                                {NORMAL = {73061, 2206, 59, 62}}},
         {31.29, 65.76, 415790, "Morqut Ascent",
                                {NORMAL = {73020, 2202, 52, 55}}},
         {63.63, 84.07, 415792, "Southern Reach Route",
                                {NORMAL = {73029, 2204, 70, 73}}},
         {76.11, 65.65, 415789, "Stormsunder Crater Circuit",
                                {NORMAL = {73017, 2201, 43, 46}}},
    }),

    Zone("Zaralek Cavern", 2133, {
         {54.48, 23.73, 415797, "Brimstone Scramble",
                                {NORMAL = {74939, 2248, 69, 72}}},
         {39.04, 50.00, 415796, "Caldera Cruise",
                                {NORMAL = {74889, 2247, 75, 80}}},
         {38.74, 60.62, 415795, "Crystal Circuit",
                                {NORMAL = {74839, 2246, 63, 68}}},
         {58.14, 57.61, 415799, "Loamm Roamm",
                                {NORMAL = {74972, 2250, 55, 60}}},
         {58.71, 45.04, 415798, "Shimmering Slalom",
                                {NORMAL = {74951, 2249, 75, 80}}},
         {51.25, 46.68, 415800, "Sulfur Sprint",
                                {NORMAL = {75035, 2251, 64, 67}}},
    }),

    Zone("Emerald Dream", 2200, {
         {62.79, 88.13, 426030, "Canopy Concours",
                                {NORMAL = {78102, 2680, 105, 110}}},
         {32.35, 48.26, 426031, "Emerald Amble",
                                {NORMAL = {78115, 2681, 84, 89}}},
         {69.61, 52.62, 426029, "Shoreline Switchback",
                                {NORMAL = {78016, 2679, 73, 78}}},
         {37.17, 44.08, 426027, "Smoldering Sprint",
                                {NORMAL = {77983, 2677, 80, 85}}},
         {35.15, 55.23, 426028, "Viridescent Venture",
                                {NORMAL = {77996, 2678, 78, 83}}},
         {59.10, 28.82, 426026, "Ysera Invitational",
                                {NORMAL = {77841, 2676, 98, 103}}},
    }),

    Zone("Northrend Cup", 113, {
         {72.69, 85.34, 432043, "Scalawag Slither",
                                {NORMAL   = {78301, 2720, 73, 78},
                                 ADVANCED = {78302, 2738, 68, 71},
                                 REVERSE  = {78303, 2756, 70, 73}}},
         {77.74, 79.39, 432044, "Daggercap Dart",
                                {NORMAL   = {78325, 2721, 77, 82},
                                 ADVANCED = {78326, 2739, 76, 79},
                                 REVERSE  = {78327, 2757, 76, 79}}},
         {70.17, 56.63, 432045, "Blackriver Burble",
                                {NORMAL   = {78334, 2722, 75, 80},
                                 ADVANCED = {78335, 2740, 67, 70},
                                 REVERSE  = {78336, 2758, 71, 74}}},
         {77.17, 31.95, 432054, "Gundrak Fast Track",
                                {NORMAL   = {79268, 2730, 60, 65},
                                 ADVANCED = {79269, 2748, 57, 60},
                                 REVERSE  = {79270, 2766, 57, 60}}},
         {65.63, 37.83, 432046, "Zul'Drak Zephyr",
                                {NORMAL   = {78346, 2723, 65, 70},
                                 ADVANCED = {78347, 2741, 62, 65},
                                 REVERSE  = {78349, 2759, 67, 70}}},  -- 7834"9" is not a typo!
         {59.79, 15.53, 432047, "Makers' Marathon",
                                {NORMAL   = {78389, 2724, 100, 105},
                                 ADVANCED = {78390, 2742, 93, 96},
                                 REVERSE  = {78391, 2760, 98, 101}}},
         {57.36, 46.87, 432048, "Crystalsong Crisis",
                                {NORMAL   = {78441, 2725, 97, 102},
                                 ADVANCED = {78442, 2743, 94, 97},
                                 REVERSE  = {78443, 2761, 96, 99}}},
         {51.125,47.57, 432049, "Dragonblight Dragon Flight",
                                {NORMAL   = {78454, 2726, 115, 120},
                                 ADVANCED = {78455, 2744, 110, 113},
                                 REVERSE  = {78456, 2762, 110, 113}}},
         {40.14, 43.67, 432050, "Citadel Sortie",
                                {NORMAL   = {78499, 2727, 110, 115},
                                 ADVANCED = {78500, 2745, 103, 106},
                                 REVERSE  = {78501, 2763, 104, 107}}},
         {33.39, 43.01, 432051, "Sholazar Spree",
                                {NORMAL   = {78558, 2728, 88, 93},
                                 ADVANCED = {78559, 2746, 85, 88},
                                 REVERSE  = {78560, 2764, 85, 88}}},
         {22.885,54.185,432052, "Geothermal Jaunt",
                                {NORMAL   = {78608, 2729, 45, 50},
                                 ADVANCED = {78609, 2747, 37, 40},
                                 REVERSE  = {78610, 2765, 37, 40}}},
         {16.215,56.74, 432055, "Coldarra Climb",
                                {NORMAL   = {79272, 2731, 57, 62},
                                 ADVANCED = {79273, 2749, 53, 56},
                                 REVERSE  = {79274, 2767, 55, 58}}},
    }),
}

------------------------------------------------------------------------

-- Return the data for the given race, or nil if not known.
local function GetRace(zone, race)
    for _, zone_data in ipairs(ZONES) do
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

-- Calls callback(zone) for each zone with races.
function RaceTimes.Data.EnumerateZones(callback)
    for _, zone in ipairs(ZONES) do
        callback(zone)
    end
end

-- Calls callback(zone, race) for each race.
function RaceTimes.Data.EnumerateRaces(callback)
    for _, zone in ipairs(ZONES) do
        for _, race in ipairs(zone.races) do
            callback(zone, race)
        end
    end
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
