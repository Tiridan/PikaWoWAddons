local P = ProfessionPath

local ORDER = {"herbs", "minerals", "fish"}
local TYPES = {
    herbs = {label = "Травы", icon = "Interface\\Icons\\INV_Misc_Flower_02", textureKey = "inv_misc_flower_02"},
    minerals = {label = "Минералы", icon = "Interface\\Icons\\Spell_Nature_Earthquake", textureKey = "spell_nature_earthquake"},
    fish = {label = "Рыбные косяки", icon = "Interface\\Icons\\INV_Misc_Fish_02", textureKey = "inv_misc_fish_02"},
}
local ROUTE_TYPES = {
    herbs = "Herb Gathering",
    minerals = "Mining",
    fish = "Fishing",
}
local RESOURCE_ROUTE_NAME = "ProfessionPath: ресурсы"

local function ClampInterval(value)
    value = tonumber(value) or 1.5
    if value < 0.5 then value = 0.5 end
    if value > 10 then value = 10 end
    return math.floor(value * 10 + 0.5) / 10
end

local function SmallButton(parent, width, text, click)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(26)
    button:SetText(text)
    button:SetScript("OnClick", click)
    return button
end

function P:InitResourceTracking()
    self.db.resourceTracking = self.db.resourceTracking or {}
    local settings = self.db.resourceTracking
    settings.selected = settings.selected or {}
    settings.interval = ClampInterval(settings.interval)
    if settings.enabled == nil then settings.enabled = false end
    self.resourceTracking = settings
    self.resourceTrackingElapsed = 0
    self.resourceTrackingCursor = 0
    self:RefreshResourceTrackingTypes()
end

function P:RefreshResourceTrackingTypes()
    self.resourceTrackingTypes = self.resourceTrackingTypes or {}
    for _, key in ipairs(ORDER) do
        local entry = self.resourceTrackingTypes[key] or {}
        entry.index, entry.name, entry.active = nil, nil, false
        self.resourceTrackingTypes[key] = entry
    end
    if not GetNumTrackingTypes or not GetTrackingInfo then return end
    for index = 1, GetNumTrackingTypes() do
        local name, texture, active = GetTrackingInfo(index)
        local normalized = string.lower(texture or "")
        for _, key in ipairs(ORDER) do
            if string.find(normalized, TYPES[key].textureKey, 1, true) then
                local entry = self.resourceTrackingTypes[key]
                entry.index, entry.name, entry.active = index, name or TYPES[key].label, active and true or false
            end
        end
    end
end

