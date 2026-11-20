local P = ProfessionPath
local C = {bg={0.045,0.038,0.03,1}, panel={0.065,0.055,0.043,1}, edge={0.65,0.65,0.65}, text={1,0.95,0.82}, muted={0.78,0.75,0.67}, gold={1,0.82,0}, ready={0.3,1,0.3}, done={0.55,0.75,0.48}, waiting={1,0.82,0}, later={0.65,0.62,0.55}, access={0.45,0.75,1}}
local function panel(parent,x,y,w,h,color)
    local f=CreateFrame("Frame",nil,parent)
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); f:SetWidth(w); f:SetHeight(h)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=32,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    f:SetBackdropColor(unpack(color or C.panel)); f:SetBackdropBorderColor(unpack(C.edge))
    return f
end
local function label(parent,x,y,w,size,color)
    local t=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); t:SetWidth(w)
    -- Keep a working inherited font when a client override cannot be loaded.
    local ok, loaded = pcall(t.SetFont,t,STANDARD_TEXT_FONT,size)
    if not ok or not loaded then
        t:SetFontObject(GameFontNormal)
        local font, _, flags = t:GetFont()
        if font then
            ok, loaded = pcall(t.SetFont,t,font,size,flags)
            if not ok or not loaded then t:SetFontObject(GameFontNormal) end
        end
    end
    t:SetJustifyH("LEFT"); t:SetJustifyV("TOP")
    t:SetTextColor(unpack(color or C.text)); return t
end
local function button(parent,x,y,w,h,text,click)
    local b=CreateFrame("Button",nil,parent,text~="" and "UIPanelButtonTemplate" or nil)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); b:SetWidth(w); b:SetHeight(h)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    if text~="" then b:SetBackdrop(nil) end
    b:SetBackdropColor(unpack(C.panel));b:SetBackdropBorderColor(unpack(C.edge))
    b.caption=label(b,10,(h-16)/2,w-20,15,C.gold); b.caption:SetText(text)
    b.caption:ClearAllPoints();b.caption:SetPoint("CENTER",b,"CENTER",0,0);b.caption:SetJustifyH("CENTER");b.caption:SetJustifyV("MIDDLE")
    b:SetScript("OnClick",click)
    b:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(C.gold)) end)
    b:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(C.edge)) end)
    return b
end

