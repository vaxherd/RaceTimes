local _, RaceTimes = ...
RaceTimes.Data = {}

local class = RaceTimes.class
local strlen = string.len
local strsub = string.sub

-- Category constants for race categories.
RaceTimes.Category = {
    NORMAL    = 1,  -- Normal race (always available)
    ADVANCED  = 2,  -- Advanced race
    REVERSE   = 3,  -- Reverse race
    CHALLENGE = 4,  -- Challenge race
    REV_CHALL = 5,  -- Reverse challenge race
    STORM     = 6,  -- Storm Gryphon race
}
local MAX_CATEGORY = 6

------------------------------------------------------------------------

-- Classes for storing race data.  Fields may be freely read by users.

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

-- Returns the localized name of the race as extracted from the race times
-- aura name, if possible; otherwise returns the default name passed to the
-- constructor.
function Race:GetLocalizedName()
    local function strip_prefix(s, prefix)
        local prefixlen = strlen(prefix)
        if strsub(s, 1, prefixlen) == prefix then
            return strsub(s, prefixlen+1)
        end
        return nil
    end
    local aura_name = C_Spell.GetSpellName(self.times_aura)
    return (strip_prefix(aura_name, "Race Times: ")
         or strip_prefix(aura_name, "Temps des courses\194\160: ")
         or self.name)
end

-- Returns the recorded best time for the given race and category, in
-- milliseconds, and the time rank (1 = gold, 2 = silver, 3 = bronze).
-- If use_saved is true, returns the best time across all saved characters
-- rather than just the current character.
-- Returns time 0 and rank 0 if no time has been recorded for the given
-- race and category.
-- Returns nil if the category is not available for that race (such as
-- Reverse for the free-order races).
function Race:GetTime(category, use_saved)
    local instance = self.instances[category]
    if not instance then return nil end
    local time
    if use_saved then
        time = RaceTimes.SavedTimes.GetBestTime(instance)
    else
        local ci = C_CurrencyInfo.GetCurrencyInfo(instance.currency)
        time = (ci and ci.quantity) or 0
    end
    local rank = (time == 0 and 0 or
                  time <= instance.gold and 1 or
                  time <= instance.silver and 2 or 3)
    return time, rank
end

-- Enumerator function for Race:EnumerateInstances().
local function InstanceEnumerator(race, index)
    index = index + 1
    if index > MAX_CATEGORY then return nil end
    if race.instances[index] then return index, race.instances[index] end
    return InstanceEnumerator(race, index)
end

-- Enumerates all instances of the given race.  Intended for use as a
-- generic for iterator.  Iteration returns two values: the numeric
-- category ID (a RaceTimes.Category enumerator) and the instance itself.
function Race:EnumerateInstances()
    return InstanceEnumerator, self, 0
end


local Zone = class()
function Zone:__constructor(name, map_id, race_list)
    self.name = name
    self.map_id = map_id
    self.races = {}
    for _, race_data in ipairs(race_list) do
        local map_x, map_y, times_aura, race_name, category_list =
            unpack(race_data)
        local waypoint =
            UiMapPoint.CreateFromCoordinates(map_id, map_x/100, map_y/100)
        local instances = {}
        for category, data in pairs(category_list) do
            instances[RaceTimes.Category[category]] = RaceInstance(unpack(data))
        end
        tinsert(self.races, Race(race_name, waypoint, times_aura, instances))
    end
end

-- Returns the localized name of the zone, if possible; otherwise returns
-- the default name passed to the constructor.
function Zone:GetLocalizedName()
    local info = C_Map.GetMapInfo(self.map_id)
    return ((info and info.name) or self.name)
end


-- Ordered list of all known races, broken down by zone.
-- We don't currently make use of the aura or quest IDs, but we
-- save them for future reference just in case they become useful.

