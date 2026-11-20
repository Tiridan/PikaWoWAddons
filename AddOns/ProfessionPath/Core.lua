local P = ProfessionPath
P.byKey, P.byName = {}, {}
for _, p in ipairs(P.catalog) do
    P.byKey[p.key] = p
    P.byName[p.name], P.byName[p.en] = p.key, p.key
end

function P:Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff64d8c7Профессии:|r " .. text)
end

function P:Init()
    ProfessionPathDB = ProfessionPathDB or {}
    self.db = ProfessionPathDB
    self.db.characters = self.db.characters or {}
    self.db.schema = self.db.schema or 1
    self.currentKey = GetRealmName() .. "|" .. UnitName("player")
    local c = self.db.characters[self.currentKey] or {}
    self.db.characters[self.currentKey] = c
    c.name, c.realm = UnitName("player"), GetRealmName()
    c.faction, c.level = UnitFactionGroup("player"), UnitLevel("player")
    c.professions = c.professions or {}
    self.selectedCharacter = self.currentKey
    for _, p in ipairs(self.catalog) do
        local name = GetSpellInfo(p.spell)
        if name then self.byName[name] = p.key end
    end
    if self.InitResourceTracking then self:InitResourceTracking() end
    if self.InitTriage then self:InitTriage() end
    self:Scan()
end

