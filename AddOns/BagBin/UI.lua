local B = BagBin
local C = {bg={0.045,0.038,0.03,1}, panel={0.065,0.055,0.043,1}, edge={0.65,0.65,0.65,1}, text={1,0.95,0.82,1}, muted={0.78,0.75,0.67,1}, gold={1,0.82,0,1}}
local function Label(parent, text, x, y, width, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    local size, color = 14, C.text
    if template == "GameFontNormalLarge" then size, color = 20, C.gold
    elseif template == "GameFontHighlightSmall" then size, color = 12, C.muted
    elseif template == "GameFontDisableSmall" then size, color = 11, C.muted end
    fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size)
    fs:SetTextColor(unpack(color)); fs:SetPoint("TOPLEFT", x, y); fs:SetWidth(width); fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP"); fs:SetText(text)
    return fs
end
local function Button(parent, text, x, y, width, fn)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 24); button:SetPoint("TOPLEFT", x, y)
    button:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    button:SetBackdropColor(unpack(C.panel)); button:SetBackdropBorderColor(unpack(C.edge))
    button.caption = Label(button, text, 8, 0, width - 16, "GameFontHighlightSmall")
    button.caption:ClearAllPoints(); button.caption:SetPoint("CENTER", button, "CENTER", 0, 0); button.caption:SetJustifyH("CENTER"); button.caption:SetJustifyV("MIDDLE"); button.caption:SetTextColor(unpack(C.gold))
    button.SetText = function(self, value) self.caption:SetText(value or "") end
    button:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.gold)) end)
    button:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.edge)) end)
    button:SetScript("OnClick", fn)
    return button
end
local function Show(frame, visible)
    if visible then frame:Show() else frame:Hide() end
end
local function Edit(parent, x, y, width)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 12)
    box:SetSize(width, 24); box:SetPoint("TOPLEFT", x, y); box:SetAutoFocus(false)
    box:SetTextColor(1, 0.86, 0.55, 1)
    box:SetTextInsets(8, 8, 0, 0)
    box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    box:SetBackdropColor(unpack(C.panel))
    box:SetBackdropBorderColor(unpack(C.edge))
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

