-- Standalone Retribution Paladin helper for WoW WotLK 3.3.5a.
-- Secure actions are configured once while the addon loads. Runtime code only
-- updates non-protected visual regions and never casts a spell automatically.

UnBotRetHelper = UnBotRetHelper or {}

UnBotRetHelper.config = {
    flashOfLightHealth = 65,
    flashEmergencyHealth = 35,
    divineProtectionHealth = 35,
    divineShieldHealth = 20,
    layOnHandsHealth = 15,
    sacredShieldRefresh = 3,
    updateInterval = 0.10,
}

UnBotRetHelper.defaults = {
    schemaVersion = 1,
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = -180,
    scale = 1,
    locked = true,
    visible = true,
}

UnBotRetHelper.spells = {
    {
        key = "sacredShield",
        id = 53601,
        fallback = "Священный щит",
        buttonName = "UnBotRetHelperSacredShieldButton",
        targetMode = "friendly",
        shortLabel = "Щит",
    },
    {
        key = "flashOfLight",
        id = 19750,
        fallback = "Вспышка Света",
        buttonName = "UnBotRetHelperFlashOfLightButton",
        targetMode = "friendly",
        shortLabel = "Всп.",
    },
    {
        key = "cleanse",
        id = 4987,
        fallback = "Очищение",
        buttonName = "UnBotRetHelperCleanseButton",
        targetMode = "friendly",
        shortLabel = "Очищ.",
    },
    {
        key = "divineProtection",
        id = 498,
        fallback = "Божественная защита",
        buttonName = "UnBotRetHelperDivineProtectionButton",
        targetMode = "player",
        shortLabel = "Защ.",
    },
    {
        key = "divineShield",
        id = 642,
        fallback = "Божественный щит",
        buttonName = "UnBotRetHelperDivineShieldButton",
        targetMode = "player",
        shortLabel = "Бабл",
    },
    {
        key = "layOnHands",
        id = 633,
        fallback = "Возложение рук",
        buttonName = "UnBotRetHelperLayOnHandsButton",
        targetMode = "friendly",
        shortLabel = "Руки",
    },
}

UnBotRetHelper.auras = {
    sacredShield = { id = 53601, fallback = "Священный щит" },
    artOfWar = { id = 53489, fallback = "Искусство войны" },
    forbearance = { id = 25771, fallback = "Воздержанность" },
}

UnBotRetHelper.state = {
    initialized = false,
    elapsed = 0,
    dragging = false,
    buttons = {},
    buttonsByKey = {},
}

function UnBotRetHelper.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00UnBot RetHelper:|r " .. tostring(message))
end

function UnBotRetHelper.IsPaladin()
    local _, class = UnitClass("player")
    return class == "PALADIN"
end

function UnBotRetHelper.InitializeSpellNames()
    local index, definition, name, _, icon
    for index, definition in ipairs(UnBotRetHelper.spells) do
        name, _, icon = GetSpellInfo(definition.id)
        definition.name = name or definition.fallback
        definition.icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    for _, definition in pairs(UnBotRetHelper.auras) do
        definition.name = GetSpellInfo(definition.id) or definition.fallback
    end
end

function UnBotRetHelper.InitializeDB()
    if type(UnBotRetHelperDB) ~= "table" then
        UnBotRetHelperDB = {}
    end

    local defaults = UnBotRetHelper.defaults
    if type(UnBotRetHelperDB.schemaVersion) ~= "number" then
        UnBotRetHelperDB.schemaVersion = defaults.schemaVersion
    elseif UnBotRetHelperDB.schemaVersion < defaults.schemaVersion then
        UnBotRetHelperDB.schemaVersion = defaults.schemaVersion
    end
    if type(UnBotRetHelperDB.point) ~= "string" then
        UnBotRetHelperDB.point = defaults.point
    end
    if type(UnBotRetHelperDB.relativePoint) ~= "string" then
        UnBotRetHelperDB.relativePoint = defaults.relativePoint
    end
    if type(UnBotRetHelperDB.x) ~= "number" then
        UnBotRetHelperDB.x = defaults.x
    end
    if type(UnBotRetHelperDB.y) ~= "number" then
        UnBotRetHelperDB.y = defaults.y
    end
    if type(UnBotRetHelperDB.scale) ~= "number" or UnBotRetHelperDB.scale < 0.5 or UnBotRetHelperDB.scale > 2 then
        UnBotRetHelperDB.scale = defaults.scale
    end
    if type(UnBotRetHelperDB.locked) ~= "boolean" then
        UnBotRetHelperDB.locked = defaults.locked
    end
    if type(UnBotRetHelperDB.visible) ~= "boolean" then
        UnBotRetHelperDB.visible = defaults.visible
    end
    if type(UnBotRetHelperDB.bindings) ~= "table" then
        UnBotRetHelperDB.bindings = {}
    end

    UnBotRetHelper.db = UnBotRetHelperDB
end

