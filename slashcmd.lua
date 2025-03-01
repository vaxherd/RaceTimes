local _, RaceTimes = ...
RaceTimes.SlashCmd = {}

SlashCmdHelp = SlashCmdHelp or {}

------------------------------------------------------------------------

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
        if arg == "dump" then
            RaceTimes.Data.DumpLastTimes()
            return
        end
        if arg == nil or arg == "" then
            RaceTimes.UI.Open()
        elseif arg == "recenter" then
            RaceTimes.UI.Recenter()
            RaceTimes.UI.Open()
        elseif arg == "settings" then
            RaceTimes.Settings.Open()
        end
    end
end
