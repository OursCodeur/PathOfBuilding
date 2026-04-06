-- Path of Building
--
-- Class: Item
-- Equippable item class
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local dmgTypeList = {"Physical", "Lightning", "Cold", "Fire", "Chaos"}
local catalystList = {"Abrasive", "Accelerating", "Fertile", "Imbued", "Intrinsic", "Noxious", "Prismatic", "Tempering", "Turbulent", "Unstable"}
local catalystTags = {
	{ "attack" },
	{ "speed" },
	{ "life", "mana", "resource" },
	{ "caster" },
	{ "jewellery_attribute", "attribute" },
	{ "physical_damage", "chaos_damage" },
	{ "jewellery_resistance", "resistance" },
	{ "jewellery_defense", "defences" },
	{ "jewellery_elemental" ,"elemental_damage" },
	{ "critical" },
}

local function getCatalystScalar(catalystId, tags, quality)
	if not catalystId or type(catalystId) ~= "number" or not catalystTags[catalystId] or not tags or type(tags) ~= "table" or #tags == 0 then
		return 1
	end
	if not quality then
		quality = 20
	end

	-- Create a fast lookup table for all provided tags
	local tagLookup = {}
	for _, curTag in ipairs(tags) do
		tagLookup[curTag] = true;
	end

	-- Find if any of the catalyst's tags match the provided tags
	for _, catalystTag in ipairs(catalystTags[catalystId]) do
		if tagLookup[catalystTag] then
			return (100 + quality) / 100
		end
	end
	return 1
end

local influenceInfo = itemLib.influenceInfo.all

local ItemClass = newClass("Item", function(self, raw, rarity, highQuality)
	if raw then
		self:ParseRaw(sanitiseText(raw), rarity, highQuality)
	end	
end)

-- Reset all influence keys to false
function ItemClass:ResetInfluence()
	for _, curInfluenceInfo in ipairs(influenceInfo) do
		self[curInfluenceInfo.key] = false
	end
end

local influenceItemMap = { }
for _, curInfluenceInfo in ipairs(influenceInfo) do
	influenceItemMap[curInfluenceInfo.display.." Item"] = curInfluenceInfo.key
end

local lineFlags = {
	["crafted"] = true, ["crucible"] = true, ["custom"] = true, ["eater"] = true, ["enchant"] = true,
	["exarch"] = true, ["fractured"] = true, ["implicit"] = true, ["scourge"] = true, ["synthesis"] = true,
	["specialSource"] = true, ["veiled"] = true,
	["unscalable"] = true,
	["mutated"] = true
}

-- Special function to store unique instances of modifier on specific item slots
-- that require special handling for ItemConditions. Only called if line #224 is
-- uncommented
local specialModifierFoundList = {}
local inverseModifierFoundList = {}
local function getTagBasedModifiers(tagName, itemSlotName)
	local tag_name = tagName:lower()
	local slot_name = itemSlotName:lower():gsub(" ", "_")
	-- iterate all the item modifiers
	for k,v in pairs(data.itemMods.Item) do
		-- iterate across the modifier tags for each modifier
		for _,tag in ipairs(v.modTags) do
			-- if tag matches the tag_name we are investigating
			if tag:lower() == tag_name then
				local found = false
				-- if there is a valid weightKey table
				if #v.weightKey > 0 then
					for _,wk in ipairs(v.weightKey) do
						-- and it matches the slot_name of the item we are investigating
						if wk == slot_name then
							for _, dv in ipairs(v) do
								-- and the modifier description contains the tag_name keyword
								if dv:lower():find(tag_name) then
									found = true
									break
								else
									local excluded = false
									if data.itemTagSpecial[tagName] and data.itemTagSpecial[tagName][itemSlotName] then
										for _, specialMod in ipairs(data.itemTagSpecial[tagName][itemSlotName]) do
											if dv:lower():find(specialMod:lower()) then
												exclude = true
												break
											end
										end
									end
									if exclude then
										found = true
										break
									end
								end
							end
							if not found and not specialModifierFoundList[k] then
								specialModifierFoundList[k] = true
								ConPrintf("[%s] [%s] ENTRY: %s", tagName, itemSlotName, k)
							end
						end
					end
				else
					for _, dv in ipairs(v) do
						if dv:lower():find(tag_name) then
							found = true
							break
						else
							local excluded = false
							if data.itemTagSpecial[tagName] and data.itemTagSpecial[tagName][itemSlotName] then
								for _, specialMod in ipairs(data.itemTagSpecial[tagName][itemSlotName]) do
									if dv:lower():find(specialMod:lower()) then
										exclude = true
										break
									end
								end
							end
							if exclude then
								found = true
								break
							end
						end
					end
					if not found and not specialModifierFoundList[k] then
						specialModifierFoundList[k] = true
						ConPrintf("[%s] ENTRY: %s", tagName, k)
					end
				end
			end
		end
		for _, dv in ipairs(v) do
			if dv:lower():find(tag_name) then
				local found_2 = false
				if #v.weightKey > 0 then
					for _,wk in ipairs(v.weightKey) do
						if wk == slot_name then
							-- this is useless if the modTags = { } (is empty)
							if #v.modTags > 0 then
								for _,tag in ipairs(v.modTags) do
									if tag:lower() == tag_name then
										found_2 = true
										break
									else
										local excluded = false
										-- if we have an exclusion pattern list for that tagName and itemSlotName
										if data.itemTagSpecialExclusionPattern[tagName] and data.itemTagSpecialExclusionPattern[tagName][itemSlotName] then
											-- iterate across the exclusion patterns
											for _, specialMod in ipairs(data.itemTagSpecialExclusionPattern[tagName][itemSlotName]) do
												-- and if the description matches pattern exclude it
												if dv:lower():find(specialMod:lower()) then
													excluded = true
													break
												end
											end
										end
										if excluded then
											found_2 = true
											break
										end
									end
								end
								if not found_2 and not inverseModifierFoundList[k] then
									inverseModifierFoundList[k] = true
									ConPrintf("[%s] appears in desc but not in tags. [%s] %s", tag_name, k, dv)
									break
								end
							end
						end
					end
				else
					-- this is useless if the modTags = { } (is empty)
					if #v.modTags > 0 then
						for _,tag in ipairs(v.modTags) do
							if tag:lower() == tag_name then
								found_2 = true
								break
							else
								local excluded = false
								-- if we have an exclusion pattern list for that tagName and itemSlotName
								if data.itemTagSpecialExclusionPattern[tagName] and data.itemTagSpecialExclusionPattern[tagName][itemSlotName] then
									-- iterate across the exclusion patterns
									for _, specialMod in ipairs(data.itemTagSpecialExclusionPattern[tagName][itemSlotName]) do
										-- and if the description matches pattern exclude it
										if dv:lower():find(specialMod:lower()) then
											excluded = true
											break
										end
									end
								end
								if excluded then
									found_2 = true
									break
								end
							end
						end
						if not found_2 and not inverseModifierFoundList[k] then
							inverseModifierFoundList[k] = true
							ConPrintf("[%s] appears in desc but not in tags. [%s] %s", tag_name, k, dv)
						end
					end
				end
			end
		end
	end
end

-- Iterate over modifiers to see if specific substring is found (for conditional checking)
function ItemClass:FindModifierSubstring(substring, itemSlotName)
	local modLines = {}
	local substring, explicit = substring:gsub("explicit ", "")

	-- The commented out line below is used at GGPK updates to check if any new modifiers
	-- have been identified that need to be added to the manually maintained special modifier
	-- pool in Data.lua (data.itemTagSpecial and data.itemTagSpecialExclusionPattern tables)
	--getTagBasedModifiers(substring, itemSlotName)

	-- merge various modifier lines into one table
	for _,v in pairs(self.explicitModLines) do t_insert(modLines, v) end
	if explicit < 1 then
		for _,v in pairs(self.enchantModLines) do t_insert(modLines, v) end
		for _,v in pairs(self.scourgeModLines) do t_insert(modLines, v) end
		for _,v in pairs(self.implicitModLines) do t_insert(modLines, v) end
		for _,v in pairs(self.crucibleModLines) do t_insert(modLines, v) end
	end

	for _,v in pairs(modLines) do
		local currentVariant = false
		if v.variantList then
			for variant, enabled in pairs(v.variantList) do
				if enabled and variant == self.variant then
					currentVariant = true
				end
			end
		else
			currentVariant = true
		end
		if currentVariant then
			if v.line:lower():find(substring) and not v.line:lower():find(substring .. " modifier") then
				local excluded = false
				if data.itemTagSpecialExclusionPattern[substring] and data.itemTagSpecialExclusionPattern[substring][itemSlotName] then
					for _, specialMod in ipairs(data.itemTagSpecialExclusionPattern[substring][itemSlotName]) do
						if v.line:lower():find(specialMod:lower()) then
							excluded = true
							break
						end
					end
				end
				if not excluded then
					return true
				end
			end
			if data.itemTagSpecial[substring] and data.itemTagSpecial[substring][itemSlotName] then
				for _, specialMod in ipairs(data.itemTagSpecial[substring][itemSlotName]) do
					if v.line:lower():find(specialMod:lower()) and (not v.variantList or v.variantList[self.variant]) then
						return true
					end
				end
			end
		end
	end
	return false
end

local function specToNumber(s)
	local n = s:match("^([%+%-]?[%d%.]+)")
	return n and tonumber(n)
end

local function parseModLineText(line, range, valueScalar)
	local hasRangedText = range ~= nil and line:find("%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)") ~= nil
	local parsedLine = (range ~= nil and hasRangedText) and itemLib.applyRange(line, range, valueScalar) or line
	return modLib.parseMod(parsedLine)
end

local beastCraftAffixLookup = { }
for _, mod in pairs(data.beastCraft or { }) do
	if mod.affix and mod.affix ~= "" then
		beastCraftAffixLookup[mod.affix] = true
	end
end

local veiledAffixLookup = { }
for _, mod in pairs(data.veiledMods or { }) do
	if mod.affix and mod.affix ~= "" then
		veiledAffixLookup[mod.affix] = true
	end
end

local advancedClipboardSpecialSourceDefs = {
	{
		id = "BEASTCRAFT",
		matchesAffix = function(affix)
			return beastCraftAffixLookup[affix] or false
		end,
		pool = function()
			return data.beastCraft or { }
		end,
	},
	{
		id = "VEILED",
		matchesAffix = function(affix)
			return veiledAffixLookup[affix] or false
		end,
		matchesMod = function(mod)
			if veiledAffixLookup[mod.affix] then
				return true
			end
			for _, tag in ipairs(mod.modTags or { }) do
				if tag == "unveiled_mod" then
					return true
				end
			end
			return false
		end,
		pool = function()
			return data.veiledMods or { }
		end,
	},
	{
		id = "ESSENCE",
		matchesAffix = function(affix)
			return affix == "Essences" or affix == "of the Essence"
		end,
	},
	{
		id = "DELVE",
		matchesAffix = function(affix)
			return affix == "Subterranean" or affix == "of the Underground"
		end,
	},
}

local function getAdvancedClipboardSpecialSource(groupOrAffix)
	local affix = type(groupOrAffix) == "table" and groupOrAffix.affix or groupOrAffix
	if not affix then
		return
	end
	for _, sourceDef in ipairs(advancedClipboardSpecialSourceDefs) do
		if sourceDef.matchesAffix(affix) then
			return sourceDef
		end
	end
end

local function getAdvancedClipboardSpecialSourceById(sourceId)
	for _, sourceDef in ipairs(advancedClipboardSpecialSourceDefs) do
		if sourceDef.id == sourceId then
			return sourceDef
		end
	end
end

local function getFallbackAffixPools(item)
	return {
		item and item.affixes,
		data.veiledMods,
		data.beastCraft,
		data.masterMods,
	}
end

local function getFallbackAffix(item, modId)
	if not modId then
		return
	end
	for _, pool in ipairs(getFallbackAffixPools(item)) do
		if pool and pool[modId] then
			return pool[modId]
		end
	end
end

local function parseAdvancedClipboardDescriptor(line)
	local body = line:match("^%{%s*(.-)%s*%}$")
	if not body or not body:find(" Modifier", 1, true) then
		return
	end
	local group = {
		type = "Other",
		affix = body:match('Modifier%s+"([^"]+)"'),
		tier = tonumber(body:match("%(Tier:%s*(%d+)%)")),
		lines = { },
	}
	if body:find("Prefix Modifier", 1, true) then
		group.type = "Prefix"
	elseif body:find("Suffix Modifier", 1, true) then
		group.type = "Suffix"
	elseif body:find("Implicit Modifier", 1, true) then
		group.type = "Implicit"
	end
	group.crafted = body:find("Master Crafted", 1, true) ~= nil
	group.fractured = body:find("Fractured", 1, true) ~= nil
	group.exarch = body:find("Searing Exarch", 1, true) ~= nil
	group.eater = body:find("Eater of Worlds", 1, true) ~= nil
	group.veiled = group.affix and veiledAffixLookup[group.affix] or nil
	local increasedMagnitude = body:match("[—-]%s*([%d%.]+)%%%s+Increased%s*$")
	local reducedMagnitude = body:match("[—-]%s*([%d%.]+)%%%s+Reduced%s*$")
	if increasedMagnitude then
		group.valueScalar = 1 + tonumber(increasedMagnitude) / 100
	elseif reducedMagnitude then
		group.valueScalar = 1 - tonumber(reducedMagnitude) / 100
	end
	return group
end

