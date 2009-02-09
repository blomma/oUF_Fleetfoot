--[[

	oUF_Blomma

	Author:		Blomma
	Mail:		blomma@gmail.com

	Credits:	oUF_Lyn (used as base) / http://www.wowinterface.com/downloads/info10326-oUF_Lyn.html
				oUF_TsoHG (used as base) / http://www.wowinterface.com/downloads/info8739-oUF_TsoHG.html
				Rothar for buff border (and Neal for the edited version)
				p3lim for party toggle function

--]]

-- ------------------------------------------------------------------------
-- local horror
-- ------------------------------------------------------------------------
local select = select
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitIsConnected = UnitIsConnected
local UnitAura = UnitAura
local UnitPowerType = UnitPowerType
local sformat = string.format

-- ------------------------------------------------------------------------
-- font, fontsize and textures
-- ------------------------------------------------------------------------
local font = "Interface\\AddOns\\oUF_Blomma\\fonts\\font.ttf"
local upperfont = "Interface\\AddOns\\oUF_Blomma\\fonts\\upperfont.ttf"
local fontsize = 15
local bartex = "Interface\\AddOns\\oUF_Blomma\\textures\\statusbar"
local bufftex = "Interface\\AddOns\\oUF_Blomma\\textures\\border"
local playerClass = select(2, UnitClass("player"))

-- ------------------------------------------------------------------------
-- change some colors :)
-- ------------------------------------------------------------------------
local colors = setmetatable({
	happiness = setmetatable({
		[1] = {182/225, 34/255, 32/255},	-- unhappy
		[2] = {220/225, 180/225, 52/225},	-- content
		[3] = {143/255, 194/255, 32/255},	-- happy
	}, {__index = oUF.colors.happiness}),
}, {__index = oUF.colors})