function UnBotRetHelper.ConfigureSecureAction(button)
    local definition = button.definition
    local macroText
    if definition.targetMode == "friendly" then
        macroText = "/cast [target=mouseover,help,nodead][help,nodead][target=player] " .. definition.name
    else
        macroText = "/cast [target=player] " .. definition.name
    end

    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", macroText)
    button:RegisterForClicks("AnyUp")
end

function UnBotRetHelper.CreateSolidTexture(parent, layer)
    local texture = parent:CreateTexture(nil, layer or "ARTWORK")
    texture:SetTexture("Interface\\Buttons\\WHITE8X8")
    return texture
end

function UnBotRetHelper.CreateButtonBorder(button)
    button.border = {}

    button.border.top = UnBotRetHelper.CreateSolidTexture(button, "ARTWORK")
    button.border.top:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
    button.border.top:SetPoint("TOPRIGHT", button, "TOPRIGHT", 1, 1)
    button.border.top:SetHeight(2)

    button.border.bottom = UnBotRetHelper.CreateSolidTexture(button, "ARTWORK")
    button.border.bottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", -1, -1)
    button.border.bottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
    button.border.bottom:SetHeight(2)

    button.border.left = UnBotRetHelper.CreateSolidTexture(button, "ARTWORK")
    button.border.left:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
    button.border.left:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", -1, -1)
    button.border.left:SetWidth(2)

    button.border.right = UnBotRetHelper.CreateSolidTexture(button, "ARTWORK")
    button.border.right:SetPoint("TOPRIGHT", button, "TOPRIGHT", 1, 1)
    button.border.right:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
    button.border.right:SetWidth(2)
end

function UnBotRetHelper.SetBorderColor(button, red, green, blue, alpha)
    alpha = alpha or 1
    if button.borderRed == red and button.borderGreen == green and button.borderBlue == blue and button.borderAlpha == alpha then
        return
    end
    button.borderRed = red
    button.borderGreen = green
    button.borderBlue = blue
    button.borderAlpha = alpha
    local _, texture
    for _, texture in pairs(button.border) do
        texture:SetVertexColor(red, green, blue, alpha)
    end
end

function UnBotRetHelper.SetTextIfChanged(fontString, text)
    text = text or ""
    if fontString.retHelperText == text then
        return
    end
    fontString.retHelperText = text
    fontString:SetText(text)
end

function UnBotRetHelper.CreateButton(definition, index)
    local button = CreateFrame("Button", definition.buttonName, UnBotRetHelper.panel, "SecureActionButtonTemplate")
    button:SetWidth(44)
    button:SetHeight(44)
    button:SetPoint("LEFT", UnBotRetHelper.panel, "LEFT", 7 + ((index - 1) * 47), -10)
    button.definition = definition
    button.recommendation = 0
    button.reason = "Сейчас нет рекомендации."
    button.learned = false
    button.canRecommend = false

    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetAllPoints(button)
    button.icon:SetTexture(definition.icon)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button)
    button.cooldown:SetFrameLevel(button:GetFrameLevel() + 2)

    button.timerText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.timerText:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    button.timerText:SetJustifyH("LEFT")
    button.timerText:SetTextColor(1, 0.95, 0.45)

    button.keyText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.keyText:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
    button.keyText:SetJustifyH("RIGHT")
    button.keyText:SetTextColor(1, 1, 1)

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
    button.label:SetText(definition.shortLabel)
    button.label:SetTextColor(0.9, 0.9, 0.9)

    UnBotRetHelper.CreateButtonBorder(button)
    UnBotRetHelper.SetBorderColor(button, 0.35, 0.35, 0.35, 1)

    button.glow = button:CreateTexture(nil, "OVERLAY")
    button.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.glow:SetBlendMode("ADD")
    button.glow:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.glow:SetWidth(70)
    button.glow:SetHeight(70)
    button.glow:SetAlpha(0)

    UnBotRetHelper.ConfigureSecureAction(button)
    button:SetScript("OnEnter", function(self) UnBotRetHelper.ShowTooltip(self) end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UnBotRetHelper.state.buttons[index] = button
    UnBotRetHelper.state.buttonsByKey[definition.key] = button
    return button
end

function UnBotRetHelper.CreateUI()
    UnBotRetHelper.InitializeSpellNames()

    local panel = CreateFrame("Frame", "UnBotRetHelperPanel", UIParent)
    panel:SetWidth(296)
    panel:SetHeight(78)
    panel:SetFrameStrata("MEDIUM")
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    panel:SetBackdropColor(0.03, 0.03, 0.03, 0.88)
    panel:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    panel:Hide()
    UnBotRetHelper.panel = panel

    local index, definition
    for index, definition in ipairs(UnBotRetHelper.spells) do
        UnBotRetHelper.CreateButton(definition, index)
    end

    panel:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then
            UnBotRetHelper.Print("в бою панель перемещать нельзя.")
            return
        end
        if UnBotRetHelper.db and UnBotRetHelper.IsPaladin() then
            if UnBotRetHelper.db.locked and not IsShiftKeyDown() then
                UnBotRetHelper.Print("зажмите Shift и тяните за заголовок панели, либо /urh unlock.")
                return
            end
            UnBotRetHelper.state.dragging = true
            self:StartMoving()
        end
    end)

    panel:SetScript("OnDragStop", function(self)
        if not UnBotRetHelper.state.dragging then
            return
        end
        UnBotRetHelper.state.dragging = false
        -- Stopping an already-started drag prevents the protected children from
        -- continuing to follow the cursor if combat began between mouse-down
        -- and mouse-up. No new position is applied while combat is locked.
        self:StopMovingOrSizing()
        if InCombatLockdown() then
            UnBotRetHelper.Print("бой начался: новое положение не сохранено.")
            return
        end
        UnBotRetHelper.SavePosition()
        UnBotRetHelper.Print("положение панели сохранено.")
    end)

    local dragHandle = CreateFrame("Frame", nil, panel)
    dragHandle:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -3)
    dragHandle:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -3)
    dragHandle:SetHeight(20)
    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle.label = dragHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dragHandle.label:SetPoint("CENTER", dragHandle, "CENTER", 0, 0)
    dragHandle.label:SetText("RetHelper  |  Shift + ЛКМ: переместить")
    dragHandle:SetScript("OnDragStart", function()
        panel:GetScript("OnDragStart")(panel)
    end)
    dragHandle:SetScript("OnDragStop", function()
        panel:GetScript("OnDragStop")(panel)
    end)
    UnBotRetHelper.dragHandle = dragHandle

    panel:SetScript("OnUpdate", function(_, elapsed)
        UnBotRetHelper.state.elapsed = UnBotRetHelper.state.elapsed + elapsed
        if UnBotRetHelper.state.elapsed >= UnBotRetHelper.config.updateInterval then
            UnBotRetHelper.state.elapsed = 0
            if UnBotRetHelper.state.initialized and UnBotRetHelper.IsPaladin() then
                UnBotRetHelper.Refresh()
            end
        end
    end)
