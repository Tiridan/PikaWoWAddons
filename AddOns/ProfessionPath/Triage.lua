local P = ProfessionPath
local QUEST_HORDE = 6622
local QUEST_ALLIANCE = 6624
local BANDAGE_ITEM_ID = 16991
local NAMEPLATE_BORDER = "Interface\\Tooltips\\Nameplate-Border"

local patientNames = {}
local function AddPatientName(name, priority, shortLabel, red, green, blue)
    patientNames[name] = {priority = priority, shortLabel = shortLabel, red = red, green = green, blue = blue}
end

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
AddPatientName("Critically Injured Soldier", 1, "CRITICAL", 0.95, 0.10, 0.10)
AddPatientName("Critically Injured Alliance Soldier", 1, "CRITICAL", 0.95, 0.10, 0.10)
AddPatientName("Badly Injured Soldier", 2, "BADLY", 1.00, 0.48, 0.05)
AddPatientName("Badly Injured Alliance Soldier", 2, "BADLY", 1.00, 0.48, 0.05)
AddPatientName("Injured Soldier", 3, "INJURED", 0.95, 0.82, 0.12)
AddPatientName("Injured Alliance Soldier", 3, "INJURED", 0.95, 0.82, 0.12)

local nameplates = {}
local activeQuestIndex
local lastWorldChildren = -1
local scanElapsed = 0
local serial = 0
local panelManuallyHidden = false
local wasQuestActive = false
local panel

local function FindQuest()
    for index = 1, GetNumQuestLogEntries() do
        local _, _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(index)
        if not isHeader and (questID == QUEST_HORDE or questID == QUEST_ALLIANCE) then return index end
    end
end

local function IsNameplate(frame)
    if not frame or frame:GetObjectType() ~= "Frame" then return false end
    if frame.UnitFrame or frame.extended or frame.aloftData or frame.kui then return true end
    if frame:GetName() then return false end
    for index = 1, frame:GetNumRegions() do
        local region = select(index, frame:GetRegions())
        if region and region:GetObjectType() == "Texture" and region:GetTexture() == NAMEPLATE_BORDER then return true end
    end
    return false
end

local function FindPatientInRegions(owner)
    for index = 1, owner:GetNumRegions() do
        local region = select(index, owner:GetRegions())
        if region and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text and patientNames[text] then return text, patientNames[text] end
        end
    end
end

local function FindPatient(frame)
    local name, data = FindPatientInRegions(frame)
    if name then return name, data end
    for index = 1, frame:GetNumChildren() do
        local child = select(index, frame:GetChildren())
        if child and child ~= frame.professionPathTriageOverlay then
            name, data = FindPatientInRegions(child)
            if name then return name, data end
        end
    end
end

local function CreateOverlay(plate)
    local overlay = CreateFrame("Frame", nil, plate)
    overlay:SetWidth(64); overlay:SetHeight(64); overlay:SetPoint("BOTTOM", plate, "TOP", 0, 4)
    overlay:SetFrameStrata("HIGH"); overlay:SetFrameLevel(plate:GetFrameLevel() + 20); overlay:EnableMouse(false)
    overlay.background = overlay:CreateTexture(nil, "BACKGROUND")
    overlay.background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    overlay.background:SetPoint("CENTER", overlay, "CENTER", 0, 2); overlay.background:SetWidth(46); overlay.background:SetHeight(46)
    overlay.border = overlay:CreateTexture(nil, "BORDER")
    overlay.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border"); overlay.border:SetBlendMode("ADD")
    overlay.border:SetPoint("CENTER", overlay.background, "CENTER", 0, 0); overlay.border:SetWidth(74); overlay.border:SetHeight(74)
    overlay.number = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    overlay.number:SetPoint("CENTER", overlay.background, "CENTER", 0, 2); overlay.number:SetTextColor(1, 1, 1)
    overlay.label = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    overlay.label:SetPoint("TOP", overlay.background, "BOTTOM", 0, -1); overlay.label:SetTextColor(1, 1, 1)
    overlay:Hide(); plate.professionPathTriageOverlay = overlay
    return overlay
end

local function ResetPlate(plate)
    local state = nameplates[plate]
    if state then
        state.name, state.patient, state.seenAt = nil, nil, nil
        state.overlay:Hide()
    end
end

