local _, RaceTimes = ...
RaceTimes.SlashCmd = {}

local strfind = string.find
local strstr = function(s1,s2,pos) return strfind(s1,s2,pos,true) end
local strsub = string.sub

SlashCmdHelp = SlashCmdHelp or {}

------------------------------------------------------------------------

-- Convenience function to list all races in a map.
local function DumpRaces(map)
    local races = C_AreaPoiInfo.GetDragonridingRacesForMap(map) or {}
    for _,race in ipairs(races) do
        local poi = C_AreaPoiInfo.GetAreaPOIInfo(map, race)
        print(string.format("%.3f %.3f %s",
                            poi.position.x*100, poi.position.y*100, poi.name))
    end
end

function RaceTimes.SlashCmd.Init()
    SLASH_RACETIMES1 = "/racetimes"
    SLASH_RACETIMES2 = "/rt"
    SlashCmdHelp["RACETIMES"] = {
        args = "[|cFFFFFF00recenter|r || |cFFFFFF00settings|r]",
        help = {"Opens the dragon racing personal best time list.",
                'With the "recenter" subcommand, also moves the window back to the center of the screen.',
                'With the "settings" subcommand, instead opens the addon settings window.'},
    }
    SlashCmdList["RACETIMES"] = function(arg)
        arg = arg or ""
        local space = strstr(arg, " ") or #arg+1
        local subcommand = strsub(arg, 1, space-1)
        arg = strsub(arg, space+1)
        if subcommand == "" then
            RaceTimes.UI.Open()
        elseif subcommand == "recenter" then
            RaceTimes.UI.Recenter()
            RaceTimes.UI.Open()
        elseif subcommand == "settings" then
            RaceTimes.Settings.Open()
        elseif subcommand == "dump" then
            RaceTimes.Data.DumpLastTimes()
        elseif subcommand == "dumpraces" then
            local map = tonumber(arg)
            if not map then error("Usage: /racetimes dumpraces MAP-ID") end
            DumpRaces(map)
        end
    end
end