local ZONES = {
    Zone("The Waking Shores", 2022, {
         {23.283,84.258,415640, "Apex Canopy River Run",
                                {NORMAL    = {66732, 2054, 52, 55},
                                 ADVANCED  = {66733, 2055, 45, 50},
                                 REVERSE   = {72734, 2178, 48, 53},
                                 CHALLENGE = {75782, 2427, 53, 56},
                                 REV_CHALL = {75783, 2428, 53, 56}}},
         {41.959,67.358,415639, "Emberflow Flight",
                                {NORMAL    = {66727, 2052, 50, 53},
                                 ADVANCED  = {66728, 2053, 44, 49},
                                 REVERSE   = {72707, 2177, 45, 50},
                                 CHALLENGE = {75780, 2425, 50, 53},
                                 REV_CHALL = {75781, 2426, 51, 54}}},
         {62.766,73.954,415643, "Flashfrost Flyover",
                                {NORMAL    = {66710, 2046, 63, 66},
                                 ADVANCED  = {66712, 2047, 61, 66},
                                 REVERSE   = {72700, 2181, 60, 65},
                                 CHALLENGE = {75789, 2433, 64, 67},
                                 REV_CHALL = {75790, 2434, 69, 74}}},
         {63.280,70.853,415541, "Ruby Lifeshrine Loop",
                                {NORMAL    = {66679, 2042, 53, 56},
                                 ADVANCED  = {66692, 2044, 52, 57},
                                 REVERSE   = {72052, 2154, 50, 55},
                                 CHALLENGE = {75776, 2421, 54, 57},
                                 REV_CHALL = {75777, 2422, 57, 60},
                                 STORM     = {77777, 2664, 65, 70}}},--Jackpot!
         {55.433,41.199,415641, "Uktulut Coaster",
                                {NORMAL    = {66777, 2056, 45, 48},
                                 ADVANCED  = {66778, 2057, 40, 45},
                                 REVERSE   = {72739, 2179, 43, 48},
                                 CHALLENGE = {75785, 2429, 46, 49},
                                 REV_CHALL = {75786, 2430, 48, 51}}},
         {42.619,94.527,415644, "Wild Preserve Circuit",
                                {NORMAL    = {66725, 2050, 40, 43},
                                 ADVANCED  = {66726, 2051, 38, 43},
                                 REVERSE   = {72706, 2182, 41, 46},
                                 CHALLENGE = {75791, 2435, 43, 46},
                                 REV_CHALL = {75792, 2436, 44, 47}}},
         {47.044,85.545,415638, "Wild Preserve Slalom",
                                {NORMAL    = {66721, 2048, 42, 45},
                                 ADVANCED  = {66722, 2049, 40, 45},
                                 REVERSE   = {72705, 2176, 41, 46},
                                 CHALLENGE = {75778, 2423, 48, 51},
                                 REV_CHALL = {75779, 2424, 49, 52}}},
         {73.176,33.993,415642, "Wingrest Roundabout",
                                {NORMAL    = {66786, 2058, 53, 56},
                                 ADVANCED  = {66787, 2059, 53, 58},
                                 REVERSE   = {72740, 2180, 56, 61},
                                 CHALLENGE = {75787, 2431, 60, 63},
                                 REV_CHALL = {75788, 2432, 60, 63}}},
    }),

    Zone("Ohn'ahran Plains", 2023, {
         {25.749,55.053,415654, "Emerald Garden Ascent",
                                {NORMAL    = {66885, 2066, 63, 66},
                                 ADVANCED  = {66886, 2067, 55, 60},
                                 REVERSE   = {72805, 2186, 57, 62},
                                 CHALLENGE = {75799, 2444, 66, 69},
                                 REV_CHALL = {75800, 2445, 66, 69}}},
         {86.244,35.774,415652, "Fen Flythrough",
                                {NORMAL    = {66877, 2062, 48, 51},
                                 ADVANCED  = {66878, 2063, 41, 46},
                                 REVERSE   = {72802, 2184, 47, 52},
                                 CHALLENGE = {75795, 2440, 50, 53},
                                 REV_CHALL = {75796, 2441, 50, 53},
                                 STORM     = {77785, 2665, 82, 87}}},
         {59.958,35.546,415656, "Maruukai Dash",
                                {NORMAL    = {66921, 2069, 25, 28},
                                 CHALLENGE = {75801, 2446, 24, 27}}},
         {47.437,70.648,415657, "Mirror of the Sky Dash",
                                {NORMAL    = {66933, 2070, 26, 29},
                                 CHALLENGE = {75802, 2447, 27, 30}}},
         {80.904,72.127,415653, "Ravine River Run",
                                {NORMAL    = {66880, 2064, 49, 52},
                                 ADVANCED  = {66681, 2065, 47, 52},
                                 REVERSE   = {72803, 2185, 46, 51},
                                 CHALLENGE = {75797, 2442, 50, 53},
                                 REV_CHALL = {75798, 2443, 51, 54}}},
         {43.799,66.812,415658, "River Rapids Route",
                                {NORMAL    = {70710, 2119, 48, 51},
                                 ADVANCED  = {70711, 2120, 43, 48},
                                 REVERSE   = {72807, 2187, 44, 49},
                                 CHALLENGE = {75803, 2448, 52, 55},
                                 REV_CHALL = {75804, 2449, 52, 55}}},
         {63.788,30.526,415650, "Sundapple Copse Circuit",
                                {NORMAL    = {66835, 2060, 49, 52},
                                 ADVANCED  = {66836, 2061, 41, 46},
                                 REVERSE   = {72801, 2183, 45, 50},
                                 CHALLENGE = {75793, 2437, 51, 54},
                                 REV_CHALL = {75794, 2439, 50, 53}}},
    }),

    Zone("Azure Span", 2024, {
         {42.234,56.770,415664, "Archive Ambit",
                                {NORMAL    = {67741, 2089, 91, 94},
                                 ADVANCED  = {67742, 2090, 81, 86},
                                 REVERSE   = {72797, 2193, 76, 81},
                                 CHALLENGE = {75816, 2460, 90, 93},
                                 REV_CHALL = {75817, 2461, 92, 95}}},
         {20.922,22.594,415660, "Azure Span Slalom",
                                {NORMAL    = {67002, 2076, 58, 61},
                                 ADVANCED  = {67003, 2077, 56, 61},
                                 REVERSE   = {72799, 2189, 53, 58},
                                 CHALLENGE = {75807, 2452, 55, 58},
                                 REV_CHALL = {75808, 2453, 55, 58}}},
         {47.893,40.806,415659, "Azure Span Sprint",
                                {NORMAL    = {66946, 2074, 63, 66},
                                 ADVANCED  = {66947, 2075, 58, 63},
                                 REVERSE   = {72796, 2188, 60, 65},
                                 CHALLENGE = {75805, 2450, 67, 70},
                                 REV_CHALL = {75806, 2451, 69, 72}}},
         {48.451,35.734,415663, "Frostland Flyover",
                                {NORMAL    = {67565, 2085, 76, 79},
                                 ADVANCED  = {67566, 2086, 72, 77},
                                 REVERSE   = {72795, 2192, 69, 74},
                                 CHALLENGE = {75813, 2458, 85, 88},
                                 REV_CHALL = {75815, 2459, 83, 86}}},
         {16.553,49.319,415662, "Iskaara Tour",
                                {NORMAL    = {67296, 2083, 75, 78},
                                 ADVANCED  = {67297, 2084, 70, 75},
                                 REVERSE   = {72800, 2191, 67, 72},
                                 CHALLENGE = {75811, 2456, 78, 81},
                                 REV_CHALL = {75812, 2457, 79, 82}}},
         {71.312,24.662,415661, "Vakthros Ascent",
                                {NORMAL    = {67031, 2078, 58, 61},
                                 ADVANCED  = {67031, 2079, 56, 61},
                                 REVERSE   = {72794, 2190, 56, 61},
                                 CHALLENGE = {75809, 2454, 63, 66},
                                 REV_CHALL = {75810, 2455, 64, 67},
                                 STORM     = {77786, 2666, 120, 125}}},
    }),

    Zone("Thaldraszus", 2025, {
         {60.278,41.765,415669, "Academy Ascent",
                                {NORMAL    = {70059, 2098, 54, 57},
                                 ADVANCED  = {70060, 2099, 52, 57},
                                 REVERSE   = {72754, 2197, 53, 58},
                                 CHALLENGE = {75826, 2468, 65, 68},
                                 REV_CHALL = {75827, 2469, 65, 68}}},
         {58.043,33.668,415671, "Caverns Criss-Cross",
                                {NORMAL    = {70161, 2103, 50, 53},
                                 ADVANCED  = {70163, 2104, 45, 50},
                                 REVERSE   = {72750, 2199, 47, 52},
                                 CHALLENGE = {75829, 2472, 56, 59},
                                 REV_CHALL = {75830, 2473, 54, 57}}},
         {37.673,48.974,415668, "Cliffside Circuit",
                                {NORMAL    = {70051, 2096, 69, 72},
                                 ADVANCED  = {70052, 2097, 66, 71},
                                 REVERSE   = {72760, 2196, 69, 74},
                                 CHALLENGE = {75824, 2466, 81, 84},
                                 REV_CHALL = {75825, 2467, 80, 83}}},
         {57.742,74.995,415665, "Flowing Forest Flight",
                                {NORMAL    = {67095, 2080, 49, 52},
                                 ADVANCED  = {67096, 2081, 40, 45},
                                 REVERSE   = {72793, 2194, 41, 46},
                                 CHALLENGE = {75820, 2462, 47, 50},
                                 REV_CHALL = {75821, 2463, 46, 49}}},
         {39.486,76.220,415670, "Garden Gallivant",
                                {NORMAL    = {70157, 2101, 61, 64},
                                 ADVANCED  = {70158, 2102, 54, 59},
                                 REVERSE   = {72769, 2198, 57, 62},
                                 CHALLENGE = {75784, 2470, 60, 63},
                                 REV_CHALL = {75828, 2471, 64, 67}}},
         {57.251,66.853,415666, "Tyrhold Trial",
                                {NORMAL    = {69957, 2092, 81, 84},
                                 ADVANCED  = {69958, 2093, 75, 80},
                                 REVERSE   = {72792, 2195, 59, 64},
                                 CHALLENGE = {75822, 2464, 58, 61},
                                 REV_CHALL = {75823, 2465, 63, 66},
                                 STORM     = {77784, 2667, 80, 85}}},
    }),

    Zone("Forbidden Reach", 2151, {
         {63.154,51.676,415791, "Aerie Chasm Cruise",
                                {NORMAL    = {73025, 2203, 53, 56},
                                 ADVANCED  = {73027, 2209, 50, 55},
                                 REVERSE   = {73028, 2215, 50, 55},
                                 CHALLENGE = {75958, 2478, 53, 56},
                                 REV_CHALL = {75959, 2479, 52, 55}}},
         {41.401,14.672,415793, "Caldera Coaster",
                                {NORMAL    = {73033, 2205, 58, 61},
                                 ADVANCED  = {73034, 2211, 52, 57},
                                 REVERSE   = {73052, 2217, 49, 54},
                                 CHALLENGE = {75962, 2482, 55, 58},
                                 REV_CHALL = {75963, 2483, 53, 56}}},
         {49.463,59.955,415794, "Forbidden Reach Rush",
                                {NORMAL    = {73061, 2206, 59, 62},
                                 ADVANCED  = {73062, 2212, 56, 61},
                                 REVERSE   = {73065, 2218, 57, 62},
                                 CHALLENGE = {75964, 2484, 60, 63},
                                 REV_CHALL = {75965, 2485, 60, 63}}},
         {31.353,65.882,415790, "Morqut Ascent",
                                {NORMAL    = {73020, 2202, 52, 55},
                                 ADVANCED  = {73023, 2208, 49, 54},
                                 REVERSE   = {73024, 2214, 52, 57},
                                 CHALLENGE = {75956, 2476, 50, 53},
                                 REV_CHALL = {75957, 2477, 50, 53}}},
         {63.610,84.316,415792, "Southern Reach Route",
                                {NORMAL    = {73029, 2204, 70, 73},
                                 ADVANCED  = {73030, 2210, 68, 73},
                                 REVERSE   = {73032, 2216, 63, 68},
                                 CHALLENGE = {75960, 2480, 70, 73},
                                 REV_CHALL = {75961, 2481, 68, 71}}},
         {76.190,65.740,415789, "Stormsunder Crater Circuit",
                                {NORMAL    = {73017, 2201, 43, 46},
                                 ADVANCED  = {73018, 2207, 42, 47},
                                 REVERSE   = {73019, 2213, 42, 47},
                                 CHALLENGE = {75954, 2474, 45, 48},
                                 REV_CHALL = {75955, 2475, 44, 47},
                                 STORM     = {77787, 2668, 92, 97}}},
    }),

    Zone("Zaralek Cavern", 2133, {
         {54.506,23.739,415797, "Brimstone Scramble",
                                {NORMAL    = {74939, 2248, 69, 72},
                                 ADVANCED  = {74943, 2254, 64, 69},
                                 REVERSE   = {74944, 2260, 64, 69},
                                 CHALLENGE = {75976, 2490, 69, 72},
                                 REV_CHALL = {75977, 2491, 71, 74}}},
         {39.086,49.889,415796, "Caldera Cruise",
                                {NORMAL    = {74889, 2247, 75, 80},
                                 ADVANCED  = {74899, 2253, 68, 73},
                                 REVERSE   = {74925, 2259, 68, 73},
                                 CHALLENGE = {75974, 2488, 72, 75},
                                 REV_CHALL = {75975, 2489, 72, 75}}},
         {38.740,60.577,415795, "Crystal Circuit",
                                {NORMAL    = {74839, 2246, 63, 68},
                                 ADVANCED  = {74842, 2252, 55, 60},
                                 REVERSE   = {74882, 2258, 53, 58},
                                 CHALLENGE = {75972, 2486, 57, 60},
                                 REV_CHALL = {75973, 2487, 58, 61},
                                 STORM     = {77793, 2669, 95, 100}}},
         {58.062,57.517,415799, "Loamm Roamm",
                                {NORMAL    = {74972, 2250, 55, 60},
                                 ADVANCED  = {74975, 2256, 50, 55},
                                 REVERSE   = {74977, 2262, 48, 53},
                                 CHALLENGE = {75980, 2494, 53, 56},
                                 REV_CHALL = {75981, 2495, 52, 55}}},
         {58.695,45.040,415798, "Shimmering Slalom",
                                {NORMAL    = {74951, 2249, 75, 80},
                                 ADVANCED  = {74954, 2255, 70, 75},
                                 REVERSE   = {74956, 2261, 70, 75},
                                 CHALLENGE = {75978, 2492, 79, 82},
                                 REV_CHALL = {75979, 2493, 75, 78}}},
         {51.244,46.646,415800, "Sulfur Sprint",
                                {NORMAL    = {75035, 2251, 64, 67},
                                 ADVANCED  = {75042, 2257, 58, 63},
                                 REVERSE   = {75043, 2263, 57, 62},
                                 CHALLENGE = {75982, 2496, 67, 70},
                                 REV_CHALL = {75983, 2497, 65, 68}}},
    }),

    Zone("Emerald Dream", 2200, {
         {62.799,88.118,426030, "Canopy Concours",
                                {NORMAL    = {78102, 2680, 105, 110},
                                 ADVANCED  = {78103, 2686, 93, 96},
                                 REVERSE   = {78104, 2692, 96, 99},
                                 CHALLENGE = {78105, 2702, 105, 108},
                                 REV_CHALL = {78106, 2703, 105, 108}}},
         {32.345,48.193,426031, "Emerald Amble",
                                {NORMAL    = {78115, 2681, 84, 89},
                                 ADVANCED  = {78116, 2687, 70, 73},
                                 REVERSE   = {78117, 2693, 70, 73},
                                 CHALLENGE = {78118, 2704, 73, 76},
                                 REV_CHALL = {78119, 2705, 73, 76}}},
         {69.618,52.619,426029, "Shoreline Switchback",
                                {NORMAL    = {78016, 2679, 73, 78},
                                 ADVANCED  = {78017, 2685, 63, 66},
                                 REVERSE   = {78018, 2691, 62, 65},
                                 CHALLENGE = {78019, 2700, 70, 73},
                                 REV_CHALL = {78020, 2701, 70, 73}}},
         {37.177,44.078,426027, "Smoldering Sprint",
                                {NORMAL    = {77983, 2677, 80, 85},
                                 ADVANCED  = {77984, 2683, 73, 76},
                                 REVERSE   = {77985, 2689, 73, 76},
                                 CHALLENGE = {77986, 2696, 79, 82},
                                 REV_CHALL = {77987, 2697, 80, 83}}},
         {35.156,55.222,426028, "Viridescent Venture",
                                {NORMAL    = {77996, 2678, 78, 83},
                                 ADVANCED  = {77997, 2684, 64, 67},
                                 REVERSE   = {77998, 2690, 64, 67},
                                 CHALLENGE = {77999, 2698, 73, 76},
                                 REV_CHALL = {78000, 2699, 73, 76}}},
         {59.109,28.812,426026, "Ysera Invitational",
                                {NORMAL    = {77841, 2676, 98, 103},
                                 ADVANCED  = {77842, 2682, 87, 90},
                                 REVERSE   = {77843, 2688, 87, 90},
                                 CHALLENGE = {77844, 2694, 95, 98},
                                 REV_CHALL = {77845, 2695, 97, 100}}},
    }),

    Zone("Kalimdor", 12, {
         {51.078,22.454,415866, "Felwood Flyover",
                                {NORMAL    = {75277, 2312, 70, 75},
                                 ADVANCED  = {75293, 2342, 63, 66},
                                 REVERSE   = {75294, 2372, 62, 65}}},
         {60.573,25.704,415867, "Winter Wander",
                                {NORMAL    = {75310, 2313, 80, 85},
                                 ADVANCED  = {75311, 2343, 73, 76},
                                 REVERSE   = {75312, 2373, 70, 73}}},
         {55.444,28.147,415868, "Nordrassil Spiral",
                                {NORMAL    = {75317, 2314, 45, 50},
                                 ADVANCED  = {75318, 2344, 41, 46},
                                 REVERSE   = {75319, 2374, 41, 46}}},
         {51.436,31.186,415869, "Hyjal Hotfoot",
                                {NORMAL    = {75330, 2315, 70, 75},
                                 ADVANCED  = {75331, 2345, 69, 72},
                                 REVERSE   = {75332, 2375, 67, 72}}},
         {65.612,32.161,415870, "Rocketway Ride",  -- Listed in the Kalimdor Cup quest objectives as "The Aszhara Rocketway Ride", but the best times aura name is just "Rocketway Ride".
                                {NORMAL    = {75347, 2316,101,106},
                                 ADVANCED  = {75355, 2346, 94,100},
                                 REVERSE   = {75356, 2376, 94,100}}},
         {47.560,35.914,415871, "Ashenvale Ambit",
                                {NORMAL    = {75378, 2317, 64, 69},
                                 ADVANCED  = {75379, 2347, 59, 64},
                                 REVERSE   = {75380, 2377, 59, 64}}},
         {59.886,51.833,415872, "Durotar Tour",
                                {NORMAL    = {75385, 2318, 82, 87},
                                 ADVANCED  = {75386, 2348, 75, 80},
                                 REVERSE   = {75387, 2378, 75, 80}}},
         {46.478,50.215,415873, "Webwinder Weave",
                                {NORMAL    = {75394, 2319, 80, 85},
                                 ADVANCED  = {75395, 2349, 73, 78},
                                 REVERSE   = {75396, 2379, 70, 75}}},
         {38.305,56.063,415874, "Desolace Drift",
                                {NORMAL    = {75409, 2320, 78, 83},
                                 ADVANCED  = {75410, 2350, 70, 75},
                                 REVERSE   = {75411, 2380, 71, 76}}},
         {51.040,51.962,415875, "Great Divide Dive",
                                {NORMAL    = {75412, 2321, 48, 53},
                                 ADVANCED  = {75413, 2351, 43, 48},
                                 REVERSE   = {75414, 2381, 44, 49}}},
         {51.314,68.089,415876, "Razorfen Roundabout",
                                {NORMAL    = {75437, 2322, 53, 58},
                                 ADVANCED  = {75438, 2352, 47, 52},
                                 REVERSE   = {75439, 2382, 48, 53}}},
         {48.717,68.415,415877, "Thousand Needles Thread",
                                {NORMAL    = {75463, 2323, 87, 92},
                                 ADVANCED  = {75464, 2353, 77, 82},
                                 REVERSE   = {75465, 2383, 77, 82}}},
         {43.700,70.088,415878, "Feralas Ruins Ramble",
                                {NORMAL    = {75468, 2324, 89, 94},
                                 ADVANCED  = {75469, 2354, 84, 89},
                                 REVERSE   = {75470, 2384, 84, 89}}},
         {42.629,83.398,415879, "Ahn'Qiraj Circuit",
                                {NORMAL    = {75472, 2325, 77, 82},
                                 ADVANCED  = {75473, 2355, 68, 73},
                                 REVERSE   = {75474, 2385, 69, 74}}},
         {49.129,90.001,415880, "Uldum Tour",
                                {NORMAL    = {75481, 2326, 84, 89},
                                 ADVANCED  = {75482, 2356, 76, 81},
                                 REVERSE   = {75483, 2386, 76, 81}}},
         {50.293,83.854,415881, "Un'Goro Crater Circuit",
                                {NORMAL    = {75485, 2327,100,105},
                                 ADVANCED  = {75486, 2357, 90, 95},
                                 REVERSE   = {75487, 2387, 92, 97}}},
    }),

    Zone("Northrend", 113, {
         {72.69, 85.34, 432043, "Scalawag Slither",
                                {NORMAL    = {78301, 2720, 73, 78},
                                 ADVANCED  = {78302, 2738, 68, 71},
                                 REVERSE   = {78303, 2756, 70, 73}}},
         {77.74, 79.39, 432044, "Daggercap Dart",
                                {NORMAL    = {78325, 2721, 77, 82},
                                 ADVANCED  = {78326, 2739, 76, 79},
                                 REVERSE   = {78327, 2757, 76, 79}}},
         {70.17, 56.63, 432045, "Blackriver Burble",
                                {NORMAL    = {78334, 2722, 75, 80},
                                 ADVANCED  = {78335, 2740, 67, 70},
                                 REVERSE   = {78336, 2758, 71, 74}}},
         {77.17, 31.95, 432054, "Gundrak Fast Track",
                                {NORMAL    = {79268, 2730, 60, 65},
                                 ADVANCED  = {79269, 2748, 57, 60},
                                 REVERSE   = {79270, 2766, 57, 60}}},
         {65.63, 37.83, 432046, "Zul'Drak Zephyr",
                                {NORMAL    = {78346, 2723, 65, 70},
                                 ADVANCED  = {78347, 2741, 62, 65},
                                 REVERSE   = {78349, 2759, 67, 70}}},  -- 7834"9" is not a typo!  78348 apparently got skipped.
         {59.79, 15.53, 432047, "Makers' Marathon",
                                {NORMAL    = {78389, 2724, 100, 105},
                                 ADVANCED  = {78390, 2742, 93, 96},
                                 REVERSE   = {78391, 2760, 98, 101}}},
         {57.36, 46.87, 432048, "Crystalsong Crisis",
                                {NORMAL    = {78441, 2725, 97, 102},
                                 ADVANCED  = {78442, 2743, 94, 97},
                                 REVERSE   = {78443, 2761, 96, 99}}},
         {51.125,47.57, 432049, "Dragonblight Dragon Flight",
                                {NORMAL    = {78454, 2726, 115, 120},
                                 ADVANCED  = {78455, 2744, 110, 113},
                                 REVERSE   = {78456, 2762, 110, 113}}},
         {40.14, 43.67, 432050, "Citadel Sortie",
                                {NORMAL    = {78499, 2727, 110, 115},
                                 ADVANCED  = {78500, 2745, 103, 106},
                                 REVERSE   = {78501, 2763, 104, 107}}},
         {33.39, 43.01, 432051, "Sholazar Spree",
                                {NORMAL    = {78558, 2728, 88, 93},
                                 ADVANCED  = {78559, 2746, 85, 88},
                                 REVERSE   = {78560, 2764, 85, 88}}},
         {22.885,54.185,432052, "Geothermal Jaunt",
                                {NORMAL    = {78608, 2729, 45, 50},
                                 ADVANCED  = {78609, 2747, 37, 40},
                                 REVERSE   = {78610, 2765, 37, 40}}},
         {16.215,56.74, 432055, "Coldarra Climb",
                                {NORMAL    = {79272, 2731, 57, 62},
                                 ADVANCED  = {79273, 2749, 53, 56},
                                 REVERSE   = {79274, 2767, 55, 58}}},
    }),

    Zone("Isle of Dorn", 2248, {
         {48.089,35.183,444141, "Dornogal Drift",
                                {NORMAL    = {80219, 2923, 48, 53},
                                 ADVANCED  = {80225, 2929, 43, 46},
                                 REVERSE   = {80231, 2935, 43, 46}}},
         {38.651,43.548,444142, "Storm Watch's Survey",
                                {NORMAL    = {80220, 2924, 63, 68},
                                 ADVANCED  = {80226, 2930, 60, 63},
                                 REVERSE   = {80232, 2936, 62, 65}}},
         {53.470,64.237,444143, "Basin Bypass",
                                {NORMAL    = {80221, 2925, 58, 63},
                                 ADVANCED  = {80227, 2931, 54, 57},
                                 REVERSE   = {80233, 2937, 57, 60}}},
         {62.154,46.028,444144, "The Wold Ways",
                                {NORMAL    = {80222, 2926, 68, 73},
                                 ADVANCED  = {80228, 2932, 68, 71},
                                 REVERSE   = {80234, 2938, 70, 73}}},
         {58.322,24.832,444146, "Thunderhead Trail",
                                {NORMAL    = {80223, 2927, 70, 75},
                                 ADVANCED  = {80229, 2933, 66, 69},
                                 REVERSE   = {80235, 2939, 66, 69}}},
         {32.935,74.805,444147, "Orecreg's Doglegs",
                                {NORMAL    = {80224, 2928, 65, 70},
                                 ADVANCED  = {80230, 2934, 61, 64},
                                 REVERSE   = {80236, 2940, 61, 64}}},
    }),

    Zone("The Ringing Deeps", 2214, {
         {40.882,11.293,444148, "Earthenworks Weave",
                                {NORMAL    = {80237, 2941, 52, 57},
                                 ADVANCED  = {80244, 2947, 49, 52},
                                 REVERSE   = {80250, 2953, 50, 53}}},
         {42.255,27.428,444149, "Ringing Deeps Ramble",
                                {NORMAL    = {80238, 2942, 57, 62},
                                 ADVANCED  = {80245, 2948, 53, 56},
                                 REVERSE   = {80251, 2954, 53, 56}}},
         {67.894,34.831,444150, "Chittering Concourse",
                                {NORMAL    = {80239, 2943, 56, 61},
                                 ADVANCED  = {80246, 2949, 53, 56},
                                 REVERSE   = {80252, 2955, 54, 57}}},
         {52.461,46.884,444151, "Cataract River Cruise",
                                {NORMAL    = {80240, 2944, 60, 65},
                                 ADVANCED  = {80247, 2950, 58, 61},
                                 REVERSE   = {80253, 2956, 57, 60}}},
         {66.570,68.651,444152, "Taelloch Twist",
                                {NORMAL    = {80242, 2945, 47, 52},
                                 ADVANCED  = {80248, 2951, 43, 46},
                                 REVERSE   = {80254, 2957, 44, 47}}},
         {63.536,75.145,444154, "Opportunity Point Amble",
                                {NORMAL    = {80243, 2946, 77, 82},
                                 ADVANCED  = {80249, 2952, 71, 74},
                                 REVERSE   = {80255, 2958, 72, 75}}},
    }),

    Zone("Hallowfall", 2215, {
         {72.762,38.414,444155, "Dunelle's Detour",
                                {NORMAL    = {80256, 2959, 65, 70},
                                 ADVANCED  = {80265, 2965, 62, 65},
                                 REVERSE   = {80271, 2971, 64, 67}}},
         {59.209,68.939,444156, "Tenir's Traversal",
                                {NORMAL    = {80257, 2960, 65, 70},
                                 ADVANCED  = {80266, 2966, 60, 63},
                                 REVERSE   = {80272, 2972, 63, 66}}},
         {41.423,67.198,444157, "Light's Redoubt Descent",
                                {NORMAL    = {80258, 2961, 63, 68},
                                 ADVANCED  = {80267, 2967, 62, 65},
                                 REVERSE   = {80273, 2973, 62, 65}}},
         {60.420,26.017,444158, "Stillstone Slalom",
                                {NORMAL    = {80259, 2962, 56, 61},
                                 ADVANCED  = {80268, 2968, 54, 57},
                                 REVERSE   = {80274, 2974, 56, 59}}},
         {38.983,61.334,444159, "Mereldar Meander",
                                {NORMAL    = {80260, 2963, 76, 81},
                                 ADVANCED  = {80269, 2969, 71, 74},
                                 REVERSE   = {80275, 2975, 71, 74}}},
         {54.123,17.394,444161, "Velhan's Venture",
                                {NORMAL    = {80261, 2964, 55, 60},
                                 ADVANCED  = {80270, 2970, 50, 53},
                                 REVERSE   = {80276, 2976, 50, 53}}},
    }),

    Zone("Azj-Kahet", 2255, {
         {40.774,67.792,444162, "City of Threads Twist",
                                {NORMAL    = {80277, 2977, 78, 83},
                                 ADVANCED  = {80283, 2983, 74, 77},
                                 REVERSE   = {80289, 2989, 74, 77}}},
         {77.900,79.681,444163, "Maddening Deep Dip",
                                {NORMAL    = {80278, 2978, 58, 63},
                                 ADVANCED  = {80284, 2984, 54, 57},
                                 REVERSE   = {80290, 2990, 56, 59}}},
         {52.932,36.212,444164, "The Weaver's Wing",
                                {NORMAL    = {80279, 2979, 54, 59},
                                 ADVANCED  = {80285, 2985, 51, 54},
                                 REVERSE   = {80291, 2991, 50, 53}}},
         {71.380,36.404,444167, "Rak-Ahat Rush",
                                {NORMAL    = {80280, 2980, 70, 75},
                                 ADVANCED  = {80286, 2986, 66, 69},
                                 REVERSE   = {80292, 2992, 66, 69}}},
         {23.831,48.369,444168, "Pit Plunge",
                                {NORMAL    = {80281, 2981, 63, 68},
                                 ADVANCED  = {80287, 2987, 61, 64},
                                 REVERSE   = {80293, 2993, 61, 64}}},
         {40.203,32.189,444169, "Siegehold Scuttle",
                                {NORMAL    = {80282, 2982, 70, 75},
                                 ADVANCED  = {80288, 2988, 66, 69},
                                 REVERSE   = {80294, 2994, 63, 66}}},
    }),

    Zone("Undermine", 2346, {
         {39.04, 28.68, 466683, "Skyrocketing Sprint",
                                {NORMAL    = {85071, 3119, 32, 42},
                                 REVERSE   = {85096, 3121, 32, 42}}},
         {33.77, 76.24, 466684, "The Heaps Leap",
                                {NORMAL    = {85097, 3122, 33, 43},
                                 REVERSE   = {85098, 3123, 33, 43}}},
         {39.22, 11.36, 466685, "Scrapshop Shot",
                                {NORMAL    = {85099, 3124, 36, 46},
                                 REVERSE   = {85100, 3125, 36, 46}}},
         {25.49, 42.12, 466686, "Rags to Riches Rush",
                                {NORMAL    = {85101, 3126, 40, 50},
                                 REVERSE   = {85102, 3127, 40, 50}}},
    }),
}

------------------------------------------------------------------------

-- Returns the data for the given race, or nil if not known.
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

-- Enumerator for RaceTimes.Data.EnumerateRaces().
local function AllRacesEnumerator(_, state)
    if not state then
        state = {1, 0}
    end
    local i_zone, i_race = unpack(state)
    local zone = ZONES[i_zone]
    if i_race >= #zone.races then
        i_zone = i_zone + 1
        zone = ZONES[i_zone]
        if not zone then
            return nil
        end
        i_race = 0
    end
    i_race = i_race + 1
    return {i_zone,i_race}, zone, zone.races[i_race]
end

------------------------------------------------------------------------

-- Enumerates all zones.  Intended for use as a generic for iterator.
-- Iteration returns two values, an iterator and the actual zone object
-- (like ipairs()).
function RaceTimes.Data.EnumerateZones()
    return ipairs(ZONES)
end

-- Enumerates all races.  Intended for use as a generic for iterator.
-- Iteration returns three values: an iterator (like ipairs()), the zone
-- object, and the race object.
-- Races for a single zone can be enumerated with ipairs(zone.races).
function RaceTimes.Data.EnumerateRaces()
    return AllRacesEnumerator, nil, nil
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
