local _, RaceTimes = ...

local L = {}

local locale = GetLocale()  -- Assumed not to change at runtime.
RaceTimes._L = function(s)
    local t = L[s]
    return (t and t[locale]) or s
end

-- Frame header
L["Skyriding Race Times"] = {
    frFR = "Temps des Courses draconiques",
}

-- Category buttons
L["Normal"] = {
    frFR = "Normal",
}
L["Advanced"] = {
    frFR = "Avancé",
}
L["Challenge"] = {
    frFR = "Défi",
}
L["Storm"] = {  -- For the Storm Gryphon tutorial races in the Dragon Isles.
}
L["Reverse"] = {
    frFR = "Inversé",
}
L["R-Challenge"] = {  -- Abbreviation for "reverse challenge".
    frFR = "Défi inversé",
}

-- Time format for seconds (arguments: minutes, seconds)
L["%d:%02d"] = {
}
-- Time format for decimal separator and milliseconds (arguments: milliseconds)
L[".%03d"] = {
}

-- Tooltip gold/silver time headers.  A space is inserted between this
-- text and the relevant time.
L["Gold:"] = {
    frFR = "Or\194\160:",
}
L["Silver:"] = {
    frFR = "Argent\194\160:",
}

-- "Race Starting" aura name (spell 439233 etc, used to detect race start).
-- Note that we could also implement the aura name check by simply
-- comparing against that specific spell ID's name, but this provides a
-- good example of a fully localized string.
L["Race Starting"] = {
    deDE = "Rennstart",
    esES = "Comienzo de la carrera",
    esMX = "Inicio de carrera inminente",
    frFR = "Départ de la course",
    itIT = "Inizio della Corsa",
    koKR = "경주 시작",
    ptBR = "Início da Corrida",
    ruRU = "Начало гонки",
    zhCN = "竞速开始",
    zhTW = "比賽開始",
}

-- Settings section header for time display options
L["Time display settings"] = {
}

-- Checkbox option name and comment text
L["Show best time across all saved characters"] = {
}
L["When unchecked, the best time for the current character is shown."] = {
}

-- Settings section header and comments for character management
L["Saved character management"] = {
}
L["Unchecking a character causes that character's times to be deleted on the next login or UI reload."] = {
}
L["The logged-in character's times are always recorded."] = {
}

-- Settings section header and text for addon info
L["About RaceTimes"] = {
}
L["RaceTimes is a simple addon to record and display best times for each skyriding race, optionally across multiple characters."] = {
}
L["The best time list can be opened with the |cFFFFFF00/racetimes|r (or |cFFFFFF00/rt|r) command."] = {
}

-- Author and version strings for addon info.  A space is inserted between
-- each of these strings and the relevant text.
L["Author:"] = {
}
L["Version:"] = {
}
