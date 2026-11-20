-- ProfessionPath 1.1.0 and newer contains the same helper. Keep this add-on as
-- a compatibility fallback, but do not create a second panel or duplicate marks.
if ProfessionPath and ProfessionPath.SetTriageEnabled then
    return
end

local ADDON_PREFIX = "|cff52d273TriageHelper:|r "
local QUEST_HORDE = 6622
local QUEST_ALLIANCE = 6624
local BANDAGE_ITEM_ID = 16991
local NAMEPLATE_BORDER = "Interface\\Tooltips\\Nameplate-Border"

local patientNames = {}
local function AddPatientName(name, priority, shortLabel, red, green, blue)
    patientNames[name] = {
        priority = priority,
        shortLabel = shortLabel,
        red = red,
        green = green,
        blue = blue,
    }
end

-- ruRU names from the WotLK 3.3.5 quest/NPC database. Alternative spellings
-- are included because private servers sometimes ship a different locale set.
AddPatientName("Смертельно раненный солдат", 1, "ПРИ СМЕРТИ", 0.95, 0.10, 0.10)
AddPatientName("Смертельно раненый солдат", 1, "ПРИ СМЕРТИ", 0.95, 0.10, 0.10)
AddPatientName("Смертельно раненный солдат Альянса", 1, "ПРИ СМЕРТИ", 0.95, 0.10, 0.10)
AddPatientName("Смертельно раненый солдат Альянса", 1, "ПРИ СМЕРТИ", 0.95, 0.10, 0.10)
AddPatientName("Критически раненый солдат", 1, "ПРИ СМЕРТИ", 0.95, 0.10, 0.10)
AddPatientName("Критически раненый солдат Альянса", 1, "ПРИ СМЕРТИ", 0.95, 0.10, 0.10)
AddPatientName("Тяжелораненый солдат", 2, "ТЯЖЕЛО", 1.00, 0.48, 0.05)
AddPatientName("Тяжелораненый солдат Альянса", 2, "ТЯЖЕЛО", 1.00, 0.48, 0.05)
AddPatientName("Тяжело раненый солдат", 2, "ТЯЖЕЛО", 1.00, 0.48, 0.05)
AddPatientName("Тяжело раненый солдат Альянса", 2, "ТЯЖЕЛО", 1.00, 0.48, 0.05)
AddPatientName("Раненый солдат", 3, "РАНЕН", 0.95, 0.82, 0.12)
AddPatientName("Раненый солдат Альянса", 3, "РАНЕН", 0.95, 0.82, 0.12)

-- enUS names are useful when the server returns English NPC names to a ruRU client.
AddPatientName("Critically Injured Soldier", 1, "CRITICAL", 0.95, 0.10, 0.10)
AddPatientName("Critically Injured Alliance Soldier", 1, "CRITICAL", 0.95, 0.10, 0.10)
AddPatientName("Badly Injured Soldier", 2, "BADLY", 1.00, 0.48, 0.05)
AddPatientName("Badly Injured Alliance Soldier", 2, "BADLY", 1.00, 0.48, 0.05)
AddPatientName("Injured Soldier", 3, "INJURED", 0.95, 0.82, 0.12)
AddPatientName("Injured Alliance Soldier", 3, "INJURED", 0.95, 0.82, 0.12)

local driver = CreateFrame("Frame")
local nameplates = {}
local lastWorldChildren = -1
local activeQuestIndex
local scanElapsed = 0
local serial = 0
local panelManuallyHidden = false
local wasQuestActive = false

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(ADDON_PREFIX .. message)
end

local function FindQuest()
    local entries = GetNumQuestLogEntries()
    local index
    for index = 1, entries do
        local _, _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(index)
        if not isHeader and (questID == QUEST_HORDE or questID == QUEST_ALLIANCE) then
            return index
        end
    end
end

local function IsNameplate(frame)
    if not frame or frame:GetObjectType() ~= "Frame" then
        return false
    end
    if frame.UnitFrame or frame.extended or frame.aloftData or frame.kui then
        return true
    end
    if frame:GetName() then
        return false
    end
    local index
    for index = 1, frame:GetNumRegions() do
        local region = select(index, frame:GetRegions())
        if region and region:GetObjectType() == "Texture" and region:GetTexture() == NAMEPLATE_BORDER then
            return true
        end
    end
    return false
end

local function FindPatientInRegions(owner)
    local index
    for index = 1, owner:GetNumRegions() do
        local region = select(index, owner:GetRegions())
        if region and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text and patientNames[text] then
                return text, patientNames[text]
            end
        end
    end
end

local function FindPatient(frame)
    local name, data = FindPatientInRegions(frame)
    if name then
        return name, data
    end
    local index
    for index = 1, frame:GetNumChildren() do
        local child = select(index, frame:GetChildren())
        if child and child ~= frame.triageHelperOverlay then
            name, data = FindPatientInRegions(child)
            if name then
                return name, data
            end
        end
    end