function B:BuildWindow()
    if self.window then return end
    local f = CreateFrame("Frame", "BagBinWindow", UIParent)
    self.window = f; self.tab = "candidates"; self.page = 1
    f:SetSize(650, 700); f:SetPoint("CENTER", 0, -15); f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true); f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    f:SetBackdropColor(unpack(C.bg))
    f:SetBackdropBorderColor(unpack(C.edge))
    Label(f, "Корзина", 24, -20, 520, "GameFontNormalLarge")
    Label(f, "Цена торговца за полный стак - BagBin " .. self.version, 24, -44, 550, "GameFontHighlightSmall")
    Button(f, "X", 602, -20, 24, function() f:Hide() end)
    table.insert(UISpecialFrames, "BagBinWindow")
    Label(f, "Удалять дешевле", 24, -90, 122, "GameFontHighlightSmall")
    Label(f, "золото", 154, -66, 52, "GameFontHighlightSmall")
    Label(f, "серебро", 214, -66, 52, "GameFontHighlightSmall")
    Label(f, "медь", 274, -66, 52, "GameFontHighlightSmall")
    f.thresholdGold = Edit(f, 154, -84, 52)
    f.thresholdSilver = Edit(f, 214, -84, 52)
    f.thresholdCopper = Edit(f, 274, -84, 52)
    Label(f, "за полный стак", 340, -90, 150, "GameFontHighlightSmall")
    local function ApplyThreshold()
        B:SetThresholdParts(f.thresholdGold:GetText(), f.thresholdSilver:GetText(), f.thresholdCopper:GetText())
        f.thresholdGold:ClearFocus(); f.thresholdSilver:ClearFocus(); f.thresholdCopper:ClearFocus()
    end
    for _, box in ipairs({f.thresholdGold, f.thresholdSilver, f.thresholdCopper}) do box:SetScript("OnEnterPressed", ApplyThreshold) end
    Button(f, "Применить", 502, -84, 124, ApplyThreshold)
    f.auto = CreateFrame("CheckButton", "BagBinAutoCheck", f, "UICheckButtonTemplate")
    f.auto:SetPoint("TOPLEFT", 24, -118); f.auto:SetSize(24, 24)
    Label(f, "Автоочистка после лута, вне боя", 56, -124, 280, "GameFontHighlightSmall")
    f.auto:SetScript("OnClick", function(self) B:SetAuto(self:GetChecked()) end)
    f.reserve = Edit(f, 570, -118, 56)
    f.reserveLabel = Label(f, "Минимум свободных мест", 350, -124, 210, "GameFontHighlightSmall")
    f.reserveLabel:ClearAllPoints(); f.reserveLabel:SetPoint("RIGHT", f.reserve, "LEFT", -12, 0)
    f.reserveLabel:SetHeight(24); f.reserveLabel:SetJustifyV("MIDDLE")
    f.reserve:SetScript("OnEnterPressed", function(self) B:SetReserveSlots(self:GetText()); self:ClearFocus() end)
    Label(f, "Пока окно открыто, автоочистка на паузе. Удалённое вернуть нельзя.", 24, -145, 600, "GameFontHighlightSmall")
    f.tabs = {}
    local function Tab(key, text, x, width)
        f.tabs[key] = Button(f, text, x, -170, width, function() B.tab = key; B.page = 1; B:Refresh() end)
        f.tabs[key]:SetHeight(30)
    end
    Tab("candidates", "К удалению", 24, 114)
    Tab("partial", "Неполные", 146, 114)
    Tab("whitegear", "Белый шмот", 268, 114)
    Tab("keep", "Исключения", 390, 114)
    Tab("extra", "Белые спис.", 512, 114)
    f.summary = Label(f, "", 24, -207, 602, "GameFontHighlightSmall")
    f.capacity = Label(f, "", 24, -220, 602, "GameFontDisableSmall")
    f.rows = {}
    f.partialLabel = Label(f, "Без изменения количества, минут:", 24, -246, 290, "GameFontHighlightSmall")
    f.partialMinutes = Edit(f, 318, -240, 54)
    f.partialMinutes:SetScript("OnEnterPressed", function(self)
        B:SetPartialMinutes(self:GetText()); self:ClearFocus()
    end)
    f.partialApply = Button(f, "Применить таймер", 410, -240, 214, function()
        B:SetPartialMinutes(f.partialMinutes:GetText()); f.partialMinutes:ClearFocus()
    end)
    for i = 1, 7 do
        local row = CreateFrame("Frame", nil, f)
        row:SetSize(602, 36); row:SetPoint("TOPLEFT", 24, -230 - (i - 1) * 38)
        row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        row:SetBackdropColor(unpack(C.panel)); row:SetBackdropBorderColor(unpack(C.edge))
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(26, 26); row.icon:SetPoint("LEFT")
        row.name = Label(row, "", 34, -1, 410, "GameFontHighlightSmall")
        row.detail = Label(row, "", 34, -19, 410, "GameFontDisableSmall")
        row.action = Button(row, "", 461, -1, 140, function()
            if row.id and (B.tab == "partial" or B.tab == "whitegear") then B:Start(true, B.tab, row.bag, row.slot)
            elseif row.id then B:EditList(B.tab == "candidates" and "keep" or B.tab == "keep" and "unkeep" or "unextra", tostring(row.id)) end
        end)
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            if self.link then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(self.link); GameTooltip:Show() end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f.rows[i] = row
    end
    f.prev = Button(f, "<", 24, -475, 38, function() B.page = math.max(1, B.page - 1); B:Refresh() end)
    f.page = Label(f, "", 78, -481, 130, "GameFontHighlightSmall")
    f.next = Button(f, ">", 206, -475, 38, function() B.page = B.page + 1; B:Refresh() end)
    f.refreshButton = Button(f, "Обновить", 266, -570, 110, function() B:Refresh() end)
    f.clean = Button(f, "Очистить сейчас", 410, -570, 214, function() B:Start(true) end)
    f.itemLabel = Label(f, "Предмет для списка (Shift+клик по ссылке или введите ID):", 24, -609, 520, "GameFontHighlightSmall")
    f.item = Edit(f, 29, -632, 264)
    f.item:SetMaxLetters(512)
    f.item:SetScript("OnTextChanged", function(self)
        if B.window and B.window.inputHint then
            B.window.inputHint:SetText(self:GetText() == "" and "Поле пустое: выберите предмет ссылкой или введите ID." or "Готово к действию: нажмите «Защитить» или «Разрешить белый».")
        end
    end)
    f.keepButton = Button(f, "Защитить", 309, -632, 130, function()
        if B:EditList("keep", f.item:GetText()) then B.tab = "keep"; B.page = 1; B:Refresh() end
        f.item:ClearFocus()
    end)
    f.extraButton = Button(f, "Разрешить белый", 448, -632, 176, function()
        if B:EditList("extra", f.item:GetText()) then B.tab = "extra"; B.page = 1; B:Refresh() end
        f.item:ClearFocus()
    end)
    f.inputHint = Label(f, "Поле пустое: выберите предмет ссылкой или введите ID.", 29, -662, 595, "GameFontDisableSmall")
    for _, row in ipairs(f.rows) do
        row.icon:ClearAllPoints(); row.icon:SetPoint("LEFT",row,"LEFT",6,0)
        row.action:ClearAllPoints(); row.action:SetPoint("RIGHT",row,"RIGHT",-6,0)
        row.action:SetWidth(134)
    end
    f.item:ClearAllPoints(); f.item:SetPoint("TOPLEFT",24,-632)
    f.inputHint:ClearAllPoints(); f.inputHint:SetPoint("TOPLEFT",24,-664)
    for _, check in ipairs({f.auto}) do
        check:SetNormalTexture(""); check:SetPushedTexture("")
        check:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        check:SetBackdropColor(unpack(C.panel)); check:SetBackdropBorderColor(unpack(C.edge))
    end
    for _, tab in pairs(f.tabs) do
        tab.caption:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",10)
        tab.caption:SetWidth(106)
    end
    -- Secure post-hook only fills our focused editor; does not replace bag/chat handlers.
    hooksecurefunc("ChatEdit_InsertLink", function(link)
        if f:IsShown() and f.item:HasFocus() then f.item:SetText(link) end
    end)
    f:SetScript("OnShow", function()
        if B.run then B:Finish("Открыт просмотр корзины.") end
        B:Refresh()
    end)
    f:SetScript("OnHide", function() f.item:ClearFocus(); f.thresholdGold:ClearFocus(); f.thresholdSilver:ClearFocus(); f.thresholdCopper:ClearFocus(); GameTooltip:Hide() end)
    f:Hide()