function P:Scan()
    if not self.db or self.scanning then return end
    if GetNumSkillLines() == 0 then return end
    self.scanning = true
    local opened, found = {}, {}
    local i = 1
    -- Expand only collapsed headers, remembering full-list indices; restore backwards.
    while i <= GetNumSkillLines() and i <= 512 do
        local name, header, expanded, rank, temporary, bonus, cap = GetSkillLineInfo(i)
        if header and not expanded then
            opened[#opened + 1] = i
            ExpandSkillHeader(i)
        elseif not header and self.byName[name] and type(rank) == "number" and type(cap) == "number" then
            found[self.byName[name]] = {rank = rank, cap = cap, bonus = bonus or 0, temporary = temporary or 0}
        end
        i = i + 1
    end
    for j = #opened, 1, -1 do CollapseSkillHeader(opened[j]) end
    local c = self.db.characters[self.currentKey]
    c.level, c.faction = UnitLevel("player"), UnitFactionGroup("player")
    -- Confirm an empty result twice before retiring all known professions.
    self.emptyScans = next(found) and 0 or (self.emptyScans or 0) + 1
    if next(found) or self.emptyScans >= 2 then
        for _, p in ipairs(self.catalog) do
            local s = c.professions[p.key]
            if found[p.key] then
                s = s or {}; c.professions[p.key] = s
                for k, v in pairs(found[p.key]) do s[k] = v end
                s.active, s.updated = true, time()
            elseif s then s.active = false end
        end
        c.updated = time()
    elseif not c.updated then c.updated = time() end
    self.scanning, self.ignoreSkillUntil = false, GetTime() + 0.25
    if self.Refresh and self.window and self.window:IsShown() then self:Refresh() end
end

function P:Character()
    return self.db.characters[self.selectedCharacter] or self.db.characters[self.currentKey]
end

function P:Skill(c, key)
    local s = c.professions and c.professions[key]
    if s and s.active ~= false then return s end
end

function P:NextRank(c, p)
    local s = self:Skill(c, p.key)
    local cap = s and s.cap or 0
    for i, r in ipairs(p.ranks) do
        if cap < r.cap then return r, i end
    end
end

function P:State(c, p, r)
    local s = self:Skill(c, p.key)
    local rank, cap = s and s.rank or 0, s and s.cap or 0
    if cap >= r.cap then return "Изучено", "done" end
    local nextRank = self:NextRank(c, p)
    if nextRank ~= r then return "Позже", "later" end
    if rank < r.skill then return "Ещё " .. (r.skill - rank) .. " навыка", "waiting" end
    if (c.level or 1) < r.level then return "Нужен " .. r.level .. " уровень", "waiting" end
    if r.cap > 300 then return "Навык готов; нужен доступ", "access" end
    if r.method == "Задание" then return "Можно начать задание", "ready" end
    if r.method == "Книга" then return "Можно изучить книгу", "ready" end
    return "Можно учиться", "ready"
end

function P:Destination(c, r)
    return r[c.faction]
end

function P:PinDestination(d, route)
    local c = self:Character()
    if not d or not d.x or not d.y then self:Print("Точка внутри подземелья: " .. (d and d.zone or "место не определено") .. "."); return end
    if not d.neutral and c.faction ~= UnitFactionGroup("player") then self:Print("Это маршрут другой фракции. Выберите своего персонажа."); return end
    if not TomTom or not TomTom.AddZWaypoint then self:Print(d.name .. ": " .. d.zone .. string.format(" (%.1f, %.1f).", d.x, d.y)); return end
    for continent = 1, 4 do
        local zones = {GetMapZones(continent)}
        for zone, name in ipairs(zones) do
            if name == d.zone or name == d.zoneEN then
                if self.lastPin and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(self.lastPin) end
                self.lastPin = TomTom:AddZWaypoint(continent, zone, d.x, d.y, d.name, false, true, true, nil, true, route == true)
                if route then
                    self:Print("Путь к " .. d.name .. ": следуйте стрелке TomTom. Если стрелка скрыта, включите её в настройках TomTom.")
                elseif not InCombatLockdown() then
                    if not WorldMapFrame:IsShown() then ShowUIPanel(WorldMapFrame) end
                    SetMapZoom(continent, zone)
                else
                    self:Print("Карту можно открыть после боя; метка уже установлена.")
                end
                self:Print("Отмечено: " .. d.name .. " — " .. d.zone .. ".")
                return
            end
        end
    end
    self:Print(d.name .. ": " .. d.zone .. string.format(" (%.1f, %.1f).", d.x, d.y))
end

function P:Pin(r, route)
    self:PinDestination(self:Destination(self:Character(), r), route)
end

function P:Status()
    self:Scan()
    local c = self:Character()
    self:Print(c.name .. " — " .. c.realm)
    for _, p in ipairs(self.catalog) do
        local s = self:Skill(c, p.key)
        if s then
            local r = self:NextRank(c, p)
            local text = p.name .. ": " .. s.rank .. "/" .. s.cap
            if r then
                local d = self:Destination(c, r)
                text = text .. "; с " .. r.skill .. ": " .. (d and (d.name .. ", " .. d.zone) or "фракция неизвестна")
            else text = text .. "; все ранги открыты" end
            self:Print(text)
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("SKILL_LINES_CHANGED")
events:RegisterEvent("CHAT_MSG_SKILL")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("TRADE_SKILL_SHOW")
events:RegisterEvent("TRAINER_CLOSED")
events:RegisterEvent("BAG_UPDATE")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        P:Init(); P:CreateLauncher()
        P.pending, P.loginRetries = GetTime() + 1, 5
        P:Print("Путь ремесленника " .. P.version .. " — /profpath или кнопка у миникарты.")
    elseif event == "PLAYER_LOGOUT" then P:Scan()
    elseif P.db and not P.scanning and (event ~= "SKILL_LINES_CHANGED" or GetTime() > (P.ignoreSkillUntil or 0)) then
        P.pending = GetTime() + 0.3
    end
end)
events:SetScript("OnUpdate", function()
    if P.pending and GetTime() >= P.pending then
        P.pending = nil; P:Scan()
        if P.loginRetries and P.loginRetries > 0 then
            P.loginRetries = P.loginRetries - 1; P.pending = GetTime() + 1
        end
    end
end)

SLASH_PROFESSIONPATH1 = "/profpath"
SLASH_PROFESSIONPATH2 = "/ppath"
SlashCmdList.PROFESSIONPATH = function(msg)
    if not P.db then P:Init() end
    if msg == "status" then P:Status()
    elseif msg == "resources" or msg == "track" then P:ToggleTrackingWindow()
    elseif msg == "resetpos" then
        P.db.position = nil
        if P.window then P.window:ClearAllPoints(); P.window:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
    else P:Toggle() end
end
