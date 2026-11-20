local P=PikaBankViewer;

function P:OpenInventory()
    if self.adi and self.adi:IsEnabled() then
        local bag=self.adi:GetModule("Backpack",true); if bag then bag:Open(); return; end
    end
    if ArkInventory and ArkInventory:IsEnabled() then
        ArkInventory.Frame_Main_Show(ArkInventory.Const.Location.Bag); return;
    end
    if Bagnon and Bagnon:IsEnabled() then Bagnon:ShowFrame("inventory"); return; end
    if self.oneBag and self.oneBag:IsEnabled() then self.oneBag:OpenBag(0); return; end
    OpenAllBags();
end

-- OneBag3/OneBank3 create their frames during AceAddon initialization.
hooksecurefunc(P, "AttachBags", function()
    local ace = LibStub and LibStub("AceAddon-3.0", true);
    if not ace then return; end
    P.oneBag = ace:GetAddon("OneBag3", true);
    P.oneBank = ace:GetAddon("OneBank3", true);
    for _, name in ipairs({"OneBag3", "OneBank3"}) do
        local addon = ace:GetAddon(name, true);
        local frame = addon and addon.frame;
        if frame and frame.configButton and not frame.pikaNavigation then
            local bank = P:Button(frame, "Б", 22, function()
                if P.atBank and P.oneBank and P.oneBank:IsEnabled() then P.oneBank.frame:Show();
                else P:Open("bank"); end
            end);
            local ling = P:Button(frame, "Ling", 48, function() P:Open("ling"); end);
            bank:SetHeight(20); ling:SetHeight(20);
            ling:SetPoint("RIGHT", frame.configButton, "LEFT", -3, 0);
            bank:SetPoint("RIGHT", ling, "LEFT", -3, 0);
            for _, button in ipairs({bank,ling}) do
                local label = button == bank and "Банк: у банкира — OneBank3, вдали — сохранённый просмотр" or "Ling — хранилище ресурсов";
                button:SetScript("OnEnter",function(b) GameTooltip:SetOwner(b,"ANCHOR_TOP"); GameTooltip:SetText(label); GameTooltip:Show(); end);
                button:SetScript("OnLeave",function() GameTooltip:Hide(); end);
            end
            if frame.name then frame.name:SetPoint("RIGHT",bank,"LEFT",-4,0); end
            frame.pikaNavigation = {bank,ling};
        end
    end
end);

-- The inventory addons own their windows and settings. Ling never disables them.
if ArkInventory then
    hooksecurefunc(ArkInventory,"MenuSwitchLocation",function(frame,level,value,offset)
        if level==offset+1 then
            ArkInventory.Lib.DewDrop:AddLine("text","Ling","tooltipTitle","Хранилище Ling",
                "icon","Interface\\AddOns\\PikaBankViewer\\Portrait",
                "iconCoordLeft",0.193359375,"iconCoordRight",0.59765625,"iconCoordTop",0.0390625,"iconCoordBottom",0.443359375,
                "closeWhenClicked",true,"func",function() P:Open("ling"); end);
        end
    end);
end

hooksecurefunc(P,"CreateUI",function()
    if not P.bankTab or P.inventoryNavigation then return; end
    P.inventoryNavigation=true;
    P.bankTab:Hide();
    P.lingTab:ClearAllPoints(); P.lingTab:SetPoint("TOPLEFT",P.frame,"TOPLEFT",20,-49);
    P.bagsTab=P:Button(P.frame,"Сумки",70,function() P:OpenInventory(); end);
    P.bagsTab:SetPoint("LEFT",P.lingTab,"RIGHT",6,0);
end);
hooksecurefunc(P,"Refresh",function()
    if not P.frame or not P.frame:IsShown() or not P.bagsTab then return; end
    P.bankTab:Hide(); P.search:ClearAllPoints();
    P.search:SetPoint("TOPLEFT",P.frame,"TOPLEFT",204,-50);
    P.search:SetPoint("TOPRIGHT",P.frame,"TOPRIGHT",P.mode=="bank" and -24 or -158,-50);
end);
SLASH_PIKALING1="/ling"; SLASH_PIKALING2="/arkling";
SlashCmdList.PIKALING=function() P:Open("ling"); end;

-- Extend Bagnon's own menu layout so search/title reserve space for these buttons.
if Bagnon and Bagnon.Frame and Bagnon.Frame.PlaceMenuButtons then
    local placeMenu = Bagnon.Frame.PlaceMenuButtons;
    Bagnon.Frame.PlaceMenuButtons = function(frame, ...)
        local width, height = placeMenu(frame, ...);
        local id = frame:GetFrameID();
        if id ~= "inventory" and id ~= "bank" then return width, height; end
        if not frame.pikaNavigation then
            frame.pikaNavigation = {
                P:Button(frame, "Банк", 48, function() Bagnon:ShowFrame("bank"); end),
                P:Button(frame, "Ling", 44, function() P:Open("ling"); end)
            };
            for _, button in ipairs(frame.pikaNavigation) do button:SetHeight(20); end
        end
        local menu = frame.menuButtons;
        for _, button in ipairs(frame.pikaNavigation) do
            button:ClearAllPoints();
            if #menu > 0 then button:SetPoint("TOPLEFT", menu[#menu], "TOPRIGHT", 4, 0);
            else button:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8); end
            menu[#menu + 1] = button; button:Show();
        end
        width = 0;
        for i, button in ipairs(menu) do width = width + button:GetWidth() + (i > 1 and 4 or 0); end
        return width, math.max(height, 20);
    end;
end
