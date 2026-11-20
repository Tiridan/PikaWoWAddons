local G = SoloProgressGuide
G.questLog = {}
G.events = CreateFrame("Frame")

function G:Print(text)
 DEFAULT_CHAT_FRAME:AddMessage("|cffdfb66cSolo Progress|r: "..text)
end
function G:GetRealmMode()
 local realm=(GetRealmName() or ""):lower():gsub("%s+"," "):match("^%s*(.-)%s*$")
 if realm=="solo progress" then return "Solo Progress" end
 if realm=="solo" then return "Solo" end
 return nil
end
function G:IsSupported()
 return self:GetRealmMode()~=nil
end
function G:Changed()
 self.dirty = true
end
function G:Init()
 if not self:IsSupported() then self.active=false;return end
 self.realmMode=self:GetRealmMode()
 SoloProgressGuideDB = type(SoloProgressGuideDB)=="table" and SoloProgressGuideDB or {}
 local db = SoloProgressGuideDB
 db.characters = type(db.characters)=="table" and db.characters or {}
 db.ui = type(db.ui)=="table" and db.ui or {}
 db.schema = db.schema or 1
 local key = GetRealmName().."|"..(UnitGUID("player") or UnitName("player"))
 db.characters[key] = type(db.characters[key])=="table" and db.characters[key] or {}
 self.db = db.characters[key]
 self.db.name = UnitName("player")
 self.db.realm = GetRealmName()
 self.db.realmMode = self:GetRealmMode()
 self.db.faction = UnitFactionGroup("player")
 self.db.quests = self.db.quests or {}
 self.db.manual = self.db.manual or {}
 self.db.knownObjectives = self.db.knownObjectives or {}
 self.db.achievements = self.db.achievements or {}
 self.db.discovered = self.db.discovered or {}
 self.db.repeatables = self.db.repeatables or {}
 -- A history-derived phase was only a hint. On Solo Progress the server reply
 -- is authoritative and may legitimately be lower after .ip low.
 if self.realmMode=="Solo Progress" and self.db.phaseSource=="history" then
  self.db.historySuggestedPhase=self.db.phase
  self.db.phase=nil;self.db.phaseSource=nil;self.db.phaseAt=nil
  self.ipStatus="Старая автоматическая отметка по истории снята. Нажмите «Запросить мой этап», чтобы получить точное значение сервера."
 end
 self.completedNow=nil;self.historyReady=false;self.phaseFresh=false;self.queryPending=nil;self.lastQuery=nil
 self.liveAchievements={}
 self.helpIndex=nil;self.helpByKey=nil
 self.active = true
 self:ScanLog()
 self:ScanAchievements()
 for _,event in ipairs({"QUEST_LOG_UPDATE","QUEST_QUERY_COMPLETE","QUEST_COMPLETE","QUEST_FINISHED","CHAT_MSG_COMBAT_FACTION_CHANGE","BAG_UPDATE","PLAYER_LEVEL_UP","ACHIEVEMENT_EARNED","GET_ITEM_INFO_RECEIVED","CHAT_MSG_SYSTEM","BANKFRAME_OPENED","BANKFRAME_CLOSED","PLAYER_LOGOUT"}) do self.events:RegisterEvent(event) end
 self:QueryQuests(true)
 self:CreateLauncher()
 self:Print("v"..self.version.." готов для реалма "..self.db.realmMode..". /spg — открыть путеводитель; «Мой этап» — восстановить текущее положение.")
end
function G:QueryQuests(silent)
 if not self.active or self.queryPending then return end
 if self.lastQuery and GetTime()-self.lastQuery<15 then
  if not silent then self:Print("История недавно запрошена. Повтор доступен через 15 секунд.") end
  return
 end
 self.lastQuery=GetTime()
 self.queryPending=GetTime()+10
 self.queryState="Запрашиваем историю заданий..."
 QueryQuestsCompleted()
 self:Changed()
