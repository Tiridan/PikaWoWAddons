local B = BagBin

-- WotLK 3.3.5 items only. Bank copies and engineering schematics do not count.
B.vendorItems = {
    {id=49040, name="Дживс", skill=450},
    {id=40769, name="Хламобот", skill=425, consumable=true},
    {id=34113, name="Полевой ремонтный робот 110G", skill=325, consumable=true},
    {id=18232, name="Полевой ремонтный робот 74A", skill=300, consumable=true},
}
B.vendorMounts = {[61425]=true, [61447]=true}

function B:VendorFreeSlots()
    local free = 0
    for bag = 0, 4 do
        local slots, family = GetContainerNumFreeSlots(bag)
        -- Ammo, soul and profession bags cannot hold arbitrary loot.
        if family == 0 then free = free + (slots or 0) end
    end
    return free
end

function B:VendorUnbound(bag, slot)
    self.tip:SetOwner(UIParent, "ANCHOR_NONE")
    self.tip:ClearLines(); self.tip:SetBagItem(bag, slot)
    local lines = self.tip:NumLines() or 0
    local first = _G.BagBinScanTooltipTextLeft1
    local known = lines > 0 and first and first:GetText() and first:GetText() ~= ""
        and ITEM_SOULBOUND ~= nil
    for i = 1, lines do
        for _, side in ipairs({"Left", "Right"}) do
            local fs = _G["BagBinScanTooltipText" .. side .. i]
            local text = fs and fs:GetText()
            if text then
                text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                for _, token in pairs({ITEM_SOULBOUND, ITEM_ACCOUNTBOUND, ITEM_BNETACCOUNTBOUND}) do
                    if token and token ~= "" and text:find(token, 1, true) then known = false end
                end
            end
        end
    end
    self.tip:Hide()
    return known
end

function B:VendorValue()
    local total, grey, green, stacks = 0, 0, 0, 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            local id = link and tonumber(link:match("item:(%d+)"))
            if id and not self.hardKeep[id] and not self.db.keep[id] then
                local _, count, locked = GetContainerItemInfo(bag, slot)
                local name, _, quality, _, _, itemType, _, _, _, _, price = GetItemInfo(link)
                if name and not locked and count and price and price > 0
                    and (quality == 0 or quality == 2) and not self:QuestItem(bag, slot, itemType)
                    and (quality == 0 or self:VendorUnbound(bag, slot)) then
                    local value = price * count
                    total = total + value; stacks = stacks + 1
                    if quality == 0 then grey = grey + value else green = green + value end
                end
            end
        end
    end
    return total, grey, green, stacks
end

function B:VendorEngineering()
    local engineering = GetSpellInfo(4036)
    for i = 1, GetNumSkillLines() do
        local name, header, _, rank = GetSkillLineInfo(i)
        if not header and name == engineering then return rank or 0 end
    end
    return 0
end

function B:VendorReady(start, duration, enabled)
    return enabled == 1 and start ~= nil and duration ~= nil
        and (start == 0 or duration == 0 or start + duration <= GetTime())
end

function B:VendorOptions()
    local rows, rank = {}, self:VendorEngineering()
    for _, provider in ipairs(self.vendorItems) do
        local found, ready = false, false
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local link = GetContainerItemLink(bag, slot)
                if link and tonumber(link:match("item:(%d+)")) == provider.id then
                    found = true
                    local _, count, locked = GetContainerItemInfo(bag, slot)
                    if count and count > 0 and not locked and rank >= provider.skill
                        and IsUsableItem(provider.id)
                        and self:VendorReady(GetContainerItemCooldown(bag, slot)) then ready = true end
                end
            end
        end
        if found then
            local name = GetItemInfo(provider.id) or provider.name
            rows[#rows + 1] = {key="item:" .. provider.id, kind="item", id=provider.id,
                name=name, ready=ready, note=ready and (provider.consumable and "расходуется 1 шт." or "многоразовый")
                    or rank < provider.skill and ("нужна инженерия " .. provider.skill) or "откат / недоступен"}
        end
    end
    for i = 1, GetNumCompanions("MOUNT") do
        local _, name, spell, _, active = GetCompanionInfo("MOUNT", i)
        if self.vendorMounts[spell] then
            local outdoors = IsOutdoors() and not IsSwimming() and not IsFlying()
            rows[#rows + 1] = {key="spell:" .. spell, kind="spell", id=spell, name="Тундровый мамонт",
                ready=not active and outdoors and IsUsableSpell(spell)
                    and self:VendorReady(GetSpellCooldown(spell)),
                note=active and "уже призван" or outdoors and "если разрешён здесь" or "нужно наружу, на сушу"}
        end
    end
    return rows
end

function B:CloseVendorOffer()
    if InCombatLockdown() then return end
    if self.vendorWindow then
        UnregisterStateDriver(self.vendorWindow, "visibility")
        self.vendorWindow:Hide()
    end
    self.vendorOffer = nil
end

