local ADDON_PREFIX = "|cff31eaffCursor Halo:|r "
local DOT_COUNT = 24
local RADIUS = 32

local anchor = CreateFrame("Frame", "CursorHaloAnchor", UIParent)
anchor:SetWidth(1)
anchor:SetHeight(1)
anchor:SetFrameStrata("TOOLTIP")
anchor:SetFrameLevel(100)

local halo = CreateFrame("Frame", "CursorHaloVisual", anchor)
halo:SetWidth(1)
halo:SetHeight(1)
halo:SetPoint("CENTER", anchor, "CENTER", 0, 0)

local function CreateDot(size, red, green, blue, alpha, angle)
    local texture = halo:CreateTexture(nil, "OVERLAY")
    texture:SetTexture("Interface\\Buttons\\WHITE8X8")
    texture:SetBlendMode("ADD")
    texture:SetVertexColor(red, green, blue, alpha)
    texture:SetWidth(size)
    texture:SetHeight(size)
    texture:SetPoint(
        "CENTER",
        halo,
        "CENTER",
        math.cos(angle) * RADIUS,
        math.sin(angle) * RADIUS
    )
    return texture
end

for index = 1, DOT_COUNT do
    local angle = ((index - 1) / DOT_COUNT) * math.pi * 2
    CreateDot(8, 0.00, 0.35, 0.55, 0.18, angle)
    CreateDot(4, 0.15, 0.95, 1.00, 0.72, angle)
end

local lastX
local lastY
local lastScale

anchor:SetScript("OnUpdate", function(self)
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()

    if scale ~= lastScale then
        halo:SetScale(1 / scale)
        lastScale = scale
    end

    x = x / scale
    y = y / scale

    if x ~= lastX or y ~= lastY then
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        lastX = x
        lastY = y
    end
end)

SLASH_CURSORHALO1 = "/cursorhalo"
SLASH_CURSORHALO2 = "/chalo"

SlashCmdList.CURSORHALO = function(message)
    message = string.lower((message or ""):match("^%s*(.-)%s*$"))

    if message == "off" then
        anchor:Hide()
        DEFAULT_CHAT_FRAME:AddMessage(ADDON_PREFIX .. "метка скрыта до следующего входа или /reload.")
    elseif message == "on" then
        anchor:Show()
        DEFAULT_CHAT_FRAME:AddMessage(ADDON_PREFIX .. "метка включена.")
    else
        DEFAULT_CHAT_FRAME:AddMessage(ADDON_PREFIX .. "постоянная метка активна. Команды: /cursorhalo on, /cursorhalo off")
    end
end

anchor:Show()