local function normaliseAdvancedClipboardLine(line)
	if line:match("^%b()$") then
		return
	end
	local unscalable = line:match("%s+[—-]%s+Unscalable Value$") ~= nil
	line = line:gsub("%s+[—-]%s+Unscalable Value$", "")
	local displayLine = line:gsub("([%+%-]?%d+%.?%d*)%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)", function(valueStr)
		return valueStr
	end)
	local range
	local canResolve = true
	local inBounds = true
	local rangeValues = { }
	local rawLine = line:gsub("([%+%-]?%d+%.?%d*)%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)", function(valueStr, minStr, maxStr)
		local value = tonumber(valueStr)
		local min = tonumber(minStr)
		local max = tonumber(maxStr)
		if not value or not min or not max then
			canResolve = false
			return valueStr .. "(" .. minStr .. "-" .. maxStr .. ")"
		end
		local low = math.min(min, max)
		local high = math.max(min, max)
		if value < low or value > high then
			inBounds = false
			canResolve = false
		end
		if high ~= low then
			local lineRange = (value - low) / (high - low)
			t_insert(rangeValues, lineRange)
			if range == nil then
				range = lineRange
			elseif math.abs(range - lineRange) > 0.001 then
				canResolve = false
			end
		elseif value ~= low then
			canResolve = false
		end
		local sign = valueStr:match("^[%+%-]") or ""
		if low < 0 and high < 0 then
			return "-(" .. tostring(math.abs(low)) .. "-" .. tostring(math.abs(high)) .. ")"
		end
		return sign .. "(" .. tostring(low) .. "-" .. tostring(high) .. ")"
	end)
	return {
		line = canResolve and rawLine or displayLine,
		matchLine = rawLine,
		range = canResolve and range or nil,
		canResolve = canResolve,
		inBounds = inBounds,
		rangeValues = rangeValues,
		displayLine = displayLine,
		unscalable = unscalable or nil,
	}
end

