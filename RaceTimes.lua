local module_name
module_name, RaceTimes = ...

RaceTimes.VERSION = "1.4+"

RaceTimes.startup_frame = CreateFrame("Frame")
RaceTimes.startup_frame:RegisterEvent("ADDON_LOADED")
RaceTimes.startup_frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == module_name then
        RaceTimes.SlashCmd.Init()
        RaceTimes.UI.Init()
    end
end)

function RaceTimes.Show()
    RaceTimes.UI.Open()
end