end

function UnBotRetHelper.ApplyLayout()
    if not UnBotRetHelper.db or InCombatLockdown() then
        return false
    end

    local panel = UnBotRetHelper.panel
    panel:ClearAllPoints()
    panel:SetPoint(
        UnBotRetHelper.db.point,
        UIParent,
        UnBotRetHelper.db.relativePoint,
        UnBotRetHelper.db.x,
        UnBotRetHelper.db.y
    )
    panel:SetScale(UnBotRetHelper.db.scale)

    UnBotRetHelper.ApplyVisibilityDriver()
    return true
end

function UnBotRetHelper.ApplyVisibilityDriver()
    if not UnBotRetHelper.db or InCombatLockdown() then
        return false
    end

    local panel = UnBotRetHelper.panel
    if not UnBotRetHelper.IsPaladin() then
        if UnregisterStateDriver then
            UnregisterStateDriver(panel, "visibility")
        end
        panel:Hide()
    elseif RegisterStateDriver then
        if UnBotRetHelper.db.visible then
            RegisterStateDriver(panel, "visibility", "[combat] show; show")
        else
            RegisterStateDriver(panel, "visibility", "[combat] show; hide")
        end
    elseif UnBotRetHelper.db.visible then
        panel:Show()
    else
        panel:Hide()
    end
    return true
end

function UnBotRetHelper.SavePosition()
    if not UnBotRetHelper.db or InCombatLockdown() then
        return
    end
    local point, _, relativePoint, x, y = UnBotRetHelper.panel:GetPoint(1)
    if point then
        UnBotRetHelper.db.point = point
        UnBotRetHelper.db.relativePoint = relativePoint or point
        UnBotRetHelper.db.x = x or 0
        UnBotRetHelper.db.y = y or 0
    end
end

function UnBotRetHelper.IsSpellLearned(spellName)
    if not spellName or spellName == "" then
        return false
    end
    local tabCount = GetNumSpellTabs and GetNumSpellTabs() or 0
    local tab, _, _, offset, spellCount, spellIndex, learnedName
    for tab = 1, tabCount do
        _, _, offset, spellCount = GetSpellTabInfo(tab)
        offset = offset or 0
        spellCount = spellCount or 0
        for spellIndex = offset + 1, offset + spellCount do
            learnedName = GetSpellName(spellIndex, BOOKTYPE_SPELL or "spell")
            if learnedName == spellName then
                return true
            end
        end
    end
    return false
end

function UnBotRetHelper.RefreshLearnedSpells()
    local _, button
    for _, button in ipairs(UnBotRetHelper.state.buttons) do
        button.learned = UnBotRetHelper.IsSpellLearned(button.definition.name)
    end
end

function UnBotRetHelper.GetFriendlyUnit()
    if UnitExists("mouseover") and UnitIsFriend("player", "mouseover") and not UnitIsDeadOrGhost("mouseover") then
        return "mouseover"
    end
    if UnitExists("target") and UnitIsFriend("player", "target") and not UnitIsDeadOrGhost("target") then
        return "target"
    end
    return "player"
end

