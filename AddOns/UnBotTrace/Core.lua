UnBotTrace = { active = false, maxEntries = 1000, timeout = 900, version = "1.2.0" };

function UnBotTrace.Text(value, limit)
	local value = tostring(value or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
		:gsub("|H.-|h(.-)|h", "%1"):gsub("[\r\n\t]", " ");
	limit = limit or 700;
	if (#value > limit) then
		local cut = limit;
		while (cut > 0 and (value:byte(cut + 1) or 0) >= 128
			and (value:byte(cut + 1) or 0) < 192) do cut = cut - 1; end
		value = value:sub(1, cut).."...";
	end
	return value;
end

function UnBotTrace.Safe(method, ...)
	local ok, err = pcall(UnBotTrace[method], ...);
	if (not ok) then
		if (UnBotTrace.sweep) then UnBotTrace.sweep.active = false; end
		UnBotTrace.active = false;
		UnBotTrace.error = UnBotTrace.Text(err);
		if (UnBotTrace.run) then UnBotTrace.run.loggerError = UnBotTrace.error; end
	end
end

function UnBotTrace.Add(kind, message, target)
	if (not UnBotTrace.active) then return; end
	local run = UnBotTrace.run;
	run.total = run.total + 1;
	local row = {seq = run.total, ms = math.floor((GetTime() - UnBotTrace.started) * 1000 + 0.5),
		kind = kind, text = UnBotTrace.Text(message), target = UnBotTrace.Text(target, 80)};
	if (#run.events >= UnBotTrace.maxEntries) then table.remove(run.events, 1); run.dropped = run.dropped + 1; end
	run.events[#run.events + 1] = row;
	UnBotTrace.dirty = true;
end

function UnBotTrace.Start()
	if (UnBotTrace.active) then UnBotTrace.Show(); return; end
	UnBotTraceDB = UnBotTraceDB or {};
	UnBotTraceDB.runs = UnBotTraceDB.runs or {};
	local run = {version = UnBotTrace.version, unbotVersion = GetAddOnMetadata("UnBotCustom", "Version"),
		startedAt = time(), player = UnitName("player"), realm = GetRealmName(),
		zone = GetRealZoneText(), events = {}, total = 0, dropped = 0, status = "recording"};
	table.insert(UnBotTraceDB.runs, 1, run);
	while (#UnBotTraceDB.runs > 2) do table.remove(UnBotTraceDB.runs); end
	UnBotTrace.run = run;
	UnBotTrace.active = true;
	UnBotTrace.started = GetTime();
	UnBotTrace.names = {};
	UnBotTrace.namesCount = 0;
	UnBotTrace.lastSnapshot = nil;
	UnBotTrace.lastCommand = "Ещё не было";
	UnBotTrace.lastCommandAt = nil;
	UnBotTrace.bucket = nil;
	UnBotTrace.bucketCount = 0;
	UnBotTrace.peak = 0;
	UnBotTrace.error = nil;
	UnBotTrace.Add("СТАРТ", "Включите запись экрана, затем нажмите Призвать в UnBot.");
	UnBotTrace.Snapshot();
	UnBotTrace.Show();
end

function UnBotTrace.Stop(reason)
	if (UnBotTrace.sweep and UnBotTrace.sweep.active) then
		UnBotTrace.SweepStop(reason or "Остановлено пользователем; текущий бот может остаться в группе.");
	end
	if (not UnBotTrace.active) then return; end
	UnBotTrace.Add("СТОП", reason or "Остановлено пользователем");
	UnBotTrace.active = false;
	UnBotTrace.run.status = reason or "stopped";
	UnBotTrace.run.endedAt = time();
	UnBotTrace.dirty = true;
end

function UnBotTrace.Remember(name)
	if (name and not UnBotTrace.names[name] and UnBotTrace.namesCount < 1000) then
		UnBotTrace.names[name] = true;
		UnBotTrace.namesCount = UnBotTrace.namesCount + 1;
	end
end

function UnBotTrace.Command(api, message, channel, target)
	if (not UnBotTrace.active) then return; end
	if (api == "SendChatMessage" and channel ~= "SAY" and channel ~= "WHISPER"
		and channel ~= "RAID" and channel ~= "PARTY") then return; end
	local now = GetTime();
	local bucket = math.floor(now);
	if (UnBotTrace.bucket ~= bucket) then UnBotTrace.bucket = bucket; UnBotTrace.bucketCount = 0; end
	UnBotTrace.bucketCount = UnBotTrace.bucketCount + 1;
	UnBotTrace.peak = math.max(UnBotTrace.peak, UnBotTrace.bucketCount);
	local gap = UnBotTrace.lastCommandAt and math.floor((now - UnBotTrace.lastCommandAt) * 1000 + 0.5);
	UnBotTrace.lastCommandAt = now;
	UnBotTrace.Remember(target);
	local name = tostring(message or ""):match("^%.playerbot bot %S+ (.+)$");
	UnBotTrace.Remember(name);
	UnBotTrace.lastCommand = api.." "..UnBotTrace.Text(message, 200)
		..(target and (" -> "..UnBotTrace.Text(target, 80)) or "");
	UnBotTrace.Add("КОМАНДА", UnBotTrace.lastCommand.." ["..tostring(channel or "")
		.."; интервал "..tostring(gap or "-").." мс]", target);
	-- The hook observes the client API call, not server delivery/acceptance.
	UnBotTrace.Snapshot();
end

function UnBotTrace.Snapshot()
	if (not UnBotTrace.active) then return; end
	local bot, stage = "—", "Наблюдение";
	if (UnBotTrace.sweep and UnBotTrace.sweep.active) then
		local test = UnBotTrace.sweep;
		bot = test.names[test.index] or "—";
		stage = "Прогон "..test.index.."/"..#test.names.."; следующий шаг: "
			..(test.phase == "add" and "призвать" or test.phase == "kick" and "выгнать из группы" or "отключить");
	elseif (UnBotSummonLog and UnBotSummonLog.Context) then
		local s, check, builder, gate, buff, reserve = UnBotSummonLog.Context();
		if (s and s.active) then bot = s.requestedName or s.candidate or "—"; stage = s.stage or "Призыв";
		elseif (check and check.active) then bot = check.currentName or "—"; stage = "Проверка спеков: "..tostring(check.mode);
		elseif (gate and gate.active) then stage = "Проверка прибытия: "..tostring(gate.stage);
		elseif (buff and buff.active) then stage = "Баффы: "..tostring(buff.stage);
		elseif (reserve and reserve.active) then stage = "Резерв: "..tostring(reserve.stage); end
	end
	local raid = GetNumRaidMembers();
	local count = raid > 0 and raid or GetNumPartyMembers();
	local online = 0;
	local roster = {};
	for i = 1, math.min(count, 40) do
		local unit = (raid > 0 and "raid" or "party")..i;
		local name = UnitName(unit);
		if (name) then
			UnBotTrace.Remember(name);
			local connected = UnitIsConnected(unit) and true or false;
			if (connected) then online = online + 1; end
			roster[#roster + 1] = name..(connected and " +" or " офлайн");
		end
	end
	table.sort(roster);
	UnBotTrace.bot, UnBotTrace.stage = bot, stage;
	UnBotTrace.rosterLabel = (raid > 0 and "Рейд" or "Группа")..": "..tostring(count)
		.." участников, онлайн "..online..(raid > 0 and "" or " (+ вы)");
	local snapshot = stage.." | "..bot.." | "..table.concat(roster, ", ");
	if (snapshot ~= UnBotTrace.lastSnapshot) then
		UnBotTrace.lastSnapshot = snapshot;
		UnBotTrace.Add("ЭТАП", snapshot);
	end
end

function UnBotTrace.InstallHooks()
	if (UnBotTrace.hooked or not hooksecurefunc) then return; end
	UnBotTrace.hooked = true;
	hooksecurefunc("SendChatMessage", function(message, channel, language, target)
		UnBotTrace.Safe("Command", "SendChatMessage", message, channel, target);
	end);
	for _, name in ipairs({"InviteUnit", "UninviteUnit", "ConvertToRaid", "SetRaidSubgroup", "SetLootMethod"}) do
		local api = name;
		if (type(_G[api]) == "function") then
			hooksecurefunc(api, function(a, b, c) UnBotTrace.Safe("Command", api, a, b, c); end);
		end
	end
	if (UnBotSummonLog) then
		hooksecurefunc(UnBotSummonLog, "Add", function(kind, text)
			if (kind == "message" or kind == "summon_stop") then UnBotTrace.Safe("Add", "UnBot", text); end
		end);
		hooksecurefunc(UnBotSummonLog, "SetEnabled", function(enabled)
			if (enabled) then UnBotTrace.Safe("Start"); end
		end);
		hooksecurefunc(UnBotSummonLog, "Begin", function()
			if (UnBotSquadConfig and UnBotSquadConfig.summonLogging) then UnBotTrace.Safe("Start"); end
		end);
	end
end

function UnBotTrace.IsSystemChat(message)
	local text = UnBotTrace.Text(message):match("^%s*(.-)%s*$");
	if text == "" then return true end
	local label = text:match("^%[([^%]]+)%]");
	if not label then return false end
	label = label:lower();
	if label == "autobalance" or label == "playerbot" or label == "unbot" then return false end
	return text:match("^%[[^%]]+%]%s*[^:]+:") ~= nil;
end

function UnBotTrace.Event(event, message, sender)
	if (event == "PLAYER_LOGIN") then
		UnBotTraceDB = UnBotTraceDB or {};
		for _, run in ipairs(UnBotTraceDB.runs or {}) do
			if (run.status == "recording") then run.status = "interrupted_unknown"; end
		end
		for _, run in ipairs(UnBotTraceDB.bossRuns or {}) do
			if run.status == "recording" then run.status = "interrupted_unknown"; end
		end
		UnBotTrace.InstallHooks();
		return;
	end
	if (not UnBotTrace.active) then return; end
	if (event == "PLAYER_LOGOUT") then UnBotTrace.Stop("player_logout"); return; end
	if (event == "CHAT_MSG_WHISPER" and not UnBotTrace.names[sender]) then return; end
	if (event == "CHAT_MSG_SYSTEM" and UnBotTrace.IsSystemChat(message)) then return; end
	if (event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE") then UnBotTrace.Snapshot();
	else UnBotTrace.Add(event == "CHAT_MSG_WHISPER" and "ОТВЕТ" or event, message, sender); end
end

UnBotTrace.events = CreateFrame("Frame", "UnBotTraceEventFrame");
for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_LOGOUT", "CHAT_MSG_WHISPER", "CHAT_MSG_SYSTEM",
	"UI_ERROR_MESSAGE", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "PLAYER_LEAVING_WORLD"}) do
	UnBotTrace.events:RegisterEvent(event);
end
UnBotTrace.events:SetScript("OnEvent", function(self, event, ...) UnBotTrace.Safe("Event", event, ...); end);
UnBotTrace.events:SetScript("OnUpdate", function(self, elapsed)
	if (not UnBotTrace.active) then return; end
	self.elapsed = (self.elapsed or 0) + elapsed;
	if (self.elapsed < 0.1) then return; end
	self.elapsed = 0;
	UnBotTrace.Safe("SweepTick");
	UnBotTrace.Safe("Snapshot");
	if (not (UnBotTrace.sweep and UnBotTrace.sweep.active)
		and GetTime() - UnBotTrace.started >= UnBotTrace.timeout) then
		UnBotTrace.Safe("Stop", "Лимит записи: 15 минут (либо завершён длинный прогон)");
	end
end);

function UnBotTrace.SweepBlocked()
	if (UnBotMarket and (UnBotMarket.job or UnBotMarket.trade)) then
		return "Сначала остановите скан или торговую операцию UnBotMarket.";
	end
	if (UnitAffectingCombat("player") or (InCombatLockdown and InCombatLockdown())) then
		return "Прогон остановлен: персонаж в бою.";
	end
	if (UnitIsDeadOrGhost("player")) then return "Прогон остановлен: персонаж мёртв."; end
	if (UnBotSummonLog and UnBotSummonLog.Context) then
		local s, check, builder, gate, buff, reserve = UnBotSummonLog.Context();
		if ((s and s.active) or (check and (check.active or (check.autoStartAt or 0) > 0))
			or (gate and gate.active) or (buff and buff.active) or (reserve and reserve.active)) then
			return "Сначала остановите другой призыв, проверку, баффы или подготовку резерва UnBot.";
		end
	end
	for _, name in ipairs({"UnBotBotScanner", "UnBotJunkCleaner", "UnBotDKSpecBalance",
		"UnBotFastJunkRaid", "UnBotGroundChest", "UnBotLockboxService", "UnBotSquadRoleAction"}) do
		local state = _G[name];
		if (type(state) == "table" and state.active) then return "Сначала остановите сервис UnBot: "..name; end
	end
	return nil;
end

function UnBotTrace.SweepMessage(text)
	UnBotTrace.Add("ПРОГОН", text);
	UnBotTrace.Show();
	if (DEFAULT_CHAT_FRAME) then DEFAULT_CHAT_FRAME:AddMessage("|cff70ddd0[UnBotTrace]|r "..text); end
end

function UnBotTrace.SweepStop(reason)
	local test = UnBotTrace.sweep;
	if (not test or not test.active) then return; end
	test.active = false;
	UnBotTrace.run.sweep.status = reason;
	UnBotTrace.SweepMessage(reason);
	-- No cleanup burst on stop, logout or combat. Only the explicit timed steps
	-- below may send commands; retained members can be removed manually.
end

function UnBotTrace.SweepStart()
	if (UnBotTrace.sweep and UnBotTrace.sweep.active) then
		UnBotTrace.SweepMessage("Прогон уже идёт; повторный клик не начинает его заново."); return;
	end
	local blocked = UnBotTrace.SweepBlocked();
	if (blocked) then UnBotTrace.SweepMessage(blocked); return; end
	if (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0) then
		UnBotTrace.SweepMessage("Для прогона сначала выйдите из группы/рейда, включая офлайн-резерв."); return;
	end
	if (not UnBotBotRegistry or type(UnBotBotRegistry.bots) ~= "table") then
		UnBotTrace.SweepMessage("Реестр UnBot недоступен. Включите UnBot Custom с собранным реестром."); return;
	end
	if (UnBotRegistryMatchesCurrentContext and not UnBotRegistryMatchesCurrentContext(UnBotBotRegistry)) then
		UnBotTrace.SweepMessage("Реестр не соответствует текущему реалму и фракции."); return;
	end
	local names = {};
	local skipped = 0;
	for name, profile in pairs(UnBotBotRegistry.bots) do
		if (type(name) == "string" and #name > 0 and #name <= 64
			and not name:find("[%s%c|,;]") and type(profile) == "table"
			and name ~= UnitName("player") and not profile.accountAlt and not profile.protectedAccountCharacter
			and not (UnBotIsAccountAltProfile and UnBotIsAccountAltProfile(name, profile))) then
			names[#names + 1] = name;
		else skipped = skipped + 1; end
	end
	table.sort(names);
	if (#names == 0 or #names > 5000) then
		UnBotTrace.SweepMessage("Прогон не начат: допустимо от 1 до 5000 обычных ботов; найдено "..#names.."."); return;
	end
	if (UnBotTrace.active) then UnBotTrace.Stop("Новый отдельный прогон реестра"); end
	UnBotTrace.Start();
	UnBotTrace.sweep = {active = true, names = names, index = 1, phase = "add",
		nextTime = GetTime() + 1, deadline = GetTime() + #names * 4 + 30, sent = 0};
	UnBotTrace.run.sweep = {names = names, status = "running", sent = 0, skipped = skipped};
	UnBotTrace.Snapshot();
	UnBotTrace.SweepMessage("Прогон реестра: "..#names.." ботов по алфавиту. На имя: add -> исключение -> remove,"
		.." по 1 секунде между командами. Ответы не проверяются. Пропущено защищённых/некорректных записей: "..skipped..".");
end

function UnBotTrace.SweepTick()
	local test = UnBotTrace.sweep;
	if (not test or not test.active) then return; end
	local blocked = UnBotTrace.SweepBlocked();
	if (blocked) then UnBotTrace.SweepStop(blocked); return; end
	local now = GetTime();
	if (now > test.deadline) then UnBotTrace.SweepStop("Прогон остановлен по общему таймауту."); return; end
	if (now < test.nextTime) then return; end
	local name = test.names[test.index];
	if (not name) then
		UnBotTrace.SweepStop("Прогон завершён: команды отправлены для "..#test.names.." ботов. Ответы и удаление не проверялись."); return;
	end
	-- Capacity is a safety guard only; never wait for this bot or retry a command.
	if (test.phase == "add" and (GetNumRaidMembers() >= 40
		or (GetNumRaidMembers() == 0 and GetNumPartyMembers() >= 4))) then
		UnBotTrace.SweepStop("Прогон остановлен: группа заполнена оставшимися участниками. Повторного add нет."); return;
	end
	UnBotTrace.run.sweep.index = test.index;
	UnBotTrace.run.sweep.name = name;
	UnBotTrace.run.sweep.phase = test.phase;
	UnBotTrace.Add("ШАГ", test.index.."/"..#test.names.." "..test.phase, name);
	UnBotTrace.Refresh();
	test.nextTime = now + 1; -- one step per tick; no catch-up burst after a frame stall
	if (test.phase == "add") then
		test.phase = "kick";
		SendChatMessage(".playerbot bot add "..name, "SAY");
	elseif (test.phase == "kick") then
		test.phase = "remove";
		UninviteUnit(name);
	else
		test.phase = "add";
		test.index = test.index + 1;
		SendChatMessage(".playerbot bot remove "..name, "SAY");
	end
	test.sent = test.sent + 1;
	UnBotTrace.run.sweep.sent = test.sent;
	UnBotTrace.Snapshot();
end

SLASH_UNBOTTRACE1 = "/ubtrace";
SlashCmdList.UNBOTTRACE = function(message)
	if (message == "start") then UnBotTrace.Safe("Start");
	elseif (message == "sweep") then UnBotTrace.Safe("SweepStart");
	elseif (message == "stop") then UnBotTrace.Safe("Stop");
	else UnBotTrace.Show(); end
end;

-- One explicitly started boss capture; independent of summon tracing.
UnBotTrace.boss = {limit=20000, timeout=1200, callbacks={
 "DBM_Debug","DBM_Pull","DBM_Wipe","DBM_Kill","DBM_TimerBegin",
 "DBM_TimerStart","DBM_TimerStop","DBM_TimerUpdate","DBM_Announce","DBM_SetStage"}};

function UnBotTrace.BossMessage(text)
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff70ddd0[DBM log]|r "..text);end
end

function UnBotTrace.BossValue(value)
 if type(value)=="table" then
  return {id=value.id,revision=value.revision,inCombat=value.inCombat,
   name=value.localization and value.localization.general and value.localization.general.name};
 end
 if type(value)=="string" then return UnBotTrace.Text(value,1200);end
 if type(value)=="number" or type(value)=="boolean" then return value;end
 return nil;
end

function UnBotTrace.BossAdd(event,...)
 local b=UnBotTrace.boss;if not b.active then return;end
 if #b.run.events>=b.limit then UnBotTrace.BossStop("event_limit");return;end
 local row={ms=math.floor((GetTime()-b.started)*1000+0.5),event=event,n=select("#",...),args={}};
 for i=1,math.min(row.n,20) do row.args[i]=UnBotTrace.BossValue(select(i,...));end
 b.run.events[#b.run.events+1]=row;
end

function UnBotTrace.BossModules()
 local out={};
 for _,m in ipairs(DBM and DBM.Mods or {}) do
  local entry={id=m.id,inCombat=m.inCombat,options={},timers={}};
  for k,v in pairs(m.Options or {}) do
   if type(v)=="boolean" or type(v)=="number" or type(v)=="string" then entry.options[k]=v;end
  end
  for _,t in ipairs(m.timers or {}) do
   entry.timers[#entry.timers+1]={id=t.id,spellId=t.spellId,option=t.option,timer=t.timer,type=t.type};
  end
  out[#out+1]=entry;
 end
 return out;
end

function UnBotTrace.BossStop(reason)
 local b=UnBotTrace.boss;if not b.active then return;end
 b.active=false;
 b.run.status=reason or "stopped";b.run.endedAt=time();
 b.run.duration=GetTime()-b.started;b.run.modulesAtEnd=UnBotTrace.BossModules();
 for _,event in ipairs(b.callbacks) do DBM:UnregisterCallback(event,b.callback);end
 b.frame:UnregisterAllEvents();b.frame:SetScript("OnUpdate",nil);
 if DBM.Options.DebugLevel==3 then DBM.Options.DebugLevel=b.oldDebugLevel;end
 if b.ownsCombatLog and LoggingCombat() then LoggingCombat(false);end
 UnBotTrace.BossMessage("Запись остановлена: "..b.run.status..", событий "..#b.run.events..". /reload сохранит журнал.");
end

function UnBotTrace.BossEvent(event,...)
 local b=UnBotTrace.boss;if not b.active then return;end
 if event=="PLAYER_LOGOUT" then UnBotTrace.BossStop("logout_or_reload");return;end
 if event=="COMBAT_LOG_EVENT_UNFILTERED" then
  local stamp,kind,sg,sn,sf,dg,dn,df,spell,name,school,extra,extraName=...;
  local hostile=bit and bit.band and (bit.band(sf or 0,96)>0 or bit.band(df or 0,96)>0);
  if hostile and (kind=="SPELL_CAST_START" or kind=="SPELL_CAST_SUCCESS" or kind=="SPELL_CAST_FAILED"
   or kind=="SPELL_INTERRUPT" or kind=="SPELL_SUMMON" or kind=="SPELL_AURA_APPLIED"
   or kind=="SPELL_AURA_REMOVED" or kind=="UNIT_DIED") then
   UnBotTrace.BossAdd(kind,stamp,sg,sn,dg,dn,spell,name,school,extra,extraName);
  end
 else UnBotTrace.BossAdd(event,...);end
end

function UnBotTrace.BossStart()
 local b=UnBotTrace.boss;
 if b.active then UnBotTrace.BossMessage("Запись уже идёт. Остановка: /ubdbmlog stop.");return;end
 if not DBM or not DBM.RegisterCallback or not DBM.UnregisterCallback or not DBM.Options then
  UnBotTrace.BossMessage("DBM недоступен: включите DBM-Core и повторите команду.");return;
 end
 UnBotTraceDB=UnBotTraceDB or {};UnBotTraceDB.bossRuns=UnBotTraceDB.bossRuns or {};
 local roster={};local raid=GetNumRaidMembers();
 for i=0,(raid>0 and raid or GetNumPartyMembers()) do
  local u=i==0 and "player" or (raid>0 and "raid" or "party")..i;
  if (raid==0 or i>0) and UnitName(u) then roster[#roster+1]={name=UnitName(u),guid=UnitGUID(u),online=UnitIsConnected(u) and true or false};end
 end
 b.run={version=UnBotTrace.version,startedAt=time(),zone=GetRealZoneText(),instance={GetInstanceInfo()},
  dbmVersion=GetAddOnMetadata("DBM-Core","Version"),unbotVersion=GetAddOnMetadata("UnBotCustom","Version"),
  roster=roster,status="recording",events={},modulesAtStart=UnBotTrace.BossModules(),options={}};
 for k,v in pairs(DBM.Options) do if type(v)=="boolean" or type(v)=="number" or type(v)=="string" then b.run.options[k]=v;end end
 table.insert(UnBotTraceDB.bossRuns,1,b.run);
 while #UnBotTraceDB.bossRuns>2 do table.remove(UnBotTraceDB.bossRuns);end
 b.oldDebugLevel=DBM.Options.DebugLevel;DBM.Options.DebugLevel=3;
 b.started=GetTime();b.active=true;b.ownsCombatLog=false;
 if LoggingCombat then
  b.run.combatLogWasActive=LoggingCombat() and true or false;
  if not b.run.combatLogWasActive then LoggingCombat(true);b.ownsCombatLog=true;end
  b.run.combatLogActive=LoggingCombat() and true or false;
 end
 b.callback=function(event,...)
  if not b.active then return;end
  UnBotTrace.BossAdd(event,...);
  if event=="DBM_Pull" then b.run.modulesAtPull=UnBotTrace.BossModules();end
 end;
 for _,event in ipairs(b.callbacks) do DBM:RegisterCallback(event,b.callback);end
 b.frame=b.frame or CreateFrame("Frame");
 for _,event in ipairs({"COMBAT_LOG_EVENT_UNFILTERED","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED",
  "PLAYER_LOGOUT","PLAYER_ENTERING_WORLD","ADDON_LOADED","CHAT_MSG_MONSTER_YELL","CHAT_MSG_MONSTER_SAY",
  "CHAT_MSG_MONSTER_EMOTE","CHAT_MSG_RAID_BOSS_EMOTE","CHAT_MSG_RAID_BOSS_WHISPER","CHAT_MSG_SYSTEM",
  "UNIT_SPELLCAST_START","UNIT_SPELLCAST_SUCCEEDED","UI_ERROR_MESSAGE"}) do b.frame:RegisterEvent(event);end
 b.frame:SetScript("OnEvent",function(_,event,...)
  local ok,err=pcall(UnBotTrace.BossEvent,event,...);
  if not ok then b.run.error=UnBotTrace.Text(err);UnBotTrace.BossStop("logger_error");end
 end);
 b.nextSample=0;
 b.frame:SetScript("OnUpdate",function()
  if not b.active then return;end
  local now=GetTime();
  if now-b.started>=b.timeout then UnBotTrace.BossStop("timeout_20min");return;end
  if now<b.nextSample then return;end;b.nextSample=now+1;
  for _,u in ipairs({"target","focus","boss1","boss2","boss3","boss4","boss5"}) do
   if UnitExists(u) then UnBotTrace.BossAdd("UNIT_SAMPLE",u,UnitGUID(u),UnitName(u),UnitHealth(u),UnitHealthMax(u),UnitCastingInfo(u));end
  end
  if LoggingCombat then
   local active=LoggingCombat() and true or false;
   if active~=b.run.combatLogActive then b.run.combatLogActive=active;UnBotTrace.BossAdd("COMBAT_LOG_STATE",active);end
  end
 end);
 UnBotTrace.BossAdd("CAPTURE_START",GetRealZoneText());
 UnBotTrace.BossMessage("Запись начата: DBM + способности босса + combat log. Лимит 20 минут. После боя: /ubdbmlog stop, затем /reload.");
end

SLASH_UNBOTDBMLOG1="/ubdbmlog";
SlashCmdList.UNBOTDBMLOG=function(text)
 text=tostring(text or ""):lower():match("^%s*(.-)%s*$");
 if text=="start" then UnBotTrace.BossStart();
 elseif text=="stop" then UnBotTrace.BossStop("manual");
 else
  local b=UnBotTrace.boss;
  UnBotTrace.BossMessage(b.active and ("Запись идёт: "..#b.run.events.." событий.") or "Запись выключена. /ubdbmlog start — начать, /ubdbmlog stop — остановить.");
 end
end;
