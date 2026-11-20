-- Native 3.3.5 browse-page filter. Server auction indices NEVER change.
local M = AuctionMog

function M:ResetBrowseIDs()
    for i = 1, NUM_BROWSE_TO_DISPLAY or 8 do
        local button = _G["BrowseButton" .. i]
        if button then button:SetID(i) end
    end
end

function M:BrowseState(link)
    local id = link and tonumber(link:match("item:(%d+)"))
    if not id or not self.collectionAvailable then return nil end
    if self.known[id] then return false end
    local name, _, _, _, _, _, _, _, slot = GetItemInfo(link)
    if not name or slot == nil then return nil end
    return not self.excluded[slot] and IsEquippableItem(link) and true or false
end

function M:PaintBrowseRow(visual, index, offset)
    local prefix = "BrowseButton" .. visual
    local button = _G[prefix]
    local name, texture, count, quality, canUse, level, minimum, increment, buyout, bid, high, owner = GetAuctionItemInfo("list", index)
    if not name or not minimum or not increment or not buyout or not bid then button:Hide(); return end
    -- Native click/modified-click/tooltip handlers add the faux-scroll offset.
    button:SetID(index - offset)
    button:SetWidth(600)
    _G[prefix .. "Highlight"]:SetWidth(562)
    local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[1]
    _G[prefix .. "Name"]:SetText(name)
    _G[prefix .. "Name"]:SetVertexColor(color.r, color.g, color.b)
    _G[prefix .. "Level"]:SetText(level > UnitLevel("player") and ("|cffff2020" .. level .. "|r") or level)
    local duration = GetAuctionItemTimeLeft("list", index)
    _G[prefix .. "ClosingTimeText"]:SetText(AuctionFrame_GetTimeLeftText(duration))
    _G[prefix .. "ClosingTime"].tooltip = AuctionFrame_GetTimeLeftTooltipText(duration)
    local icon = _G[prefix .. "ItemIconTexture"]
    icon:SetTexture(texture)
    icon:SetVertexColor(1, canUse and 1 or 0.1, canUse and 1 or 0.1)
    _G[prefix .. "ItemCount"]:SetText(count > 1 and count or "")
    _G[prefix .. "ItemCount"]:Show()
    local shownBid = bid > 0 and bid or minimum
    local required = bid > 0 and (bid + increment) or minimum
    local money = _G[prefix .. "MoneyFrame"]
    MoneyFrame_Update(money:GetName(), shownBid)
    if high then _G[prefix .. "YourBidText"]:Show() else _G[prefix .. "YourBidText"]:Hide() end
    money:SetPoint("RIGHT", button, "RIGHT", 10, buyout > 0 and 10 or 3)
    if buyout > 0 then
        MoneyFrame_Update(_G[prefix .. "BuyoutFrameMoney"], buyout)
        _G[prefix .. "BuyoutFrame"]:Show()
    else _G[prefix .. "BuyoutFrame"]:Hide() end
    _G[prefix .. "HighBidder"]:SetText(owner or "")
    button.bidAmount, button.buyoutPrice, button.itemCount = shownBid, buyout, count
    if GetSelectedAuctionItem("list") == index then
        button:LockHighlight()
        MoneyInputFrame_SetCopper(BrowseBidPrice, required)
        if not InCombatLockdown() and owner and owner ~= UnitName("player") then
            local funds = GetMoney()
            if buyout > 0 and buyout >= minimum and (funds + (high and bid or 0)) >= buyout then
                AuctionFrame.buyoutPrice = buyout
                BrowseBuyoutButton:Enable()
            end
            if not high and funds >= required and required <= MAXIMUM_BID_PRICE then BrowseBidButton:Enable() end
        end
    else button:UnlockHighlight() end
    button:Show()
end