local function RegisterNameplate(plate)
    if nameplates[plate] then return end
    nameplates[plate] = {overlay = CreateOverlay(plate)}
    plate:HookScript("OnHide", function(self) ResetPlate(self) end)
end

local function ScanWorldFrame(frame, ...)
    if not frame then return end
    if IsNameplate(frame) then RegisterNameplate(frame) end
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
    for _, state in pairs(nameplates) do state.overlay:Hide() end
end

local function SortPatients(left, right)
    if left.patient.priority ~= right.patient.priority then return left.patient.priority < right.patient.priority end
    if left.seenAt ~= right.seenAt then return left.seenAt < right.seenAt end
    return left.serial < right.serial
end

local function UpdateOverlays()
    if not activeQuestIndex or not P:IsTriageEnabled() then HideAllOverlays(); return 0 end
    ScanForNewNameplates()
    local visible = {}
    for plate, state in pairs(nameplates) do
        if plate:IsShown() then
            local name, patient = FindPatient(plate)
            if name then
                if state.name ~= name or not state.seenAt then
                    serial = serial + 1
                    state.name, state.patient, state.seenAt, state.serial = name, patient, GetTime(), serial
                end
                visible[#visible + 1] = state
            else ResetPlate(plate) end
        else ResetPlate(plate) end
    end
    table.sort(visible, SortPatients)
    local now = GetTime()
    for index, state in ipairs(visible) do
        local overlay, patient = state.overlay, state.patient
        overlay.number:SetText(index); overlay.label:SetText(index == 1 and "СЕЙЧАС" or patient.shortLabel)
        overlay.background:SetVertexColor(patient.red, patient.green, patient.blue, 0.92)
        if index == 1 then
            overlay.border:SetVertexColor(1, 1, 0, 0.65 + 0.35 * math.abs(math.sin(now * 4))); overlay:SetScale(1.18)
        else
            overlay.border:SetVertexColor(patient.red, patient.green, patient.blue, 0.70); overlay:SetScale(0.92)
        end
        overlay:Show()
    end
    return #visible
end

local function FriendlyPlatesEnabled()
    return GetCVar("nameplateShowFriends") == "1"
end

local function GetObjectiveText()
    if not activeQuestIndex then return "" end
    return GetQuestLogLeaderBoard(1, activeQuestIndex) or "Задание активно"
end

local function UpdatePanel(visiblePatients)
    if not panel then return end
    if not activeQuestIndex or not P:IsTriageEnabled() then panel:Hide(); return end
    if not panelManuallyHidden then panel:Show() end
    local platesText = FriendlyPlatesEnabled() and "|cff55ff55включены|r" or "|cffff5555выключены|r — нажмите Shift+V"
    panel.status:SetText(GetObjectiveText() .. "\nВидно пациентов: " .. visiblePatients .. ". Дружественные таблички: " .. platesText)
end

local function RefreshQuestState()
    activeQuestIndex = FindQuest()
    local active = activeQuestIndex ~= nil
    if P:IsTriageEnabled() and active and not wasQuestActive then
        panelManuallyHidden = false
        P:Print("Помощник первой помощи активен. Включите дружественные таблички Shift+V.")
    elseif not active and wasQuestActive then
        if panel then panel:Hide() end
        HideAllOverlays()
        if P:IsTriageEnabled() then P:Print("Задание первой помощи больше не активно; метки скрыты.") end
    end
    wasQuestActive = active
    if panel then UpdatePanel(0) end
end

local function BuildPanel()
    if panel then return end
    panel = CreateFrame("Frame", "ProfessionPathTriagePanel", UIParent)
    panel:SetWidth(390); panel:SetHeight(196); panel:SetPoint("TOP", UIParent, "TOP", 0, -115)
    panel:SetFrameStrata("DIALOG"); panel:SetMovable(true); panel:EnableMouse(true); panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving); panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = {left = 11, right = 12, top = 12, bottom = 11}})
    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panel.title:SetPoint("TOP", panel, "TOP", 0, -17); panel.title:SetText("Очередь на медобслуживание")
    panel.priority = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.priority:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -48); panel.priority:SetWidth(342); panel.priority:SetJustifyH("LEFT")
    panel.priority:SetText("|cffff30301. При смерти|r  >  |cffff8a102. Тяжело|r  >  |cffffd52a3. Ранен|r\nСреди равных первым идёт тот, кто появился раньше.")
    panel.status = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.status:SetPoint("TOPLEFT", panel.priority, "BOTTOMLEFT", 0, -12); panel.status:SetWidth(342); panel.status:SetJustifyH("LEFT")
    panel.hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.hint:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 24, 21); panel.hint:SetWidth(342); panel.hint:SetJustifyH("LEFT")
    panel.hint:SetText("Нажмите на табличку №1, затем используйте кнопку бинта или свою горячую клавишу.")
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() panelManuallyHidden = true; panel:Hide() end)
    local platesButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    platesButton:SetWidth(136); platesButton:SetHeight(24); platesButton:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 23, 47); platesButton:SetText("Вкл. таблички")
    platesButton:SetScript("OnClick", function()
        SetCVar("nameplateShowFriends", "1"); P:Print("Дружественные таблички включены. Их можно включать/выключать Shift+V.")
    end)
    local bandageButton = CreateFrame("Button", "ProfessionPathTriageBandageButton", panel, "SecureActionButtonTemplate,UIPanelButtonTemplate")
    bandageButton:SetWidth(190); bandageButton:SetHeight(24); bandageButton:SetPoint("LEFT", platesButton, "RIGHT", 13, 0)
    bandageButton:SetText("Перевязать цель"); bandageButton:RegisterForClicks("AnyUp")
    bandageButton:SetAttribute("type", "item"); bandageButton:SetAttribute("item", "item:" .. BANDAGE_ITEM_ID)
    panel:Hide()