end
function G:ReadHistory()
 if not self.active then return end
 local history={}
 local ok,result=pcall(GetQuestsCompleted,history)
 if not ok then self.queryState="Не удалось прочитать историю. Нажмите «Обновить».";self.queryPending=nil;return end
 if type(result)=="table" then history=result end
 self.completedNow={}
 local n=0
 for id,done in pairs(history) do
  if done and done~=0 and tonumber(id) then self.db.quests[tonumber(id)]=true;self.completedNow[tonumber(id)]=true;n=n+1 end
 end
 self.queryPending=nil
 self.historyReady=true
 self.db.historyAt=time()
 self.queryState="Сервер вернул "..n.." сданных заданий всего (включая прокачку)"
 self:RepeatableProgress(8302)
 self:ScanLog()
 self:ScanAchievements()
 local inferred,why=self:HistoryHint()
 if self.realmMode=="Solo" and inferred and (self.db.phase==nil or inferred>self.db.phase) then
  self.db.phase=inferred;self.db.phaseSource="history";self.db.phaseAt=time();self.db.maxPhase=math.max(self.db.maxPhase or 0,inferred)
  self.ipStatus="История заданий и достижений указывает на этап "..inferred.." ("..why..")."
 elseif self.realmMode=="Solo Progress" and inferred then
  self.db.historySuggestedPhase=inferred
  self.ipStatus="История содержит ориентир до этапа "..inferred.." ("..why.."), но текущий этап она не меняет. Нажмите «Запросить мой этап»."
 end
 self:Changed()
