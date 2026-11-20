local G = ThoriumBrotherhoodGuide
G.events = CreateFrame("Frame")
G.questLog = {}

function G:Print(text)
 DEFAULT_CHAT_FRAME:AddMessage("|cffff9d2eБратство Тория|r: "..text)
end

function G:CharacterDB()
 ThoriumBrotherhoodGuideDB = type(ThoriumBrotherhoodGuideDB) == "table" and ThoriumBrotherhoodGuideDB or {}
 ThoriumBrotherhoodGuideDB.characters = type(ThoriumBrotherhoodGuideDB.characters) == "table" and ThoriumBrotherhoodGuideDB.characters or {}
 local key = (GetRealmName() or "?").."|"..(UnitGUID("player") or UnitName("player") or "?")
 ThoriumBrotherhoodGuideDB.characters[key] = type(ThoriumBrotherhoodGuideDB.characters[key]) == "table" and ThoriumBrotherhoodGuideDB.characters[key] or {}
 self.db = ThoriumBrotherhoodGuideDB.characters[key]
 self.db.quests = type(self.db.quests) == "table" and self.db.quests or {}
end

function G:ScanQuestLog()
 self.questLog = {}
 for i = 1, GetNumQuestLogEntries() do
  local title, _, _, header, _, complete, _, id = GetQuestLogTitle(i)
  if not header and title then
   if not id or id == 0 then id = tonumber((GetQuestLink(i) or ""):match("quest:(%d+)")) end
   if id then self.questLog[id] = {title = title, complete = complete == 1} end
  end
 end
end

function G:QueryHistory(silent)
 if self.historyPending then return end
 self.historyPending = true
 self.historyMessage = "Запрашиваю серверную историю сданных заданий..."
 QueryQuestsCompleted()
 if not silent then self:Print(self.historyMessage) end
 self:RefreshUI()
end

function G:ReadHistory()
 local history = {}
 local ok, result = pcall(GetQuestsCompleted, history)
 if not ok then
  self.historyPending = nil
  self.historyMessage = "Сервер не отдал историю. Нажмите «Обновить» ещё раз."
  self:RefreshUI()
  return
 end
 if type(result) == "table" then history = result end
 local count = 0
 for id, done in pairs(history) do
  if done and done ~= 0 and tonumber(id) then self.db.quests[tonumber(id)] = true; count = count + 1 end
 end
 self.historyPending = nil
 self.historyReady = true
 self.db.historyAt = time()
 self.historyMessage = "Сервер подтвердил "..count.." сданных заданий (проверка по ID)."
 self:ScanQuestLog()
 self:RefreshUI()
end

function G:QuestState(id)
 local live = self.questLog[id]
 if live then return live.complete and "ready" or "active", live.title end
 if self.db.quests[id] then return "done" end
 return self.historyReady and "missing" or "unknown"
end

function G:GetReputation()
 for i = 1, GetNumFactions() do
  local name, _, standing, bottom, top, earned, _, _, header = GetFactionInfo(i)
  local key = (name or ""):lower()
  if not header and self.factionNames[key] then
   return {name = name, standing = standing, bottom = bottom or 0, top = top or 0, earned = earned or 0}
  end
 end
 return nil
end