end

local function CreateOverlay(plate)
    local overlay = CreateFrame("Frame", nil, plate)
    overlay:SetWidth(64)
    overlay:SetHeight(64)
    overlay:SetPoint("BOTTOM", plate, "TOP", 0, 4)
    overlay:SetFrameStrata("HIGH")
    overlay:SetFrameLevel(plate:GetFrameLevel() + 20)
    overlay:EnableMouse(false)

    overlay.background = overlay:CreateTexture(nil, "BACKGROUND")
    overlay.background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    overlay.background:SetPoint("CENTER", overlay, "CENTER", 0, 2)
    overlay.background:SetWidth(46)
    overlay.background:SetHeight(46)

    overlay.border = overlay:CreateTexture(nil, "BORDER")
    overlay.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    overlay.border:SetBlendMode("ADD")
    overlay.border:SetPoint("CENTER", overlay.background, "CENTER", 0, 0)
    overlay.border:SetWidth(74)
    overlay.border:SetHeight(74)

    overlay.number = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    overlay.number:SetPoint("CENTER", overlay.background, "CENTER", 0, 2)
    overlay.number:SetTextColor(1, 1, 1)

    overlay.label = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    overlay.label:SetPoint("TOP", overlay.background, "BOTTOM", 0, -1)
    overlay.label:SetTextColor(1, 1, 1)

    overlay:Hide()
    plate.triageHelperOverlay = overlay
    return overlay
end

local function ResetPlate(plate)
    local state = nameplates[plate]
    if state then
        state.name = nil
        state.patient = nil
        state.seenAt = nil
        if state.overlay then
            state.overlay:Hide()
        end
    end
end

local function RegisterNameplate(plate)
    if nameplates[plate] then
        return
    end
    nameplates[plate] = { overlay = CreateOverlay(plate) }
    plate:HookScript("OnHide", function(self)
        ResetPlate(self)
    end)
end

local function ScanWorldFrame(frame, ...)
    if not frame then
        return
    end
    if IsNameplate(frame) then
        RegisterNameplate(frame)
    end
    return ScanWorldFrame(...)
end

local function ScanForNewNameplates()
    local count = WorldFrame:GetNumChildren()
    if count ~= lastWorldChildren then
        lastWorldChildren = count
        ScanWorldFrame(WorldFrame:GetChildren())
    end
end

local function HideAllOverlays()
    local _, state
    for _, state in pairs(nameplates) do
        state.overlay:Hide()
    end
end

local function SortPatients(left, right)
    if left.patient.priority ~= right.patient.priority then
        return left.patient.priority < right.patient.priority
    end
    if left.seenAt ~= right.seenAt then
        return left.seenAt < right.seenAt
    end
    return left.serial < right.serial
end

local function UpdateOverlays()
    if not activeQuestIndex then
        HideAllOverlays()
        return 0
    end

    ScanForNewNameplates()
    local visible = {}
    local plate, state
    for plate, state in pairs(nameplates) do
        if plate:IsShown() then
            local name, patient = FindPatient(plate)
            if name then
                if state.name ~= name or not state.seenAt then
                    serial = serial + 1
                    state.name = name
                    state.patient = patient
                    state.seenAt = GetTime()
                    state.serial = serial
                end
                table.insert(visible, state)
            else
                ResetPlate(plate)
            end
        else
            ResetPlate(plate)
        end
    end

    table.sort(visible, SortPatients)
    local now = GetTime()
    local index
    for index, state in ipairs(visible) do
        local overlay = state.overlay
        local patient = state.patient
        overlay.number:SetText(index)
        overlay.label:SetText(index == 1 and "СЕЙЧАС" or patient.shortLabel)
        overlay.background:SetVertexColor(patient.red, patient.green, patient.blue, 0.92)
        if index == 1 then
            local pulse = 0.65 + 0.35 * math.abs(math.sin(now * 4))
            overlay.border:SetVertexColor(1, 1, 0, pulse)
            overlay:SetScale(1.18)
        else
            overlay.border:SetVertexColor(patient.red, patient.green, patient.blue, 0.70)
            overlay:SetScale(0.92)
        end
        overlay:Show()
    end
    return #visible
end

local panel = CreateFrame("Frame", "TriageHelperPanel", UIParent)
panel:SetWidth(390)
panel:SetHeight(196)
panel:SetPoint("TOP", UIParent, "TOP", 0, -115)
panel:SetFrameStrata("DIALOG")
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})

panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
panel.title:SetPoint("TOP", panel, "TOP", 0, -17)
panel.title:SetText("Очередь на медобслуживание")

panel.priority = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
panel.priority:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -48)
panel.priority:SetWidth(342)
panel.priority:SetJustifyH("LEFT")
panel.priority:SetText("|cffff30301. При смерти|r  >  |cffff8a102. Тяжело|r  >  |cffffd52a3. Ранен|r\nСреди равных первым идёт тот, кто появился раньше.")

