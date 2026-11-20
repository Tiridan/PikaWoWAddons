local addon = DarkmoonDeckTracker

local function ItemCount( itemID )
	return GetItemCount( itemID, true ) or 0
end

local function ItemName( itemID, fallback )
	return GetItemInfo( itemID ) or fallback or ( "Предмет " .. itemID )
end

local function ItemLink( itemID, fallback )
	local name, link, quality = GetItemInfo( itemID )
	if link then return link end
	local color = "|cffffffff"
	if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
		local hex = ITEM_QUALITY_COLORS[quality].hex
		if hex then color = string.sub( hex, 1, 2 ) == "|c" and hex or ( "|c" .. hex ) end
	end
	return color .. "|Hitem:" .. itemID .. ":0:0:0:0:0:0:0|h[" .. ( name or fallback or ( "Предмет " .. itemID ) ) .. "]|h|r"
end

local function DeckState( deck )
	local have, duplicates, missing = 0, 0, { }
	for index, itemID in ipairs( deck.cards ) do
		local count = ItemCount( itemID )
		if count > 0 then have = have + 1 end
		if count > 1 then duplicates = duplicates + count - 1 end
		if count == 0 then missing[#missing + 1] = addon.ranks[index] end
	end
	return have, duplicates, missing, ItemCount( deck.deckID )
end

local function RewardIndex( row, deck )
	local index = tonumber( row.rewardIndex ) or 1
	if index < 1 or index > #deck.rewards then index = 1 end
	return index
end

local function UpdateRewardDisplay( row, deck )
	local index = RewardIndex( row, deck )
	local reward = deck.rewards[index]
	local prefix = "Награда: "
	if #deck.rewards > 1 then prefix = "Награда " .. index .. "/" .. #deck.rewards .. ": " end
	row.reward:SetText( prefix .. ItemName( reward[1], reward[2] ) )
	row.rewardIcon:SetTexture( GetItemIcon( reward[1] ) or "Interface\\Icons\\INV_Misc_QuestionMark" )
end

local function PrintRewards( deck )
	local links = { }
	for _, reward in ipairs( deck.rewards ) do
		links[#links + 1] = ItemLink( reward[1], reward[2] )
	end
	DEFAULT_CHAT_FRAME:AddMessage( "|cff69ccf0Карты Новолуния:|r " .. deck.name .. " — награда: " .. table.concat( links, ", " ) )
end

function addon.Refresh( )
	if not addon.frame or not addon.frame:IsShown( ) then return end
	local ready, totalOwned = 0, 0
	for index, row in ipairs( addon.rows ) do
		local deck = addon.decks[index]
		local have, duplicates, missing, made = DeckState( deck )
		local complete = have == #deck.cards
		if complete or made > 0 then ready = ready + 1 end
		totalOwned = totalOwned + have

		row.title:SetText( ( complete and "|cff35d05b" or made > 0 and "|cff72c7ff" or "|cffffd34e" ) .. deck.name .. "|r" )
		local status = "Карты: " .. have .. "/" .. #deck.cards
		if made > 0 then status = status .. "  •  готовая колода: " .. made end
		if duplicates > 0 then status = status .. "  •  дублей: " .. duplicates end
		row.progress:SetText( status )
		if complete then
			row.missing:SetText( "|cff35d05bМожно собрать колоду.|r" )
		elseif #missing > 0 then
			row.missing:SetText( "Не хватает: " .. table.concat( missing, ", " ) )
		else
			row.missing:SetText( "" )
		end
		UpdateRewardDisplay( row, deck )
	end
	addon.frame.summary:SetText( "Готово или уже собрано: " .. ready .. "/" .. #addon.decks .. "  •  найдено видов карт: " .. totalOwned )
end

local function ShowDeckTooltip( row )
	local deck = addon.decks[row.deckIndex]
	GameTooltip:SetOwner( row, "ANCHOR_RIGHT" )
	GameTooltip:SetText( deck.name, 1, 0.82, 0 )
	for index, itemID in ipairs( deck.cards ) do
		local count = ItemCount( itemID )
		local r, g, b = 1, 0.35, 0.35
		if count > 0 then r, g, b = 0.35, 1, 0.45 end
		GameTooltip:AddDoubleLine( addon.ranks[index], tostring( count ), r, g, b, r, g, b )
	end
	GameTooltip:AddLine( " " )
	GameTooltip:AddLine( "Награда:", 0.45, 0.8, 1 )
	for _, reward in ipairs( deck.rewards ) do
		GameTooltip:AddLine( ItemName( reward[1], reward[2] ), 1, 1, 1 )
	end
	GameTooltip:AddLine( "Нажмите, чтобы вывести ссылки на награды в чат.", 0.65, 0.85, 1, true )
	GameTooltip:Show( )
end

local function ShowRewardTooltip( row )
	local deck = addon.decks[row.deckIndex]
	local index = RewardIndex( row, deck )
	local reward = deck.rewards[index]
	GameTooltip:SetOwner( row.rewardButton, "ANCHOR_RIGHT" )
	GameTooltip:SetHyperlink( "item:" .. reward[1] .. ":0:0:0:0:0:0:0" )
	if #deck.rewards > 1 then
		GameTooltip:AddLine( " " )
		GameTooltip:AddLine( "Вариант " .. index .. " из " .. #deck.rewards .. ". Колесо мыши — другой предмет.", 0.45, 0.8, 1, true )
	end
	GameTooltip:Show( )
end

local function ChangeReward( row, delta )
	local deck = addon.decks[row.deckIndex]
	if #deck.rewards < 2 then return end
	row.rewardIndex = ( RewardIndex( row, deck ) - 1 + delta ) % #deck.rewards + 1
	UpdateRewardDisplay( row, deck )
	ShowRewardTooltip( row )
end

local function CreateRow( parent, index, y )
	local row = CreateFrame( "Button", nil, parent )
	row:SetPoint( "TOPLEFT", parent, "TOPLEFT", 4, y )
	row:SetWidth( 565 ); row:SetHeight( 64 ); row.deckIndex = index
	row:SetHighlightTexture( "Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD" )

	local shade = row:CreateTexture( nil, "BACKGROUND" )
	shade:SetAllPoints( row )
	shade:SetTexture( 0.08, 0.10, 0.14, index % 2 == 0 and 0.72 or 0.5 )

	row.title = row:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
	row.title:SetPoint( "TOPLEFT", row, "TOPLEFT", 8, -5 ); row.title:SetJustifyH( "LEFT" )
	row.progress = row:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" )
	row.progress:SetPoint( "TOPLEFT", row.title, "BOTTOMLEFT", 0, -3 ); row.progress:SetJustifyH( "LEFT" )
	row.missing = row:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" )
	row.missing:SetPoint( "TOPLEFT", row.progress, "BOTTOMLEFT", 0, -2 ); row.missing:SetWidth( 350 ); row.missing:SetJustifyH( "LEFT" )
	row.missing:SetWordWrap( false )
	row.reward = row:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" )
	row.reward:SetPoint( "TOPRIGHT", row, "TOPRIGHT", -47, -8 ); row.reward:SetWidth( 160 ); row.reward:SetJustifyH( "RIGHT" )
	row.reward:SetTextColor( 0.55, 0.82, 1 )
	row.rewardIcon = row:CreateTexture( nil, "ARTWORK" )
	row.rewardIcon:SetWidth( 34 ); row.rewardIcon:SetHeight( 34 ); row.rewardIcon:SetPoint( "TOPRIGHT", row, "TOPRIGHT", -8, -8 )
	row.rewardIcon:SetTexCoord( 0.07, 0.93, 0.07, 0.93 )
	row.rewardButton = CreateFrame( "Button", nil, row )
	row.rewardButton:SetPoint( "TOPRIGHT", row, "TOPRIGHT", -4, -4 )
	row.rewardButton:SetWidth( 210 ); row.rewardButton:SetHeight( 52 )
	row.rewardButton:EnableMouseWheel( true )
	row.rewardButton:SetHighlightTexture( "Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD" )
	row.rewardButton:SetScript( "OnEnter", function( ) ShowRewardTooltip( row ) end )
	row.rewardButton:SetScript( "OnLeave", function( ) GameTooltip:Hide( ) end )
	row.rewardButton:SetScript( "OnClick", function( ) PrintRewards( addon.decks[row.deckIndex] ) end )
	row.rewardButton:SetScript( "OnMouseWheel", function( self, delta ) ChangeReward( row, delta > 0 and -1 or 1 ) end )

	row:SetScript( "OnEnter", ShowDeckTooltip )
	row:SetScript( "OnLeave", function( ) GameTooltip:Hide( ) end )
	row:SetScript( "OnClick", function( self ) PrintRewards( addon.decks[self.deckIndex] ) end )
	return row
end

local function CreateWindow( )
	local frame = CreateFrame( "Frame", "DarkmoonDeckTrackerFrame", UIParent, "UIPanelDialogTemplate" )
	frame:SetWidth( 625 ); frame:SetHeight( 570 ); frame:SetPoint( "CENTER" )
	frame:SetMovable( true ); frame:EnableMouse( true ); frame:SetClampedToScreen( true )
	frame:RegisterForDrag( "LeftButton" )
	frame:SetScript( "OnDragStart", function( self ) self:StartMoving( ) end )
	frame:SetScript( "OnDragStop", function( self )
		self:StopMovingOrSizing( )
		local point, _, relativePoint, x, y = self:GetPoint( 1 )
		DarkmoonDeckTrackerDB.window = { point, relativePoint, x, y }
	end )
	frame:SetScript( "OnShow", addon.Refresh )
	frame:Hide( )

	local close = CreateFrame( "Button", nil, frame, "UIPanelCloseButton" )
	close:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", -5, -5 )
	local title = frame:CreateFontString( nil, "OVERLAY", "GameFontNormalLarge" )
	title:SetPoint( "TOP", frame, "TOP", 0, -15 ); title:SetText( "Карты Новолуния" )
	frame.summary = frame:CreateFontString( nil, "OVERLAY", "GameFontHighlight" )
	frame.summary:SetPoint( "TOPLEFT", frame, "TOPLEFT", 22, -43 )
	local note = frame:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" )
	note:SetPoint( "TOPLEFT", frame.summary, "BOTTOMLEFT", 0, -3 )
	note:SetText( "Сумки + личный банк. Наведите на колоду — карты, на награду — описание предмета." )
	note:SetTextColor( 0.7, 0.7, 0.7 )

	local refresh = CreateFrame( "Button", nil, frame, "UIPanelButtonTemplate" )
	refresh:SetWidth( 92 ); refresh:SetHeight( 22 ); refresh:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", -38, -39 )
	refresh:SetText( "Обновить" ); refresh:SetScript( "OnClick", addon.Refresh )

	local scroll = CreateFrame( "ScrollFrame", "DarkmoonDeckTrackerScrollFrame", frame, "UIPanelScrollFrameTemplate" )
	scroll:SetPoint( "TOPLEFT", frame, "TOPLEFT", 18, -82 ); scroll:SetPoint( "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 18 )
	local child = CreateFrame( "Frame", nil, scroll )
	child:SetWidth( 570 ); child:SetHeight( #addon.decks * 68 + 80 ); scroll:SetScrollChild( child )

	addon.rows = { }
	local y, lastExpansion = -2, nil
	for index, deck in ipairs( addon.decks ) do
		if deck.expansion ~= lastExpansion then
			local header = child:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
			header:SetPoint( "TOPLEFT", child, "TOPLEFT", 6, y ); header:SetText( deck.expansion )
			header:SetTextColor( 0.95, 0.65, 0.2 ); y = y - 22; lastExpansion = deck.expansion
		end
		addon.rows[index] = CreateRow( child, index, y ); y = y - 68
	end
	child:SetHeight( -y + 4 )
	addon.frame = frame

	if DarkmoonDeckTrackerDB.window then
		local p = DarkmoonDeckTrackerDB.window
		frame:ClearAllPoints( ); frame:SetPoint( p[1], UIParent, p[2], p[3], p[4] )
	end
end

local function CreateMinimapButton( )
	local button = CreateFrame( "Button", "DarkmoonDeckTrackerMinimapButton", Minimap )
	button:SetWidth( 32 ); button:SetHeight( 32 ); button:SetPoint( "TOPLEFT", Minimap, "TOPLEFT", -7, 5 )
	button:SetFrameStrata( "MEDIUM" ); button:RegisterForClicks( "LeftButtonUp" )
	local border = button:CreateTexture( nil, "OVERLAY" )
	border:SetWidth( 54 ); border:SetHeight( 54 ); border:SetPoint( "CENTER" )
	border:SetTexture( "Interface\\Minimap\\MiniMap-TrackingBorder" )
	local icon = button:CreateTexture( nil, "BACKGROUND" )
	icon:SetWidth( 20 ); icon:SetHeight( 20 ); icon:SetPoint( "CENTER", 0, 1 )
	icon:SetTexture( "Interface\\Icons\\INV_Misc_Ticket_Tarot_01" )
	button:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
	button:SetScript( "OnClick", function( ) addon.Toggle( ) end )
	button:SetScript( "OnEnter", function( self )
		GameTooltip:SetOwner( self, "ANCHOR_LEFT" ); GameTooltip:SetText( "Карты Новолуния" )
		GameTooltip:AddLine( "Показать собранные и недостающие карты.", 1, 1, 1, true ); GameTooltip:Show( )
	end )
	button:SetScript( "OnLeave", function( ) GameTooltip:Hide( ) end )
	addon.minimapButton = button
end

function addon.Toggle( )
	if addon.frame:IsShown( ) then addon.frame:Hide( ) else addon.frame:Show( ) end
end

local events = CreateFrame( "Frame" )
events:RegisterEvent( "PLAYER_LOGIN" )
events:RegisterEvent( "BAG_UPDATE" )
events:RegisterEvent( "BANKFRAME_OPENED" )
events:RegisterEvent( "BANKFRAME_CLOSED" )
events:RegisterEvent( "PLAYERBANKSLOTS_CHANGED" )
events:SetScript( "OnEvent", function( self, event )
	if event == "PLAYER_LOGIN" then
		DarkmoonDeckTrackerDB = DarkmoonDeckTrackerDB or { }
		CreateWindow( ); CreateMinimapButton( )
		SLASH_DARKMOONDECKTRACKER1 = "/cards"
		SLASH_DARKMOONDECKTRACKER2 = "/dmt"
		SlashCmdList.DARKMOONDECKTRACKER = addon.Toggle
		for _, deck in ipairs( addon.decks ) do
			GetItemInfo( deck.deckID )
			for _, itemID in ipairs( deck.cards ) do GetItemInfo( itemID ) end
			for _, reward in ipairs( deck.rewards ) do GetItemInfo( reward[1] ) end
		end
		DEFAULT_CHAT_FRAME:AddMessage( "|cff69ccf0Карты Новолуния " .. addon.version .. ":|r /cards — открыть трекер." )
	else
		addon.Refresh( )
	end
end )