end

function B:Refresh()
    local f = self.window
    if not f or not f:IsShown() then return end
    -- Legacy removed tabs fall back to the cleanup list.
    if not f.tabs[self.tab] then self.tab = "candidates"; self.page = 1 end
    -- Clear every page-specific control before any page can return early.
    if f.visibleTab ~= self.tab then
        if CloseDropDownMenus then CloseDropDownMenus() end
        f.visibleTab = self.tab
    end
    for _, control in ipairs({f.partialLabel, f.partialMinutes, f.partialApply,
        f.prev, f.next, f.page, f.refreshButton, f.clean,
        f.itemLabel, f.item, f.inputHint, f.keepButton, f.extraButton}) do control:Hide() end
    for _, row in ipairs(f.rows) do row:Hide() end
    for key, button in pairs(f.tabs) do
        if key == self.tab then button:Disable(); button:SetBackdropBorderColor(unpack(C.gold))
        else button:Enable(); button:SetBackdropBorderColor(unpack(C.edge)) end
    end
    if not f.thresholdGold:HasFocus() and not f.thresholdSilver:HasFocus() and not f.thresholdCopper:HasFocus() then
        local gold = math.floor(self.db.threshold / 10000)
        local silver = math.floor(self.db.threshold / 100) % 100
        local copper = self.db.threshold % 100
        f.thresholdGold:SetText(tostring(gold)); f.thresholdSilver:SetText(tostring(silver)); f.thresholdCopper:SetText(tostring(copper))
    end
    f.auto:SetChecked(self.db.auto)
    Show(f.partialLabel, self.tab == "partial")
    Show(f.partialMinutes, self.tab == "partial")
    Show(f.partialApply, self.tab == "partial")
    if not f.partialMinutes:HasFocus() then f.partialMinutes:SetText(tostring(self.db.partialMinutes)) end
    local rows, value
    f.prev:Show(); f.next:Show(); f.page:Show(); f.refreshButton:Show()
    local hasItemEditor = self.tab == "keep" or self.tab == "extra"
    local footer = -576
    f.prev:ClearAllPoints(); f.prev:SetPoint("TOPLEFT", 24, footer)
    f.page:ClearAllPoints(); f.page:SetPoint("TOPLEFT", 78, footer - 6)
    f.next:ClearAllPoints(); f.next:SetPoint("TOPLEFT", 206, footer)
    f.refreshButton:ClearAllPoints(); f.refreshButton:SetPoint("TOPLEFT", 266, footer)
    f.clean:ClearAllPoints(); f.clean:SetPoint("TOPLEFT", 410, footer)
    local hasClean = self.tab == "candidates"
    Show(f.clean, hasClean)
    Show(f.itemLabel, hasItemEditor); Show(f.item, hasItemEditor); Show(f.inputHint, hasItemEditor)
    Show(f.keepButton, hasItemEditor); Show(f.extraButton, hasItemEditor)
    if self.tab == "candidates" or self.tab == "partial" or self.tab == "whitegear" then
        rows, value = self.tab == "partial" and self:ScanPartial() or self.tab == "whitegear" and self:ScanWhiteGear() or self:Scan()
        f.summary:SetText(self.tab == "partial" and "По окончании таймера: в общую очередь по цене текущей пачки."
            or self.tab == "whitegear" and "Белое оружие и броня. Только ручное удаление, автоматическая очистка их не трогает."
            or "Мест к освобождению: " .. #rows .. "  |  Цена содержимого: " .. self:Money(value))
    else
        rows = {}
        local ids = {}
        for id, enabled in pairs(self.db[self.tab]) do if enabled and type(id) == "number" then ids[id] = true end end
        if self.tab == "keep" then for id in pairs(self.hardKeep) do ids[id] = true end end
        for id in pairs(ids) do
            local name, link = GetItemInfo(id)
            rows[#rows + 1] = {id = id, name = name or ("Предмет #" .. id), link = link}
        end
        table.sort(rows, function(a, b) return a.id < b.id end)
        f.summary:SetText(self.tab == "keep" and "Никогда не удаляются. Камни возвращения защищены постоянно."
            or "Только указанные белые предметы. Порог и защита заданий сохраняются.")
    end
    f.reserve:SetText(tostring(self.db.reserveSlots))
    f.capacity:SetText("Свободно мест сейчас: " .. self:FreeSlots() .. "  |  автоочистка включается ниже " .. self.db.reserveSlots)
    local pages = math.max(1, math.ceil(#rows / 7))
    self.page = math.max(1, math.min(self.page, pages))
    f.page:SetText(self.page .. " / " .. pages)
    if self.page > 1 then f.prev:Enable() else f.prev:Disable() end
    if self.page < pages then f.next:Enable() else f.next:Disable() end
    for i, row in ipairs(f.rows) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 24, -(self.tab == "partial" and 280 or 245) - (i - 1) * 38)
        local item = rows[(self.page - 1) * 7 + i]
        if item then
            row.id = item.id; row.link = item.link
            row.bag = item.bag; row.slot = item.slot
            row.icon:SetTexture(GetItemIcon(item.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText(item.link or item.name)
            row.detail:SetText(item.count and ("В сумке: " .. item.count .. "  |  Полный стак: " .. item.maxStack .. " шт. = " .. self:Money(item.full))
                or ("ID " .. item.id .. (self.hardKeep[item.id] and " - постоянная защита" or "")))
            if self.tab == "partial" or item.aged then
                local remaining = self:PartialRemaining(item)
                row.detail:SetText(item.count .. "/" .. item.maxStack .. " шт. | Сейчас: " .. self:Money(item.value)
                    .. " | " .. (remaining == 0 and "К удалению" or string.format("Осталось %d:%02d", math.floor(remaining / 60), remaining % 60)))
            end
            row.action:SetText(self.tab == "candidates" and "Сохранить" or (self.tab == "partial" or self.tab == "whitegear") and "Удалить" or "Убрать из списка")
            if self.hardKeep[item.id] then row.action:Disable() else row.action:Enable() end
            row:Show()
        else row.id = nil; row:Hide() end
    end
    if self.run or self.fault then f.clean:Disable() else f.clean:Enable() end
    if self.fault then f.summary:SetText("Ошибка удаления: автоочистка приостановлена до /reload. Подробности в чате.") end
end

function B:Toggle()
    self:BuildWindow()
    if self.window:IsShown() then self.window:Hide() else self.window:Show() end
end

function B:CreateLauncher()
    if self.launcher then return end
    local f = CreateFrame("Button", "BagBinMinimapButton", Minimap)
    BagBinLauncher = f -- Compatibility alias for the former floating launcher.
    self.launcher = f
    f:SetSize(32, 32); f:SetFrameStrata("MEDIUM"); f:SetClampedToScreen(true)
    -- Preserve db.launcher; the minimap/collector now controls button placement.
    f:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -8)
    f:SetNormalTexture("Interface\\Icons\\INV_Misc_Bag_10")
    f:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    f:RegisterForClicks("LeftButtonUp")
    f:SetScript("OnClick", function() B:Toggle() end)
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:AddLine("Корзина")
        GameTooltip:AddLine("ЛКМ: список и настройки. Открыть: /bagbin", 1, 1, 1, true)
        GameTooltip:AddLine("Порог за полный стак: " .. B:Money(B.db.threshold), 1, 0.82, 0)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