end
function G:ScanLog()
 if not self.active then return end
 self.questLog={}
 for i=1,GetNumQuestLogEntries() do
  local title,_,_,header,_,complete,_,id=GetQuestLogTitle(i)
  if not header and title then
   if not id or id==0 then id=tonumber((GetQuestLink(i) or ""):match("quest:(%d+)")) end
   if id then
    local objectives={}
    for j=1,GetNumQuestLeaderBoards(i) do
     local text,kind,finished=GetQuestLogLeaderBoard(j,i)
     objectives[#objectives+1]={text=text or "",kind=kind,done=finished}
    end
    self.questLog[id]={title=title,complete=complete==1,objectives=objectives,index=i}
    if title=="Военные действия" or title=="War Effort" then self.db.discovered.war=id end
    -- A resource quest has one collection objective. Only live objective text verifies the amount.
    for _,row in ipairs(self.resources[self.db.faction] or {}) do
     if row[1]==id and #objectives==1 then
      local current,needed=objectives[1].text:match("(%d+)%s*/%s*(%d+)")
      if needed and tonumber(needed)>0 then self.db.knownObjectives[id]={needed=tonumber(needed),at=time()} end
     end
    end
   end
  end
 end
 self:Changed()
end
function G:QuestState(id)
 if id==8302 and self.RepeatableQuestState then return self:RepeatableQuestState() end
 if self.questLog[id] then return "active", self.questLog[id].complete and "Готово к сдаче" or "В журнале" end
 if self.completedNow and self.completedNow[id] then return "done","Сдано" end
 if self.db.quests[id] then return "history","Сдано ранее" end
 return "unknown", self.historyReady and "Не сдано" or "Не проверено"
end
function G:NormalizeHelp(text)
 local upper="АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
 local lower="абвгдеёжзийклмнопрстуфхцчшщъыьэюя"
 text=text or ""
 for i=1,#upper,2 do text=text:gsub(upper:sub(i,i+1),lower:sub(i,i+1)) end
 text=text:gsub("[A-Z]",function(c) return string.char(c:byte()+32) end)
 text=text:gsub("ё","е"):gsub("’", " "):gsub("‘", " "):gsub("`", " ")
 return (text:gsub("[%[%]%(%)%.,!?;:/%-%_'\"]"," "):gsub("[ \t\r\n]+"," "))
end
function G:BuildHelpIndex()
 if self.helpIndex then return end
 self.helpIndex={};self.helpByKey={}
 local source="https://docs.google.com/document/d/1rFZtORJEa9sB690lUD0MLYyOLiTW6jZxrvvBxPASqCc/"
 local aliases={[0]="он мк mc molten core руны",[1]="ониксия лкт bwl",[2]="лкт bwl бвл убpс ubrs",[3]="ак aq анкираж скоробей скоробея",[4]="ак aq анкираж",[5]="ак aq анкираж",[6]="накс naxx",[8]="кара каражан бк tbc",[9]="сск ssc кт tk",[10]="бт bt хиджал",[16]="цлк icc"}
 local function add(e)
  e.chatText=self.shortHelp[e.key] or e.chatText or (e.quest and ("«"..e.title.."»."))
  e.chatSpoiler=self.shortSpoilers[e.key] or self.shortSpoilers[e.spoilerKey]
  e.search=self:NormalizeHelp(e.title.." "..(e.tags or "").." "..table.concat(e.steps or {}," ").." "..(e.spoiler or "").." "..(aliases[e.stage] or ""))
  self.helpIndex[#self.helpIndex+1]=e;self.helpByKey[e.key]=e
 end
 for _,e in ipairs(self.helpTopics) do e.source=e.source or source;add(e) end
 for id=0,18 do
  local s=self.stages[id]
  for i,step in ipairs(s.steps) do
   local key=id..":"..i
   local spoiler=step.spoiler or (i==1 and self.stageSpoilers[id])
   add({key="step:"..key,stage=id,title=step[1],steps={step[2]},source=source,
    tags=s.title,spoilerKey=spoiler,spoiler=spoiler and (self.spoilers[spoiler].text.." "..self.botInstructions) or nil,
    url=step.quest and self:QuestURL(step.quest) or nil})
  end
  for i,n in ipairs(self.guideNotes[id] or {}) do
   add({key="note:"..id..":"..i,stage=id,title=n[1],steps={n[2]},tags=s.title,source=source})
  end
  for _,cid in ipairs(s.chains) do
   local c=self.chains[cid]
   if c and (c.faction=="Both" or c.faction==self.db.faction) then
     for _,q in ipairs(c.quests or {}) do
     local key="quest:"..q.id
     if not self.helpByKey[key] then
      local detail=self.questHelp[q.id]
      add({key=key,stage=id,quest=q.id,title=q.title,tags=c.title.." "..q.zone,
       intro="Цепочка: "..c.title..". "..self:QuestLevelLabel(self.questMetadata[q.id]),
       steps=detail and detail.steps or {q.title},walkthrough=detail and detail.steps,
       entityRefs=detail and detail.refs,serverNote=detail and detail.serverNote,source=detail and detail.serverNote and source,
       chatText=detail and table.concat(detail.steps," "),
       url=detail and detail.url or self:QuestURL(q.id).."#comments"})
     end
    end
   end
  end
 end
end
function G:SearchHelp(query,stage)
 self:BuildHelpIndex()
 local tokens={};local ignored={['как']=true,['почему']=true,['не']=true,['где']=true,['что']=true,['мне']=true,['это']=true,['работает']=true,['сделать']=true,['делать']=true,['квест']=true}
 for token in self:NormalizeHelp(query):gmatch("[^ \t\r\n]+") do if not ignored[token] then tokens[#tokens+1]=token end end
 local found={}
 for _,e in ipairs(self.helpIndex) do
  local match=#tokens>0 or stage==nil or e.stage==stage
  for _,token in ipairs(tokens) do if not e.search:find(token,1,true) then match=false;break end end
  if match then found[#found+1]=e end
 end
 return found
end
function G:HelpChatText(e,includeSpoiler)
 local text=e.chatText or table.concat(e.steps or {}," ")
 if includeSpoiler and e.spoiler then text=text.." Спойлер: "..(e.chatSpoiler or e.spoiler) end
 if e.url and not text:find(e.url,1,true) then text=text.." "..e.url end
 return text
end
function G:ChatChunks(text)
 -- 220 payload bytes plus numbering leaves room below the legacy 255-byte limit.
 text=(text or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|H.-|h(.-)|h","%1"):gsub("|","")
 local result,line={},""
 local function flush() if line~="" then result[#result+1]=line;line="" end end
 text=text:gsub("([%.!?]) +","%1\n")
 for sentence in text:gmatch("[^\r\n]+") do
  if #sentence<=220 then
   if #line+#sentence+1>220 then flush() end
   line=line=="" and sentence or line.." "..sentence
  else
   flush()
   for word in sentence:gmatch("[^ \t\r\n]+") do
    if #line+#word+1>220 then flush() end
    while #word>220 do
     local last=220
     while word:byte(last+1)>=128 and word:byte(last+1)<192 do last=last-1 end
     result[#result+1]=word:sub(1,last);word=word:sub(last+1)
    end
    if word~="" then line=line=="" and word or line.." "..word end
   end
   flush()
  end
 end
 flush()
 for i,s in ipairs(result) do result[i]="["..i.."/"..#result.."] "..s end
 return result
end
function G:HelpDraftKey(entry,spoiler,index)
 return entry.key..(spoiler and ":spoiler:" or ":plain:")..index
end
function G:GetHelpDraft(key,original)
 local draft=self.db.helpDrafts and self.db.helpDrafts[key]
 if type(draft)=="table" and draft.original==original and type(draft.text)=="string" then return draft.text end
 return original
end
function G:SaveHelpDraft(key,original,text)
 if #text>249 or not text:find("[^ \t\r\n]") then return false end
 self.db.helpDrafts=self.db.helpDrafts or {}
 self.db.helpDrafts[key]=text~=original and {original=original,text=text} or nil
 return true
end
function G:InsertHelpChat(text,world)
 if world then text=".chat "..text end
 if #text>255 then self:Print("Сообщение слишком длинное. Выберите отдельную часть.");return end
 local box=ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend() or ChatFrameEditBox
 if box and box:IsShown() and box:GetText()~="" then self:Print("В чате есть черновик. Сначала отправьте или очистите его; подсказка не вставлена.");return end
 if ChatFrame_OpenChat then ChatFrame_OpenChat(text) else self:Print("Строка чата недоступна. Используйте копирование.") end
end
function G:ProgressQuestCatalog(stageId)
 local catalog={}
 local function add(id,context,optional)
  local meta=self.questMetadata[id]
  if meta then catalog[id]={title=meta.title,context=context,level=meta.level,minLevel=meta.minLevel,optional=optional and true or nil} end
 end
 for id,s in pairs(self.stages) do
  if stageId==nil or stageId==id then
   for _,cid in ipairs(s.chains) do
    local c=self.chains[cid]
    if c and (c.faction=="Both" or c.faction==self.db.faction) then
      for _,q in ipairs(c.quests or {}) do if not q.repeatable then add(q.id,c.title,q.optional or c.optional) end end
    end
   end
   for _,step in ipairs(s.steps) do
    if step.quest then add(step.quest,s.title) end
    for _,qid in ipairs(step.quests or {}) do add(qid,s.title) end
   end
   if id==3 then
    for _,r in ipairs(self.resources[self.db.faction] or {}) do add(r[1],"Снабжение Ан’Киража") end
    if self.db.discovered.war then catalog[self.db.discovered.war]={title="Военные действия",context="Подготовка Ан’Киража"} end
   end
  end
 end
 return catalog
end
function G:QuestLevelLabel(meta)
 if not meta or not meta.level or meta.level<=0 then return "Уровень задания не указан в базе" end
 return "Уровень задания: "..meta.level..(meta.minLevel and meta.minLevel>0 and ("; доступно с "..meta.minLevel) or "")
end
function G:QuestProgressCounts(stageId)
 local total,done,missing,uncertain=0,0,0,0
 for id,meta in pairs(self:ProgressQuestCatalog(stageId)) do
  if not meta.optional then total=total+1
  local state=self:QuestState(id)
  if state=="done" then done=done+1
  elseif not self.historyReady or state=="history" then uncertain=uncertain+1
  else missing=missing+1 end end
 end
 return total,done,missing,uncertain
end
function G:StageProgress(stageId)
 local s=self.stages[stageId]
 if not (s and s.progressBySteps) then
  local total,done,missing,uncertain=self:QuestProgressCounts(stageId)
  if total>0 then return done,total,math.floor(done*100/total+0.5),uncertain end
 end
 local totalSteps,stepDone=0,0
 for i,step in ipairs(s and s.steps or {}) do
  local state=self:StepState(step,stageId..":"..i)
  if state~="info" then totalSteps=totalSteps+1;if state=="done" or state=="manual" then stepDone=stepDone+1 end end
 end
 return stepDone,totalSteps,totalSteps>0 and math.floor(stepDone*100/totalSteps+0.5) or 0,0
end
function G:AchievementDone(id)
 -- WoW 3.3.5: id, name, points, completed. Numeric points (even 0) are truthy.
 local _,_,_,completed=GetAchievementInfo(id)
 completed=completed==true
 self.liveAchievements=self.liveAchievements or {}
 self.liveAchievements[id]=completed and true or nil
 if completed then self.db.achievements[id]=true end
 return completed and true or false
end
function G:ScanAchievements()
 if not self.active then return end
 self.liveAchievements={}
 for _,s in pairs(self.stages) do
  for _,step in ipairs(s.steps) do
   if step.achievement then self:AchievementDone(step.achievement) end
   for _,id in ipairs(step.achievements or {}) do self:AchievementDone(id) end
  end
 end
 self:Changed()
end
function G:HistoryHint()
 -- Historical lower bound is only a suggestion: .ip low can lower the current phase.
 local hints={{10259,8,"задание у Тёмного портала"},{10445,10,"допуск в Хиджал"},{10949,10,"допуск в Чёрный храм"}}
 local phase,why
 local currentQuests=self.historyReady and self.completedNow or self.db.quests
 for _,h in ipairs(hints) do if currentQuests and currentQuests[h[1]] and (not phase or h[2]>phase) then phase,why=h[2],h[3] end end
 local achievements={{686,1},{685,3},{687,6},{690,9},{696,10},{697,11},{691,12},{698,13},{575,14},{3916,16},{4597,17},{4815,18}}
 for _,a in ipairs(achievements) do if self.liveAchievements and self.liveAchievements[a[1]] and (not phase or a[2]>phase) then phase,why=a[2],"достижения этого персонажа" end end
 if not phase and select(2,UnitClass("player"))=="DEATHKNIGHT" then phase,why=13,"особенность старта рыцаря смерти (нужна сверка)" end
 return phase,why
end
function G:SetPhase(value,source)
 value=tonumber(value)
 if not self.active or not value or value%1~=0 or value<0 or value>18 then return false end
 local previousPhase=self.db.phase
 self.db.phase=value
 self.selectedStage=nil
 self.db.phaseSource=source or "manual"
 self.db.phaseAt=time()
 self.db.maxPhase=math.max(self.db.maxPhase or 0,value)
 self.phaseFresh=source=="server"
 self:Changed()
 self:Print("Этап "..value..": "..self.stages[value].title..(source=="server" and " (ответ сервера)." or " (указано вручную; серверный прогресс не менялся)."))
 if value==3 and previousPhase~=3 then
  self:Print("С начала этапа 3 доступна полная цепочка допуска в Зул’Гуруб: от «Духов крикунов» до «Длани Растахана». Откройте этап 3 в /spg: Зул’Гуруб и варианты допуска Ан’Киража показаны отдельно. Рейд необязателен для перехода.")
 end
 return true
end
function G:RequestPhase()
 if not self.active then return end
 if self.realmMode=="Solo" then
  self.ipStatus="Реалм Solo: обновляем историю выполненных заданий вместо .ip get..."
  self:QueryQuests(false)
  self:Changed()
  return
 end
 if InCombatLockdown() or UnitIsDeadOrGhost("player") then self:Print("Запросите этап вне боя и после воскрешения.");return end
 if self.ipPending or (self.lastIP and GetTime()-self.lastIP<10) then return end
 if not UnitExists("target") or not UnitIsUnit("target","player") then
  self.ipStatus="Сначала нажмите «1. Выбрать себя целью», затем «2. Запросить этап»."
  self:Print("Сначала выберите себя целью первой кнопкой, затем повторите запрос.")
  self:Changed();return
 end
 self.lastIP=GetTime();self.ipPending=GetTime()+8
 self.ipLines={};self.ipStatus="Ждём ответ сервера..."
 SendChatMessage(".ip get","SAY")
 self:Changed()
end
function G:HandleSystem(message)
 if not self.ipPending then return end
 local text=(message or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|H.-|h(.-)|h","%1")
 if #self.ipLines<8 then self.ipLines[#self.ipLines+1]=text end
 -- Exact upstream grammar: no guessing from numbers in other system messages.
 local name,value=text:match("^Progression Level for (.-) = (%d+)%s*$")
 if name and name==UnitName("player") and tonumber(value)<=18 then
  self.ipPending=nil
  self.ipStatus="Ответ сервера принят: этап "..value
  self.db.lastIP=text
  self:SetPhase(value,"server")
  self.selectedStage=nil
  if self.window then self:Navigate("journey") else self.page="journey" end
  return
 end
 self:Changed()
end
function G:ResourceState(row)
 local state,label=self:QuestState(row[1])
 local live=self.db.knownObjectives[row[1]]
 local needed=live and live.needed or row[4]
 local bags=GetItemCount(row[2],false) or 0
 -- Bank is intentionally not used: it may be stale and custom reagent storage is invisible.
 return state,label,bags,needed,live~=nil
end
function G:ResourceProgress()
 local done=0
 for _,r in ipairs(self.resources[self.db.faction] or {}) do if self:QuestState(r[1])=="done" then done=done+1 end end
 return done,15
end
function G:QuestFinished(id)
 local state=self:QuestState(id)
 return state=="done" or state=="history"
end
function G:ItemStorageLabel(itemID)
 local bags=GetItemCount(itemID,false) or 0
 if bags>0 then return "Получен (инвентарь)" end
 local total=GetItemCount(itemID,true) or 0
 if total>bags then return "Получен (банк)" end
end
function G:WarEffortState()
 if self.db.discovered.war then return self:QuestState(self.db.discovered.war) end
 for _,id in ipairs({8286,8288,8301,8302,8303,8305}) do
  local state=self:QuestState(id)
  if state=="active" or state=="done" or state=="history" then
   return "done","Выполнено: ветка Скипетра уже открылась"
  end
 end
 local done=self:ResourceProgress()
 if done==15 then return "active","15 / 15; теперь сдайте 100 жетонов главнокомандующему" end
 return "unknown","Сначала завершите 15 / 15 ресурсных заданий"
end
function G:NozdormuProgress()
 if not GetFactionInfoByID then return nil end
 local name,_,standing,barMin,barMax,barValue=GetFactionInfoByID(910)
 if not name or not standing then return nil end
 local labels={"Ненависть","Враждебность","Неприязнь","Равнодушие","Дружелюбие","Уважение","Почтение","Превознесение"}
 local standingLabel=GetText and GetText("FACTION_STANDING_LABEL"..standing,UnitSex and UnitSex("player"))
 return standingLabel or labels[standing] or name,standing,barMin,barMax,barValue
end
function G:NozdormuStanding()
 local label,standing=self:NozdormuProgress()
 return label,standing
end
function G:RepeatableProgress(id)
 local target=id==8302 and 5 or 1
 self.db.repeatables=self.db.repeatables or {}
 local record=self.db.repeatables[id]
 if type(record)~="table" then record={count=0};self.db.repeatables[id]=record end
 local count=math.max(0,math.min(target,tonumber(record.count) or 0))
 local later=self.questLog[8303] or (self.completedNow and self.completedNow[8303]) or self.db.quests[8303]
 local _,standingID=self:NozdormuStanding()
 if later or (standingID and standingID>=4) then
  count=target;record.count=count;record.inferredComplete=true
 elseif count==0 and ((self.completedNow and self.completedNow[id]) or self.db.quests[id]) then
  count=1;record.count=1;record.estimated=true
 end
 return count,target,record.estimated and true or false
end
function G:RepeatableQuestState()
 local count,target,estimated=self:RepeatableProgress(8302)
 if count>=target then return "done","Повторные сдачи: "..count.." / "..target end
 local log=self.questLog[8302]
 local ready=(log and log.complete) or (GetItemCount(20384,false) or 0)>=200
 local suffix=estimated and "; минимум по истории" or ""
 if ready then return "active","Готово к сдаче; повторы: "..count.." / "..target..suffix end
 if log then return "active","В журнале; повторы: "..count.." / "..target..suffix end
 if count>0 then return "active","Сдано повторов: "..count.." / "..target..suffix end
 return "unknown","Повторные сдачи: 0 / "..target
end
function G:AdjustRepeatable(id,delta)
 local count,target=self:RepeatableProgress(id)
 local record=self.db.repeatables[id]
 record.count=math.max(0,math.min(target,count+(tonumber(delta) or 0)))
 record.estimated=nil;record.inferredComplete=nil;record.manual=true;record.at=time()
 self:Changed()
end
function G:BeginRepeatableTurnIn(id)
 if id~=8302 then return end
 local _,standing,_,_,value=self:NozdormuProgress()
 self.pendingRepeatable={id=id,standing=standing,value=value,at=GetTime()}
end
function G:CheckRepeatableTurnIn()
 local pending=self.pendingRepeatable
 if not pending then return end
 local _,standing,_,_,value=self:NozdormuProgress()
 local advanced=standing and pending.standing and (standing>pending.standing or (standing==pending.standing and value and pending.value and value>pending.value))
 if advanced then
  self:AdjustRepeatable(pending.id,1);self.pendingRepeatable=nil;self.repeatableCheckDue=nil
  local count,target=self:RepeatableProgress(pending.id)
  self:Print("«Рука праведника»: учтена повторная сдача "..count.." / "..target..".")
 elseif GetTime()-(pending.at or 0)>=5 then
  self.pendingRepeatable=nil;self.repeatableCheckDue=nil
 else self.repeatableCheckDue=GetTime()+0.5 end
end
function G:ScepterPathState()
 if GetItemCount(21175,false)>0 then return "done","Скипетр при себе" end
 if self:QuestFinished(8742) or self:QuestFinished(8745) then return "done","Цепочка Скипетра завершена" end
 if self.db.pathChoice=="mallet" then return "info","Не выбрана: вы отметили путь Молота" end
 local chain=self.chains[10]
 for _,q in ipairs(chain and chain.quests or {}) do
  if self.questLog[q.id] then
   if q.id==8302 then
    local standing,standingID=self:NozdormuStanding()
    if standingID and standingID>=4 then return "active","Репутация: "..standing.."; проверьте задание «Анахронос»" end
    local count,target=self:RepeatableProgress(8302)
    if count>=target then return "active","Повторные сдачи «Руки праведника»: "..count.." / "..target.."; больше повторять не нужно, проверьте «Анахронос»" end
    return "active","Сейчас: «Рука праведника» — повторные сдачи "..count.." / "..target..(standing and ("; репутация: "..standing) or "")
   end
   return "active","Сейчас: «"..q.title.."»"
  end
 end
 for _,id in ipairs({8305,8519,8555,8303,8302,8301,8288,8286}) do
  if self:QuestFinished(id) then return "active","Ветка начата; продолжайте цепочку Скипетра" end
 end
 if self.db.pathChoice=="scepter" then return "active","Выбран путь Скипетра; начните с «Что ждёт нас завтра»" end
 return "unknown","Основная наградная ветка"
end
function G:MalletPathState()
 if self.db.phase and self.db.phase>3 and self.db.pathChoice=="mallet" then return "done","Гонг уже пройден путём Молота" end
 if GetItemCount(9240,false)>0 then return "active","Молот Зул’Фаррака при себе" end
 if GetItemCount(9241,false)>0 then return "active","Священный молот при себе; отнесите его к алтарю" end
 if self.db.pathChoice=="mallet" then return "active","Выбран путь Молота" end
 local scepterState=self:ScepterPathState()
 if scepterState=="active" or scepterState=="done" then return "info","Альтернатива не выбрана: вы на ветке Скипетра" end
 return "info","Необязательная короткая альтернатива"
end
function G:AQCurrentAction()
 local resources=self:ResourceProgress()
 if resources<15 then return "Сначала завершите оставшиеся ресурсные задания: "..resources.." / 15." end
 local warState,warText=self:WarEffortState()
 if warState~="done" then return warText..". Это отдельное задание «Военные действия», а не ещё одна ресурсная сдача." end
 if self.questLog[8302] then
  local standing,standingID=self:NozdormuStanding()
  if standingID and standingID>=4 then return "Ресурсы и «Военные действия» уже завершены. Репутация с Родом Ноздорму — "..standing..". Проверьте у Баристолфа или Анахроноса задание «Анахронос»." end
  local count,target=self:RepeatableProgress(8302)
  if count>=target then return "Ресурсы и «Военные действия» завершены. Повторные сдачи «Руки праведника»: "..count.." / "..target..". Больше панцири для продолжения не нужны; проверьте «Анахронос»." end
  return "Ресурсы и «Военные действия» уже завершены. Вы идёте по ветке Скипетра. «Руку праведника» нужно сдать ещё "..(target-count).." раз: сейчас "..count.." / "..target.." повторов. Каждая сдача требует 200 панцирей"..(standing and (". Текущая репутация: "..standing) or "").."."
 end
 if self.db.pathChoice=="mallet" then return "Подготовка завершена. Вы выбрали отдельную короткую ветку Молота; откройте её карточку ниже и проверьте оба предметных шага." end
 local state,text=self:ScepterPathState()
 if state=="active" or state=="done" then return "Ресурсы и «Военные действия» завершены. Вы на ветке Скипетра. "..text.."." end
 return "Подготовка завершена. Теперь выберите одну отдельную ветку: наградную цепочку Скипетра или необратимый короткий путь Молота."
end
function G:StepState(step,key)
 if step.informational then return "info","" end
 if step.resource then local n=self:ResourceProgress();return n==15 and "done" or "active",n.." / 15 заданий" end
 if step.special=="runes" and self.liveAchievements and self.liveAchievements[686] then return "done","Засчитано по победе над Рагнаросом; квесты не подтверждены" end
 if step.quest then return self:QuestState(step.quest) end
 if step.quests then
  for _,id in ipairs(step.quests) do if self:QuestState(id)=="done" then return "done","Сдано" end end
  for _,id in ipairs(step.quests) do if self.questLog[id] then return "active","В журнале" end end
 end
 if step.achievement and self.liveAchievements and self.liveAchievements[step.achievement] then return "done","Выполнено: достижение" end
 for _,id in ipairs(step.achievements or {}) do if self.liveAchievements and self.liveAchievements[id] then return "done","Выполнено: достижение" end end
 if step.special=="war" then return self:WarEffortState() end
 if step.special=="scepterPath" then return self:ScepterPathState() end
 if step.special=="malletPath" then return self:MalletPathState() end
 if step.special=="gong" and self.db.phase and self.db.phase>3 then return "done","Этап гонга уже пройден" end
 -- Only a fresh server reply can close these milestones; saved/manual phases are not evidence.
 if step.serverPhase and self.realmMode=="Solo Progress" and self.phaseFresh and self.db.phaseSource=="server" and self.db.phase and self.db.phase>=step.serverPhase then
  return "done",step.serverPhaseStatus
 end
 if self.db.manual[key] then return "manual","Отмечено вами" end
 if step.achievement or step.achievements then return "unknown","Достижение ещё не получено" end
 return "unknown",""
end
function G:ToggleManual(key)
 if not self.active then return end
 self.db.manual[key]=not self.db.manual[key] or nil
 self:Changed()
end
function G:ChoosePath(path)
 if path~="scepter" and path~="mallet" then return end
 self.db.pathChoice=path
 self.aqPathChoiceReview=nil;self.aqPathPreview=nil;self.focusChosenPath=true
 self:Changed()
end
function G:PhaseLabel()
 if self.db.phase==nil then return "Этап ещё не определён" end
 if self.realmMode=="Solo" and self.db.phaseSource=="history" then return "Последний подтверждённый этап: "..self.db.phase.." (каждый этап проверяется отдельно)" end
 local source=self.db.phaseSource=="server" and (self.phaseFresh and "сервер" or "сохранённый ответ") or self.db.phaseSource=="history" and "история заданий и достижений" or "ваша отметка"
 return "Этап "..self.db.phase.." - "..source
end
function G:OnEvent(event,...)
 if event=="PLAYER_LOGIN" then self:Init();return end
 if not self.active then return end
 if event=="PLAYER_LOGOUT" then self:SaveView()
 elseif event=="QUEST_QUERY_COMPLETE" then self:ReadHistory()
 elseif event=="CHAT_MSG_SYSTEM" then self:HandleSystem(...)
 elseif event=="QUEST_LOG_UPDATE" then self.scanDue=GetTime()+0.3
 elseif event=="QUEST_FINISHED" then self.refreshDue=GetTime()+1;if self.pendingRepeatable then self.repeatableCheckDue=GetTime()+0.5 end
 elseif event=="CHAT_MSG_COMBAT_FACTION_CHANGE" then if self.pendingRepeatable then self.repeatableCheckDue=GetTime()+0.5 end
 elseif event=="QUEST_COMPLETE" then
  if GetQuestID then
   local id=GetQuestID(); local title=GetTitleText()
   if id and (title=="Военные действия" or title=="War Effort") then self.db.discovered.war=id end
   if id==8302 then self:BeginRepeatableTurnIn(id) end
  end
 elseif event=="ACHIEVEMENT_EARNED" then
  local id=tonumber((...));local had=id and self.liveAchievements and self.liveAchievements[id]
  self:ScanAchievements()
  if id and not had and self.liveAchievements and self.liveAchievements[id] then
   local _,title=GetAchievementInfo(id)
   self:Print("Цель отмечена автоматически: "..(title or tostring(id))..". Текущий этап можно уточнить в «Мой этап».")
  end
 else self:Changed() end
end
G.events:SetScript("OnEvent",function(_,event,...) G:OnEvent(event,...) end)
G.events:SetScript("OnUpdate",function(_,elapsed)
 if not G.active then return end
 G.tick=(G.tick or 0)+elapsed;if G.tick<0.2 then return end;G.tick=0
 local now=GetTime()
 if G.queryPending and now>=G.queryPending then G.queryPending=nil;G.queryState="Сервер не вернул историю. Нажмите «Обновить».";G:Changed() end
 if G.ipPending and now>=G.ipPending then
  G.ipPending=nil;G.ipStatus="Формат ответа не распознан. Сверьте чат и выберите этап ниже."
  G.db.lastIP=table.concat(G.ipLines or {},"\n");G:Changed()
 end
 if G.scanDue and now>=G.scanDue then G.scanDue=nil;G:ScanLog() end
 if G.repeatableCheckDue and now>=G.repeatableCheckDue then G:CheckRepeatableTurnIn() end
 if G.refreshDue and now>=G.refreshDue and not G.queryPending and (not G.lastQuery or now-G.lastQuery>=15) then G.refreshDue=nil;G:QueryQuests(true) end
 if G.dirty and G.window and G.window:IsShown() then G.dirty=nil;G:Render() end
end)
G.events:RegisterEvent("PLAYER_LOGIN")
SLASH_SOLOPROGRESSGUIDE1="/spg"
SLASH_SOLOPROGRESSGUIDE2="/soloprogress"
SlashCmdList.SOLOPROGRESSGUIDE=function(msg)
 if not G.active then G:Print("Этот путеводитель работает только на реалмах Solo и Solo Progress.");return end
 local command,arg=(msg or ""):match("^(%S*)%s*(.-)$")
 if command=="phase" then
  if not G:SetPhase(arg,"manual") then G:Print("/spg phase 0–18 — локальная отметка; для ответа сервера откройте «Мой этап».") end
 elseif command=="refresh" then G:QueryQuests(false)
 elseif command=="scale" then
  local scale=tonumber(arg)
  if scale and scale>=0.65 and scale<=1.2 then SoloProgressGuideDB.ui.scale=scale;if G.window then G:ApplyScale() end else G:Print("/spg scale 0.65–1.2") end
 else G:Toggle() end
end