function UnBotRetHelper.GetHealthPercent(unit)
    local maximum = UnitHealthMax(unit) or 0
    if maximum <= 0 then
        return 100
    end
    return ((UnitHealth(unit) or 0) / maximum) * 100
end

function UnBotRetHelper.GetAuraRemaining(expirationTime)
    if not expirationTime or expirationTime <= 0 then
        return 0
    end
    local remaining = expirationTime - GetTime()
    if remaining < 0 then
        return 0
    end
    return remaining
end

function UnBotRetHelper.FindBuff(unit, auraDefinition)
    local index, name, duration, expirationTime, spellId
    for index = 1, 40 do
        name, _, _, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff(unit, index)
        if not name then
            break
        end
        if (spellId and spellId == auraDefinition.id) or name == auraDefinition.name then
            return true, UnBotRetHelper.GetAuraRemaining(expirationTime), duration or 0
        end
    end
    return false, 0, 0
end

function UnBotRetHelper.FindCleanseDebuff(unit)
    local index, name, debuffType
    for index = 1, 40 do
        name, _, _, _, debuffType = UnitDebuff(unit, index)
        if not name then
            break
        end
        if debuffType == "Magic" or debuffType == "Poison" or debuffType == "Disease" then
            return name, debuffType
        end
    end
    return nil, nil
end

function UnBotRetHelper.SetCooldown(cooldownFrame, start, duration, enabled)
    start = start or 0
    duration = duration or 0
    enabled = enabled or 0
    if cooldownFrame.retHelperStart == start and cooldownFrame.retHelperDuration == duration and cooldownFrame.retHelperEnabled == enabled then
        return
    end
    cooldownFrame.retHelperStart = start
    cooldownFrame.retHelperDuration = duration
    cooldownFrame.retHelperEnabled = enabled

    if cooldownFrame.SetCooldown then
        if enabled == 0 then
            cooldownFrame:SetCooldown(0, 0)
        else
            cooldownFrame:SetCooldown(start, duration)
        end
    elseif CooldownFrame_SetTimer then
        CooldownFrame_SetTimer(cooldownFrame, start, duration, enabled)
    end
end

function UnBotRetHelper.UpdateAbilityState(button)
    local start, duration, enabled = 0, 0, 0
    local usable, noMana = false, false
    if button.learned then
        start, duration, enabled = GetSpellCooldown(button.definition.name)
        start = start or 0
        duration = duration or 0
        enabled = enabled or 0
        usable, noMana = IsUsableSpell(button.definition.name)
    end
    UnBotRetHelper.SetCooldown(button.cooldown, start, duration, enabled)

    button.cooldownStart = start
    button.cooldownDuration = duration
    button.usable = usable and true or false
    button.noMana = noMana and true or false
    button.canRecommend = button.learned and button.usable and (duration == 0 or duration <= 1.5)
end

function UnBotRetHelper.SetRecommendation(button, level, reason, timerText)
    button.recommendation = level or 0
    button.reason = reason or "Сейчас нет рекомендации."
    if timerText ~= nil then
        UnBotRetHelper.SetTextIfChanged(button.timerText, timerText)
    end
end

function UnBotRetHelper.FormatRemaining(seconds)
    if not seconds or seconds <= 0 then
        return ""
    end
    if seconds < 10 then
        return string.format("%.1f", seconds)
    end
    return tostring(math.floor(seconds + 0.5))
end

