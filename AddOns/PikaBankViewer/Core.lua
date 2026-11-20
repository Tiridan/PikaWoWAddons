-- BEGIN STANDALONE LING SCANNER
---@diagnostic disable: undefined-global
-- Standalone scanner and diagnostics for Ling. No DialogUI presentation required.
--
-- The server exposes the bank as a gossip tree: a fixed category menu followed
-- by one or more pages of item links.  The scanner deliberately selects only a
-- category, "Next Page", or "Back...".  It never selects an item or the
-- "Deposit All Reagents" action. Withdrawals belong to the separate controller.

PikaBankScanner = PikaBankScanner or {};
local RS = PikaBankScanner;

RS.schema = 1;
RS.maxActions = 300;
RS.timeoutSeconds = 120;
RS.actionDelay = 0.12;
RS.resultsPerPage = 9;
RS.lingFrameScaleFactor = 0.78;

local CYRILLIC_LOWER = {
    ["А"]="а", ["Б"]="б", ["В"]="в", ["Г"]="г", ["Д"]="д", ["Е"]="е", ["Ё"]="ё",
    ["Ж"]="ж", ["З"]="з", ["И"]="и", ["Й"]="й", ["К"]="к", ["Л"]="л", ["М"]="м",
    ["Н"]="н", ["О"]="о", ["П"]="п", ["Р"]="р", ["С"]="с", ["Т"]="т", ["У"]="у",
    ["Ф"]="ф", ["Х"]="х", ["Ц"]="ц", ["Ч"]="ч", ["Ш"]="ш", ["Щ"]="щ", ["Ъ"]="ъ",
    ["Ы"]="ы", ["Ь"]="ь", ["Э"]="э", ["Ю"]="ю", ["Я"]="я",
};

local VALID_ANCHOR_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
};

local function Lower(text)
    text = string.lower(tostring(text or ""));
    for upper, lower in pairs(CYRILLIC_LOWER) do
        text = string.gsub(text, upper, lower);
    end
    return text;
end

local function CleanText(text)
    text = tostring(text or "");
    text = string.gsub(text, "|T.-|t", "");
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "");
    text = string.gsub(text, "|r", "");
    text = string.gsub(text, "|H.-|h(.-)|h", "%1");
    text = string.gsub(text, "^%s+", "");
    text = string.gsub(text, "%s+$", "");
    return text;
end

local function OptionKey(text)
    local clean = Lower(CleanText(text));
    clean = string.gsub(clean, "[%s%.]+$", "");
    return clean;
end

local function GetOptions()
    local values = { GetGossipOptions() };
    local options = {};
    for i = 1, #values, 2 do
        local raw = values[i] or "";
        table.insert(options, {
            raw = raw,
            text = CleanText(raw),
            key = OptionKey(raw),
            iconType = values[i + 1],
            originalIndex = ((i + 1) / 2),
            itemID = tonumber(string.match(raw, "|Hitem:(%d+)")),
            texture = RS:IconFromOption(raw),
        });
    end
    return options;
end

local function FindOption(options, key)
    key = Lower(key or "");
    for _, option in ipairs(options) do
        if (option.key == key) then
            return option;
        end
    end
    return nil;
end

local function IsRootMenu(options)
    return FindOption(options, "deposit all reagents") ~= nil;
end

local function IsBack(option)
    return option and (option.key == "back" or option.key == "назад");
end

local function IsNext(option)
    return option and (option.key == "next page" or option.key == "следующая страница");
end

local function IsPrevious(option)
    return option and (option.key == "previous page" or option.key == "предыдущая страница");
end

local function ParseNPCEntry(guid)
    if (not guid) then return nil; end
    local hex = guid;
    if (string.sub(hex, 1, 2) == "0x" or string.sub(hex, 1, 2) == "0X") then
        hex = string.sub(hex, 3);
    end
    while (string.len(hex) < 16) do hex = "0" .. hex; end
    if (string.upper(string.sub(hex, 1, 1)) ~= "F") then return nil; end
    return tonumber(string.sub(hex, 7, 10), 16);
end

local function CurrentCacheKey()
    local realm = (GetRealmName and GetRealmName()) or "realm";
    local player = UnitName("player") or "player";
    local entry = ParseNPCEntry(UnitGUID("npc"));
    return realm .. ":" .. player .. ":" .. tostring(entry or Lower(UnitName("npc") or "ling"));
end

local function EnsureSettings()
    if (not PikaBankViewerDB) then PikaBankViewerDB = {}; end
    if (not PikaBankViewerDB.reagentSearchBanks) then
        PikaBankViewerDB.reagentSearchBanks = {};
    end
    return PikaBankViewerDB.reagentSearchBanks;
end

function RS:IsBusy()
    return self.scan ~= nil or self.navigation ~= nil;
end

function RS:IsLing(options)
    return Lower(UnitName("npc") or "") == "ling";
end

function RS:IsReachable()
    return self:IsLing() and (not CheckInteractDistance or CheckInteractDistance("npc", 1)) and true or false;
end

function RS:OutOfRange()
    if self:IsBusy() or (PikaBankViewer and PikaBankViewer.online) then
        local closeNPC = self:IsLing();
        self:TraceWrite("LING_OUT_OF_RANGE");
        self:OnGossipClosed();
        -- A local distance check can precede the server's GOSSIP_CLOSED.
        -- End the actual interaction too, otherwise the next click may retain it.
        if closeNPC then CloseGossip(); end
        if PikaBankViewer and PikaBankViewer.mode == "ling" and PikaBankViewer.frame then
            PikaBankViewer.frame:Hide();
        end
    end
end

function RS:GetIndex()
    if (not self.cacheKey) then return nil; end
    local banks = PikaBankViewerDB and PikaBankViewerDB.reagentSearchBanks;
    local index = banks and banks[self.cacheKey];
    if (index and index.schema == self.schema and index.complete and index.items) then
        return index;
    end
    return nil;
end

function RS:SetStatus(text, r, g, b)
    self.status = text;
    if PikaBankViewer and PikaBankViewer.Refresh then PikaBankViewer:Refresh(); end
end

function RS:SuspendAutoSelect() end
function RS:RestoreAutoSelect() end
function RS:RefreshScanButton() end
function RS:RefreshResults() end

function RS:CancelPending()
    self.pending = nil;
end

function RS:QueueSelect(option, transitionText)
    if (not option or self.pending) then return false; end
    local busy = self.scan or self.navigation;
    if (not busy) then return false; end
    if (busy.actions >= self.maxActions) then
        self:Abort("Превышен безопасный лимит переходов.");
        return false;
    end
    self.pending = {
        due = GetTime() + (busy.actionDelay or self.actionDelay),
        optionIndex = option.originalIndex,
        optionKey = option.key,
        itemID = option.itemID,
        transitionText = transitionText,
    };
    return true;
end