-- ------------------------------------------------------------------------
-- right click
-- ------------------------------------------------------------------------
local menu = function(self)
	local unit = string.gsub(self.unit, '(.)', string.upper, 1)
	if(_G[unit..'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[unit..'FrameDropDown'], 'cursor')
	end
end

-- ------------------------------------------------------------------------
-- reformat everything above 9999, i.e. 10000 -> 10k
-- ------------------------------------------------------------------------
local truncate = function(value)
	if(value >= 1e6) then
		return sformat('%dm', value / 1e6)
	elseif(value >= 1e4) then
		return sformat('%dk', value / 1e3)
	else
		return value
	end
end

-- ------------------------------------------------------------------------
-- returns the hex code of a rgb value
-- ------------------------------------------------------------------------
local rgbtohex = function(r, g, b)
	if type(r) == "table" then
		if r.r then
			r, g, b = r.r, r.g, r.b
		else
			r, g, b = unpack(r)
		end
	end
	return sformat("|cff%02x%02x%02x", r*255, g*255, b*255)
end

-- ------------------------------------------------------------------------
-- name update
-- ------------------------------------------------------------------------
oUF.Tags['[name]'] = function(u, r)
	return UnitName(r or u):lower() or ''
end

-- ------------------------------------------------------------------------
-- level update
-- ------------------------------------------------------------------------
local GetDifficultyColor = function(level)
	local levelDiff = UnitLevel('target') - UnitLevel('player')

	if level == '??' then
		return	.69,.31,.31
	elseif levelDiff >= 5 then
		return .69,.31,.31
	elseif levelDiff >= 3 then
		return .71,.43,.27
	elseif levelDiff >= -2 then
		return .84,.75,.65
	elseif -levelDiff <= GetQuestGreenRange() then
		return .33,.59,.33
	else
		return	.55,.57,.61
	end
end

oUF.Tags['[blommalevel]'] = function(u)
	local l = not UnitIsConnected(u) and '??' or UnitLevel(u) < 1 and '??' or UnitLevel(u)
	local c = UnitClassification(u)
	local r,g,b = GetDifficultyColor(level)
	local rs = c == "rare" and l.."R" or c == "eliterare" and l.."R+" or c == "elite" and l.."+" or c == "worldboss" and l.."B" or l
	return string.format("|cff%02x%02x%02x"..rs.. "|r", r*255, g*255, b*255)
end
oUF.TagEvents["[blommalevel]"] = "UNIT_LEVEL PLAYER_LEVEL_UP"

-- ------------------------------------------------------------------------
-- health update
-- ------------------------------------------------------------------------
local PostUpdateHealth = function(self, event, unit, bar, min, max)
	if(UnitIsDead(unit)) then
		bar:SetValue(0)
		bar.value:SetText("Dead")
	elseif(UnitIsGhost(unit)) then
		bar:SetValue(0)
		bar.value:SetText("Ghost")
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText("Offline")
	elseif(unit == "player" or unit=="target" or unit=="pet" or unit == "targettarget") then
		if(min ~= max) then
			bar.value:SetText("|cff33EE44"..truncate(min) .."|r.".. floor(min/max*100).."%")
		else
			bar.value:SetText()
		end
	else
		bar.value:SetText()
	end
end

-- ------------------------------------------------------------------------
-- power update
-- ------------------------------------------------------------------------
local PostUpdatePower = function(self, event, unit, bar, min, max)
	local ptype, ptypestr = UnitPowerType(unit)
	local color = oUF.colors.power[ptypestr]
	if(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText()
	elseif(unit=="player" or unit=="pet") then
		if(min==max or (ptype==6 and min == 0)) then
			bar.value:SetText()
		elseif(ptype==1 or ptype==3 or ptype==6 or ptype==2) then
			bar.value:SetText(rgbtohex(color)..truncate(min).."|r")
		else
			bar.value:SetText(rgbtohex(color)..truncate(min).."|r.".. floor(min/max*100).."%")
		end
	end
end

-- ------------------------------------------------------------------------
-- aura reskin
-- ------------------------------------------------------------------------
local PostCreateAuraIcon = function(self, button, icons)
	icons.showDebuffType = true

	local icon = button.icon
	icon:SetTexCoord(.07, .93, .07, .93)
	icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)

	local overlay = button.overlay
	overlay:SetTexture(bufftex)
	overlay:SetTexCoord(0,1,0,1)
	overlay.Hide = function(self) self:SetVertexColor(0.3, 0.3, 0.3) end

	local cd = button.cd
	cd:SetReverse()
	cd:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
	cd:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
end

-- ------------------------------------------------------------------------
-- aura sorting
-- ------------------------------------------------------------------------
local sortunit
local sortIcons = function(a, b)
	local aet = select(7, UnitAura(sortunit, a:GetID(), a.filter)) or -1
	local bet = select(7, UnitAura(sortunit, b:GetID(), b.filter)) or -1

	return aet > bet
end

local SetAuraPosition = function(self, icons, x)
	if(icons and x > 0) then
		if( icons.visibleDebuffs ) then
			sortunit = self.unit
			sort(icons, sortIcons)
		end

		local col = 0
		local row = 0
		local spacing = icons.spacing or 0
		local gap = icons.gap
		local size = (icons.size or 16) + spacing
		local anchor = icons.initialAnchor or "BOTTOMLEFT"
		local growthx = (icons["growth-x"] == "LEFT" and -1) or 1
		local growthy = (icons["growth-y"] == "DOWN" and -1) or 1
		local cols = math.floor(icons:GetWidth() / size + .5)
		local rows = math.floor(icons:GetHeight() / size + .5)

		for i = 1, x do
			local button = icons[i]
			if(button and button:IsShown()) then
				if(gap and button.debuff) then
					if(col > 0) then
						col = col + 1
					end

					gap = false
				end

				if(col >= cols) then
					col = 0
					row = row + 1
				end
				button:ClearAllPoints()
				button:SetPoint(anchor, icons, anchor, col * size * growthx, row * size * growthy)

				col = col + 1
			end
		end
	end
end

-- ------------------------------------------------------------------------
-- the layout starts here
-- ------------------------------------------------------------------------
local SetStyle = function(self, unit)
	self.menu = menu
	self.colors = colors

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks("anyup")
	self:SetAttribute("*type2", "menu")

	--
	-- background
	--
	self:SetBackdrop{
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
		insets = {left = -2, right = -2, top = -2, bottom = -2},
	}
	self:SetBackdropColor(0,0,0,1)

	--
	-- healthbar
	--
	self.Health = CreateFrame"StatusBar"
	self.Health:SetHeight(19)
	self.Health:SetStatusBarTexture(bartex)
	self.Health:SetParent(self)
	self.Health:SetPoint"TOP"
	self.Health:SetPoint"LEFT"
	self.Health:SetPoint"RIGHT"
	--
	-- healthbar background
	--
	self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(bartex)
	self.Health.bg:SetAlpha(0.30)

	--
	-- healthbar text
	--
	self.Health.value = self.Health:CreateFontString(nil, "OVERLAY")
	self.Health.value:SetPoint("RIGHT", -2, 2)
	self.Health.value:SetFont(font, fontsize, "OUTLINE")
	self.Health.value:SetTextColor(1,1,1)
	self.Health.value:SetShadowOffset(1, -1)

	--
	-- healthbar functions
	--
	self.Health.colorTapping = true
	self.Health.colorDisconnected = true
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.frequentUpdates = true
	self.PostUpdateHealth = PostUpdateHealth

	--
	-- powerbar
	--
	self.Power = CreateFrame"StatusBar"
	self.Power:SetHeight(3)
	self.Power:SetStatusBarTexture(bartex)
	self.Power:SetParent(self)
	self.Power:SetPoint"LEFT"
	self.Power:SetPoint"RIGHT"
	self.Power:SetPoint("TOP", self.Health, "BOTTOM", 0, -1.45) -- Little offset to make it pretty

	--
	-- powerbar background
	--
	self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
	self.Power.bg:SetAllPoints(self.Power)
	self.Power.bg:SetTexture(bartex)
	self.Power.bg:SetAlpha(0.30)

	--
	-- powerbar text
	--
	self.Power.value = self.Power:CreateFontString(nil, "OVERLAY")
	self.Power.value:SetPoint("RIGHT", self.Health.value, "BOTTOMRIGHT", 0, -5)
	self.Power.value:SetFont(font, fontsize, "OUTLINE")
	self.Power.value:SetTextColor(1,1,1)
	self.Power.value:SetShadowOffset(1, -1)
	self.Power.value:Hide()

	--
	-- powerbar functions
	--
	self.Power.colorTapping = true
	self.Power.colorDisconnected = true
	self.Power.colorClass = true
	self.Power.colorPower = true
	self.Power.frequentUpdates = true
	self.PostUpdatePower = PostUpdatePower

	--
	-- names
	--
	self.Name = self.Health:CreateFontString(nil, "OVERLAY")
	self.Name:SetPoint("LEFT", self, 0, 9)
	self.Name:SetJustifyH"LEFT"
	self.Name:SetFont(font, fontsize, "OUTLINE")
	self.Name:SetShadowOffset(1, -1)
	self.Name:SetTextColor(1,1,1)
	self:Tag(self.Name, '[name]')

	--
	-- oUF_BarFader
	--
	if(IsAddOnLoaded('oUF_BarFader')) then
		self.BarFade = true
	end

	-- ------------------------------------
	-- player
	-- ------------------------------------
	if unit=="player" then
		self:SetWidth(250)
		self:SetHeight(20)
		self.Health:SetHeight(15.5)
		self.Name:Hide()
		self.Health.value:SetPoint("RIGHT", 0, 9)
		self.Power:SetHeight(3)
		self.Power.value:Show()
		self.Power.value:SetPoint("LEFT", self.Health, 0, 9)
		self.Power.value:SetJustifyH"LEFT"

		--
		-- leader icon
		--
		self.Leader = self.Health:CreateTexture(nil, "OVERLAY")
		self.Leader:SetHeight(12)
		self.Leader:SetWidth(12)
		self.Leader:SetPoint("BOTTOMRIGHT", self, -2, 4)
		self.Leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"

		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(16)
		self.RaidIcon:SetWidth(16)
		self.RaidIcon:SetPoint("TOP", self, 0, 9)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
	end

	-- ------------------------------------
	-- pet
	-- ------------------------------------
	if unit=="pet" then
		self:SetWidth(120)
		self:SetHeight(18)
		self.Health:SetHeight(15.5)
		self.Name:Hide()
		self.Health.value:SetPoint("RIGHT", 0, 9)
		self.Power:SetHeight(3)
		self.Power.value:Show()
		self.Power.value:SetPoint("LEFT", self.Health, 0, 9)
		self.Power.value:SetJustifyH"LEFT"

		if playerClass=="HUNTER" then
			self.Health.colorReaction = false
			self.Health.colorClass = false
			self.Health.colorHappiness = true
		end

		--
		-- buffs
		--
		self.Buffs = CreateFrame("Frame", nil, self)
		self.Buffs.size = 29
		self.Buffs:SetHeight(self.Buffs.size)
		self.Buffs:SetWidth(self.Buffs.size * 4)
		self.Buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -2, -5)
		self.Buffs.initialAnchor = "TOPLEFT"
		self.Buffs["growth-y"] = "DOWN"
		self.Buffs.filter = false
		self.Buffs.num = 20
		self.Buffs.spacing = 2

		--
		-- combo points
		--
		self.CPoints = self:CreateFontString(nil, "OVERLAY")
		self.CPoints:SetPoint("RIGHT", self, "LEFT", -10, 0)
		self.CPoints:SetFont(font, 38, "OUTLINE")
		self.CPoints:SetTextColor(0, 0.81, 1)
		self.CPoints:SetShadowOffset(1, -1)
		self.CPoints:SetJustifyH"RIGHT"

		--
		-- custom aura textures
		--
		self.PostCreateAuraIcon = PostCreateAuraIcon
	end

	-- ------------------------------------
	-- target
	-- ------------------------------------
	if unit=="target" then
		--
		-- level
		--
		self.Level = self.Health:CreateFontString(nil, "OVERLAY")
		self.Level:SetPoint("LEFT", self.Health, 0, 9)
		self.Level:SetJustifyH("LEFT")
		self.Level:SetFont(font, fontsize, "OUTLINE")
		self.Level:SetTextColor(1,1,1)
		self.Level:SetShadowOffset(1, -1)
		self:Tag(self.Level, '[blommalevel]')

		self:SetWidth(250)
		self:SetHeight(20)
		self.Health:SetHeight(15.5)
		self.Power:SetHeight(3)
		self.Power.value:Hide()
		self.Health.value:SetPoint("RIGHT", 0, 9)
		self.Name:SetPoint("LEFT", self.Level, "RIGHT", 0, 0)
		self.Name:SetHeight(20)
		self.Name:SetWidth(150)

		--
		-- combo points
		--
		self.CPoints = self:CreateFontString(nil, "OVERLAY")
		self.CPoints:SetPoint("RIGHT", self, "LEFT", -10, 0)
		self.CPoints:SetFont(font, 38, "OUTLINE")
		self.CPoints:SetTextColor(0, 0.81, 1)
		self.CPoints:SetShadowOffset(1, -1)
		self.CPoints:SetJustifyH("RIGHT")
		self.CPoints.unit = 'player'

		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(24)
		self.RaidIcon:SetWidth(24)
		self.RaidIcon:SetPoint("RIGHT", self, 30, 0)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"

		--
		-- buffs
		--
		self.Buffs = CreateFrame("Frame", nil, self)
		self.Buffs.size = 22
		self.Buffs:SetHeight(self.Buffs.size)
		self.Buffs:SetWidth(self.Buffs.size * 5)
		self.Buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -2, 15)
		self.Buffs.initialAnchor = "BOTTOMLEFT"
		self.Buffs["growth-y"] = "TOP"
		self.Buffs.filter = "HELPFUL"
		self.Buffs.num = 40
		self.Buffs.spacing = 2

		--
		-- debuffs
		--
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs.size = 35
		self.Debuffs:SetHeight(self.Debuffs.size)
		self.Debuffs:SetWidth(self.Debuffs.size * 5)
		self.Debuffs:SetPoint('CENTER', UIParent, 'CENTER', 0, -80)
		self.Debuffs.initialAnchor = "TOPLEFT"
		self.Debuffs["growth-y"] = "TOP"
		self.Debuffs.filter = "HARMFUL|PLAYER"
		self.Debuffs.num = 10
		self.Debuffs.spacing = 2

		--
		-- Aura debuff sorting
		--
		self.SetAuraPosition = SetAuraPosition

		--
		-- custom aura textures
		--
		self.PostCreateAuraIcon = PostCreateAuraIcon
	end

	-- ------------------------------------
	-- target of target and focus
	-- ------------------------------------
	if unit=="targettarget" or unit=="focus" then
		self:SetWidth(120)
		self:SetHeight(18)
		self.Health:SetHeight(18)
		self.Power:Hide()
		self.Power.value:Hide()
		self.Health.value:Hide()
		self.Name:SetWidth(95)
		self.Name:SetHeight(18)
		self.Name:SetTextColor(0.9, 0.5, 0.2)

		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(16)
		self.RaidIcon:SetWidth(16)
		self.RaidIcon:SetPoint("RIGHT", self, 0, 9)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
	end

	-- ------------------------------------
	-- player and target castbar
	-- ------------------------------------
	if(unit == 'player' or unit == 'target') then
		self.Castbar = CreateFrame('StatusBar', nil, self)
		self.Castbar:SetStatusBarTexture(bartex)

		if(unit == "player") then
			self.Castbar:SetStatusBarColor(1, 0.50, 0)
			self.Castbar:SetHeight(20)
			self.Castbar:SetWidth(250)

			self.Castbar:SetBackdrop({
				bgFile = "Interface\ChatFrame\ChatFrameBackground",
				insets = {top = -3, left = -3, bottom = -3, right = -3}})

			self.Castbar.SafeZone = self.Castbar:CreateTexture(nil,"ARTWORK")
			self.Castbar.SafeZone:SetTexture(bartex)
			self.Castbar.SafeZone:SetVertexColor(.75,.10,.10,.6)
			self.Castbar.SafeZone:SetPoint("TOPRIGHT")
			self.Castbar.SafeZone:SetPoint("BOTTOMRIGHT")
			self.Castbar:SetPoint('CENTER', UIParent, 'CENTER', 0, -230)
		else
			self.Castbar:SetStatusBarColor(0.80, 0.01, 0)
			self.Castbar:SetHeight(20)
			self.Castbar:SetWidth(250)

			self.Castbar:SetBackdrop({
				bgFile = "Interface\ChatFrame\ChatFrameBackground",
				insets = {top = -3, left = -30, bottom = -3, right = -3}})

			self.Castbar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -5)
		end

		self.Castbar:SetBackdropColor(0, 0, 0, 0.5)

		self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BORDER')
		self.Castbar.bg:SetAllPoints(self.Castbar)
		self.Castbar.bg:SetTexture(0, 0, 0, 0.6)

		self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY')
		self.Castbar.Text:SetPoint('LEFT', self.Castbar, 2, 0)
		self.Castbar.Text:SetFont(upperfont, 11, "OUTLINE")
		self.Castbar.Text:SetShadowOffset(1, -1)
		self.Castbar.Text:SetTextColor(1, 1, 1)
		self.Castbar.Text:SetJustifyH('LEFT')

		self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY')
		self.Castbar.Time:SetPoint('RIGHT', self.Castbar, -2, 0)
		self.Castbar.Time:SetFont(upperfont, 12, "OUTLINE")
		self.Castbar.Time:SetTextColor(1, 1, 1)
		self.Castbar.Time:SetJustifyH('RIGHT')
	end

	-- ------------------------------------
	-- autoshot bar
	-- ------------------------------------
	if(IsAddOnLoaded('oUF_AutoShot') and playerClass == 'HUNTER' and unit == 'player') then
		self.AutoShot = CreateFrame('StatusBar', nil, self)
		self.AutoShot:SetPoint('BOTTOMLEFT', self.Castbar, 'TOPLEFT', 0, 5)
		self.AutoShot:SetStatusBarTexture(bartex)
		self.AutoShot:SetStatusBarColor(1, 0.7, 0)
		self.AutoShot:SetHeight(6)
		self.AutoShot:SetWidth(250)
		self.AutoShot:SetBackdrop({
			bgFile = "Interface\ChatFrame\ChatFrameBackground",
			insets = {top = -3, left = -3, bottom = -3, right = -3}})
		self.AutoShot:SetBackdropColor(0, 0, 0)

		self.AutoShot.Text = self.AutoShot:CreateFontString(nil, 'OVERLAY')
		self.AutoShot.Text:SetPoint('CENTER', self.AutoShot)
		self.AutoShot.Text:SetFont(upperfont, 11, "OUTLINE")
		self.AutoShot.Text:SetShadowOffset(1, -1)
		self.AutoShot.Text:SetTextColor(1, 1, 1)

		self.AutoShot.bg = self.AutoShot:CreateTexture(nil, 'BORDER')
		self.AutoShot.bg:SetAllPoints(self.AutoShot)
		self.AutoShot.bg:SetTexture(0.3, 0.3, 0.3)
	end

	-- ------------------------------------
	-- party
	-- ------------------------------------
	if(self:GetParent():GetName():match"oUF_Party") then
		self:SetWidth(160)
		self:SetHeight(20)
		self.Health:SetHeight(15)
		self.Power:SetHeight(3)
		self.Power.value:Hide()
		self.Health.value:SetPoint("RIGHT", 0 , 9)
		self.Name:SetPoint("LEFT", 0, 9)
	end

	-- ------------------------------------
	-- raid
	-- ------------------------------------
	if(self:GetParent():GetName():match"oUF_Raid") then
		self:SetWidth(50)
		self:SetHeight(15)
		self.Health:SetHeight(13)
		self.Power:SetHeight(2)
		self.Health:SetFrameLevel(2)
		self.Power:SetFrameLevel(2)
		self.Health.value:Hide()
		self.Power.value:Hide()
		self.Name:SetFont(font, 9, "OUTLINE")
		self.Name:SetWidth(50)
		self.Name:SetHeight(15)
	end

	self.disallowVehicleSwap = true

	if(self:GetParent():GetName():match"oUF_Party") then
		self:SetAttribute('initial-height', 20)
		self:SetAttribute('initial-width', 160)
	else
		self:SetAttribute('initial-height', height)
		self:SetAttribute('initial-width', width)
	end

	return self
