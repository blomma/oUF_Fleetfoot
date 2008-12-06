﻿--[[

	oUF_Blomma

	Author:		Blomma
	Mail:		blomma@gmail.com

	Credits:	
				oUF_Lyn (used as base) / http://www.wowinterface.com/downloads/info10326-oUF_Lyn.html
				oUF_TsoHG (used as base) / http://www.wowinterface.com/downloads/info8739-oUF_TsoHG.html
				Rothar for buff border (and Neal for the edited version)
				p3lim for party toggle function

--]]

-- ------------------------------------------------------------------------
-- local horror
-- ------------------------------------------------------------------------
local select = select
local UnitClass = UnitClass
local UnitIsDead = UnitIsDead
local UnitIsPVP = UnitIsPVP
local UnitIsGhost = UnitIsGhost
local UnitIsPlayer = UnitIsPlayer
local UnitReaction = UnitReaction
local UnitIsConnected = UnitIsConnected
local UnitCreatureType = UnitCreatureType
local UnitClassification = UnitClassification
local UnitReactionColor = UnitReactionColor
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

-- ------------------------------------------------------------------------
-- font, fontsize and textures
-- ------------------------------------------------------------------------
local font = "Interface\\AddOns\\oUF_Blomma\\fonts\\font.ttf"
local upperfont = "Interface\\AddOns\\oUF_Blomma\\fonts\\upperfont.ttf"
local fontsize = 15
local bartex = "Interface\\AddOns\\oUF_Blomma\\textures\\statusbar"
local bufftex = "Interface\\AddOns\\oUF_Blomma\\textures\\border"
local playerClass = select(2, UnitClass("player"))

-- castbar position
local playerCastBar_x = 0
local playerCastBar_y = -200

-- ------------------------------------------------------------------------
-- change some colors :)
-- ------------------------------------------------------------------------
oUF.colors.happiness = {
	[1] = {182/225, 34/255, 32/255},	-- unhappy
	[2] = {220/225, 180/225, 52/225},	-- content
	[3] = {143/255, 194/255, 32/255},	-- happy
}

-- ------------------------------------------------------------------------
-- right click
-- ------------------------------------------------------------------------
local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

-- ------------------------------------------------------------------------
-- reformat everything above 9999, i.e. 10000 -> 10k
-- ------------------------------------------------------------------------
local numberize = function(v)
	if v <= 9999 then return v end
	if v >= 1000000 then
		local value = string.format("%.1fm", v/1000000)
		return value
	elseif v >= 10000 then
		local value = string.format("%.1fk", v/1000)
		return value
	end
end

-- ------------------------------------------------------------------------
-- returns the hex code of a rgb value
-- ------------------------------------------------------------------------
local hexColor = function(r, g, b)
	if type(r) == "table" then
		if r.r then
			r, g, b = r.r, r.g, r.b
		else
			r, g, b = unpack(r)
		end
	end
    
	return string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
end
-- ------------------------------------------------------------------------
-- level update
-- ------------------------------------------------------------------------
local updateLevel = function(self, unit, name)
	local lvl = UnitLevel(unit)
	local typ = UnitClassification(unit)

	local color = GetDifficultyColor(lvl)

	if lvl <= 0 then	lvl = "??" end

	if typ=="worldboss" then
	    self.Level:SetText("|cffff0000"..lvl.."b|r")
	elseif typ=="rareelite" then
	    self.Level:SetText(lvl.."r+")
		self.Level:SetTextColor(color.r, color.g, color.b)
	elseif typ=="elite" then
	    self.Level:SetText(lvl.."+")
		self.Level:SetTextColor(color.r, color.g, color.b)
	elseif typ=="rare" then
		self.Level:SetText(lvl.."r")
		self.Level:SetTextColor(color.r, color.g, color.b)
	else
		if UnitIsConnected(unit) == nil then
			self.Level:SetText("??")
		else
			self.Level:SetText(lvl)
		end
		if(not UnitIsPlayer(unit)) then
			self.Level:SetTextColor(color.r, color.g, color.b)
		else
			local _, class = UnitClass(unit)
			color = self.colors.class[class]
			self.Level:SetTextColor(color[1], color[2], color[3])
		end
	end