panel.status = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
panel.status:SetPoint("TOPLEFT", panel.priority, "BOTTOMLEFT", 0, -12)
panel.status:SetWidth(342)
panel.status:SetJustifyH("LEFT")

panel.hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
panel.hint:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 24, 21)
panel.hint:SetWidth(342)
panel.hint:SetJustifyH("LEFT")
panel.hint:SetText("Нажмите на табличку №1, затем используйте кнопку бинта или свою горячую клавишу.")

local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -5)
close:SetScript("OnClick", function()
    panelManuallyHidden = true
    panel:Hide()
end)

local platesButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
platesButton:SetWidth(136)
platesButton:SetHeight(24)
platesButton:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 23, 47)
platesButton:SetText("Вкл. таблички")
platesButton:SetScript("OnClick", function()
    SetCVar("nameplateShowFriends", "1")
    Print("Дружественные таблички включены. Их можно включать/выключать Shift+V.")
end)

local bandageButton = CreateFrame("Button", "TriageHelperBandageButton", panel, "SecureActionButtonTemplate,UIPanelButtonTemplate")
bandageButton:SetWidth(190)
bandageButton:SetHeight(24)
bandageButton:SetPoint("LEFT", platesButton, "RIGHT", 13, 0)
bandageButton:SetText("Перевязать цель")
bandageButton:RegisterForClicks("AnyUp")
bandageButton:SetAttribute("type", "item")
bandageButton:SetAttribute("item", "item:" .. BANDAGE_ITEM_ID)

local function GetObjectiveText()
    if not activeQuestIndex then
        return ""
    end
    local description = GetQuestLogLeaderBoard(1, activeQuestIndex)
    return description or "Задание активно"
end

local function FriendlyPlatesEnabled()
    return GetCVar("nameplateShowFriends") == "1"
end

local function UpdatePanel(visiblePatients)
    if not activeQuestIndex then
        panel:Hide()
        return
    end
    if not panelManuallyHidden then
        panel:Show()
    end
    local platesText = FriendlyPlatesEnabled() and "|cff55ff55включены|r" or "|cffff5555выключены|r — нажмите Shift+V"
    panel.status:SetText(GetObjectiveText() .. "\nВидно пациентов: " .. visiblePatients .. ". Дружественные таблички: " .. platesText)
end

local function RefreshQuestState()
    activeQuestIndex = FindQuest()
    local active = activeQuestIndex ~= nil
    if active and not wasQuestActive then
        panelManuallyHidden = false
        Print("Помощник активен. Включите дружественные таблички Shift+V.")
    elseif not active and wasQuestActive then
        panel:Hide()
        HideAllOverlays()
        Print("Задание больше не активно; метки скрыты.")
    end
    wasQuestActive = active
end

local function DebugVisibleNameplates()
    ScanForNewNameplates()
    local found = 0
    local plate
    for plate in pairs(nameplates) do
        if plate:IsShown() then
            local texts = {}
            local index
            for index = 1, plate:GetNumRegions() do
                local region = select(index, plate:GetRegions())
                if region and region:GetObjectType() == "FontString" and region:GetText() then
                    table.insert(texts, region:GetText())
                end
            end
            if #texts > 0 then
                found = found + 1
                Print("Табличка " .. found .. ": " .. table.concat(texts, " | "))
            end
        end
    end
    if found == 0 then
        Print("Видимые таблички не найдены. Нажмите Shift+V и повторите /triage debug.")
    end
end

SLASH_TRIAGEHELPER1 = "/triage"
SLASH_TRIAGEHELPER2 = "/medqueue"
SlashCmdList.TRIAGEHELPER = function(message)
    message = string.lower(message or "")
    if message == "debug" then
        DebugVisibleNameplates()
    elseif message == "show" then
        panelManuallyHidden = false
        if activeQuestIndex then
            panel:Show()
        else
            Print("Задание 6622/6624 сейчас нет в журнале.")
        end
    elseif message == "hide" then
        panelManuallyHidden = true
        panel:Hide()
    else
        if activeQuestIndex then
            panelManuallyHidden = panel:IsShown()
            if panelManuallyHidden then
                panel:Hide()
            else
                panel:Show()
            end
        else
            Print("Команды: /triage show, /triage hide, /triage debug. Метки активны только во время задания.")
        end
    end
end

driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("QUEST_LOG_UPDATE")
driver:RegisterEvent("BAG_UPDATE")
driver:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        ScanForNewNameplates()
    end
    RefreshQuestState()
end)

driver:SetScript("OnUpdate", function(self, elapsed)
    scanElapsed = scanElapsed + elapsed
    if scanElapsed < 0.10 then
        return
    end
    scanElapsed = 0
    local visiblePatients = UpdateOverlays()
    UpdatePanel(visiblePatients)
end)

panel:Hide()
