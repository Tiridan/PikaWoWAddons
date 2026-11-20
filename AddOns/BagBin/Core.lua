BagBin = {}
local B = BagBin
B.version = "1.12.0"
B.lootSettingsMoved = true -- Loot automation and manual-delete preferences belong to UnBot.
B.frame = CreateFrame("Frame")
B.tip = CreateFrame("GameTooltip", "BagBinScanTooltip", nil, "GameTooltipTemplate")
B.hardKeep = {[6948] = true, [44314] = true}
B.qualityLabels = {[0]="Серый", [1]="Белый", [2]="Зелёный", [3]="Синий", [4]="Фиолетовый", [5]="Оранжевый"}

-- FrameXML owns this global. Even assigning it back to itself taints the
-- standard popup dispatch, including protected USE_BIND confirmation.
-- Register only our own entry; never replace Blizzard's table or callbacks.
StaticPopupDialogs["BAGBIN_INSTANCE_CONFIRM"] = {
    text = "Подземелье: %s.\nРазрешить автоочистку серого хлама дешевле %s за полный стак?\nОтвет сохранится на 24 часа для этого персонажа и подземелья.",
    button1 = "Разрешить",
    button2 = "Запретить",
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
    OnAccept = function(frame, data)
        B:SaveInstanceDecision(data or (frame and frame.data), true)
    end,
    OnCancel = function(frame, data)
        B:SaveInstanceDecision(data or (frame and frame.data), false)
    end,
}

function B:Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc66Корзина:|r " .. text)
end

function B:Money(value)
    value = math.floor(value or 0)
    return string.format("%dз %dс %dм", math.floor(value / 10000), math.floor(value / 100) % 100, value % 100)
end

function B:Init()
    BagBinDB = type(BagBinDB) == "table" and BagBinDB or {}
    self.db = BagBinDB
    if type(self.db.partialMinutes) ~= "number" or self.db.partialMinutes ~= self.db.partialMinutes
        or self.db.partialMinutes < 1 or self.db.partialMinutes > 60 then self.db.partialMinutes = 3 end
    self.partialWatch = {}
    if type(self.db.threshold) ~= "number" or self.db.threshold ~= self.db.threshold
        or self.db.threshold < 1 or self.db.threshold > 1000000 then self.db.threshold = 1000 end
    if type(self.db.reserveSlots) ~= "number" or self.db.reserveSlots ~= self.db.reserveSlots
        or self.db.reserveSlots < 0 or self.db.reserveSlots > 100 then self.db.reserveSlots = 5 end
    if self.db.auto == nil then self.db.auto = true end
    if type(self.db.keep) ~= "table" then self.db.keep = {} end
    if type(self.db.extra) ~= "table" then self.db.extra = {} end
    self:Print(self.version .. " загружена. /bagbin — список и настройки. Автоочистка " .. (self.db.auto and "включена." or "выключена."))
end

function B:QuestItem(bag, slot, itemType)
    if itemType == "Quest" or itemType == "Задание" or itemType == "Задания" then return true end
    if GetContainerItemQuestInfo then
        local isQuest, questID = GetContainerItemQuestInfo(bag, slot)
        if isQuest or questID then return true end
    end
    -- Localized tooltip covers quest starters and quest-bound items, too.
    self.tip:SetOwner(UIParent, "ANCHOR_NONE")
    self.tip:ClearLines()
    self.tip:SetBagItem(bag, slot)
    local lines = self.tip:NumLines()
    if not lines or lines == 0 then self.tip:Hide(); return true end
    for i = 1, lines do
        local fs = _G["BagBinScanTooltipTextLeft" .. i]
        local text = fs and fs:GetText()
        if text and ((ITEM_BIND_QUEST and string.find(text, ITEM_BIND_QUEST, 1, true))
            or (ITEM_STARTS_QUEST and string.find(text, ITEM_STARTS_QUEST, 1, true))) then
            self.tip:Hide(); return true
        end
    end
    self.tip:Hide()
    return false
end

