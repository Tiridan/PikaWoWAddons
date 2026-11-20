local G=SoloProgressGuide
local C={bg={0.045,0.038,0.03,1},panel={0.065,0.055,0.043,1},line={0.65,0.65,0.65},text={1,0.95,0.82},muted={0.78,0.75,0.67},gold={1,0.82,0},green={0.3,1,0.3},blue={0.45,0.75,1},red={1,0.35,0.25}}
local function color(font,c) font:SetTextColor(c[1],c[2],c[3]) end
local function label(parent,size,x,y,width,text,c)
 local f=parent:CreateFontString(nil,"OVERLAY")
 f:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",size)
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y);f:SetWidth(width)
 f:SetJustifyH("LEFT");f:SetJustifyV("TOP");f:SetSpacing(3)
 f:SetText(text or "");color(f,c or C.text);return f
end
local function panel(parent,x,y,w,h)
 local f=CreateFrame("Frame",nil,parent)
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y);f:SetWidth(w);f:SetHeight(h)
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=32,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 f:SetBackdropColor(unpack(C.panel));f:SetBackdropBorderColor(unpack(C.line));return f
end
local function button(parent,x,y,w,h,text,fn)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y);b:SetWidth(w);b:SetHeight(h)
 b:SetBackdrop(nil)
 b:SetBackdropColor(0.095,0.12,0.155,1);b:SetBackdropBorderColor(unpack(C.line))
 b.text=label(b,15,0,0,w-16,text,C.gold)
 b.text:ClearAllPoints();b.text:SetPoint("CENTER",b,"CENTER",0,0);b.text:SetJustifyH("CENTER");b.text:SetJustifyV("MIDDLE")
 b:SetScript("OnClick",fn)
 b:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(C.gold)) end)
 b:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(C.line));GameTooltip:Hide() end)
 return b
end
local function icon(parent,path,x,y,size)
 local t=parent:CreateTexture(nil,"ARTWORK")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y);t:SetWidth(size);t:SetHeight(size)
 t:SetTexture(path or G.icons.unknown);t:SetTexCoord(0.07,0.93,0.07,0.93);return t
end
function G:ApplyScale()
 local scale=SoloProgressGuideDB.ui.scale or 0.9
 local width=self.window and self.window:GetWidth() or 1180
 local height=self.window and self.window:GetHeight() or 760
 scale=math.min(scale,(UIParent:GetWidth()-20)/width,(UIParent:GetHeight()-20)/height)
 self.window:SetScale(math.max(0.4,scale))
end
function G:LayoutWindow()
 if not self.window then return end
 local w=self.window
 local width=w:GetWidth()
 local height=w:GetHeight()
 local sidebarWidth=300
 local mainX=sidebarWidth+22
 local contentWidth=math.max(726,width-mainX-42)
 local viewportHeight=math.max(554,height-176)
 self.contentWidth=contentWidth
 self.viewportHeight=viewportHeight
 if self.searchButton then
  self.searchButton:ClearAllPoints();self.searchButton:SetPoint("TOPLEFT",w,"TOPLEFT",mainX+118,-22)
 end
 if self.identity then
  self.identity:ClearAllPoints();self.identity:SetPoint("TOPLEFT",w,"TOPLEFT",mainX+298,-24)
  self.identity:SetWidth(math.max(220,width-mainX-368))
 end
 if self.closeButton then
  self.closeButton:ClearAllPoints();self.closeButton:SetPoint("TOPLEFT",w,"TOPLEFT",width-46,-18)
 end
 local tabWidth=(contentWidth-36)/4
 for i,data in ipairs(self.tabOrder or {}) do
  local b=self.tabs and self.tabs[data[1]]
  if b then
   b:ClearAllPoints();b:SetPoint("TOPLEFT",w,"TOPLEFT",mainX+(i-1)*(tabWidth+12),-80);b:SetWidth(tabWidth)
  end
 end
 if self.stageHeader then self.stageHeader:SetWidth(sidebarWidth-39) end
 local stageWidth=sidebarWidth-39
 for i=0,18 do
  local b=self.stageButtons and self.stageButtons[i]
  if b then
   b:SetWidth(stageWidth);b.text:SetWidth(stageWidth-80)
   b.progress:ClearAllPoints();b.progress:SetPoint("TOPLEFT",b,"TOPLEFT",stageWidth-48,-7)
  end
 end
 if self.scroll then
  self.scroll:ClearAllPoints();self.scroll:SetPoint("TOPLEFT",w,"TOPLEFT",mainX,-128)
  self.scroll:SetWidth(contentWidth);self.scroll:SetHeight(viewportHeight)
 end
 if self.content then self.content:SetWidth(contentWidth) end
 if self.footer then
  self.footer:ClearAllPoints();self.footer:SetPoint("TOPLEFT",w,"TOPLEFT",mainX+2,-(height-38));self.footer:SetWidth(contentWidth)
 end
 if self.guideVersion then
  self.guideVersion:ClearAllPoints();self.guideVersion:SetPoint("TOPLEFT",w,"TOPLEFT",24,-(height-27))
 end