function G:MaterialLine(materials)
 local parts = {}
 for _, mat in ipairs(materials) do
  local have = GetItemCount(mat[1], false) or 0
  parts[#parts + 1] = mat[3]..": "..have.."/"..mat[2]
 end
 return table.concat(parts, "; ")
end

function G:FirstCampaignQuest()
 for _, row in ipairs(self.campaign) do
  local state = self:QuestState(row[1])
  if state ~= "done" then return row, state end
 end
end

function G:CampaignCounts()
 local counts = {done=0, active=0, ready=0, missing=0, unknown=0}
 for _, row in ipairs(self.campaign) do counts[self:QuestState(row[1])] = (counts[self:QuestState(row[1])] or 0) + 1 end
 return counts
end

function G:SetQuestMarker(id)
 local target = self.questTargets[id]
 if not target then self:Print("Для этого задания нет наружной точки. Откройте журнал задания."); return false end
 if not TomTom or not TomTom.AddZWaypoint then
  self:Print(target.name..": "..target.zoneRU..string.format(" %.1f, %.1f. Для стрелки включите TomTom.", target.x, target.y))
  return false
 end
 for continent = 1, 4 do
  for zone, name in ipairs({GetMapZones(continent)}) do
   if name == target.zone or name == target.zoneRU then
    if not WorldMapFrame:IsShown() then ShowUIPanel(WorldMapFrame) end
    SetMapZoom(continent, zone)
    local pin = TomTom:AddZWaypoint(continent, zone, target.x, target.y, "Братство Тория: "..target.name, false, true, true, nil, true, true)
    if self.questPin and self.questPin ~= pin and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(self.questPin) end
    self.questPin = pin
    self:Print("Метка: "..target.name.." — "..target.zoneRU..string.format(" %.1f, %.1f.", target.x, target.y))
    return true
   end
  end
 end
 self:Print("Не найдена карта зоны: "..target.zoneRU)
 return false
end

function G:FarmPlan(rep)
 if not rep then return "Откройте окно репутаций хотя бы раз или проверьте, что Братство Тория отображается в списке." end
 if rep.standing <= 4 then
  return "Равнодушие → Дружелюбие: сначала закройте все задания Тлеющего ущелья ниже. После «Что за флюс?» сдавайте самый дешёвый для вас вариант: королевская кровь (травничество), железные слитки (горное дело) или толстая кожа (снятие шкур). Чешую инцендозавров выгодно фармить заранее в Шлаковой яме; уголь продаёт сам мастер Бёрнинейт."
 elseif rep.standing == 5 then
  return "Дружелюбие → Уважение: сдавайте «Признание» по 4 остатка тёмного железа. Лучший активный фарм — полные зачистки Глубин Чёрной горы: остатки падают с мобов и боссов, а у Локтоса можно сразу сдавать поздние материалы, когда откроется Уважение."
 elseif rep.standing >= 6 and rep.standing < 8 then
  return "Уважение → Превознесение: сдавайте материалы Локтосу Тёмному Торговцу в «Угрюмом обжоре» внутри Глубин Чёрной горы. Для времени — рейды Огненных Недр (ядра/кожа); для соло-фарма — руда тёмного железа в ГЧГ. Не тратьте Кровь горы, если она на аукционе дороже эквивалентной репутации ядер."
 end
 return "Превознесение уже достигнуто — проверьте рецепты и планы у Локтоса Тёмного Торговца в Глубинах Чёрной горы."
end

function G:Init()
 self:CharacterDB()
 self:ScanQuestLog()
 self.events:RegisterEvent("QUEST_LOG_UPDATE")
 self.events:RegisterEvent("QUEST_QUERY_COMPLETE")
 self.events:RegisterEvent("QUEST_FINISHED")
 self.events:RegisterEvent("UPDATE_FACTION")
 self.events:RegisterEvent("BAG_UPDATE")
 self:CreateUI()
 self:CreateLauncher()
 self:QueryHistory(true)
 self:Print("v"..self.version.." готов. /thorium — открыть помощник.")
end

G.events:SetScript("OnEvent", function(_, event)
 if event == "PLAYER_LOGIN" then G:Init()
 elseif event == "QUEST_QUERY_COMPLETE" then G:ReadHistory()
 elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_FINISHED" then G:ScanQuestLog(); G:RefreshUI()
 elseif event == "UPDATE_FACTION" or event == "BAG_UPDATE" then G:RefreshUI() end
end)
G.events:RegisterEvent("PLAYER_LOGIN")

SLASH_THORIUMBROTHERHOODGUIDE1 = "/thorium"
SLASH_THORIUMBROTHERHOODGUIDE2 = "/tbg"
SlashCmdList.THORIUMBROTHERHOODGUIDE = function() G:ToggleUI() end