function UnBotRetHelper.RefreshRecommendations()
    local buttons = UnBotRetHelper.state.buttonsByKey
    local friendlyUnit = UnBotRetHelper.GetFriendlyUnit()
    local targetHealth = UnBotRetHelper.GetHealthPercent(friendlyUnit)
    local playerHealth = UnBotRetHelper.GetHealthPercent("player")
    local targetName = UnitName(friendlyUnit) or UnitName("player") or "игрок"
    local hasSacredShield, sacredRemaining = UnBotRetHelper.FindBuff(friendlyUnit, UnBotRetHelper.auras.sacredShield)
    local hasArtOfWar, artRemaining = UnBotRetHelper.FindBuff("player", UnBotRetHelper.auras.artOfWar)
    local hasForbearance, forbearanceRemaining = UnBotRetHelper.FindBuff("player", UnBotRetHelper.auras.forbearance)
    local cleanseName = UnBotRetHelper.FindCleanseDebuff(friendlyUnit)
    local _, button

    for _, button in ipairs(UnBotRetHelper.state.buttons) do
        UnBotRetHelper.SetRecommendation(button, 0, "Сейчас нет рекомендации.", nil)
    end

    button = buttons.sacredShield
    local sacredTimer = ""
    if hasSacredShield then
        sacredTimer = UnBotRetHelper.FormatRemaining(sacredRemaining)
    elseif button.canRecommend then
        sacredTimer = "0"
    end
    UnBotRetHelper.SetTextIfChanged(button.timerText, sacredTimer)
    if hasSacredShield then
        UnBotRetHelper.SetRecommendation(button, 0, "Священный щит активен на цели " .. targetName .. ".", nil)
        if sacredRemaining <= UnBotRetHelper.config.sacredShieldRefresh and button.canRecommend then
            UnBotRetHelper.SetRecommendation(button, 1, "Обновить Священный щит на цели " .. targetName .. ".", nil)
        end
    elseif button.canRecommend then
        UnBotRetHelper.SetRecommendation(button, 1, "На цели " .. targetName .. " нет Священного щита.", nil)
    end

    button = buttons.flashOfLight
    local flashTimer = hasArtOfWar and UnBotRetHelper.FormatRemaining(artRemaining) or ""
    if targetHealth <= UnBotRetHelper.config.flashEmergencyHealth and button.canRecommend and not hasArtOfWar then
        flashTimer = "каст"
    end
    UnBotRetHelper.SetTextIfChanged(button.timerText, flashTimer)
    if targetHealth <= UnBotRetHelper.config.flashEmergencyHealth and button.canRecommend then
        if hasArtOfWar then
            UnBotRetHelper.SetRecommendation(button, 2, string.format("Цель %s: %.0f%% здоровья; Искусство войны активно — Вспышка мгновенная.", targetName, targetHealth), nil)
        else
            UnBotRetHelper.SetRecommendation(button, 2, string.format("Цель %s: %.0f%% здоровья; прока Искусства войны нет — потребуется обычное произнесение.", targetName, targetHealth), nil)
        end
    elseif targetHealth <= UnBotRetHelper.config.flashOfLightHealth and hasArtOfWar and button.canRecommend then
        UnBotRetHelper.SetRecommendation(button, 1, string.format("Цель %s: %.0f%% здоровья; доступна мгновенная Вспышка Света.", targetName, targetHealth), nil)
    end

    button = buttons.cleanse
    UnBotRetHelper.SetTextIfChanged(button.timerText, (cleanseName and button.canRecommend) and "!" or "")
    if cleanseName and button.canRecommend then
        UnBotRetHelper.SetRecommendation(button, 1, "Можно снять с цели " .. targetName .. ": " .. cleanseName .. ".", nil)
    end

    button = buttons.divineProtection
    UnBotRetHelper.SetTextIfChanged(button.timerText, hasForbearance and ("Возд. " .. UnBotRetHelper.FormatRemaining(forbearanceRemaining)) or "")
    if hasForbearance then
        UnBotRetHelper.SetRecommendation(button, 0, "Божественная защита недоступна: действует Воздержанность.", nil)
    elseif playerHealth <= UnBotRetHelper.config.divineProtectionHealth and button.canRecommend then
        UnBotRetHelper.SetRecommendation(button, 1, string.format("У игрока %.0f%% здоровья — рекомендуется Божественная защита.", playerHealth), nil)
    end

    button = buttons.divineShield
    UnBotRetHelper.SetTextIfChanged(button.timerText, hasForbearance and ("Возд. " .. UnBotRetHelper.FormatRemaining(forbearanceRemaining)) or "")
    if hasForbearance then
        UnBotRetHelper.SetRecommendation(button, 0, "Божественный щит недоступен: действует Воздержанность.", nil)
    elseif playerHealth <= UnBotRetHelper.config.divineShieldHealth and button.canRecommend then
        UnBotRetHelper.SetRecommendation(button, 2, string.format("Авария: у игрока %.0f%% здоровья — рекомендуется Божественный щит.", playerHealth), nil)
    end

    button = buttons.layOnHands
    UnBotRetHelper.SetTextIfChanged(button.timerText, (targetHealth <= UnBotRetHelper.config.layOnHandsHealth and button.canRecommend) and "!" or "")
    if targetHealth <= UnBotRetHelper.config.layOnHandsHealth and button.canRecommend then
        UnBotRetHelper.SetRecommendation(button, 2, string.format("Авария: у цели %s %.0f%% здоровья — рекомендуется Возложение рук.", targetName, targetHealth), nil)
    end

    UnBotRetHelper.state.friendlyUnit = friendlyUnit
    UnBotRetHelper.state.friendlyName = targetName
end

function UnBotRetHelper.GetButtonBindingAction(button)
    return "CLICK " .. button:GetName() .. ":LeftButton"
end

function UnBotRetHelper.GetButtonKey(button)
    local action = UnBotRetHelper.GetButtonBindingAction(button)
    local key = GetBindingKey(action)
    if not key then
        key = GetBindingKey("CLICK " .. button:GetName())
    end
    return key
end

function UnBotRetHelper.GetShortKeyText(key)
    if not key or key == "" then
        return ""
    end
    if GetBindingText then
        local text = GetBindingText(key, "KEY_", true)
        if text and text ~= "" then
            return text
        end
    end
    return key
end

