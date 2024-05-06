local _, RaceTimes = ...
RaceTimes.SlashCmd = {}

SlashCmdHelp = SlashCmdHelp or {}

------------------------------------------------------------------------

function RaceTimes.SlashCmd.Init()
    SLASH_RACETIMES1 = "/racetimes"
    SLASH_RACETIMES2 = "/rt"
    SlashCmdHelp["RACETIMES"] = {
        args = nil,
        help = "Open the dragon racing personal best time list."
    }
    SlashCmdList["RACETIMES"] = function(arg)
        if arg == "dump" then
            RaceTimes.Data.DumpLastTimes()
            return
        end
        RaceTimes.UI.Open()
    end
end