function B:BuildVendorWindow()
    if self.vendorWindow then return end
    local f = CreateFrame("Frame", "BagBinVendorWindow", UIParent, "SecureHandlerStateTemplate")
    self.vendorWindow = f
    f:SetSize(560, 410); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true); f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    f:SetBackdropColor(0.045, 0.038, 0.03, 1); f:SetBackdropBorderColor(0.65, 0.65, 0.65, 1)
    local function label(text, y, height)
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("TOPLEFT", 20, y); fs:SetWidth(520); fs:SetHeight(height)
        fs:SetJustifyH("LEFT"); fs:SetText(text); return fs
    end
    label("Корзина — вызвать торговца для продажи?", -16, 24)
    f.summary = label("", -46, 66)
    label("Выберите торговца. Затем откройте его вручную и продайте вещи.\nСумма — оценка; автоматическая продажа не запускается.", -116, 36)
    f.buttons = {}
    for i = 1, 5 do
        local button = CreateFrame("Button", nil, f, "SecureActionButtonTemplate,UIPanelButtonTemplate")
        button:SetSize(520, 32); button:SetPoint("TOPLEFT", 20, -162 - (i - 1) * 37)
        button:RegisterForClicks("LeftButtonUp")
        button:SetScript("PreClick", function(btn)
            if InCombatLockdown() then return end
            btn:SetAttribute("type", nil); btn.attempted = nil
            if not B.vendorOffer or B:Busy() or GetUnitSpeed("player") > 0
                or UnitCastingInfo("player") or UnitChannelInfo("player") then
                B:Print("Призыв недоступен: остановитесь и завершите текущее действие."); return
            end
            for _, option in ipairs(B:VendorOptions()) do
                if option.key == btn.providerKey and option.ready then
                    btn:SetAttribute(option.kind, option.kind == "item" and ("item:" .. option.id) or GetSpellInfo(option.id))
                    btn:SetAttribute("type", option.kind); btn.attempted = option.name; return
                end
            end
            B:Print("Торговец сейчас недоступен: проверьте предмет, откат и место призыва.")
        end)
        button:SetScript("PostClick", function(btn)
            if not btn.attempted or InCombatLockdown() then return end
            B.vendorHoldUntil = GetTime() + 120
            B:Print("Запрошен призыв: " .. btn.attempted .. ". Откройте торговца для продажи. Автоочистка ждёт 2 минуты.")
            B:CloseVendorOffer()
        end)
        f.buttons[i] = button
    end
    local later = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    later:SetSize(220, 26); later:SetPoint("BOTTOM", 0, 16); later:SetText("Не сейчас")
    later:SetScript("OnClick", function() B:CloseVendorOffer() end)
    f:Hide()
end

function B:CheckVendorOffer(manual)
    if not self.db then return false end
    if InCombatLockdown() or UnitAffectingCombat("player") then return self.vendorOffer ~= nil end
    local free = self:VendorFreeSlots()
    if free > 1 then
        self.vendorNotified = nil
        if self.vendorOffer and not self.vendorOffer.manual then self:CloseVendorOffer() end
    end
    if self.vendorHoldUntil and GetTime() < self.vendorHoldUntil then
        if not manual then return true end
    else self.vendorHoldUntil = nil end
    if self:Busy() then
        if self.vendorOffer then self:CloseVendorOffer() end
        if manual then self:Print("Торговец: " .. self:Busy() .. ".") end
        return false
    end
    if not manual and not self.vendorOffer and (free > 1 or self.vendorNotified) then return false end
    local total, grey, green, stacks = self:VendorValue()
    local options, ready = self:VendorOptions(), false
    for _, option in ipairs(options) do if option.ready then ready = true end end
    if total == 0 or not ready then
        self:CloseVendorOffer()
        if manual then self:Print(total == 0 and "Нет хлама или непривязанной зелёнки для продажи."
            or "Нет доступного торговца: проверьте сумки, инженерию, откат и место призыва.") end
        return false
    end
    self:BuildVendorWindow()
    local fresh = not self.vendorOffer
    self.vendorOffer = self.vendorOffer or {manual=manual}
    if manual then self.vendorOffer.manual = true end
    self.vendorNotified = true
    local f = self.vendorWindow
    f.summary:SetText("Свободно обычных ячеек: " .. free .. ". К продаже: " .. stacks .. " стаков.\nХлам: "
        .. self:Money(grey) .. "; непривязанная зелёнка: " .. self:Money(green) .. ".\nВсего: " .. self:Money(total))
    for i, button in ipairs(f.buttons) do
        local option = options[i]
        button:SetAttribute("type", nil)
        if option then
            button.providerKey = option.key
            button:SetText(option.name .. " — " .. option.note)
            if option.ready then button:Enable() else button:Disable() end
            button:Show()
        else button:Hide() end
    end
    if fresh then
        RegisterStateDriver(f, "visibility", "[combat] hide; show")
        f:Show()
        self:Print("Можно продать хлам и непривязанную зелёнку на " .. self:Money(total) .. ". Выберите торговца в окне.")
    end
    return true
end

function B:VendorTick()
    if GetTime() < (self.vendorTickAt or 0) then return end
    self.vendorTickAt = GetTime() + 1
    self:CheckVendorOffer()
end