function UnBotRetHelper.ApplyButtonVisual(button)
    UnBotRetHelper.SetTextIfChanged(button.keyText, UnBotRetHelper.GetShortKeyText(UnBotRetHelper.GetButtonKey(button)))

    local visualState
    if not button.learned then
        visualState = "unlearned"
    elseif button.recommendation == 2 then
        visualState = "urgent"
    elseif button.recommendation == 1 then
        visualState = "useful"
    elseif not button.usable or (button.cooldownDuration or 0) > 1.5 then
        visualState = "unavailable"
    else
        visualState = "normal"
    end

    if button.visualState == visualState then
        if visualState == "unlearned" then
            button.reason = "Заклинание не изучено."
        end
        return
    end
    button.visualState = visualState

    if visualState == "unlearned" then
        button.icon:SetVertexColor(0.22, 0.22, 0.22)
        button.label:SetTextColor(0.45, 0.45, 0.45)
        UnBotRetHelper.SetBorderColor(button, 0.22, 0.22, 0.22, 1)
        button.glow:SetVertexColor(0.3, 0.3, 0.3)
        button.glow:SetAlpha(0)
        button.reason = "Заклинание не изучено."
        return
    end

    if visualState == "unavailable" then
        button.icon:SetVertexColor(0.48, 0.48, 0.48)
    else
        button.icon:SetVertexColor(1, 1, 1)
    end
    button.label:SetTextColor(0.9, 0.9, 0.9)

    if visualState == "urgent" then
        UnBotRetHelper.SetBorderColor(button, 1, 0.12, 0.08, 1)
        button.glow:SetVertexColor(1, 0.08, 0.03)
        button.glow:SetAlpha(0.62)
    elseif visualState == "useful" then
        UnBotRetHelper.SetBorderColor(button, 1, 0.72, 0.08, 1)
        button.glow:SetVertexColor(0.3, 1, 0.15)
        button.glow:SetAlpha(0.42)
    else
        UnBotRetHelper.SetBorderColor(button, 0.35, 0.35, 0.35, 1)
        button.glow:SetVertexColor(0.35, 0.35, 0.35)
        button.glow:SetAlpha(0)
    end
end

function UnBotRetHelper.Refresh()
    local _, button
    for _, button in ipairs(UnBotRetHelper.state.buttons) do
        UnBotRetHelper.UpdateAbilityState(button)
    end
    UnBotRetHelper.RefreshRecommendations()
    for _, button in ipairs(UnBotRetHelper.state.buttons) do
        UnBotRetHelper.ApplyButtonVisual(button)
    end
end

function UnBotRetHelper.ShowTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(button.definition.name, 1, 0.82, 0)
    if not button.learned then
        GameTooltip:AddLine("Заклинание не изучено", 1, 0.25, 0.25, true)
    else
        GameTooltip:AddLine(button.reason or "Сейчас нет рекомендации.", 1, 1, 1, true)
    end
    local key = UnBotRetHelper.GetButtonKey(button)
    GameTooltip:AddLine("Клавиша: " .. (key or "не назначена"), 0.7, 0.85, 1, true)
    if button.definition.targetMode == "friendly" then
        GameTooltip:AddLine("Цель: mouseover > дружественная цель > игрок", 0.65, 0.65, 0.65, true)
    else
        GameTooltip:AddLine("Цель: игрок", 0.65, 0.65, 0.65, true)
    end
    GameTooltip:Show()
end

function UnBotRetHelper.GetSpecStatus()
    if not UnBotRetHelper.IsPaladin() then
        return "недоступно: персонаж не паладин"
    end
    if not GetTalentTabInfo then
        return "специализация не подтверждена: API талантов недоступен"
    end
    local points = {}
    local index
    for index = 1, 3 do
        local _, _, spent = GetTalentTabInfo(index)
        points[index] = tonumber(spent) or 0
    end
    if points[3] > points[1] and points[3] > points[2] and points[3] > 0 then
        return "Воздаяние подтверждено (талантов: " .. points[3] .. ")"
    end
    return string.format("Воздаяние не подтверждено (ветки: %d/%d/%d)", points[1], points[2], points[3])
end

function UnBotRetHelper.DescribeBindingAction(action)
    if not action or action == "" then
        return "свободна"
    end
    local displayName = _G["BINDING_NAME_" .. action]
    return displayName or action
end

function UnBotRetHelper.IsExpectedAction(action, button)
    if not action or action == "" then
        return false
    end
    return action == UnBotRetHelper.GetButtonBindingAction(button)
        or action == ("CLICK " .. button:GetName())
end

