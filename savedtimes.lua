local _, RaceTimes = ...
RaceTimes.SavedTimes = {}

local class = RaceTimes.class
local tinsert = tinsert


-------- Persistent data --------

-- List of saved times, indexed by "CharName-Server" and quest ID.
RaceTimes_saved_times = nil

-- Set of characters to be preserved across a reload.  Removing a
-- character from this set causes its data to be discarded the next
-- time the addon is loaded.
RaceTimes_saved_chars = nil


-------- Runtime-only data (not saved to persistent storage) --------

-- Name (in "CharName-Server" format) of the current character, or nil
-- if the name is unavailable (should never happen).
local player_name = nil

-- Best time across all characters for each race instance, indexed by
-- quest ID.
local best_time = {}

------------------------------------------------------------------------

function RaceTimes.SavedTimes.Init()
    RaceTimes_saved_chars = RaceTimes_saved_chars or {}
    RaceTimes_saved_times = RaceTimes_saved_times or {}

    for name, _ in pairs(RaceTimes_saved_times) do
        if not RaceTimes_saved_chars[name] then
            RaceTimes_saved_times[name] = nil
            RaceTimes_saved_chars[name] = nil
        end
    end

    local name = UnitNameUnmodified("player")
    local server = select(2, UnitFullName("player"))
    player_name = name.."-"..server
    local times = RaceTimes_saved_times[name] or {}
    for _, zone, race in RaceTimes.Data.EnumerateRaces() do
        for category, instance in race:EnumerateInstances() do
            local ci = C_CurrencyInfo.GetCurrencyInfo(instance.currency)
            local time = (ci and ci.quantity) or 0
            if time > 0 then
                local quest = instance.quest
                times[quest] = time
                best_time[quest] = time
            end
        end
    end
    RaceTimes_saved_times[player_name] = times
    RaceTimes_saved_chars[player_name] = true

    for name, times in pairs(RaceTimes_saved_times) do
        if name ~= player_name then
            for quest, time in pairs(times) do
                local best = best_time[quest]
                if not best or time < best then
                    best_time[quest] = time
                end
            end
        end
    end
end

-- Returns the best time across all saved characters for the given race
-- instance, or 0 if no time for the instance has been saved for any character.
function RaceTimes.SavedTimes.GetBestTime(instance)
    return best_time[instance.quest] or 0
end

-- Updates the current character's best time for the given race instance.
function RaceTimes.SavedTimes.UpdateTime(instance, time)
    assert(time > 0)
    if not player_name then return end

    local quest = instance.quest
    assert(not RaceTimes_saved_times[player_name][quest]
           or time <= RaceTimes_saved_times[player_name][quest])
    RaceTimes_saved_times[player_name][quest] = time
    if time < best_time[quest] then
        best_time[quest] = time
    end
end

-- Returns the list of saved characters, sorted lexically.
function RaceTimes.SavedTimes.GetSavedChars()
    local names = {}
    local i = 0
    for k, _ in pairs(RaceTimes_saved_chars) do tinsert(names, k) end
    table.sort(names)
    return names
end

-- Returns whether data for the given character will be saved.
function RaceTimes.SavedTimes.GetSaveChar(name)
    assert(name)
    assert(RaceTimes_saved_chars[name] ~= nil)
    return RaceTimes_saved_chars[name]
end

-- Sets whether to save data for the given character.
function RaceTimes.SavedTimes.SetSaveChar(name, save)
    assert(name)
    assert(RaceTimes_saved_chars[name] ~= nil)
    assert(save == true or save == false)
    RaceTimes_saved_chars[name] = save
end