function P:GetSelectedResourceTracking()
    self:RefreshResourceTrackingTypes()
    local selected = {}
    for _, key in ipairs(ORDER) do
        local entry = self.resourceTrackingTypes[key]
        if self.resourceTracking.selected[key] and entry and entry.index then
            selected[#selected + 1] = {key = key, index = entry.index, name = entry.name}
        end
    end
    return selected
end

function P:AdvanceResourceTracking()
    if not self.resourceTracking or not self.resourceTracking.enabled then return end
    local selected = self:GetSelectedResourceTracking()
    if #selected == 0 then
        self.resourceTracking.enabled = false
        self.resourceTrackingLastKey = nil
        self:Print("Отслеживание остановлено: выбранные типы пока недоступны персонажу.")
        self:RefreshTrackingWindow()
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        self.resourceTrackingWaitingCombat = true
        self:RefreshTrackingWindow()
        return
    end
    self.resourceTrackingWaitingCombat = false
    if #selected == 1 and self.resourceTrackingLastKey == selected[1].key then return end
    self.resourceTrackingCursor = self.resourceTrackingCursor % #selected + 1
    local target = selected[self.resourceTrackingCursor]
    if SetTracking then
        local ok = pcall(SetTracking, target.index)
        if ok then
            self.resourceTrackingLastKey = target.key
            self.resourceTrackingLastName = target.name or TYPES[target.key].label
        end
    end
    self:RefreshTrackingWindow()
end

function P:SetResourceTrackingEnabled(enabled, quiet)
    if not self.resourceTracking then self:InitResourceTracking() end
    if enabled then
        local selected = self:GetSelectedResourceTracking()
        if #selected == 0 then
            self.resourceTracking.enabled = false
            if not quiet then self:Print("Выберите хотя бы один доступный тип: травы, минералы или рыбные косяки.") end
        else
            self.resourceTracking.enabled = true
            self.resourceTrackingElapsed = 0
            self.resourceTrackingCursor = 0
            self.resourceTrackingLastKey = nil
            self:AdvanceResourceTracking()
            if not quiet then
                if #selected == 1 then
                    self:Print("Отслеживание ресурсов включено: " .. (selected[1].name or TYPES[selected[1].key].label) .. ".")
                else
                    self:Print("Цикл отслеживания включён: " .. #selected .. " типа, интервал " .. string.format("%.1f", self.resourceTracking.interval) .. " сек.")
                end
            end
        end
    else
        self.resourceTracking.enabled = false
        self.resourceTrackingLastKey = nil
        self.resourceTrackingWaitingCombat = false
        if not quiet then self:Print("Цикл отслеживания ресурсов выключен.") end
    end
    self:RefreshTrackingWindow()
end

function P:SetResourceTrackingInterval(value)
    if not self.resourceTracking then self:InitResourceTracking() end
    self.resourceTracking.interval = ClampInterval(value)
    self.resourceTrackingElapsed = 0
    self:RefreshTrackingWindow()
end

function P:ToggleResourceType(key)
    if not TYPES[key] then return end
    self.resourceTracking.selected[key] = not self.resourceTracking.selected[key]
    self.resourceTrackingCursor = 0
    self.resourceTrackingLastKey = nil
    if self.resourceTracking.enabled then self:AdvanceResourceTracking() end
    self:RefreshTrackingWindow()
end

function P:ResourceTrackingTick(elapsed)
    if not self.resourceTracking or not self.resourceTracking.enabled then return end
    self.resourceTrackingElapsed = (self.resourceTrackingElapsed or 0) + elapsed
    if self.resourceTrackingElapsed >= self.resourceTracking.interval then
        self.resourceTrackingElapsed = 0
        self:AdvanceResourceTracking()
    end
end

function P:BuildCurrentResourceRoute()
    if not self.resourceTracking then self:InitResourceTracking() end
    local routes, gatherMate = Routes, GatherMate
    if not routes or not routes.db or not routes.TSP or not gatherMate or not gatherMate.gmdbs then
        self.resourceRouteStatusText = "|cffff6666Нужны включённые GatherMate и Routes.|r"
        self:Print("Для маршрута сбора включите аддоны GatherMate и Routes.")
        self:RefreshTrackingWindow()
        return
    end

    local zone = GetRealZoneText and GetRealZoneText()
    local routeZone = zone and routes.zoneData and routes.zoneData[zone]
    local gatherZone = zone and gatherMate.zoneData and gatherMate.zoneData[zone]
    if not zone or not routeZone or not gatherZone or not routeZone[4] or routeZone[4] == "" then
        self.resourceRouteStatusText = "|cffff6666Для текущей локации нет карты Routes.|r"
        self:Print("Не удалось определить поддерживаемую карту текущей локации.")
        self:RefreshTrackingWindow()
        return
    end

    local running = routes.TSP.IsTSPRunning and routes.TSP:IsTSPRunning()
    if running then
        self.resourceRouteStatusText = "|cffffcc44Routes уже оптимизирует другой маршрут.|r"
        self:Print("Routes уже оптимизирует маршрут. Дождитесь завершения и нажмите кнопку ещё раз.")
        self:RefreshTrackingWindow()
        return
    end

    local nodes, seen, routeTypes, labels = {}, {}, {}, {}
    local selectedCount = 0
    local gatherZoneID = gatherZone[3]
    for _, key in ipairs(ORDER) do
        if self.resourceTracking.selected[key] then
            selectedCount = selectedCount + 1
            labels[#labels + 1] = TYPES[key].label
            local dbType = ROUTE_TYPES[key]
            local zoneNodes = gatherMate.gmdbs[dbType] and gatherMate.gmdbs[dbType][gatherZoneID]
            if type(zoneNodes) == "table" then
                routeTypes[dbType == "Herb Gathering" and "Herbalism" or dbType] = true
                for coord in pairs(zoneNodes) do
                    if type(coord) == "number" and not seen[coord] then
                        seen[coord] = true
                        nodes[#nodes + 1] = coord
                    end
                end
            end
        end
    end

    if selectedCount == 0 then
        self.resourceRouteStatusText = "|cffffcc44Сначала отметьте типы ресурсов.|r"
        self:Print("Для маршрута отметьте травы, минералы или рыбные косяки.")
        self:RefreshTrackingWindow()
        return
    end
    if #nodes < 2 then
        self.resourceRouteStatusText = "|cffffcc44В GatherMate найдено меньше двух точек.|r"
        self:Print("В " .. zone .. " недостаточно известных точек выбранных ресурсов. Сначала импортируйте или соберите данные GatherMate.")
        self:RefreshTrackingWindow()
        return
    end

    routes.TSP:DecrossRoute(nodes)
    local mapfile = routeZone[4]
    local routeDB = routes.db.global
    routeDB.routes[mapfile] = routeDB.routes[mapfile] or {}
    local routeData = routeDB.routes[mapfile][RESOURCE_ROUTE_NAME]
    if type(routeData) ~= "table" then
        routeData = {}
        routeDB.routes[mapfile][RESOURCE_ROUTE_NAME] = routeData
    end
    routeData.route = nodes
    routeData.metadata = nil
    routeData.cluster_dist = nil
    routeData.selection = {}
    routeData.db_type = routeTypes
    routeData.taboos = routeData.taboos or {}
    routeData.taboolist = routeData.taboolist or {}
    routeData.hidden = false
    routeData.visible = true
    routeData.looped = 1
    routeData.color = routeData.color or {0.35, 0.95, 0.35, 1}
    routeData.length = routes.TSP:PathLength(nodes, zone)

    local routeOptions = routes.options and routes.options.args and routes.options.args.routes_group and routes.options.args.routes_group.args
    if routeOptions then
        if not routeOptions[mapfile] then
            routeOptions[mapfile] = {type = "group", name = zone, args = {}}
        end
        local routeKey = string.gsub(RESOURCE_ROUTE_NAME, "%s", "\255")
        routeOptions[mapfile].args[routeKey] = routes:CreateAceOptRouteTable(mapfile, RESOURCE_ROUTE_NAME)
    end

    routes:DrawWorldmapLines()
    routes:DrawMinimapLines(true)
    self.resourceTracking.lastRouteZone = zone
    self.resourceTracking.lastRouteNodes = #nodes
    self.resourceTracking.lastRouteTypes = table.concat(labels, ", ")
    self.resourceRouteStatusText = "|cff55ff55Создано:|r " .. zone .. ", " .. #nodes .. " точек. Оптимизация..."
    self:Print("Маршрут сбора создан: " .. zone .. ", " .. #nodes .. " точек (" .. table.concat(labels, ", ") .. ").")

    if #nodes <= 724 and routes.TSP.SolveTSPBackground and routes.TSP.SetFinishFunction then
        local result = routes.TSP:SolveTSPBackground(nodes, nil, {}, zone, routeDB.defaults.tsp)
        if result == 1 then
            routes.TSP:SetFinishFunction(function(output, metadata, length)
                if routeDB.routes[mapfile] and routeDB.routes[mapfile][RESOURCE_ROUTE_NAME] == routeData then
                    routeData.route, routeData.metadata, routeData.length = output, metadata, length
                    routes:DrawWorldmapLines()
                    routes:DrawMinimapLines(true)
                    P.resourceRouteStatusText = "|cff55ff55Готово:|r " .. zone .. ", " .. #output .. " точек."
                    P:Print("Маршрут сбора оптимизирован: " .. zone .. ".")
                    P:RefreshTrackingWindow()
                end
            end)
        else
            self.resourceRouteStatusText = "|cff55ff55Создано:|r " .. zone .. ", " .. #nodes .. " точек."
        end
    else
        self.resourceRouteStatusText = "|cff55ff55Создано:|r " .. zone .. ", " .. #nodes .. " точек; без полной оптимизации."
        if #nodes > 724 then self:Print("Точек больше 724: маршрут построен, но полная оптимизация Routes пропущена.") end
    end

    self:RefreshTrackingWindow()
    if not InCombatLockdown or not InCombatLockdown() then
        local mapID = routeZone[3]
        local continent = math.floor(mapID / 100)
        local mapZone = mapID - continent * 100
        if self.trackingWindow then self.trackingWindow:Hide() end
        if WorldMapFrame and not WorldMapFrame:IsShown() then ShowUIPanel(WorldMapFrame) end
        if SetMapZoom then SetMapZoom(continent, mapZone) end
    else
        self:Print("Маршрут уже создан; карту можно открыть после боя.")
    end
end

function P:BuildTrackingWindow()
    if self.trackingWindow then return end
    local modal = CreateFrame("Frame", "ProfessionPathTrackingModal", UIParent)
    self.trackingModal = modal
    modal:SetAllPoints(UIParent)
    modal:SetFrameStrata("FULLSCREEN_DIALOG")
    modal:SetFrameLevel(90)
    modal:EnableMouse(true)
    modal.shade = modal:CreateTexture(nil, "BACKGROUND")
    modal.shade:SetAllPoints(modal)
    modal.shade:SetTexture("Interface\\Buttons\\WHITE8X8")
    modal.shade:SetVertexColor(0, 0, 0, 0.48)
    modal:Hide()

    local frame = CreateFrame("Frame", "ProfessionPathTrackingWindow", UIParent)
    self.trackingWindow = frame
    frame:SetWidth(440); frame:SetHeight(390)
    frame:SetPoint("CENTER", UIParent, "CENTER", 190, 40)
    if self.db.resourceTrackingPosition then
        local pos = self.db.resourceTrackingPosition
        frame:ClearAllPoints(); frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    end
    frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(100); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local point, _, _, x, y = f:GetPoint(1)
        self.db.resourceTrackingPosition = {point = point, x = x, y = y}
    end)
    frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = {left = 11, right = 12, top = 12, bottom = 11}})
    frame:SetBackdropColor(0.045, 0.038, 0.03, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -20); title:SetText("Отслеживание ресурсов")
    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -47); subtitle:SetWidth(375); subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Выбранные типы по очереди включаются на миникарте.")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    self.trackingChecks = {}
    for i, key in ipairs(ORDER) do
        local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -70 - (i - 1) * 40)
        check:SetWidth(30); check:SetHeight(30); check.key = key
        check.icon = check:CreateTexture(nil, "ARTWORK")
        check.icon:SetPoint("LEFT", check, "RIGHT", 4, 0); check.icon:SetWidth(24); check.icon:SetHeight(24); check.icon:SetTexture(TYPES[key].icon)
        check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        check.label:SetPoint("LEFT", check.icon, "RIGHT", 8, 0); check.label:SetWidth(270); check.label:SetJustifyH("LEFT")
        check:SetScript("OnClick", function(button) self:ToggleResourceType(button.key) end)
        self.trackingChecks[key] = check
    end

    local intervalLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    intervalLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -202); intervalLabel:SetText("Интервал переключения:")
    local minus = SmallButton(frame, 32, "-", function() self:SetResourceTrackingInterval(self.resourceTracking.interval - 0.5) end)
    minus:SetPoint("TOPLEFT", frame, "TOPLEFT", 211, -197)
    self.trackingIntervalBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.trackingIntervalBox:SetPoint("LEFT", minus, "RIGHT", 8, 0); self.trackingIntervalBox:SetWidth(58); self.trackingIntervalBox:SetHeight(26)
    self.trackingIntervalBox:SetAutoFocus(false); self.trackingIntervalBox:SetJustifyH("CENTER")
    self.trackingIntervalBox:SetScript("OnEnterPressed", function(box)
        self:SetResourceTrackingInterval(string.gsub(box:GetText() or "", ",", ".")); box:ClearFocus()
    end)
    self.trackingIntervalBox:SetScript("OnEscapePressed", function(box) box:ClearFocus(); self:RefreshTrackingWindow() end)
    local plus = SmallButton(frame, 32, "+", function() self:SetResourceTrackingInterval(self.resourceTracking.interval + 0.5) end)
    plus:SetPoint("LEFT", self.trackingIntervalBox, "RIGHT", 8, 0)
    local seconds = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    seconds:SetPoint("LEFT", plus, "RIGHT", 8, 0); seconds:SetText("сек.")

    self.trackingStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.trackingStatus:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -242); self.trackingStatus:SetWidth(392); self.trackingStatus:SetHeight(34); self.trackingStatus:SetJustifyH("LEFT"); self.trackingStatus:SetJustifyV("TOP")
    self.resourceRouteStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.resourceRouteStatus:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -278); self.resourceRouteStatus:SetWidth(392); self.resourceRouteStatus:SetHeight(34); self.resourceRouteStatus:SetJustifyH("LEFT"); self.resourceRouteStatus:SetJustifyV("TOP")
    self.resourceRouteButton = SmallButton(frame, 392, "Построить маршрут текущей локации", function() self:BuildCurrentResourceRoute() end)
    self.resourceRouteButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 58)
    self.trackingStartButton = SmallButton(frame, 392, "Включить", function() self:SetResourceTrackingEnabled(not self.resourceTracking.enabled) end)
    self.trackingStartButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 23)
    frame:SetScript("OnShow", function() modal:Show(); self:RefreshTrackingWindow() end)
    frame:SetScript("OnHide", function() modal:Hide() end)
    frame:Hide()
    tinsert(UISpecialFrames, "ProfessionPathTrackingWindow")