function UnBotRetHelper.BindDefaults(force)
    if InCombatLockdown() then
        UnBotRetHelper.Print("в бою изменять привязки нельзя.")
        return
    end
    if not SetBindingClick or not SaveBindings then
        UnBotRetHelper.Print("SetBindingClick/SaveBindings недоступны в этом клиенте.")
        return
    end

    local requests = {
        { key = "F", button = UnBotRetHelper.state.buttonsByKey.sacredShield },
        { key = "G", button = UnBotRetHelper.state.buttonsByKey.flashOfLight },
    }
    local blocked = false
    local _, request, action
    for _, request in ipairs(requests) do
        action = GetBindingAction(request.key) or ""
        request.oldAction = action
        if action ~= "" and not UnBotRetHelper.IsExpectedAction(action, request.button) and not force then
            UnBotRetHelper.Print(request.key .. " занята: " .. UnBotRetHelper.DescribeBindingAction(action))
            blocked = true
        end
    end
    if blocked then
        UnBotRetHelper.Print("привязки не изменены; для явной перезаписи используйте /urh bind force.")
        return
    end

    local success = true
    for _, request in ipairs(requests) do
        if not SetBindingClick(request.key, request.button:GetName(), "LeftButton") then
            success = false
        end
    end
    if not success then
        for _, request in ipairs(requests) do
            if request.oldAction and request.oldAction ~= "" then
                SetBinding(request.key, request.oldAction)
            else
                SetBinding(request.key)
            end
        end
        UnBotRetHelper.Print("не удалось назначить клавиши; прежние привязки восстановлены.")
        return
    end

    SaveBindings(GetCurrentBindingSet())
    UnBotRetHelper.db.bindings.F = requests[1].button:GetName()
    UnBotRetHelper.db.bindings.G = requests[2].button:GetName()
    UnBotRetHelper.Print("назначено: F — Священный щит, G — Вспышка Света.")
    UnBotRetHelper.Refresh()
end

function UnBotRetHelper.IsOurBindingAction(action)
    local _, button
    for _, button in ipairs(UnBotRetHelper.state.buttons) do
        if UnBotRetHelper.IsExpectedAction(action, button) then
            return true
        end
    end
    return false
end

