ChatTimestampsDB = ChatTimestampsDB or {};

local ADDON_NAME = "ChatTimestamps";
local DEFAULT_FORMAT = "%H:%M:%S";

-- WotLK ChatFrame.lua:2802 formats a channel notice without checking whether
-- the client has its localized template. Install only a missing template before
-- the normal handler runs, preserving channel routing and other chat filters.
local function ChatTimestampsChannelNoticeFilter(self, event, code)
	if (type(code) ~= "string") then
		return false;
	end
	local key = "CHAT_"..code.."_NOTICE";
	if (not _G[key.."_BN"] and not _G[key]) then
		-- The code becomes part of a format string and WoW chat markup.
		local displayCode = code:gsub("%%", "%%%%"):gsub("|", "||"):gsub("[\r\n]", " ");
		_G[key] = "[%s. %s] Неизвестное уведомление канала (код: "..displayCode..").";
	end
	return false;
end

-- Register during file loading: initial channel notices can precede PLAYER_LOGIN.
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", ChatTimestampsChannelNoticeFilter);

local function ChatTimestampsMessage(text)
	if (DEFAULT_CHAT_FRAME) then
		DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffChatTimestamps:|r "..tostring(text));
	end
end

local function ChatTimestampsPrefix()
	local format = ChatTimestampsDB.format or DEFAULT_FORMAT;
	return "|cff888888["..date(format).."]|r ";
end

local function ChatTimestampsHookFrame(frame)
	if (not frame or frame.ChatTimestampsHooked or type(frame.AddMessage) ~= "function") then
		return;
	end
	local originalAddMessage = frame.AddMessage;
	frame.ChatTimestampsHooked = true;
	frame.AddMessage = function(self, text, ...)
		if (
			ChatTimestampsDB.enabled ~= false
			and type(text) == "string"
			and text ~= ""
		) then
			text = ChatTimestampsPrefix()..text;
		end
		return originalAddMessage(self, text, ...);
	end;
end

local function ChatTimestampsHookAllFrames()
	for index = 1, (NUM_CHAT_WINDOWS or 10), 1 do
		ChatTimestampsHookFrame(_G["ChatFrame"..tostring(index)]);
	end
end

local function ChatTimestampsStatus()
	local state = ChatTimestampsDB.enabled ~= false and "включены" or "выключены";
	local example = ChatTimestampsDB.format == "%H:%M" and "[ЧЧ:ММ]" or "[ЧЧ:ММ:СС]";
	ChatTimestampsMessage("отметки времени "..state..", формат "..example..".");
end

SLASH_CHATTIMESTAMPS1 = "/cttime";
SlashCmdList["CHATTIMESTAMPS"] = function(message)
	local command = string.lower((message or ""):match("^%s*(.-)%s*$") or "");
	if (command == "on" or command == "вкл") then
		ChatTimestampsDB.enabled = true;
		ChatTimestampsStatus();
	elseif (command == "off" or command == "выкл") then
		ChatTimestampsDB.enabled = false;
		ChatTimestampsStatus();
	elseif (command == "seconds" or command == "sec" or command == "сек") then
		ChatTimestampsDB.format = "%H:%M:%S";
		ChatTimestampsStatus();
	elseif (command == "minutes" or command == "min" or command == "мин") then
		ChatTimestampsDB.format = "%H:%M";
		ChatTimestampsStatus();
	elseif (command == "" or command == "status" or command == "статус") then
		ChatTimestampsStatus();
	else
		ChatTimestampsMessage("команды: /cttime on, off, seconds, minutes, status.");
	end
end;

local frame = CreateFrame("Frame", "ChatTimestampsEventFrame");
frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("PLAYER_LOGIN");
frame:SetScript("OnEvent", function(self, event, name)
	if (event == "ADDON_LOADED" and name == ADDON_NAME) then
		if (ChatTimestampsDB.enabled == nil) then
			ChatTimestampsDB.enabled = true;
		end
		if (ChatTimestampsDB.format ~= "%H:%M" and ChatTimestampsDB.format ~= "%H:%M:%S") then
			ChatTimestampsDB.format = DEFAULT_FORMAT;
		end
	elseif (event == "PLAYER_LOGIN") then
		ChatTimestampsHookAllFrames();
		self:UnregisterEvent("PLAYER_LOGIN");
	end
end);