function M:RenderBrowse()
    if not self.browseEnabled or not AuctionFrameBrowse:IsShown() then return end
    if self:Busy() then return end
    local batch = GetNumAuctionItems("list")
    if batch > 50 then return end -- ignore full-scan buffers; filter only normal browse pages
    self:Collection()
    local matches, unknown = {}, 0
    for index = 1, batch do
        local state = self:BrowseState(GetAuctionItemLink("list", index))
        if state then matches[#matches + 1] = index elseif state == nil then unknown = unknown + 1 end
    end
    self.browseMatches = matches
    local visible = NUM_BROWSE_TO_DISPLAY or 8
    local offset = math.min(FauxScrollFrame_GetOffset(BrowseScrollFrame), math.max(0, #matches - visible))
    BrowseScrollFrame.offset = offset
    BrowseBidButton:Disable(); BrowseBuyoutButton:Disable(); AuctionFrame.buyoutPrice = nil
    local selected = GetSelectedAuctionItem("list")
    local retained = false
    for _, index in ipairs(matches) do if index == selected then retained = true; break end end
    if selected and selected > 0 and not retained then
        SetSelectedAuctionItem("list", 0)
        CloseAuctionStaticPopups()
    end
    for visual = 1, visible do
        local index = matches[offset + visual]
        if index then self:PaintBrowseRow(visual, index, offset)
        else _G["BrowseButton" .. visual]:Hide() end
    end
    BrowseCurrentBidSort:SetWidth(184)
    FauxScrollFrame_Update(BrowseScrollFrame, #matches, visible, AUCTIONS_BUTTON_HEIGHT)
    self.browseStatus:SetText("Новых: " .. #matches .. "/" .. batch .. "; Не проверено: " .. unknown)
    self.browseStatus:Show()
    if #matches == 0 then
        BrowseNoResultsText:SetText(unknown > 0 and "Новые трансмоги не определены. Есть незагруженные данные." or
            "На этой странице новых трансмогов нет. Проверь следующую.")
        BrowseNoResultsText:Show()
    else BrowseNoResultsText:Hide() end
end

function M:InstallBrowse()
    if self.browseInstalled or not AuctionFrameBrowse or not IsUsableCheckButton or not AuctionFrameBrowse_Update then return end
    self.browseInstalled = true
    local check = CreateFrame("CheckButton", "AuctionMogNewCheck", AuctionFrameBrowse, "UICheckButtonTemplate")
    self.browseCheck = check
    check:SetWidth(24); check:SetHeight(24)
    check:SetPoint("LEFT", IsUsableCheckButton, "RIGHT", 88, 0)
    local label = _G.AuctionMogNewCheckText or check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:ClearAllPoints(); label:SetPoint("LEFT", check, "RIGHT", 0, 0)
    label:SetFontObject(GameFontHighlightSmall); label:SetText("Новый трансмог")
    self.browseStatus = AuctionFrameBrowse:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.browseStatus:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 0, 0)
    self.browseStatus:Hide()
    check:SetScript("OnClick", function(f)
        M.browseEnabled = f:GetChecked() and true or false
        CloseAuctionStaticPopups(); SetSelectedAuctionItem("list", 0)
        BrowseScrollFrame.offset = 0
        BrowseScrollFrameScrollBar:SetValue(0)
        AuctionFrameBrowse_Update()
        M:Print("Фильтр «Новый трансмог»: " .. (M.browseEnabled and "включён для текущей страницы." or "выключен."))
    end)
    check:SetScript("OnEnter", function(f)
        GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Новый трансмог")
        GameTooltip:AddLine("Фильтр загруженной страницы по transmogTip. Полный скан не нужен. Следующая страница — штатной кнопкой «Далее».", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    check:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.originalBrowseUpdate = AuctionFrameBrowse_Update
    AuctionFrameBrowse_Update = function(...)
        if M.renderingBrowse then return end
        M:ResetBrowseIDs()
        if not M.browseEnabled then BrowseNoResultsText:SetText(BROWSE_NO_RESULTS) end
        M.originalBrowseUpdate(...)
        M.renderingBrowse = true
        local ok = M:Safe(M.RenderBrowse)
        M.renderingBrowse = nil
        if not ok then
            M.browseEnabled = false; M.browseCheck:SetChecked(false)
            M:ResetBrowseIDs(); M.originalBrowseUpdate()
        end
        if not M.browseEnabled then M.browseStatus:Hide() end
    end
    -- Collection changes arrive asynchronously; update the native filter too.
    hooksecurefunc(M, "Refresh", function()
        if M.browseEnabled and not M.renderingBrowse then AuctionFrameBrowse_Update() end
    end)
end

-- Also works when enabled after PLAYER_LOGIN (addon managers / demand loading).
M:Safe(M.Init)
M:Safe(M.InstallBrowse)
