local _, RaceTimes = ...
RaceTimes.SlashCmd = {}

local strfind = string.find
local strstr = function(s1,s2,pos) return strfind(s1,s2,pos,true) end
local strsub = string.sub

SlashCmdHelp = SlashCmdHelp or {}

------------------------------------------------------------------------

-- Convenience function to list all races in a map, optionally including
-- races in child maps.
local function DumpRaces(base_map, children)
    local races = {}
    local function FindRaces(map, target_map)
        local x0, x1, y0, y1 = C_Map.GetMapRectOnMap(map, target_map)
        local function Transform(x, y)
            return x0 + x*(x1-x0), y0 + y*(y1-y0)
        end
        local race_pois = C_AreaPoiInfo.GetDragonridingRacesForMap(map) or {}
        for _, poi in ipairs(race_pois) do
            local info = C_AreaPoiInfo.GetAreaPOIInfo(map, poi)
            local x, y = Transform(info.position.x, info.position.y)
            races[info.name] = races[info.name] or {x, y}
        end
        -- Cup races aren't included in the GetDragonridingRacesForMap()
        -- list, so we have to look them up manually.
        local map_pois = C_AreaPoiInfo.GetAreaPOIForMap(map) or {}
        for _, poi in ipairs(map_pois) do
            local info = C_AreaPoiInfo.GetAreaPOIInfo(map, poi)
            if info.atlasName == "racing" then
                local x, y = Transform(info.position.x, info.position.y)
                races[info.name] = races[info.name] or {x, y}
            end
        end
    end
    FindRaces(base_map, base_map)
    if children then
        for _, info in ipairs(C_Map.GetMapChildrenInfo(base_map) or {}) do
            FindRaces(info.mapID, base_map)
        end
    end
    print("Races on map "..base_map..":"..(#races==0 and " None" or ""))
    local names = {}
    for name in pairs(races) do tinsert(names, name) end
    table.sort(names)
    for _, name in ipairs(names) do
        local x, y = unpack(races[name])
        print(string.format("   %.3f %.3f %s", x*100, y*100, name))
    end
end

function RaceTimes.SlashCmd.Init()
    SLASH_RACETIMES1 = "/racetimes"
    SLASH_RACETIMES2 = "/rt"
    SlashCmdHelp["RACETIMES"] = {
        args = "[|cFFFFFF00recenter|r || |cFFFFFF00settings|r]",
        help = {"Opens the skyriding race personal best time list.",
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
            local map
            local children = false
            if arg == "" then
                map = C_Map.GetBestMapForUnit("player")
            else
                if strsub(arg, -4) == " all" then
                    children = true
                    arg = strsub(arg, 1, -5)
                end
                map = tonumber(arg)
                if not map then
                    error("Usage: /racetimes dumpraces [MAP-ID [all]]")
                end
            end
            DumpRaces(map, children)
        end
    end
end
