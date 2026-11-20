DungeonSeeker = { version = "1.1.6", status = "Выберите подземелье в меню (средняя кнопка мыши)." }
local A = DungeonSeeker

function A:Say(text)
    self.status = text
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc66Поиск подземелья:|r " .. text)
    if self.RefreshUI then self:RefreshUI() end
end

function A:Init()
    if type(DungeonSeekerDB) ~= "table" then DungeonSeekerDB = {} end
    self.db = DungeonSeekerDB
    if type(self.db.roles) ~= "table" then
        local _, tank, heal, damage = GetLFGRoles()
        self.db.roles = { tank = tank, heal = heal, damage = damage }
    end
    self.db.targetID = tonumber(self.db.targetID)
end

function A:Info(id)
    if type(id) ~= "number" or id <= 0 then return end
    local name, kind, minLevel, maxLevel, _, _, _, expansion, _, _, difficulty, maxPlayers = GetLFGDungeonInfo(id)
    if not name or name == "" then return end
    return { id = id, name = name, kind = kind, minLevel = minLevel or 1,
        maxLevel = maxLevel or 80, expansion = expansion, difficulty = difficulty or 0, maxPlayers = maxPlayers }
end

function A:Catalog()
    local targets, seen = {}, {}
    local level = UnitLevel("player")
    local locks = GetLFDChoiceLockedState({}) or {}
    for _, id in pairs(GetLFDChoiceOrder({}) or {}) do
        local info = self:Info(id)
        if info and not seen[id] and (info.kind == 1 or info.kind == 5)
            and level >= info.minLevel and level <= info.maxLevel then
            seen[id] = true
            info.locked = locks[id] and true or false
            targets[#targets + 1] = info
        end
    end
    table.sort(targets, function(a, b) return a.name < b.name end)
    return targets
end

function A:Call(name, ...)
    if InCombatLockdown() or UnitAffectingCombat("player") then
        self:Stop("Начался бой; автоматические действия остановлены.")
        return false
    end
    local fn = _G[name]
    if type(fn) ~= "function" then self:Stop("Клиент не поддерживает " .. name .. "."); return false end
    self.activeCall = name
    self.lastCall = name
    local ok, err = pcall(fn, ...)
    self.activeCall = nil
    if not ok then self:Stop("Ошибка " .. name .. ": " .. tostring(err)); return false end
    return true
end

function A:Stop(reason, cancelQueue)
    local r = self.run
    self.run = nil
    if cancelQueue and r and r.queueOwned then
        local mode = GetLFGMode()
        if InCombatLockdown() or UnitAffectingCombat("player") then
            reason = (reason or "Остановлено.") .. " Очередь в бою отмените вручную."
        elseif mode == "proposal" then
            local exists, _, _, _, _, _, responded = GetLFGProposal()
            if exists and not responded then pcall(RejectProposal) end
        elseif mode == "queued" or mode == "rolecheck" then
            pcall(LeaveLFG)
        end
    end
    self:Say(reason or "Остановлено. Текущая группа сохранена.")
end

function A:Start()
    if self.run then return end
    self:Init()
    if InCombatLockdown() or UnitAffectingCombat("player") or UnitIsDeadOrGhost("player") then
        self:Say("Вход доступен живым и вне боя."); return
    end
    if GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 or IsInInstance() or GetLFGMode() then
        self:Say("Для входа выйдите из группы, подземелья и текущей очереди."); return
    end
    local target = self:Info(self.db.targetID)
    if not target or (target.kind ~= 1 and target.kind ~= 5) then
        self:Say("Сначала выберите конкретное подземелье средней кнопкой мыши."); return
    end
    local available
    for _, item in ipairs(self:Catalog()) do
        if item.id == target.id and not item.locked then available = true end
    end
    if not available then self:Say("Выбранное подземелье недоступно для уровня или заблокировано."); return end
    local roles = self.db.roles
    if not roles.tank and not roles.heal and not roles.damage then self:Say("Выберите хотя бы одну роль."); return end
    self.run = { target = target, roles = { tank = roles.tank, heal = roles.heal, damage = roles.damage },
        queueOwned = true, stage = "queue", deadline = GetTime() + 180, prompted = false }
    self:Say("Ищем конкретно: " .. target.name .. ". Приглашение подтвердите в окне Blizzard.")
    if not self:Call("SetLFGRoles", false, roles.tank and true or false, roles.heal and true or false, roles.damage and true or false) then return end
    if not self:Call("ClearAllLFGDungeons") then return end
    if not self:Call("SetLFGDungeon", target.id) then return end
    self:Call("JoinLFG")
end

function A:Exit()
    if self.exitRun then return end
    if self.run then self:Stop("Поиск остановлен пользователем.", true) end
    if InCombatLockdown() or UnitAffectingCombat("player") then
        self:Say("Выйти можно после окончания боя."); return
    end
    if IsInInstance() then
        self.exitRun = { deadline = GetTime() + 30 }
        -- LFGTeleport(true) is the client action behind "Перенестись из подземелья".
        -- false means teleport INTO the dungeon on WotLK 3.3.5.
        if self:Call("LFGTeleport", true) then self:Say("Выходим из подземелья...") end
    elseif GetLFGMode() then
        pcall(LeaveLFG)
        self:Say("Поиск/приглашение отменено.")
    else
        self:Say("Вы уже снаружи подземелья.")
    end
end

function A:ProposalTargetMatches(target)
    local exists, _, id = GetLFGProposal()
    if not exists or not id then return true end
    return id == target.id
end

function A:InstanceTargetMatches(target)
    if GetPartyLFGBackfillInfo then
        local _, id = GetPartyLFGBackfillInfo()
        if id then return id == target.id end
    end
    local name = GetInstanceInfo()
    return not name or name == "" or name == target.name
end

function A:IsLFGDungeon()
    local inside, instanceType = IsInInstance()
    local mode = GetLFGMode()
    return inside and instanceType == "party" and (mode == "lfgparty" or mode == "abandonedInDungeon")
end

A.finalGoals = {
    -- Classic
    ["Огненная пропасть"] = { boss = "Тарагаман Ненасытный" }, ["Пещеры Стенаний"] = { boss = "Мутанус Пожиратель" },
    ["Мертвые копи"] = { boss = "Эдвин ван Клиф" }, ["Крепость Темного Клыка"] = { boss = "Архимаг Аругал" },
    ["Непроглядная Пучина"] = { boss = "Аку'май" }, ["Тюрьма"] = { boss = "Базиль Тредд" },
    ["Гномреган"] = { boss = "Мекжинер Термоштепсель" }, ["Лабиринты Иглошкурых"] = { boss = "Чарлга Остробок" },
    ["Монастырь Алого ордена - Собор"] = { boss = "Верховный инквизитор Вайтмейн" }, ["Монастырь Алого ордена - Оружейная"] = { boss = "Ирод" },
    ["Монастырь Алого ордена - Библиотека"] = { boss = "Чародей Доан" }, ["Монастырь Алого ордена - Кладбище"] = { boss = "Волхв Талнос" },
    ["Курганы Иглошкурых"] = { boss = "Амненнар Хладовей" }, ["Ульдаман"] = { boss = "Аркедас" },
    ["Зул'Фаррак"] = { boss = "Вождь Укорз Пескочес" }, ["Мародон"] = { boss = "Принцесса Терадрас" },
    ["Мародон - Пещера Злых Духов"] = { boss = "Принцесса Терадрас" }, ["Мародон - Оскверненный грот"] = { boss = "Принцесса Терадрас" },
    ["Затонувший храм"] = { boss = "Аватара Хаккара" }, ["Храм Атал'Хаккара"] = { boss = "Аватара Хаккара" },
    ["Глубины Черной горы"] = { boss = "Император Дагран Тауриссан" }, ["Забытый Город - Восток"] = { boss = "Алззин Перевертень" },
    ["Забытый Город - Запад"] = { boss = "Принц Тортелдрин" }, ["Забытый Город - Север"] = { boss = "Король Гордок" },
    ["Нижняя часть пика Черной горы"] = { boss = "Властитель Змейталак" }, ["Стратхольм"] = { boss = "Барон Ривендер" },
    ["Стратхольм - Главные врата"] = { boss = "Барон Ривендер" }, ["Стратхольм - Черный ход"] = { boss = "Барон Ривендер" },
    ["Некроситет"] = { boss = "Темный магистр Гандлинг" },
    -- The Burning Crusade
    ["Бастионы Адского Пламени"] = { boss = "Назан" }, ["Кузня Крови"] = { boss = "Кели'дан Разрушитель" },
    ["Узилище"] = { boss = "Квагмирран" }, ["Нижетопь"] = { boss = "Черная охотница" },
    ["Гробницы Маны"] = { boss = "Принц Шаффар" }, ["Аукенайские гробницы"] = { boss = "Экзарх Маладаар" },
    ["Сетеккские залы"] = { boss = "Король воронов Айкисс" }, ["Темный лабиринт"] = { boss = "Зыбун" },
    ["Механар"] = { boss = "Паталеон Вычислитель" }, ["Ботаника"] = { boss = "Предводитель Скалезуб" },
    ["Аркатрац"] = { boss = "Предвестник Скайрисс" }, ["Старые предгорья Хилсбрада"] = { boss = "Охотник Эпох" },
    ["Черные топи"] = { boss = "Эонус" }, ["Разрушенные залы"] = { boss = "Вождь Каргат Острорук" },
    ["Паровое подземелье"] = { boss = "Полководец Калитреш" }, ["Терраса Магистров"] = { boss = "Кель'тас Солнечный Скиталец" },
    -- Wrath of the Lich King
    ["Ан'кахет: Старое Королевство"] = { boss = "Глашатай Волаж" }, ["Азжол-Неруб"] = { boss = "Ануб'арак" },
    ["Очищение Стратхольма"] = { boss = "Мал'Ганис" }, ["Крепость Драк'Тарон"] = { boss = "Пророк Тарон'джа" },
    ["Гундрак"] = { boss = "Гал'дара" }, ["Чертоги Молний"] = { boss = "Локен" },
    ["Чертоги Камня"] = { boss = "Сьоннир Литейщик" }, ["Нексус"] = { boss = "Керистраза" },
    ["Окулус"] = { boss = "Хранитель энергии Эрегос" }, ["Крепость Утгард"] = { boss = "Ингвар Расхититель" },
    ["Вершина Утгард"] = { boss = "Король Имирон" }, ["Аметистовая крепость"] = { boss = "Сианигоса" },
    ["Испытание чемпиона"] = { boss = "Черный рыцарь" }, ["Яма Сарона"] = { boss = "Повелитель Плети Тираний" },
    ["Кузня Душ"] = { boss = "Пожиратель Душ" }, ["Залы Отражений"] = { text = "Пережить побег от Короля-лича" },
}

function A:GetDungeonObjectives()
    if not self:IsLFGDungeon() then return end
    local instanceName = GetInstanceInfo()
    if not instanceName or instanceName == "" then return end
    return instanceName, self.finalGoals[instanceName]
end

function A:UpdateObjectivePanel()
    if self.RefreshObjectiveUI then self:RefreshObjectiveUI() end
end

function A:ObjectiveTick()
    local now = GetTime()
    if not self:IsLFGDungeon() then
        if self.objectiveVisible then self.objectiveVisible = nil; self.objectiveDone = nil; self:UpdateObjectivePanel() end
        self.objectiveProbe = nil
        return
    end
    if not self.objectiveVisible then self.objectiveVisible = true end
    if not self.objectiveNext or now >= self.objectiveNext then
        self.objectiveNext = now + 2
        self:UpdateObjectivePanel()
    end
end

function A:OnCombatLog(...)
    if not self.objectiveVisible then return end
    local _, subEvent, _, _, _, _, _, _, destinationName = ...
    if subEvent ~= "UNIT_DIED" then return end
    local instanceName, goal = self:GetDungeonObjectives()
    if goal and goal.boss == destinationName and not (self.objectiveDone and self.objectiveDone.instance == instanceName) then
        self.objectiveDone = { instance = instanceName, boss = destinationName }
        self:UpdateObjectivePanel()
        self:Say("Цель поиска выполнена: " .. destinationName .. ".")
    end
end

function A:Tick()
    if self.exitRun then
        if not IsInInstance() then
            if GetLFGMode() then pcall(LeaveLFG) end
            self.exitRun = nil
            self:Say("Вы вышли из подземелья.")
        elseif GetTime() >= self.exitRun.deadline then
            self.exitRun = nil
            self:Say("Не удалось подтвердить выход. Используйте штатную кнопку выхода.")
        end
        return
    end
    local r = self.run
    if not r then return end
    local mode = GetLFGMode()
    if GetTime() >= r.deadline then self:Stop("Время ожидания приглашения истекло.", true); return end
    if InCombatLockdown() or UnitAffectingCombat("player") then self:Stop("Начался бой; поиск остановлен.", true); return end
    if UnitIsDeadOrGhost("player") then self:Stop("Персонаж погиб; поиск остановлен.", true); return end
    if r.stage == "queue" then
        if mode == "proposal" and not r.prompted then
            if not self:ProposalTargetMatches(r.target) then
                self:Stop("Сервер предложил другое подземелье. Поиск остановлен.", true)
                return
            end
            r.prompted = true
            self:Say("Нажмите «В подземелье» в штатном приглашении.")
        elseif IsInInstance() and (mode == "lfgparty" or (mode == "abandonedInDungeon" and r.prompted)) then
            if not self:InstanceTargetMatches(r.target) then
                self:Stop("Выпало другое подземелье. Вход отменён.", true)
                return
            end
            self.run = nil
            self:Say("Соло-вход выполнен: " .. r.target.name .. ". Смотрите панель «Цель».")
            PlaySound("RaidWarning")
            self:UpdateObjectivePanel()
        elseif not mode and not r.prompted then
            self:Stop("Поиск завершён или был отменён.")
        end
    end
end

function A:Diagnostic()
    local target = self:Info(self.db.targetID)
    local name = GetInstanceInfo()
    self:Say("Выбрано: " .. (target and target.name or "нет") .. "; очередь: "
        .. tostring(GetLFGMode()) .. "; место: " .. tostring(name) .. ".")
end

A.events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "UPDATE_INSTANCE_INFO", "COMBAT_LOG_EVENT_UNFILTERED", "LFG_PROPOSAL_FAILED", "LFG_PROPOSAL_SHOW", "UI_ERROR_MESSAGE", "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }) do A.events:RegisterEvent(event) end
A.events:SetScript("OnEvent", function(_, event, ...)
    local arg1, arg2 = ...
    if event == "PLAYER_LOGIN" then A:Init(); A:CreateLauncher()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_INSTANCE_INFO" then A:UpdateObjectivePanel()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then A:OnCombatLog(...)
    elseif event == "LFG_PROPOSAL_FAILED" and A.run then A:Stop("Приглашение не состоялось; поиск остановлен.", true)
    elseif A.run and (event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN") and arg1 == "DungeonSeeker" then
        A:Stop("Клиент заблокировал " .. tostring(A.activeCall or arg2) .. ".", true)
    elseif event == "UI_ERROR_MESSAGE" and A.run then
        local message = type(arg1) == "string" and arg1 or arg2
        if message then
            A.lastUIError = message
            if A.activeCall then A:Stop("Ошибка " .. A.activeCall .. ": " .. message, true) end
        end
    end
end)
A.events:SetScript("OnUpdate", function(_, elapsed)
    A.elapsed = (A.elapsed or 0) + elapsed
    if A.elapsed >= 0.25 then A.elapsed = 0; A:Tick(); A:ObjectiveTick() end
end)

SLASH_DUNGEONSEEKER1 = "/ds"
SLASH_DUNGEONSEEKER2 = "/dseeker"
SlashCmdList.DUNGEONSEEKER = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")
    if msg == "enter" or msg == "start" then A:Start()
    elseif msg == "exit" or msg == "stop" then A:Exit()
    elseif msg == "status" then A:Diagnostic()
    else A:ToggleMenu() end
end