end

-- ------------------------------------------------------------------------
-- name update
-- ------------------------------------------------------------------------
local updateName = function(self, event, unit)
	if(self.unit ~= unit) then return end

	local name = UnitName(unit)
    self.Name:SetText(string.lower(name))

	if unit=="targettarget" then
		local totName = UnitName(unit)
		local pName = UnitName("player")
		if totName==pName then
			self.Name:SetTextColor(0.9, 0.5, 0.2)
		else
			self.Name:SetTextColor(1,1,1)
		end
	else
		self.Name:SetTextColor(1,1,1)
	end

    if unit=="target" then -- Show level value on targets only
		updateLevel(self, unit, name)
    end
end

-- ------------------------------------------------------------------------
-- health update
-- ------------------------------------------------------------------------
local updateHealth = function(self, event, unit, bar, min, max)
	if(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
		bar.value:SetText("dead")
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText("offline")
    elseif(unit == "player") then
		if(min ~= max) then
			bar.value:SetText("|cff33EE44"..numberize(min) .."|r.".. floor(min/max*100).."%")
		else
			bar.value:SetText(" ")
		end
	elseif(unit == "targettarget") then
		bar.value:SetText(floor(min/max*100).."%")
    elseif(unit == "target") then
		if(min ~= max) then
			bar.value:SetText("|cff33EE44"..numberize(min).."|r."..floor(min/max*100).."%")
		else
			bar.value:SetText(" ")
		end

	elseif(min == max) then
        if unit == "pet" then
			bar.value:SetText(" ") -- just here if otherwise wanted
		else
			bar.value:SetText(" ")
		end
    else
        if((max-min) < max) then
			if unit == "pet" then
				bar.value:SetText("-"..max-min) -- negative values as for party, just here if otherwise wanted
			else
				bar.value:SetText("-"..max-min) -- this makes negative values (easier as a healer)
			end
	    end
    end

    self:UNIT_NAME_UPDATE(event, unit)
end


-- ------------------------------------------------------------------------
-- power update
-- ------------------------------------------------------------------------
local updatePower = function(self, event, unit, bar, min, max)
	if UnitIsPlayer(unit)==nil then
		bar.value:SetText()
	else
		local _, ptype = UnitPowerType(unit)
		local color = oUF.colors.power[ptype]
		if(min==0) then
			bar.value:SetText()
		elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
			bar:SetValue(0)
		elseif(not UnitIsConnected(unit)) then
			bar.value:SetText()
		elseif unit=="player" then
			if(min==max) then
				bar.value:SetText("")
	        else
				local d = floor(min/max*100)
            	bar.value:SetText(hexColor(color)..numberize(min).."|r.".. d.."%")
			end
        else
			if((max-min) > 0) then
				bar.value:SetText(min)
				if color then
					bar.value:SetTextColor(color[1], color[2], color[3])
				else
					bar.value:SetTextColor(0.2, 0.66, 0.93)
				end
			else
				bar.value:SetText(min)
				if color then
					bar.value:SetTextColor(color[1], color[2], color[3])
				else
					bar.value:SetTextColor(0.2, 0.66, 0.93)
				end
			end
		end
	end
end

-- ------------------------------------------------------------------------
-- aura reskin
-- ------------------------------------------------------------------------
local auraIcon = function(self, button, icons)
	icons.showDebuffType = true -- show debuff border type color

	button.icon:SetTexCoord(.07, .93, .07, .93)
	button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)

	button.overlay:SetTexture(bufftex)
	button.overlay:SetTexCoord(0,1,0,1)
	button.overlay.Hide = function(self) self:SetVertexColor(0.3, 0.3, 0.3) end

	button.cd:SetReverse()
	button.cd:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
	button.cd:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
