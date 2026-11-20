local G = ThoriumBrotherhoodGuide
local C = {bg={0.045,0.038,0.03,1},line={0.65,0.65,0.65},text={1,0.95,0.82},muted={0.78,0.75,0.67},gold={1,0.82,0},green={0.3,1,0.3},blue={0.45,0.75,1}}

local function text(parent, size, color)
 local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
 fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size or 12)
 fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP"); fs:SetSpacing(3)
 fs:SetTextColor(unpack(color or C.text))
 return fs
end

function G:CreateLauncher()
 if self.launcher then return end
 local b = CreateFrame("Button", "ThoriumBrotherhoodGuideMinimapButton", Minimap)
 -- Normal Minimap child: MinimapButtonButton discovers and collects it.
 b:SetWidth(24); b:SetHeight(24); b:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -4, 0)
 b:SetClampedToScreen(true); b:RegisterForClicks("LeftButtonUp"); b:SetFrameStrata("MEDIUM")
 b:SetNormalTexture("Interface\\Icons\\INV_Ingot_Thorium")
 b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
 b:SetScript("OnClick", function() G:ToggleUI() end)
 b:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:AddLine("Братство Тория", 1, 0.82, 0)
  GameTooltip:AddLine("Левый клик: открыть путеводитель", 1, 1, 1)
  GameTooltip:AddLine("Открыть: /thorium", 0.8, 0.85, 0.9)
  GameTooltip:Show()
 end)
 b:SetScript("OnLeave", function() GameTooltip:Hide() end)
 self.launcher = b
end

function G:CreateUI()
 local f = CreateFrame("Frame", "ThoriumBrotherhoodGuideFrame", UIParent)
 f:SetWidth(760); f:SetHeight(690); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true); f:Hide()
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=11,right=12,top=12,bottom=11}})
 f:SetBackdropColor(unpack(C.bg)); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
 local title = text(f, 20, C.gold); title:SetPoint("TOPLEFT", 26, -22); title:SetText("Братство Тория")
 local subtitle = text(f, 13, C.muted); subtitle:SetPoint("TOPLEFT", 27, -48); subtitle:SetText("Путь к Превознесению: задания, сдачи и выгодный фарм")
 local close = CreateFrame("Button", nil, f, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -5, -5)
 local refresh = CreateFrame("Button", nil, f, "UIPanelButtonTemplate"); refresh:SetSize(132, 25); refresh:SetPoint("TOPRIGHT", -44, -40); refresh:SetText("Обновить историю"); refresh:SetScript("OnClick", function() G:QueryHistory(false) end)
 local divider=f:CreateTexture(nil,"ARTWORK"); divider:SetTexture("Interface\\Buttons\\WHITE8X8");divider:SetVertexColor(unpack(C.line));divider:SetPoint("TOPLEFT",24,-70);divider:SetSize(690,1)
 local scroll = CreateFrame("ScrollFrame", "ThoriumBrotherhoodGuideScrollFrame", f, "UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT", 28, -84); scroll:SetPoint("BOTTOMRIGHT", -38, 22)
 local child = CreateFrame("Frame", nil, scroll); child:SetWidth(666); child:SetHeight(1); scroll:SetScrollChild(child)
 self.frame, self.rows, self.questButtons = f, {}, {}
 f.scroll, f.child = scroll, child
end

function G:AddLine(y, value, color, height)
 self.rowCursor = self.rowCursor + 1
 local fs = self.rows[self.rowCursor]
 if not fs then fs = text(self.frame.child, 12); self.rows[self.rowCursor] = fs end
 fs:Show(); fs:SetTextColor(unpack(color or C.text)); fs:ClearAllPoints()
 fs:SetPoint("TOPLEFT", 4, -y); fs:SetWidth(630); fs:SetText(value); fs:SetNonSpaceWrap(false)
 return y + (height or math.max(18, fs:GetStringHeight() + 6))
end

function G:AddQuestLine(y, id, value, color)
 self.rowCursor = self.rowCursor + 1
 local fs = self.rows[self.rowCursor]
 if not fs then fs = text(self.frame.child, 12); self.rows[self.rowCursor] = fs end
 fs:Show(); fs:SetTextColor(unpack(color or C.text)); fs:ClearAllPoints()
 fs:SetPoint("TOPLEFT", 4, -y); fs:SetWidth(482); fs:SetText(value); fs:SetNonSpaceWrap(false)
 self.questButtonCursor = self.questButtonCursor + 1
 local b = self.questButtons[self.questButtonCursor]
 if not b then
  b = CreateFrame("Button", nil, self.frame.child, "UIPanelButtonTemplate")
  b:SetWidth(122); b:SetHeight(23); b:SetText("К квесту")
  self.questButtons[self.questButtonCursor] = b
 end
 b:ClearAllPoints(); b:SetPoint("TOPRIGHT", self.frame.child, "TOPRIGHT", -6, -y)
 b:SetScript("OnClick", function() G:SetQuestMarker(id) end); b:Show()
 return y + math.max(26, fs:GetStringHeight() + 6)