function P:CycleCharacter()
    local keys={}
    for key in pairs(self.db.characters) do keys[#keys+1]=key end
    table.sort(keys)
    local index=1
    for i,key in ipairs(keys) do if key==self.selectedCharacter then index=i%#keys+1;break end end
    self.selectedCharacter=keys[index];self:Refresh()
end

function P:BuildWindow()
    if self.window then return end
    local f=CreateFrame("Frame","ProfessionPathWindow",UIParent)
    self.window=f;f:Hide();f:SetWidth(980);f:SetHeight(760)
    f:SetScale(math.min(1,(UIParent:GetWidth()-40)/980,(UIParent:GetHeight()-40)/760))
    f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    if self.db.position then
        local pos=self.db.position;f:ClearAllPoints();f:SetPoint(pos.point,UIParent,pos.point,pos.x,pos.y)
    end
    f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=11,right=12,top=12,bottom=11}})
    f:SetBackdropColor(unpack(C.bg));f:SetBackdropBorderColor(1,1,1,1)
    local drag=CreateFrame("Frame",nil,f);drag:SetPoint("TOPLEFT",f,"TOPLEFT",0,0);drag:SetWidth(760);drag:SetHeight(74)
    drag:EnableMouse(true);drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart",function() f:StartMoving() end)
    drag:SetScript("OnDragStop",function()
        f:StopMovingOrSizing();local point,_,_,x,y=f:GetPoint(1)
        self.db.position={point=point,x=x,y=y}
    end)
    label(f,24,20,800,28,C.gold):SetText("Путь ремесленника")
    label(f,25,57,850,14,C.muted):SetText("Ваши профессии, следующий ранг и место обучения")
    button(f,780,18,138,30,"Ресурсы",function()
        if self.ToggleTrackingWindow then self:ToggleTrackingWindow()
        else self:Print("Новые модули ещё не загружены. Полностью закройте WoW и запустите клиент снова.") end
    end)
    button(f,930,18,30,30,"X",function() f:Hide() end)
    self.charButton=button(f,24,91,555,34,"Персонаж",function() self:CycleCharacter() end)
    button(f,589,91,160,34,"Мой персонаж",function() self.selectedCharacter=self.currentKey;self:Scan();self:Refresh() end)
    self.filterButton=button(f,759,91,197,34,"Все профессии",function() self.onlyLearned=not self.onlyLearned;self:Refresh() end)
    self.rows={}
    for i=1,14 do
        local row=button(f,24,155+(i-1)*39,246,36,"",function(b) self.selectedProfession=b.key;self:Refresh() end)
        row.caption:Hide()
        row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetPoint("TOPLEFT",row,"TOPLEFT",7,-5);row.icon:SetWidth(26);row.icon:SetHeight(26);row.icon:SetTexCoord(.08,.92,.08,.92)
        row.name=label(row,42,3,194,14)
        row.value=label(row,42,19,194,12,C.muted)
        self.rows[i]=row
    end
    label(f,24,136,245,12,C.muted):SetText("ПРОФЕССИИ ПЕРСОНАЖА")
    self.summary=label(f,24,710,245,13,C.muted)
    self.detail=panel(f,288,145,668,553)
    local d=self.detail
    self.profTitle=label(d,18,16,485,24,C.gold)
    self.profValue=label(d,514,18,140,20,C.ready)
    self.bar=CreateFrame("StatusBar",nil,d)
    self.bar:SetPoint("TOPLEFT",d,"TOPLEFT",18,-52);self.bar:SetWidth(632);self.bar:SetHeight(5)
    self.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");self.bar:SetStatusBarColor(unpack(C.ready))
    self.nextPanel=panel(d,18,75,632,220,{0.10,0.08,0.045,1})
    local n=self.nextPanel
    self.nextLabel=label(n,14,12,600,12,C.ready)
    self.nextTitle=label(n,14,35,278,18)
    self.nextRequirement=label(n,14,67,600,15,C.gold)
    self.nextDestination=label(n,14,93,600,17)
    self.nextNote=label(n,14,141,600,14,C.muted)
    self.pin=button(n,300,31,156,30,"Метка на карте",function() if self.activeRank then self:Pin(self.activeRank) end end)
    self.route=button(n,462,31,156,30,"Проложить путь",function() if self.activeRank then self:Pin(self.activeRank,true) end end)
    self.rankHeader=label(d,18,311,620,12,C.muted);self.rankHeader:SetText("ВСЕ РАНГИ  /  НАЖМИТЕ СТРОКУ, ЧТОБЫ УЗНАТЬ МЕСТО")
    self.questGuideToggle=button(d,18,304,632,27,"СПОЙЛЕР КВЕСТА: ГДЕ ЛОВИТЬ 4 РЫБЫ  v",function()
        if self.activeRank and self.activeRank.triage then
            if self.SetTriageEnabled then self:SetTriageEnabled(not self:IsTriageEnabled())
            else self:Print("Новые модули ещё не загружены. Полностью закройте WoW и запустите клиент снова.") end
        else
            self.questGuideExpanded=not self.questGuideExpanded;self:RefreshDetail()
        end
    end)
    self.questGuideToggle:Hide()
    self.rankRows={}
    for i=1,6 do
        local row=button(d,18,336+(i-1)*35,632,31,"",function(b) self.previewRank=b.index;self.questGuideExpanded=false;self:RefreshDetail() end)
        row.caption:Hide();row.index=i
        row.rank=label(row,10,8,190,14)
        row.requirement=label(row,206,8,200,13,C.muted)
        row.state=label(row,410,8,210,13)
        self.rankRows[i]=row
    end
    self.questGuidePanel=panel(d,18,336,632,199,{0.075,0.062,0.04,1});self.questGuidePanel:Hide()
    self.questGuideRows={}
    for i=1,5 do
        local row=panel(self.questGuidePanel,8,8+(i-1)*37,616,33,C.panel)
        row.name=label(row,8,3,226,11)
        row.status=label(row,238,4,70,10,C.ready);row.status:SetJustifyH("RIGHT")
        row.place=label(row,8,18,300,10,C.muted)
        row.pin=button(row,316,3,134,27,"Метка на карте",function(b) if b.destination then self:PinDestination(b.destination) end end)
        row.route=button(row,456,3,152,27,"Проложить путь",function(b) if b.destination then self:PinDestination(b.destination,true) end end)
        self.questGuideRows[i]=row
    end
    self.footer=label(f,288,710,665,13,C.muted)
    f:SetScript("OnShow",function() self:Scan();self:Refresh() end)
    tinsert(UISpecialFrames,"ProfessionPathWindow")
