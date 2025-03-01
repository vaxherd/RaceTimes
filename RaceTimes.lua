local module_name
module_name, RaceTimes = ...

RaceTimes.VERSION = "2.0"

RaceTimes.startup_frame = CreateFrame("Frame")
-- We wait for PLAYER_LOGIN instead of running immediately on ADDON_LOADED
-- because the server name (needed for generating the saved data key) isn't
-- available until the PLAYER_LOGIN event.
RaceTimes.startup_frame:RegisterEvent("PLAYER_LOGIN")
RaceTimes.startup_frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "PLAYER_LOGIN" then
        RaceTimes.SavedTimes.Init()
        RaceTimes.Settings.Init()
        RaceTimes.SlashCmd.Init()
        RaceTimes.UI.Init()
    end
end)

function RaceTimes.Show()
    RaceTimes.UI.Open()
end

function RaceTimes.ShowSettings()
    RaceTimes.Settings.Open()
end