end

function G:RefreshUI()
 if not self.frame then return end
 self.rowCursor = 0; self.questButtonCursor = 0
 local child, y, rep = self.frame.child, 0, self:GetReputation()
 if rep then
  local rank = self.rankNames[rep.standing] or "Неизвестно"
  local current, needed = math.max(0, rep.earned - rep.bottom), math.max(0, rep.top - rep.bottom)
  y = self:AddLine(y, "Репутация: |cff80ff80"..rank.."|r  "..current.." / "..needed.."  ("..rep.name..")", C.text, 23)
 else y = self:AddLine(y, "Репутация пока не обнаружена. Откройте вкладку «Репутация» и нажмите «Обновить историю».", {1,0.35,0.35}, 23) end
 y = self:AddLine(y, self.historyMessage or "История заданий ещё не запрошена.", C.blue) + 10
 y = self:AddLine(y, "ЧТО ДЕЛАТЬ СЕЙЧАС", C.gold, 24)
 local nextQuest, state = self:FirstCampaignQuest()
 if nextQuest then
  local marker = state == "active" and "В ЖУРНАЛЕ" or state == "ready" and "ГОТОВО К СДАЧЕ" or state == "unknown" and "НЕ ПРОВЕРЕНО" or "НЕ СДАНО"
  y = self:AddLine(y, "["..marker.."] "..nextQuest[2].." — "..nextQuest[3], C.text)
 else y = self:AddLine(y, "Все основные задания Тлеющего ущелья подтверждены. Переходите к сдачам по текущей репутации.", C.green) end
 local counts = self:CampaignCounts()
 y = self:AddLine(y, "Итог по списку: СДАНО "..counts.done.."/"..#self.campaign.."; В ЖУРНАЛЕ "..counts.active.."; ГОТОВО К СДАЧЕ "..counts.ready.."; НЕ СДАНО "..counts.missing.."; НЕ ПРОВЕРЕНО "..counts.unknown..".", C.blue)
 y = self:AddLine(y, "Совет: "..self:FarmPlan(rep), C.muted) + 10
 y = self:AddLine(y, "ОСНОВНЫЕ ЗАДАНИЯ ТЛЕЮЩЕГО УЩЕЛЬЯ", C.gold, 24)
 for _, row in ipairs(self.campaign) do
  local state, liveTitle = self:QuestState(row[1])
  local label, col = "НЕ СДАНО", C.muted
  if state == "done" then label, col = "СДАНО", C.green elseif state == "active" then label, col = "В ЖУРНАЛЕ", C.gold elseif state == "ready" then label, col = "ГОТОВО К СДАЧЕ", {0.3,1,1} elseif state == "unknown" then label, col = "НЕ ПРОВЕРЕНО", {0.7,0.7,0.7} end
  y = self:AddQuestLine(y, row[1], "["..label.."] ["..row[1].."] "..(liveTitle or row[2]).." — "..row[3], col)
 end
 y = y + 10; y = self:AddLine(y, "СДАЧИ: В РЮКЗАКЕ СЕЙЧАС", C.gold, 24)
 local sections = {{"Равнодушие → Дружелюбие", self.repeatables.neutral}, {"Дружелюбие → Уважение", self.repeatables.friendly}, {"Уважение → Превознесение", self.repeatables.honored}}
 for _, section in ipairs(sections) do
  y = self:AddLine(y, section[1], C.blue, 20)
  for _, row in ipairs(section[2]) do y = self:AddQuestLine(y, row[1], "["..row[1].."] "..row[2].." (+"..row[3].." реп.): "..self:MaterialLine(row[4]), C.muted) end
 end
 y = y + 8; y = self:AddLine(y, "Важно: повторяемые сдачи сервер обычно не хранит как «сдано» навсегда. Аддон использует историю для обычных заданий, текущую репутацию для этапа фарма и содержимое сумок для готовых сдач.", {1,0.65,0.25})
 child:SetHeight(math.max(1, y + 20))
 for i=self.rowCursor+1,#self.rows do self.rows[i]:Hide() end
 for i=self.questButtonCursor+1,#self.questButtons do self.questButtons[i]:Hide() end
end

function G:ToggleUI()
 if not self.frame then return end
 if self.frame:IsShown() then self.frame:Hide() else self:RefreshUI(); self.frame:Show() end
end