function B:Candidate(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    local id = link and tonumber(string.match(link, "item:(%d+)"))
    if not id or self.hardKeep[id] or self.db.keep[id] then return nil end
    local _, count, locked = GetContainerItemInfo(bag, slot)
    if locked or not count or count < 1 then return nil end
    local name, _, quality, _, _, itemType, _, maxStack, _, _, price = GetItemInfo(link)
    if not name or not quality or not maxStack or maxStack < 1 or not price or price <= 0 then return nil end
    -- Higher quality is always protected. Whites require a per-item opt-in.
    if quality ~= 0 and not (quality == 1 and self.db.extra[id]) then return nil end
    if price * maxStack >= self.db.threshold then
        local partial = self:PartialCandidate(bag, slot)
        if partial and self:PartialRemaining(partial) == 0 then partial.aged = true; return partial end
        return nil
    end
    if self:QuestItem(bag, slot, itemType) then return nil end
    return {bag = bag, slot = slot, id = id, link = link, name = name,
        count = count, full = price * maxStack, maxStack = maxStack, value = price * count}
end

function B:Scan()
    self:ObserveStacks()
    local rows, value = {}, 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local item = self:Candidate(bag, slot)
            if item then rows[#rows + 1] = item; value = value + item.value end
        end
    end
    table.sort(rows, function(a, b)
        if a.value ~= b.value then return a.value < b.value end
        if a.bag ~= b.bag then return a.bag < b.bag end
        return a.slot < b.slot
    end)
    return rows, value
end

function B:FreeSlots()
    local free = 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            if not GetContainerItemLink(bag, slot) then free = free + 1 end
        end
    end
    return free
end

function B:PartialCandidate(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    local id = link and tonumber(string.match(link, "item:(%d+)"))
    if not id or self.hardKeep[id] or self.db.keep[id] then return nil end
    local _, count, locked = GetContainerItemInfo(bag, slot)
    if locked or not count or count < 1 then return nil end
    local name, _, quality, _, _, itemType, _, maxStack, _, _, price = GetItemInfo(link)
    if not name or quality ~= 0 or not maxStack or maxStack <= count or not price or price <= 0 then return nil end
    if price * maxStack < self.db.threshold or price * count >= self.db.threshold or self:QuestItem(bag, slot, itemType) then return nil end
    return {bag=bag, slot=slot, id=id, link=link, name=name, count=count,
        full=price * maxStack, maxStack=maxStack, value=price * count}
end

function B:ScanPartial()
    self:ObserveStacks()
    local rows, value = {}, 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local item = self:PartialCandidate(bag, slot)
            if item then rows[#rows + 1] = item; value = value + item.value end
        end
    end
    table.sort(rows, function(a, b)
        if a.value ~= b.value then return a.value < b.value end
        if a.bag ~= b.bag then return a.bag < b.bag end
        return a.slot < b.slot
    end)
    return rows, value
end

-- Session-only ages: uncertain identity (moving/splitting stacks) starts a fresh wait.
function B:ObserveStacks()
    if not self.db then return end
    self.partialWatch = self.partialWatch or {}
    local current, now = {}, GetTime()
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            local _, count, locked = GetContainerItemInfo(bag, slot)
            if link and count then
                local key = bag .. ":" .. slot
                local old = self.partialWatch[key]
                current[key] = old and old.link == link and old.count == count and not locked
                    and old or {link=link, count=count, since=now}
            end
        end
    end
    self.partialWatch = current
end

function B:PartialRemaining(item)
    local record = self.partialWatch and self.partialWatch[item.bag .. ":" .. item.slot]
    if not record or record.link ~= item.link or record.count ~= item.count then
        return self.db.partialMinutes * 60
    end
    return math.max(0, math.ceil(self.db.partialMinutes * 60 - (GetTime() - record.since)))
end

function B:SetPartialMinutes(text)
    local minutes = tonumber(text)
    if not minutes or minutes ~= minutes or minutes < 1 or minutes > 60 or minutes ~= math.floor(minutes) then
        self:Print("Таймер неполных стаков: целое число от 1 до 60 минут."); return
    end
    if self.run then self:Finish("Таймер изменён.") end
    self.db.partialMinutes = minutes
    self:Print("Таймер неполных стаков: " .. minutes .. " мин.")
    self:Refresh()
end

function B:WhiteGearCandidate(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    local id = link and tonumber(string.match(link, "item:(%d+)"))
    if not id or self.hardKeep[id] or self.db.keep[id] then return nil end
    local _, count, locked = GetContainerItemInfo(bag, slot)
    if locked or not count or count < 1 then return nil end
    local name, _, quality, _, _, itemType, _, maxStack, _, equipSlot, price = GetItemInfo(link)
    if not name or quality ~= 1 or (itemType ~= "Armor" and itemType ~= "Weapon") then return nil end
    if self:QuestItem(bag, slot, itemType) then return nil end
    return {bag=bag, slot=slot, id=id, link=link, name=name, count=count,
        full=(price or 0) * (maxStack or 1), maxStack=maxStack or 1, value=(price or 0) * count,
        equipSlot=equipSlot}
end

function B:ScanWhiteGear()
    local rows, value = {}, 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local item = self:WhiteGearCandidate(bag, slot)
            if item then rows[#rows + 1] = item; value = value + item.value end
        end
    end
    table.sort(rows, function(a, b) if a.name ~= b.name then return a.name < b.name end return a.slot < b.slot end)
    return rows, value
end

function B:Busy()
    if InCombatLockdown() or UnitAffectingCombat("player") then return "идёт бой" end
    if UnitIsDeadOrGhost("player") then return "персонаж мёртв" end
    if GetCursorInfo() then return "курсор занят" end
    if self.looting or self.merchant or self.bank or self.trade or self.mail or self.auction then
        return "закройте лут, торговлю, почту и банк"
    end
end

function B:SaveInstanceDecision(request, allowed)
    if not request or request ~= self.instanceRequest or not self.db.auto then return end
    self:CheckInstance()
    if request ~= self.instanceRequest or request.key ~= self.instanceKey then return end
    if type(self.db.instanceDecisions) ~= "table" then self.db.instanceDecisions = {} end
    local record = self.db.instanceDecisions[request.key]
    if type(record) ~= "table" then record = {}; self.db.instanceDecisions[request.key] = record end
    record.allowed = allowed
    record.decidedAt = time()
    self.instanceRequest = nil
    self.instanceAutoAllowed = allowed
    self.pending = nil
    self:Print("Автоочистка " .. (allowed and "разрешена" or "запрещена") .. " на 24 часа: " .. request.name .. ".")
    if allowed and self.lootPending then self:Schedule() end
end

function B:CheckInstance()
    if not IsInInstance or not self.db then return end
    local inInstance, instanceType = IsInInstance()
    local name = GetInstanceInfo and select(1, GetInstanceInfo()) or nil
    local inside = inInstance and (instanceType == "party" or instanceType == "raid")
    if not inside then
        self.instanceRequest = nil
        StaticPopup_Hide("BAGBIN_INSTANCE_CONFIRM")
        self.instanceKey = nil; self.instanceAutoAllowed = true; self.instancePrompt = nil
        return
    end
    local key = tostring(instanceType) .. ":" .. tostring(name or "Подземелье")
    if self.instanceKey ~= key then
        self.instanceRequest = nil
        StaticPopup_Hide("BAGBIN_INSTANCE_CONFIRM")
    end
    self.instanceKey = key; self.instanceAutoAllowed = false; self.instancePrompt = true
    local record = type(self.db.instanceDecisions) == "table" and self.db.instanceDecisions[key]
    local now = time()
    if type(record) == "table" and type(record.allowed) == "boolean"
        and type(record.decidedAt) == "number" and now >= record.decidedAt
        and now - record.decidedAt < 86400 then
        self.instanceAutoAllowed = record.allowed
        return
    end
    self.pending = nil
    if self.db.auto and not self.instanceRequest and name and name ~= "" then
        local request = {key = key, name = name}
        self.instanceRequest = request
        if not StaticPopup_Show("BAGBIN_INSTANCE_CONFIRM", name, self:Money(self.db.threshold), request) then
            self.instanceRequest = nil
        end
    end
end

function B:Finish(reason, failed)
    local run = self.run
    self.run = nil
    if failed then self.fault = true; self.pending = nil end
    if run and (run.removed > 0 or run.manual or reason) then
        self:Print("Освобождено мест: " .. run.removed .. ". Цена удалённого: " .. self:Money(run.value) .. "."
            .. (reason and (" " .. reason) or ""))
    end
    if failed then self:Print("Автоочистка приостановлена до /reload. Предметы повторно не удаляются.") end
    if self.Refresh then self:Refresh() end
end

function B:Start(manual, mode, selectedBag, selectedSlot)
    if not self.db or self.run then return end
    if not manual and self.CheckVendorOffer and self:CheckVendorOffer() then return end
    if not manual then self:CheckInstance() end
    if (mode == "partial" or mode == "whitegear") and not manual then return end
    if self.fault then if manual then self:Print("После ошибки нужен /reload.") end; return end
    local reason = self:Busy()
    if reason then if manual then self:Print("Очистка не начата: " .. reason .. ".") end; return end
    if not manual and (not self.db.auto or (self.window and self.window:IsShown()) or (self.instancePrompt and not self.instanceAutoAllowed)) then return end
    local free = self:FreeSlots()
    if not manual and free >= self.db.reserveSlots then return end
    self.pending = nil
    self.lootPending = nil
    local rows = mode == "partial" and self:ScanPartial() or mode == "whitegear" and self:ScanWhiteGear() or self:Scan()
    if selectedBag and selectedSlot then
        local selected = {}
        for _, item in ipairs(rows) do if item.bag == selectedBag and item.slot == selectedSlot then selected[1] = item; break end end
        rows = selected
    end
    if not manual then
        local need = self.db.reserveSlots - free
        while #rows > need do rows[#rows] = nil end
    end
    if #rows == 0 then if manual then self:Print(mode == "partial" and "Этот неполный стак больше не подходит для удаления." or mode == "whitegear" and "Этот белый предмет больше не найден в сумках." or "Нет хлама дешевле порога.") end; return end
    self.run = {queue = rows, index = 1, removed = 0, value = 0, manual = manual,
        partial = mode == "partial", whitegear = mode == "whitegear", untilTime = GetTime() + 60, nextTime = GetTime()}
end

function B:Step()
    local run = self.run
    if not run then return end
    local now = GetTime()
    if now < run.nextTime then return end
    -- Verify the previous deletion before counting it or touching another slot.
    if run.verify then
        local item = run.verify
        if not GetContainerItemLink(item.bag, item.slot) and not GetCursorInfo() then
            run.removed = run.removed + 1; run.value = run.value + item.value
            run.verify = nil
        elseif now >= run.verifyUntil then
            self:Finish("Удаление не подтверждено. Проверьте сумку и курсор.", true); return
        else return end
    end
    if now >= run.untilTime then self:Finish("Достигнут лимит времени."); return end
    if not run.manual then
        self:CheckInstance()
        if self.instancePrompt and not self.instanceAutoAllowed then
            self:Finish("Автоочистка в подземелье не разрешена."); return
        end
    end
    local reason = self:Busy()
    if reason then self:Finish("Остановлено: " .. reason .. "."); return end
    if not run.manual and self.CheckVendorOffer and self:CheckVendorOffer() then return end
    if not run.manual and self:FreeSlots() >= self.db.reserveSlots then self:Finish(); return end
    self:ObserveStacks()
    local planned = run.queue[run.index]
    if not planned then self:Finish(); return end
    run.index = run.index + 1
    run.nextTime = now + 0.25
    local item = run.partial and self:PartialCandidate(planned.bag, planned.slot)
        or run.whitegear and self:WhiteGearCandidate(planned.bag, planned.slot)
        or self:Candidate(planned.bag, planned.slot)
    if not item or item.link ~= planned.link or item.count ~= planned.count then return end
    -- Never delete whatever happened to be on the user's cursor.
    PickupContainerItem(item.bag, item.slot)
    local kind, cursorID, cursorLink = GetCursorInfo()
    if kind ~= "item" or cursorID ~= item.id or cursorLink ~= item.link then
        self:Finish("Предмет на курсоре не совпал с выбранным. Проверьте курсор.", true); return
    end
    local ok = pcall(DeleteCursorItem)
    if not ok or GetCursorInfo() then
        -- Return only the exact item we just picked up; never clear an unrelated cursor.
        local k, id, link = GetCursorInfo()
        if k == "item" and id == item.id and link == item.link then ClearCursor() end
        self:Finish("Клиент не разрешил удаление.", true); return
    end
    run.verify = item; run.verifyUntil = now + 2
end

function B:Schedule()
    if not self.db or not self.db.auto or self.fault or self.run then return end
    self.pending = {at = GetTime() + 1, expires = GetTime() + 30}
end

function B:SetReserveSlots(text)
    local value = tonumber(string.gsub(text or "", ",", "."))
    if not value or value ~= value or value < 0 or value > 100 or value ~= math.floor(value) then
        self:Print("Минимум свободных мест: целое число от 0 до 100."); return
    end
    if self.run then self:Finish("Резерв свободных мест изменён.") end
    self.db.reserveSlots = value
    self:Print("Резерв свободных мест: " .. value .. ". Автоочистка начнётся только ниже этого значения.")
    self:Refresh()
end

function B:MasterLootTargets()
    local rows, seen = {}, {}
    local player = UnitName("player")
    if player and player ~= "" then
        rows[#rows + 1] = {name = player, label = player .. " (игрок)"}; seen[player] = true
    end
    local storage = self:MasterAltStorage()
    if storage then
        for name, active in pairs(storage.names or {}) do
            if type(name) == "string" and name ~= "" and not seen[name] and active == true then
                rows[#rows + 1] = {name = name, label = name .. " (альт)"}; seen[name] = true
            end
        end
    end
    table.sort(rows, function(a, b)
        if player and a.name == player then return true end
        if player and b.name == player then return false end
        return a.name < b.name
    end)
    return rows
end

-- Read-only access to legacy recipient lists for UnBot migration.
function B:MasterAltStorage()
    local realm, player = GetRealmName and GetRealmName(), UnitName("player")
    local master = self.db and self.db.masterLoot
    local realms = type(master) == "table" and master.altLists
    local players = type(realms) == "table" and realms[realm]
    return type(players) == "table" and players[player] or nil
end

function B:SetAuto(enabled)
    self.db.auto = enabled and true or false
    self.pending = nil
    if not self.db.auto then
        self.instanceRequest = nil
        StaticPopup_Hide("BAGBIN_INSTANCE_CONFIRM")
    end
    self:CheckInstance()
    if self.run then self:Finish("Настройки изменены.") end
    self:Print("Автоочистка " .. (self.db.auto and "включена: после следующего лута." or "выключена."))
    self:Refresh()
end

function B:SetThreshold(text)
    local silver = tonumber((string.gsub(text or "", ",", ".")))
    local copper = silver and silver * 100 or nil
    if not copper or copper ~= copper or copper < 1 or copper > 1000000 then
        self:Print("Введите три целых поля: золото, серебро и медь."); return
    end
    if self.run then self:Finish("Порог изменён.") end
    self.db.threshold = math.floor(copper + 0.5)
    self:Print("Порог полного стака: " .. self:Money(self.db.threshold) .. ".")
    self:Refresh()
end

function B:SetThresholdParts(goldText, silverText, copperText)
    local gold = tonumber(goldText) or 0
    local silver = tonumber(silverText) or 0
    local copper = tonumber(copperText) or 0
    if gold ~= math.floor(gold) or silver ~= math.floor(silver) or copper ~= math.floor(copper)
        or gold < 0 or silver < 0 or silver > 99 or copper < 0 or copper > 99
        or gold > 10000 then
        self:Print("Введите целые значения: золото 0-10000, серебро и медь 0-99."); return
    end
    local total = gold * 10000 + silver * 100 + copper
    if total < 1 or total > 100000000 then self:Print("Порог должен быть от 1 меди до 10000 золотых."); return end
    if self.run then self:Finish("Порог изменён.") end
    self.db.threshold = total
    self:Print("Порог полного стака: " .. self:Money(total) .. ".")
    self:Refresh()
end

function B:EditList(action, text)
    local id = tonumber(string.match(text or "", "item:(%d+)")) or tonumber(text)
    if not id or id < 1 or id ~= math.floor(id) then self:Print("Вставьте ссылку на предмет или его числовой ID."); return false end
    if self.run then self:Finish("Список изменён.") end
    if action == "keep" then
        self.db.keep[id] = true
        self:Print("Добавлен в исключения: " .. (select(2, GetItemInfo(id)) or tostring(id)) .. ". Очистка BagBin его не удалит.")
    elseif action == "extra" then
        local _, _, quality = GetItemInfo(id)
        if quality ~= 1 or self.hardKeep[id] then self:Print("Добавлять можно только известные клиенту белые предметы, кроме камней возвращения."); return false end
        if self.db.keep[id] then self:Print("Сначала уберите предмет из исключений."); return false end
        self.db.extra[id] = true
        self:Print("Разрешён белый предмет: " .. (select(2, GetItemInfo(id)) or tostring(id)) .. ".")
    elseif action == "unkeep" then self.db.keep[id] = nil
    elseif action == "unextra" then self.db.extra[id] = nil end
    if action == "unkeep" then self:Print("Убран из исключений: " .. (select(2, GetItemInfo(id)) or tostring(id)) .. ". Теперь он снова может попасть под очистку.")
    elseif action == "unextra" then self:Print("Убрано разрешение белого предмета: " .. (select(2, GetItemInfo(id)) or tostring(id)) .. ".") end
    self:Refresh()
    return true
end

B.frame:SetScript("OnUpdate", function()
    if B.db and B.VendorTick then B:VendorTick() end
    if B.db and GetTime() >= (B.partialTick or 0) then
        B.partialTick = GetTime() + 1
        B:ObserveStacks()
        if B.window and B.window:IsShown() then
            if B.tab == "partial" or B.tab == "candidates" then B:Refresh() end
        elseif B.db.auto and not B.run and not B.pending and not B:Busy()
            and B:FreeSlots() < B.db.reserveSlots then
            for _, item in ipairs(B:ScanPartial()) do
                if B:PartialRemaining(item) == 0 then B:Schedule(); break end
            end
        end
    end
    if B.run then B:Step()
    elseif B.pending then
        local now = GetTime()
        if now > B.pending.expires then B.pending = nil
        elseif now >= B.pending.at then
            B.pending.at = now + 1
            if not B:Busy() and not (B.window and B.window:IsShown()) then B:Start(false) end
        end
    end
end)

B.frame:SetScript("OnEvent", function(_, event, payload, ...)
    if event == "ADDON_LOADED" and payload == "BagBin" then B:Init(); B:CreateLauncher()
    elseif event == "LOOT_OPENED" then B.looting = true
    elseif event == "LOOT_CLOSED" then B.looting = nil; B.lootPending = true; B:Schedule()
    elseif event == "BAG_UPDATE" then B:ObserveStacks(); B:Schedule()
    elseif event == "PLAYER_REGEN_ENABLED" and B.lootPending then B.lootPending = nil; B:Schedule()
    elseif event == "MERCHANT_SHOW" then B.merchant = true
    elseif event == "MERCHANT_CLOSED" then B.merchant = nil
    elseif event == "BANKFRAME_OPENED" then B.bank = true
    elseif event == "BANKFRAME_CLOSED" then B.bank = nil
    elseif event == "TRADE_SHOW" then B.trade = true
    elseif event == "TRADE_CLOSED" then B.trade = nil
    elseif event == "MAIL_SHOW" then B.mail = true
    elseif event == "MAIL_CLOSED" then B.mail = nil
    elseif event == "AUCTION_HOUSE_SHOW" then B.auction = true
    elseif event == "AUCTION_HOUSE_CLOSED" then B.auction = nil
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        B:CheckInstance()
        if event ~= "PLAYER_ENTERING_WORLD" then return end
        B.pending = nil; B.lootPending = nil
        B.looting = nil; B.merchant = nil; B.bank = nil; B.trade = nil; B.mail = nil; B.auction = nil
        if B.run then B:Finish("Смена зоны.") end
    end
end)
for _, event in ipairs({"ADDON_LOADED", "LOOT_OPENED", "LOOT_CLOSED", "BAG_UPDATE", "PLAYER_REGEN_ENABLED", "ZONE_CHANGED_NEW_AREA",
    "MERCHANT_SHOW", "MERCHANT_CLOSED", "BANKFRAME_OPENED", "BANKFRAME_CLOSED",
    "TRADE_SHOW", "TRADE_CLOSED", "MAIL_SHOW", "MAIL_CLOSED", "AUCTION_HOUSE_SHOW",
    "AUCTION_HOUSE_CLOSED", "PLAYER_ENTERING_WORLD"}) do B.frame:RegisterEvent(event) end

SLASH_BAGBIN1 = "/bagbin"
SLASH_BAGBIN2 = "/bbin"
SlashCmdList.BAGBIN = function(text)
    if not B.db then return end
    local command, rest = string.match(text or "", "^(%S*)%s*(.-)%s*$")
    if command == "clean" then B:Start(true)
    elseif command == "vendor" and B.CheckVendorOffer then B:CheckVendorOffer(true)
    elseif command == "on" then B:SetAuto(true)
    elseif command == "off" then B:SetAuto(false)
    elseif command == "threshold" then B:SetThreshold(rest)
    elseif command == "keep" or command == "extra" or command == "unkeep" or command == "unextra" then B:EditList(command, rest)
    else B:Toggle() end
end
