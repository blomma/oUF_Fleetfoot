--[[

	oUF_Fleetfoot

	Author:		Fleetfoot
	Mail:		blomma@gmail.com

	Credits:	oUF_Lyn (used as base) / http://www.wowinterface.com/downloads/info10326-oUF_Lyn.html
				oUF_Caellian (inspiration and code) / http://www.wowinterface.com/downloads/info9974.html

--]]

local print = function(a) ChatFrame1:AddMessage("|cff33ff99oUF:|r "..tostring(a)) end

-- ------------------------------------------------------------------------
-- local horror
-- ------------------------------------------------------------------------
local select = select
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitIsConnected = UnitIsConnected
local UnitAura = UnitAura
local UnitPowerType = UnitPowerType
local floor = math.floor
local format = string.format
local GetTime = GetTime

-- ------------------------------------------------------------------------
-- font, fontsize and textures
-- ------------------------------------------------------------------------
local font = [=[Interface\AddOns\oUF_Fleetfoot\fonts\font.ttf]=]
local upperfont = [=[Interface\AddOns\oUF_Fleetfoot\fonts\upperfont.ttf]=]
local fontsize = 15
local bartex = [=[Interface\AddOns\oUF_Fleetfoot\textures\statusbar]=]
local bufftex = [=[Interface\AddOns\oUF_Fleetfoot\textures\border]=]
local normTex = [=[Interface\Addons\oUF_Fleetfoot\textures\normTex]=]
local revTex = [=[Interface\Addons\oUF_Fleetfoot\textures\normTex]=]

local class = select(2, UnitClass("player"))

local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], tile = true, tileSize = 16,
	insets = {left = -2, right = -2, top = -2, bottom = -2},
}

-- ------------------------------------------------------------------------
-- change some colors
-- ------------------------------------------------------------------------
local runeloadcolors = {
	[1] = {0.69, 0.31, 0.31},
	[2] = {0.69, 0.31, 0.31},
	[3] = {0.33, 0.59, 0.33},
	[4] = {0.33, 0.59, 0.33},
	[5] = {0.31, 0.45, 0.63},
	[6] = {0.31, 0.45, 0.63},
}

local colors = setmetatable({
	happiness = setmetatable({
		[1] = {182/225, 34/255, 32/255},	-- unhappy
		[2] = {220/225, 180/225, 52/225},	-- content
		[3] = {143/255, 194/255, 32/255},	-- happy
	}, {__index = oUF.colors.happiness}),
	runes = setmetatable({
		[1] = {0.69, 0.31, 0.31},
		[2] = {0.33, 0.59, 0.33},
		[3] = {0.31, 0.45, 0.63},
		[4] = {0.84, 0.75, 0.65},
	}, {__index = oUF.colors.runes}),
}, {__index = oUF.colors})

-- ------------------------------------------------------------------------
-- these auras we dont need to see and are handled by my Filter addon instead
-- ------------------------------------------------------------------------
local auraFilter = {
	[GetSpellInfo(34074)] = true, -- Hunter: Aspect of the Viper
	[GetSpellInfo(61847)] = true, -- Hunter: Aspect of the Dragonhawk Rank 2
	[GetSpellInfo(61609)] = true, -- Hunter, Vicious Viper
}