end

function P:RefreshTrackingWindow()
    if not self.trackingWindow then return end
    self:RefreshResourceTrackingTypes()
    for _, key in ipairs(ORDER) do
        local check = self.trackingChecks[key]
        local available = self.resourceTrackingTypes[key] and self.resourceTrackingTypes[key].index
        check:SetChecked(self.resourceTracking.selected[key] and true or false)
        check.label:SetText(TYPES[key].label .. (available and "" or "  |cff888888(не изучено)|r"))
    end
    self.trackingIntervalBox:SetText(string.format("%.1f", self.resourceTracking.interval))
    local routeReady = Routes and Routes.db and Routes.TSP and GatherMate and GatherMate.gmdbs
    if routeReady then self.resourceRouteButton:Enable() else self.resourceRouteButton:Disable() end
    if self.resourceRouteStatusText then
        self.resourceRouteStatus:SetText(self.resourceRouteStatusText)
    elseif routeReady then
        self.resourceRouteStatus:SetText("Маршрут берёт известные точки GatherMate и рисуется аддоном Routes.")
    else
        self.resourceRouteStatus:SetText("|cffff6666Для маршрута нужны включённые GatherMate и Routes.|r")
    end
    local selected = self:GetSelectedResourceTracking()
    if self.resourceTracking.enabled then
        self.trackingStartButton:SetText("Выключить")
        if self.resourceTrackingWaitingCombat then
            self.trackingStatus:SetText("|cffffcc44Пауза в бою.|r Переключение продолжится после боя.")
        elseif #selected == 1 then
            self.trackingStatus:SetText("|cff55ff55Включено:|r " .. (self.resourceTrackingLastName or selected[1].name or TYPES[selected[1].key].label) .. ". Переключение не требуется.")
        else
            self.trackingStatus:SetText("|cff55ff55Цикл работает.|r Сейчас: " .. (self.resourceTrackingLastName or "выбранный ресурс") .. ".")
        end
    else
        self.trackingStartButton:SetText("Включить")
        self.trackingStatus:SetText("Цикл выключен. Отметьте нужные ресурсы и нажмите «Включить».")
    end
end

function P:ToggleTrackingWindow()
    self:BuildTrackingWindow()
    if self.trackingWindow:IsShown() then self.trackingWindow:Hide() else self.trackingWindow:Show() end
end

local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, elapsed)
    if P.db then P:ResourceTrackingTick(elapsed) end
end)
