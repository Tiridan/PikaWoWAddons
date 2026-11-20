function UnBotTrace.Refresh()
	local f = UnBotTrace.window;
	if (not f or not f:IsShown()) then return; end
	f.status:SetText(UnBotTrace.error and ("Ошибка логгера: "..UnBotTrace.error)
		or (UnBotTrace.active and "ЗАПИСЬ ДИАГНОСТИКИ" or "ДИАГНОСТИКА ОСТАНОВЛЕНА"));
	f.bot:SetText("Бот: "..UnBotTrace.Text(UnBotTrace.bot or "—", 100));
	f.stage:SetText("Этап: "..UnBotTrace.Text(UnBotTrace.stage or "Ожидание запуска", 150));
	f.command:SetText("Последняя команда: "..UnBotTrace.Text(UnBotTrace.lastCommand or "—", 230));
	f.roster:SetText((UnBotTrace.rosterLabel or "Группа: —").."  |  Пик API-вызовов за секунду: "..tostring(UnBotTrace.peak or 0));
	local events = UnBotTrace.run and UnBotTrace.run.events or {};
	local first = math.max(1, #events - #f.rows + 1);
	for i, line in ipairs(f.rows) do
		local e = events[first + i - 1];
		line:SetText(e and string.format("%06.1f  #%d  %s  %s%s", e.ms / 1000, e.seq,
			e.kind, e.target ~= "" and (e.target..": ") or "", UnBotTrace.Text(e.text, 210)) or "");
		if (e and e.kind == "КОМАНДА") then line:SetTextColor(1, 0.85, 0.4);
		elseif (e and (e.kind == "ОТВЕТ" or e.kind == "CHAT_MSG_SYSTEM")) then line:SetTextColor(0.5, 0.9, 0.86);
		else line:SetTextColor(0.88, 0.9, 0.93); end
	end
end

function UnBotTrace.Show()
	if (UnBotTrace.window) then UnBotTrace.window:Show(); UnBotTrace.Refresh(); return; end
	local f = CreateFrame("Frame", "UnBotTraceWindow", UIParent);
	UnBotTrace.window = f;
	f:SetWidth(800); f:SetHeight(570);
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true);
	f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", function(self) self:StartMoving(); end);
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); end);
	f:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4}});
	f:SetBackdropColor(0.015, 0.025, 0.04, 1);
	f:SetBackdropBorderColor(0.25, 0.65, 0.65, 1);
	local function label(y, size, text, height)
		local l = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
		l:SetFont("Fonts\\FRIZQT__.TTF", size, "");
		l:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -y); l:SetWidth(764);
		l:SetHeight(height or size + 5); l:SetJustifyH("LEFT"); l:SetJustifyV("TOP");
		l:SetText(text or ""); return l;
	end
	label(15, 20, "UnBotTrace — диагностика призыва"):SetTextColor(0.45, 0.9, 0.85);
	label(45, 13, "Запишите экран до кика. Для проверки всех ботов — кнопка прогона реестра внизу.");
	f.status = label(70, 15); f.status:SetTextColor(1, 0.8, 0.3);
	f.bot = label(97, 17); f.stage = label(123, 15);
	f.command = label(148, 14, "", 39);
	f.roster = label(190, 13);
	f.rows = {};
	for i = 1, 10 do f.rows[i] = label(220 + (i - 1) * 27, 13, "", 26); end
	local start = CreateFrame("Button", nil, f, "UIPanelButtonTemplate");
	start:SetWidth(145); start:SetHeight(26); start:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 47);
	start:SetText("Начать диагностику"); start:SetScript("OnClick", function() UnBotTrace.Safe("Start"); end);
	local stop = CreateFrame("Button", nil, f, "UIPanelButtonTemplate");
	stop:SetWidth(100); stop:SetHeight(26); stop:SetPoint("LEFT", start, "RIGHT", 8, 0);
	stop:SetText("Остановить"); stop:SetScript("OnClick", function() UnBotTrace.Safe("Stop"); end);
	local sweep = CreateFrame("Button", nil, f, "UIPanelButtonTemplate");
	f.sweepButton = sweep;
	sweep:SetWidth(310); sweep:SetHeight(26); sweep:SetPoint("LEFT", stop, "RIGHT", 12, 0);
	sweep:SetText("Прогнать призыв всего реестра");
	sweep:SetScript("OnClick", function() UnBotTrace.Safe("SweepStart"); end);
	sweep:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP");
		GameTooltip:AddLine("Прогон всего реестра", 0.4, 0.9, 0.85);
		GameTooltip:AddLine("Каждому обычному боту: add, исключение из группы, remove. Между командами 1 секунда. Ответов не ждём, who и init не отправляем.", 1, 1, 1, true);
		GameTooltip:AddLine("Старт только вне боя и без группы. Карантин не исключает бота из теста. Альты аккаунта пропускаются. Остановить — кнопкой рядом.", 1, 0.82, 0.3, true);
		GameTooltip:AddLine("Запишите видео с видимыми именем и шагом. При задержке сервера кик может относиться к предыдущему боту.", 1, 1, 1, true);
		GameTooltip:Show();
	end);
	sweep:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	label(535, 12, "Резервный файл: SavedVariables\\UnBotTrace.lua после /reload. При кике он может не сохраниться.");
	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton");
	close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3);
	f:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed;
		if (self.elapsed >= 0.1) then self.elapsed = 0; UnBotTrace.Safe("Refresh"); end
	end);
	table.insert(UISpecialFrames, "UnBotTraceWindow");
	f:Show(); UnBotTrace.Refresh();
end