end

function P:InitTriage()
    self.db.triage = self.db.triage or {}
    if self.db.triage.enabled == nil then self.db.triage.enabled = false end
    BuildPanel()
    RefreshQuestState()
end

function P:IsTriageEnabled()
    return self.db and self.db.triage and self.db.triage.enabled == true
end

function P:SetTriageEnabled(enabled, quiet)
    if not self.db.triage then self.db.triage = {} end
    self.db.triage.enabled = enabled and true or false
    if enabled then
        panelManuallyHidden = false
        RefreshQuestState()
        if activeQuestIndex then
            panel:Show()
            if not quiet then self:Print("Помощник первой помощи включён. Лечите пациента с номером 1.") end
        elseif not quiet then
            self:Print("Помощник первой помощи включён и откроется при получении задания 6622/6624.")
        end
    else
        if panel then panel:Hide() end
        HideAllOverlays()
        if not quiet then self:Print("Помощник первой помощи выключен.") end
    end
    if self.window and self.window:IsShown() then self:RefreshDetail() end
end

local function DebugVisibleNameplates()
    ScanForNewNameplates()
    local found = 0
    for plate in pairs(nameplates) do
        if plate:IsShown() then
            local texts = {}
            for index = 1, plate:GetNumRegions() do
                local region = select(index, plate:GetRegions())
                if region and region:GetObjectType() == "FontString" and region:GetText() then texts[#texts + 1] = region:GetText() end
            end
            if #texts > 0 then found = found + 1; P:Print("Табличка " .. found .. ": " .. table.concat(texts, " | ")) end
        end
    end
    if found == 0 then P:Print("Видимые таблички не найдены. Нажмите Shift+V и повторите /triage debug.") end
end

SLASH_PROFESSIONPATHTRIAGE1 = "/triage"
SLASH_PROFESSIONPATHTRIAGE2 = "/medqueue"
SlashCmdList.PROFESSIONPATHTRIAGE = function(message)
    message = string.lower(message or "")
    if message == "debug" then DebugVisibleNameplates()
    elseif message == "show" then
        panelManuallyHidden = false
        if activeQuestIndex and P:IsTriageEnabled() then panel:Show() else P:Print("Включите помощника на этапе «Первая помощь — Искусник»; панель появится во время задания.") end
    elseif message == "hide" then panelManuallyHidden = true; if panel then panel:Hide() end
    else P:SetTriageEnabled(not P:IsTriageEnabled()) end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("QUEST_LOG_UPDATE")
driver:RegisterEvent("BAG_UPDATE")
driver:SetScript("OnEvent", function()
    if P.db then RefreshQuestState() end
end)
driver:SetScript("OnUpdate", function(_, elapsed)
    if not P.db or not P:IsTriageEnabled() or not activeQuestIndex then return end
    scanElapsed = scanElapsed + elapsed
    if scanElapsed < 0.10 then return end
    scanElapsed = 0
    UpdatePanel(UpdateOverlays())
end)