end

function P:RefreshDetail()
    local c=self:Character()
    local p=self.byKey[self.selectedProfession]
    if not p then return end
    local s=self:Skill(c,p.key)
    self.profTitle:SetText(p.name)
    self.profValue:SetText(s and (s.rank.." / "..s.cap) or "Не изучено")
    self.bar:SetMinMaxValues(0,s and math.max(s.cap,1) or 75);self.bar:SetValue(s and s.rank or 0)
    local nextRank,nextIndex=self:NextRank(c,p)
    local index=self.previewRank or nextIndex or 6
    local r=p.ranks[index];self.activeRank=r
    local state,code=self:State(c,p,r)
    self.nextLabel:SetText((self.previewRank and "ВЫБРАННЫЙ РАНГ" or nextRank and "СЛЕДУЮЩИЙ ШАГ" or "ВСЕ РАНГИ ОТКРЫТЫ").."  /  "..state)
    self.nextLabel:SetTextColor(unpack(C[code]))
    self.nextTitle:SetText(r.name.." — до "..r.cap)
    self.nextRequirement:SetText("С навыка "..r.skill.."  |  Уровень "..r.level.."  |  "..r.method)
    local dest=self:Destination(c,r)
    local coords=dest and dest.x and string.format(" (%.1f, %.1f)",dest.x,dest.y) or ""
    self.nextDestination:SetText(dest and (dest.name.." — "..dest.zone..coords) or "Фракция персонажа пока неизвестна")
    local note=r.note
    if r.cap==375 then note=note.." Нужен доступ в Запределье."
    elseif r.cap==450 then note=note.." Нужен доступ в Нордскол." end
    if not nextRank and not self.previewRank then note="Все ранги открыты. "..(s.rank>=s.cap and "Профессия прокачана до максимума." or "Продолжайте прокачку до "..s.cap.."; новый ранг изучать не нужно.") end
    self.nextNote:SetText(note)
    self.pin.caption:SetText(TomTom and "Метка на карте" or "Путь в чат")
    for i,row in ipairs(self.rankRows) do
        local rr=p.ranks[i];local text,color=self:State(c,p,rr)
        row.rank:SetText(rr.name.." / "..rr.cap)
        row.requirement:SetText("Навык "..rr.skill.." / ур. "..rr.level)
        row.state:SetText(text);row.state:SetTextColor(unpack(C[color]))
        row:SetBackdropColor(unpack(i==index and {0.18,0.15,0.10,1} or C.panel))
        row:SetBackdropBorderColor(unpack(i==index and C.gold or C.edge))
    end
    local guide=r.guide or p.specializationGuide
    if r.triage then
        local triageEnabled=self.IsTriageEnabled and self:IsTriageEnabled()
        self.rankHeader:Hide();self.questGuideToggle:Show();self.questGuidePanel:Hide()
        self.questGuideToggle.caption:SetText(triageEnabled and "ПОМОЩНИК ЗАДАНИЯ: ВКЛЮЧЁН  /  НАЖМИТЕ, ЧТОБЫ ВЫКЛЮЧИТЬ" or "ПОМОЩНИК ЗАДАНИЯ: ВКЛЮЧИТЬ ПОРЯДОК ЛЕЧЕНИЯ")
        for _,row in ipairs(self.rankRows) do row:Show() end
    elseif guide then
        self.rankHeader:Hide();self.questGuideToggle:Show()
        local guideLabel=p.specializationGuide==guide and "СПЕЦИАЛИЗАЦИИ" or "СПОЙЛЕР КВЕСТА"
        self.questGuideToggle.caption:SetText(self.questGuideExpanded and ("СКРЫТЬ: "..guide.title.."  ^") or (guideLabel..": "..guide.title.."  v"))
        if self.questGuideExpanded then
            self.questGuidePanel:SetHeight(14+#guide.steps*37);self.questGuidePanel:Show()
            for _,row in ipairs(self.rankRows) do row:Hide() end
            for i,row in ipairs(self.questGuideRows) do
                local step=guide.steps[i]
                if step then
                    local target=step[c.faction] or step.target
                    row:Show();row.pin.destination=target;row.route.destination=target
                    local amount=step.item and GetItemCount(step.item) or 0
                    local needed=step.count or 1
                    local caught=step.item and amount>=needed
                    row.name:SetText((step.item and GetItemInfo(step.item)) or step.name)
                    row.status:SetText(step.item and (needed>1 and (amount.."/"..needed) or (caught and "Поймано" or "")) or "")
                    row.status:SetTextColor(unpack(caught and C.ready or C.gold))
                    row.place:SetText((target.hint or step.hint)..string.format("  (%.1f, %.1f)",target.x,target.y))
                else row:Hide() end
            end
        else
            self.questGuidePanel:Hide()
            for _,row in ipairs(self.rankRows) do row:Show() end
        end
    else
        self.rankHeader:Show();self.questGuideToggle:Hide();self.questGuidePanel:Hide()
        for _,row in ipairs(self.rankRows) do row:Show() end
    end
    self.footer:SetText("Классическая прогрессия / TBC / WotLK. Порог навыка не подтверждает доступ к этапу сервера. Координаты — ориентир для клиента 3.3.5.")
end

function P:Refresh()
    if not self.window then return end
    local c=self:Character()
    local current=self.selectedCharacter==self.currentKey
    local stamp=current and "сейчас" or (c.updated and date("%d.%m %H:%M",c.updated) or "нет снимка")
    self.charButton.caption:SetText(c.name.." / "..c.realm.." / ур. "..(c.level or 1).." / "..stamp.."  >")
    self.filterButton.caption:SetText(self.onlyLearned and "Только изученные" or "Все профессии")
    local entries,learned={},0
    for _,p in ipairs(self.catalog) do
        if self:Skill(c,p.key) then learned=learned+1;entries[#entries+1]=p end
    end
    if not self.onlyLearned then for _,p in ipairs(self.catalog) do if not self:Skill(c,p.key) then entries[#entries+1]=p end end end
    if self.onlyLearned and not self:Skill(c,self.selectedProfession) then self.selectedProfession=nil end
    if not self.selectedProfession then self.selectedProfession=(entries[1] or self.catalog[1]).key end
    if self.detailKey~=self.selectedProfession or self.detailCharacter~=self.selectedCharacter then
        self.previewRank=nil;self.questGuideExpanded=false;self.detailKey=self.selectedProfession;self.detailCharacter=self.selectedCharacter
    end
    for i,row in ipairs(self.rows) do
        local p=entries[i]
        if p then
            row.key=p.key;row:Show();row.icon:SetTexture(p.icon);row.name:SetText(p.name)
            local s=self:Skill(c,p.key);local r=self:NextRank(c,p)
            row.value:SetText(s and (s.rank.." / "..s.cap..(r and ("   Следующий: "..r.skill) or "   Последний ранг")) or "Не изучено")
            row:SetBackdropColor(unpack(p.key==self.selectedProfession and {0.18,0.15,0.10,1} or C.bg))
            row:SetBackdropBorderColor(unpack(p.key==self.selectedProfession and C.gold or C.edge))
        else row:Hide() end
    end
    self.summary:SetText("Изучено: "..learned.." / 14\n"..(current and "Навык обновляется автоматически" or "Сохранённый снимок персонажа"))
    self:RefreshDetail()
end

function P:Toggle()
    self:BuildWindow()
    if self.window:IsShown() then self.window:Hide() else self.previewRank=nil;self.window:Show() end
end

function P:CreateLauncher()
    if self.launcher then return end
    local b=CreateFrame("Button","ProfessionPathMinimapButton",Minimap)
    self.launcher=b;b:SetWidth(30);b:SetHeight(30);b:SetPoint("TOPLEFT",Minimap,"TOPLEFT",-7,-20)
    -- Preserve old floating coordinates without restoring them outside the minimap.
    b:SetClampedToScreen(true);b:EnableMouse(true);b:RegisterForClicks("LeftButtonUp")
    b:SetNormalTexture("Interface\\Icons\\Trade_BlackSmithing")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    b:SetScript("OnClick",function() self:Toggle() end)
    b:SetScript("OnEnter",function()
        GameTooltip:SetOwner(b,"ANCHOR_LEFT");GameTooltip:AddLine("Путь ремесленника",.95,.77,.43)
        GameTooltip:AddLine("ЛКМ: профессии и следующий учитель",1,1,1)
        GameTooltip:AddLine("Открыть: /profpath",.6,.7,.7);GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
end