local function resolveAdvancedClipboardAffix(item, group)
	local sourceDef = getAdvancedClipboardSpecialSource(group)
	local candidatePools = { sourceDef and sourceDef.pool and sourceDef.pool(item) or item.affixes }
	if not candidatePools[1] then
		return
	end
	local matches = { }
	for _, pool in ipairs(candidatePools) do
		for modId, mod in pairs(pool) do
			if mod.type == group.type and mod.affix == group.affix and #mod == #group.lines then
				local range
				local displayLines = { }
				local rangeValues = { }
				local matched = true
				for i, groupLine in ipairs(group.lines) do
					if not groupLine.inBounds or mod[i] ~= (groupLine.matchLine or groupLine.line) then
						matched = false
						break
					elseif groupLine.range ~= nil then
						if range == nil then
							range = groupLine.range
						elseif math.abs(range - groupLine.range) > 0.001 then
							matched = false
							break
						end
					end
					displayLines[i] = groupLine.displayLine or groupLine.line
					for _, value in ipairs(groupLine.rangeValues or { }) do
						t_insert(rangeValues, value)
					end
				end
				if matched then
					if range == nil and rangeValues[1] then
						local total = 0
						for _, value in ipairs(rangeValues) do
							total = total + value
						end
						range = m_max(0, m_min(1, total / #rangeValues))
					end
					t_insert(matches, {
						modId = modId,
						mod = mod,
						range = range,
						displayLines = displayLines,
						sourceId = sourceDef and sourceDef.id or nil,
					})
				end
			end
		end
	end
	if not matches[1] then
		return
	elseif #matches == 1 or not group.tier then
		return matches[1]
	end
	table.sort(matches, function(a, b)
		local modA = a.mod
		local modB = b.mod
		if modA.level ~= modB.level then
			return modA.level > modB.level
		end
		return a.modId < b.modId
	end)
	return matches[group.tier] or matches[1]
end

local function buildParsedModLine(line, opts)
	opts = opts or { }
	local modLine = {
		line = line,
		modTags = opts.modTags or { },
	}
	if opts.range ~= nil then
		modLine.range = opts.range
	end
	if opts.valueScalar ~= nil then
		modLine.valueScalar = opts.valueScalar
	end
	for key, value in pairs(opts.flags or { }) do
		modLine[key] = value or nil
	end
	local modList, extra = parseModLineText(line, opts.range, opts.valueScalar)
	modLine.modList = modList or { }
	modLine.extra = extra
	return modLine
end

local function buildAdvancedClipboardModLine(item, group, groupLine)
	local catalystScalar = getCatalystScalar(item.catalyst, { }, item.catalystQuality)
	return buildParsedModLine(groupLine.line, {
		range = groupLine.range,
		valueScalar = catalystScalar,
		flags = {
			implicit = group and group.type == "Implicit" or nil,
			crafted = group and group.crafted or nil,
			fractured = group and group.fractured or nil,
			exarch = group and group.exarch or nil,
			eater = group and group.eater or nil,
			veiled = group and group.veiled or nil,
			specialSource = group and group.preserveOnCraft or nil,
			unscalable = groupLine.unscalable or nil,
		},
	})
end

local function buildResolvedCustomAffixModLine(mod, line, range, opts)
	return buildParsedModLine(line, {
		range = range,
		modTags = mod and mod.modTags or { },
		flags = {
			custom = true,
			veiled = opts and opts.veiled or nil,
			unscalable = opts and opts.unscalable or nil,
		},
	})
end

local modifierMagnitudeScalarDefs = {
	implicit = {
		modName = "ImplicitModifierMagnitudes",
		literalScalars = {
			["implicit modifier magnitudes are doubled"] = 2,
			["implicit modifier magnitudes are tripled"] = 3,
		},
		increasedPattern = "^([%+%-]?[%d%.]+)%% increased implicit modifier magnitudes$",
		reducedPattern = "^([%+%-]?[%d%.]+)%% reduced implicit modifier magnitudes$",
	},
	unveiled = {
		modName = "UnveiledModifierMagnitudes",
		increasedPattern = "^([%+%-]?[%d%.]+)%% increased unveiled modifier magnitudes$",
	},
}

local function getMagnitudeScalarFromModList(modList, modName)
	if not modList then
		return
	end
	local totalIncrease = 0
	for _, mod in ipairs(modList) do
		if mod.name == modName and mod.type == "INC" then
			totalIncrease = totalIncrease + mod.value
		end
	end
	if totalIncrease ~= 0 then
		return 1 + totalIncrease / 100
	end
end

local function getModifierMagnitudeScalar(modLine, scalarDef)
	local line = modLine.line
	if modLine.range and line:match("%(%-?[%d%.]+%-%-?[%d%.]+%)") then
		local scalar = getMagnitudeScalarFromModList(parseModLineText(line, modLine.range), scalarDef.modName)
		if scalar then
			return scalar
		end
	end
	local scalar = getMagnitudeScalarFromModList(modLine.modList, scalarDef.modName)
	if scalar then
		return scalar
	end
	local lowerLine = line:lower()
	if scalarDef.literalScalars and scalarDef.literalScalars[lowerLine] then
		return scalarDef.literalScalars[lowerLine]
	end
	local increased = scalarDef.increasedPattern and lowerLine:match(scalarDef.increasedPattern)
	if increased then
		return 1 + tonumber(increased) / 100
	end
	local reduced = scalarDef.reducedPattern and lowerLine:match(scalarDef.reducedPattern)
	if reduced then
		return 1 - tonumber(reduced) / 100
	end
end

local function getImplicitModifierMagnitudeScalar(modLine)
	return getModifierMagnitudeScalar(modLine, modifierMagnitudeScalarDefs.implicit)
end

local function getUnveiledModifierMagnitudeScalar(modLine)
	return getModifierMagnitudeScalar(modLine, modifierMagnitudeScalarDefs.unveiled)
end

local function appendAdvancedClipboardGroupModLines(item, targetList, group)
	for _, groupLine in ipairs(group.lines) do
		t_insert(targetList, buildAdvancedClipboardModLine(item, group, groupLine))
	end
end

local function appendAdvancedClipboardSpecialSourceModLines(item, resolved, group)
	local mod = resolved.mod or item:GetAffix(resolved.modId)
	for lineIndex, line in ipairs(mod or { }) do
		local groupLine = group and group.lines and group.lines[lineIndex] or nil
		t_insert(item.explicitModLines, buildResolvedCustomAffixModLine(mod, line, resolved.range, {
			veiled = resolved.sourceId == "VEILED",
			unscalable = groupLine and groupLine.unscalable or nil,
		}))
	end
end

local function applyAdvancedClipboardAffixGroup(item, group)
	local resolved = resolveAdvancedClipboardAffix(item, group)
	if not resolved then
		group.preserveOnCraft = true
		appendAdvancedClipboardGroupModLines(item, item.explicitModLines, group)
		return false
	end
	if resolved.sourceId then
		appendAdvancedClipboardSpecialSourceModLines(item, resolved, group)
		return false
	end
	item.crafted = true
	resolved.fractured = group.fractured
	resolved.displayLines = resolved.displayLines and copyTable(resolved.displayLines) or nil
	t_insert(group.type == "Prefix" and item.prefixes or item.suffixes, resolved)
	return true
end

local function getModifierMagnitudeScalars(modLineLists, checkVariant)
	local totalIncreases = {
		implicit = 0,
		unveiled = 0,
	}
	for _, modLineList in ipairs(modLineLists) do
		for _, modLine in ipairs(modLineList or { }) do
			if checkVariant(modLine) then
				local implicitScalar = getImplicitModifierMagnitudeScalar(modLine)
				if implicitScalar then
					totalIncreases.implicit = totalIncreases.implicit + (implicitScalar - 1) * 100
				end
				local unveiledScalar = getUnveiledModifierMagnitudeScalar(modLine)
				if unveiledScalar then
					totalIncreases.unveiled = totalIncreases.unveiled + (unveiledScalar - 1) * 100
				end
			end
		end
	end
	return {
		implicit = 1 + totalIncreases.implicit / 100,
		unveiled = 1 + totalIncreases.unveiled / 100,
	}
end

local function parseCraftedAffixSpec(specVal)
	local affix = { }
	specVal = specVal:gsub("{(.-)}", function(spec)
		local key, value = spec:match("^([^:]+):(.+)$")
		if key == "range" then
			affix.range = tonumber(value)
		elseif spec == "fractured" then
			affix.fractured = true
		end
		return ""
	end)
	affix.modId = specVal
	affix.range = affix.range or (specVal ~= "None" and main.defaultItemAffixQuality) or nil
	return affix
end

local function buildCraftedAffixSpec(affix)
	local spec = ""
	if affix.fractured then
		spec = spec .. "{fractured}"
	end
	if affix.range then
		spec = spec .. "{range:" .. round(affix.range, 3) .. "}"
	end
	return spec .. affix.modId
end

local function isAdvancedClipboardMetaLine(line)
	return influenceItemMap[line]
		or line == "Split"
		or line == "Mirrored"
		or line == "Corrupted"
		or line == "Fractured Item"
		or line == "Synthesised Item"
		or line == "Unidentified"
end

local function isBaseDisplayLine(item, line)
	if not item or not item.base or not line then
		return false
	end
	return line == item.base.type
		or line == item.base.subType
		or (item.base.subType and line == item.base.subType .. " " .. item.base.type)
end

local ignoredGameFooterLines = {
	["Right click to drink. Can only hold charges while in belt. Refills as you kill monsters."] = true,
	["Right click to activate. Only one Tincture in your belt can be active at a time. Mana Burn causes you to lose 1% of your maximum Mana per stack per second. Can be deactivated manually, or will automatically deactivate when you reach 0 Mana."] = true,
	["Place into an allocated Jewel Socket on the Passive Skill Tree. Right click to remove from the Socket."] = true,
}

local knownFlavourLineLookupCache = { }
local function getKnownFlavourLineLookup(title, item)
	if not title and not (item and item.title) then
		return
	end
	title = (title or item.title):gsub("^Foulborn%s+", "")
	local cacheKey = title
	if item and item.baseName then
		cacheKey = cacheKey .. "\31" .. item.baseName
	end
	if knownFlavourLineLookupCache[cacheKey] == nil then
		local lookup = { }
		for _, entry in pairs(data.flavourText or { }) do
			if entry.name == title and entry.text then
				for _, line in ipairs(entry.text) do
					lookup[line] = true
				end
			end
		end
		if item and item.rarity == "UNIQUE" and item.baseName then
			local unique = main and main.uniqueDB and main.uniqueDB.list and main.uniqueDB.list[title .. ", " .. item.baseName:gsub(" %(.+%)","")]
			if unique and unique.flavourText then
				for _, line in ipairs(unique.flavourText) do
					lookup[line] = true
				end
			end
		end
		knownFlavourLineLookupCache[cacheKey] = next(lookup) and lookup or false
	end
	return knownFlavourLineLookupCache[cacheKey] or nil
end

local function removeKnownFlavourTextFromExplicitMods(item)
	if item.rarity ~= "UNIQUE" and item.rarity ~= "RELIC" then
		return false
	end
	local flavourLookup = getKnownFlavourLineLookup(item.title, item)
	if not flavourLookup then
		return false
	end
	local filtered = { }
	local removed = false
	for _, modLine in ipairs(item.explicitModLines) do
		if not (modLine.extra and flavourLookup[modLine.line]) then
			t_insert(filtered, modLine)
		else
			removed = true
		end
	end
	item.explicitModLines = filtered
	return removed
end

local function escapeLuaPattern(text)
	return text:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

local function matchImportedEnchantLineToTemplate(line, templateLine)
	if line == templateLine then
		return true, nil
	end
	local ranges = { }
	local placeholderLine = templateLine:gsub("(%+?)%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)", function(plus, minStr, maxStr)
		t_insert(ranges, {
			sign = plus,
			min = tonumber(minStr),
			max = tonumber(maxStr),
		})
		return "__RANGE" .. #ranges .. "__"
	end)
	if not ranges[1] then
		return
	end
	local pattern = "^" .. escapeLuaPattern(placeholderLine) .. "$"
	for i = 1, #ranges do
		pattern = pattern:gsub("__RANGE" .. i .. "__", function()
			return "([%+%-]?[%d%.]+)"
		end, 1)
	end
	local captures = { line:match(pattern) }
	if #captures ~= #ranges then
		return
	end
	local resolvedRange
	for i, valueStr in ipairs(captures) do
		local value = tonumber(valueStr)
		local min = ranges[i].min
		local max = ranges[i].max
		if not value or not min or not max then
			return
		end
		local low = m_min(min, max)
		local high = m_max(min, max)
		if value < low or value > high then
			return
		end
		local lineRange
		if high ~= low then
			lineRange = (value - low) / (high - low)
		elseif value == low then
			lineRange = 0
		else
			return
		end
		if resolvedRange == nil then
			resolvedRange = lineRange
		elseif math.abs(resolvedRange - lineRange) > 0.001 then
			return
		end
	end
	return true, resolvedRange
end

local function canonicalizeEnchantModLines(item)
	if not item.enchantments or not item.enchantModLines[1] then
		return
	end
	local matchedAny = false
	local i = 1
	while i <= #item.enchantModLines do
		local bestMatch
		for _, sourceEnchants in pairs(item.enchantments) do
			for _, enchantLine in ipairs(sourceEnchants) do
				local templateParts = { }
				for part in enchantLine:gmatch("([^/]+)") do
					t_insert(templateParts, part)
				end
				if i + #templateParts - 1 <= #item.enchantModLines then
					local ranges = { }
					local matched = true
					for partIndex, templatePart in ipairs(templateParts) do
						local modLine = item.enchantModLines[i + partIndex - 1]
						local lineMatched, range = matchImportedEnchantLineToTemplate(modLine.line, templatePart)
						if not lineMatched then
							matched = false
							break
						end
						ranges[partIndex] = range
					end
					if matched and (not bestMatch or #templateParts > #bestMatch.parts) then
						bestMatch = {
							parts = templateParts,
							ranges = ranges,
						}
					end
				end
			end
		end
			if bestMatch then
				for partIndex, templatePart in ipairs(bestMatch.parts) do
					local modLine = item.enchantModLines[i + partIndex - 1]
					modLine.line = templatePart
					modLine.range = bestMatch.ranges[partIndex] ~= nil and bestMatch.ranges[partIndex] or modLine.range
				end
				matchedAny = true
				i = i + #bestMatch.parts
		else
			i = i + 1
		end
	end
	return matchedAny
end

local function isLikelyAdvancedUniqueFlavourTailLine(modLine)
	if not modLine or not modLine.extra then
		return false
	end
	local line = modLine.line or ""
	if line:find("%d") or line:find("%%") or line:match("^%b()$") then
		return false
	end
	if line:find("^\"") or line:find("\"$") then
		return true
	end
	if line:find("[%.!,;:]$") then
		return true
	end
	if line:find("'") and line:match("^[%a%s%p]+$") then
		return true
	end
	return false
end

local function buildAdvancedUniqueComparableKey(modLine)
	local key = modLine.line:gsub("\n", "\n")
	key = key:gsub("%(%-?[%d%.]+%-%-?[%d%.]+%)", "#")
	key = key:gsub("[%+%-]?%d+%.?%d*", "#")
	key = key:gsub("^[%+%-](.+)$", "%1")
	if modLine.enchant then
		key = key .. "\31enchant"
	end
	if modLine.implicit then
		key = key .. "\31implicit"
	end
	return key
end

local function collectAdvancedUniqueComparableEntries(item)
	local entries = { }
	for _, listInfo in ipairs({
		{ section = "enchantModLines", modList = item.enchantModLines },
		{ section = "implicitModLines", modList = item.implicitModLines },
		{ section = "explicitModLines", modList = item.explicitModLines },
	}) do
		local modList = listInfo.modList
		for _, modLine in ipairs(modList) do
			if item:CheckModLineVariant(modLine) then
				t_insert(entries, {
					key = buildAdvancedUniqueComparableKey(modLine),
					range = modLine.range,
					section = listInfo.section,
					modLine = copyTable(modLine),
				})
			end
		end
	end
	return entries
end

local function multisetScoreAdvancedUniqueEntries(importedEntries, candidateEntries)
	local remaining = { }
	for _, entry in ipairs(importedEntries) do
		remaining[entry.key] = (remaining[entry.key] or 0) + 1
	end
	local matches = 0
	for _, entry in ipairs(candidateEntries) do
		if (remaining[entry.key] or 0) > 0 then
			remaining[entry.key] = remaining[entry.key] - 1
			matches = matches + 1
		end
	end
	return matches
end

local function isBetterAdvancedUniqueSelection(candidate, bestSelection, selectionFields, template)
	if not bestSelection then
		return true
	end
	for _, field in ipairs(selectionFields) do
		local templateValue = template[field] or 0
		local candidateDelta = math.abs((candidate[field] or 0) - templateValue)
		local bestDelta = math.abs((bestSelection[field] or 0) - templateValue)
		if candidateDelta ~= bestDelta then
			return candidateDelta < bestDelta
		end
	end
	return false
end

local function maybeCanonicalizeAdvancedUnique(item, hadAdvancedClipboardGroups)
	if not hadAdvancedClipboardGroups or item.variantList or (item.rarity ~= "UNIQUE" and item.rarity ~= "RELIC") then
		return
	end
	if not main or not main.uniqueDB or main.uniqueDB.loading then
		return
	end
	local template = main.uniqueDB.list[item.name]
	if not template or not template.variantList then
		return
	end
	local importedEntries = collectAdvancedUniqueComparableEntries(item)
	if not importedEntries[1] then
		return
	end

	local selectionFields = { "variant" }
	if template.hasAltVariant then
		t_insert(selectionFields, "variantAlt")
	end
	if template.hasAltVariant2 then
		t_insert(selectionFields, "variantAlt2")
	end
	if template.hasAltVariant3 then
		t_insert(selectionFields, "variantAlt3")
	end
	if template.hasAltVariant4 then
		t_insert(selectionFields, "variantAlt4")
	end
	if template.hasAltVariant5 then
		t_insert(selectionFields, "variantAlt5")
	end
	if #selectionFields > 2 then
		return
	end

	local bestSelection
	local bestScore = -1
	local candidate = new("Item", template:BuildRaw())
	local function searchSelection(index)
		if index > #selectionFields then
			local score = multisetScoreAdvancedUniqueEntries(importedEntries, collectAdvancedUniqueComparableEntries(candidate))
			if score > bestScore or (score == bestScore and isBetterAdvancedUniqueSelection(candidate, bestSelection, selectionFields, template)) then
				bestScore = score
				bestSelection = { }
				for _, field in ipairs(selectionFields) do
					bestSelection[field] = candidate[field]
				end
			end
			return
		end
		local field = selectionFields[index]
		for variantId = 1, #candidate.variantList do
			candidate[field] = variantId
			searchSelection(index + 1)
		end
	end
	searchSelection(1)
	if not bestSelection or bestScore <= 0 then
		return
	end

	local resolved = new("Item", template:BuildRaw())
	for field, value in pairs(bestSelection) do
		resolved[field] = value
	end

	local importedByKey = { }
	for _, entry in ipairs(importedEntries) do
		importedByKey[entry.key] = importedByKey[entry.key] or { }
		t_insert(importedByKey[entry.key], entry)
	end
	for _, sectionName in ipairs({ "enchantModLines", "implicitModLines", "explicitModLines" }) do
		local filtered = { }
		for _, modLine in ipairs(resolved[sectionName]) do
			if resolved:CheckModLineVariant(modLine) then
				local list = importedByKey[buildAdvancedUniqueComparableKey(modLine)]
				if list and list[1] then
					modLine.range = list[1].range
					modLine.veiled = list[1].modLine and list[1].modLine.veiled or nil
					modLine.unscalable = list[1].modLine and list[1].modLine.unscalable or nil
					t_remove(list, 1)
					t_insert(filtered, modLine)
				end
			else
				t_insert(filtered, modLine)
			end
		end
		resolved[sectionName] = filtered
	end
	local resolvedFlavourLookup = getKnownFlavourLineLookup(resolved.title, resolved)
	for _, list in pairs(importedByKey) do
		for _, entry in ipairs(list) do
			if entry.modLine and resolved[entry.section]
				and not (entry.modLine.extra and resolvedFlavourLookup and resolvedFlavourLookup[entry.modLine.line])
				and not (entry.section == "explicitModLines" and isLikelyAdvancedUniqueFlavourTailLine(entry.modLine)) then
				t_insert(resolved[entry.section], copyTable(entry.modLine))
			end
		end
	end

	resolved.quality = item.quality
	resolved.catalyst = item.catalyst
	resolved.catalystQuality = item.catalystQuality
	resolved.itemLevel = item.itemLevel
	resolved.sockets = item.sockets
	resolved.flaskDisplayData = item.flaskDisplayData and copyTable(item.flaskDisplayData) or nil
	resolved.note = item.note
	resolved.split = item.split
	resolved.mirrored = item.mirrored
	resolved.corrupted = item.corrupted
	resolved.fractured = item.fractured
	resolved.synthesised = item.synthesised
	resolved.cleansing = item.cleansing
	resolved.tangle = item.tangle
	resolved.adjudicator = item.adjudicator
	resolved.basilisk = item.basilisk
	resolved.crusader = item.crusader
	resolved.eyrie = item.eyrie
	resolved.shaper = item.shaper
	resolved.elder = item.elder
	resolved:BuildAndParseRaw()
	return resolved
end

-- Parse raw item data and extract item name, base type, quality, and modifiers
function ItemClass:ParseRaw(raw, rarity, highQuality)
	self.raw = raw
	self.name = "?"
	self.namePrefix = ""
	self.nameSuffix = ""
	self.base = nil
	self.rarity = rarity or "UNIQUE"
	self.quality = nil
	self.flaskDisplayData = nil
	self.rawLines = { }
	-- Find non-blank lines and trim whitespace
	for line in raw:gmatch("%s*([^\n]*%S)") do
		t_insert(self.rawLines, line)
	end
	local mode = rarity and "GAME" or "WIKI"
	local l = 1
	local itemClass
	if self.rawLines[l] then
		if self.rawLines[l]:match("^Item Class:") then
			itemClass = self.rawLines[l]:gsub("^Item Class: %s+", "%1")
			l = l + 1 -- Item class is already determined by the base type
		end
		local rarity = self.rawLines[l]:match("^Rarity: (%a+)")
		if rarity then
			mode = "GAME"
			if colorCodes[rarity:upper()] then
				self.rarity = rarity:upper()
			end
			if self.rarity == "UNIQUE" or self.rarity == "RELIC" then
				-- Hack for relics
				for _, line in ipairs(self.rawLines) do
					if line:find("Foil Unique") then
						self.rarity = "RELIC"
						local captured = line:match("%((.-)%)")
						self.foilType = captured or "Rainbow"
						break
					end
				end
			end
			l = l + 1
		end
	end
	if self.rawLines[l] then
		self.name = self.rawLines[l]
		-- Determine if "Unidentified" item
		local unidentified = false
		for _, line in ipairs(self.rawLines) do
			if line == "Unidentified" then
				unidentified = true
				break
			end
		end

		-- Found the name for a rare or unique, but let's parse it if it's a magic or normal or Unidentified item to get the base
		if not (self.rarity == "NORMAL" or self.rarity == "MAGIC" or unidentified) then
			l = l + 1
		end
	end
	self.checkSection = false
	self.sockets = { }
	self.classRequirementModLines = { }
	self.buffModLines = { }
	self.enchantModLines = { }
	self.scourgeModLines = { }
	self.implicitModLines = { }
	self.explicitModLines = { }
	self.crucibleModLines = { }
	local implicitLines = 0
	self.variantList = nil
	self.prefixes = { }
	self.suffixes = { }
	self.requirements = { }
	self.requirements.str = 0
	self.requirements.dex = 0
	self.requirements.int = 0
	self.baseLines = { }
	local importedLevelReq
	local flaskBuffLines
	local tinctureBuffLines
	local deferJewelRadiusIndexAssignment
	local advancedClipboardGroups = { }
	local activeAdvancedClipboardGroup
	local strippedIgnoredMetadata
	local skipNextBuffReminderLine
	local gameModeStage = "FINDIMPLICIT"
	local foundExplicit, foundImplicit

	while self.rawLines[l] do	
		local line = self.rawLines[l]
		local advancedClipboardGroup
		if skipNextBuffReminderLine then
			skipNextBuffReminderLine = nil
			if line:match("^%b()$") then
				strippedIgnoredMetadata = true
				goto continue
			end
		end
		if ignoredGameFooterLines[line] then
			strippedIgnoredMetadata = true
			goto continue
		end
		advancedClipboardGroup = parseAdvancedClipboardDescriptor(line)
		if advancedClipboardGroup then
			activeAdvancedClipboardGroup = advancedClipboardGroup
			t_insert(advancedClipboardGroups, advancedClipboardGroup)
			goto continue
		end
		if activeAdvancedClipboardGroup and line ~= "--------" then
			if isAdvancedClipboardMetaLine(line) then
				activeAdvancedClipboardGroup = nil
			else
			if line:match("^%b()$") then
				goto continue
			end
			local advancedLine = normaliseAdvancedClipboardLine(line)
			if advancedLine then
				t_insert(activeAdvancedClipboardGroup.lines, advancedLine)
				goto continue
			end
			end
		elseif line == "--------" then
			activeAdvancedClipboardGroup = nil
		end
		if line == "Veiled Prefix" or line == "Veiled Suffix" then
			self.veiled = true
		end
		if flaskBuffLines and flaskBuffLines[line] then
			flaskBuffLines[line] = nil
			skipNextBuffReminderLine = true
		elseif tinctureBuffLines and tinctureBuffLines[line] then
			tinctureBuffLines[line] = nil
			skipNextBuffReminderLine = true
		elseif line == "--------" then
			self.checkSection = true
		elseif line == "Split" then
			self.split = true
		elseif line == "Mirrored" then
			self.mirrored = true
		elseif line == "Corrupted" then
			self.corrupted = true
		elseif line == "Fractured Item" then
			self.fractured = true
		elseif line == "Synthesised Item" then
			self.synthesised = true
		elseif line:match("Foil Unique") then
			local captured = line:match("%((.-)%)")
			self.foilType = captured or "Rainbow"
		elseif influenceItemMap[line] then
			self[influenceItemMap[line]] = true
		elseif line == "Requirements:" then
			-- nothing to do
		else
			if self.checkSection then
				if gameModeStage == "IMPLICIT" then
					if foundImplicit then
						-- There were definitely implicits, so any following modifiers must be explicits
						gameModeStage = "EXPLICIT"
						foundExplicit = true
					else
						gameModeStage = "FINDEXPLICIT"
					end
				elseif gameModeStage == "EXPLICIT" then
					gameModeStage = "DONE"
				elseif gameModeStage == "FINDIMPLICIT" and self.itemLevel and not line:match(" %(implicit%)") and
						not line:match(" %(enchant%)") and not line:find("Talisman Tier") then
					gameModeStage = "EXPLICIT"
					foundExplicit = true
				end
				self.checkSection = false
			end
			local specName, specVal = line:match("^([%a ]+:?): (.+)$")
			if specName then
				if specName == "Class:" then
					specName = "Requires Class"
				end
			else
				specName, specVal = line:match("^(Requires %a+) (.+)$")
			end
			if specName then
				if specName == "Unique ID" then
					self.uniqueID = specVal
				elseif specName == "Item Level" then
					self.itemLevel = specToNumber(specVal)
				elseif specName == "Memory Strands" then
					-- Metadata from Memories; not an item stat and should not survive import.
					strippedIgnoredMetadata = true
				elseif specName == "Requires Class" then
					self.classRestriction = specVal
				elseif specName == "Quality" then
					self.quality = specToNumber(specVal)
				elseif specName == "Sockets" then
					local group = 0
					for c in specVal:gmatch(".") do
						if c:match("[RGBWA]") then
							t_insert(self.sockets, { color = c, group = group })
						elseif c == " " then
							group = group + 1
						end
					end
				elseif specName == "Radius" and self.type == "Jewel" then
					self.jewelRadiusLabel = specVal:match("^%a+")
					if specVal:match("^%a+") == "Variable" then
                        -- Jewel radius is variable and must be read from it's mods instead after they are parsed
                        deferJewelRadiusIndexAssignment = true
                    else
                        for index, data in pairs(data.jewelRadius) do
                            if specVal:match("^%a+") == data.label then
                                self.jewelRadiusIndex = index
                                break
                            end
						end
					end
				elseif specName == "Limited to" and self.type == "Jewel" then
					self.limit = specToNumber(specVal)
				elseif specName == "Variant" then
					if not self.variantList then
						self.variantList = { }
					end
					-- This has to be kept for backwards compatibility
					local ver, name = specVal:match("{([%w_]+)}(.+)")
					if ver then
						t_insert(self.variantList, name)
					else
						t_insert(self.variantList, specVal)
					end
				elseif specName == "Talisman Tier" then
					self.talismanTier = specToNumber(specVal)
				elseif specName == "Armour" or specName == "Evasion Rating" or specName == "Evasion" or specName == "Energy Shield" or specName == "Ward" then
					if specName == "Evasion Rating" then
						specName = "Evasion"
						if self.baseName == "Two-Toned Boots (Armour/Energy Shield)" then
							-- Another hack for Two-Toned Boots
							self.baseName = "Two-Toned Boots (Armour/Evasion)"
							self.base = data.itemBases[self.baseName]
						end
					elseif specName == "Energy Shield" then
						specName = "EnergyShield"
						if self.baseName == "Two-Toned Boots (Armour/Evasion)" then
							-- Yet another hack for Two-Toned Boots
							self.baseName = "Two-Toned Boots (Evasion/Energy Shield)"
							self.base = data.itemBases[self.baseName]
						end
					end
					self.armourData = self.armourData or { }
					self.armourData[specName] = specToNumber(specVal)
				elseif specName:match("BasePercentile") then
					self.armourData = self.armourData or { }
					self.armourData[specName] = specToNumber(specVal) or 0
				elseif specName == "Requires Level" then
					self.requirements.level = specToNumber(specVal)
				elseif specName == "Level" then
					-- Requirements from imported items can't always be trusted
					importedLevelReq = specToNumber(specVal)
				elseif specName == "LevelReq" then
					self.requirements.level = specToNumber(specVal)
				elseif specName == "Has Alt Variant" then
					self.hasAltVariant = true
				elseif specName == "Has Alt Variant Two" then
					self.hasAltVariant2 = true
				elseif specName == "Has Alt Variant Three" then
					self.hasAltVariant3 = true
				elseif specName == "Has Alt Variant Four" then
					self.hasAltVariant4 = true
				elseif specName == "Has Alt Variant Five" then
					self.hasAltVariant5 = true
				elseif specName == "Selected Variant" then
					self.variant = specToNumber(specVal)
				elseif specName == "Selected Alt Variant" then
					self.variantAlt = specToNumber(specVal)
				elseif specName == "Selected Alt Variant Two" then
					self.variantAlt2 = specToNumber(specVal)
				elseif specName == "Selected Alt Variant Three" then
					self.variantAlt3 = specToNumber(specVal)
				elseif specName == "Selected Alt Variant Four" then
					self.variantAlt4 = specToNumber(specVal)
				elseif specName == "Selected Alt Variant Five" then
					self.variantAlt5 = specToNumber(specVal)
				elseif specName == "Has Variants" or specName == "Selected Variants" then
					-- Need to skip this line for backwards compatibility
					-- with builds that used an old Watcher's Eye implementation
					l = l + 1
				elseif specName == "League" then
					self.league = specVal
				elseif specName == "Crafted" then
					self.crafted = true
				elseif specName == "Scourge" then
					self.scourge = true
				elseif specName == "Crucible" then
					self.crucible = true
				elseif specName == "Implicit" then
					self.implicit = true
				elseif specName == "Prefix" then
					t_insert(self.prefixes, parseCraftedAffixSpec(specVal))
				elseif specName == "Suffix" then
					t_insert(self.suffixes, parseCraftedAffixSpec(specVal))
				elseif specName == "Implicits" then
					implicitLines = specToNumber(specVal) or 0
					gameModeStage = "EXPLICIT"
				elseif specName == "Unreleased" then
					self.unreleased = (specVal == "true")
				elseif specName == "Upgrade" then
					self.upgradePaths = self.upgradePaths or { }
					t_insert(self.upgradePaths, specVal)
				elseif specName == "Source" then
					self.source = specVal
				elseif specName == "Cluster Jewel Skill" then
					if self.clusterJewel and self.clusterJewel.skills[specVal] then
						self.clusterJewelSkill = specVal
					end
				elseif specName == "Cluster Jewel Node Count" then
					if self.clusterJewel then
						local num = specToNumber(specVal) or self.clusterJewel.maxNodes
						self.clusterJewelNodeCount = m_min(m_max(num, self.clusterJewel.minNodes), self.clusterJewel.maxNodes)
					end
				elseif specName == "Catalyst" then
					for i=1, #catalystList do
						if specVal == catalystList[i] then
							self.catalyst = i
						end
					end
				elseif specName == "CatalystQuality" then
					self.catalystQuality = specToNumber(specVal)
				elseif specName == "Note" then
					self.note = specVal
				elseif specName == "Str" or specName == "Strength" or specName == "Dex" or specName == "Dexterity" or
				       specName == "Int" or specName == "Intelligence" then
					self.requirements[specName:sub(1,3):lower()] = specToNumber(specVal)
				elseif specName == "Critical Strike Range" or specName == "Attacks per Second" or specName == "Weapon Range" or
				       specName == "Critical Strike Chance" or specName == "Physical Damage" or specName == "Elemental Damage" or
				       specName == "Chaos Damage" or specName == "Chance to Block" or specName == "Block chance" or
					specName == "Armour" or specName == "Energy Shield" or specName == "Evasion" then
					self.hidden_specs = true
				-- Anything else is an explicit with a colon in it (Fortress Covenant, Pure Talent, etc) unless it's part of the custom name
				elseif not (self.name:match(specName) and self.name:match(specVal)) then
					foundExplicit = true
					gameModeStage = "EXPLICIT"
				end
			end
			if line == "Prefixes:" then
				foundExplicit = true
				gameModeStage = "EXPLICIT"
			end
			if not specName or foundExplicit or foundImplicit then
				local modLine = { modTags = {} }

				line = line:gsub("{(%a*):?([^}]*)}", function(k,val)
					if k == "variant" then
						modLine.variantList = { }
						for varId in val:gmatch("%d+") do
							modLine.variantList[tonumber(varId)] = true
						end
					elseif k == "tags" then
						for tag in val:gmatch("[%a_]+") do
							t_insert(modLine.modTags, tag)
						end
					elseif k == "range" then
						modLine.range = tonumber(val)
					elseif lineFlags[k] then
						modLine[k] = true
					end

					return ""
				end)

				line = line:gsub(" %((%l+)%)", function(k)
					if lineFlags[k] then
						modLine[k] = true
					end
					return ""
				end)

				if modLine.enchant then
					modLine.crafted = true
					modLine.implicit = true
				end

				local baseName
				if not self.base and (self.rarity == "NORMAL" or self.rarity == "MAGIC") then
					-- Exact match (affix-less magic and normal items)
					if self.name:match("Energy Blade") and itemClass then -- Special handling for energy blade base.
						self.name = itemClass:match("One Hand") and "Energy Blade One Handed" or "Energy Blade Two Handed"
					end
					if data.itemBases[self.name] then
						baseName = self.name
					else
						local bestMatch = {length = -1}
						-- Partial match (magic items with affixes)
						for itemBaseName, baseData in pairs(data.itemBases) do
							local s, e = self.name:find(itemBaseName, 1, true)
							if s and e and (e-s > bestMatch.length) then
								bestMatch.match = itemBaseName
								bestMatch.length = e-s
								bestMatch.e = e
								bestMatch.s = s
							end
						end
						if bestMatch.match then
							self.namePrefix = self.name:sub(1, bestMatch.s - 1)
							self.nameSuffix = self.name:sub(bestMatch.e + 1)
							baseName = bestMatch.match
						end
					end
					if not baseName then
						local s, e = self.name:find("Two-Toned Boots", 1, true)
						if s then
							-- Hack for Two-Toned Boots
							baseName = "Two-Toned Boots"
							self.namePrefix = self.name:sub(1, s - 1)
							self.nameSuffix = self.name:sub(e + 1)
						end
					end
					self.name = self.name:gsub(" %(.+%)","")
				end
				if not baseName then
					baseName = line:gsub("^Superior ", ""):gsub("^Synthesised ","")
				end
				if baseName == "Two-Toned Boots" then
					baseName = "Two-Toned Boots (Armour/Energy Shield)"
				end
				local base = data.itemBases[baseName]
				if base then
					-- Items with variants can have multiple bases
					self.baseLines[baseName] = { line = baseName, variantList = modLine.variantList }
					-- Set the actual base if variant matches or doesn't have variants
					if not self.variant or not modLine.variantList or modLine.variantList[self.variant] then
						self.baseName = baseName
						if not (self.rarity == "NORMAL" or self.rarity == "MAGIC") then
							self.title = self.name
						end
						if self.title and self.title:find("Foulborn") then
							self.foulborn = true
						end
						self.type = base.type
						self.base = base
						self.affixes = (self.base.subType and data.itemMods[self.base.type..self.base.subType])
								or data.itemMods[self.base.type]
								or data.itemMods.Item
						if self.base.flask then
							if self.base.utility_flask then
								self.enchantments = data.enchantments["UtilityFlask"]
							else
								self.enchantments = data.enchantments["Flask"]
							end
						else
							self.enchantments = data.enchantments[self.base.type]
						end
						self.corruptible = self.base.type ~= "Flask"
						self.canBeInfluenced = self.base.influenceTags ~= nil
						self.clusterJewel = data.clusterJewels and data.clusterJewels.jewels[self.baseName]
						self.requirements.str = self.base.req.str or 0
						self.requirements.dex = self.base.req.dex or 0
						self.requirements.int = self.base.req.int or 0
						local maxReq = m_max(self.requirements.str, self.requirements.dex, self.requirements.int)
						self.defaultSocketColor = (maxReq == self.requirements.dex and "G") or (maxReq == self.requirements.int and "B") or "R"
						if self.base.flask and self.base.flask.buff and not flaskBuffLines then
							flaskBuffLines = { }
							for _, line in ipairs(self.base.flask.buff) do
								flaskBuffLines[line] = true
								local modList, extra = modLib.parseMod(line)
								t_insert(self.buffModLines, { line = line, extra = extra, modList = modList or { } })
							end
						end
						if self.base.tincture and self.base.tincture.buff and not tinctureBuffLines then
							tinctureBuffLines = { }
							for _, line in ipairs(self.base.tincture.buff) do
								tinctureBuffLines[line] = true
								local modList, extra = modLib.parseMod(line)
								t_insert(self.buffModLines, { line = line, extra = extra, modList = modList or { } })
							end
						end
					end
					-- Base lines don't need mod parsing, skip it
					goto continue
				end
				if self.base and self.base.flask then
					local duration = line:match("^Lasts ([%d%.]+) Seconds$")
					if duration then
						self.flaskDisplayData = self.flaskDisplayData or { }
						self.flaskDisplayData.duration = tonumber(duration)
						goto continue
					end
					local chargesUsed, chargesMax = line:match("^Consumes (%d+) of (%d+) Charges on use$")
					if chargesUsed then
						self.flaskDisplayData = self.flaskDisplayData or { }
						self.flaskDisplayData.chargesUsed = tonumber(chargesUsed)
						self.flaskDisplayData.chargesMax = tonumber(chargesMax)
						goto continue
					end
					local currentCharges = line:match("^Currently has (%d+) Charges$")
					if currentCharges then
						self.flaskDisplayData = self.flaskDisplayData or { }
						self.flaskDisplayData.currentCharges = tonumber(currentCharges)
						goto continue
					end
				elseif self.base and self.base.tincture then
					local manaBurn = line:match("^Inflicts Mana Burn every ([%d%.]+) Seconds$")
					if manaBurn then
						strippedIgnoredMetadata = true
						goto continue
					end
					local cooldown = line:match("^[%d%.]+ Second Cooldown [Ww]hen Deactivated$")
					if cooldown then
						strippedIgnoredMetadata = true
						goto continue
					end
				end
				if modLine.implicit then
					foundImplicit = true
					gameModeStage = "IMPLICIT"
				end
				local catalystScalar = getCatalystScalar(self.catalyst, modLine.modTags, self.catalystQuality)
				local rangedLine = itemLib.applyRange(line, 1, catalystScalar)
				local modList, extra = modLib.parseMod(rangedLine)
				if (not modList or extra) and self.rawLines[l+1] then
					-- Try to combine it with the next line
					local nextLine = self.rawLines[l+1]:gsub("%b{}", ""):gsub(" ?%(%l+%)","")
					local combLine = line.." "..nextLine
					rangedLine = itemLib.applyRange(combLine, 1, catalystScalar)
					modList, extra = modLib.parseMod(rangedLine, true)
					if modList and not extra then
						line = line.."\n"..nextLine
						l = l + 1
					else
						modList, extra = modLib.parseMod(rangedLine)
					end
				end

				local lineLower = line:lower()
				if lineLower == "implicit modifiers cannot be changed" then
					self.implicitsCannotBeChanged = true
				elseif lineLower:match(" prefix modifiers? allowed") then
					self.prefixes.limit = (self.prefixes.limit or 0) + (tonumber(lineLower:match("%+(%d+) prefix modifiers? allowed")) or 0) - (tonumber(lineLower:match("%-(%d+) prefix modifiers? allowed")) or 0)
				elseif lineLower:match(" suffix modifiers? allowed") then
					self.suffixes.limit = (self.suffixes.limit or 0) + (tonumber(lineLower:match("%+(%d+) suffix modifiers? allowed")) or 0) - (tonumber(lineLower:match("%-(%d+) suffix modifiers? allowed")) or 0)
				elseif lineLower:find("can be anointed") then -- blight uniques and Cord Belt
					self.canBeAnointed = true
				elseif lineLower == "can have a second enchantment modifier" then
					self.canHaveTwoEnchants = true
				elseif lineLower == "can have 1 additional enchantment modifiers" then
					self.canHaveTwoEnchants = true
				elseif lineLower == "can have 2 additional enchantment modifiers" then
					self.canHaveTwoEnchants = true
					self.canHaveThreeEnchants = true
				elseif lineLower == "can have 3 additional enchantment modifiers" then
					self.canHaveTwoEnchants = true
					self.canHaveThreeEnchants = true
					self.canHaveFourEnchants = true
				elseif lineLower == "has elder, shaper and all conqueror influences" then
					self.HasElderShaperAndAllConquerorInfluences = true
					for _, curInfluenceInfo in ipairs(itemLib.influenceInfo.default) do
						self[curInfluenceInfo.key] = true
					end
				elseif lineLower:match("if the eater of worlds is dominant") then
					self.canHaveEldritchInfluence = true
				elseif lineLower == "has a crucible passive skill tree with only support passive skills" then
					self.canHaveOnlySupportSkillsCrucibleTree = true
				elseif lineLower == "has a crucible passive skill tree" then
					self.canHaveShieldCrucibleTree = true
				elseif lineLower == "has a two handed sword crucible passive skill tree" then
					self.canHaveTwoHandedSwordCrucibleTree = true
				elseif lineLower == "cannot roll caster modifiers" then
					self.restrictTag = true
					self.noCaster = true
				elseif lineLower == "cannot roll attack modifiers" then
					self.restrictTag = true
					self.noAttack = true
				elseif lineLower == "cannot roll modifiers of non-cold damage types" then
					self.restrictDamageType = true
					self.onlyColdDamage = true
				elseif lineLower == "cannot roll modifiers of non-fire damage types" then
					self.restrictDamageType = true
					self.onlyFireDamage = true
				elseif lineLower == "cannot roll modifiers of non-lightning damage types" then
					self.restrictDamageType = true
					self.onlyLightningDamage = true
				elseif lineLower == "cannot roll modifiers of non-chaos damage types" then
					self.restrictDamageType = true
					self.onlyChaosDamage = true
				elseif lineLower == "cannot roll modifiers of non-physical damage types" then
					self.restrictDamageType = true
					self.onlyPhysicalDamage = true
				end

				local modLines
				if modLine.enchant or (modLine.crafted and #self.enchantModLines + #self.implicitModLines < implicitLines) then
					modLines = self.enchantModLines
				elseif modLine.scourge then
					modLines = self.scourgeModLines
				elseif line:find("Requires Class") then
					modLines = self.classRequirementModLines
				elseif modLine.implicit or (not modLine.crafted and #self.enchantModLines + #self.scourgeModLines + #self.implicitModLines < implicitLines) then
					modLines = self.implicitModLines
				elseif modLine.crucible then
					modLines = self.crucibleModLines
				else
					modLines = self.explicitModLines
				end
				modLine.line = line
				if modLines == self.implicitModLines then
					modLine.implicit = true
				end
				if modList then
					modLine.modList = modList
					modLine.extra = extra
					modLine.valueScalar = catalystScalar
					modLine.range = modLine.range or main.defaultItemAffixQuality
					t_insert(modLines, modLine)
					if mode == "GAME" then
						if gameModeStage == "FINDIMPLICIT" then
							gameModeStage = "IMPLICIT"
						elseif gameModeStage == "FINDEXPLICIT" then
							foundExplicit = true
							gameModeStage = "EXPLICIT"
						elseif gameModeStage == "EXPLICIT" then
							foundExplicit = true
						end
					else
						foundExplicit = true
					end
				elseif mode == "GAME" then
					if gameModeStage == "IMPLICIT" or gameModeStage == "EXPLICIT" or (gameModeStage == "FINDIMPLICIT" and (not data.itemBases[line]) and not (self.name == line) and not line:find("Two%-Toned") and not isBaseDisplayLine(self, line)) then
						modLine.modList = { }
						modLine.extra = line
						t_insert(modLines, modLine)
					elseif gameModeStage == "FINDEXPLICIT" then
						gameModeStage = "DONE"
					end
				elseif foundExplicit or (not foundExplicit and gameModeStage == "EXPLICIT") then
					modLine.modList = { }
					modLine.extra = line
					t_insert(modLines, modLine)
				end
			end
		end
		::continue::
		l = l + 1
	end
	if self.baseName and self.title then
		self.name = self.title .. ", " .. self.baseName:gsub(" %(.+%)","")
	end
	if self.base and not self.requirements.level then
		if importedLevelReq and #self.sockets == 0 then
			-- Requirements on imported items can only be trusted for items with no sockets
			self.requirements.level = importedLevelReq
		else
			self.requirements.level = self.base.req.level
		end
	end
	local strippedKnownFlavour = removeKnownFlavourTextFromExplicitMods(self)
	local normalisedEnchantLines = canonicalizeEnchantModLines(self)
	local advancedAffixGroupCount = 0
	local advancedAffixResolvedCount = 0
	local hadAdvancedClipboardGroups = advancedClipboardGroups[1] ~= nil
	for _, group in ipairs(advancedClipboardGroups) do
		if group.type == "Implicit" then
			appendAdvancedClipboardGroupModLines(self, self.implicitModLines, group)
		elseif group.type == "Prefix" or group.type == "Suffix" then
			advancedAffixGroupCount = advancedAffixGroupCount + 1
			if applyAdvancedClipboardAffixGroup(self, group) then
				advancedAffixResolvedCount = advancedAffixResolvedCount + 1
			end
		else
			appendAdvancedClipboardGroupModLines(self, self.explicitModLines, group)
		end
	end
	self.affixLimit = 0
	if self.crafted then
		if not self.affixes then 
			self.crafted = false
		elseif self.rarity == "MAGIC" then
			if self.prefixes.limit or self.suffixes.limit then
				self.prefixes.limit = m_max(m_min((self.prefixes.limit or 0) + 1, 2), 0)
				self.suffixes.limit = m_max(m_min((self.suffixes.limit or 0) + 1, 2), 0)
				self.affixLimit = self.prefixes.limit + self.suffixes.limit
			else
				self.affixLimit = 2
			end
		elseif self.rarity == "RARE" then
			self.affixLimit = (((self.type == "Jewel" and not (self.base.subType == "Abyss" and self.corrupted)) or self.type == "Graft") and 4 or 6)
			if self.prefixes.limit or self.suffixes.limit then
				self.prefixes.limit = m_max(m_min((self.prefixes.limit or 0) + self.affixLimit / 2, self.affixLimit), 0)
				self.suffixes.limit = m_max(m_min((self.suffixes.limit or 0) + self.affixLimit / 2, self.affixLimit), 0)
				self.affixLimit = self.prefixes.limit + self.suffixes.limit
			end
		else
			self.crafted = false
		end
		if self.crafted then
			for _, list in ipairs({self.prefixes,self.suffixes}) do
				for i = 1, (list.limit or (self.affixLimit / 2)) do
					if not list[i] then
						list[i] = { modId = "None" }
						elseif list[i].modId ~= "None" and not self.affixes[list[i].modId] then
						if not self:GetAffix(list[i].modId) then
							for modId, mod in pairs(self.affixes) do
								if list[i].modId == mod.affix then
									list[i].modId = modId
									break
								end
							end
							if not self:GetAffix(list[i].modId) then
								list[i].modId = "None"
							end
						end
					end
				end
			end
		end
	end
	if advancedAffixResolvedCount > 0 and self.crafted then
		self:RebuildExplicitModLinesFromAffixes(copyTable(self.explicitModLines))
	end
	if hadAdvancedClipboardGroups or strippedIgnoredMetadata or strippedKnownFlavour or normalisedEnchantLines then
		self.raw = self:BuildRaw()
	end
	if self.base and self.base.socketLimit then
		if #self.sockets == 0 then
			for i = 1, self.base.socketLimit do
				t_insert(self.sockets, {
					color = self.defaultSocketColor,
					group = 0,
				})
			end
		end
	end
	self.abyssalSocketCount = 0
	if self.variantList then
		self.variant = m_min(#self.variantList, self.variant or #self.variantList)
		if self.hasAltVariant then
			self.variantAlt = m_min(#self.variantList, self.variantAlt or #self.variantList)
		end
		if self.hasAltVariant2 then
			self.variantAlt2 = m_min(#self.variantList, self.variantAlt2 or #self.variantList)
		end
		if self.hasAltVariant3 then
			self.variantAlt3 = m_min(#self.variantList, self.variantAlt3 or #self.variantList)
		end
		if self.hasAltVariant4 then
			self.variantAlt4 = m_min(#self.variantList, self.variantAlt4 or #self.variantList)
		end
		if self.hasAltVariant5 then
			self.variantAlt5 = m_min(#self.variantList, self.variantAlt5 or #self.variantList)
		end
	end
	if not self.quality then
		self:NormaliseQuality()
		if highQuality then
			-- Behavior of NormaliseQuality should be looked at because calling it twice has different results.
			-- Leaving it alone for now. Just moving it here from Main.lua so BuildAndParseRaw doesn't need to be called.
			self:NormaliseQuality()
		end
	end
	self:BuildModList()
	local canonicalUnique = maybeCanonicalizeAdvancedUnique(self, hadAdvancedClipboardGroups)
	if canonicalUnique then
		wipeTable(self)
		for key, value in pairs(canonicalUnique) do
			self[key] = value
		end
	end
	if deferJewelRadiusIndexAssignment then
		self.jewelRadiusIndex = self.jewelData.radiusIndex
	end
end

function ItemClass:NormaliseQuality()
	if self.base and (self.base.armour or self.base.weapon or self.base.flask or self.base.tincture) then
		if not self.quality then
			self.quality = 0
		elseif not self.uniqueID and not self.corrupted and not self.split and not self.mirrored and self.quality < 20 then
			self.quality = 20
		end
	end	
end

function ItemClass:GetModSpawnWeight(mod, includeTags, excludeTags)
	local weight = 0
	if self.base then
		local function HasInfluenceTag(key)
			if self.base.influenceTags then
				for _, curInfluenceInfo in ipairs(influenceInfo) do
					if self[curInfluenceInfo.key] and self.base.influenceTags[curInfluenceInfo.key] == key then
						return true
					end
				end
			end
			return false
		end

		local function HasMavenInfluence(modAffix)
			return modAffix:match("Elevated")
		end
		if self.restrictTag then
			for _, key in ipairs(mod.modTags) do
				local flagName = "no" .. key:gsub("^%l", string.upper)
				if flagName and self[flagName] then
					return 0
				end
			end
		end
		if self.restrictDamageType then
			local required, restricted = false, {}
			for _, element in ipairs({ "fire", "cold", "lightning", "chaos", "physical" }) do
				local flagName = "only" .. element:gsub("^%l", string.upper) .. "Damage"
				if self[flagName] then
					required = true
				else
					restricted[element] = true
				end
			end
			if required then
				for _, key in ipairs(mod.modTags) do
					if restricted[key] then
						return 0
					end
				end
			end
		end

		for i, key in ipairs(mod.weightKey) do
			if (self.base.tags[key] or (includeTags and includeTags[key]) or HasInfluenceTag(key)) and not (excludeTags and excludeTags[key]) then
				weight = (HasInfluenceTag(key) and HasMavenInfluence(mod.affix)) and 1000 or mod.weightVal[i]
				break
			end
		end
		for i, key in ipairs(mod.weightMultiplierKey or {}) do
			if (self.base.tags[key] or (includeTags and includeTags[key]) or HasInfluenceTag(key)) and not (excludeTags and excludeTags[key]) then
				weight = weight * mod.weightMultiplierVal[i] / 100
				break
			end
		end
	end
	return weight
end

function ItemClass:GetNecropolisModSpawnWeight(mod)
	local weight = 0
	if self.base then
		for i, key in ipairs(mod.weightKey) do
			if self.base.tags[key:gsub("necropolis_", "")] then
				weight = mod.weightVal[i]
				break
			end
		end
	end
	return weight
end

function ItemClass:CheckIfModIsDelve(mod)
	local sourceDef = getAdvancedClipboardSpecialSource("Subterranean")
	return sourceDef and sourceDef.matchesAffix(mod.affix) or false
end

function ItemClass:CheckIfModIsEssence(mod)
	local sourceDef = getAdvancedClipboardSpecialSource("Essences")
	return sourceDef and sourceDef.matchesAffix(mod.affix) or false
end

function ItemClass:CheckIfModIsVeiled(mod)
	local sourceDef = getAdvancedClipboardSpecialSourceById("VEILED")
	return sourceDef and sourceDef.matchesMod(mod) or false
end

function ItemClass:CheckIfModIsBeastCraft(mod)
	local sourceDef = getAdvancedClipboardSpecialSource("of Farrul")
	return sourceDef and sourceDef.matchesAffix(mod.affix) or false
end

function ItemClass:CheckIfModUsesSpecialSource(mod)
	return self:CheckIfModIsDelve(mod)
		or self:CheckIfModIsEssence(mod)
		or self:CheckIfModIsVeiled(mod)
		or self:CheckIfModIsBeastCraft(mod)
end

function ItemClass:GetAffix(modId)
	return getFallbackAffix(self, modId)
end


function ItemClass:BuildRaw()
	local rawLines = { }
	t_insert(rawLines, "Rarity: " .. self.rarity)
	if self.title then
		t_insert(rawLines, self.title)
		t_insert(rawLines, self.baseName)
	else
		t_insert(rawLines, (self.namePrefix or "") .. self.baseName .. (self.nameSuffix or ""))
	end
	if self.armourData then
		for _, type in ipairs({ "Armour", "Evasion", "EnergyShield", "Ward" }) do
			if self.armourData[type] and self.armourData[type] > 0 then
				t_insert(rawLines, type:gsub("EnergyShield", "Energy Shield") .. ": " .. self.armourData[type])
				if self.armourData[type .. "BasePercentile"] then
					t_insert(rawLines, type .. "BasePercentile: " .. self.armourData[type .. "BasePercentile"])
				end
			end
		end
	end
	if self.uniqueID then
		t_insert(rawLines, "Unique ID: " .. self.uniqueID)
	end
	if self.league then
		t_insert(rawLines, "League: " .. self.league)
	end
	if self.unreleased then
		t_insert(rawLines, "Unreleased: true")
	end
	for i, curInfluenceInfo in ipairs(influenceInfo) do
		if self[curInfluenceInfo.key] then
			t_insert(rawLines, curInfluenceInfo.display .. " Item")
		end
	end
	if self.crafted then
		t_insert(rawLines, "Crafted: true")
		for i, affix in ipairs(self.prefixes or { }) do
			t_insert(rawLines, "Prefix: " .. buildCraftedAffixSpec(affix))
		end
		for i, affix in ipairs(self.suffixes or { }) do
			t_insert(rawLines, "Suffix: " .. buildCraftedAffixSpec(affix))
		end
	end
	if self.catalyst and self.catalyst > 0 then
		t_insert(rawLines, "Catalyst: " .. catalystList[self.catalyst])
	end
	if self.catalystQuality then
		t_insert(rawLines, "CatalystQuality: " .. self.catalystQuality)
	end
	if self.clusterJewel then
		if self.clusterJewelSkill then
			t_insert(rawLines, "Cluster Jewel Skill: " .. self.clusterJewelSkill)
		end
		if self.clusterJewelNodeCount then
			t_insert(rawLines, "Cluster Jewel Node Count: " .. self.clusterJewelNodeCount)
		end
	end
	if self.talismanTier then
		t_insert(rawLines, "Talisman Tier: " .. self.talismanTier)
	end
	if self.itemLevel then
		t_insert(rawLines, "Item Level: " .. self.itemLevel)
	end
	local function writeModLine(modLine)
		local line = modLine.line
		if modLine.range and line:match("%(%-?[%d%.]+%-%-?[%d%.]+%)") then
			line = "{range:" .. round(modLine.range, 3) .. "}" .. line
		end
		if modLine.crafted then
			line = "{crafted}" .. line
		end
		if modLine.custom then
			line = "{custom}" .. line
		end
		if modLine.scourge then
			line = "{scourge}" .. line
		end
		if modLine.crucible then
			line = "{crucible}" .. line
		end
		if modLine.mutated then
			line = "{mutated}" .. line
		end
		if modLine.fractured then
			line = "{fractured}" .. line
		end
		if modLine.exarch then
			line = "{exarch}" .. line
		end
		if modLine.eater then
			line = "{eater}" .. line
		end
		if modLine.veiled then
			line = "{veiled}" .. line
		end
		if modLine.unscalable then
			line = "{unscalable}" .. line
		end
			if modLine.synthesis then
				line = "{synthesis}" .. line
			end
			if modLine.specialSource then
				line = "{specialSource}" .. line
			end
			if modLine.variantList then
			local varSpec
			for varId in pairs(modLine.variantList) do
				varSpec = (varSpec and varSpec .. "," or "") .. varId
			end
			local var = "{variant:" .. varSpec .. "}"
			line = var .. line:gsub("\n", "\n" .. var) -- Variants that go over 1 line need to have the gsub to fix there being no "variant:" at the start
		end
		if modLine.modTags and #modLine.modTags > 0 then
			line = "{tags:" .. table.concat(modLine.modTags, ",") .. "}" .. line
		end
		t_insert(rawLines, line)
	end
	if self.variantList then
		for _, variantName in ipairs(self.variantList) do
			t_insert(rawLines, "Variant: " .. variantName)
		end
		t_insert(rawLines, "Selected Variant: " .. self.variant)

		for _, baseLine in pairs(self.baseLines) do
			if baseLine.variantList then
				writeModLine(baseLine)
			end
		end	
		if self.hasAltVariant then
			t_insert(rawLines, "Has Alt Variant: true")
			t_insert(rawLines, "Selected Alt Variant: " .. self.variantAlt)
		end
		if self.hasAltVariant2 then
			t_insert(rawLines, "Has Alt Variant Two: true")
			t_insert(rawLines, "Selected Alt Variant Two: " .. self.variantAlt2)
		end
		if self.hasAltVariant3 then
			t_insert(rawLines, "Has Alt Variant Three: true")
			t_insert(rawLines, "Selected Alt Variant Three: " .. self.variantAlt3)
		end
		if self.hasAltVariant4 then
			t_insert(rawLines, "Has Alt Variant Four: true")
			t_insert(rawLines, "Selected Alt Variant Four: " .. self.variantAlt4)
		end
		if self.hasAltVariant5 then
			t_insert(rawLines, "Has Alt Variant Five: true")
			t_insert(rawLines, "Selected Alt Variant Five: " .. self.variantAlt5)
		end
	end
	if self.quality then
		t_insert(rawLines, "Quality: " .. self.quality)
	end
	if self.base and self.base.flask and (self.flaskData or self.flaskDisplayData) then
		local displayData = self.flaskData or self.flaskDisplayData
		local currentCharges = self.flaskDisplayData and self.flaskDisplayData.currentCharges or displayData.currentCharges
		if displayData.duration then
			t_insert(rawLines, string.format("Lasts %.2f Seconds", displayData.duration))
		end
		if displayData.chargesUsed and displayData.chargesMax then
			t_insert(rawLines, string.format("Consumes %d of %d Charges on use", displayData.chargesUsed, displayData.chargesMax))
		end
		if currentCharges then
			t_insert(rawLines, string.format("Currently has %d Charges", currentCharges))
		end
	end
	if self.sockets and #self.sockets > 0 then
		local line = "Sockets: "
		for i, socket in pairs(self.sockets) do
			line = line .. socket.color
			if self.sockets[i+1] then
				line = line .. (socket.group == self.sockets[i+1].group and "-" or " ")
			end
		end
		t_insert(rawLines, line)
	end
	if self.requirements and self.requirements.level then
		t_insert(rawLines, "LevelReq: " .. self.requirements.level)
	end
	if self.jewelRadiusLabel then
		t_insert(rawLines, "Radius: " .. self.jewelRadiusLabel)
	end
	if self.limit then
		t_insert(rawLines, "Limited to: " .. self.limit)
	end
	if self.classRestriction then
		t_insert(rawLines, "Requires Class " .. self.classRestriction)
	end
	t_insert(rawLines, "Implicits: " .. (#self.enchantModLines + #self.implicitModLines + #self.scourgeModLines))
	for _, modLine in ipairs(self.enchantModLines) do
		writeModLine(modLine)
	end
	for _, modLine in ipairs(self.scourgeModLines) do
		writeModLine(modLine)
	end
	for _, modLine in ipairs(self.classRequirementModLines) do
		writeModLine(modLine)
	end
	for _, modLine in ipairs(self.implicitModLines) do
		writeModLine(modLine)
	end
	for _, modLine in ipairs(self.explicitModLines) do
		writeModLine(modLine)
	end
	for _, modLine in ipairs(self.crucibleModLines) do
		writeModLine(modLine)
	end
	if self.split then
		t_insert(rawLines, "Split")
	end
	if self.mirrored then
		t_insert(rawLines, "Mirrored")
	end
	if self.fractured then
		t_insert(rawLines, "Fractured Item")
	end
	if self.corrupted or self.scourge then
		t_insert(rawLines, "Corrupted")
	end
	if self.foilType then
		t_insert(rawLines, "Foil Unique" .. " (" .. self.foilType .. ")")
	end
	return table.concat(rawLines, "\n")
end

function ItemClass:BuildAndParseRaw()
	if self.base and self.base.flask then
		self:BuildModList()
	end
	local raw = self:BuildRaw()
	self:ParseRaw(raw)
end

function ItemClass:RebuildExplicitModLinesFromAffixes(savedMods)
	savedMods = savedMods or { }
	wipeTable(self.explicitModLines)
	self.namePrefix = ""
	self.nameSuffix = ""
	self.requirements.level = self.base.req.level
	local statOrder = { }
	local savedQualityMods = { }
	local savedOtherMods = { }
	local function rebuildParsedLine(modLine)
		local modList, extra = modLib.parseMod(modLine.line)
		modLine.modList = modList or { }
		modLine.extra = extra
	end
	for _, mod in ipairs(savedMods) do
		if mod.line and mod.line:match("^Quality %([^)]+ Modifiers%): ") then
			t_insert(savedQualityMods, mod)
		else
			t_insert(savedOtherMods, mod)
		end
	end
	for _, mod in ipairs(savedQualityMods) do
		t_insert(self.explicitModLines, mod)
	end
	for _, list in ipairs({self.prefixes,self.suffixes}) do
		for i = 1, (list.limit or (self.affixLimit / 2)) do
			local affix = list[i]
			if not affix then
				list[i] = { modId = "None" }
				affix = list[i]
			end
			local mod = self:GetAffix(affix.modId)
			if mod then
				if mod.type == "Prefix" then
					self.namePrefix = mod.affix .. " " .. self.namePrefix
				elseif mod.type == "Suffix" then
					self.nameSuffix = self.nameSuffix .. " " .. mod.affix
				end
				self.requirements.level = m_max(self.requirements.level or 0, m_floor(mod.level * 0.8))
				local rangeScalar = getCatalystScalar(self.catalyst, mod.modTags, self.catalystQuality)
				for j, line in ipairs(mod) do
					local exactLine = affix.displayLines and affix.displayLines[j]
					line = exactLine or itemLib.applyRange(line, affix.range or 0.5, rangeScalar)
					local order = mod.statOrder[j]
					if statOrder[order] then
						local start = 1
						statOrder[order].line = statOrder[order].line:gsub("%d+", function(num)
							local _, e, other = line:find("(%d+)", start)
							start = e + 1
							return tonumber(num) + tonumber(other)
						end)
						rebuildParsedLine(statOrder[order])
					else
						local modLine = { line = line, order = order, modTags = mod.modTags }
						if affix.fractured then
							modLine.fractured = true
						end
						rebuildParsedLine(modLine)
						for l = 1, #self.explicitModLines + 1 do
							if not self.explicitModLines[l] or (self.explicitModLines[l].order and self.explicitModLines[l].order > order) then
								t_insert(self.explicitModLines, l, modLine)
								break
							end
						end
						statOrder[order] = modLine
					end
				end
			end
		end
	end
	for _, mod in ipairs(savedOtherMods) do
		t_insert(self.explicitModLines, mod)
	end
	if self.baseName and self.title then
		self.name = self.title .. ", " .. self.baseName:gsub(" %(.+%)","")
	elseif self.baseName then
		self.name = (self.namePrefix or "") .. self.baseName .. (self.nameSuffix or "")
	end
end

-- Rebuild explicit modifiers using the item's affixes
function ItemClass:Craft()
	-- Save off explicit lines that aren't represented by the current affix slots
	-- so source-specific imported lines survive affix edits.
	local savedMods = {}
	for _, mod in ipairs(self.explicitModLines) do
		if mod.crafted or mod.custom or mod.specialSource then
			t_insert(savedMods, mod)
		end
	end

	self:RebuildExplicitModLinesFromAffixes(savedMods)
	self:BuildAndParseRaw()
end

function ItemClass:CheckModLineVariant(modLine)
	return not modLine.variantList 
		or modLine.variantList[self.variant]
		or (self.hasAltVariant and modLine.variantList[self.variantAlt])
		or (self.hasAltVariant2 and modLine.variantList[self.variantAlt2])
		or (self.hasAltVariant3 and modLine.variantList[self.variantAlt3])
		or (self.hasAltVariant4 and modLine.variantList[self.variantAlt4])
		or (self.hasAltVariant5 and modLine.variantList[self.variantAlt5])
end

-- Return the name of the slot this item is equipped in
function ItemClass:GetPrimarySlot()
	if self.base.weapon then
		return "Weapon 1"
	elseif self.type == "Quiver" or self.type == "Shield" then
		return "Weapon 2"
	elseif self.type == "Ring" then
		return "Ring 1"
	elseif self.type == "Flask" then
		return "Flask 1"
	elseif self.type == "Tincture" then
		return "Flask 1"
	elseif self.type == "Graft" then
		return "Graft 1"
	else
		return self.type
	end
end

-- Calculate local modifiers, and removes them from the modifier list
-- To be considered local, a modifier must be an exact flag match, and cannot have any tags (e.g. conditions, multipliers)
-- Only the InSlot tag is allowed (for Adds x to x X Damage in X Hand modifiers)
local function calcLocal(modList, name, type, flags)
	local result
	if type == "FLAG" then
		result = false
	elseif type == "MORE" then
		result = 1
	else
		result = 0
	end
	local i = 1
	while modList[i] do
		local mod = modList[i]
		if mod.name == name and mod.type == type and mod.flags == flags and mod.keywordFlags == 0 and (not mod[1] or mod[1].type == "InSlot") then
			if type == "FLAG" then
				result = result or mod.value
			-- convert MORE to times multiplier, e.g. 50% more = 1.5x, result = 1.5
			elseif type == "MORE" then
				result = result * ((100 + mod.value) / 100)
			else
				result = result + mod.value
			end
			t_remove(modList, i)
		else
			i = i + 1
		end
	end
	return result
end

-- Build list of modifiers in a given slot number (1 or 2) while applying local modifiers and adding quality
function ItemClass:BuildModListForSlotNum(baseList, slotNum)
	local slotName = self:GetPrimarySlot()
	if slotNum == 2 then
		slotName = slotName:gsub("1", "2")
	end
	local modList = new("ModList")
	for _, baseMod in ipairs(baseList) do
		local mod = copyTable(baseMod)
		local add = true
		for _, tag in ipairs(mod) do
			if tag.type == "SlotNumber" or tag.type == "InSlot" then
				if tag.num ~= slotNum then
					add = false
					break
				end
			end
			for k, v in pairs(tag) do
				if type(v) == "string" then
					tag[k] = v:gsub("{SlotName}", slotName)
							  :gsub("{Hand}", (slotNum == 1) and "MainHand" or "OffHand")
							  :gsub("{OtherSlotNum}", slotNum == 1 and "2" or "1")
				end
			end
		end
		if add then
			mod.sourceSlot = slotName
			modList:AddMod(mod)
		end
	end
	if #self.sockets > 0 then
		local multiName = {
			R = "Multiplier:RedSocketIn"..slotName,
			G = "Multiplier:GreenSocketIn"..slotName,
			B = "Multiplier:BlueSocketIn"..slotName,
			W = "Multiplier:WhiteSocketIn"..slotName,
		}
		local groupCounts = {}
		for _, socket in ipairs(self.sockets) do
			local group = socket.group
    		groupCounts[group] = (groupCounts[group] or 0) + 1
			if multiName[socket.color] then
				modList:NewMod(multiName[socket.color], "BASE", 1, "Item Sockets")
			end
		end
		local unlinkedSockets = 0
		for _, count in pairs(groupCounts) do
			if count == 1 then
				unlinkedSockets = unlinkedSockets + 1
			end
		end
		modList:NewMod("Multiplier:UnlinkedSocketIn"..slotName, "BASE", unlinkedSockets, "Unlinked Item Sockets")
	end
	local craftedQuality = calcLocal(modList,"Quality","BASE",0) or 0
	if craftedQuality ~= self.craftedQuality then
		if self.craftedQuality then
			self.quality = (self.quality or 0) - self.craftedQuality + craftedQuality
		end
		self.craftedQuality = craftedQuality
	end
	if self.quality then
		modList:NewMod("Multiplier:QualityOn"..slotName, "BASE", self.quality, "Quality")
	end
	if self.base.weapon then
		local weaponData = { }
		self.weaponData[slotNum] = weaponData
		weaponData.type = self.base.type
		weaponData.subType = self.base.subType
		weaponData.name = self.name
		weaponData.AttackSpeedInc = calcLocal(modList, "Speed", "INC", ModFlag.Attack) + m_floor(self.quality / 8 * calcLocal(modList, "AlternateQualityLocalAttackSpeedPer8Quality", "INC", 0))
		weaponData.AttackRate = round(self.base.weapon.AttackRateBase * (1 + weaponData.AttackSpeedInc / 100), 2)
		weaponData.rangeBonus = calcLocal(modList, "WeaponRange", "BASE", 0) + 10 * calcLocal(modList, "WeaponRangeMetre", "BASE", 0) + m_floor(self.quality / 10 * calcLocal(modList, "AlternateQualityLocalWeaponRangePer10Quality", "BASE", 0))
		weaponData.range = self.base.weapon.Range + weaponData.rangeBonus
		local LocalIncEle = calcLocal(modList, "LocalElementalDamage", "INC", 0)
		for _, dmgType in ipairs(dmgTypeList) do
			local min = (self.base.weapon[dmgType.."Min"] or 0) + calcLocal(modList, dmgType.."Min", "BASE", 0)
			local max = (self.base.weapon[dmgType.."Max"] or 0) + calcLocal(modList, dmgType.."Max", "BASE", 0)
			if dmgType == "Physical" then
				local physInc = calcLocal(modList, "PhysicalDamage", "INC", 0)
				local qualityScalar = self.quality
				if calcLocal(modList, "AlternateQualityWeapon", "BASE", 0) > 0 then
					qualityScalar = 0
				end
				min = round(min * (1 + physInc / 100) * (1 + qualityScalar / 100))
				max = round(max * (1 + physInc / 100) * (1 + qualityScalar / 100))
			elseif dmgType ~= "Physical" and dmgType ~= "Chaos" then
				local localInc = calcLocal(modList, "Local"..dmgType.."Damage", "INC", 0) + LocalIncEle
				min = round(min * (1 + localInc / 100))
				max = round(max * (1 + localInc / 100))
			end
			if min > 0 and max > 0 then
				weaponData[dmgType.."Min"] = min
				weaponData[dmgType.."Max"] = max
				local dps = (min + max) / 2 * weaponData.AttackRate
				weaponData[dmgType.."DPS"] = dps
				if dmgType ~= "Physical" and dmgType ~= "Chaos" then
					weaponData.ElementalDPS = (weaponData.ElementalDPS or 0) + dps
				end
			end
		end
		weaponData.CritChance = round((self.base.weapon.CritChanceBase + calcLocal(modList, "CritChance", "BASE", 0)) * (1 + (calcLocal(modList, "CritChance", "INC", 0) + m_floor(self.quality / 4 * calcLocal(modList, "AlternateQualityLocalCritChancePer4Quality", "INC", 0))) / 100), 2)
		for _, value in ipairs(modList:List(nil, "WeaponData")) do
			weaponData[value.key] = value.value
		end
		for _, mod in ipairs(modList) do
			-- Convert accuracy, L/MGoH and PAD Leech modifiers to local
			if (
				(mod.name == "Accuracy" and mod.flags == 0) or (mod.name == "ImpaleChance" and mod.flags ~= ModFlag.Spell) or
				((mod.name == "LifeOnHit" or mod.name == "ManaOnHit") and mod.flags == ModFlag.Attack) or
				((mod.name == "PhysicalDamageLifeLeech" or mod.name == "PhysicalDamageManaLeech") and mod.flags == ModFlag.Attack)
			   ) and (mod.keywordFlags == 0 or mod.keywordFlags == KeywordFlag.Attack) and not mod[1] then
				mod[1] = { type = "Condition", var = (slotNum == 1) and "MainHandAttack" or "OffHandAttack" }
			elseif (mod.name == "PoisonChance" or mod.name == "BleedChance") and mod.flags ~= ModFlag.Spell and (not mod[1] or (mod[1].type == "Condition" and mod[1].var == "CriticalStrike" and not mod[2])) then
				t_insert(mod, { type = "Condition", var = (slotNum == 1) and "MainHandAttack" or "OffHandAttack" })
			end
		end
		weaponData.TotalDPS = 0
		for _, dmgType in ipairs(dmgTypeList) do
			weaponData.TotalDPS = weaponData.TotalDPS + (weaponData[dmgType.."DPS"] or 0)
		end
	elseif self.base.armour then
		local armourData = self.armourData
		local armourBase = calcLocal(modList, "Armour", "BASE", 0) + (self.base.armour.ArmourBaseMin or 0)
		local armourVariance = (self.base.armour.ArmourBaseMax or 0) - (self.base.armour.ArmourBaseMin or 0)
		local armourEvasionBase = calcLocal(modList, "ArmourAndEvasion", "BASE", 0)
		local evasionBase = calcLocal(modList, "Evasion", "BASE", 0) + (self.base.armour.EvasionBaseMin or 0)
		local evasionVariance = (self.base.armour.EvasionBaseMax or 0) - (self.base.armour.EvasionBaseMin or 0)
		local evasionEnergyShieldBase = calcLocal(modList, "EvasionAndEnergyShield", "BASE", 0)
		local energyShieldBase = calcLocal(modList, "EnergyShield", "BASE", 0) + (self.base.armour.EnergyShieldBaseMin or 0)
		local energyShieldVariance = (self.base.armour.EnergyShieldBaseMax or 0) - (self.base.armour.EnergyShieldBaseMin or 0)
		local armourEnergyShieldBase = calcLocal(modList, "ArmourAndEnergyShield", "BASE", 0)
		local wardBase = calcLocal(modList, "Ward", "BASE", 0) + (self.base.armour.WardBaseMin or 0)
		local wardVariance = (self.base.armour.WardBaseMax or 0) - (self.base.armour.WardBaseMin or 0)
		local armourInc = calcLocal(modList, "Armour", "INC", 0)
		local armourEvasionInc = calcLocal(modList, "ArmourAndEvasion", "INC", 0)
		local evasionInc = calcLocal(modList, "Evasion", "INC", 0)
		local evasionEnergyShieldInc = calcLocal(modList, "EvasionAndEnergyShield", "INC", 0)
		local energyShieldInc = calcLocal(modList, "EnergyShield", "INC", 0)
		local wardInc = calcLocal(modList, "Ward", "INC", 0)
		local armourEnergyShieldInc = calcLocal(modList, "ArmourAndEnergyShield", "INC", 0)
		local defencesInc = calcLocal(modList, "Defences", "INC", 0)
		local qualityScalar = self.quality
		if calcLocal(modList, "AlternateQualityArmour", "BASE", 0) > 0 then
			qualityScalar = 0
		end
		-- base percentiles need to differ for each armour type, as they're weighted differently
		if armourData.Armour and armourData.Armour > 0 and not armourData.ArmourBasePercentile then
			armourData.ArmourBasePercentile = ((armourData.Armour / ((1 + (armourInc + armourEvasionInc + armourEnergyShieldInc + defencesInc) / 100) * (1 + (qualityScalar / 100))) - armourBase)) / armourVariance
			armourData.ArmourBasePercentile = round(m_max(m_min(armourData.ArmourBasePercentile, 1), 0), 4)
		end
		if armourData.Evasion and armourData.Evasion > 0 and not armourData.EvasionBasePercentile then
			armourData.EvasionBasePercentile = ((armourData.Evasion / ((1 + (evasionInc + armourEvasionInc + evasionEnergyShieldInc + defencesInc) / 100) * (1 + (qualityScalar / 100))) - evasionBase)) / evasionVariance
			armourData.EvasionBasePercentile = round(m_max(m_min(armourData.EvasionBasePercentile, 1), 0), 4)
		end
		if armourData.EnergyShield and armourData.EnergyShield > 0 and not armourData.EnergyShieldBasePercentile then
			armourData.EnergyShieldBasePercentile = ((armourData.EnergyShield / ((1 + (energyShieldInc + armourEnergyShieldInc + evasionEnergyShieldInc + defencesInc) / 100) * (1 + (qualityScalar / 100))) - energyShieldBase)) / energyShieldVariance
			armourData.EnergyShieldBasePercentile = round(m_max(m_min(armourData.EnergyShieldBasePercentile, 1), 0), 4)
		end
		if armourData.Ward and armourData.Ward > 0 and not armourData.WardBasePercentile then
			armourData.WardBasePercentile = ((armourData.Ward / ((1 + (wardInc + defencesInc) / 100) * (1 + (qualityScalar / 100))) - wardBase)) / wardVariance
			armourData.WardBasePercentile = round(m_max(m_min(armourData.WardBasePercentile, 1), 0),4)
		end

		armourData.Armour = round((armourBase + armourEvasionBase + armourEnergyShieldBase + armourVariance * (armourData.ArmourBasePercentile or 1)) * (1 + (armourInc + armourEvasionInc + armourEnergyShieldInc + defencesInc) / 100) * (1 + (qualityScalar / 100)))
		armourData.Evasion = round((evasionBase + armourEvasionBase + evasionEnergyShieldBase + evasionVariance * (armourData.EvasionBasePercentile or 1)) * (1 + (evasionInc + armourEvasionInc + evasionEnergyShieldInc + defencesInc) / 100) * (1 + (qualityScalar / 100)))
		armourData.EnergyShield = round((energyShieldBase + evasionEnergyShieldBase + armourEnergyShieldBase + energyShieldVariance * (armourData.EnergyShieldBasePercentile or 1)) * (1 + (energyShieldInc + armourEnergyShieldInc + evasionEnergyShieldInc + defencesInc) / 100) * (1 + (qualityScalar / 100)))
		armourData.Ward = round((wardBase + wardVariance * (armourData.WardBasePercentile or 1)) * (1 + (wardInc + defencesInc) / 100) * (1 + (qualityScalar / 100)))

		if not armourData.ArmourBasePercentile and armourData.Armour > 0 then
			armourData.ArmourBasePercentile = 1
		end
		if not armourData.EvasionBasePercentile and armourData.Evasion > 0 then
			armourData.EvasionBasePercentile = 1
		end
		if not armourData.EnergyShieldBasePercentile and armourData.EnergyShield > 0 then
			armourData.EnergyShieldBasePercentile = 1
		end
		if not armourData.WardBasePercentile and armourData.Ward > 0 then
			armourData.WardBasePercentile = 1
		end

		if self.base.armour.BlockChance then
			armourData.BlockChance = m_floor((self.base.armour.BlockChance * (1 + calcLocal(modList, "BlockChance", "INC", 0) / 100) + calcLocal(modList, "BlockChance", "BASE", 0)))
		end
		if self.base.armour.MovementPenalty then
			modList:NewMod("MovementSpeed", "INC", -self.base.armour.MovementPenalty, self.modSource, { type = "Condition", var = "IgnoreMovementPenalties", neg = true })
		end
		for _, value in ipairs(modList:List(nil, "ArmourData")) do
			armourData[value.key] = value.value
		end
	elseif self.base.flask then
		local flaskData = self.flaskData
		local durationInc = calcLocal(modList, "Duration", "INC", 0)
		local durationMore = calcLocal(modList, "Duration", "MORE", 0)
		if self.base.flask.life or self.base.flask.mana then
			-- Recovery flask
			flaskData.instantPerc = calcLocal(modList, "FlaskInstantRecovery", "BASE", 0)
			flaskData.instantLowLifePerc = calcLocal(modList, "FlaskLowLifeInstantRecovery", "BASE", 0)
			local recoveryMod = 1 + calcLocal(modList, "FlaskRecovery", "INC", 0) / 100
			local rateMod = 1 + calcLocal(modList, "FlaskRecoveryRate", "INC", 0) / 100
			flaskData.duration = round(self.base.flask.duration * (1 + durationInc / 100) / rateMod * durationMore, 1)
			if self.base.flask.life then
				flaskData.lifeBase = self.base.flask.life * (1 + self.quality / 100) * recoveryMod
				flaskData.lifeInstant = flaskData.lifeBase * flaskData.instantPerc / 100
				flaskData.lifeGradual = flaskData.lifeBase * (1 - flaskData.instantPerc / 100)
				flaskData.lifeTotal = flaskData.lifeInstant + flaskData.lifeGradual
				flaskData.lifeAdditional = calcLocal(modList, "FlaskAdditionalLifeRecovery", "BASE", 0)
				flaskData.lifeEffectNotRemoved = calcLocal(baseList, "LifeFlaskEffectNotRemoved", "FLAG", 0)
			end
			if self.base.flask.mana then
				flaskData.manaBase = self.base.flask.mana * (1 + self.quality / 100) * recoveryMod
				flaskData.manaInstant = flaskData.manaBase * flaskData.instantPerc / 100
				flaskData.manaGradual = flaskData.manaBase * (1 - flaskData.instantPerc / 100)
				flaskData.manaTotal = flaskData.manaInstant + flaskData.manaGradual
				flaskData.manaEffectNotRemoved = calcLocal(baseList, "ManaFlaskEffectNotRemoved", "FLAG", 0)
			end
		else
			-- Utility flask
			flaskData.duration = round(self.base.flask.duration * (1 + durationInc / 100) * (1 + self.quality / 100) * durationMore, 1)
		end
		flaskData.chargesMax = self.base.flask.chargesMax + calcLocal(modList, "FlaskCharges", "BASE", 0)
		flaskData.chargesUsed = m_floor(self.base.flask.chargesUsed * (1 + calcLocal(modList, "FlaskChargesUsed", "INC", 0) / 100))
		flaskData.gainMod = 1 + calcLocal(modList, "FlaskChargeRecovery", "INC", 0) / 100
		flaskData.effectInc = calcLocal(modList, "FlaskEffect", "INC", 0) + calcLocal(modList, "LocalEffect", "INC", 0)
		for _, value in ipairs(modList:List(nil, "FlaskData")) do
			flaskData[value.key] = value.value
		end
		if self.flaskDisplayData then
			if self.flaskDisplayData.duration and flaskData.duration and not self.flaskDisplayData.durationScale and flaskData.duration ~= 0 then
				self.flaskDisplayData.durationScale = self.flaskDisplayData.duration / flaskData.duration
			end
			if self.flaskDisplayData.chargesMax and flaskData.chargesMax and self.flaskDisplayData.chargesMaxDelta == nil then
				self.flaskDisplayData.chargesMaxDelta = self.flaskDisplayData.chargesMax - flaskData.chargesMax
			end
			if self.flaskDisplayData.chargesUsed and flaskData.chargesUsed and self.flaskDisplayData.chargesUsedDelta == nil then
				self.flaskDisplayData.chargesUsedDelta = self.flaskDisplayData.chargesUsed - flaskData.chargesUsed
			end
			if self.flaskDisplayData.durationScale and flaskData.duration then
				flaskData.duration = round(flaskData.duration * self.flaskDisplayData.durationScale, 1)
			end
			if self.flaskDisplayData.chargesMaxDelta then
				flaskData.chargesMax = flaskData.chargesMax + self.flaskDisplayData.chargesMaxDelta
			end
			if self.flaskDisplayData.chargesUsedDelta then
				flaskData.chargesUsed = flaskData.chargesUsed + self.flaskDisplayData.chargesUsedDelta
			end
			if self.flaskDisplayData.currentCharges then
				flaskData.currentCharges = m_min(self.flaskDisplayData.currentCharges, flaskData.chargesMax or self.flaskDisplayData.currentCharges)
			end
		end
	elseif self.base.tincture then
		local tinctureData = self.tinctureData
		tinctureData.manaBurn = (self.base.tincture.manaBurn + 0.01) / (1 + calcLocal(modList, "TinctureManaBurnRate", "INC", 0) / 100) / (1 + calcLocal(modList, "TinctureManaBurnRate", "MORE", 0) / 100)
		tinctureData.cooldownInc = calcLocal(modList, "TinctureCooldownRecovery", "INC", 0) + calcLocal(modList, "CooldownRecovery", "INC", 0)
		tinctureData.cooldown = self.base.tincture.cooldown / (1 + tinctureData.cooldownInc / 100)
		tinctureData.effectInc = calcLocal(modList, "TinctureEffect", "INC", 0) + calcLocal(modList, "LocalEffect", "INC", 0)
		for _, value in ipairs(modList:List(nil, "TinctureData")) do
			tinctureData[value.key] = value.value
		end
	elseif self.type == "Jewel" then
		if self.name:find("Grand Spectrum") then
			local spectrumMod = modLib.createMod("Multiplier:GrandSpectrum", "BASE", 1, self.name)
			modList:AddMod(spectrumMod)
			modList:NewMod("MinionModifier", "LIST", { mod = spectrumMod }, self.name)
		end

		local jewelData = self.jewelData
		for _, func in ipairs(modList:List(nil, "JewelFunc")) do
			jewelData.funcList = jewelData.funcList or { }
			t_insert(jewelData.funcList, func)
		end
		for _, value in ipairs(modList:List(nil, "JewelData")) do
			jewelData[value.key] = value.value
		end
		if modList:List(nil, "ImpossibleEscapeKeystones") then
			jewelData.impossibleEscapeKeystones = { }
			for _, value in ipairs(modList:List(nil, "ImpossibleEscapeKeystones")) do
				jewelData.impossibleEscapeKeystones[value.key] = value.value
			end
		end
		if self.clusterJewel then
			jewelData.clusterJewelNotables = { }
			for _, name in ipairs(modList:List(nil, "ClusterJewelNotable")) do
				t_insert(jewelData.clusterJewelNotables, name)
			end
			jewelData.clusterJewelAddedMods = { }
			for _, line in ipairs(modList:List(nil, "AddToClusterJewelNode")) do
				t_insert(jewelData.clusterJewelAddedMods, line)
			end

			-- Small and Medium Curse Cluster Jewel passive mods are parsed the same so the medium cluster data overwrites small and the skills differ
			-- This changes small curse clusters to have the correct clusterJewelSkill so it passes validation below and works as expected in the tree
			if self.clusterJewel.size == "Small" and jewelData.clusterJewelSkill == "affliction_curse_effect" then
				jewelData.clusterJewelSkill = "affliction_curse_effect_small"
			elseif self.clusterJewel.size == "Medium" and jewelData.clusterJewelSkill == "affliction_curse_effect_small" then
				jewelData.clusterJewelSkill = "affliction_curse_effect"
			end

			-- Validation
			if jewelData.clusterJewelNodeCount then
				jewelData.clusterJewelNodeCount = m_min(m_max(jewelData.clusterJewelNodeCount, self.clusterJewel.minNodes), self.clusterJewel.maxNodes)
			end
			if jewelData.clusterJewelSkill and not self.clusterJewel.skills[jewelData.clusterJewelSkill] then
				jewelData.clusterJewelSkill = nil
			end
			jewelData.clusterJewelValid = jewelData.clusterJewelKeystone 
				or ((jewelData.clusterJewelSkill or jewelData.clusterJewelSmallsAreNothingness) and jewelData.clusterJewelNodeCount) 
				or (jewelData.clusterJewelSocketCountOverride and jewelData.clusterJewelNothingnessCount)
		end
	end	
	return { unpack(modList) }
end

-- Build lists of modifiers for each slot the item can occupy
function ItemClass:BuildModList()
	if not self.base then
		return
	end
	local baseList = new("ModList")
	if self.base.weapon then
		self.weaponData = { }
	elseif self.base.armour then
		self.armourData = self.armourData or { }
	elseif self.base.flask then
		self.flaskData = { }
		self.buffModList = { }
	elseif self.base.tincture then
		self.tinctureData = { }
		self.buffModList = { }
	elseif self.type == "Jewel" then
		self.jewelData = { }
	end
	self.baseModList = baseList
	self.rangeLineList = { }
	self.modSource = "Item:"..(self.id or -1)..":"..self.name
	for _, modLine in ipairs(self.buffModLines) do
		if not modLine.extra and self:CheckModLineVariant(modLine) then
			for _, mod in ipairs(modLine.modList) do
				mod.source = self.modSource
				t_insert(self.buffModList, mod)
			end
		end
	end
	local modifierMagnitudeScalars = getModifierMagnitudeScalars({ self.explicitModLines, self.crucibleModLines }, function(modLine)
		return self:CheckModLineVariant(modLine)
	end)
	local function processModLine(modLine, applyImplicitMagnitude)
		if self:CheckModLineVariant(modLine) then
			-- special section for variant over-ride of pre-modifier item parameters
			if modLine.line:find("Requires Class") then
				self.classRestriction = modLine.line:gsub("{variant:([%d,]+)}", ""):match("Requires Class (.+)")
			end
			-- handle understood modifier variable properties
			if not modLine.extra then
				local catalystScalar = getCatalystScalar(self.catalyst, modLine.modTags, self.catalystQuality)
				local magnitudeScalar = modLine.unscalable and 1 or ((applyImplicitMagnitude and modifierMagnitudeScalars.implicit) or 1)
				local unveiledScalar = (modLine.unscalable or not modLine.veiled) and 1 or modifierMagnitudeScalars.unveiled
				local valueScalar = catalystScalar * magnitudeScalar * unveiledScalar
				local hasRangedText = modLine.line:find("%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)") ~= nil
				if hasRangedText or valueScalar ~= 1 then
					local scaledLine = modLine.line:gsub("\n"," ")
					if modLine.range and hasRangedText then
						scaledLine = itemLib.applyRange(scaledLine, modLine.range, valueScalar)
					else
						scaledLine = itemLib.applyValueScalar(scaledLine, valueScalar)
					end
					-- Check if we can parse it before adding the mods
					local list, extra = modLib.parseMod(scaledLine)
					if list and not extra then
						modLine.modList = list
						modLine.extra = nil
						modLine.valueScalar = valueScalar
						if modLine.range and hasRangedText then
							t_insert(self.rangeLineList, modLine)
						end
					end
				end
				for _, mod in ipairs(modLine.modList or { }) do
					mod = modLib.setSource(mod, self.modSource)
					baseList:AddMod(mod)
				end
				if modLine.modTags and #modLine.modTags > 0 then
					self.hasModTags = true
				end
			end
		end
	end
	for _, modLine in ipairs(self.enchantModLines) do
		processModLine(modLine, false)
	end
	for _, modLine in ipairs(self.scourgeModLines) do
		processModLine(modLine, false)
	end
	for _, modLine in ipairs(self.classRequirementModLines) do
		processModLine(modLine, false)
	end
	for _, modLine in ipairs(self.implicitModLines) do
		processModLine(modLine, true)
	end
	for _, modLine in ipairs(self.explicitModLines) do
		processModLine(modLine, false)
	end
	for _, modLine in ipairs(self.crucibleModLines) do
		processModLine(modLine, false)
	end
	if self.name == "Tabula Rasa, Simple Robe" or self.name == "Skin of the Loyal, Simple Robe" or self.name == "Skin of the Lords, Simple Robe" or self.name == "The Apostate, Cabalist Regalia" then
		-- Hack to remove the energy shield and base int requirement
		baseList:NewMod("ArmourData", "LIST", { key = "EnergyShield", value = 0 })
		self.requirements.int = 0
	end
	if calcLocal(baseList, "NoAttributeRequirements", "FLAG", 0) then
		self.requirements.strMod = 0
		self.requirements.dexMod = 0
		self.requirements.intMod = 0
	else
		self.requirements.strMod = m_floor((self.requirements.str + calcLocal(baseList, "StrRequirement", "BASE", 0)) * (1 + calcLocal(baseList, "StrRequirement", "INC", 0) / 100))
		self.requirements.dexMod = m_floor((self.requirements.dex + calcLocal(baseList, "DexRequirement", "BASE", 0)) * (1 + calcLocal(baseList, "DexRequirement", "INC", 0) / 100))
		self.requirements.intMod = m_floor((self.requirements.int + calcLocal(baseList, "IntRequirement", "BASE", 0)) * (1 + calcLocal(baseList, "IntRequirement", "INC", 0) / 100))
	end
	self.grantedSkills = { }
	for _, skill in ipairs(baseList:List(nil, "ExtraSkill")) do
		if skill.name ~= "Unknown" then
			t_insert(self.grantedSkills, {
				skillId = skill.skillId,
				level = skill.level,
				noSupports = skill.noSupports,
				source = self.modSource,
				triggered = skill.triggered,
				triggerChance = skill.triggerChance,
			})
		end
	end
	local socketCount = calcLocal(baseList, "SocketCount", "BASE", 0)
	self.abyssalSocketCount = calcLocal(baseList, "AbyssalSocketCount", "BASE", 0)
	self.selectableSocketCount = m_max(self.base.socketLimit or 0, #self.sockets) - self.abyssalSocketCount
	if calcLocal(baseList, "NoSockets", "FLAG", 0) then
		-- Remove all sockets
		wipeTable(self.sockets)
		self.selectableSocketCount = 0
	elseif socketCount > 0 then
		-- Force the socket count to be equal to the stated number
		self.selectableSocketCount = socketCount
		local group = 0
		for i = 1, m_max(socketCount, #self.sockets) do 
			if i > socketCount then
				self.sockets[i] = nil
			elseif not self.sockets[i] then
				self.sockets[i] = {
					color = self.defaultSocketColor,
					group = group
				}
			else
				group = self.sockets[i].group
			end
		end
	elseif self.abyssalSocketCount > 0 then
		-- Ensure that there are the correct number of abyssal sockets present
		local newSockets = { }
		local group = 0
		if self.sockets then
			for i, socket in ipairs(self.sockets) do
				if socket.color ~= "A" then
					if #newSockets >= self.selectableSocketCount then
						break
					end
					t_insert(newSockets, socket)
					group = socket.group
				end
			end
		end
		for i = 1, self.abyssalSocketCount do
			group = group + 1
			t_insert(newSockets, {
				color = "A",
				group = group
			})
		end
		self.sockets = newSockets
	end
	self.socketedJewelEffectModifier = 1 + calcLocal(baseList, "SocketedJewelEffect", "INC", 0) / 100
	if self.base.weapon or self.type == "Ring" then
		self.slotModList = { }
		for i = 1, 2 do
			self.slotModList[i] = self:BuildModListForSlotNum(baseList, i)
		end
		-- Ring 3
		if self.type == "Ring" then
			self.slotModList[3] = self:BuildModListForSlotNum(baseList, 3)
		end
	else
		self.modList = self:BuildModListForSlotNum(baseList)
	end
end