end

-- ------------------------------------------------------------------------
-- the layout starts here
-- ------------------------------------------------------------------------
local func = function(self, unit)
	self.sortAuras = {} -- Enable Aura Sorting

	self.menu = menu -- Enable the menus

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

	--
	-- background
	--
	self:SetBackdrop{
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
	insets = {left = -2, right = -2, top = -2, bottom = -2},
	}
	self:SetBackdropColor(0,0,0,1) -- and color the backgrounds

	--
	-- healthbar
	--
	self.Health = CreateFrame"StatusBar"
	self.Health:SetHeight(19) -- Custom height
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
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.colorDisconnected = true
	self.Health.colorTapping = true
	self.PostUpdateHealth = updateHealth -- let the colors be

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
    self.Power.value:SetPoint("RIGHT", self.Health.value, "BOTTOMRIGHT", 0, -5) -- powerbar text in health box
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
	self.Power.colorHappiness = false
	self.PostUpdatePower = updatePower -- let the colors be

	--
	-- names
	--
	self.Name = self.Health:CreateFontString(nil, "OVERLAY")
    self.Name:SetPoint("LEFT", self, 0, 9)
    self.Name:SetJustifyH"LEFT"
	self.Name:SetFont(font, fontsize, "OUTLINE")
	self.Name:SetShadowOffset(1, -1)
    self.UNIT_NAME_UPDATE = updateName

	--
	-- level
	--
	self.Level = self.Health:CreateFontString(nil, "OVERLAY")
	self.Level:SetPoint("LEFT", self.Health, 0, 9)
	self.Level:SetJustifyH("LEFT")
	self.Level:SetFont(font, fontsize, "OUTLINE")
    self.Level:SetTextColor(1,1,1)
	self.Level:SetShadowOffset(1, -1)
	self.UNIT_LEVEL = updateLevel

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
		self.Level:Hide()

		--[[
		if(playerClass=="DRUID") then
			-- bar
			self.DruidMana = CreateFrame('StatusBar', nil, self)
			self.DruidMana:SetPoint('TOP', self, 'BOTTOM', 0, -6)
			self.DruidMana:SetStatusBarTexture(bartex)
			self.DruidMana:SetStatusBarColor(45/255, 113/255, 191/255)
			self.DruidMana:SetHeight(10)
			self.DruidMana:SetWidth(250)
			-- bar bg
			self.DruidMana.bg = self.DruidMana:CreateTexture(nil, "BORDER")
			self.DruidMana.bg:SetAllPoints(self.DruidMana)
			self.DruidMana.bg:SetTexture(bartex)
			self.DruidMana.bg:SetAlpha(0.30)
			-- black bg
			self.DruidMana:SetBackdrop{
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
				insets = {left = -2, right = -2.5, top = -2.5, bottom = -2},
				}
			self.DruidMana:SetBackdropColor(0,0,0,1)
			-- text
			self.DruidManaText = self.DruidMana:CreateFontString(nil, 'OVERLAY')
			self.DruidManaText:SetPoint("CENTER", self.DruidMana, "CENTER", 0, 1)
			self.DruidManaText:SetFont(font, 12, "OUTLINE")
			self.DruidManaText:SetTextColor(1,1,1)
			self.DruidManaText:SetShadowOffset(1, -1)
		end
		--]]

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

		--
		-- oUF_PowerSpark support
		--
        self.Spark = self.Power:CreateTexture(nil, "OVERLAY")
		self.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		self.Spark:SetVertexColor(1, 1, 1, 1)
		self.Spark:SetBlendMode("ADD")
		self.Spark:SetHeight(self.Power:GetHeight()*2.5)
		self.Spark:SetWidth(self.Power:GetHeight()*2)
        -- self.Spark.rtl = true -- Make the spark go from Right To Left instead
		-- self.Spark.manatick = true -- Show mana regen ticks outside FSR (like the energy ticker)
		-- self.Spark.highAlpha = 1 	-- What alpha setting to use for the FSR and energy spark
		-- self.Spark.lowAlpha = 0.25 -- What alpha setting to use for the mana regen ticker

		--
		-- oUF_BarFader
		--
		self.BarFade = true
		self.BarFadeAlpha = 0.2
	end

	-- ------------------------------------
	-- pet
	-- ------------------------------------
	if unit=="pet" then
		self:SetWidth(120)
		self:SetHeight(18)
		self.Health:SetHeight(18)
		self.Power:Hide()
		self.Health.value:Hide()
		self.Level:Hide()
		self.Name:Hide()

		if playerClass=="HUNTER" then
			self.Health.colorReaction = false
			self.Health.colorClass = false
			self.Health.colorHappiness = true
		end

		--
		-- oUF_BarFader
		--
		self.BarFade = true
		self.BarFadeAlpha = 0.2
	end

	-- ------------------------------------
	-- target
	-- ------------------------------------
    if unit=="target" then
		self:SetWidth(250)
		self:SetHeight(20)
		self.Health:SetHeight(15.5)
		self.Power:SetHeight(3)
		self.Power.value:Hide()
		self.Health.value:SetPoint("RIGHT", 0, 9)
		self.Name:SetPoint("LEFT", self.Level, "RIGHT", 0, 0)
		self.Name:SetHeight(20)
		self.Name:SetWidth(150)

		self.Health.colorClass = false

		--
		-- combo points
		--
		if(playerClass=="ROGUE" or playerClass=="DRUID") then
			self.CPoints = self:CreateFontString(nil, "OVERLAY")
			self.CPoints:SetPoint("RIGHT", self, "LEFT", -10, 0)
			self.CPoints:SetFont(font, 38, "OUTLINE")
			self.CPoints:SetTextColor(0, 0.81, 1)
			self.CPoints:SetShadowOffset(1, -1)
			self.CPoints:SetJustifyH"RIGHT"
		end

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
		self.Buffs = CreateFrame("Frame", nil, self) -- buffs
		self.Buffs.size = 22
		self.Buffs:SetHeight(self.Buffs.size)
		self.Buffs:SetWidth(self.Buffs.size * 5)
		self.Buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -2, 15)
		self.Buffs.initialAnchor = "BOTTOMLEFT"
		self.Buffs["growth-y"] = "TOP"
		self.Buffs.filter = "HELPFUL|PLAYER"
		self.Buffs.num = 20
		self.Buffs.spacing = 2

		--
		-- debuffs
		--
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs.size = 35
		self.Debuffs:SetHeight(self.Debuffs.size)
		self.Debuffs:SetWidth(self.Debuffs.size * 5)
		self.Debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -247, 40)
		self.Debuffs.initialAnchor = "TOPLEFT"
		self.Debuffs["growth-y"] = "TOP"
		self.Debuffs.filter = "HARMFUL|PLAYER"
		self.Debuffs.num = 40
		self.Debuffs.spacing = 2
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

		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(16)
		self.RaidIcon:SetWidth(16)
		self.RaidIcon:SetPoint("RIGHT", self, 0, 9)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"

		--
		-- oUF_BarFader
		--
		if unit=="focus" then
			self.BarFade = true
			self.BarFadeAlpha = 0.2
		end
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

			self.Castbar:SetPoint('CENTER', UIParent, 'CENTER', playerCastBar_x, playerCastBar_y)
		else
			self.Castbar:SetStatusBarColor(0.80, 0.01, 0)
			self.Castbar:SetHeight(20)
			self.Castbar:SetWidth(250)

			self.Castbar:SetBackdrop({
				bgFile = "Interface\ChatFrame\ChatFrameBackground",
				insets = {top = -3, left = -30, bottom = -3, right = -3}})

			-- self.Castbar.Icon = self.Castbar:CreateTexture(nil, 'OVERLAY')
			-- self.Castbar.Icon:SetPoint("RIGHT", self.Castbar, "LEFT", -3, 0)
			-- self.Castbar.Icon:SetHeight(24)
			-- self.Castbar.Icon:SetWidth(24)
			-- self.Castbar.Icon:SetTexCoord(0.1,0.9,0.1,0.9)

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

		--
		-- debuffs
		--
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs.size = 20 * 1.3
		self.Debuffs:SetHeight(self.Debuffs.size)
		self.Debuffs:SetWidth(self.Debuffs.size * 5)
		self.Debuffs:SetPoint("LEFT", self, "RIGHT", 5, 0)
		self.Debuffs.initialAnchor = "TOPLEFT"
	    self.Debuffs.filter = false
		self.Debuffs.showDebuffType = true
		self.Debuffs.spacing = 2
		self.Debuffs.num = 2 -- max debuffs

		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(24)
		self.RaidIcon:SetWidth(24)
		self.RaidIcon:SetPoint("LEFT", self, -30, 0)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
	end

	-- ------------------------------------
	-- raid
	-- ------------------------------------
    if(self:GetParent():GetName():match"oUF_Raid") then
		self:SetWidth(85)
		self:SetHeight(15)
		self.Health:SetHeight(15)
		self.Power:Hide()
		self.Health:SetFrameLevel(2)
		self.Power:SetFrameLevel(2)
		self.Health.value:Hide()
		self.Power.value:Hide()
		self.Name:SetFont(font, 12, "OUTLINE")
		self.Name:SetWidth(85)
		self.Name:SetHeight(15)

		--
		-- oUF_DebuffHighlight support
		--
		self.DebuffHighlight = self.Health:CreateTexture(nil, "OVERLAY")
		self.DebuffHighlight:SetAllPoints(self.Health)
		self.DebuffHighlight:SetTexture("Interface\\AddOns\\oUF_Blomma\\textures\\highlight.tga")
		self.DebuffHighlight:SetBlendMode("ADD")
		self.DebuffHighlight:SetVertexColor(0, 0, 0, 0)
		self.DebuffHighlightAlpha = 0.8
		self.DebuffHighlightFilter = true
    end

	--
	-- fading for party and raid
	--
	if(not unit) then -- fadeout if units are out of range
		self.Range = false -- put true to make party/raid frames fade out if not in your range
		self.inRangeAlpha = 1.0 -- what alpha if IN range
		self.outsideRangeAlpha = 0.5 -- the alpha it will fade out to if not in range
    end

	--
	-- custom aura textures
	--
	self.PostCreateAuraIcon = auraIcon
	self.SetAuraPosition = auraOffset

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
oUF:RegisterStyle("Lyn", func)