function RS:Abort(reason)
    self:TraceWrite("SCANNER_ABORT", { reason = reason });
    local hadScan = self.scan ~= nil;
    self.scan = nil;
    self.navigation = nil;
    self:CancelPending();
    self:RestoreAutoSelect();
    if (self.scanButton) then self.scanButton:Enable(); end
    if (hadScan and reason) then
        self:SetStatus(reason .. " Старый индекс сохранён.", 1.0, 0.45, 0.35);
    elseif (reason) then
        self:SetStatus(reason, 1.0, 0.45, 0.35);
    end
    self:RefreshScanButton();
end

function RS:BuildCategories(options)
    local categories = {};
    for _, option in ipairs(options) do
        if (not option.itemID and option.key ~= "deposit all reagents" and not IsBack(option)
                and not IsNext(option) and not IsPrevious(option)) then
            table.insert(categories, {
                text = option.text,
                key = option.key,
            });
        end
    end
    return categories;
end

function RS:FindCategoryOption(options, category)
    for _, option in ipairs(options) do
        if (option.key == category.key) then return option; end
    end
    return nil;
end

function RS:StorePageItems(options)
    local scan = self.scan;
    local category = scan.categories[scan.categoryIndex];
    for _, option in ipairs(options) do
        if (option.itemID) then
            local name = string.match(option.raw, "|h%[([^%]]+)%]|h");
            name = name or option.text;
            name = string.gsub(name, "^%[", "");
            name = string.gsub(name, "%]%s*%(%d+%)%s*$", "");
            local amount = tonumber(string.match(option.text, "%((%d+)%)%s*$")) or 0;
            if scan.strictCounts and not tonumber(string.match(option.text, "%((%d+)%)%s*$")) then
                self:Abort("Не удалось прочитать точное количество ресурса " .. option.itemID .. "."); return;
            end
            local seenKey = tostring(option.itemID);
            local existing = scan.seen[seenKey];
            local item = {
                id = option.itemID,
                texture = option.texture,
                name = name,
                amount = amount,
                category = category.text,
                categoryKey = category.key,
                page = scan.page,
            };
            if existing and scan.strictCounts then
                self:Abort("Повтор ресурса в полном снимке: " .. option.itemID .. "."); return;
            end
            if (existing) then
                scan.items[existing] = item;
            else
                table.insert(scan.items, item);
                scan.seen[seenKey] = #scan.items;
            end
        end
    end
end

function RS:CompleteScan()
    local scan = self.scan;
    table.sort(scan.items, function(a, b)
        return Lower(a.name) < Lower(b.name);
    end);
    local banks = EnsureSettings();
    banks[self.cacheKey] = {
        schema = self.schema,
        complete = true,
        scannedAt = time(),
        npc = UnitName("npc") or "Ling",
        categories = scan.categories,
        items = scan.items,
    };
    local count = #scan.items;
    self:TraceWrite("SCAN_COMPLETE", { count = count, actions = scan.actions });
    self.scan = nil;
    self:CancelPending();
    self:RestoreAutoSelect();
    self:SetStatus("Индекс готов: " .. count .. " реагентов. Введите название.", 0.45, 1.0, 0.55);
    self:RefreshScanButton();
    self:RefreshResults();
end

