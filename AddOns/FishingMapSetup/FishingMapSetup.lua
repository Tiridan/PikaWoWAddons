local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self)
    FishingMapSetupDB = FishingMapSetupDB or {}

    if GatherMate and GatherMate.db and GatherMate.db.profile then
        GatherMate.db.profile.show["Fishing"] = "always"
        GatherMate.db.profile.showWorldMap = true
        GatherMate.db.profile.showMinimap = true
    end

    if not FishingMapSetupDB.fishImported then
        local dataAddon = LibStub("AceAddon-3.0"):GetAddon("GatherMate_Data", true)
        if dataAddon and dataAddon.PerformMerge then
            dataAddon:PerformMerge({ Fish = true }, "Merge")
            FishingMapSetupDB.fishImported = true
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Fishing Map:|r база рыбных мест импортирована.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff3333Fishing Map:|r не удалось загрузить GatherMate_Data.")
        end
    end

    if GatherMate and GatherMate.SendMessage then
        GatherMate:SendMessage("GatherMateConfigChanged")
    end

    self:UnregisterEvent("PLAYER_LOGIN")
end)