function UnBotRetHelper.Unbind()
    if InCombatLockdown() then
        UnBotRetHelper.Print("в бою изменять привязки нельзя.")
        return
    end
    if not SaveBindings then
        UnBotRetHelper.Print("SaveBindings недоступна в этом клиенте.")
        return
    end

    local keys = {}
    local seen = {}
    local _, button, key1, key2, key
    for _, button in ipairs(UnBotRetHelper.state.buttons) do
        key1, key2 = GetBindingKey(UnBotRetHelper.GetButtonBindingAction(button))
        if key1 and not seen[key1] then
            keys[#keys + 1] = key1
            seen[key1] = true
        end
        if key2 and not seen[key2] then
            keys[#keys + 1] = key2
            seen[key2] = true
        end
    end
    for key in pairs(UnBotRetHelper.db.bindings) do
        if type(key) == "string" and not seen[key] and UnBotRetHelper.IsOurBindingAction(GetBindingAction(key) or "") then
            keys[#keys + 1] = key
            seen[key] = true
        end
    end

    local removed = 0
    for _, key in ipairs(keys) do
        if UnBotRetHelper.IsOurBindingAction(GetBindingAction(key) or "") then
            SetBinding(key)
            UnBotRetHelper.db.bindings[key] = nil
            removed = removed + 1
        end
    end
    SaveBindings(GetCurrentBindingSet())
    UnBotRetHelper.Print("снято привязок RetHelper: " .. removed .. ".")
    UnBotRetHelper.Refresh()
end

function UnBotRetHelper.PrintStatus()
    local visibility = UnBotRetHelper.panel:IsShown() and "показана" or "скрыта"
    local lockText = UnBotRetHelper.db.locked and "заблокирована" or "разблокирована"
    UnBotRetHelper.Print("панель " .. visibility .. ", " .. lockText .. ", масштаб " .. string.format("%.2f", UnBotRetHelper.db.scale) .. ".")
    UnBotRetHelper.Print("специализация: " .. UnBotRetHelper.GetSpecStatus() .. ".")
    local fAction = GetBindingAction("F") or ""
    local gAction = GetBindingAction("G") or ""
    UnBotRetHelper.Print("F: " .. UnBotRetHelper.DescribeBindingAction(fAction) .. "; G: " .. UnBotRetHelper.DescribeBindingAction(gAction) .. ".")
end

function UnBotRetHelper.PrintHelp()
    UnBotRetHelper.Print("/urh show|hide, lock|unlock, scale 0.5-2.0, bind [force], unbind, status, reset")
    UnBotRetHelper.Print("перемещение вне боя: Shift + ЛКМ за заголовок; после /urh unlock можно без Shift.")
end

function UnBotRetHelper.RequireOutOfCombat(actionName)
    if InCombatLockdown() then
        UnBotRetHelper.Print("в бою нельзя " .. actionName .. ".")
        return false
    end
    return true
end

function UnBotRetHelper.HandleSlash(message)
    message = message or ""
    local command, rest = string.match(message, "^%s*(%S*)%s*(.-)%s*$")
    command = string.lower(command or "")
    rest = string.lower(rest or "")

    if command == "" or command == "help" then
        UnBotRetHelper.PrintHelp()
    elseif command == "show" then
        if not UnBotRetHelper.RequireOutOfCombat("показывать панель") then return end
        if not UnBotRetHelper.IsPaladin() then
            UnBotRetHelper.Print("панель доступна только паладину.")
            return
        end
        UnBotRetHelper.db.visible = true
        UnBotRetHelper.ApplyVisibilityDriver()
        UnBotRetHelper.Print("панель показана.")
    elseif command == "hide" then
        if not UnBotRetHelper.RequireOutOfCombat("скрывать панель") then return end
        UnBotRetHelper.db.visible = false
        UnBotRetHelper.ApplyVisibilityDriver()
        UnBotRetHelper.Print("панель скрыта вне боя; в бою secure-драйвер покажет её.")
    elseif command == "lock" then
        UnBotRetHelper.db.locked = true
        UnBotRetHelper.Print("панель закреплена; перемещение за заголовок только с Shift.")
    elseif command == "unlock" then
        UnBotRetHelper.db.locked = false
        UnBotRetHelper.Print("перемещение разрешено вне боя; тяните ЛКМ за заголовок панели.")
    elseif command == "scale" then
        if not UnBotRetHelper.RequireOutOfCombat("менять масштаб") then return end
        local value = tonumber(rest)
        if not value or value < 0.5 or value > 2 then
            UnBotRetHelper.Print("масштаб должен быть числом от 0.5 до 2.0.")
            return
        end
        UnBotRetHelper.db.scale = value
        UnBotRetHelper.panel:SetScale(value)
        UnBotRetHelper.Print("масштаб: " .. string.format("%.2f", value) .. ".")
    elseif command == "bind" then
        UnBotRetHelper.BindDefaults(rest == "force")
    elseif command == "unbind" then
        UnBotRetHelper.Unbind()
    elseif command == "status" then
        UnBotRetHelper.PrintStatus()
    elseif command == "reset" then
        if not UnBotRetHelper.RequireOutOfCombat("сбрасывать положение") then return end
        UnBotRetHelper.db.point = UnBotRetHelper.defaults.point
        UnBotRetHelper.db.relativePoint = UnBotRetHelper.defaults.relativePoint
        UnBotRetHelper.db.x = UnBotRetHelper.defaults.x
        UnBotRetHelper.db.y = UnBotRetHelper.defaults.y
        UnBotRetHelper.db.scale = UnBotRetHelper.defaults.scale
        UnBotRetHelper.ApplyLayout()
        UnBotRetHelper.Print("положение и масштаб восстановлены; остальные настройки сохранены.")
    else
        UnBotRetHelper.PrintHelp()
    end
end

function UnBotRetHelper.Initialize()
    if UnBotRetHelper.state.initialized then
        return
    end
    UnBotRetHelper.InitializeDB()
    UnBotRetHelper.RefreshLearnedSpells()
    UnBotRetHelper.state.initialized = true
    UnBotRetHelper.ApplyLayout()
    if UnBotRetHelper.IsPaladin() then
        UnBotRetHelper.Refresh()
    end
end

function UnBotRetHelper.OnEvent(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "UnBotRetHelper" then
            UnBotRetHelper.Initialize()
            UnBotRetHelper.eventFrame:UnregisterEvent("ADDON_LOADED")
        end
        return
    end
    if event == "PLAYER_LOGIN" then
        UnBotRetHelper.Initialize()
        return
    end
    if not UnBotRetHelper.state.initialized then
        return
    end
    if event == "SPELLS_CHANGED" then
        UnBotRetHelper.RefreshLearnedSpells()
    elseif event == "PLAYER_REGEN_DISABLED" and UnBotRetHelper.state.dragging then
        UnBotRetHelper.state.dragging = false
        UnBotRetHelper.panel:StopMovingOrSizing()
        UnBotRetHelper.Print("бой начался: перемещение остановлено, положение не менялось.")
    elseif event == "PLAYER_REGEN_ENABLED" and UnBotRetHelper.state.dragging then
        UnBotRetHelper.state.dragging = false
        UnBotRetHelper.panel:StopMovingOrSizing()
        UnBotRetHelper.SavePosition()
    end
    UnBotRetHelper.state.elapsed = UnBotRetHelper.config.updateInterval
end

UnBotRetHelper.CreateUI()

UnBotRetHelper.eventFrame = CreateFrame("Frame")
UnBotRetHelper.eventFrame:RegisterEvent("ADDON_LOADED")
UnBotRetHelper.eventFrame:RegisterEvent("PLAYER_LOGIN")
UnBotRetHelper.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
UnBotRetHelper.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
UnBotRetHelper.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
UnBotRetHelper.eventFrame:RegisterEvent("UNIT_HEALTH")
UnBotRetHelper.eventFrame:RegisterEvent("UNIT_AURA")
UnBotRetHelper.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
UnBotRetHelper.eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
UnBotRetHelper.eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
UnBotRetHelper.eventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
UnBotRetHelper.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
UnBotRetHelper.eventFrame:RegisterEvent("SPELLS_CHANGED")
UnBotRetHelper.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
UnBotRetHelper.eventFrame:RegisterEvent("UPDATE_BINDINGS")
UnBotRetHelper.eventFrame:SetScript("OnEvent", UnBotRetHelper.OnEvent)

SLASH_UNBOTRETHELPER1 = "/urh"
SlashCmdList["UNBOTRETHELPER"] = UnBotRetHelper.HandleSlash