function RS:ProcessScan(options)
    local scan = self.scan;
    if (not scan) then return; end
    if (GetTime() > scan.deadline) then
        self:Abort("Сервер не успел ответить за " .. self.timeoutSeconds .. " сек.");
        return;
    end

    if (scan.phase == "toRoot") then
        if (IsRootMenu(options)) then
            scan.categories = self:BuildCategories(options);
            if (#scan.categories == 0) then
                self:Abort("Не удалось распознать категории Ling.");
                return;
            end
            scan.phase = "categories";
            scan.categoryIndex = 1;
            scan.page = 0;
        else
            local back;
            for _, option in ipairs(options) do
                if (IsBack(option)) then
                    back = option;
                    break
                end
            end
            if (back) then
                self:SetStatus("Возвращаюсь к списку категорий...");
                self:QueueSelect(back, "root");
            else
                self:Abort("Это меню не похоже на банк реагентов Ling.");
            end
            return;
        end
    end

    if (IsRootMenu(options)) then
        if (scan.categoryIndex > #scan.categories) then
            self:CompleteScan();
            return;
        end
        local category = scan.categories[scan.categoryIndex];
        local option = self:FindCategoryOption(options, category);
        if (not option) then
            self:Abort("Категория «" .. category.text .. "» исчезла с сервера.");
            return;
        end
        scan.page = 0;
        self:SetStatus("Сканирование " .. scan.categoryIndex .. "/" .. #scan.categories .. ": " .. category.text);
        self:QueueSelect(option, "category");
        return;
    end

    local back;
    local nextPage;
    for _, option in ipairs(options) do
        if (IsBack(option)) then back = option;
        elseif (IsNext(option)) then nextPage = option;
        end
    end
    if (not back) then
        self:Abort("Получена неизвестная страница; сканирование остановлено безопасно.");
        return;
    end

    self:StorePageItems(options);
    if not self.scan then return; end
    if (nextPage) then
        scan.page = scan.page + 1;
        self:QueueSelect(nextPage, "next");
    else
        scan.categoryIndex = scan.categoryIndex + 1;
        scan.page = 0;
        self:QueueSelect(back, "root");
    end
end

function RS:StartScan(fastRead)
    if (self.scan) then
        self:Abort("Сканирование остановлено.");
        return;
    end
    if (self.navigation) then
        self:Abort("Переход отменён.");
    end
    if ((InCombatLockdown and InCombatLockdown()) or UnitAffectingCombat("player")) then
        self:SetStatus("Сканирование недоступно в бою.", 1.0, 0.45, 0.35);
        return;
    end
    local options = GetOptions();
    if (not self:IsReachable()) then
        self:SetStatus("Сначала откройте диалог с Ling.", 1.0, 0.45, 0.35);
        return;
    end
    self.cacheKey = CurrentCacheKey();
    self:SuspendAutoSelect();
    self.scan = {
        phase = "toRoot",
        -- Bot deposits still read every category/page, but do not wait twice
        -- between acknowledged read-only transitions. Normal scans keep their pace.
        actionDelay = fastRead == true and 0.04 or self.actionDelay,
        immediateReplies = fastRead == true,
        strictCounts = fastRead == true,
        categories = nil,
        categoryIndex = 0,
        page = 0,
        items = {},
        seen = {},
        actions = 0,
        deadline = GetTime() + self.timeoutSeconds,
    };
    self:SetStatus("Начинаю безопасное сканирование...");
    self:TraceWrite("SCAN_START", { cacheKey = self.cacheKey });
    self:RefreshScanButton();
    self:ProcessScan(options);
end

function RS:Matches(item, query)
    if (query == "") then return true; end
    local haystack = Lower(item.name .. " " .. item.category);
    for token in string.gmatch(Lower(query), "%S+") do
        if (not string.find(haystack, token, 1, true)) then return false; end
    end
    return true;
end

RS.traceMaxEvents = 5000;
RS.traceDuration = 600;

function RS:TracePrint(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff80dfff[Ling debug]|r " .. text);
end

function RS:TraceText(value)
    local text = tostring(value or "");
    if (#text > 2048) then return string.sub(text, 1, 2048) .. " <truncated>"; end
    return text;
end

function RS:TraceWrite(kind, data)
    if (not self.traceActive) then return; end
    local db = PikaBankViewerDB.reagentTrace;
    if (#db.events >= self.traceMaxEvents) then
        self:TraceStop("event_limit");
        return;
    end
    data = data or {};
    data.event = kind;
    data.at = time();
    data.elapsed = math.floor((GetTime() - self.traceStarted) * 1000 + 0.5) / 1000;
    data.session = db.session;
    data.menu = self.traceMenuSerial;
    data.mode = self.scan and "scan" or (self.navigation and "navigation" or "idle");
    db.events[#db.events + 1] = data;
end

function RS:TraceInventory(reason, baseline)
    if (not self.traceActive) then return; end
    local counts, links = {}, {};
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot);
            local id = link and tonumber(string.match(link, "item:(%d+)"));
            if (id) then
                local _, count = GetContainerItemInfo(bag, slot);
                counts[id] = (counts[id] or 0) + (count or 0);
                links[id] = link;
            end
        end
    end
    local previous = self.traceBags or {};
    self.traceBags = counts;
    if (baseline) then
        self:TraceWrite("BAGS_BASELINE", { reason = reason, counts = counts });
        return;
    end
    local changes = {};
    for id, count in pairs(counts) do
        if (count ~= (previous[id] or 0)) then
            changes[#changes + 1] = { id = id, before = previous[id] or 0,
                after = count, delta = count - (previous[id] or 0), link = links[id] };
        end
    end
    for id, count in pairs(previous) do
        if (not counts[id]) then
            changes[#changes + 1] = { id = id, before = count, after = 0, delta = -count };
        end
    end
    if (#changes > 0) then
        table.sort(changes, function(a, b) return a.id < b.id; end);
        self:TraceWrite("BAGS_DELTA", { reason = reason, changes = changes });
    end
end

function RS:TraceGossip(options)
    if (not self.traceActive) then return; end
    -- Do not use IsLing's "scanner busy" fallback to identify a new NPC.
    if (not self:IsLing()) then
        if (self.traceOpen or self.traceUntil) then
            self:TraceWrite("OTHER_NPC_OPENED");
        end
        self.traceOpen, self.traceUntil, self.traceSampleAt = nil, nil, nil;
        self.traceMenu = nil;
        return;
    end
    if (not self.traceOpen and not self.traceUntil) then
        self:TraceInventory("Ling opened", true);
    else
        self:TraceInventory("GOSSIP_SHOW");
    end
    self.traceOpen, self.traceUntil = true, nil;
    self.traceMenuSerial = (self.traceMenuSerial or 0) + 1;
    local menu = {};
    for i = 1, math.min(#options, 64) do
        local option = options[i];
        menu[i] = { index = option.originalIndex, raw = self:TraceText(option.raw),
            itemID = option.itemID, iconType = option.iconType,
            amount = tonumber(string.match(option.text, "%((%d+)%)%s*$")) };
    end
    self.traceMenu = menu;
    self:TraceWrite("GOSSIP_SHOW", { npc = UnitName("npc"), guid = UnitGUID("npc"),
        cacheKey = CurrentCacheKey(), greeting = self:TraceText(GetGossipText()),
        options = menu, optionCount = #options, truncated = #options > 64 });
end

function RS:TraceSelected(index, code)
    if (not self.traceActive or not self.traceMenu) then return; end
    if (not self.traceOpen and (not self.traceClosedAt or GetTime() - self.traceClosedAt > 0.2)) then return; end
    -- Secure post-hook: use the last received menu, never call SelectGossipOption here.
    local option = self.traceMenu[tonumber(index) or 0];
    self:TraceWrite("SELECT_GOSSIP_OPTION", { index = index, option = option,
        code = code ~= nil and self:TraceText(code) or nil,
        source = self.scan and "scanner" or (self.navigation and "search_navigation" or "outside_scanner") });
    self.traceSampleAt = GetTime() + 0.25;
end

function RS:TraceClosed()
    if (not self.traceActive or not self.traceOpen) then return; end
    self:TraceWrite("GOSSIP_CLOSED");
    self:TraceInventory("GOSSIP_CLOSED");
    self.traceOpen = nil;
    self.traceClosedAt = GetTime();
    self.traceUntil = GetTime() + 15;
    self.traceSampleAt = GetTime() + 0.25;
end

function RS:TraceStop(reason)
    if (not self.traceActive) then return; end
    -- Metadata also records the stop when the event array is full.
    local db = PikaBankViewerDB.reagentTrace;
    db.stoppedAt, db.stopReason = time(), reason or "manual";
    db.stopElapsed = GetTime() - self.traceStarted;
    if (#db.events < self.traceMaxEvents) then
        self:TraceWrite("TRACE_STOP", { reason = db.stopReason });
    end
    self.traceActive, self.traceOpen, self.traceUntil = nil, nil, nil;
    self.traceSampleAt, self.traceMenu, self.traceBags = nil, nil, nil;
    self:TracePrint("Запись остановлена (" .. db.stopReason .. "), событий: " .. #db.events .. ". Для сохранения на диск: /reload.");
end

function RS:TraceStart()
    if (self.traceActive) then self:TracePrint("Запись уже включена."); return; end
    EnsureSettings();
    local db = PikaBankViewerDB.reagentTrace;
    if (not db) then
        db = { schema = 1, events = {}, session = 0 };
        PikaBankViewerDB.reagentTrace = db;
    end
    if (db.schema ~= 1 or type(db.events) ~= "table") then
        self:TracePrint("Неизвестная схема журнала; сохранённые данные оставлены без изменений."); return;
    end
    if #db.events > 0 then
        local history=PikaBankViewerDB.reagentTraceHistory or {};
        PikaBankViewerDB.reagentTraceHistory=history;
        history[#history+1]=db;
        while #history>2 do table.remove(history,1); end
        db={schema=1,events={},session=tonumber(db.session) or 0};
        PikaBankViewerDB.reagentTrace=db;
    end
    db.session = (tonumber(db.session) or 0) + 1;
    self.traceActive, self.traceStarted = true, GetTime();
    self.traceMenuSerial, self.traceClosedAt = 0, nil;
    self:TraceWrite("TRACE_START", { realm = GetRealmName(), player = UnitName("player"),
        version = GetAddOnMetadata("PikaBankViewer", "Version") or "0.3.13", duration = self.traceDuration, limit = self.traceMaxEvents });
    self:TracePrint("Новый журнал: до 5000 событий / 10 минут. Откройте Ling; остановка: /lingtrace off.");
    if (UnitName("npc") and ((DGossipFrame and DGossipFrame:IsShown())
            or (GossipFrame and GossipFrame:IsShown())
            or (PikaBankViewer and PikaBankViewer.online))) then
        self:TraceGossip(GetOptions());
    end
end

function RS:TraceUpdate()
    if (not self.traceActive) then return; end
    local now = GetTime();
    if (now - self.traceStarted >= self.traceDuration) then self:TraceStop("timeout"); return; end
    if (self.traceSampleAt and now >= self.traceSampleAt) then
        self.traceSampleAt = nil;
        self:TraceInventory("settled");
    end
    if (self.traceUntil and now > self.traceUntil) then
        self:TraceInventory("post-close window ended");
        self.traceUntil, self.traceMenu, self.traceBags = nil, nil, nil;
    end
end

function RS:TraceEvent(event, ...)
    if (not self.traceActive) then return; end
    if (event == "PLAYER_LOGOUT") then
        if (self.traceBags) then self:TraceInventory("PLAYER_LOGOUT"); end
        self:TraceStop("logout_or_reload"); return;
    end
    if (not self.traceOpen and not (self.traceUntil and GetTime() <= self.traceUntil)) then return; end
    if (event == "BAG_UPDATE") then
        self:TraceWrite(event, { bag = (...) });
        self:TraceInventory(event);
        self.traceSampleAt = GetTime() + 0.25;
    else
        local args = {};
        for i = 1, math.min(select("#", ...), 12) do
            local value = select(i, ...);
            if (type(value) == "string") then args[i] = self:TraceText(value);
            elseif (type(value) == "number" or type(value) == "boolean") then args[i] = value; end
        end
        self:TraceWrite(event, { args = args });
    end
end

SLASH_PIKABANKLINGTRACE1 = "/pikatrace";
SlashCmdList["PIKABANKLINGTRACE"] = function(message)
    local command = Lower(CleanText(message));
    if (command == "on") then RS:TraceStart();
    elseif (command == "off") then
        if (RS.traceActive) then
            if (RS.traceBags) then RS:TraceInventory("manual stop"); end
            RS:TraceStop("manual");
        else RS:TracePrint("Запись уже выключена."); end
    else
        local db = PikaBankViewerDB and PikaBankViewerDB.reagentTrace;
        RS:TracePrint((RS.traceActive and "Запись включена" or "Запись выключена")
            .. "; событий: " .. tostring(db and db.events and #db.events or 0)
            .. ". /lingtrace on - начать, /lingtrace off - остановить, /lingtrace status - состояние.");
    end
end;
-- Reuse the historical command key instead of removing a registered slash
-- handler at PLAYER_LOGIN. It is an identifier, not a DialogUI dependency.
SLASH_DIALOGUILINGTRACE1 = "/lingtrace";
SlashCmdList.DIALOGUILINGTRACE = SlashCmdList.PIKABANKLINGTRACE;
hooksecurefunc("SelectGossipOption", function(index, code) RS:TraceSelected(index, code); end);

function RS:GetOptions() return GetOptions(); end
function RS:GetContextKey() return CurrentCacheKey(); end
function RS:IconFromOption(raw)
    local path = string.match(raw or "", "|T([^:|]+)");
    if path and string.find(string.lower(path), "^interface[/\\]")
            and not string.find(string.lower(path), "questionmark", 1, true)
            and not string.find(string.lower(path), "wowunknownitem", 1, true) then
        return (string.gsub(path, "/", "\\"));
    end
end

function RS:ImportLegacy()
    if PikaImportArkLing then PikaImportArkLing(); end
    EnsureSettings();
    local legacy = DialogUISettings;
    if type(legacy) ~= "table" then return; end
    local function copy(value, seen)
        if type(value) ~= "table" then return value; end
        seen = seen or {};
        if seen[value] then return seen[value]; end
        local result = {}; seen[value] = result;
        for key, child in pairs(value) do result[key] = copy(child, seen); end
        return result;
    end
    for key, bank in pairs(legacy.reagentSearchBanks or {}) do
        if PikaBankViewerDB.reagentSearchBanks[key] == nil then
            PikaBankViewerDB.reagentSearchBanks[key] = copy(bank);
        end
    end
    if not PikaBankViewerDB.reagentTrace and legacy.reagentTrace then
        PikaBankViewerDB.reagentTrace = copy(legacy.reagentTrace);
    end
end

function RS:AttachPresentation()
    -- Disable only the old Ling controller if DialogUI is also installed.
    local old = DialogUI_ReagentSearch;
    if old then
        if old:IsBusy() then old:Abort(); end
        old.traceActive = nil;
        if old.panel then old.panel:Hide(); end
        if DialogUIReagentSearchEventFrame then
            DialogUIReagentSearchEventFrame:UnregisterAllEvents();
            DialogUIReagentSearchEventFrame:SetScript("OnUpdate", nil);
            DialogUIReagentSearchEventFrame:SetScript("OnEvent", nil);
        end
        SlashCmdList.DIALOGUILINGTRACE = SlashCmdList.PIKABANKLINGTRACE;
    end
    -- Leave every non-Ling NPC on its original handler, including teleports.
    -- Suppress GOSSIP_SHOW before the native panel opens; hiding it afterwards
    -- would invoke its OnHide/CloseGossip and terminate the session.
    if GossipFrame and not self.nativeHandlerAttached then
        local original = GossipFrame:GetScript("OnEvent");
        if original then
            GossipFrame:SetScript("OnEvent", function(frame, eventName, ...)
                if (eventName or event) == "GOSSIP_SHOW" and RS:IsLing() then return; end
                return original(frame, eventName, ...);
            end);
            self.nativeHandlerAttached = true;
        end
    end
end

function RS:OnGossipShow()
    local options = GetOptions();
    self:TraceGossip(options);
    if not self:IsLing() then
        if PikaBankViewer and PikaBankViewer.online then self:OnGossipClosed(); end
        return;
    end
    if not self:IsReachable() then
        self:TraceWrite("IGNORED_GOSSIP", {reason="out_of_range"});
        self:OutOfRange(); return;
    end
    if self.sessionClosed and not IsRootMenu(options) then
        self:TraceWrite("IGNORED_GOSSIP", {reason="page_after_close"}); return;
    end
    self.sessionClosed = nil;
    if self.scan then self.scan.waitingReply = nil; end
    PikaBankViewer:OnGossip(options);
    PikaBankViewer:PrioritizeRequests();
    if self.scan then
        self:CancelPending();
        if self.scan.immediateReplies then
            self:ProcessScan(options);
        else
            self.pending = {due=GetTime()+self.actionDelay,process=true};
        end
    end
end

function RS:OnGossipClosed()
    self.sessionClosed = true;
    self:TraceClosed();
    if PikaBankViewer then PikaBankViewer:OnClosed(); end
    if self:IsBusy() then self:Abort("Диалог с Ling закрыт."); end
end

function RS:OnUpdate()
    self:TraceUpdate();
    if self.scan and self.scan.waitingReply and GetTime() > self.scan.waitingReply + 5 then
        self:Abort("Ling не ответил на переход меню.");
        PikaBankViewer:Stop("Получение отменено: нет ответа Ling.", true); return;
    end
    if self.scan and not self:IsReachable() then self:OutOfRange(); return; end
    if self.scan and (not self:IsLing() or InCombatLockdown() or UnitAffectingCombat("player")) then
        self:Abort("Диалог изменился или начался бой. Сканирование остановлено."); return;
    end
    if self.scan and GetTime() > self.scan.deadline then self:Abort("Истёк таймаут операции."); return; end
    if not self.pending or GetTime() < self.pending.due then return; end
    local pending = self.pending; self.pending = nil;
    if not self.scan then return; end
    if pending.process then self:ProcessScan(GetOptions());
    elseif pending.optionIndex then
        local option = GetOptions()[pending.optionIndex];
        if not option or option.key ~= pending.optionKey or option.itemID ~= pending.itemID
                or option.itemID or option.key == "deposit all reagents" then
            self:Abort("Меню изменилось. Сканирование остановлено без повторного запроса."); return;
        end
          self.scan.actions = self.scan.actions + 1;
          self.scan.waitingReply = GetTime();
          self.selecting = true;
          local ok = pcall(SelectGossipOption, pending.optionIndex);
          self.selecting = nil;
          if not ok then self:Abort("Игра отклонила переход меню Ling."); end
    end
end

RS.events = CreateFrame("Frame", "PikaBankScannerEventFrame");
for _, name in ipairs({"PLAYER_LOGIN","GOSSIP_SHOW","GOSSIP_CLOSED","PLAYER_REGEN_DISABLED",
        "PLAYER_LOGOUT","BAG_UPDATE","CHAT_MSG_SYSTEM","CHAT_MSG_LOOT","CHAT_MSG_MONSTER_SAY",
        "CHAT_MSG_MONSTER_WHISPER","CHAT_MSG_ADDON","UI_ERROR_MESSAGE","UI_INFO_MESSAGE"}) do
    RS.events:RegisterEvent(name);
end
RS.events:SetScript("OnEvent", function(_, name, ...)
    if name == "PLAYER_LOGIN" then RS:ImportLegacy(); RS:AttachPresentation();
    elseif name == "GOSSIP_SHOW" then RS:OnGossipShow();
    elseif name == "GOSSIP_CLOSED" then RS:OnGossipClosed();
    elseif name == "PLAYER_REGEN_DISABLED" and RS:IsBusy() then RS:Abort("Операция остановлена при входе в бой.");
    else RS:TraceEvent(name, ...); end
end);
RS.events:SetScript("OnUpdate", function() RS:OnUpdate(); end);

-- END STANDALONE LING SCANNER
PikaBankViewer = {};
local P = PikaBankViewer;
local RS = PikaBankScanner;
P.queue = {};
P.category = "all";
P.mode = "ling";

function P:Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff80dfff[Банк и Ling]|r " .. text);
end

function P:Context()
    PikaBankViewerDB = PikaBankViewerDB or {};
    PikaBankViewerDB.characters = PikaBankViewerDB.characters or {};
    local key = GetRealmName() .. ":" .. UnitName("player");
    local db = PikaBankViewerDB.characters[key];
    if not db then db = {}; PikaBankViewerDB.characters[key] = db; end
    db.name, db.realm = UnitName("player"), GetRealmName();
    return db, key;
end

function P:ViewedBank()
    local current,key=self:Context();
    local selected=self.bankCharacter or key;
    local character=PikaBankViewerDB.characters[selected];
    if not character then selected,character=key,current; self.bankCharacter=nil; end
    return character.bank,selected,character;
end

function P:BankCharacters()
    local _,current=self:Context(); local result={};
    for key,character in pairs(PikaBankViewerDB.characters) do
        if key==current or character.bank then
            result[#result+1]={key=key,text=(character.name or key:match("([^:]+)$") or key)
                .. ((character.realm or key:match("^(.*):")) ~= GetRealmName() and (" — " .. (character.realm or key:match("^(.*):") or "")) or "")};
        end
    end
    table.sort(result,function(a,b)
        if a.key==current then return b.key~=current; end
        if b.key==current then return false; end
        return a.text<b.text;
    end);
    return result;
end

function P:SelectBankCharacter(key)
    if not PikaBankViewerDB.characters[key] then return; end
    self.bankCharacter,self.category,self.rowOffset,self.categoryOffset=key,"all",0,0;
    self.selected=nil; self:Refresh();
end

function P:CanChangeBankBags()
    local _,current=self:Context(); local _,viewed=self:ViewedBank();
    return self.mode=="bank" and self.atBank and current==viewed and not self:Combat();
end

function P:ChangeBankBag(number)
    if not self:CanChangeBankBags() then return; end
    if not GetNumBankSlots or number>GetNumBankSlots() then return; end
    local slot=BankButtonIDToInvSlotID and BankButtonIDToInvSlotID(number+4,1);
    if not slot then return; end
    local kind,id=GetCursorInfo();
    if kind then
        local equipLoc=id and select(9,GetItemInfo(id));
        if kind~="item" or equipLoc~="INVTYPE_BAG" then
            self:Print("Для замены возьмите сумку из рюкзака и перенесите на банковскую сумку."); return;
        end
    end
    if not PutItemInBag(slot) then PickupBagFromSlot(slot); end
    self.bankAt=GetTime()+0.2;
end

function P:IsLing()
    return string.lower(UnitName("npc") or "") == "ling";
end

function P:Combat()
    return InCombatLockdown() or UnitAffectingCombat("player");
end

function P:Index()
    local db, prefix = self:Context();
    local banks = PikaBankViewerDB and PikaBankViewerDB.reagentSearchBanks or {};
    if self.lingKey then return banks[self.lingKey]; end
    if db.lingKey and banks[db.lingKey] then return banks[db.lingKey]; end
    -- Only import this character's newest completed snapshot, never another player.
    local best;
    for key, value in pairs(banks) do
        if string.sub(key, 1, #prefix + 1) == prefix .. ":" and value.complete
                and (not best or (value.scannedAt or 0) > (best.scannedAt or 0)) then
            best = value; db.lingKey = key;
        end
    end
    return best;
end

function P:FindItem(id)
    local index = self:Index();
    for _, item in ipairs(index and index.items or {}) do
        if item.id == id then return item; end
    end
end

function P:RecoverIcons()
    local index = self:Index();
    if not index then return; end
    local missing = {};
    for _, item in ipairs(index.items or {}) do
        if not item.texture then missing[item.id] = item; end
    end
    local trace = PikaBankViewerDB and PikaBankViewerDB.reagentTrace;
    local events = trace and trace.events or {};
    -- Icon identity is shared across characters; never import counts from a trace.
    for i = #events, 1, -1 do
        for _, option in ipairs(events[i].options or {}) do
            local item = missing[option.itemID];
            if item then
                local texture = RS:IconFromOption(option.raw);
                if texture then item.texture = texture; missing[option.itemID] = nil; end
            end
        end
    end
end

function P:Bags()
    local totals = {};
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot);
            local id = link and tonumber(string.match(link, "item:(%d+)"));
            if id then
                local _, count = GetContainerItemInfo(bag, slot);
                totals[id] = (totals[id] or 0) + (count or 0);
            end
        end
    end
    return totals;
end

function P:BankItemCategory(item)
    local name,_,quality,level,_,itemType,subType,_,equipLoc=GetItemInfo(item.id)
    item.name = name or item.name;
    item.bankType = itemType or item.bankType;
    item.bankSubType = subType or item.bankSubType;
    item.bankEquipLoc=equipLoc or item.bankEquipLoc
    item.bankLevel=level or item.bankLevel
    item.bankQuality=quality or item.bankQuality
    if item.bankType then return "bank_type:" .. item.bankType, item.bankType; end
    return "bank_unknown", "Не определено";
end

function P:CaptureBank()
    if not self.atBank then return; end
    local items = {};
    for bag = -1, 11 do
        if bag == -1 or bag >= 5 then
            local slots = GetContainerNumSlots(bag);
            if bag == -1 then slots = 28; end
            for slot = 1, slots do
                local link = GetContainerItemLink(bag, slot);
                local texture, count = GetContainerItemInfo(bag, slot);
                local id = link and tonumber(string.match(link, "item:(%d+)"));
                if id then
                    items[#items + 1] = { id = id, link = link, amount = count or 1,
                        texture = texture, bag = bag, slot = slot };
                    self:BankItemCategory(items[#items]);
                end
            end
        end
    end
    local db = self:Context();
    db.bank = db.bank or {};
    db.bank.items, db.bank.updatedAt = items, time();
    if BankButtonIDToInvSlotID and GetInventoryItemLink and GetNumBankSlots then
        db.bank.bags=db.bank.bags or {};
        db.bank.purchasedSlots=GetNumBankSlots();
        for number=1,7 do
            local slot=BankButtonIDToInvSlotID(number+4,1);
            local link=slot and GetInventoryItemLink("player",slot);
            local bag=db.bank.bags[number] or {}; db.bank.bags[number]=bag;
            bag.link=link; bag.id=link and tonumber(link:match("item:(%d+)"));
            bag.texture=slot and GetInventoryItemTexture("player",slot);
            bag.slots=GetContainerNumSlots(number+4);
            bag.purchased=number<=db.bank.purchasedSlots;
        end
    end
    self:Refresh();
end

function P:SetNotice(text)
    self.notice = text;
    self:Refresh();
end

function P:Stop(text, uncertain)
    if uncertain then
        local index = self:Index();
        if index then index.viewerStale = true; end
    end
    self.op, self.sendAt, self.processAt = nil, nil, nil;
    self.queue = {};
    self.queueDeadline, self.actions = nil, 0;
    if text then self:SetNotice(text); self:Print(text); end
end

function P:Activity()
    local db = self:Context();
    db.lingActivity = db.lingActivity or {};
    local key = self.lingKey or db.lingKey or "ling";
    db.lingActivity[key] = db.lingActivity[key] or {events={}};
    return db.lingActivity[key];
end

function P:RecordActivity(kind, id, amount)
    local activity = self:Activity();
    activity.events = activity.events or {};
    table.insert(activity.events, {at=time(),kind=kind,id=id,amount=amount});
    while #activity.events > 100 do table.remove(activity.events,1); end
    activity.dirty = true;
    local index = self:Index(); if index then index.viewerStale = true; end
end

function P:NeedsScan()
    local index = self:Index();
    return not index or not index.complete or index.viewerStale or self:Activity().dirty;
end

function P:ScheduleRefresh()
    if self.BotDeposit and self.BotDeposit.job then return; end
    if self:NeedsScan() and not self:Combat() then self.scanAt = GetTime() + 0.2;
    else
        self.scanAt = nil;
        self.notice = self:Combat() and "Просмотр. Обновление недоступно в бою."
            or "Сохранённый снимок: изменений не зарегистрировано. Получение доступно сразу.";
    end
end

function P:PrioritizeRequests()
    if #self.queue == 0 then return; end
    -- Let an already sent navigation request finish before changing controllers.
    if RS.scan and RS.scan.waitingReply then return; end
    self.scanAt = nil;
    if RS.scan then
        -- Abort with no failure reason: the normal failure hook clears requests.
        RS:Abort(); self.notice = "Обновление прервано для получения ресурса.";
    end
    self:Kick();
end

function P:StartScan()
    if self.BotDeposit and self.BotDeposit.job then return; end
    if not self.online or not RS:IsReachable() or self:Combat() then
        self:SetNotice("Для обновления откройте Ling вне боя."); return;
    end
    if self.op or self.deposit or #self.queue > 0 then
        self:SetNotice("Сначала завершите получение или нажмите «Стоп»."); return;
    end
    if RS.scan then return; end
    local index = self:Index(); if index then index.viewerStale = true; end
    self.notice = "Обновление хранилища...";
    RS:StartScan();
    self:Refresh();
end

function P:ScanFinished()
    local index = self:Index();
    if index then index.viewerStale, index.viewerUpdatedAt = nil, time(); end
    local activity = self:Activity(); activity.dirty = nil; activity.verifiedAt = time();
    self.notice = "Хранилище обновлено.";
    self:Refresh();
    self:Kick();
end

function P:OnGossip(options)
    if not self:IsLing() then
        if self.online then self:OnClosed(); end
        return;
    end
    local first = not self.online;
    -- A fresh root menu while idle also arrives on another right-click on Ling.
    -- Background replies must not reopen a hidden view or replace the bank tab.
    local reopen = false;
    if not first and self.frame and not self.frame:IsShown()
            and not RS:IsBusy() and not self.op and not self.scanAt
            and not self.deposit and #self.queue == 0 then
        for _, option in ipairs(options) do
            if option.key == "deposit all reagents" then reopen = true; break end
        end
    end
    self.online = true;
    RS:TraceWrite("VIEW_GOSSIP_DECISION", {first=first,reopen=reopen,
        shown=self.frame and self.frame:IsShown() or false,view=self.mode,
        scannerBusy=RS:IsBusy(),scanScheduled=self.scanAt~=nil,
        operation=self.op and self.op.stage,deposit=self.deposit~=nil,queue=#self.queue});
    self.options = options;
    self.lingKey = RS:GetContextKey();
    RS.cacheKey = self.lingKey;
    local db = self:Context(); db.lingKey = self.lingKey;
    if first then
        self:Stop(); self.deposit = nil; self.currentCategory = nil;
        -- NPC/session events update data, never replace a visible user-selected view.
        if not self.frame or not self.frame:IsShown() then self:Open("ling"); end
        self:ScheduleRefresh();
    elseif reopen then
        self:Open("ling");
        self:ScheduleRefresh();
    end
    if not RS.scan then
        self:UpdatePage(options);
        if self.op then
            if self.op.stage == "withdrawWait" then self.op.replyReceived = true; end
            self.processAt = GetTime() + 0.15;
        end
    end
    self:Refresh();
end

function P:UpdatePage(options)
    local index = self:Index();
    if not index then return; end
    for _, option in ipairs(options) do
        if option.itemID then
            local amount = tonumber(string.match(option.text, "%((%d+)%)%s*$"));
            local item = self:FindItem(option.itemID);
            if item and amount then
                item.amount = amount;
                item.texture = option.texture or item.texture;
                item.viewerCheckedAt = time();
            end
        end
    end
end

function P:OnViewHidden()
    -- Changing tabs is not a close. Only the hidden Ling view ends its session.
    if self.mode ~= "ling" or not self.online then return; end
    local closeNPC = RS:IsLing();
    RS:TraceWrite("VIEW_CLOSED", {scannerBusy=RS:IsBusy(), operation=self.op and self.op.stage});
    -- Clear local work first, including replies already scheduled by the scanner.
    -- This also guards against a synchronous GOSSIP_CLOSED / OnHide callback.
    RS:OnGossipClosed();
    if closeNPC then CloseGossip(); end
end

function P:OnClosed()
    if self.BotDeposit and self.BotDeposit.job then self.BotDeposit:Finish(false, "Диалог Ling закрыт."); end
    if not self.online then return; end
    self.online, self.scanAt = nil, nil;
    local uncertain = self.op and self.op.stage == "withdrawWait";
    self:Stop("Диалог закрыт. Доступен сохранённый просмотр.", uncertain);
    if self.deposit then self.deposit.closed = true; end
    self:Refresh();
    -- The server's close event is authoritative even while the broad distance
    -- check still reports nearby. Do not hide a manually opened offline view.
    if self.mode == "ling" and self.frame then self.frame:Hide(); end
end

function P:StackCount(value)
    return math.max(1, math.min(200, math.floor(tonumber(value) or 1)));
end

function P:StackPreview(item, count)
    if not item then return nil; end
    local _, _, _, _, _, _, _, size = GetItemInfo(item.id);
    if size and size > 0 then item.stackSize = size; end
    size = item.stackSize;
    if not size or size <= 0 then return nil; end
    return math.min(item.amount or 0, self:StackCount(count) * size), size;
end

function P:AddRequest(item, all, stacks)
    if self.BotDeposit and self.BotDeposit.job then return; end
    if self.mode ~= "ling" or not item then return; end
    if not self.online or not RS:IsReachable() or self:Combat() then
        self:SetNotice("Получение доступно при разговоре с Ling вне боя."); return;
    end
    if self.deposit then self:SetNotice("Ожидаю завершения внесения."); return; end
    if #self.queue >= 40 then self:SetNotice("В очереди уже 40 заявок."); return; end
    if (item.amount or 0) <= 0 then return; end
    -- Keep identity and intent. No stale positional gossip index is ever queued.
    self.queue[#self.queue + 1] = { id = item.id, category = item.categoryKey,
        all = all and true or false, remainingStacks = self:StackCount(stacks), name = item.name };
    self.notice = "В очереди: " .. #self.queue .. ". Ожидаю подтверждения сервера.";
    self:Refresh(); self:PrioritizeRequests();
end

function P:Kick()
    if self.BotDeposit and self.BotDeposit.job then return; end
    if self.op or RS:IsBusy() or self.scanAt or not self.online then return; end
    local request = self.queue[1];
    if not request then return; end
    if not self.queueDeadline then self.queueDeadline, self.actions = GetTime() + 120, 0; end
    self.op = { request = request, stage = "root", pages = 0 };
    self.processAt = GetTime() + 0.15;
end

function P:Send(option, nextStage)
    if not option then self:Stop("Не удалось найти пункт Ling. Обновите хранилище.", true); return; end
    self.op.stage = nextStage;
    self.op.option = option;
    self.sendAt = GetTime() + 0.15;
    self.processAt = nil;
end

function P:Process()
    local op = self.op;
    if not op then return; end
    local options = self.options or {};
    local root, back, nextPage, category, target;
    for _, option in ipairs(options) do
        if option.key == "deposit all reagents" then root = option; end
        if option.key == "back" or option.key == "назад" then back = option; end
        if option.key == "next page" or option.key == "следующая страница" then nextPage = option; end
        if option.key == op.request.category then category = option; end
        if option.itemID == op.request.id then target = option; end
    end
    if op.stage == "depositWait" then return; end
    if op.stage == "withdrawWait" then
        if not op.replyReceived then return; end
        local amount = target and tonumber(string.match(target.text, "%((%d+)%)%s*$"));
        if target and not amount then self:Stop("Не удалось прочитать остаток Ling. Получение остановлено.", true); return; end
        -- Absence is meaningful only on the fresh item page, never the root menu.
        if root or (not target and not back) then self:Stop("Неожиданный ответ Ling. Получение остановлено.", true); return; end
        amount = amount or 0;
        local gained = (self:Bags()[op.request.id] or 0) - op.beforeBags;
        if amount < op.before and gained == op.before - amount then
            self:RecordActivity("withdraw_confirmed", op.request.id, gained);
            local item = self:FindItem(op.request.id);
            if item then item.amount, item.viewerCheckedAt = amount, time(); end
            op.request.remainingStacks = (op.request.remainingStacks or 1) - 1;
            if (op.request.all or op.request.remainingStacks > 0) and amount > 0 then
                op.stage = "page"; op.replyReceived = nil;
                self.processAt = GetTime() + 0.15;
            else
                table.remove(self.queue, 1); self.op = nil;
                self.notice = "Получено: " .. (op.request.name or tostring(op.request.id));
                if #self.queue == 0 then self.queueDeadline = nil; self:Print("Получение завершено."); end
                self:Kick();
            end
            self:Refresh();
        elseif GetTime() > (op.sentAt or 0) + 4 then
            self:Stop("Нет однозначного подтверждения выдачи. Повтор не отправлен; обновите хранилище.", true);
        else self.processAt = GetTime() + 0.15; end
        return;
    end
    if root then
        if op.request.deposit then
            self.deposit = { before = self:Bags(), started = GetTime() };
            local index = self:Index(); if index then index.viewerStale = true; end
            self:Send(root, "depositWait");
        elseif category then
            self.currentCategory = op.request.category;
            self:Send(category, "page");
        else self:Stop("Категория больше не найдена. Обновите хранилище.", true); end
        return;
    end
    if op.stage == "root" then self:Send(back, "root"); return; end
    if target then
        local amount = tonumber(string.match(target.text, "%((%d+)%)%s*$"));
        if not amount or amount <= 0 then self:Stop("Ling не сообщил доступное количество.", true); return; end
        op.before, op.beforeBags = amount, self:Bags()[op.request.id] or 0;
        op.replyReceived = nil;
        self:Send(target, "withdrawWait");
    elseif nextPage and op.pages < 50 then
        op.pages = op.pages + 1; self:Send(nextPage, "page");
    else self:Stop("Ресурс больше не найден. Обновите хранилище.", true); end
end

function P:DepositAll()
    if self.BotDeposit and self.BotDeposit.job then return; end
    if not self.online or not RS:IsReachable() or self:Combat() then return; end
    if self.deposit or (self.op and self.op.stage == "withdrawWait") then
        self:SetNotice("Дождитесь подтверждения текущей операции."); return;
    end
    self:Stop(); self.scanAt = nil;
    if RS:IsBusy() then RS:Abort("Переход к внесению реагентов."); end
    self.queueDeadline, self.actions = GetTime() + 30, 0;
    self.op = { request = { deposit = true }, stage = "root" };
    self.processAt = GetTime() + 0.15;
    self:SetNotice("Возвращаюсь к внесению всех реагентов...");
end

function P:FinishDeposit()
    local dep = self.deposit;
    if not dep then return; end
    local index = self:Index();
    if index then
        index.viewerStale = true;
        if dep.success then
            local after = self:Bags();
            for id, before in pairs(dep.before) do
                local delta = before - (after[id] or 0);
                local item = self:FindItem(id);
                if delta > 0 and item then item.amount = (item.amount or 0) + delta; end
            end
        end
    end
    self.deposit = nil;
    self:RecordActivity(dep.success and "deposit_confirmed" or "deposit_uncertain");
    self:Stop(dep.success and "Внесение подтверждено. Остатки предварительные; откройте Ling для сверки."
        or "Внесение не подтверждено. Откройте Ling для сверки.", true);
    if self.online then self:ScheduleRefresh(); end
end

function P:Cancel()
    if self.BotDeposit and self.BotDeposit.job then self.BotDeposit:Finish(false, "Остановлено пользователем."); return; end
    local uncertain = self.op and self.op.stage == "withdrawWait";
    self.scanAt = nil;
    if RS:IsBusy() then RS:Abort("Остановлено пользователем."); end
    self:Stop("Очередь остановлена.", uncertain);
    -- An already sent withdrawal/deposit cannot be undone; close the interaction.
    if uncertain and self.online then CloseGossip(); end
end

function P:Update()
    local now = GetTime();
    if self.iconRetryAt and now >= self.iconRetryAt then
        self.iconRetryAt = nil;
        if self.frame and self.frame:IsShown() and now <= (self.iconRetryUntil or 0) then
            self:Refresh();
            if self.missingIcons then self.iconRetryAt = now + 0.5; end
        end
    end
    if self.bankAt and now >= self.bankAt then self.bankAt = nil; self:CaptureBank(); end
    if self.deposit then
        if self.deposit.success and now >= math.max(self.deposit.success + 0.6, (self.deposit.changedAt or 0) + 0.4) then self:FinishDeposit();
        elseif now > self.deposit.started + 10 then self:FinishDeposit(); end
    end
    if not self.online then return; end
    if not RS:IsReachable() then RS:OutOfRange(); return; end
    if self:Combat() then
        self.scanAt = nil;
        if self.op or #self.queue > 0 then self:Stop("Получение остановлено: бой.", true); end
        return;
    end
    if self.scanAt and now >= self.scanAt then self.scanAt = nil; self:StartScan(); end
    if self.queueDeadline and now > self.queueDeadline then
        self:Stop("Истёк лимит времени очереди. Оставшиеся запросы отменены.", true); return;
    end
    if self.op and self.op.sentAt and now > self.op.sentAt + 5 and not self.sendAt then
        self:Stop("Ling не ответил. Повтор не отправлен.", true); return;
    end
    if self.sendAt and now >= self.sendAt then
        self.sendAt = nil;
        if not RS:IsReachable() or RS:IsBusy() then self:Stop("Диалог изменился. Очередь остановлена.", true); return; end
        self.actions = (self.actions or 0) + 1;
        if self.actions > 300 then self:Stop("Достигнут лимит действий очереди.", true); return; end
        local op = self.op;
        if op then
            -- Validate the currently visible row immediately before using its index.
            local fresh = RS:GetOptions()[op.option.originalIndex];
            if not fresh or fresh.key ~= op.option.key or fresh.itemID ~= op.option.itemID then
                self:Stop("Пункты Ling изменились. Запрос отменён.", true); return;
            end
            op.sentAt = now;
            if op.stage == "withdrawWait" then self:RecordActivity("withdraw_sent", op.request.id);
            elseif op.stage == "depositWait" then self:RecordActivity("deposit_sent"); end
            SelectGossipOption(op.option.originalIndex);
        end
    elseif self.processAt and now >= self.processAt then
        self.processAt = nil; self:Process();
    end
end

function P:AttachBags()
    local ace = LibStub and LibStub("AceAddon-3.0", true);
    local addon = ace and ace:GetAddon("AdiBags", true);
    if not addon or self.adiModule then return; end
    self.adi = addon;
    local mod = addon:NewModule("PikaBankButtons", "AceEvent-3.0");
    self.adiModule = mod;
    function mod:OnBagFrameCreated(bag)
        if bag.bagName ~= "Backpack" then return; end
        P:CreateBagButtons(bag:GetFrame());
    end
    addon:HookBagFrameCreation(mod, "OnBagFrameCreated");
end

P.events = CreateFrame("Frame");
for _, event in ipairs({ "PLAYER_LOGIN", "BANKFRAME_OPENED", "BANKFRAME_CLOSED",
        "PLAYERBANKSLOTS_CHANGED", "PLAYERBANKBAGSLOTS_CHANGED", "BAG_UPDATE",
        "CHAT_MSG_SYSTEM", "UI_ERROR_MESSAGE", "PLAYER_LOGOUT" }) do P.events:RegisterEvent(event); end
P.events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        RS:ImportLegacy(); P:Context(); P:CreateUI(); P:AttachBags();
        P:Print("0.3.13: самостоятельный банк и Ling готовы. /pikabank — открыть.");
    elseif event == "BANKFRAME_OPENED" then P.atBank = true; P.bankAt = GetTime() + 0.25;
    elseif event == "BANKFRAME_CLOSED" then P.atBank = nil; P.bankAt = nil; P:Refresh();
    elseif event == "BAG_UPDATE" or event == "PLAYERBANKSLOTS_CHANGED" or event == "PLAYERBANKBAGSLOTS_CHANGED" then
        if P.atBank then P:CaptureBank(); P.bankAt = GetTime() + 0.2; end
        if P.deposit and event == "BAG_UPDATE" then P.deposit.changedAt = GetTime(); end
        if P.op and P.op.stage == "withdrawWait" then P.processAt = GetTime() + 0.15; end
    elseif event == "CHAT_MSG_SYSTEM" then
        local text = (...);
        if P.deposit and text == "All reagents deposited successfully." then P.deposit.success = GetTime(); end
    elseif event == "UI_ERROR_MESSAGE" then
        if P.op then P:Stop("Сервер сообщил ошибку: " .. tostring((...)), true); end
    elseif event == "PLAYER_LOGOUT" then
        if P.op or P.deposit then local index = P:Index(); if index then index.viewerStale = true; end end
    end
end);
P.events:SetScript("OnUpdate", function() P:Update(); end);
hooksecurefunc(RS, "CompleteScan", function() if P.online then P:ScanFinished(); end end);
hooksecurefunc(RS, "Abort", function(_, reason)
    if P.online and reason then P:Stop(reason, true); end
end);
SLASH_PIKABANKVIEWER1 = "/pikabank";
SlashCmdList.PIKABANKVIEWER = function(text) P:Open(text == "bank" and "bank" or "ling"); end;
