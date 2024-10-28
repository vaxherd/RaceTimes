local _, RaceTimes = ...

local L = {}

local locale = GetLocale()  -- Assumed not to change at runtime.
RaceTimes._L = function(s)
    local t = L[s]
    return (t and t[locale]) or s
end

-- Frame header
L["Skyriding Race Times"] = {
}

-- Category buttons
L["Normal"] = {
}
L["Advanced"] = {
}
L["Challenge"] = {
}
L["Storm"] = {  -- For the Storm Gryphon tutorial races in the Dragon Isles.
}
L["Reverse"] = {
}
L["R-Challenge"] = {  -- Abbreviation for "reverse challenge".
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
}
L["Silver:"] = {
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