end

-- ------------------------------------------------------------------------
-- spawning the frames
-- ------------------------------------------------------------------------

--
-- normal frames
--
oUF:RegisterStyle("Blomma", SetStyle)
oUF:SetActiveStyle("Blomma")

oUF:Spawn("player", "oUF_Player"):SetPoint("CENTER", -280, -106)
oUF:Spawn("target", "oUF_Target"):SetPoint("CENTER", 280, -106)
oUF:Spawn("pet", "oUF_Pet"):SetPoint("BOTTOMLEFT", oUF.units.player, 0, -30)
oUF:Spawn("targettarget", "oUF_TargetTarget"):SetPoint("TOPRIGHT", oUF.units.target, 0, 35)
oUF:Spawn("focus", "oUF_Focus"):SetPoint("BOTTOMRIGHT", oUF.units.player, 0, -30)

--
-- party
--
local party = oUF:Spawn("header", "oUF_Party")
party:SetManyAttributes("showParty", true, "yOffset", -15, "showPlayer", false)
party:SetPoint("TOPLEFT", 20, -20)
party:Show()

--
-- raid
--
local Raid = {}
for i = 1, NUM_RAID_GROUPS do
	local RaidGroup = oUF:Spawn("header", "oUF_Raid" .. i)
	RaidGroup:SetAttribute("groupFilter", tostring(i))
	RaidGroup:SetAttribute("showRaid", true)
	RaidGroup:SetAttribute("yOffset", -10)
	RaidGroup:SetAttribute("point", "TOP")
	RaidGroup:SetAttribute("sortDir", "ASC")
	RaidGroup:SetAttribute("showRaid", true)
	RaidGroup:SetAttribute("showParty", false)
	table.insert(Raid, RaidGroup)
	if i == 1 then
		RaidGroup:SetPoint("TOPLEFT", UIParent, 20, -20)
	else
		RaidGroup:SetPoint("TOPLEFT", Raid[i-1], "TOPRIGHT", 10, 0)
	end
	RaidGroup:Show()
end

--
-- party toggle in raid
--
local partyToggle = CreateFrame('Frame')
partyToggle:RegisterEvent('PLAYER_LOGIN')
partyToggle:RegisterEvent('RAID_ROSTER_UPDATE')
partyToggle:RegisterEvent('PARTY_LEADER_CHANGED')
partyToggle:RegisterEvent('PARTY_MEMBER_CHANGED')
partyToggle:SetScript('OnEvent', function(self)
	if(InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
	else
		self:UnregisterEvent('PLAYER_REGEN_DISABLED')
		if(UnitInRaid("player")) then
			party:Hide()
		else
			party:Show()
		end
	end
end)
