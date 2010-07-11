------------------------------------------------------------------------
--	PhanxChat                                                         --
--	Removes chat frame clutter and adds some functionality.           --
--	by Phanx < addons@phanx.net >                                     --
--	Copyright © 2006–2010 Phanx. See README for license terms.        --
--	http://www.wowinterface.com/downloads/info6323-PhanxChat.html     --
--	http://wow.curse.com/downloads/wow-addons/details/phanxchat.aspx  --
------------------------------------------------------------------------

local URL_STYLE = "|cff33ccff%s|r"
--	%s = url (required)

------------------------------------------------------------------------
--	Nothing beyond here is intended to be configurable.
------------------------------------------------------------------------

local _, PhanxChat = ...
local CURRENT_URL, TLDS, URL_EVENTS, URL_PATTERNS
local URL_LINK = "|Hurl:%s|h" .. URL_STYLE .. "|h"

------------------------------------------------------------------------

local function LinkURL(url, tld)
	if tld then
		return TLDS[tld:upper()] and URL_LINK:format(url, url) or url
	else
		return URL_LINK:format(url, url)
	end
end

local function LinkURLs(frame, event, message, ...)
	if type(message) == "string" then
		for _, pattern in ipairs(URL_PATTERNS) do
			local new = message:gsub(pattern, LinkURL)
			if message ~= new then
				message = new
				break
			end
		end
	end
	return false, message, ...
end

------------------------------------------------------------------------

function PhanxChat.SetItemRef(link, ...)
	if link:sub(1, 3) == "url" then
		CURRENT_URL = link:sub(5)
		return StaticPopup_Show("URL_COPY_DIALOG")
	end
	PhanxChat.hooks.SetItemRef(link, ...)
end

------------------------------------------------------------------------

function PhanxChat:SetLinkURLs(v)
	if self.debug then print("PhanxChat: SetLinkURLs", v) end
	if type(v) == "boolean" then
		self.db.LinkURLs = v
	end

	if self.db.LinkURLs then
		for _, event in ipairs(URL_EVENTS) do
			ChatFrame_AddMessageEventFilter(event, LinkURLs)
		end
		if not self.hooks.SetItemRef then
			self.hooks.SetItemRef = SetItemRef
			SetItemRef = self.SetItemRef
		end
	else
		for _, event in ipairs(URL_EVENTS) do
			ChatFrame_RemoveMessageEventFilter(event, LinkURLs)
		end
		if self.hooks.SetItemRef then
			SetItemRef = self.hooks.SetItemRef
			self.hooks.SetItemRef = nil
		end
	end

	if not StaticPopupDialogs.URL_COPY_DIALOG then
		StaticPopupDialogs.URL_COPY_DIALOG = {
			text = "URL",
			button2 = CLOSE,
			hasEditBox = 1,
			hasWideEditBox = 1,
			hideOnEscape = 1,
			maxLetters = 1024,
			showAlert = 1,
			timeout = 0,
			whileDead = 1,
			OnShow = function(self)
				local icon = self.icon or _G[self:GetName().."AlertIcon"]
				if icon then
					icon:Hide()
				end
				local wideEditBox = self.wideEditBox or _G[self:GetName().."WideEditBox"]
				if wideEditBox then
					wideEditBox:SetText(CURRENT_URL)
					wideEditBox:SetFocus()
					wideEditBox:HighlightText(0)
				end
				local button2 = self.button2 or _G[self:GetName().."Button2"]
				if button2 then
					button2:ClearAllPoints()
					button2:SetPoint("TOPRIGHT", wideEditBox, "BOTTOMRIGHT", 7, 12)
					button2:SetWidth(150)
				end
			end,
			EditBoxOnEscapePressed = function(self)
				self:GetParent():Hide()
			end,
		}
	end
end

------------------------------------------------------------------------

table.insert(PhanxChat.RunOnLoad, PhanxChat.SetLinkURLs)

------------------------------------------------------------------------

URL_EVENTS = {
	"CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER",
	"CHAT_MSG_BN_CONVERSATION",
	"CHAT_MSG_BN_WHISPER",
	"CHAT_MSG_BN_WHISPER_INFORM",
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_DUNGEON_GUIDE",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_GUIDE",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_SAY",
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_YELL"
}