-- ------------------------------------------------------------------------
-- right click
-- ------------------------------------------------------------------------
local function menu(self)
	local unit = string.gsub(self.unit, '(.)', string.upper, 1)
	if(_G[unit..'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[unit..'FrameDropDown'], 'cursor')
	elseif(self.unit:match('party')) then
		ToggleDropDownMenu(1, nil, _G['PartyMemberFrame'..self.id..'DropDown'], 'cursor')
	else
		FriendsDropDown.unit = self.unit
		FriendsDropDown.id = self.id
		FriendsDropDown.initialize = RaidFrameDropDown_Initialize
		ToggleDropDownMenu(1, nil, FriendsDropDown, 'cursor')
	end
end

-- ------------------------------------------------------------------------
-- reformat everything above 9999, i.e. 10000 -> 10k
-- ------------------------------------------------------------------------
local function ShortValue(value)
	if(value >= 1e6) then
		return format('%dm', value / 1e6)
	elseif(value >= 1e4) then
		return format('%dk', value / 1e3)
	else
		return value
	end
end

local day, hour, minute, tenseconds = 86400, 3600, 60, 10
local function GetFormattedTime(s)
	if s >= day then
		return format('%dd', floor(s/day + 0.5)), s % day
	elseif s >= hour then
		return format('%dh', floor(s/hour + 0.5)), s % hour
	elseif s >= minute then
		return format('%dm', floor(s/minute + 0.5)), s % minute
	elseif s >= tenseconds then
		return format('%d', floor(s + 0.5)), s - floor(s)
	else
		return format('%.1f', floor(s*10)/10), 0.1
	end
end

-- ------------------------------------------------------------------------
-- custom tags
-- ------------------------------------------------------------------------
oUF.Tags['[name]'] = function(u, r)
	return UnitName(r or u):lower() or ''
end

oUF.Tags['[diffcolor]']  = function(unit)
	local r, g, b
	local level = UnitLevel(unit)
	if level < 1 then
		r, g, b = .69,.31,.31
	else
		local diffcolor = UnitLevel('target') - UnitLevel('player')
		if diffcolor >= 5 then
			r, g, b = .69,.31,.31
		elseif diffcolor >= 3 then
			r, g, b = .71,.43,.27
		elseif diffcolor >= -2 then
			r, g, b = .84,.75,.65
		elseif -diffcolor <= GetQuestGreenRange() then
			r, g, b = .33,.59,.33
		else
			r, g, b = .55,.57,.61
		end
	end
	return format('|cff%02x%02x%02x', r*255, g*255, b*255)
end

oUF.TagEvents['[diffcolor]'] = 'UNIT_LEVEL'

-- ------------------------------------------------------------------------
-- health update
-- ------------------------------------------------------------------------
local function PostUpdateHealth(self, event, unit, bar, min, max)
	if(UnitIsDead(unit)) then
		bar:SetValue(0)
		if bar.value then
			bar.value:SetText("Dead")
		end
	elseif(UnitIsGhost(unit)) then
		bar:SetValue(0)
		if bar.value then
			bar.value:SetText("Ghost")
		end
	elseif(not UnitIsConnected(unit)) then
		bar:SetValue(0)
		if bar.value then
			bar.value:SetText("Offline")
		end
	elseif(unit == "player" or unit=="target" or unit=="pet") then
		if(min ~= max) then
			bar.value:SetFormattedText('|cff33EE44%s|r.%d%%', ShortValue(min), floor(min/max*100))
		else
			bar.value:SetText()
		end
	end
end

-- ------------------------------------------------------------------------
-- power update
-- ------------------------------------------------------------------------
local function PostUpdatePower(self, event, unit, bar, min, max)
	local ptype, ptypestr = UnitPowerType(unit)
	if(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	elseif(not UnitIsConnected(unit)) then
		if bar.value then
			bar.value:SetText()
		end
	elseif(unit=="player" or unit=="pet") then
		local r,g,b = unpack(oUF.colors.power[ptypestr])
		if(min==max or (ptype==6 and min == 0)) then
			bar.value:SetText()
		elseif(ptype==1 or ptype==3 or ptype==6 or ptype==2) then
			bar.value:SetFormattedText('|cff%02x%02x%02x%s|r', r * 255, g * 255, b * 255, ShortValue(min))
		else
			bar.value:SetFormattedText('|cff%02x%02x%02x%s|r.%d%%', r * 255, g * 255, b * 255, ShortValue(min), floor(min/max*100))
		end
	end
end

-- ------------------------------------------------------------------------
-- aura
-- ------------------------------------------------------------------------
local function UpdateAuraTimer(self,elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed >= 0.1 then
		self.timeLeft = self.timeLeft - self.elapsed
		self.remaining:SetText(GetFormattedTime(self.timeLeft))
		self.elapsed = 0
	end
end

local function PostCreateAuraIcon(self, button, icons, index, debuff)
	icons.showDebuffType = true

	button.icon:SetTexCoord(.07, .93, .07, .93)

	local overlay = button.overlay
	overlay:SetTexture(bufftex)
	overlay:SetTexCoord(0,1,0,1)
	overlay.Hide = function(self) self:SetVertexColor(0.3, 0.3, 0.3) end

	local cd = button.cd
	cd:SetReverse()
	cd.noOCC = true
	cd.noCooldownCount = true

	if (self.unit == 'player') then
		button:SetScript('OnMouseUp', function(self, mouseButton)
			if mouseButton == 'RightButton' and not self.debuff then
				CancelUnitBuff('player', self:GetID())
			end
		end)
	end

	if icons ~= self.Enchant then
		local remaining = button.cd:CreateFontString(nil, 'OVERLAY')
		remaining:Hide()

		remaining:SetFont(font, 12, 'OUTLINE')
		remaining:SetTextColor(0.84, 0.75, 0.65)
		remaining:SetJustifyH('LEFT')
		remaining:SetShadowColor(0, 0, 0)
		remaining:SetShadowOffset(1.25, -1.25)
		remaining:SetPoint('TOPLEFT', 1.5, 3)
		
		button.remaining = remaining
	end
end

local function PostUpdateAuraIcon(self, icons, unit, icon, index, offset, filter, debuff)
	if icons ~= self.Enchant then
		local _, _, _, _, _, _, timeLeft, _ = UnitAura(unit, index, filter)
		if(timeLeft > 0) then
			icon.timeLeft = timeLeft - GetTime()
			icon.elapsed = 0
			icon.remaining:Show()
			icon:SetScript('OnUpdate', UpdateAuraTimer)
		else
			icon.remaining:Hide()
			icon:SetScript('OnUpdate', nil)
		end
	end
end

local function CustomAuraFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, expiration, caster)
	if (auraFilter[name] and caster == 'player') then
		return false
	else
		return true
	end
end

local function HidePortrait(self, unit)
	if (self.unit == 'target') then
		if (not UnitExists(self.unit) or not UnitIsConnected(self.unit) or not UnitIsVisible(self.unit)) then
			self.Portrait:SetAlpha(0)
		else
			self.Portrait:SetAlpha(1)
		end
	end
end

-- ------------------------------------------------------------------------
-- aura sorting
-- ------------------------------------------------------------------------
local incs = { 23, 10, 4, 1 }
local incsCount = #incs
local function shellsort(t, n, before)
	for ii=1,incsCount do
		local h = incs[ii]
		for i = h + 1, n do
			local v = t[i]
			for j = i - h, 1, -h do
				local testval = t[j]
				if not before(v, testval) then break end
				t[i] = testval
				i = j
			end
			t[i] = v
		end
    end
end

local function sortTarget(a, b)
	if(a.timeLeft == nil) then
		return true
	elseif(b.timeLeft == nil) then
		return false
	else
		return a.timeLeft > b.timeLeft
	end
end

local function sortPlayer(a, b)
	if(a.timeLeft == 0) then
		return true
	elseif(b.timeLeft == 0) then
		return false
	else
		return a.timeLeft > b.timeLeft
	end
end

local function SetAuraPosition(self, icons, x)
	if(icons and x > 0) then
		if(icons.visibleDebuffs and self.unit == 'target') then
			shellsort(icons, #icons, sortTarget)
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
-- remove the blizz frames
-- ------------------------------------------------------------------------
BuffFrame:Hide()
TemporaryEnchantFrame:Hide()

-- ------------------------------------------------------------------------
-- the layout starts here
-- ------------------------------------------------------------------------
local function SetStyle(self, unit)
	self.menu = menu
	self.colors = colors

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks("anyup")
	self:SetAttribute("*type2", "menu")

	--
	-- background
	--
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0,0,0,1)

	--
	-- healthbar
	--
	self.Health = CreateFrame("StatusBar", nil, self)
	self.Health:SetStatusBarTexture(bartex)
	self.Health:SetPoint("TOP")
	self.Health:SetPoint("LEFT")
	self.Health:SetPoint("RIGHT")
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
	if not self:GetParent():GetName():match("oUF_Party") and
			not self:GetParent():GetName():match("oUF_Raid") and
			unit ~= 'targettarget' and
			unit ~= 'focus' then
		self.Health.value = self.Health:CreateFontString(nil, "OVERLAY")
		self.Health.value:SetPoint("RIGHT", -2, 2)
		self.Health.value:SetFont(font, fontsize, "OUTLINE")
		self.Health.value:SetTextColor(1,1,1)
		self.Health.value:SetShadowOffset(1, -1)
	end
	--
	-- healthbar functions
	--
	self.Health.colorTapping = true
	self.Health.colorDisconnected = true
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.frequentUpdates = 0.1
	self.PostUpdateHealth = PostUpdateHealth

	--
	-- powerbar
	--
	self.Power = CreateFrame("StatusBar", nil, self)
	self.Power:SetHeight(3)
	self.Power:SetStatusBarTexture(bartex)
	self.Power:SetPoint("TOP", self.Health, "BOTTOM", 0, -1.5)
	self.Power:SetPoint("LEFT")
	self.Power:SetPoint("RIGHT")

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
	if unit ~= 'target' and not self:GetParent():GetName():match("oUF_Party") and not self:GetParent():GetName():match("oUF_Raid") then
		self.Power.value = self.Power:CreateFontString(nil, "OVERLAY")
		self.Power.value:SetPoint("RIGHT", self.Health.value, "BOTTOMRIGHT", 0, -5)
		self.Power.value:SetFont(font, fontsize, "OUTLINE")
		self.Power.value:SetTextColor(1,1,1)
		self.Power.value:SetShadowOffset(1, -1)
	end
	--
	-- powerbar functions
	--
	self.Power.colorTapping = true
	self.Power.colorDisconnected = true
	self.Power.colorClass = true
	self.Power.colorPower = true
	self.PostUpdatePower = PostUpdatePower

	--
	-- names
	--
	if unit ~= 'player' and unit ~= 'pet' then
		self.Name = self.Health:CreateFontString(nil, "OVERLAY")
		self.Name:SetPoint("LEFT", self, 0, 9)
		self.Name:SetJustifyH("LEFT")
		self.Name:SetFont(font, fontsize, "OUTLINE")
		self.Name:SetShadowOffset(1, -1)
		self.Name:SetTextColor(1,1,1)
		self:Tag(self.Name, '[name]')
	end
	--
	-- leader icon
	--
	self.Leader = self.Health:CreateTexture(nil, "OVERLAY")
	self.Leader:SetHeight(12)
	self.Leader:SetWidth(12)
	self.Leader:SetPoint("BOTTOMRIGHT", self, 5, -2)

	-- ------------------------------------
	-- player
	-- ------------------------------------
	if(unit == "player") then
		self:SetWidth(250)
		self:SetHeight(46)

		self.Health:SetHeight(15.5)
		self.Health.value:SetPoint("RIGHT", 0, 9)

		self.Power:SetPoint("TOP", self.Health, "BOTTOM", 0, -27.5)
		self.Power.value:SetPoint("LEFT", self.Health, 0, 9)
		self.Power.value:SetJustifyH("LEFT")
		self.Power.frequentUpdates = 0.1

		--
		-- buffs
		--
		self.Buffs = CreateFrame("Frame", nil, self)
		self.Buffs.size = 30
		self.Buffs:SetHeight(self.Buffs.size)
		self.Buffs:SetWidth(self.Buffs.size * 10)
		self.Buffs:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -170, -10)
		self.Buffs.initialAnchor = "TOPRIGHT"
		self.Buffs["growth-y"] = "DOWN"
		self.Buffs["growth-x"] = "LEFT"
		self.Buffs.filter = "HELPFUL"
		self.Buffs.num = 40
		self.Buffs.spacing = 4

		--
		-- debuffs
		--
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs.size = 40
		self.Debuffs:SetHeight(self.Debuffs.size)
		self.Debuffs:SetWidth(self.Debuffs.size * 10)
		self.Debuffs:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -170, -150)
		self.Debuffs.initialAnchor = "TOPRIGHT"
		self.Debuffs["growth-y"] = "DOWN"
		self.Debuffs["growth-x"] = "LEFT"
		self.Debuffs.filter = "HARMFUL"
		self.Debuffs.num = 10
		self.Debuffs.spacing = 4

		self.PostCreateEnchantIcon = PostCreateAuraIcon

		--
		-- custom aura textures
		--
		self.PostCreateAuraIcon = PostCreateAuraIcon
		self.PostUpdateAuraIcon = PostUpdateAuraIcon

		self.CustomAuraFilter = CustomAuraFilter
	end

	-- ------------------------------------
	-- pet
	-- ------------------------------------
	if(unit == "pet") then
		self:SetWidth(120)
		self:SetHeight(20)

		self.Health:SetHeight(15.5)
		self.Health.value:SetPoint("RIGHT", 0, 9)

		self.Power.value:SetPoint("LEFT", self.Health, 0, 9)
		self.Power.value:SetJustifyH("LEFT")
		self.Power.frequentUpdates = 0.1

		if(class == "HUNTER") then
			self.Health.colorReaction = false
			self.Health.colorClass = false
			self.Health.colorHappiness = true
		end

		--
		-- buffs
		--
		self.Auras = CreateFrame("Frame", nil, self)
		self.Auras.size = 22
		self.Auras:SetHeight(self.Auras.size)
		self.Auras:SetWidth(self.Auras.size * 5)
		self.Auras:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -2, -5)
		self.Auras.initialAnchor = "TOPLEFT"
		self.Auras["growth-y"] = "DOWN"
		self.Auras.gap = true
		self.Auras.num = 20
		self.Auras.spacing = 2

		--
		-- combo points
		--
		self.CPoints = self:CreateFontString(nil, "OVERLAY")
		self.CPoints:SetPoint("RIGHT", self, "LEFT", -10, 0)
		self.CPoints:SetFont(font, 45, "OUTLINE")
		self.CPoints:SetTextColor(0, 0.81, 1)
		self.CPoints:SetShadowOffset(1, -1)
		self.CPoints:SetJustifyH("RIGHT")

		--
		-- custom aura textures
		--
		self.PostCreateAuraIcon = PostCreateAuraIcon
	end

	-- ------------------------------------
	-- target
	-- ------------------------------------
	if(unit == "target") then
		self:SetWidth(250)
		self:SetHeight(46)

		self.Health:SetHeight(15.5)
		self.Health.value:SetPoint("RIGHT", 0, 9)

		self.Power:SetPoint("TOP", self.Health, "BOTTOM", 0, -27.5)

		--
		-- level
		--
		self.Info = self.Health:CreateFontString(nil, "OVERLAY")
		self.Info:SetPoint("LEFT", self.Health, 0, 9)
		self.Info:SetJustifyH("LEFT")
		self.Info:SetFont(font, fontsize, "OUTLINE")
		self.Info:SetTextColor(1,1,1)
		self.Info:SetShadowOffset(1, -1)
		self:Tag(self.Info, '[diffcolor][level][shortclassification]')

		self.Name:SetPoint("LEFT", self.Info, "RIGHT", 0, 0)
		self.Name:SetHeight(20)
		self.Name:SetWidth(150)

		--
		-- combo points
		--
		self.CPoints = self:CreateFontString(nil, "OVERLAY")
		self.CPoints:SetPoint("RIGHT", self, "LEFT", -10, 0)
		self.CPoints:SetFont(font, 45, "OUTLINE")
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

		--
		-- buffs
		--
		-- self.Buffs = CreateFrame("Frame", nil, self)
		-- self.Buffs.size = 22
		-- self.Buffs:SetHeight(self.Buffs.size)
		-- self.Buffs:SetWidth(self.Buffs.size * 5)
		-- self.Buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -2, 15)
		-- self.Buffs.initialAnchor = "BOTTOMLEFT"
		-- self.Buffs["growth-y"] = "UP"
		-- self.Buffs.filter = "HELPFUL"
		-- self.Buffs.num = 40
		-- self.Buffs.spacing = 2

		--
		-- buffs
		--
		self.Auras = CreateFrame("Frame", nil, self)
		self.Auras.size = 22
		self.Auras:SetHeight(self.Auras.size)
		self.Auras:SetWidth(self.Auras.size * 5)
		self.Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -2, 15)
		self.Auras.initialAnchor = "BOTTOMLEFT"
		self.Auras["growth-y"] = "UP"
		self.Auras.num = 40
		self.Auras.spacing = 2

		--
		-- debuffs
		--
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs.size = 35
		self.Debuffs:SetHeight(self.Debuffs.size)
		self.Debuffs:SetWidth(self.Debuffs.size * 5)
		self.Debuffs:SetPoint('CENTER', UIParent, 'CENTER', 0, -170)
		self.Debuffs.initialAnchor = "TOPLEFT"
		self.Debuffs["growth-y"] = "UP"
		self.Debuffs.filter = "HARMFUL|PLAYER"
		self.Debuffs.num = 10
		self.Debuffs.spacing = 2

		--
		-- Aura debuff sorting
		--
		--self.SetAuraPosition = SetAuraPosition

		--
		-- custom aura textures
		--
		self.PostCreateAuraIcon = PostCreateAuraIcon
		self.PostUpdateAuraIcon = PostUpdateAuraIcon
	end

	-- ------------------------------------
	-- target of target and focus
	-- ------------------------------------
	if(unit == "targettarget" or unit == "focus") then
		self.Power:Hide()

		self:SetWidth(120)
		self:SetHeight(18)

		self.Health:SetHeight(18)

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
	end

	-- ------------------------------------
	-- player and target portrait
	-- ------------------------------------
	if(unit == 'player' or unit == 'target') then
		self.Portrait = CreateFrame('PlayerModel', nil, self)
		self.Portrait:SetFrameLevel(1)
		self.Portrait:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, -1.5)
		self.Portrait:SetPoint('BOTTOMRIGHT', self.Power, 'TOPRIGHT', -0.5, 1.5)
		table.insert(self.__elements, HidePortrait)

		self.PortraitOverlay = CreateFrame('StatusBar', nil, self)
		self.PortraitOverlay:SetFrameLevel(2)
		self.PortraitOverlay:SetAllPoints(self.Portrait)
		self.PortraitOverlay:SetStatusBarTexture(normTex)
		self.PortraitOverlay:SetStatusBarColor(0.25, 0.25, 0.25, 0.5)
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

			self.Castbar:SetBackdrop(backdrop)

			self.Castbar.SafeZone = self.Castbar:CreateTexture(nil,"ARTWORK")
			self.Castbar.SafeZone:SetTexture(bartex)
			self.Castbar.SafeZone:SetVertexColor(.75,.10,.10,.6)
			self.Castbar.SafeZone:SetPoint("TOPRIGHT")
			self.Castbar.SafeZone:SetPoint("BOTTOMRIGHT")
			self.Castbar:SetPoint('CENTER', UIParent, 'CENTER', 0, -255)
		else
			self.Castbar:SetStatusBarColor(0.80, 0.01, 0)
			self.Castbar:SetHeight(20)
			self.Castbar:SetWidth(250)

			self.Castbar:SetBackdrop(backdrop)

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
	if IsAddOnLoaded('oUF_AutoShot') and class == 'HUNTER' and unit == 'player' then
		self.AutoShot = CreateFrame('StatusBar', nil, self)
		self.AutoShot:SetPoint('BOTTOMLEFT', self.Castbar, 'TOPLEFT', 0, 5)
		self.AutoShot:SetStatusBarTexture(bartex)
		self.AutoShot:SetStatusBarColor(1, 0.7, 0)
		self.AutoShot:SetHeight(6)
		self.AutoShot:SetWidth(250)
		self.AutoShot:SetBackdrop(backdrop)
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
	-- enchants
	-- ------------------------------------
	if IsAddOnLoaded('oUF_WeaponEnchant') and unit == 'player' then
		self.Enchant = CreateFrame('Frame', nil, self)
		self.Enchant:SetHeight(20 * 2)
		self.Enchant:SetWidth(20)
		self.Enchant:SetPoint('TOPLEFT', self, 'TOPRIGHT', 5, 2)
		self.Enchant.size = 20
		self.Enchant.spacing = 1
		self.Enchant.initialAnchor = 'TOPLEFT'
		self.Enchant['growth-y'] = 'DOWN'
	end

	-- ------------------------------------
	-- rune bar
	-- ------------------------------------
	if IsAddOnLoaded('oUF_RuneBar') and class == 'DEATHKNIGHT' and unit == 'player' then
		self.RuneBar = {}
		for i = 1, 6 do
			self.RuneBar[i] = CreateFrame('StatusBar', self:GetName()..'_RuneBar'..i, self)
			self.RuneBar[i]:SetHeight(7)
			self.RuneBar[i]:SetWidth(250/6 - 0.85)
			if (i == 1) then
				self.RuneBar[i]:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -2)
			else
				self.RuneBar[i]:SetPoint('TOPLEFT', self.RuneBar[i-1], 'TOPRIGHT', 1, 0)
			end
			self.RuneBar[i]:SetStatusBarTexture(bartex)
			self.RuneBar[i]:SetStatusBarColor(unpack(runeloadcolors[i]))
			self.RuneBar[i]:SetBackdrop(backdrop)
			self.RuneBar[i]:SetBackdropColor(0, 0, 0)
			self.RuneBar[i]:SetMinMaxValues(0, 1)

			self.RuneBar[i].bg = self.RuneBar[i]:CreateTexture(nil, 'BORDER')
			self.RuneBar[i].bg:SetAllPoints(self.RuneBar[i])
			self.RuneBar[i].bg:SetTexture(bartex)
			self.RuneBar[i].bg:SetVertexColor(0.15, 0.15, 0.15)
		end
	end

	-- ------------------------------------
	-- party
	-- ------------------------------------
	if(self:GetParent():GetName():match("oUF_Party")) then
		self:SetWidth(50)
		self:SetHeight(17.5)

		self.Health:SetHeight(13)

		self.Name:SetFont(font, 9, "OUTLINE")
		self.Name:SetWidth(50)
		self.Name:SetHeight(15)
	end

	-- ------------------------------------
	-- raid
	-- ------------------------------------
	if(self:GetParent():GetName():match("oUF_Raid")) then
		self:SetWidth(50)
		self:SetHeight(17.5)

		self.Health:SetHeight(13)

		self.Name:SetFont(font, 9, "OUTLINE")
		self.Name:SetWidth(50)
		self.Name:SetHeight(15)
	end

	self.disallowVehicleSwap = true

	self:SetAttribute('initial-height', height)
	self:SetAttribute('initial-width', width)
	return self
end

-- ------------------------------------------------------------------------
-- spawning the frames
-- ------------------------------------------------------------------------

--
-- normal frames
--
oUF:RegisterStyle("Fleetfoot", SetStyle)
oUF:SetActiveStyle("Fleetfoot")

oUF:Spawn("player", "oUF_Player"):SetPoint("CENTER", -280, -206)
oUF:Spawn("target", "oUF_Target"):SetPoint("CENTER", 280, -206)
oUF:Spawn("pet", "oUF_Pet"):SetPoint("BOTTOMLEFT", oUF.units.player, 0, -35)
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
