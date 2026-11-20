local A = DungeonSeeker

local function label(parent, text, x, y, width, template)
    local f = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    f:SetWidth(width)
    f:SetText(text)
    return f
end

function A:Fold(text)
    text = (text or ""):gsub("[A-Z]", function(c) return string.char(c:byte() + 32) end)
    return text:gsub("Ё", "е"):gsub("ё", "е")
end

function A:RefreshUI()
    if not self.menu then return end
    local f = self.menu
    local selected = self:Info(self.db.targetID)
    f.selected:SetText("Подземелье: " .. (selected and selected.name or "не выбрано"))
    f.status:SetText(self.status)
    local query, shown = self:Fold(f.search:GetText()), {}
    for _, item in ipairs(self:Catalog()) do
        if query == "" or self:Fold(item.name):find(query, 1, true) then shown[#shown + 1] = item end
    end
    f.page = math.max(1, math.min(f.page or 1, math.max(1, math.ceil(#shown / 8))))
    for i, row in ipairs(f.rows) do
        local item = shown[(f.page - 1) * 8 + i]
        row.item = item
        if item then
            row.text:SetText((item.id == self.db.targetID and "|cffffcc66> " or "") .. item.name
                .. (item.locked and " |cff999999(недоступно)|r" or ""))
            row:Show()
        else row:Hide() end
    end
    f.pageLabel:SetText(#shown == 0 and "Нет доступных совпадений"
        or (f.page .. " / " .. math.max(1, math.ceil(#shown / 8))))
end

function A:ToggleMenu()
    if not self.db then self:Init() end
    if not self.menu then self:CreateMenu() end
    if self.menu:IsShown() then self.menu:Hide() else self:RefreshUI(); self.menu:Show() end
end

function A:CreateMenu()
    local f = CreateFrame("Frame", "DungeonSeekerMenu", UIParent)
    self.menu = f
    f:SetWidth(440); f:SetHeight(330)
    f:SetPoint("BOTTOMLEFT", self.launcher, "TOPLEFT", -80, 4)
    f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true)
    f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32,
        edgeSize = 32, insets = { left = 10, right = 10, top = 10, bottom = 10 } })
    tinsert(UISpecialFrames, "DungeonSeekerMenu")
    label(f, "Выбор подземелья", 20, -18, 390, "GameFontNormalLarge")
    label(f, "Средняя кнопка мыши по кнопкам открывает это меню", 20, -44, 390)
    f.search = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    f.search:SetPoint("TOPLEFT", 24, -64); f.search:SetWidth(382); f.search:SetHeight(24)
    f.search:SetAutoFocus(false); f.search:SetMaxLetters(80)
    f.search:SetScript("OnTextChanged", function() f.page = 1; A:RefreshUI() end)
    f.search:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
    f.rows = {}
    for i = 1, 8 do
        local row = CreateFrame("Button", nil, f)
        row:SetPoint("TOPLEFT", 20, -94 - (i - 1) * 22); row:SetWidth(400); row:SetHeight(22)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.text = label(row, "", 5, -3, 390)
        row:SetScript("OnClick", function(b)
            if not A.run and b.item and not b.item.locked then A.db.targetID = b.item.id; A:RefreshUI() end
        end)
        f.rows[i] = row
    end
    local prev = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    prev:SetPoint("TOPLEFT", 20, -275); prev:SetWidth(35); prev:SetHeight(22); prev:SetText("<")
    prev:SetScript("OnClick", function() f.page = math.max(1, (f.page or 1) - 1); A:RefreshUI() end)
    local next = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    next:SetPoint("TOPLEFT", 405, -275); next:SetWidth(35); next:SetHeight(22); next:SetText(">")
    next:SetScript("OnClick", function() f.page = (f.page or 1) + 1; A:RefreshUI() end)
    f.pageLabel = label(f, "", 60, -281, 340); f.pageLabel:SetJustifyH("CENTER")
    f.selected = label(f, "", 20, -302, 390, "GameFontNormal")
    f.status = label(f, "", 20, -323, 390)
    f:Hide(); self:RefreshUI()
end

function A:CreateLauncher()
    if self.launcher then return end
    local f = CreateFrame("Frame", "DungeonSeekerLauncher", UIParent)
    self.launcher = f; f:SetWidth(156); f:SetHeight(30)
    f:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", -4, -155); f:SetClampedToScreen(true)
    f.enter = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.enter:SetPoint("TOPLEFT"); f.enter:SetWidth(76); f.enter:SetHeight(28); f.enter:SetText("Войти")
    f.exit = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.exit:SetPoint("TOPLEFT", 80, 0); f.exit:SetWidth(76); f.exit:SetHeight(28); f.exit:SetText("Выйти")
    f.enter:RegisterForClicks("LeftButtonUp", "MiddleButtonUp")
    f.exit:RegisterForClicks("LeftButtonUp", "MiddleButtonUp")
    f.enter:SetScript("OnClick", function(_, click) if click == "MiddleButton" then A:ToggleMenu() else A:Start() end end)
    f.exit:SetScript("OnClick", function(_, click) if click == "MiddleButton" then A:ToggleMenu() else A:Exit() end end)
    f.enter:SetScript("OnEnter", function()
        GameTooltip:SetOwner(f.enter, "ANCHOR_TOP"); GameTooltip:AddLine("Войти", 1, .82, .4)
        GameTooltip:AddLine("Искать выбранное подземелье", 1, 1, 1, true); GameTooltip:Show()
    end)
    f.exit:SetScript("OnEnter", function()
        GameTooltip:SetOwner(f.exit, "ANCHOR_TOP"); GameTooltip:AddLine("Выйти", 1, .82, .4)
        GameTooltip:AddLine("Покинуть подземелье, группу или очередь", 1, 1, 1, true); GameTooltip:Show()
    end)
    f.enter:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.exit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self:CreateObjectiveFrame()
end

function A:CreateObjectiveFrame()
    if self.objective then return end
    local f = CreateFrame("Frame", "DungeonSeekerObjectiveFrame", UIParent)
    self.objective = f
    f:SetWidth(270); f:SetHeight(52); f:SetFrameStrata("MEDIUM"); f:SetClampedToScreen(true)
    f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32,
        edgeSize = 16, insets = { left = 7, right = 7, top = 7, bottom = 7 } })
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(frame) if not InCombatLockdown() then frame:StartMoving() end end)
    f:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = frame:GetPoint()
        A.db.objectivePoint = { point = point, relativePoint = relativePoint, x = x, y = y }
    end)
    local point = self.db.objectivePoint
    if type(point) == "table" and point.point and point.relativePoint then
        f:SetPoint(point.point, UIParent, point.relativePoint, tonumber(point.x) or 0, tonumber(point.y) or 0)
    else
        f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -220)
    end
    f.title = label(f, "Цель поиска подземелья", 13, -11, 244, "GameFontNormal")
    f.lines = {}
    for i = 1, 5 do f.lines[i] = label(f, "", 13, -11 - i * 17, 244) end
    f:Hide()
end

function A:RefreshObjectiveUI()
    local f = self.objective
    if not f then return end
    if not self.objectiveVisible then f:Hide(); return end
    local instanceName, goal = self:GetDungeonObjectives()
    if not instanceName then f:Hide(); return end
    f.title:SetText("Цель: " .. instanceName)
    local count = 1
    local completed = self.objectiveDone and self.objectiveDone.instance == instanceName
    if goal and goal.boss then
        f.lines[1]:SetText((completed and "|cff66cc66Цель выполнена: |r" or "|cffffcc66Нужно убить: |r") .. goal.boss)
    elseif goal and goal.text then
        f.lines[1]:SetText((completed and "|cff66cc66Цель выполнена: |r" or "|cffffcc66Нужно сделать: |r") .. goal.text)
    else
        f.lines[1]:SetText("|cffccccccЦель этого подземелья пока не внесена в каталог.|r")
    end
    for i, line in ipairs(f.lines) do if i <= count then line:Show() else line:Hide() end end
    f:SetHeight(31 + count * 17)
    f:Show()
end