URL_PATTERNS = {
		-- X://Y url
	"^(%a[%w%.+-]+://%S+)",
	"%f[%S](%a[%w%.+-]+://%S+)",
		-- www.X.Y url
	"^(www%.[-%w_%%]+%.%S+)",
	"%f[%S](www%.[-%w_%%]+%.%S+)",
		-- X@Y.Z email
	"(%S+@[-%w_%%%.]+%.(%a%a+))",
		-- XXX.YYY.ZZZ.WWW:VVVV/UUUUU IPv4 address with port and path
	"^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d/%S+)",
	"%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d/%S+)",
		-- XXX.YYY.ZZZ.WWW:VVVV IPv4 address with port (IP of ts server for example)
	"^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d)%f[%D]",
	"%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d)%f[%D]",
		-- XXX.YYY.ZZZ.WWW/VVVVV IPv4 address with path
	"^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%/%S+)",
	"%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%/%S+)",
		-- XXX.YYY.ZZZ.WWW IPv4 address
	"^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%)%f[%D]",
	"%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%)%f[%D]",
		-- X.Y.Z:WWWW/VVVVV url with port and path
	"^([-%w_%%%.]+[-%w_%%]%.(%a%a+):[0-6]?%d?%d?%d?%d/%S+)",
	"%f[%S]([-%w_%%%.]+[-%w_%%]%.(%a%a+):[0-6]?%d?%d?%d?%d/%S+)",
		-- X.Y.Z:WWWW url with port
	"^([-%w_%%%.]+[-%w_%%]%.(%a%a+):[0-6]?%d?%d?%d?%d)%f[%D]",
	"%f[%S]([-%w_%%%.]+[-%w_%%]%.(%a%a+):[0-6]?%d?%d?%d?%d)%f[%D]",
		-- X.Y.Z/WWWWW url with path
	"^([-%w_%%%.]+[-%w_%%]%.(%a%a+)/%S+)",
	"%f[%S]([-%w_%%%.]+[-%w_%%]%.(%a%a+)/%S+)",
		-- X.Y.Z url
	"^([-%w_%%%.]+[-%w_%%]%.(%a%a+))",
	"%f[%S]([-%w_%%%.]+[-%w_%%]%.(%a%a+))",
}

TLDS = { AC = true, AD = true, AE = true, AERO = true, AF = true, AG = true, AI = true, AL = true, AM = true, AN = true, AO = true, AQ = true, AR = true, ARPA = true, AS = true, ASIA = true, AT = true, AU = true, AW = true, AX = true, AZ = true, BA = true, BB = true, BD = true, BE = true, BF = true, BG = true, BH = true, BI = true, BIZ = true, BJ = true, BM = true, BN = true, BO = true, BR = true, BS = true, BT = true, BV = true, BW = true, BY = true, BZ = true, CA = true, CAT = true, CC = true, CD = true, CF = true, CG = true, CH = true, CI = true, CK = true, CL = true, CM = true, CN = true, CO = true, COM = true, COOP = true, CR = true, CU = true, CV = true, CX = true, CY = true, CZ = true, DE = true, DJ = true, DK = true, DM = true, DO = true, DZ = true, EC = true, EDU = true, EE = true, EG = true, ER = true, ES = true, ET = true, EU = true, FI = true, FJ = true, FK = true, FM = true, FO = true, FR = true, GA = true, GB = true, GD = true, GE = true, GF = true, GG = true, GH = true, GI = true, GL = true, GM = true, GN = true, GOV = true, GP = true, GQ = true, GR = true, GS = true, GT = true, GU = true, GW = true, GY = true, HK = true, HM = true, HN = true, HR = true, HT = true, HU = true, ID = true, IE = true, IL = true, IM = true, IN = true, INFO = true, INT = true, IO = true, IQ = true, IR = true, IS = true, IT = true, JE = true, JM = true, JO = true, JOBS = true, JP = true, KE = true, KG = true, KH = true, KI = true, KM = true, KN = true, KP = true, KR = true, KW = true, KY = true, KZ = true, LA = true, LB = true, LC = true, LI = true, LK = true, LR = true, LS = true, LT = true, LU = true, LV = true, LY = true, MA = true, MC = true, MD = true, ME = true, MG = true, MH = true, MIL = true, MK = true, ML = true, MM = true, MN = true, MO = true, MOBI = true, MP = true, MQ = true, MR = true, MS = true, MT = true, MU = true, MUSEUM = true, MV = true, MW = true, MX = true, MY = true, MZ = true, NA = true, NAME = true, NC = true, NE = true, NET = true, NF = true, NG = true, NI = true, NL = true, NO = true, NP = true, NR = true, NU = true, NZ = true, OM = true, ORG = true, PA = true, PE = true, PF = true, PG = true, PH = true, PK = true, PL = true, PM = true, PN = true, PR = true, PRO = true, PS = true, PT = true, PW = true, PY = true, QA = true, RE = true, RO = true, RS = true, RU = true, RW = true, SA = true, SB = true, SC = true, SD = true, SE = true, SG = true, SH = true, SI = true, SJ = true, SK = true, SL = true, SM = true, SN = true, SO = true, SR = true, ST = true, SU = true, SV = true, SY = true, SZ = true, TC = true, TD = true, TEL = true, TF = true, TG = true, TH = true, TJ = true, TK = true, TL = true, TM = true, TN = true, TO = true, TP = true, TR = true, TRAVEL = true, TT = true, TV = true, TW = true, TZ = true, UA = true, UG = true, UK = true, UM = true, US = true, UY = true, UZ = true, VA = true, VC = true, VE = true, VG = true, VI = true, VN = true, VU = true, WF = true, WS = true, YE = true, YT = true, YU = true, ZA = true, ZM = true, ZW = true, }

------------------------------------------------------------------------