end
function G:PassageRow(f,y,text,fn,ref,rowColor)
 f.passageUsed=(f.passageUsed or 0)+1;f.passageRows=f.passageRows or {}
 local row=f.passageRows[f.passageUsed]
 if not row then
  row=CreateFrame("Button",nil,f)
  row.text=label(row,14,0,5,700,"")
  row.link=button(row,476,0,100,28,"Wowhead",function() end)
  row.map=button(row,584,0,110,28,"На карту",function() end)
  f.passageRows[f.passageUsed]=row
 end
 row:ClearAllPoints();row:SetPoint("TOPLEFT",f,"TOPLEFT",28,-y);row:SetWidth(710)
  local hasLink=ref and ref[2]
  local hasMap=ref and ref.targets and #ref.targets>0
  row.text:SetWidth(hasLink and 464 or hasMap and 570 or 700);row.text:SetText(text);color(row.text,rowColor or (fn and C.gold or C.text))
  row:SetScript("OnClick",fn);row:EnableMouse(fn~=nil);row.link:Hide();row.map:Hide()
  if ref then
   if hasLink then
    row.link.text:SetText(ref[2]:find("wowhead.com",1,true) and "Wowhead" or "Источник")
    row.link:SetScript("OnClick",function() G:ShowURLs({ref[2]}) end);row.link:Show()
   end
   if hasMap then
    if not ref.compactMap then row.text:SetText(text.."\nНа карте: "..ref.targets[1].name..(#ref.targets>1 and " (выбор места)" or "")) end
    row.map:SetScript("OnClick",function() G:OpenHelpTargets(ref.targets) end);row.map:Show()
   end
 end
 local h=math.max(30,row.text:GetStringHeight()+12);row:SetHeight(h);row:Show()
 return y+h+6
end
function G:QuestPresentation(id)
 local state,status=self:QuestState(id)
 if id==8302 then
  local count,target=self:RepeatableProgress(id)
  if state=="done" then return state,status,"[СДАНО "..count.."/"..target.."] ",C.green end
  local log=self.questLog[id]
  local ready=(log and log.complete) or (GetItemCount(20384,false) or 0)>=200
  return state,status,ready and ("[ГОТОВО К СДАЧЕ "..count.."/"..target.."] ") or ("[ПОВТОРЫ "..count.."/"..target.."] "),state=="unknown" and C.gold or C.blue
 end
 if state=="done" or state=="history" then return state,status,"[СДАНО] ",C.green end
 if state=="active" then
  return state,status,status=="Готово к сдаче" and "[ГОТОВО К СДАЧЕ] " or "[В ЖУРНАЛЕ] ",C.blue
 end
 return state,status,"",C.gold
end
function G:PassageEntry(f,y,entry)
 if not entry then return y end
 local qid=entry.quest or (entry.url and tonumber(entry.url:match("quest=(%d+)")))
 if entry.url then
  local detail=qid and self.questHelp[qid]
  y=self:PassageRow(f,y,qid and "Начало задания / Wowhead" or "Источник Wowhead",nil,{"Wowhead",entry.url,targets=detail and detail.startTargets})
 end
  local stepItems=qid and self.questStepItems and self.questStepItems[qid]
  local stepMaps=qid and self.questStepMaps and self.questStepMaps[qid]
  for i,text in ipairs(entry.walkthrough or entry.steps or {}) do
   local storage=stepItems and stepItems[i] and self:ItemStorageLabel(stepItems[i])
   if storage then text=text.."\n|cff40ff40"..storage.."|r" end
   local mapRef=stepMaps and stepMaps[i] and {targets={stepMaps[i]},compactMap=true}
   y=self:PassageRow(f,y,i..". "..text,nil,mapRef)
  end
 for _,text in ipairs({entry.extra or "",entry.serverNote or ""}) do
  if text~="" then y=self:PassageRow(f,y,text) end
 end
  if not (qid and (self.compactQuestReferencesDefault or self.compactQuestReferences and self.compactQuestReferences[qid])) then
   for _,ref in ipairs(self:HelpReferences(entry,false)) do
    if ref[2]~=entry.url then
     if not ref.targets and self.HelpMapTargets then
      ref={ref[1],ref[2],targets=self:HelpMapTargets({stage=entry.stage or 0,title=ref[1],steps={},entityRefs={ref}},false)}
     end
     y=self:PassageRow(f,y,ref[1],nil,ref)
    end
   end
  end
 if entry.source then y=self:PassageRow(f,y,"Особенности сервера: вики Solo Progress",nil,{"Вики",entry.source}) end
 if entry.quest and self.sideQuests and self.sideQuests[entry.quest] then
  local sideKey="side:"..entry.quest
  self.openPassages=self.openPassages or {}
  y=self:PassageRow(f,y,(self.openPassages[sideKey] and "[-] " or "[+] ").."По пути — необязательно",function()
   G.openPassages[sideKey]=not G.openPassages[sideKey];G:Render()
  end)
  if self.openPassages[sideKey] then
   y=self:PassageRow(f,y,"Дополнительные задания для того же похода. Они не требуются для допуска и не входят в счётчик основной цепочки.")
   for _,qid in ipairs(self.sideQuests[entry.quest]) do
    local meta=self.sideQuestMetadata[qid];local detail=self.questHelp[qid]
    if meta and detail then
     local qkey=sideKey..":"..qid
     y=self:PassageRow(f,y,(self.openPassages[qkey] and "[-] " or "[+] ")..meta.title.." — необязательно",function()
      G.openPassages[qkey]=not G.openPassages[qkey];G:Render()
     end)
     if self.openPassages[qkey] then
      y=self:PassageRow(f,y,self:QuestLevelLabel(meta))
      y=self:PassageEntry(f,y,{key=qkey,title=meta.title,stage=entry.stage,url=detail.url,steps=detail.steps,entityRefs=detail.refs})
     end
    end
   end
  end
 end
 if entry.spoiler then
  local key="alternative:"..entry.key
  y=self:PassageRow(f,y,(self.openPassages[key] and "[-] " or "[+] ").."Необязательный обход",function()
   G.openPassages[key]=not G.openPassages[key];G:Render()
  end)
  if self.openPassages[key] then y=self:PassageRow(f,y,entry.spoiler) end
 end
 return y
end
function G:HelpEntryButton(f,y,key,questIDs,chainIDs,visibleText)
 self:BuildHelpIndex();self.openPassages=self.openPassages or {}
 local opened=self.openPassages[key]
 y=self:PassageRow(f,y,(opened and "[-] " or "[+] ").."Прохождение",function()
  G.openPassages[key]=not G.openPassages[key];G:Render()
 end)
 if not opened then return y end
 local entry=self.helpByKey[key]
 if questIDs and #questIDs==1 then entry=self.helpByKey["quest:"..questIDs[1]] or entry end
 if (not chainIDs or #chainIDs==0) and entry then
  local repeated=visibleText and entry.key and entry.key:match("^step:")
   and #((entry.walkthrough or entry.steps) or {})==1
   and (entry.walkthrough or entry.steps)[1]==visibleText
   and not entry.extra and not entry.serverNote and not entry.spoiler
  if not repeated then y=self:PassageEntry(f,y,entry) end
 end
 local seen={};if entry and entry.quest then seen[entry.quest]=true end
 local function quest(qid,title,chain)
  if seen[qid] then return end;seen[qid]=true
  local qentry=G.helpByKey["quest:"..qid]
  if not qentry and G.questHelp[qid] then
   local detail=G.questHelp[qid]
   qentry={key="quest:"..qid,quest=qid,title=title,stage=G.selectedStage or 0,walkthrough=detail.steps,
    steps=detail.steps,url=detail.url,entityRefs=detail.refs,serverNote=detail.serverNote}
  end
 if not qentry then return end
 local qkey=key..(chain and (":chain:"..chain) or "")..":quest:"..qid
  local state,status,prefix,questColor=G:QuestPresentation(qid)
  y=G:PassageRow(f,y,(G.openPassages[qkey] and "[-] " or "[+] ")..prefix..(title or qentry.title),function()
   G.openPassages[qkey]=not G.openPassages[qkey];G:Render()
  end,nil,questColor)
  if G.openPassages[qkey] then y=G:PassageEntry(f,y,qentry) end
 end
 if questIDs and #questIDs==1 and not seen[questIDs[1]] then
  local qid=questIDs[1];seen[qid]=true
  y=self:PassageEntry(f,y,self.helpByKey["quest:"..qid])
 else for _,qid in ipairs(questIDs or {}) do quest(qid) end end
 local groups,order={},{}
 for _,cid in ipairs(chainIDs or {}) do
  local chain=self.chains[cid]
  if chain then
   if not groups[chain.title] then groups[chain.title]={};order[#order+1]=chain.title end
   groups[chain.title][#groups[chain.title]+1]=cid
  end
 end
 for _,title in ipairs(order) do
  local ids=groups[title];local identical=#ids>1
  local first=self.chains[ids[1]]
  for n=2,#ids do
   local other=self.chains[ids[n]]
   if #other.quests~=#first.quests then identical=false end
   for i,q in ipairs(first.quests) do if not other.quests[i] or other.quests[i].id~=q.id then identical=false end end
  end
  y=self:PassageRow(f,y,"Цепочка: "..title)
  for n,cid in ipairs(ids) do
   local chain=self.chains[cid]
   local show=(chain.faction=="Both" and not chain.branch) or identical
   if not show then
    local branchKey=key..":faction:"..cid
    local name=chain.branch or (chain.faction=="Alliance" and "Альянс" or "Орда")
    show=self.openPassages[branchKey]
    y=self:PassageRow(f,y,(show and "[-] " or "[+] ").."Цепочка: "..name,function()
     G.openPassages[branchKey]=not G.openPassages[branchKey];G:Render()
    end)
   end
   if show then
    seen={}
    if chain.quests then
     for i,q in ipairs(chain.quests) do quest(q.id,i..". "..q.title..(q.repeatable and q.id~=8302 and " — повторяемое" or ""),cid) end
    else
     for i,step in ipairs(chain.steps or {}) do y=self:PassageRow(f,y,i..". "..step.title.." — "..step.text,nil,step.url and {step.title,step.url} or nil) end
    end
   end
   if identical then break end
  end
 end
 return y
end
function G:OpenHelp(key)
 self:BuildHelpIndex()
 if key and key:match("^quest:") then
  local id=tonumber(key:match("%d+"))
  for _,e in ipairs(self.helpTopics) do if e.quest==id then key=e.key;break end end
 end
 if not self.helpWindow then self:CreateHelpWindow() end
 self.helpStage=self.selectedStage or self.db.phase or 0
 self.helpSpoiler=false;self.helpPage=1
 self.helpWindow.search:SetText("");self.helpSelected=key and self.helpByKey[key] or nil;self.helpWindow:Show();self:RenderHelp()
end
function G:CreateHelpWindow()
 local f=panel(self.window,15,68,1010,614);self.helpWindow=f
 f:SetFrameStrata("DIALOG");f:SetFrameLevel(self.window:GetFrameLevel()+20);f:EnableMouse(true)
 _G.SoloProgressGuideHelp=f;table.insert(UISpecialFrames,"SoloProgressGuideHelp")
 label(f,18,20,16,820,"Поиск подсказок по прохождению",C.gold)
 button(f,948,10,42,30,"x",function() f:Hide() end)
 label(f,12,20,53,940,"Поиск по всем этапам: гонг, Рексар, урна, не дают задание. Без запроса - выбранный этап.",C.muted)
 local e=CreateFrame("EditBox",nil,f,"InputBoxTemplate");f.search=e
 e:SetPoint("TOPLEFT",f,"TOPLEFT",28,-82);e:SetWidth(810);e:SetHeight(30);e:SetAutoFocus(false)
 e:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",15);e:SetMaxLetters(120)
 e:SetScript("OnTextChanged",function() G.helpPage=1;G.helpSelected=nil;G.helpSpoiler=false;G:RenderHelp() end)
 e:SetScript("OnEscapePressed",function() f:Hide() end)
 button(f,864,82,120,30,"Очистить",function() e:SetText("") end)
 f:SetScript("OnHide",function() e:ClearFocus() end)
 f.count=label(f,12,20,126,300,"",C.muted);f.results={}
 for i=1,6 do
  local b=button(f,18,150+(i-1)*64,290,60,"",function() end)
  b.text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",13);f.results[i]=b
 end
 button(f,20,548,130,30,"< Назад",function() G.helpPage=math.max(1,G.helpPage-1);G:RenderHelp() end)
 button(f,166,548,130,30,"Далее >",function() G.helpPage=G.helpPage+1;G:RenderHelp() end)
 local scroll=CreateFrame("ScrollFrame","SoloProgressGuideHelpScroll",f,"UIPanelScrollFrameTemplate")
 scroll:SetPoint("TOPLEFT",f,"TOPLEFT",330,-126);scroll:SetWidth(644);scroll:SetHeight(454)
 local content=CreateFrame("Frame",nil,scroll);content:SetWidth(644);content:SetHeight(454);scroll:SetScrollChild(content)
 f.content=content;f.scroll=scroll;f.cards={}
 scroll:EnableMouseWheel(true);scroll:SetScript("OnMouseWheel",function(self,d)
  self:SetVerticalScroll(math.max(0,math.min(self:GetVerticalScroll()-d*45,math.max(0,content:GetHeight()-454))))
 end)
end
function G:RenderHelp()
 local f=self.helpWindow;if not f then return end
 local results=self:SearchHelp(f.search:GetText(),self.helpStage)
 self.helpPage=math.max(1,math.min(self.helpPage or 1,math.max(1,math.ceil(#results/6))))
 f.count:SetText("Найдено: "..#results..". Страница "..self.helpPage)
 for i,b in ipairs(f.results) do
  local entry=results[(self.helpPage-1)*6+i]
  if entry then b.text:SetText(entry.title);b:Show();b:SetScript("OnClick",function()
   G.helpSelected=entry;G.helpSpoiler=false;f.scroll:SetVerticalScroll(0);G:RenderHelp()
  end) else b:Hide() end
 end
 for _,c in ipairs(f.cards) do c:Hide() end
 local y,index=0,0
 local function card(title,body)
  index=index+1;local c=f.cards[index]
  if not c then
   c=panel(f.content,0,0,628,100);c.title=label(c,16,14,12,600,"");c.body=label(c,13,14,42,600,"",C.muted)
   c.a=button(c,14,0,190,30,"",function() end);c.b=button(c,218,0,190,30,"",function() end);f.cards[index]=c
  end
  c:ClearAllPoints();c:SetPoint("TOPLEFT",f.content,"TOPLEFT",0,-y);c:Show();c.a:Hide();c.b:Hide();c.body:Show();if c.linkEdit then c.linkEdit:Hide();c.linkEdit:ClearFocus() end;if c.map then c.map:Hide() end;if c.world then c.world:Hide() end;if c.editDraft then c.editDraft:Hide() end
  c.title:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",16);c.title:SetWidth(600);c.body:SetWidth(600)
  c.a:SetWidth(190);c.a.text:SetWidth(174);c.b:SetWidth(190);c.b.text:SetWidth(174)
  color(c.title,C.text);color(c.body,C.muted);c.a:SetHeight(30);c.b:SetHeight(30)
  c.title:SetText(title);c.body:ClearAllPoints();local top=22+c.title:GetStringHeight()
  c.body:SetPoint("TOPLEFT",c,"TOPLEFT",14,-top);c.body:SetText(body)
  c.base=top+c.body:GetStringHeight()+16;c:SetHeight(c.base);y=y+c.base+10;return c
 end
 local function controls(c,left,fn,right,fn2)
  c.a:ClearAllPoints();c.a:SetPoint("TOPLEFT",c,"TOPLEFT",14,-c.base);c.a.text:SetText(left);c.a:SetScript("OnClick",fn);c.a:Show()
  if right then c.b:ClearAllPoints();c.b:SetPoint("TOPLEFT",c,"TOPLEFT",218,-c.base);c.b.text:SetText(right);c.b:SetScript("OnClick",fn2);c.b:Show() end
  c:SetHeight(c.base+42);y=y+42
 end
 local function linkcard(ref)
  local c=card(ref[1],"");local old=c:GetHeight();c.body:Hide()
  local top=22+c.title:GetStringHeight()
  if not c.linkEdit then
   c.linkEdit=CreateFrame("EditBox",nil,c,"InputBoxTemplate")
   c.linkEdit:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",12);color(c.linkEdit,C.text);c.linkEdit:SetAutoFocus(false)
   c.linkEdit:SetScript("OnEscapePressed",function(edit) edit:ClearFocus() end)
   c.linkEdit:SetScript("OnTextChanged",function(edit) if c.linkURL and edit:GetText()~=c.linkURL then edit:SetText(c.linkURL) end end)
  end
  c.linkURL=ref[2];c.linkEdit:ClearAllPoints();c.linkEdit:SetPoint("TOPLEFT",c,"TOPLEFT",20,-top)
  c.linkEdit:SetWidth(356);c.linkEdit:SetHeight(28);c.linkEdit:SetText(ref[2]);c.linkEdit:Show()
  c.a:ClearAllPoints();c.a:SetPoint("TOPLEFT",c,"TOPLEFT",386,-top);c.a:SetWidth(110);c.a.text:SetWidth(100);c.a.text:SetText("Копировать")
  c.a:SetScript("OnClick",function() c.linkEdit:SetFocus();c.linkEdit:HighlightText() end);c.a:Show()
  if ref.targets and #ref.targets>0 then
   c.b:ClearAllPoints();c.b:SetPoint("TOPLEFT",c,"TOPLEFT",506,-top);c.b:SetWidth(108);c.b.text:SetWidth(100);c.b.text:SetText("На карту")
   c.b:SetScript("OnClick",function() G:OpenHelpTargets(ref.targets) end);c.b:Show()
  end
  c:SetHeight(top+40);y=y+c:GetHeight()-old
 end
 local e=self.helpSelected
 if not e then
  card("Выберите вопрос",#results>0 and "Слева - подсказки. Поиск найдёт вопрос на любом этапе." or "Совпадений нет. Попробуйте название задания, предмета или персонажа.")
 else
  card(e.title,e.walkthrough and e.intro or table.concat(e.steps or {},"\n\n"))
  if e.walkthrough then linkcard({"Ссылка на Wowhead",e.url}) end
  if e.extra then card("Версия игры и ограничения",e.extra) end
  local refs=self:HelpReferences(e,self.helpSpoiler)
  if e.source or #refs>0 then
    local c=card("Ссылки и карта","Основная страница задания и все найденные места собраны в двух кнопках.")
   controls(c,e.source and "Вики сервера" or "Wowhead",function() if e.source then G:ShowURLs({e.source}) else G:ShowHelpReferences(refs) end end,
    e.source and #refs>0 and "Wowhead" or nil,function() G:ShowHelpReferences(refs) end)
   local targets=self:HelpMapTargets(e,self.helpSpoiler)
   if #targets>0 then
    if not c.map then c.map=button(c,422,0,190,30,"На карту",function() end) end
    c.map:ClearAllPoints();c.map:SetPoint("TOPLEFT",c,"TOPLEFT",422,-c.base)
    c.map:SetScript("OnClick",function() G:ShowHelpMapTargets(targets) end);c.map:Show()
   end
  end
  if e.walkthrough then
    for i,step in ipairs(e.walkthrough) do card("Шаг "..i,step) end
    if e.serverNote then card("Особенности Solo Progress",e.serverNote) end
  end
  if e.spoiler then
   local c=card("Необязательный обход",self.helpSpoiler and e.spoiler or "Раскройте, чтобы прочитать альтернативный способ прохождения.")
   controls(c,self.helpSpoiler and "Скрыть спойлер" or "Раскрыть спойлер",function() G.helpSpoiler=not G.helpSpoiler;G:RenderHelp() end)
  end
 end
 f.content:SetHeight(math.max(454,y));f.scroll:SetVerticalScroll(math.min(f.scroll:GetVerticalScroll(),math.max(0,y-454)))
end
function G:OpenHelpTargets(targets)
 if #targets==1 then
  if self:PinHelpTarget(targets[1]) then
   if self.referenceWindow then self.referenceWindow:Hide() end
   if self.helpWindow then self.helpWindow:Hide() end
   self.window:Hide()
   return true
  end
 else self:ShowHelpMapTargets(targets) end
end
function G:ShowHelpMapTargets(targets,page)
 if not self.mapWindow then
  local f=panel(self.window,0,0,720,468);self.mapWindow=f
  f:ClearAllPoints();f:SetPoint("CENTER",self.window,"CENTER");f:SetFrameStrata("FULLSCREEN_DIALOG");f:EnableMouse(true)
  _G.SoloProgressGuideMap=f;table.insert(UISpecialFrames,"SoloProgressGuideMap")
  label(f,18,20,18,640,"Поставить метку и включить стрелку",C.gold)
  label(f,12,20,48,670,"TomTom указывает направление, а не дорогу. Координаты из базы могут отличаться на сервере. Место поиска патруля не означает, что персонаж сейчас там.",C.muted)
  button(f,664,12,36,30,"x",function() f:Hide() end)
  f.rows={}
  for i=1,8 do f.rows[i]=button(f,20,100+(i-1)*38,680,34,"",function() end) end
  button(f,20,422,140,30,"< Назад",function() G:ShowHelpMapTargets(f.targets,f.page-1) end)
  button(f,560,422,140,30,"Далее >",function() G:ShowHelpMapTargets(f.targets,f.page+1) end)
  button(f,240,422,240,30,"Убрать метки",function() G:ClearHelpMap() end)
 end
 local f=self.mapWindow;f.targets=targets;f.page=math.max(1,math.min(page or 1,math.max(1,math.ceil(#targets/8))))
 for i,b in ipairs(f.rows) do
  local pt=targets[(f.page-1)*8+i]
  if pt then
   b.text:SetText(pt.name.." - "..pt.zone..string.format(" %.1f, %.1f",pt.x,pt.y)..(pt.patrol and " (поиск)" or ""))
   b:SetScript("OnClick",function() if G:OpenHelpTargets({pt}) then f:Hide() end end);b:Show()
  else b:Hide() end
 end
 f:Show()
end
function G:HelpReferences(entry,spoiler)
 local text=entry.title.." "..table.concat(entry.steps or {}," ")
 if spoiler and entry.spoiler then text=text.." "..entry.spoiler end
 local refs=self:ReferenceLinks(text)
 for _,ref in ipairs(entry.entityRefs or {}) do
  for i=#refs,1,-1 do if refs[i][2]==ref[2] then table.remove(refs,i) end end
  refs[#refs+1]=ref
 end
 if entry.url then
  for i=#refs,1,-1 do if refs[i][2]==entry.url then table.remove(refs,i) end end
  table.insert(refs,1,{"Основная страница Wowhead",entry.url})
 end
 return refs
end
function G:ShowHelpReferences(refs,page)
 if not self.referenceWindow then
  local f=panel(self.window,0,0,760,550);self.referenceWindow=f
  f:ClearAllPoints();f:SetPoint("CENTER",self.window,"CENTER");f:SetFrameStrata("FULLSCREEN_DIALOG");f:EnableMouse(true)
  _G.SoloProgressGuideReferences=f;table.insert(UISpecialFrames,"SoloProgressGuideReferences")
  label(f,18,20,18,570,"Wowhead: ссылки из подсказки",C.gold)
  label(f,12,20,50,710,"«Копировать» выделяет ссылку в строке. Нажмите Ctrl+C для копирования в буфер.",C.muted)
  button(f,704,12,36,30,"x",function() f:Hide() end)
  f.rows={}
  for i=1,8 do
   local row=CreateFrame("Frame",nil,f);f.rows[i]=row
   row:SetPoint("TOPLEFT",f,"TOPLEFT",20,-80-(i-1)*52);row:SetWidth(720);row:SetHeight(48)
   row.text=label(row,12,0,0,710,"",C.muted)
   local edit=CreateFrame("EditBox",nil,row,"InputBoxTemplate");row.edit=edit
   edit:SetPoint("TOPLEFT",row,"TOPLEFT",8,-18);edit:SetWidth(562);edit:SetHeight(27)
   edit:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",12);color(edit,C.text);edit:SetAutoFocus(false)
   edit:SetScript("OnEscapePressed",function() edit:ClearFocus() end)
   edit:SetScript("OnTextChanged",function()
    if row.url and edit:GetText()~=row.url then edit:SetText(row.url) end
   end)
   row.copy=button(row,584,18,136,27,"Копировать",function()
    edit:SetFocus();edit:HighlightText()
   end)
   row.map=button(row,596,18,124,27,"На карту",function() end)
   row:SetScript("OnHide",function() edit:ClearFocus() end)
  end
  f.previous=button(f,20,510,130,30,"< Назад",function() G:ShowHelpReferences(f.refs,f.page-1) end)
  f.next=button(f,610,510,130,30,"Далее >",function() G:ShowHelpReferences(f.refs,f.page+1) end)
  f:SetScript("OnHide",function() for _,row in ipairs(f.rows) do row.edit:ClearFocus() end end)
 end
 local f=self.referenceWindow;f.refs=refs;f.page=math.max(1,math.min(page or 1,math.max(1,math.ceil(#refs/8))))
 for i,b in ipairs(f.rows) do
  local ref=refs[(f.page-1)*8+i]
  b.edit:ClearFocus();b.map:Hide()
  b.edit:SetWidth(562);b.copy:ClearAllPoints();b.copy:SetPoint("TOPLEFT",b,"TOPLEFT",584,-18);b.copy:SetWidth(136)
  if ref and ref.targets and #ref.targets>0 then
   b.edit:SetWidth(442);b.copy:ClearAllPoints();b.copy:SetPoint("TOPLEFT",b,"TOPLEFT",460,-18);b.copy:SetWidth(126)
   b.map:SetScript("OnClick",function() G:OpenHelpTargets(ref.targets) end);b.map:Show()
  end
  if ref then b.url=ref[2];b.text:SetText(ref[1]);b.edit:SetText(b.url);b.edit:HighlightText(0,0);b:Show() else b:Hide() end
 end
 local count=math.min(8,math.max(0,#refs-(f.page-1)*8))
 f:SetHeight(#refs>8 and 550 or 92+count*52)
 if #refs>8 then f.previous:Show();f.next:Show() else f.previous:Hide();f.next:Hide() end
 f:Show()
end
function G:CopyHelpText(text)
 local urls={}
 for url in text:gmatch("https?://[^ \t\r\n]+") do
  url=url:gsub("[%,%.%;%!%)%]]+$","")
  urls[#urls+1]=url
 end
 self:ShowURLs(#urls>0 and urls or {text})
end
function G:QuestURL(id)
 if type(id)~="number" or id<1 or id~=math.floor(id) then return nil end
 if not self.classicQuestIDs then
  self.classicQuestIDs={}
  for phase=0,6 do
   local s=self.stages[phase]
   for _,step in ipairs(s.steps) do
    if step.quest then self.classicQuestIDs[step.quest]=true end
    for _,qid in ipairs(step.quests or {}) do self.classicQuestIDs[qid]=true end
   end
   for _,cid in ipairs(s.chains) do
    for _,q in ipairs(self.chains[cid] and self.chains[cid].quests or {}) do self.classicQuestIDs[q.id]=true end
   end
  end
  for _,rows in pairs(self.resources) do for _,r in ipairs(rows) do self.classicQuestIDs[r[1]]=true end end
 end
 return "https://www.wowhead.com/"..(self.classicQuestIDs[id] and "classic" or "wotlk").."/ru/quest="..id
end
function G:ShowQuestLinks(ids)
 local urls={}
 for _,id in ipairs(type(ids)=="table" and ids or {ids}) do
  local url=self:QuestURL(id);if url then urls[#urls+1]=url end
 end
 if #urls==0 then return end
 self:ShowURLs(urls)
end
function G:ShowURLs(urls)
 if not self.linkWindow then
  local f=panel(self.window,0,0,620,260);f:ClearAllPoints();f:SetPoint("CENTER",self.window,"CENTER")
  f:SetFrameStrata("FULLSCREEN_DIALOG");f:EnableMouse(true)
  _G.SoloProgressGuideLinks=f;table.insert(UISpecialFrames,"SoloProgressGuideLinks")
  label(f,19,20,20,550,"Копирование текста",C.gold)
  label(f,13,20,54,575,"Нажмите Ctrl+C и вставьте текст в нужное окно.\nСсылку можно вставить в адресную строку браузера.",C.text)
  local e=CreateFrame("EditBox",nil,f)
  e:SetPoint("TOPLEFT",f,"TOPLEFT",20,-104);e:SetWidth(580);e:SetHeight(82)
  e:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",13);e:SetMultiLine(true);e:SetAutoFocus(false)
  e:SetScript("OnEscapePressed",function() f:Hide() end)
  f:SetScript("OnHide",function() e:ClearFocus() end)
  label(f,11,20,198,580,"Копирование не отправляет сообщение в чат.\nДля ссылок Wowhead: условия частного сервера могут отличаться.",C.muted)
  button(f,564,12,36,30,"x",function() f:Hide() end)
  f.edit=e;self.linkWindow=f
 end
 self.linkWindow:Show();self.linkWindow.edit:SetText(table.concat(urls,"\n"))
 self.linkWindow.edit:SetFocus();self.linkWindow.edit:HighlightText()
end
function G:ReferenceLinks(text)
 local result,seen={},{}
 local function add(title,url,targets)
  if not seen[url] then seen[url]=true;result[#result+1]={title,url,targets=targets} end
 end
 -- Quest 6822 shares the raid name. Unquoted mentions refer to the raid.
 if text:find("Огненные Недра",1,true) or text:find("Огненных Недр",1,true) or text:find("Огненным Недрам",1,true) then
  add("Рейд: Огненные Недра — подходы к Чёрной горе","https://www.wowhead.com/classic/ru/zone=2717",{
   {name="Подход к Чёрной горе со стороны Тлеющего ущелья",zone="Тлеющее ущелье",zoneEN="Searing Gorge",x=34.8,y=85.3},
   {name="Подход к Чёрной горе со стороны Пылающих степей",zone="Пылающие степи",zoneEN="Burning Steppes",x=29.4,y=38.3},
  })
 end
 for _,r in ipairs(self.referenceCatalog or {}) do
  if text:find(r[1],1,true) then
   local base="https://www.wowhead.com/"..r[3].."/ru/"
   if r[4]=="search" then
    local query=r[2]:gsub("([^A-Za-z0-9%-_%.~])",function(c) return string.format("%%%02X",string.byte(c)) end)
    add("Поиск: "..r[2],base.."search?q="..query)
   else add(r[2],base..r[4].."="..r[5]) end
  end
 end
 for _,chain in pairs(self.chains) do
  for _,q in ipairs(chain.quests or {}) do
   if text:find(q.title,1,true) and (q.id~=6822 or text:find("«"..q.title.."»",1,true)) then add("Задание: "..q.title.." #"..q.id,self:QuestURL(q.id)) end
  end
 end
 for _,rows in pairs(self.resources) do
  for _,r in ipairs(rows) do
   if text:find(r[3],1,true) then add("Предмет: "..r[3],"https://www.wowhead.com/classic/ru/item="..r[2]) end
  end
 end
 table.sort(result,function(a,b) return a[1]<b[1] end)
 return result
end
function G:AddReferenceRows(f,text,top)
 f.references=f.references or {}
 for index,r in ipairs(self:ReferenceLinks(text)) do
  local b=f.references[index]
  if not b then
   b=CreateFrame("Button",nil,f);b:SetWidth(720)
   b.text=label(b,13,0,3,720,"",C.blue);f.references[index]=b
  end
  b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",20,-top)
  b.text:SetText("Wowhead: "..r[1]);local h=math.max(24,b.text:GetStringHeight()+8);b:SetHeight(h)
  local url=r[2];b:SetScript("OnClick",function() G:ShowURLs({url}) end);b:Show()
  top=top+h
 end
 return top
end
function G:CreateLauncher()
 if self.launcher then return end
 local b=CreateFrame("Button","SoloProgressGuideMinimapButton",Minimap)
 SoloProgressGuideLauncher=b -- Compatibility alias for the former floating launcher.
 b:SetWidth(24);b:SetHeight(24)
 -- Keep legacy launcherPosition data, but let the minimap/collector own placement.
 b:SetPoint("TOPRIGHT",Minimap,"TOPLEFT",-4,0)
 b:SetClampedToScreen(true);b:RegisterForClicks("LeftButtonUp")
 b:SetFrameStrata("MEDIUM")
 b:SetNormalTexture(self.icons.guide)
 b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
 b:SetScript("OnClick",function() G:Toggle() end)
 b:SetScript("OnEnter",function(self)
  GameTooltip:SetOwner(self,"ANCHOR_LEFT");GameTooltip:AddLine("Solo Progress Guide",1,0.8,0.4)
  GameTooltip:AddLine("Левый клик: открыть путеводитель",1,1,1)
  GameTooltip:AddLine("Открыть: /spg",0.8,0.85,0.9);GameTooltip:Show()
 end)
 b:SetScript("OnLeave",function() GameTooltip:Hide() end)
 self.launcher=b
end
function G:CreateWindow()
 local savedSize=SoloProgressGuideDB.ui.windowSize
 local windowWidth=type(savedSize)=="table" and tonumber(savedSize[1]) or 1180
 local windowHeight=type(savedSize)=="table" and tonumber(savedSize[2]) or 760
 windowWidth=math.max(1120,math.min(1600,windowWidth or 1180))
 windowHeight=math.max(730,math.min(1000,windowHeight or 760))
 local w=panel(UIParent,0,0,windowWidth,windowHeight);w:ClearAllPoints();w:SetPoint("CENTER")
 w:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=11,right=12,top=12,bottom=11}})
 self.window=w;w:SetFrameStrata("DIALOG");w:SetClampedToScreen(true);w:SetMovable(true);w:SetResizable(true);w:SetMinResize(1120,730);w:SetMaxResize(1600,1000);w:EnableMouse(true)
 w:SetBackdropColor(unpack(C.bg));w:RegisterForDrag("LeftButton")
 w:SetScript("OnDragStart",function(self) self:StartMoving() end)
 w:SetScript("OnHide",function() G:SaveView() end)
 w:SetScript("OnDragStop",function(self)
  self:StopMovingOrSizing();local p,_,rp,x,y=self:GetPoint();SoloProgressGuideDB.ui.position={p,rp,x,y}
 end)
 local pos=SoloProgressGuideDB.ui.position
 if type(pos)=="table" and #pos==4 then w:ClearAllPoints();w:SetPoint(pos[1],UIParent,pos[2],pos[3],pos[4]) end
 _G.SoloProgressGuideWindow=w;table.insert(UISpecialFrames,"SoloProgressGuideWindow")
 icon(w,self.icons.guide,22,22,38)
 label(w,21,72,21,300,"SOLO PROGRESS",C.gold)
 label(w,11,73,48,300,"ВАШ ЖУРНАЛ ПУТЕШЕСТВИЯ",C.muted)
 self.searchButton=button(w,350,22,160,32,"Найти подсказку",function() G:OpenHelp() end)
 self.identity=label(w,13,530,24,420,"",C.muted)
 self.closeButton=button(w,994,18,28,30,"x",function() w:Hide() end)
 local tabs={{"phase","Мой этап"},{"journey","Мой путь"},{"resources","Ресурсы Ан’Киража"},{"chains","Цепочки"}}
 self.tabs={};self.tabOrder=tabs
 for i,data in ipairs(tabs) do
  local page=data[1]
  self.tabs[page]=button(w,232+(i-1)*195,80,183,34,data[2],function() G:Navigate(page) end)
 end
 self.stageHeader=label(w,11,24,94,180,"ЭТАПЫ ПУТЕШЕСТВИЯ",C.muted)
 self.stageButtons={}
 for i=0,18 do
  local id=i
  local b=button(w,20,125+i*29,191,27,"",function() G.selectedStage=id;G:Navigate("journey") end)
  b:SetNormalTexture("Interface\\Buttons\\WHITE8X8");b:SetPushedTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
  b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  b:GetNormalTexture():SetVertexColor(0,0,0,0)
  b.text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",13)
  b.text:ClearAllPoints();b.text:SetPoint("LEFT",b,"LEFT",32,0);b.text:SetWidth(113);b.text:SetJustifyH("LEFT");b.text:SetHeight(27)
  b.number=label(b,11,8,7,23,tostring(i),C.muted)
  b.progress=label(b,10,145,7,42,"",C.muted);b.progress:SetJustifyH("RIGHT");b.progress:SetHeight(23)
  b:SetScript("OnEnter",function(self)
   self:SetBackdropBorderColor(unpack(C.gold));GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
   GameTooltip:AddLine(G.stages[id].title,1,0.82,0);GameTooltip:AddLine("Этап "..id,0.78,0.75,0.67);GameTooltip:Show()
  end)
  b:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(C.line));GameTooltip:Hide() end)
  self.stageButtons[i]=b
 end
 local scroll=CreateFrame("ScrollFrame","SoloProgressGuideScroll",w,"UIPanelScrollFrameTemplate")
 scroll:SetPoint("TOPLEFT",w,"TOPLEFT",232,-128);scroll:SetWidth(766);scroll:SetHeight(554)
 local content=CreateFrame("Frame",nil,scroll);content:SetWidth(766);content:SetHeight(554);scroll:SetScrollChild(content)
 self.scroll=scroll;self.content=content;self.pool={};self.cursor=0
 scroll:EnableMouseWheel(true)
 scroll:SetScript("OnMouseWheel",function(self,delta)
  self:SetVerticalScroll(math.max(0,math.min(self:GetVerticalScroll()-delta*45,math.max(0,G.content:GetHeight()-self:GetHeight()))))
 end)
 self.footer=label(w,11,234,692,766,"",C.muted)
 self.guideVersion=label(w,10,24,703,180,"GUIDE  "..self.version,C.gold)
 local grip=CreateFrame("Button",nil,w)
 grip:SetWidth(20);grip:SetHeight(20);grip:SetPoint("BOTTOMRIGHT",w,"BOTTOMRIGHT",-10,10)
 grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
 grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
 grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
 grip:RegisterForClicks("LeftButtonDown","LeftButtonUp")
 grip:SetScript("OnMouseDown",function(_,mouseButton)
  if mouseButton=="LeftButton" and not InCombatLockdown() then w:StartSizing("BOTTOMRIGHT") end
 end)
 grip:SetScript("OnMouseUp",function()
  w:StopMovingOrSizing()
  SoloProgressGuideDB.ui.windowSize={math.floor(w:GetWidth()+0.5),math.floor(w:GetHeight()+0.5)}
  G:LayoutWindow();G:ApplyScale();G:Render()
 end)
 self.resizeGrip=grip
 w:SetScript("OnSizeChanged",function() G:LayoutWindow() end)
 self:LayoutWindow();self:ApplyScale()
 local page,scrollY,restored=self:RestoreView()
 if not restored and page=="journey" then self.focusCurrentJourney=true end
 self.restoringView=true
 self:Navigate(page)
 self.restoringView=nil
 if restored then
  self.scroll:SetVerticalScroll(math.max(0,math.min(scrollY or 0,math.max(0,self.content:GetHeight()-(self.viewportHeight or 554)))))
 end
 self:SaveView()
end
function G:SaveView()
 if not self.db then return end
 local view=type(self.db.lastView)=="table" and self.db.lastView or {}
 self.db.lastView=view
 view.page=(self.page=="phase" or self.page=="journey" or self.page=="resources" or self.page=="chains") and self.page or "journey"
 view.stage=tonumber(self.selectedStage)
 view.chain=self.selectedChain and tonumber(self.selectedChain) or nil
 view.chainStage=tonumber(self.chainStage)
 view.aqPathChoiceReview=self.aqPathChoiceReview and true or nil
 view.aqPathPreview=tonumber(self.aqPathPreview)
 view.showCompleted=self.showCompleted and true or nil
 view.completedAll=self.completedAll and true or nil
 view.completedStage=tonumber(self.completedStage)
 view.completedPage=tonumber(self.completedPage)
 if self.scroll then view.scroll=math.max(0,math.floor((self.scroll:GetVerticalScroll() or 0)+0.5)) end
 view.savedAt=time()
end
function G:RestoreView()
 local view=self.db and self.db.lastView
 if type(view)~="table" then
  self.page=self.db and self.db.phase~=nil and "journey" or "phase"
  self.selectedStage=nil;self.selectedChain=nil;self.chainStage=nil
  self.showCompleted=nil;self.completedAll=nil;self.completedStage=nil;self.completedPage=1
  return self.page,0,false
 end
 local page=view.page
 if page~="phase" and page~="journey" and page~="resources" and page~="chains" then page="journey" end
 local stage=tonumber(view.stage)
 self.selectedStage=stage and stage>=0 and stage<=18 and stage%1==0 and stage or nil
 local chain=tonumber(view.chain)
 self.selectedChain=chain and self.chains[chain] and chain or nil
 local chainStage=tonumber(view.chainStage)
 self.chainStage=chainStage and chainStage>=0 and chainStage<=18 and chainStage%1==0 and chainStage or nil
 self.aqPathChoiceReview=view.aqPathChoiceReview and true or nil
 local preview=tonumber(view.aqPathPreview)
 self.aqPathPreview=(preview==10 or preview==11) and preview or nil
 self.showCompleted=view.showCompleted and true or nil
 self.completedAll=view.completedAll and true or nil
 local completedStage=tonumber(view.completedStage)
 self.completedStage=completedStage and completedStage>=0 and completedStage<=18 and completedStage%1==0 and completedStage or nil
 self.completedPage=math.max(1,math.floor(tonumber(view.completedPage) or 1))
 self.page=page
 return page,math.max(0,tonumber(view.scroll) or 0),true
end
function G:Navigate(page)
 if not self.restoringView then self:SaveView() end
 self.page=page
 if page=="journey" then
  self.showCompleted=nil
  if not self.restoringView then
   self.aqPathChoiceReview=nil
   self.aqPathPreview=nil
  end
  local id=self.selectedStage or (self.db and self.db.phase) or 0
  if not self.restoringView then self.focusCurrentJourney=true end
  if id==3 and not self.restoringView then
   self.aqPathChoiceReview=true;self.selectedChain=nil;self.chainStage=nil
   self.focusCurrentJourney=nil;self.focusChosenPath=nil;self.pendingScrollY=nil
  end
 elseif not self.restoringView then
  self.aqPathChoiceReview=nil
  self.aqPathPreview=nil
 end
 if self.scroll then self.scroll:SetVerticalScroll(0) end
 self:Changed()
 if self.window then self:Render() end
 if not self.restoringView then self:SaveView() end
end
function G:Toggle()
 if not self.window then self:CreateWindow()
 elseif self.window:IsShown() then self.window:Hide();return else self.window:Show() end
 self:ScanLog();self:Render()
end
function G:NewCard(x,y,width,height)
 if width==766 and self.contentWidth then width=self.contentWidth end
 self.cursor=self.cursor+1
 local f=self.pool[self.cursor]
 if not f then
  f=panel(self.content,0,0,width,height)
  f.title=label(f,17,18,18,width-36,"")
  f.body=label(f,13,18,49,width-36,"",C.muted)
  f.badge=label(f,11,18,8,width-36,"",C.gold)
  f.pic=icon(f,self.icons.guide,18,18,42)
  f.bar=f:CreateTexture(nil,"ARTWORK");f.bar:SetTexture("Interface\\Buttons\\WHITE8X8")
  f.art=f:CreateTexture(nil,"BACKGROUND");f.art:SetAllPoints(f)
  f.action=button(f,18,80,220,32,"",function() end)
  f.action2=button(f,250,80,220,32,"",function() end)
  f.disclosure=CreateFrame("Button",nil,f)
  f.disclosure:SetWidth(620);f.disclosure:SetHeight(30)
  f.disclosure.text=label(f.disclosure,15,0,5,620,"",C.gold)
  f.detail=label(f,14,76,0,660,"",C.muted)
  self.pool[self.cursor]=f
 end
 f:ClearAllPoints();f:SetPoint("TOPLEFT",self.content,"TOPLEFT",x,-y);f:SetWidth(width);f:SetHeight(height)
 f:SetBackdropColor(unpack(C.panel));f:SetBackdropBorderColor(unpack(C.line));f:Show()
 for _,t in ipairs({f.title,f.body,f.badge}) do t:Show();t:SetText("");t:SetWidth(width-36) end
 f.title:ClearAllPoints();f.title:SetPoint("TOPLEFT",f,"TOPLEFT",18,-18);f.title:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",17);color(f.title,C.text)
 f.body:ClearAllPoints();f.body:SetPoint("TOPLEFT",f,"TOPLEFT",18,-49);color(f.body,C.muted)
 f.badge:ClearAllPoints();f.badge:SetPoint("TOPLEFT",f,"TOPLEFT",18,-8);color(f.badge,C.gold)
 f.pic:ClearAllPoints();f.pic:SetPoint("TOPLEFT",f,"TOPLEFT",18,-18);f.pic:SetWidth(42);f.pic:SetHeight(42)
 f.disclosure:Hide();f.detail:Hide()
 if f.rewardScepter then f.rewardScepter:Hide() end
 if f.rewardScepterLabel then f.rewardScepterLabel:Hide() end
 if f.rewardTitleIcon then f.rewardTitleIcon:Hide() end
 if f.rewardTitleLabel then f.rewardTitleLabel:Hide() end
 if f.rewardMountPanel then f.rewardMountPanel:Hide() end
 if f.resourceMap then f.resourceMap:Hide() end
 if f.resourcePin then f.resourcePin:Hide() end
 if f.colossusImage then f.colossusImage:Hide() end
 f.passageUsed=0;for _,row in ipairs(f.passageRows or {}) do row:Hide() end
 for _,b in ipairs(f.references or {}) do b:Hide() end
 f.pic:Hide();f.bar:Hide();f.art:Hide();f.action:Hide();f.action2:Hide();if f.secureTarget then f.secureTarget:Hide() end
 f.action:SetBackdropColor(0.095,0.12,0.155,1);f.action:SetBackdropBorderColor(unpack(C.line))
 f:SetScript("OnEnter",nil);f:SetScript("OnLeave",nil);f:EnableMouse(false)
 return f
end
function G:EnsurePlayerTargetButton(f)
 if f.secureTarget then return f.secureTarget end
 if InCombatLockdown() then return nil end
 local b=CreateFrame("Button",nil,f,"SecureActionButtonTemplate,UIPanelButtonTemplate")
 b:SetWidth(220);b:SetHeight(32);b:SetBackdrop(nil)
 b:SetBackdropColor(0.095,0.12,0.155,1);b:SetBackdropBorderColor(unpack(C.line))
 b.text=label(b,15,0,0,200,"1. Выбрать себя",C.gold)
 b.text:ClearAllPoints();b.text:SetPoint("CENTER",b,"CENTER",0,0);b.text:SetJustifyH("CENTER");b.text:SetJustifyV("MIDDLE")
 b:RegisterForClicks("LeftButtonUp");b:SetAttribute("type","target");b:SetAttribute("unit","player")
 b:SetScript("PostClick",function()
  if UnitExists("target") and UnitIsUnit("target","player") then G.ipStatus="Вы выбраны целью. Теперь нажмите «2. Запросить этап»." end
  G:Changed();G:Render()
 end)
 b:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(C.gold)) end)
 b:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(C.line));GameTooltip:Hide() end)
 f.secureTarget=b;return b
end
local function action(f,text,fn,x,y,w,second)
 local b=second and f.action2 or f.action;b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",x or 18,-y)
 b:SetWidth(w or 220);b.text:SetWidth((w or 220)-20);b.text:SetText(text);b:SetScript("OnClick",fn);b:Show()
end
function G:Paragraph(y,title,text,accent)
 local f=self:NewCard(0,y,766,100)
 f.title:SetText(title);if accent then color(f.title,accent) end
 f.body:SetText(text)
 local h=math.max(94,64+f.body:GetStringHeight());f:SetHeight(h)
 return y+h+12,f
end
function G:ScepterRewardCard(y)
 local f=self:NewCard(0,y,766,218)
 f.title:SetText("НАГРАДЫ ВЕТКИ А — СКИПЕТР")
 f.title:SetWidth(430);color(f.title,C.green)
 f.body:Hide();f.badge:Hide();f.pic:Hide()
 if not f.rewardScepter then
  f.rewardScepter=CreateFrame("Button",nil,f)
  f.rewardScepter:SetWidth(58);f.rewardScepter:SetHeight(58)
  f.rewardScepter.texture=icon(f.rewardScepter,GetItemIcon(21175) or "Interface\\Icons\\INV_Hammer_25",0,0,58)
  f.rewardScepter:SetScript("OnEnter",function(self)
   GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetHyperlink("item:21175");GameTooltip:Show()
  end)
  f.rewardScepter:SetScript("OnLeave",function() GameTooltip:Hide() end)
  f.rewardScepterLabel=label(f,14,0,0,350,"",C.text)
  f.rewardTitleIcon=icon(f,"Interface\\Icons\\Achievement_Zone_Silithus_01",0,0,58)
  f.rewardTitleLabel=label(f,14,0,0,350,"",C.text)
  f.rewardMountPanel=panel(f,0,0,290,164)
  f.rewardMountPanel:SetBackdropColor(0.025,0.022,0.018,1)
  f.rewardMountModel=CreateFrame("PlayerModel",nil,f.rewardMountPanel)
  f.rewardMountModel:SetAllPoints(f.rewardMountPanel)
  f.rewardMountModel:SetCreature(15711)
  f.rewardMountModel:SetModelScale(0.8);f.rewardMountModel:SetFacing(0.65);f.rewardMountModel:SetSequence(0)
  f.rewardMountScreenshot=f.rewardMountPanel:CreateTexture(nil,"ARTWORK")
  f.rewardMountScreenshot:SetTexture("Interface\\AddOns\\SoloProgressGuide\\Media\\BlackQirajiBattleTank")
  f.rewardMountScreenshot:SetWidth(146);f.rewardMountScreenshot:SetHeight(146)
  f.rewardMountScreenshot:SetPoint("TOPRIGHT",f.rewardMountPanel,"TOPRIGHT",-8,-8)
  f.rewardMountIcon=CreateFrame("Button",nil,f.rewardMountPanel)
  f.rewardMountIcon:SetWidth(46);f.rewardMountIcon:SetHeight(46);f.rewardMountIcon:SetPoint("TOPLEFT",f.rewardMountPanel,"TOPLEFT",8,-8)
  f.rewardMountIcon.texture=icon(f.rewardMountIcon,GetItemIcon(21176) or "Interface\\Icons\\INV_Misc_QirajiCrystal_05",0,0,46)
  f.rewardMountIcon:SetScript("OnEnter",function(self)
   GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetHyperlink("item:21176");GameTooltip:Show()
  end)
  f.rewardMountIcon:SetScript("OnLeave",function() GameTooltip:Hide() end)
  f.rewardMountLabel=label(f.rewardMountPanel,13,8,63,120,"Чёрный киражский боевой танк",C.gold)
  f.rewardMountLabel:SetJustifyH("CENTER")
 end
 local cardWidth=f:GetWidth()
 f.rewardScepter:ClearAllPoints();f.rewardScepter:SetPoint("TOPLEFT",f,"TOPLEFT",22,-58);f.rewardScepter:Show()
 f.rewardScepterLabel:ClearAllPoints();f.rewardScepterLabel:SetPoint("TOPLEFT",f,"TOPLEFT",94,-62)
 f.rewardScepterLabel:SetWidth(math.max(260,cardWidth-430));f.rewardScepterLabel:SetText("Скипетр Зыбучих песков\nПредмет для удара в гонг Скарабея");f.rewardScepterLabel:Show()
 f.rewardTitleIcon:ClearAllPoints();f.rewardTitleIcon:SetPoint("TOPLEFT",f,"TOPLEFT",22,-132);f.rewardTitleIcon:Show()
 f.rewardTitleLabel:ClearAllPoints();f.rewardTitleLabel:SetPoint("TOPLEFT",f,"TOPLEFT",94,-136)
 f.rewardTitleLabel:SetWidth(math.max(260,cardWidth-430));f.rewardTitleLabel:SetText("Звание\n«Повелитель скарабеев» / «Повелительница скарабеев»");f.rewardTitleLabel:Show()
 f.rewardMountPanel:ClearAllPoints();f.rewardMountPanel:SetPoint("TOPRIGHT",f,"TOPRIGHT",-20,-35);f.rewardMountPanel:Show()
 f.rewardMountModel:Hide();f.rewardMountScreenshot:Show();f.rewardMountIcon:Show();f.rewardMountLabel:Show()
 return y+230,f
end
function G:Hero(y,kicker,title,body,chapter)
 local f=self:NewCard(0,y,766,126)
 f.pic:SetTexture(self.icons[chapter==2 and "tbc" or chapter==3 and "wrath" or "classic"]);f.pic:Show()
 f.pic:ClearAllPoints();f.pic:SetPoint("TOPRIGHT",f,"TOPRIGHT",-24,-25);f.pic:SetWidth(54);f.pic:SetHeight(54)
 f.badge:SetText(kicker);f.badge:ClearAllPoints();f.badge:SetPoint("TOPLEFT",f,"TOPLEFT",24,-20)
 f.title:SetText(title);f.title:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",24);f.title:ClearAllPoints();f.title:SetPoint("TOPLEFT",f,"TOPLEFT",24,-48);f.title:SetWidth(640)
 f.body:SetText(body);f.body:ClearAllPoints();f.body:SetPoint("TOPLEFT",f,"TOPLEFT",24,-84);f.body:SetWidth(550);color(f.body,C.text)
 return y+138
end
function G:RenderSpoiler(y,key,parent)
 local entry=self.spoilers[key]
 if not entry then return y end
 self.openSpoilers=self.openSpoilers or {}
 local opened=self.openSpoilers[key]
 local f=parent or self:NewCard(0,y,766,58)
 local top=parent and y or 12
 f.disclosure:ClearAllPoints();f.disclosure:SetPoint("TOPLEFT",f,"TOPLEFT",76,-top)
 f.disclosure.text:SetText((opened and "[-] " or "[+] ").."Спойлер: боты - "..entry.title)
 f.disclosure:SetScript("OnClick",function()
  G.openSpoilers[key]=not G.openSpoilers[key];G:Changed();G:Render()
 end);f.disclosure:Show()
 local headerHeight=math.max(30,f.disclosure.text:GetStringHeight()+10)
 f.disclosure:SetHeight(headerHeight)
 local bottom=top+headerHeight+6
 if opened then
  f.detail:ClearAllPoints();f.detail:SetPoint("TOPLEFT",f,"TOPLEFT",76,-bottom)
  f.detail:SetText(entry.text.."\n\n"..self.botInstructions.."\n\nИсточник: руководство Solo Progress, раздел Los. Необязательный обход механики.")
  f.detail:Show();bottom=bottom+f.detail:GetStringHeight()+16
 end
 if parent then return bottom end
 f:SetHeight(bottom+12);return y+f:GetHeight()+12
end
function G:StageThreeAttunements(y)
 local zg=self:NewCard(0,y,766,130)
 zg.title:SetText("Зул’Гуруб — независимый допуск")
 zg.body:SetText("Восемь заданий для входа в рейд. Ресурсы, гонг и выбор ветки Ан’Киража не нужны. Зул’Гуруб необязателен для перехода дальше.")
 local bottom=math.max(82,60+zg.body:GetStringHeight())
 action(zg,"Открыть допуск в Зул’Гуруб",function()
  G.selectedChain=12;G.chainStage=3;G.aqPathChoiceReview=nil;G.aqPathPreview=nil
  G.scroll:SetVerticalScroll(0);G:Render()
 end,18,bottom,300)
 zg:SetHeight(bottom+44);y=y+zg:GetHeight()+12
 local aq=self:NewCard(0,y,766,200)
 aq.title:SetText("Ан’Кираж — два варианта допуска")
 local chosen=self.db.pathChoice=="scepter" and "Ветка А — Скипетр" or self.db.pathChoice=="mallet" and "Ветка Б — Молот" or "ещё не выбран"
 aq.body:SetText("Общая подготовка: 15 ресурсных заданий и «Военные действия».\nВетка А — Скипетр: 30 обязательных + 1 рекомендуемое задание; танк и звание.\nВетка Б — Молот: "..#self.chains[11].steps.." предметных шага, без наград Скипетра.\nДля гонга нужен один вариант. Ваш выбор: "..chosen..".")
 bottom=math.max(136,60+aq.body:GetStringHeight())
 local width=(aq:GetWidth()-54)/2
 action(aq,"Ветка А — Скипетр",function()
  G.selectedChain=10;G.chainStage=3;G.aqPathPreview=10;G.scroll:SetVerticalScroll(0);G:Render()
 end,18,bottom,width)
 action(aq,"Ветка Б — Молот",function()
  G.selectedChain=11;G.chainStage=3;G.aqPathPreview=11;G.scroll:SetVerticalScroll(0);G:Render()
 end,36+width,bottom,width,true)
 aq:SetHeight(bottom+44)
 return y+aq:GetHeight()+12
end
function G:RenderJourney()
 local phase=self.db.phase
 local id=self.selectedStage or phase or self:HistoryHint() or 0
 local stage=self.stages[id]
 if id==3 then
  if self.selectedChain==12 and self.chainStage==3 and not self.aqPathChoiceReview then return self:RenderChains() end
  local chosen=self.db.pathChoice=="scepter" and 10 or self.db.pathChoice=="mallet" and 11
  local chainId=self.aqPathPreview or (not self.aqPathChoiceReview and chosen)
  if chainId then
   self.selectedChain=chainId;self.chainStage=3
   return self:RenderChains()
  end
 end
 local y=self:Hero(0,self.chapterNames[stage.chapter].."  /  ЭТАП "..id,stage.title,stage.goal,stage.chapter)
 if id==3 then y=self:StageThreeAttunements(y) end
 local focusStepIndex
 if self.focusCurrentJourney and id~=3 then
  for i,step in ipairs(stage.steps) do
   local state=self:StepState(step,id..":"..i)
   if state~="done" and state~="manual" and state~="info" then focusStepIndex=i;break end
  end
  if not focusStepIndex then focusStepIndex=math.max(1,#stage.steps) end
 end
 if phase==nil then
  local hint,why=self:HistoryHint()
  local text=hint and ("История подсказывает этап "..hint.." или выше: "..why..". Это не текущая фаза: она могла быть понижена. Откройте «Мой этап» для сверки.") or "Вы уже играли раньше? Откройте «Мой этап»: проверим сервер и историю. Начинать маршрут с нуля не требуется."
  y=self:Paragraph(y,"Сначала определим ваше положение",text,C.gold)
 elseif self.realmMode~="Solo" and phase>id then
  y=self:Paragraph(y,"Эта часть пути уже позади", "По выбранному этапу "..phase.." этот контент уже открыт. Ниже показана отдельная история заданий; необязательные цепочки не отмечаются выполненными автоматически.",C.green)
 elseif self.realmMode~="Solo" and phase<id then
  y=self:Paragraph(y,"Впереди по маршруту","Сейчас указан этап "..phase..". Здесь можно заранее посмотреть подготовку; доступность проверяется на сервере.")
 else
  local nextStep
  for i,step in ipairs(stage.steps) do local state=self:StepState(step,id..":"..i);if state~="done" and state~="manual" and state~="info" then nextStep=step[1];break end end
  y=self:Paragraph(y,"СЕЙЧАС - "..(nextStep or "Проверьте переход"),"После завершения ключевого условия нажмите «Мой этап» и запросите фазу. Прошлые достижения не меняют текущий этап без ответа сервера.",C.gold)
 end
 if id==3 then y=self:Paragraph(y,"АН’КИРАЖ — ВАШЕ ПОЛОЖЕНИЕ",self:AQCurrentAction(),C.gold) end
 for i,step in ipairs(stage.steps) do
   local key=id..":"..i
   local state,status=self:StepState(step,key)
   if focusStepIndex==i then self.pendingScrollY=y end
   local f=self:NewCard(0,y,766,130)
  f.pic:SetTexture(step.resource and self.icons.resources or step.achievement and stage.icon or self.icons.quest);f.pic:Show()
  f.title:ClearAllPoints();f.title:SetPoint("TOPLEFT",f,"TOPLEFT",76,-16);f.title:SetWidth(665);f.title:SetText((step.informational and "" or i..". ")..step[1])
  f.body:ClearAllPoints();f.body:SetPoint("TOPLEFT",f,"TOPLEFT",76,-48);f.body:SetWidth(664);f.body:SetText(step[2])
  local bottom=math.max(92,60+f.body:GetStringHeight())
  f.badge:ClearAllPoints();f.badge:SetPoint("TOPLEFT",f,"TOPLEFT",76,-bottom);f.badge:SetText(status)
  color(f.badge,state=="done" and C.green or state=="manual" and C.blue or C.gold)
  if step.special=="scepterPath" then
   action(f,"Изучить ветку А — 30 обязательных + 1 рекомендуемое",function() G.selectedChain=10;G.chainStage=3;G.aqPathPreview=10;G.scroll:SetVerticalScroll(0);G:Render() end,76,bottom+22,320)
   bottom=bottom+50
  elseif step.special=="malletPath" then
   action(f,"Изучить ветку Б — "..#self.chains[11].steps.." шага",function() G.selectedChain=11;G.chainStage=3;G.aqPathPreview=11;G.scroll:SetVerticalScroll(0);G:Render() end,76,bottom+22,320,true)
   bottom=bottom+50
  elseif step.resource then action(f,"Открыть ресурсы",function() G:Navigate("resources") end,520,bottom-9,224)
  elseif step.quest or step.quests then
   action(f,"Wowhead",function() G:ShowQuestLinks(step.quest or step.quests) end,520,bottom-9,224)
  elseif state~="done" and state~="info" and not step.quest and not step.quests then
   action(f,state=="manual" and "Снять свою отметку" or "Отметить вручную",function() G:ToggleManual(key) end,520,bottom-9,224)
  end
  bottom=bottom+38
  if step.mapTargets then
   action(f,"Районы колоссов на карте",function() G:OpenHelpTargets(step.mapTargets) end,76,bottom,260,true)
   bottom=bottom+42
  end
  if step.chain and step.special~="scepterPath" and step.special~="malletPath" then
   local chainId=step.chain
   action(f,"Цепочка заданий",function() G.selectedChain=chainId;G:Navigate("chains") end,76,bottom,220,true)
   bottom=bottom+42
  end
  local spoiler=step.spoiler or (i==1 and self.stageSpoilers and self.stageSpoilers[id])
  if spoiler then bottom=self:RenderSpoiler(bottom,spoiler,f) end
  if step.quest or step.quests or step.chain or step.chains or G.helpStepKeys[key] then
   bottom=self:HelpEntryButton(f,bottom,G.helpStepKeys[key] or ("step:"..key),step.quest and {step.quest} or step.quests,step.chains or (step.chain and {step.chain}),step[2])
  end
  f:SetHeight(bottom+8);y=y+f:GetHeight()+12
  if step.illustration then
   local example=self:NewCard(0,y,766,486)
   example.title:SetText("ПРИМЕР УКРЫТИЯ ОТ КОЛОССАЛЬНОГО УДАРА")
   example.body:SetText("Синий круг — место игрока. Встаньте спиной под выступающее щупальце улья; колосс должен быть перед вами.")
   if not example.colossusImage then example.colossusImage=example:CreateTexture(nil,"ARTWORK") end
   example.colossusImage:SetTexture(step.illustration)
   example.colossusImage:ClearAllPoints();example.colossusImage:SetPoint("TOP",example,"TOP",0,-90)
   example.colossusImage:SetWidth(620);example.colossusImage:SetHeight(380)
   example.colossusImage:SetTexCoord(0,1,198/1024,825/1024);example.colossusImage:Show()
   y=y+example:GetHeight()+12
  end
 end
 local shownChains={}
 for _,step in ipairs(stage.steps) do
  if step.chain then shownChains[step.chain]=true end
  for _,cid in ipairs(step.chains or {}) do shownChains[cid]=true end
  if step.quest or step.quests then
   local selected={}
   local questIDs=step.quests or {step.quest}
   for _,qid in ipairs(questIDs) do selected[qid]=true end
   for _,cid in ipairs(stage.chains or {}) do
    local chain=self.chains[cid]
    if chain and chain.quests and #chain.quests==#questIDs then
     local same=true
     for _,q in ipairs(chain.quests) do if not selected[q.id] then same=false;break end end
     if same then shownChains[cid]=true end
    end
   end
  end
 end
 local remainingChains={}
 for _,cid in ipairs(stage.chains or {}) do if not shownChains[cid] then remainingChains[#remainingChains+1]=cid end end
 if id~=3 and #remainingChains>0 then
  local f=self:NewCard(0,y,766,83);f.title:SetText("Связанные цепочки этапа")
  f.body:SetText("Раскройте нужную цепочку, чтобы увидеть задания, шаги и источники.")
  local bottom=self:HelpEntryButton(f,82,"stagechains:"..id,nil,remainingChains)
  f:SetHeight(bottom+8);y=y+f:GetHeight()+12
 end
 if id~=3 and stage.note and stage.note~="" then y=self:Paragraph(y,"Полезно знать",stage.note) end
 self:BuildHelpIndex()
 self.openGuideNotes=self.openGuideNotes or {}
 for index,entry in ipairs(self.guideNotes and self.guideNotes[id] or {}) do
  local key=id..":"..index
  local opened=self.openGuideNotes[key]
  local f=self:NewCard(0,y,766,58)
  f.disclosure:ClearAllPoints();f.disclosure:SetPoint("TOPLEFT",f,"TOPLEFT",18,-12)
  f.disclosure.text:SetText((opened and "[-] " or "[+] ")..entry[1])
  f.disclosure:SetScript("OnClick",function()
   G.openGuideNotes[key]=not G.openGuideNotes[key];G:Changed();G:Render()
  end);f.disclosure:Show()
  local headerHeight=math.max(30,f.disclosure.text:GetStringHeight()+10)
  f.disclosure:SetHeight(headerHeight);f:SetHeight(headerHeight+24)
  if opened then
   f.body:ClearAllPoints();f.body:SetPoint("TOPLEFT",f,"TOPLEFT",20,-(headerHeight+24));f.body:SetWidth(726)
   f.body:SetText(entry[2].."\n\nИсточник: руководство этапов Solo Progress и ответы на частые вопросы сервера. Описанные ошибки могут зависеть от версии сервера.")
   f:SetHeight(headerHeight+42+f.body:GetStringHeight())
   local help=self.helpByKey["note:"..key]
   if help and help.source then
    action(f,"Источник",function() G:ShowURLs({help.source}) end,20,f:GetHeight(),180)
    f:SetHeight(f:GetHeight()+42)
   end
   f:SetHeight(self:AddReferenceRows(f,entry[1].." "..entry[2],f:GetHeight())+12)
  end
  y=y+f:GetHeight()+12
 end
 return y
end
function G:RenderResources()
 local faction=self.db.faction
 local location=faction=="Horde" and "Оргриммар - Аллея Духов" or "Стальгорн - Палаты Войны"
 local done,total=self:ResourceProgress()
 local y=self:Hero(0,"АН’КИРАЖ  /  ПОДГОТОВКА","Снабжение армии",location.."   |   Сдано заданий: "..done.." / "..total,1)
 if self.db.phase and self.db.phase>=4 then
  y=self:Paragraph(y,"Врата уже открыты по вашему этапу","Повторно сдавать ресурсы для продвижения не требуется. Список ниже показывает только известную историю, а не новые обязательства.",C.green)
 end
 y=self:Paragraph(y,"Каждый вид — одно отдельное задание","Числа со знаком ~ взяты из базовой версии задания. Когда вы возьмёте квест, используем его фактическое требование. Считаются только предметы при себе; банк и хранилище Ling сюда не входят.")
 for group=1,5 do
  local f=self:NewCard(0,y,766,30);f:SetBackdropColor(unpack(C.bg));f.title:SetText(self.resourceGroups[group]);f.title:ClearAllPoints();f.title:SetPoint("TOPLEFT",f,"TOPLEFT",0,-4);f.title:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",15);color(f.title,C.gold)
  y=y+36
  local col=0
  for _,r in ipairs(self.resources[faction] or {}) do
   if r[5]==group then
    local row=r
    local state,status,bags,needed,verified=self:ResourceState(row)
    local isFood=group==2
    local card=self:NewCard(col*258,y,250,isFood and 338 or 157)
    local itemName,_,_,_,_,_,_,_,_,texture=GetItemInfo(row[2])
    card.pic:SetTexture((GetItemIcon and GetItemIcon(row[2])) or texture or self.icons.unknown);card.pic:Show()
    card.title:ClearAllPoints();card.title:SetPoint("TOPLEFT",card,"TOPLEFT",72,-15);card.title:SetWidth(163);card.title:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",13);card.title:SetText(itemName or row[3])
    card.body:ClearAllPoints();card.body:SetPoint("TOPLEFT",card,"TOPLEFT",18,-68);card.body:SetText("При себе: "..bags.." / "..(verified and "" or "~")..needed)
    card.badge:ClearAllPoints();card.badge:SetPoint("TOPLEFT",card,"TOPLEFT",18,-96);card.badge:SetText(status);color(card.badge,state=="done" and C.green or C.gold)
    if state=="done" then card:SetBackdropBorderColor(unpack(C.green)) end
    local food=isFood and self.resourceFood[row[2]]
    local fishTarget
    if food then
     local source=food.recipeSource[faction] or food.recipeSource.Both or "Источник не указан"
     local farm=food.farm[faction] or food.farm.Both or ""
     fishTarget=food.fishing and (food.fishing[faction] or food.fishing.Both)
     card.detail:ClearAllPoints();card.detail:SetPoint("TOPLEFT",card,"TOPLEFT",18,-118);card.detail:SetWidth(214)
     card.detail:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",11);color(card.detail,C.muted)
     card.detail:SetText(food.recipeName.." #"..food.recipe.."\nИсточник: "..source.."\nСырьё: "..food.material.."\n"..farm);card.detail:Show()
     if fishTarget then
      if not card.resourceMap then
       card.resourceMap=button(card,18,258,102,30,"Карта",function() end)
       card.resourcePin=button(card,130,258,102,30,"Метка",function() end)
      end
      local target=fishTarget
      card.resourceMap:SetScript("OnClick",function() G:ShowMapTarget(target) end);card.resourceMap:Show()
      card.resourcePin:SetScript("OnClick",function() G:PinHelpTarget(target) end);card.resourcePin:Show()
     end
    end
    action(card,"Wowhead #"..row[1],function() G:ShowQuestLinks(row[1]) end,18,isFood and 296 or 118,214)
    card:EnableMouse(true)
    card:SetScript("OnEnter",function(self)
     GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
     local ok=pcall(GameTooltip.SetHyperlink,GameTooltip,"item:"..row[2])
     if not ok then GameTooltip:AddLine(row[3],1,0.8,0.4) end
     GameTooltip:AddLine("Задание #"..row[1],0.7,0.75,0.8)
     GameTooltip:AddLine(location,1,1,1)
     local log=G.questLog[row[1]]
     if log then for _,o in ipairs(log.objectives) do GameTooltip:AddLine(o.text,0.8,0.9,0.8,true) end end
     GameTooltip:AddLine("Собрано и сдано — разные состояния.",0.7,0.75,0.8,true);GameTooltip:Show()
    end)
    card:SetScript("OnLeave",function() GameTooltip:Hide() end)
    col=col+1
   end
  end
  y=y+(group==2 and 352 or 171)
 end
 y=self:Paragraph(y,"После 15 заданий — «Военные действия»","Обратитесь к главнокомандующему в центре места сдачи и передайте 100 наградных печатей. Затем выберите путь Скипетра или Молота. Молот не пропускает ресурсную подготовку.",C.gold)
 return y
end
function G:RenderCompletedQuests()
 local stageId=self.completedAll and nil or (self.completedStage or self.selectedStage or self.db.phase or 0)
 if self.completedAll then stageId=nil end
 local catalog=self:ProgressQuestCatalog(stageId)
 local ids={}
 for id in pairs(self.completedNow or {}) do if catalog[id] then ids[#ids+1]=id end end
 table.sort(ids)
 local pageCount=math.max(1,math.ceil(#ids/30))
 self.completedPage=math.max(1,math.min(self.completedPage or 1,pageCount))
 local y=self:Hero(0,"ИСТОРИЯ ПЕРСОНАЖА","Сданные задания допуска",self.queryState or "История ещё не получена",1)
 local f=self:NewCard(0,y,766,60)
 action(f,"К цепочкам",function() G.showCompleted=false;G:Navigate("chains") end,18,14,220)
 action(f,"Обновить историю",function() G:QueryQuests(false) end,260,14,240,true);y=y+72
 local scope=self:NewCard(0,y,766,104)
 scope.title:SetText(stageId and ("Этап "..stageId..": "..self.stages[stageId].title) or "Все этапы открытия контента")
 action(scope,self.completedAll and "Только выбранный этап" or "Все этапы допуска",function() G.completedAll=not G.completedAll;G.completedPage=1;G:Navigate("chains") end,18,56,270);y=y+116
 y=self:Paragraph(y,"Только задания открытия контента","Показаны сданные задания цепочек допуска выбранного этапа. Обычные задания прокачки исключены. Уровень задания и минимальный уровень взяты из базы; сервер может менять требования. Уровень персонажа в момент сдачи старых заданий сервер не возвращает.")
 if #ids==0 then return self:Paragraph(y,"Список пуст",self.historyReady and "Для выбранного этапа нет подтверждённых сданных заданий допуска. Можно посмотреть все этапы или открыть цепочки, чтобы увидеть оставшиеся задания." or "Дождитесь ответа или нажмите «Обновить историю».") end
 local nav=self:NewCard(0,y,766,96);nav.title:SetText("Страница "..self.completedPage.." / "..pageCount.." - всего "..#ids)
 action(nav,"< Предыдущая",function() G.completedPage=math.max(1,G.completedPage-1);G:Navigate("chains") end,18,48,220)
 action(nav,"Следующая >",function() G.completedPage=math.min(pageCount,G.completedPage+1);G:Navigate("chains") end,260,48,220,true);y=y+108
 for index=(self.completedPage-1)*30+1,math.min(#ids,self.completedPage*30) do
  local id=ids[index]
  local row=self:NewCard(0,y,766,88)
  local meta=catalog[id]
  row.title:SetText(meta.title);row.title:SetWidth(535)
  row.body:ClearAllPoints();row.body:SetPoint("TOPLEFT",row,"TOPLEFT",18,-(28+row.title:GetStringHeight()))
  row.body:SetText("Сдано - "..meta.context.."\n"..self:QuestLevelLabel(meta));row.body:SetWidth(535);color(row.body,C.green)
  action(row,"Wowhead",function() G:ShowQuestLinks(id) end,590,30,155)
  row:SetHeight(math.max(88,40+row.title:GetStringHeight()+row.body:GetStringHeight()));y=y+row:GetHeight()+8
 end
 return y
end
function G:RenderChains()
 if self.showCompleted then return self:RenderCompletedQuests() end
 local y=0
 local selected=self.selectedChain and self.chains[self.selectedChain]
 if not selected then
  y=self:Hero(0,"БИБЛИОТЕКА ДОПУСКОВ","Цепочки вашего персонажа","История заданий восстанавливается независимо от даты установки аддона.",2)
  local controls=self:NewCard(0,y,766,60)
 action(controls,"Сданные задания",function() G.showCompleted=true;G.completedAll=false;G.completedStage=G.chainStage or G.selectedStage or G.db.phase or 0;G.completedPage=1;G:Navigate("chains") end,18,14,240)
 action(controls,"Обновить историю",function() G:QueryQuests(false) end,280,14,240,true);y=y+72
 y=self:Paragraph(y,"Как читать этот раздел","Это последовательности квестов из Attune. Ветви длинных цепочек могут выполняться параллельно. Местные условия Solo Progress указаны на экране этапа; список не обещает, что следующее задание уже доступно.")
  local ids={}
  local filter=self.chainStage and self.stages[self.chainStage].chains
  if filter then for _,id in ipairs(filter) do ids[#ids+1]=id end
  else for id in pairs(self.chains) do ids[#ids+1]=id end;table.sort(ids) end
  for _,id in ipairs(ids) do
   local chain=self.chains[id]
   if chain and (chain.faction=="Both" or chain.faction==self.db.faction) then
    local chainId=id;local done,total=0,0
    for _,q in ipairs(chain.quests or {}) do
     if not q.repeatable and not q.optional then
      total=total+1;local state=self:QuestState(q.id);if state=="done" or state=="history" then done=done+1 end
     end
    end
    local f=self:NewCard(0,y,766,84);f.pic:SetTexture(chain.icon);f.pic:Show()
    f.title:ClearAllPoints();f.title:SetPoint("TOPLEFT",f,"TOPLEFT",76,-16);f.title:SetWidth(440);f.title:SetText(chain.title..(chain.branch and (" — "..chain.branch) or ""))
    f.body:ClearAllPoints();f.body:SetPoint("TOPLEFT",f,"TOPLEFT",76,-48);f.body:SetWidth(440)
    f.body:SetText(chain.quests and ("Сдано обязательных однократных заданий: "..done.." / "..total) or "Отдельная предметная ветка без цепочки заданий")
    action(f,"Открыть",function() G.selectedChain=chainId;G:Navigate("chains") end,578,24,164);y=y+96
   end
  end
  if filter then
   local f=self:NewCard(0,y,766,60);action(f,"Все цепочки",function() G.chainStage=nil;G:Navigate("chains") end,18,14,220);y=y+72
  end
 else
  local f=self:NewCard(0,y,766,60)
  if self.page=="journey" and self.chainStage==3 and (self.selectedChain==10 or self.selectedChain==11 or self.selectedChain==12) then
   action(f,"< Этап 3: все допуски",function() G.aqPathChoiceReview=true;G.aqPathPreview=nil;G.selectedChain=nil;G.scroll:SetVerticalScroll(0);G:Render() end,18,14,280)
   local choice=self.selectedChain==10 and "scepter" or "mallet"
   if self.selectedChain~=12 and (self.db.pathChoice~=choice or self.aqPathPreview) then
    action(f,self.selectedChain==10 and "Выбрать ветку А — Скипетр" or "Выбрать ветку Б — Молот",function() G:ChoosePath(choice);G:Render() end,316,14,300,true)
   end
  else
   action(f,"< Назад к цепочкам",function() G.selectedChain=nil;G:Navigate("chains") end,18,14,250)
   if self.chainStage==3 and (self.selectedChain==10 or self.selectedChain==11) then
    local choice=self.selectedChain==10 and "scepter" or "mallet"
    action(f,self.db.pathChoice==choice and "Этот путь отмечен" or "Отметить этот путь",function() G:ChoosePath(choice);G:Render() end,286,14,250,true)
   end
  end
  y=y+72
  y=self:Hero(y,selected.steps and "АЛЬТЕРНАТИВНАЯ ВЕТКА" or "ЦЕПОЧКА ДОПУСКА",selected.title..(selected.branch and (" — "..selected.branch) or ""),selected.steps and "Эта ветка состоит из предметных шагов и не смешивается с заданиями Скипетра." or "Зелёным отмечены сданные задания. Задания в журнале показывают живые цели.",2)
  if self.selectedChain==10 then y=self:ScepterRewardCard(y) end
  if selected.note then y=self:Paragraph(y,"Как читать эту ветку",selected.note,selected.steps and C.red or C.gold) end
  if selected.steps then
   local focusIndex=1
   if GetItemCount(9240,false)>0 then focusIndex=2
   elseif GetItemCount(9241,false)>0 then focusIndex=1
   elseif self.db.phase and self.db.phase>3 and self.db.pathChoice=="mallet" then focusIndex=3 end
   for i,step in ipairs(selected.steps) do
    local have=step.item and GetItemCount(step.item,false)>0
    local finished=step.gong and self.db.phase and self.db.phase>3 and self.db.pathChoice=="mallet"
    local f=self:NewCard(0,y,766,106);f.pic:SetTexture((step.item and GetItemIcon(step.item)) or selected.icon);f.pic:Show()
    if self.focusChosenPath and i==focusIndex then self.pendingScrollY=y end
    f.title:ClearAllPoints();f.title:SetPoint("TOPLEFT",f,"TOPLEFT",76,-16);f.title:SetWidth(490);f.title:SetText(i..". "..step.title)
    f.body:ClearAllPoints();f.body:SetPoint("TOPLEFT",f,"TOPLEFT",76,-48);f.body:SetWidth(490);f.body:SetText(step.text)
    f.badge:ClearAllPoints();f.badge:SetPoint("TOPRIGHT",f,"TOPRIGHT",-18,-20);f.badge:SetWidth(155);f.badge:SetText((have and "Предмет при себе") or (finished and "Выполнено") or "Шаг ветки");color(f.badge,(have or finished) and C.green or C.gold)
    if step.url then action(f,"Wowhead",function() G:ShowURLs({step.url}) end,590,58,155) end
    f:SetHeight(math.max(106,68+f.body:GetStringHeight()));y=y+f:GetHeight()+8
   end
  else
  local focusIndex
  for i,q in ipairs(selected.quests or {}) do
   local state=self:QuestState(q.id)
   if self.questLog[q.id] and state~="done" and state~="history" then focusIndex=i;break end
  end
  if not focusIndex then
   for i,q in ipairs(selected.quests or {}) do
    local state=self:QuestState(q.id)
    if state~="done" and state~="history" then focusIndex=i;break end
   end
  end
  if not focusIndex then focusIndex=math.max(1,#(selected.quests or {})) end
  for i,q in ipairs(selected.quests or {}) do
   local state,status,prefix,questColor=self:QuestPresentation(q.id)
   local finished=state=="done" or state=="history"
   local f=self:NewCard(0,y,766,88)
   if self.focusChosenPath and i==focusIndex then self.pendingScrollY=y end
   f.title:SetText(prefix..i..". "..q.title..(q.optional and " — НЕОБЯЗАТЕЛЬНО, НО КРАЙНЕ РЕКОМЕНДУЕТСЯ" or q.repeatable and q.id~=8302 and " — повторяемое" or ""));f.title:SetWidth(550);f.title:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",15);color(f.title,questColor)
   f.body:SetText(q.zone.."\n"..(q.optional and ((q.note or "Не требуется для продолжения цепочки, но заметно упрощает следующий шаг.").."\n") or q.repeatable and "Для продолжения повторять только до появления «Анахронос».\n" or "")..self:QuestLevelLabel(self.questMetadata[q.id]));f.body:SetWidth(550)
   local log=self.questLog[q.id]
   if log and #log.objectives>0 then
    local texts={q.zone}
    if q.optional then texts[#texts+1]=q.note or "Не требуется для продолжения цепочки, но заметно упрощает следующий шаг." end
    if q.repeatable then texts[#texts+1]="Да, делать сейчас: повторять до Нейтралитета или появления «Анахронос»." end
    texts[#texts+1]=self:QuestLevelLabel(self.questMetadata[q.id])
    for _,o in ipairs(log.objectives) do texts[#texts+1]=o.text end
    f.body:SetText(table.concat(texts,"\n"))
   end
   if q.id==8302 then
    local repeatCount,repeatTarget,estimated=self:RepeatableProgress(8302)
    local baseDone=self:QuestFinished(8301)
    local batches=(baseDone and 1 or 0)+repeatCount
    local fragments=GetItemCount(20384,false) or 0
    local current=(log and log.complete) and "Текущая партия 200 / 200 готова к сдаче." or ("Сейчас в сумках: "..math.min(200,fragments).." / 200 панцирей.")
    local repLabel,_,repMin,repMax,repValue=self:NozdormuProgress()
    local repText="Репутация с Родом Ноздорму: данные пока недоступны."
    if repLabel and repMin and repMax and repValue then
     local repCurrent=math.max(0,repValue-repMin)
     local repTotal=math.max(0,repMax-repMin)
     repText="Репутация с Родом Ноздорму: "..repLabel.." — "..repCurrent.." / "..repTotal.."; до следующего уровня "..math.max(0,repTotal-repCurrent).."."
    end
    f.body:SetText("Всего сдано партий по 200: "..batches.." / 6 ("..(batches*200).." / 1200 панцирей).\n«Путь праведника»: "..(baseDone and "1 / 1" or "0 / 1").."; повторы «Руки праведника»: "..repeatCount.." / "..repeatTarget..(estimated and " (минимум, восстановленный по истории)" or "")..".\n"..repText.."\n"..current.."\nКнопки справа нужны только для коррекции сдач, сделанных до установки счётчика.")
   end
   f.badge:ClearAllPoints();f.badge:SetPoint("TOPRIGHT",f,"TOPRIGHT",-18,-20);f.badge:SetWidth(155);f.badge:SetText(status);color(f.badge,questColor)
   if finished then f:SetBackdropBorderColor(unpack(C.green)) elseif state=="active" then f:SetBackdropBorderColor(unpack(C.blue)) end
   local bottom=math.max(88,64+f.body:GetStringHeight())
   if q.id==8302 then
    action(f,"- 1",function() G:AdjustRepeatable(8302,-1);G:Render() end,510,bottom,70)
    action(f,"+ 1 сдача",function() G:AdjustRepeatable(8302,1);G:Render() end,590,bottom,155,true)
    bottom=bottom+42
   else action(f,"Wowhead",function() G:ShowQuestLinks(q.id) end,590,46,155) end
   f:SetHeight(self:HelpEntryButton(f,bottom,"quest:"..q.id));y=y+f:GetHeight()+8
  end
  end
 end
 return y
end
function G:RenderPhase()
 local y=self:Hero(0,"ВОССТАНОВЛЕНИЕ ПРОГРЕССА","Где вы сейчас?",self:PhaseLabel(),(self.db.phase and self.stages[self.db.phase].chapter) or 1)
 local f=self:NewCard(0,y,766,154);f.title:SetText(self.realmMode=="Solo" and "1. Проверить историю заданий" or "1. Выбрать себя целью, 2. запросить этап")
 f.body:SetText(self.ipStatus or (self.realmMode=="Solo" and "На реалме Solo этап определяется по истории выполненных заданий. Кнопка обновит историю; команда .ip get здесь не используется." or "WoW запрещает аддону менять цель обычным кодом. Первая защищённая кнопка выбирает вашего персонажа; вторая отправляет .ip get и после ответа автоматически открывает «Мой путь»."))
 if self.realmMode~="Solo" then
  local targetButton=self:EnsurePlayerTargetButton(f)
  if targetButton then
   targetButton:ClearAllPoints();targetButton:SetPoint("TOPLEFT",f,"TOPLEFT",18,-108)
   targetButton.text:SetText(UnitExists("target") and UnitIsUnit("target","player") and "1. Вы выбраны" or "1. Выбрать себя");targetButton:Show()
  end
 end
 action(f,self.realmMode=="Solo" and "Обновить историю заданий" or "2. Запросить и открыть путь",function() G:RequestPhase() end,self.realmMode=="Solo" and 18 or 250,108,self.realmMode=="Solo" and 300 or 260)
 f.action:SetBackdropColor(0.28,0.20,0.09,1);f.action:SetBackdropBorderColor(unpack(C.gold))
 if self.realmMode=="Solo" then
  action(f,self.db.phase~=nil and "К моему пути >" or "Обновить историю",function()
   if G.db.phase~=nil then G.selectedStage=nil;G:Navigate("journey") else G:QueryQuests(false) end
  end,332,108,230,true)
 end
 y=y+166
 local history=self:NewCard(0,y,766,60)
 action(history,"Сданные задания",function() G.showCompleted=true;G.completedAll=false;G.completedStage=G.selectedStage or G.db.phase or 0;G.completedPage=1;G:Navigate("chains") end,18,14,240)
 action(history,"Обновить историю",function() G:QueryQuests(false) end,280,14,240,true);y=y+72
 local hint,why=self:HistoryHint()
 y=self:Paragraph(y,"Прогресс нового или опытного персонажа",hint and (self.realmMode=="Solo" and ("История нашла подтверждение этапа "..hint..": "..why..". На Solo каждый этап проверяется отдельно; найденный результат не закрывает промежуточные этапы автоматически.") or ("В истории есть признаки этапа "..hint.." или выше: "..why..". Это только справка и она не меняет текущий этап; точное значение берётся из ответа .ip get.")) or (self.realmMode=="Solo" and "Нажмите «Обновить историю заданий», затем откройте «Сданные задания» или выберите этап вручную. На Solo каждый этап проверяется отдельно." or "Сначала выберите себя первой кнопкой, затем запросите этап. После ответа сервера аддон автоматически откроет «Мой путь»."))
 if self.db.lastIP and self.db.lastIP~="" then y=self:Paragraph(y,"Последний ответ",self.db.lastIP) end
 y=self:Paragraph(y,self.realmMode=="Solo" and "2. При необходимости выбрать вручную" or "3. При необходимости выбрать вручную","Выберите свой текущий этап по названию доступного контента. Это только отметка в путеводителе: она не отправляет команды изменения прогресса. Последующий распознанный ответ сервера заменит отметку.")
 for i=0,18 do
  local id=i;local s=self.stages[id]
  local card=self:NewCard(0,y,766,64)
  card.title:SetText(tostring(id).." - "..s.title);card.title:SetWidth(520);card.title:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",15)
  local height=math.max(64,36+card.title:GetStringHeight())
  card:SetHeight(height)
  action(card,self.db.phase==id and "Выбран" or "Это мой этап",function() G:SetPhase(id,"manual");G.selectedStage=nil end,558,(height-32)/2,188)
  y=y+height+8
 end
 y=self:Paragraph(y,"Уже прошли всё?","Выберите «18 - Путешествие завершено», если Халион уже побеждён. Этап 17 означает только доступ к Рубиновому святилищу. Отдельные необязательные квесты останутся со своей историей.")
 return y
end
function G:Render()
 if not self.window or not self.active then return end
 self.cursor=0
 self.identity:SetText(self.db.name.."  -  "..self.db.realm.."\n"..self:PhaseLabel())
 for key,b in pairs(self.tabs) do b:SetBackdropColor(unpack(key==self.page and {0.20,0.16,0.10} or C.panel));color(b.text,key==self.page and C.gold or C.muted) end
 local id=self.selectedStage or self.db.phase or self:HistoryHint() or 0
 for i,b in pairs(self.stageButtons) do
  local done,total,pct=self:StageProgress(i)
  b.text:SetText(self.stages[i].title)
  b.progress:SetText(total>0 and (done.."/"..total) or "—")
  b:SetBackdropColor(unpack(i==id and self.page=="journey" and {0.18,0.15,0.10} or C.bg))
  color(b.number,self.realmMode~="Solo" and self.db.phase and i<self.db.phase and C.green or i==self.db.phase and C.gold or C.muted)
  b:GetNormalTexture():SetVertexColor(i==id and 0.65 or 0,i==id and 0.27 or 0,i==id and 0.07 or 0,i==id and 0.45 or 0)
  color(b.text,i==id and C.gold or C.muted)
 end
 local height
 if self.page=="resources" then height=self:RenderResources()
 elseif self.page=="chains" then height=self:RenderChains()
 elseif self.page=="phase" then height=self:RenderPhase()
 else height=self:RenderJourney() end
 for i=self.cursor+1,#self.pool do self.pool[i]:Hide() end
 local viewportHeight=self.viewportHeight or 554
 self.content:SetHeight(math.max(viewportHeight,height or viewportHeight))
 self.scroll:SetVerticalScroll(math.min(self.scroll:GetVerticalScroll(),math.max(0,self.content:GetHeight()-viewportHeight)))
 if self.pendingScrollY then
  self.scroll:SetVerticalScroll(math.max(0,math.min(self.pendingScrollY,math.max(0,self.content:GetHeight()-viewportHeight))))
  self.pendingScrollY=nil
 end
 self.focusChosenPath=nil
 self.focusCurrentJourney=nil
 local countStage=id
 if self.page=="resources" then countStage=3
 elseif self.page=="chains" then
  if self.showCompleted then
   countStage=self.completedStage or self.db.phase or 0
   if self.completedAll then countStage=nil end
  else countStage=self.chainStage end
 end
 local total,done,missing,uncertain=self:QuestProgressCounts(countStage)
 local scope=countStage and ("Каталог допуска этапа "..countStage) or "Каталог всех допусков"
 local counts=scope..": сдано "..done.."/"..total.."; не сдано "..missing
 if uncertain>0 then counts=counts.."; не подтверждено "..uncertain end
 self.footer:SetText((self.queryState or "История заданий ещё не получена").."\n"..counts..". Включая альтернативные цепочки.")
end
