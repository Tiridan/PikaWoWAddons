AuctionMog = { version = "1.2.1" }
local M = AuctionMog

M.excluded = {
    INVTYPE_AMMO = true, INVTYPE_NECK = true, INVTYPE_FINGER = true,
    INVTYPE_TRINKET = true, INVTYPE_BAG = true, INVTYPE_QUIVER = true,
}

function M:Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffce9bffAuctionMog:|r " .. text)
end

-- Isolate errors in the native browse filter.
function M:Safe(method, ...)
    local ok, err = pcall(method, self, ...)
    if not ok then
        self.error = tostring(err)
        self:Print("Ошибка обработки: " .. self.error)
    end
    return ok
end

function M:Busy()
    if gAtr_FullScanState and gAtr_FullScanState ~= ATR_FS_NULL then return true end
    for _, pane in ipairs({gShopPane or false, gSellPane or false, gMorePane or false}) do
        if pane and pane.activeSearch and pane.activeSearch.processing_state ~= KM_NULL_STATE then
            return true
        end
    end
    return false
end

function M:Collection()
    self.known = {}
    self.knownCount = 0
    self.collectionAvailable = type(TransmogTipList) == "table"
    if not self.collectionAvailable then return end
    for _, value in pairs(TransmogTipList) do
        local id = tonumber(value)
        if id and not self.known[id] then
            self.known[id] = true
            self.knownCount = self.knownCount + 1
        end
    end
end

function M:Refresh()
    self:Collection()
end

function M:Tick()
    if self.collectionDirtyAt and GetTime() >= self.collectionDirtyAt then
        self.collectionDirtyAt = nil
        self:Refresh()
    end
end

function M:Init()
    if self.initialized then return end
    self.initialized = true
    self:Collection()
    self:Print(self.version .. ": фильтр «Новый трансмог» готов.")
end

SLASH_AUCTIONMOG1 = "/amog"
SLASH_AUCTIONMOG2 = "/auctionmog"
SlashCmdList.AUCTIONMOG = function()
    M:Print(M.version .. ": используй галочку «Новый трансмог» в стандартном аукционе.")
end

M.events = CreateFrame("Frame")
M.events:RegisterEvent("PLAYER_LOGIN")
M.events:RegisterEvent("ADDON_LOADED")
M.events:RegisterEvent("AUCTION_HOUSE_SHOW")
M.events:RegisterEvent("AUCTION_HOUSE_CLOSED")
M.events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
M.events:RegisterEvent("CHAT_MSG_SYSTEM")
M.events:SetScript("OnEvent", function(_, event, message)
    if event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and message == "AuctionMog") then M:Safe(M.Init)
    elseif event == "AUCTION_HOUSE_SHOW" then
        M:Safe(M.Init)
        M.auctionOpen = true
        if M.InstallBrowse then M:Safe(M.InstallBrowse) end
    elseif event == "AUCTION_HOUSE_CLOSED" then
        M.auctionOpen = false
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or
        (event == "CHAT_MSG_SYSTEM" and type(message) == "string" and message:find("TRANSMOG_SYNC:", 1, true)) then
        -- Deferred until transmogTip's own event/filter has updated its table.
        M.collectionDirtyAt = GetTime() + 0.5
    end
    if event == "ADDON_LOADED" and message == "Blizzard_AuctionUI" and M.InstallBrowse then
        M:Safe(M.InstallBrowse)
    end
end)
M.events:SetScript("OnUpdate", function(_, elapsed)
    M.elapsed = (M.elapsed or 0) + elapsed
    if M.elapsed < 0.05 then return end
    M.elapsed = 0
    if M.collectionDirtyAt then M:Safe(M.Tick) end
end)