oUF:SetActiveStyle("Lyn")
local player = oUF:Spawn("player", "oUF_Player")
player:SetPoint("CENTER", -280, -106)
local target = oUF:Spawn("target", "oUF_Target")
target:SetPoint("CENTER", 280, -106)
local pet = oUF:Spawn("pet", "oUF_Pet")
pet:SetPoint("BOTTOMLEFT", player, 0, -30)
local tot = oUF:Spawn("targettarget", "oUF_TargetTarget")
tot:SetPoint("TOPRIGHT", target, 0, 35)
local focus	= oUF:Spawn("focus", "oUF_Focus")
focus:SetPoint("BOTTOMRIGHT", player, 0, -30)

--
-- party
--
local party	= oUF:Spawn("header", "oUF_Party")
party:SetManyAttributes("showParty", true, "yOffset", -15)
party:SetPoint("TOPLEFT", 35, -200)
party:Show()
party:SetAttribute("showRaid", false)

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
	RaidGroup:SetAttribute("showRaid", true)
	table.insert(Raid, RaidGroup)
	if i == 1 then
		RaidGroup:SetPoint("TOPLEFT", UIParent, 35, -35)
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
		if(HIDE_PARTY_INTERFACE == "1" and GetNumRaidMembers() > 0) then
			party:Hide()
		else
			party:Show()
		end
	end
end)