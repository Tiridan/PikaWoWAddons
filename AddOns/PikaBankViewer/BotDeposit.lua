-- Serialized Ling deposits. Never infer credit from a greeting or a bag loss.
local P, RS = PikaBankViewer, PikaBankScanner;
P.BotDeposit = {};
local B = P.BotDeposit;
B.pause = 3; -- Minimum settling time; fresh quantities, not time, decide success.

function B:Key(name)
    return tostring(name or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("%-.*$", "");
end

function B:Members()
    local out, seen = {}, {};
    local alts = UnBotAccountAlts;
    if not alts or not alts.IsListed then return out; end
    local raid = GetNumRaidMembers() > 0;
    local n = raid and GetNumRaidMembers() or GetNumPartyMembers();
    for i = 1, math.min(n, 40) do
        local unit = (raid and "raid" or "party") .. i;
        local name = UnitName(unit);
        if name and name ~= UnitName("player") and not seen[name] and alts.IsListed(name)
                and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
            seen[name] = true;
            out[#out + 1] = { name = name, guid = UnitGUID(unit) };
        end
    end
    table.sort(out, function(a, b) return a.name < b.name; end);
    return out;
end

function B:Conflict()
    return (UnBotAltSetups and UnBotAltSetups.job)
        or (UnBotAccountAlts and (UnBotAccountAlts.active or UnBotAccountAlts.discoveryActive));
end

function B:Ready()
    local j = self.job;
    if not j then return false; end
    if P:Combat() then return false, "Начался бой."; end
    if not P.online or not RS:IsReachable() or UnitGUID("npc") ~= j.npc
            or UnitGUID("target") ~= j.npc or RS:GetContextKey() ~= j.context then
        return false, "Диалог или выбранный Ling изменился.";
    end
    if self:Conflict() then return false, "Запущена другая операция с альтами."; end
    local members = self:Members();
    if #members ~= #j.bots then return false, "Изменился состав доступных альтов."; end
    for i, bot in ipairs(members) do
        if bot.name ~= j.bots[i].name or bot.guid ~= j.bots[i].guid then
            return false, "Альт вышел, умер или изменился состав группы.";
        end
    end
    return true;
end

function B:Status(stage, text)
    local j = self.job;
    j.stage = stage; j.deadline = GetTime() + 180;
    j.report.stage = stage; j.report.updatedAt = time();
    P.notice = "Альты " .. j.index .. "/" .. #j.bots .. ": " .. j.bots[j.index].name .. ". " .. text;
    P:Print(P.notice);
    RS:TraceWrite("BOT_DEPOSIT_STAGE", {name=j.bots[j.index].name, stage=stage});
    P:Refresh();
end

function B:Finish(ok, reason)
    local j = self.job;
    if not j then return; end
    j.report.state = ok and "verified" or "stopped";
    j.report.reason, j.report.finishedAt = reason, time();
    self.job = nil;
    P.scanAt = nil;
    if RS:IsBusy() then RS:Abort(); end
    if not ok then local index=P:Index(); if index then index.viewerStale=true; end end
    local name = j.bots[j.index] and j.bots[j.index].name or "";
    P.notice = ok and ("Сдача альтов завершена: " .. #j.bots .. ". Зачисление переданных ресурсов подтверждено.")
        or ("Очередь остановлена: " .. name .. ". " .. tostring(reason)
            .. " Следующий альт не сдаёт. "
            .. (j.sent and "Уже отправленная сдача не отменяется; автоповтора нет."
                or "Команда сдачи этому альту ещё не отправлялась."));
    P:Print(P.notice); P:Refresh();
end

function B:Send(command)
    local ok, reason = self:Ready();
    if not ok then self:Finish(false, reason); return false; end
    local j = self.job;
    local name = j.bots[j.index].name;
    self.outgoing = self.outgoing or {};
    self.outgoing[#self.outgoing + 1] = {name=name, text=command, untilAt=GetTime()+15};
    -- MultiBot normally defers SendChatMessage. This low-rate serialized flow
    -- uses its original sender so deadlines start at the actual API call.
    local send = MultiBot and MultiBot._throttleOrig or SendChatMessage;
    local sent = pcall(send, command, "WHISPER", nil, name);
    if not sent then self:Finish(false, "Не удалось отправить команду " .. command .. "."); return false; end
    if self.job and command == j.current.command then
        P:Print(name .. ": команда сдачи отправлена. Пауза " .. self.pause .. " с, затем проверка сумок и банка.");
    end
    RS:TraceWrite("BOT_DEPOSIT_COMMAND", {name=name, command=command});
    return self.job ~= nil;
end

function B:Scan(stage)
    self:Status(stage, "Полная сверка банка...");
    P.scanAt = nil;
    RS:StartScan(true);
    if not self.job then return; end
    if not RS.scan then self:Finish(false, "Не удалось начать полный скан банка."); return; end
    RS.scan.strictCounts = true;
end

function B:ReadBags(stage)
    self:Status(stage, "Читаю полный список сумок...");
    local j = self.job;
    j.inventory = {rows=0, counts={}, links={}};
    j.deadline = GetTime() + 15;
    self:Send("c");
end

function B:Next()
    local j = self.job;
    j.current = {name=j.bots[j.index].name};
    j.report.bots[j.index] = j.current;
    j.sent, j.before, j.bankBefore, j.inventory = nil, nil, nil, nil;
    self:Status("summon", "Начинаю сдачу: подвожу альта к Ling...");
    j.due = GetTime() + self.pause;
    self:Send("summon");
end

function B:Start()
    if self.job then return; end
    if not P.online or not RS:IsReachable() or P:Combat() or P.mode ~= "ling"
            or not UnitGUID("npc") or UnitGUID("target") ~= UnitGUID("npc") then
        P:SetNotice("Откройте разговор с Ling и оставьте Ling выбранным. Сдача доступна вне боя."); P:Print(P.notice); return;
    end
    if self:Conflict() or P.op or P.deposit or #P.queue > 0 or RS.navigation then
        P:SetNotice("Дождитесь текущей операции или нажмите «Стоп» перед сдачей альтов."); P:Print(P.notice); return;
    end
    local bots = self:Members();
    if #bots == 0 then P:SetNotice("Нет доступных альтов группы из реестра UnBot. Офлайн-альты и другие игроки не участвуют."); P:Print(P.notice); return; end
    local db = P:Context();
    db.botDepositAudit = db.botDepositAudit or {};
    local store = db.botDepositAudit;
    store.history = store.history or {};
    if store.last then table.insert(store.history, store.last); end
    while #store.history > 3 do table.remove(store.history, 1); end
    local report = {state="running", startedAt=time(), pause=self.pause, bots={}};
    store.last = report;
    self.job = {bots=bots, index=1, npc=UnitGUID("npc"), context=RS:GetContextKey(),
        report=report, totalDeadline=GetTime()+#bots*480};
    P.scanAt = nil; self.outgoing = {};
    P:Print("Сдача альтов по одному: " .. #bots .. ". Пауза не менее " .. self.pause .. " с; следующий ждёт сверки сумок и банка.");
    if RS.scan then
        self:Status("handoff", "Прерываю фоновый пересчёт: жду только уже отправленный переход...");
        self.job.deadline=GetTime()+8;
        self:ClaimScanner();
    else self:Next(); end
end

function B:ClaimScanner()
    if not self.job then return; end
    if RS.scan and RS.scan.waitingReply then return; end
    if RS:IsBusy() then
        self.preempting=true; RS:Abort(); self.preempting=nil;
    end
    if self.job then self:Next(); end
end

function B:BankCounts()
    local index = RS:GetIndex();
    if not index or not index.complete then return nil; end
    local counts = {};
    for _, item in ipairs(index.items) do
        if not item.id or counts[item.id] or type(item.amount) ~= "number" or item.amount < 0 then return nil; end
        counts[item.id] = item.amount;
    end
    return counts;
end

-- The server's talk 15 decides what is depositable. Inventory reads only
-- measure actual deltas; item type, local metadata and binding are not gates.
function B:PrepareInventory(inv)
    local j = self.job;
    if not next(inv.counts) then
        j.current.state = "empty";
        P:Print(j.current.name .. ": сумки пусты; сдавать нечего.");
        self:Verified(); return;
    end
    self:Status("talk", "Открываю Ling альту; затем личная команда talk 15...");
    j.deadline=GetTime()+15; j.due=GetTime()+self.pause;
    self:Send("talk");
end

function B:InventoryDone(inv)
    local j = self.job;
    j.inventory = nil;
    if j.stage == "bags_before" then
        j.before = inv.counts; j.current.before = inv.counts;
        self:PrepareInventory(inv);
    elseif j.stage == "bags_after" then
        j.current.after = inv.counts;
        j.removed = {};
        for id, before in pairs(j.before) do
            local after = inv.counts[id] or 0;
            if after > before then self:Finish(false, "Вещь " .. id .. " добавилась в сумки во время сдачи."); return; end
            if before > after then j.removed[id] = before - after; end
        end
        for id in pairs(inv.counts) do
            if not j.before[id] then self:Finish(false, "Содержимое сумок изменилось посторонним действием: ID " .. id .. "."); return; end
        end
        self:Scan("bank_after");
    end
end

function B:Verified()
    local j = self.job;
    j.current.state = j.current.state == "empty" and "empty" or "verified";
    j.current.verifiedAt = time();
    if j.current.state == "verified" then
        P:Print(j.current.name .. ": сдал ресурсы. Зачисление подтверждено: " .. j.current.transferred
            .. " шт. (" .. j.index .. "/" .. #j.bots .. ").");
    end
    -- Restore following for this one bot only, after verification.
    if not self:Send("follow") then return; end
    if j.index == #j.bots then self:Finish(true); return; end
    self:Status("next_pause", "Проверка завершена. Пауза перед следующим альтом...");
    j.due = GetTime() + self.pause;
end

function B:ScanDone()
    local j = self.job;
    if not j then return; end
    if j.stage == "handoff" then self:ClaimScanner(); return; end
    local counts = self:BankCounts();
    if not counts then self:Finish(false, "Полный снимок банка не прошёл проверку."); return; end
    if j.stage == "bank_before" then
        j.bankBefore=counts; j.current.bankBefore=counts;
        self:ReadBags("bags_before");
    elseif j.stage == "bank_after" then
        j.current.bankAfter=counts;
        local ids={}; for id in pairs(j.bankBefore) do ids[id]=true; end
        for id in pairs(counts) do ids[id]=true; end
        for id in pairs(j.removed) do ids[id]=true; end
        for id in pairs(ids) do
            local gain=(counts[id] or 0)-(j.bankBefore[id] or 0);
            if gain ~= (j.removed[id] or 0) then
                self:Finish(false, "Зачисление не совпало: ID " .. id .. ", ушло из сумок "
                    .. (j.removed[id] or 0) .. ", прирост банка " .. gain .. ". Проверьте хранилище."); return;
            end
        end
        local transferred=0;
        for _, amount in pairs(j.removed) do transferred=transferred+amount; end
        if transferred==0 then
            self:Finish(false, "После talk 15 сумки и банк не изменились. Возможно, нет подходящих ресурсов; зачисление не подтверждено."); return;
        end
        j.current.transferred=transferred; self:Verified();
    else self:Finish(false, "Получен скан банка вне ожидаемого этапа."); end
end

function B:Reply(message, sender)
    local j = self.job;
    if not j or self:Key(sender) ~= j.bots[j.index].name then return; end
    if message:find("cannot",1,true) or message:find("Cannot",1,true)
            or message:find("Unknown",1,true) or message:find("not allowed",1,true)
            or message:find("No items",1,true) then
        self:Finish(false, "Ответ альта: " .. message); return;
    end
    if j.stage == "talk" then return; end
    local inv = j.inventory;
    if not inv then return; end
    if message:find("=== Inventory ===",1,true) then
        if inv.header then self:Finish(false, "Повторное начало списка сумок."); return; end
        inv.header = true; return;
    end
    if not inv.header then return; end
    local declared = tonumber(message:match("^=== Inventory end: (%d+) ===%s*$"));
    if declared then
        if declared ~= inv.rows then self:Finish(false, "Список сумок неполный: получено " .. inv.rows .. " из " .. declared .. "."); return; end
        self:InventoryDone(inv); return;
    end
    local id = tonumber(message:match("|Hitem:(%d+)"));
    if id then
        local clean = message:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "");
        local tail = clean:match("|h%[.-%]|h(.*)$");
        tail = tail and tail:gsub("%(soulbound%)", ""):match("^%s*(.-)%s*$");
        local count = tail == "" and 1 or (tail and tonumber(tail:match("^x(%d+)$")));
        if not count then self:Finish(false, "Не удалось прочитать точное количество вещи " .. id .. "."); return; end
        if count < 1 or inv.counts[id] or inv.rows >= 240 then self:Finish(false, "Повторяющаяся или неверная запись сумок: ID " .. id .. "."); return; end
        inv.rows=inv.rows+1; inv.counts[id]=count;
        inv.links[id]=clean:match("(|Hitem:[^|]+|h%[[^%]]*%]|h)");
    elseif message:find("|Hitem:",1,true) or message:find("Inventory end",1,true) then
        self:Finish(false, "Непонятная запись списка сумок.");
    end
end

function B:Tick()
    local j = self.job;
    if not j then return; end
    local ok, reason = self:Ready();
    if not ok then self:Finish(false, reason); return; end
    local now=GetTime();
    if now>j.deadline or now>j.totalDeadline then self:Finish(false, "Истёк срок ожидания этапа " .. j.stage .. "."); return; end
    if j.stage == "handoff" then self:ClaimScanner(); return; end
    if j.stage == "talk" and now>=j.due then
        -- Save intent before sending once. No automatic retries after this point.
        j.sent=true; j.current.command="talk 15"; j.current.sentAt=time();
        self:Status("settle", "Отправляю команду сдачи; затем пауза и проверка зачисления...");
        j.due=now+self.pause;
        self:Send(j.current.command);
    elseif j.due and now>=j.due then
        if j.stage == "summon" then
            self:Status("stay", "Жду остановки альта..."); j.due=now+self.pause; self:Send("stay");
        elseif j.stage == "stay" then j.due=nil; self:Scan("bank_before");
        elseif j.stage == "settle" then j.due=nil; self:ReadBags("bags_after");
        elseif j.stage == "next_pause" then j.index=j.index+1; self:Next(); end
    end
end

B.events = CreateFrame("Frame");
for _, event in ipairs({"PLAYER_LOGIN","CHAT_MSG_WHISPER","CHAT_MSG_WHISPER_INFORM","CHAT_MSG_PARTY","CHAT_MSG_RAID",
        "PLAYER_TARGET_CHANGED","PLAYER_REGEN_DISABLED","PLAYER_LOGOUT","PLAYER_ENTERING_WORLD"}) do B.events:RegisterEvent(event); end
B.events:SetScript("OnEvent", function(_, event, message, sender)
    if event == "PLAYER_LOGIN" then
        local db=P:Context(); local last=db.botDepositAudit and db.botDepositAudit.last;
        if type(last)=="table" and last.state=="running" then
            last.state="interrupted"; last.reason="Предыдущая сессия прервана. Проверьте сумки и банк; очередь не возобновлена.";
            P:Print(last.reason);
        end
        return;
    end
    if not B.job then return; end
    if event == "CHAT_MSG_WHISPER" then B:Reply(message or "",sender);
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        for i=#(B.outgoing or {}),1,-1 do
            local own=B.outgoing[i];
            if own.untilAt<GetTime() then table.remove(B.outgoing,i);
            elseif own.text==message and own.name==B:Key(sender) then table.remove(B.outgoing,i); return; end
        end
        for _,bot in ipairs(B.job.bots) do
            if B:Key(sender)==bot.name then B:Finish(false,"Посторонняя команда альту во время проверки."); return; end
        end
    elseif event=="CHAT_MSG_PARTY" or event=="CHAT_MSG_RAID" then
        if B:Key(sender)==UnitName("player") and tostring(message):match("^%s*%a+") then
            B:Finish(false,"Сообщение игрока в группе во время сдачи; проверьте, не была ли отправлена общая команда.");
        end
    elseif event=="PLAYER_TARGET_CHANGED" then
        local ok,why=B:Ready(); if not ok then B:Finish(false,why); end
    else B:Finish(false,"Смена мира, выход или начало боя."); end
end);
B.events:SetScript("OnUpdate",function() B:Tick(); end);
hooksecurefunc(RS,"CompleteScan",function() B:ScanDone(); end);
hooksecurefunc(RS,"Abort",function(_,reason) if B.job and not B.preempting then B:Finish(false,reason or "Сканирование банка прервано."); end end);
hooksecurefunc("SelectGossipOption",function()
    if B.job and not RS.selecting then B:Finish(false,"Посторонний выбор пункта меню Ling."); end
end);
