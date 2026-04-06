describe("TestItemParse", function()
	local function raw(s, base)
		base = base or "Plate Vest"
		return "Rarity: Rare\nName\n"..base.."\n"..s
	end

	it("Rarity", function()
		local item = new("Item", "Rarity: Normal\nCoral Ring")
		assert.are.equals("NORMAL", item.rarity)
		item = new("Item", "Rarity: Magic\nCoral Ring")
		assert.are.equals("MAGIC", item.rarity)
		item = new("Item", "Rarity: Rare\nName\nCoral Ring")
		assert.are.equals("RARE", item.rarity)
		item = new("Item", "Rarity: Unique\nName\nCoral Ring")
		assert.are.equals("UNIQUE", item.rarity)
		item = new("Item", "Rarity: Unique\nName\nCoral Ring\nFoil Unique (Verdant)")
		assert.are.equals("RELIC", item.rarity)
	end)

	it("Superior/Synthesised", function()
		local item = new("Item", raw("", "Superior Plate Vest"))
		assert.are.equals("Plate Vest", item.baseName)
		item = new("Item", raw("", "Synthesised Plate Vest"))
		assert.are.equals("Plate Vest", item.baseName)
		item = new("Item", raw("", "Superior Synthesised Plate Vest"))
		assert.are.equals("Plate Vest", item.baseName)
	end)

	it("Two-Toned Boots", function()
		local item = new("Item", raw("", "Two-Toned Boots"))
		assert.are.equals("Two-Toned Boots (Armour/Energy Shield)", item.baseName)
		item = new("Item", raw("Armour: 10\nEnergy Shield: 10", "Two-Toned Boots"))
		assert.are.equals("Two-Toned Boots (Armour/Energy Shield)", item.baseName)
		item = new("Item", raw("Armour: 10\nEvasion Rating: 10", "Two-Toned Boots"))
		assert.are.equals("Two-Toned Boots (Armour/Evasion)", item.baseName)
		item = new("Item", raw("Evasion Rating: 10\nEnergy Shield: 10", "Two-Toned Boots"))
		assert.are.equals("Two-Toned Boots (Evasion/Energy Shield)", item.baseName)
	end)

	it("Magic Two-Toned Boots", function()
		local item = new("Item", [[
			Rarity: Magic
			Stalwart Two-Toned Boots of Plunder
			Armour: 100
			Energy Shield: 100
			]])
		assert.are.equal("Two-Toned Boots (Armour/Energy Shield)", item.baseName)
		assert.are.equal("Stalwart ", item.namePrefix)
		assert.are.equal(" of Plunder", item.nameSuffix)
		item = new("Item", [[
			Rarity: Magic
			Sanguine Two-Toned Boots of the Phoenix
			Armour: 100
			Evasion Rating: 100
			]])
		assert.are.equal("Two-Toned Boots (Armour/Evasion)", item.baseName)
		assert.are.equal("Sanguine ", item.namePrefix)
		assert.are.equal(" of the Phoenix", item.nameSuffix)
		item = new("Item", [[
			Rarity: Magic
			Stout Two-Toned Boots of the Lightning
			Evasion Rating: 100
			Energy Shield: 100
			]])
		assert.are.equal("Two-Toned Boots (Evasion/Energy Shield)", item.baseName)
		assert.are.equal("Stout ", item.namePrefix)
		assert.are.equal(" of the Lightning", item.nameSuffix)
	end)

	it("Title", function()
		local item = new("Item", [[
			Rarity: Rare
			Phoenix Paw
			Iron Gauntlets
		]])
		assert.are.equal("Phoenix Paw", item.title)
		assert.are.equal("Iron Gauntlets", item.baseName)
		assert.are.equal("Phoenix Paw, Iron Gauntlets", item.name)
	end)

	it("ignores bare subtype lines like Warstaff in normal and advanced imports", function()
		local normalItem = new("Item", [[
			Item Class: Warstaves
			Rarity: Unique
			Disintegrator
			Maelström Staff
			--------
			Warstaff
			Quality: +6% (augmented)
			Physical Damage: 310-459 (augmented)
			Critical Strike Chance: 8.10%
			Attacks per Second: 1.25
			Weapon Range: 1.3 metres
			--------
			Requirements:
			Level: 64
			Str: 113
			Int: 113
			--------
			Sockets: G R R R
			--------
			Item Level: 86
			--------
			+25% Chance to Block Attack Damage while wielding a Staff (implicit)
			--------
			Adds 221 to 286 Physical Damage
			+1 to Maximum Siphoning Charges per Elder or Shaper Item Equipped
			25% chance to gain a Siphoning Charge when you use a Skill
			Adds 14 to 15 Physical Damage to Attacks and Spells per Siphoning Charge
			Gain 4% of Non-Chaos Damage as extra Chaos Damage per Siphoning Charge
			1% additional Physical Damage Reduction from Hits per Siphoning Charge
			0.2% of Damage Leeched as Life per Siphoning Charge
			Take 150 Physical Damage per Second per Siphoning Charge if you've used a Skill Recently
			Battlemage
			--------
			Blurred is the boundary
			between creator and destroyer.
			--------
			Shaper Item
			Elder Item
		]])
		local advancedItem = new("Item", [[
			Item Class: Warstaves
			Rarity: Unique
			Disintegrator
			Maelström Staff
			--------
			Warstaff
			Quality: +6% (augmented)
			Physical Damage: 310-459 (augmented)
			Critical Strike Chance: 8.10%
			Attacks per Second: 1.25
			Weapon Range: 1.3 metres
			--------
			Requirements:
			Level: 64
			Str: 113
			Int: 113
			--------
			Sockets: G R R R
			--------
			Item Level: 86
			--------
			{ Implicit Modifier }
			+25% Chance to Block Attack Damage while wielding a Staff
			(Warstaves are considered Staves)
			--------
			{ Unique Modifier }
			25% chance to gain a Siphoning Charge when you use a Skill
			{ Unique Modifier }
			+1 to Maximum Siphoning Charges per Elder or Shaper Item Equipped
			{ Unique Modifier — Damage, Physical, Attack, Caster }
			Adds 14(12-14) to 15(15-16) Physical Damage to Attacks and Spells per Siphoning Charge
			{ Unique Modifier — Life }
			0.2% of Damage Leeched as Life per Siphoning Charge
			{ Unique Modifier — Damage, Chaos }
			Gain 4% of Non-Chaos Damage as extra Chaos Damage per Siphoning Charge
			{ Unique Modifier — Physical }
			1% additional Physical Damage Reduction from Hits per Siphoning Charge
			{ Unique Modifier — Damage, Physical }
			Take 150 Physical Damage per Second per Siphoning Charge if you've used a Skill Recently
			(Recently refers to the past 4 seconds)
			{ Unique Modifier — Damage, Physical, Attack }
			Adds 221(220-240) to 286(270-300) Physical Damage
			{ Unique Modifier }
			Battlemage — Unscalable Value
			(Gain Added Spell Damage equal to the Damage of your Main Hand Weapon)
			--------
			Blurred is the boundary
			between creator and destroyer.
			--------
			Shaper Item
			Elder Item
		]])
		for _, item in ipairs({ normalItem, advancedItem }) do
			assert.are.equals("Maelstrom Staff", item.baseName)
			assert.are.equals("Warstaff", item.base.subType)
			assert.are.equals("Staff", item.base.type)
			assert.is_nil(item.raw:match("Warstaff %(Not supported in PoB yet%)"))
			for _, modLine in ipairs(item.explicitModLines) do
				assert.are_not.equals("Warstaff", modLine.line)
			end
			for _, modLine in ipairs(item.implicitModLines) do
				assert.are_not.equals("Warstaff", modLine.line)
			end
		end
	end)

	it("Unique ID", function()
		local item = new("Item", raw("Unique ID: 40f9711d5bd7ad2bcbddaf71c705607aef0eecd3dcadaafec6c0192f79b82863"))
		assert.are.equals("40f9711d5bd7ad2bcbddaf71c705607aef0eecd3dcadaafec6c0192f79b82863", item.uniqueID)
	end)

	it("Item Level", function()
		local item = new("Item", raw("Item Level: 10"))
		assert.are.equals(10, item.itemLevel)
	end)

	it("ignores memory strands metadata", function()
		local item = new("Item", [[
			Item Class: Amulets
			Rarity: Rare
			Rage Idol
			Onyx Amulet
			--------
			Memory Strands: 17
			--------
			Requirements:
			Level: 60
			--------
			Item Level: 83
			--------
			+13 to all Attributes (implicit)
			--------
			+48 to Intelligence
			Adds 14 to 23 Physical Damage to Attacks
			Adds 17 to 31 Fire Damage to Attacks
			+108 to maximum Life
			+39% to Fire Resistance
			+13 to all Attributes (crafted)
		]])
		assert.are.equals(83, item.itemLevel)
		assert.is_nil(item.raw:match("Memory Strands"))
		for _, modLine in ipairs(item.explicitModLines) do
			assert.are_not.equals("Memory Strands: 17", modLine.line)
		end
	end)

	it("Quality", function()
		local item = new("Item", raw("Quality: 10"))
		assert.are.equals(10, item.quality)
		item = new("Item", raw("Quality: +12% (augmented)"))
		assert.are.equals(12, item.quality)
	end)

	it("Sockets", function()
		local item = new("Item", raw("Sockets: R-G R-B-W A"))
		assert.are.same({
			{ color = "R", group = 0 },
			{ color = "G", group = 0 },
			{ color = "R", group = 1 },
			{ color = "B", group = 1 },
			{ color = "W", group = 1 },
			{ color = "A", group = 2 },
		}, item.sockets)
	end)

	it("Jewel", function()
		local item = new("Item", raw("Radius: Large\nLimited to: 2", "Cobalt Jewel"))
		assert.are.equals("Large", item.jewelRadiusLabel)
		assert.are.equals(2, item.limit)
	end)

	it("Variant name", function()
		local item = new("Item", raw("Variant: Pre 3.19.0\nVariant: Current"))
		assert.are.same({ "Pre 3.19.0", "Current" }, item.variantList)
	end)

	it("Talisman Tier", function()
		local item = new("Item", raw("Talisman Tier: 3", "Rotfeather Talisman"))
		assert.are.equals(3, item.talismanTier)
	end)

	it("Defence", function()
		local item = new("Item", raw("Armour: 25"))
		assert.are.equals(25, item.armourData.Armour)
		item = new("Item", raw("Armour: 25 (augmented)"))
		assert.are.equals(25, item.armourData.Armour)
		item = new("Item", raw("Evasion Rating: 35", "Shabby Jerkin"))
		assert.are.equals(35, item.armourData.Evasion)
		item = new("Item", raw("Energy Shield: 15", "Simple Robe"))
		assert.are.equals(15, item.armourData.EnergyShield)
		item = new("Item", raw("Ward: 180", "Runic Crown"))
		assert.are.equals(180, item.armourData.Ward)
	end)

	it("Defence BasePercentile", function()
		local item = new("Item", raw("ArmourBasePercentile: 0.5"))
		assert.are.equals(0.5, item.armourData.ArmourBasePercentile)
		item = new("Item", raw("EvasionBasePercentile: 0.6", "Shabby Jerkin"))
		assert.are.equals(0.6, item.armourData.EvasionBasePercentile)
		item = new("Item", raw("EnergyShieldBasePercentile: 0.7", "Simple Robe"))
		assert.are.equals(0.7, item.armourData.EnergyShieldBasePercentile)
		item = new("Item", raw("WardBasePercentile: 0.8", "Runic Crown"))
		assert.are.equals(0.8, item.armourData.WardBasePercentile)
	end)

	it("Requires Level", function()
		local item = new("Item", raw("Requires Level 10"))
		assert.are.equals(10, item.requirements.level)
		item = new("Item", raw("Level: 10"))
		assert.are.equals(10, item.requirements.level)
		item = new("Item", raw("LevelReq: 10"))
		assert.are.equals(10, item.requirements.level)
	end)

	it("Alt Variant", function()
		local item = new("Item", raw([[
			Has Alt Variant: true
			Has Alt Variant Two: true
			Has Alt Variant Three: true
			Has Alt Variant Four: true
			Has Alt Variant Five: true
			Selected Variant: 10
			Selected Alt Variant: 11
			Selected Alt Variant Two: 12
			Selected Alt Variant Three: 13
			Selected Alt Variant Four: 14
			Selected Alt Variant Five: 15
			]]))
		assert.truthy(item.hasAltVariant)
		assert.truthy(item.hasAltVariant2)
		assert.truthy(item.hasAltVariant3)
		assert.truthy(item.hasAltVariant4)
		assert.truthy(item.hasAltVariant5)
		assert.are.equals(10, item.variant)
		assert.are.equals(11, item.variantAlt)
		assert.are.equals(12, item.variantAlt2)
		assert.are.equals(13, item.variantAlt3)
		assert.are.equals(14, item.variantAlt4)
		assert.are.equals(15, item.variantAlt5)
	end)

	it("Prefix/Suffix", function()
		local item = new("Item", raw([[
			Crafted: true
			Prefix: {range:0.1}IncreasedLife1
			Suffix: {fractured}{range:0.2}ColdResist1
			]]))
		assert.are.equals("IncreasedLife1", item.prefixes[1].modId)
		assert.are.equals(0.1, item.prefixes[1].range)
		assert.are.equals("ColdResist1", item.suffixes[1].modId)
		assert.are.equals(0.2, item.suffixes[1].range)
		assert.truthy(item.suffixes[1].fractured)
		item:BuildAndParseRaw()
		assert.truthy(item.suffixes[1].fractured)
	end)

	it("Implicits", function()
		local item = new("Item", raw([[
			Implicits: 2
			+8 to Strength
			+10 to Intelligence
			+12 to Dexterity
			]]))
		assert.are.equals(2, #item.implicitModLines)
		assert.are.equals("+8 to Strength", item.implicitModLines[1].line)
		assert.are.equals("+10 to Intelligence", item.implicitModLines[2].line)
		assert.are.equals(1, #item.explicitModLines)
		assert.are.equals("+12 to Dexterity", item.explicitModLines[1].line)
	end)

	it("League", function()
		local item = new("Item", raw("League: Heist"))
		assert.are.equals("Heist", item.league)
	end)

	it("Source", function()
		local item = new("Item", raw("Source: No longer obtainable"))
		assert.are.equals("No longer obtainable", item.source)
	end)

	it("Note", function()
		local item = new("Item", raw("Note: ~price 1 chaos"))
		assert.are.equals("~price 1 chaos", item.note)
	end)

	it("Attribute Requirements", function()
		local item = new("Item", raw("Dex: 100"))
		assert.are.equals(100, item.requirements.dex)
		item = new("Item", raw("Int: 101"))
		assert.are.equals(101, item.requirements.int)
		item = new("Item", raw("Str: 102"))
		assert.are.equals(102, item.requirements.str)
	end)

	it("Requires Class", function()
		local item = new("Item", raw("Requires Class Witch"))
		assert.are.equals("Witch", item.classRestriction)
		item = new("Item", raw("Class:: Witch"))
		assert.are.equals("Witch", item.classRestriction)
	end)

	it("Requires Class variant", function()
		local item = new("Item", raw([[
			Selected Variant: 2
			+8 to Strength
			{variant:1}Requires Class Witch
			{variant:2}Requires Class Templar
			]]))
		assert.are.equals(2, item.variant)
		assert.are.equals("Templar", item.classRestriction)
	end)

	it("Influence", function()
		local item = new("Item", raw("Shaper Item"))
		assert.truthy(item.shaper)
		item = new("Item", raw("Elder Item"))
		assert.truthy(item.elder)
		item = new("Item", raw("Warlord Item"))
		assert.truthy(item.adjudicator)
		item = new("Item", raw("Hunter Item"))
		assert.truthy(item.basilisk)
		item = new("Item", raw("Crusader Item"))
		assert.truthy(item.crusader)
		item = new("Item", raw("Redeemer Item"))
		assert.truthy(item.eyrie)
		item = new("Item", raw("Searing Exarch Item"))
		assert.truthy(item.cleansing)
		item = new("Item", raw("Eater of Worlds Item"))
		assert.truthy(item.tangle)
	end)

	it("short flags", function()
		local item = new("Item", raw("Split"))
		assert.truthy(item.split)
		item = new("Item", raw("Mirrored"))
		assert.truthy(item.mirrored)
		item = new("Item", raw("Corrupted"))
		assert.truthy(item.corrupted)
		item = new("Item", raw("Fractured Item"))
		assert.truthy(item.fractured)
		item = new("Item", raw("Synthesised Item"))
		assert.truthy(item.synthesised)
		item = new("Item", raw("Crafted: true"))
		assert.truthy(item.crafted)
		item = new("Item", raw("Unreleased: true"))
		assert.truthy(item.unreleased)
	end)

	it("long flags", function()
		local item = new("Item", raw("This item can be anointed by Cassia"))
		assert.truthy(item.canBeAnointed)
		item = new("Item", raw("Can have a second Enchantment Modifier"))
		assert.truthy(item.canHaveTwoEnchants)
		item = new("Item", raw("Can have 1 additional Enchantment Modifiers"))
		assert.truthy(item.canHaveTwoEnchants)
		item = new("Item", raw("Can have 2 additional Enchantment Modifiers"))
		assert.truthy(item.canHaveTwoEnchants)
		assert.truthy(item.canHaveThreeEnchants)
		item = new("Item", raw("Can have 3 additional Enchantment Modifiers"))
		assert.truthy(item.canHaveTwoEnchants)
		assert.truthy(item.canHaveThreeEnchants)
		assert.truthy(item.canHaveFourEnchants)
		item = new("Item", raw("Has a Crucible Passive Skill Tree with only Support Passive Skills"))
		assert.truthy(item.canHaveOnlySupportSkillsCrucibleTree)
		item = new("Item", raw("Has a Crucible Passive Skill Tree"))
		assert.truthy(item.canHaveShieldCrucibleTree)
		item = new("Item", raw("Has a Two Handed Sword Crucible Passive Skill Tree"))
		assert.truthy(item.canHaveTwoHandedSwordCrucibleTree)
	end)
	
	it("tags", function()
		local item = new("Item", raw("{tags:life,physical_damage}+8 to Strength"))
		assert.are.same({ "life", "physical_damage" }, item.explicitModLines[1].modTags)
	end)

	it("variant", function()
		local item = new("Item", raw([[
			Selected Variant: 2
			{variant:1}+8 to Strength
			{variant:2,3}+10 to Strength
			]]))
		assert.are.equals(2, item.variant)
		assert.are.same({ [1] = true }, item.explicitModLines[1].variantList)
		assert.are.same({ [2] = true, [3] = true }, item.explicitModLines[2].variantList)
		assert.are.equals(10, item.baseModList[1].value) -- variant 2 has +10 to Strength
	end)

	it("range", function()
		local item = new("Item", raw("{range:0.8}+(8-12) to Strength"))
		assert.are.equals(0.8, item.explicitModLines[1].range)
		assert.are.equals(11, item.baseModList[1].value) -- range 0.8 of (8-12) = 11
	end)

	it("crafted", function()
		local item = new("Item", raw("{crafted}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].crafted)
		item = new("Item", raw("+8 to Strength (crafted)"))
		assert.truthy(item.explicitModLines[1].crafted)
	end)

	it("crucible", function()
		local item = new("Item", raw("{crucible}+8 to Strength"))
		assert.truthy(item.crucibleModLines[1].crucible)
		item = new("Item", raw("+8 to Strength (crucible)"))
		assert.truthy(item.crucibleModLines[1].crucible)
	end)

	it("custom", function()
		local item = new("Item", raw("{custom}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].custom)
	end)

	it("eater", function()
		local item = new("Item", raw("{eater}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].eater)
	end)

	it("enchant", function()
		local item = new("Item", raw("+8 to Strength (enchant)"))
		assert.are.equals(1, #item.enchantModLines)
		assert.truthy(item.enchantModLines[1].crafted)
		assert.truthy(item.enchantModLines[1].implicit)
	end)

	it("exarch", function()
		local item = new("Item", raw("{exarch}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].exarch)
	end)

	it("fractured", function()
		local item = new("Item", raw("{fractured}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].fractured)
		item = new("Item", raw("+8 to Strength (fractured)"))
		assert.truthy(item.explicitModLines[1].fractured)
	end)

	it("implicit", function()
		local item = new("Item", raw("+8 to Strength (implicit)"))
		assert.truthy(item.implicitModLines[1].implicit)
	end)

	it("scourge", function()
		local item = new("Item", raw("{scourge}+8 to Strength"))
		assert.truthy(item.scourgeModLines[1].scourge)
		item = new("Item", raw("+8 to Strength (scourge)"))
		assert.truthy(item.scourgeModLines[1].scourge)
	end)

	it("synthesis", function()
		local item = new("Item", raw("{synthesis}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].synthesis)
	end)

	it("multiple bases", function()
		local item = new("Item", [[
			Ashcaller
			Selected Variant: 3
			{variant:1,2,3}Quartz Wand
			{variant:4}Carved Wand
			]])
		assert.are.same({
			["Quartz Wand"] = { line = "Quartz Wand", variantList = { [1] = true, [2] = true, [3] = true } },
			["Carved Wand"] = { line = "Carved Wand", variantList = { [4] = true } }
			}, item.baseLines)
		assert.are.equals("Quartz Wand", item.baseName)

		item = new("Item", [[
			Ashcaller
			Selected Variant: 4
			{variant:1,2,3}Quartz Wand
			{variant:4}Carved Wand
			]])
		assert.are.equals("Carved Wand", item.baseName)
	end)

	it("parses text without armour value then changes quality and has correct final armour", function()
		local item = new("Item", [[
				Armour Gloves
				Iron Gauntlets
				Quality: 0
			]])

		local original = item.armourData.Armour
		item.quality = 20
		item:BuildAndParseRaw()
		assert.are.equals(round(original * 1.2), item.armourData.Armour)
	end)

	it("magic item", function()
		local item = new("Item", [[
				Rarity: MAGIC
				Name Prefix Iron Gauntlets -> +50 ignite chance
				+50% chance to Ignite
			]])

		assert.are.equals("Name Prefix ", item.namePrefix)
		assert.are.equals(" -> +50 ignite chance", item.nameSuffix)
		assert.are.equals("Iron Gauntlets", item.baseName)
		assert.are.equals(1, #item.explicitModLines)
		assert.are.equals("+50% chance to Ignite", item.explicitModLines[1].line)
	end)

	it("Energy Blade", function()
		local item = new("Item", [[
			Item Class: One Hand Swords
			Rarity: Magic
			Superior Energy Blade
		]])
		assert.are.equal("Energy Blade One Handed", item.baseName)
		item = new("Item", [[
			Item Class: Two Hand Swords
			Rarity: Magic
			Superior Energy Blade
		]])
		assert.are.equal("Energy Blade Two Handed", item.baseName)
	end)

	it("Flask buff", function()
		local item = new("Item", [[
			Rarity: Magic
			Chemist's Granite Flask of the Opossum
		]])
		assert.are.equal(1, #item.buffModLines)
		assert.are.equal("+1500 to Armour", item.buffModLines[1].line)
	end)

	it("advanced clipboard paste resolves editable affixes", function()
		local item = new("Item", [[
			Item Class: Shields
			Rarity: Rare
			Grim Badge
			Ezomyte Tower Shield
			--------
			Quality: +20% (augmented)
			Chance to Block: 42% (augmented)
			Armour: 562 (augmented)
			--------
			Requirements:
			Level: 72
			Str: 159
			Dex: 70
			Int: 98
			--------
			Sockets: R B R
			--------
			Item Level: 87
			--------
			{ Implicit Modifier — Life }
			+40(30-40) to maximum Life
			--------
			{ Prefix Modifier "Hunter's" (Tier: 2) — Life }
			6(3-6)% increased maximum Life
			{ Prefix Modifier "Robust" (Tier: 6) — Life }
			+83(70-84) to maximum Life
			{ Prefix Modifier "Unyielding" (Tier: 1) }
			77(76-81)% increased Chance to Block
			{ Suffix Modifier "of the Conservator" (Tier: 1) — Physical }
			8% additional Physical Damage Reduction
			{ Suffix Modifier "of the Solar Storm" (Tier: 1) — Elemental, Fire, Resistance }
			+3% to maximum Fire Resistance
			(Maximum Resistances cannot be raised above 90%)
			{ Suffix Modifier "of the Hunt" (Tier: 1) — Gem }
			Socketed Gems have 30% increased Reservation Efficiency — Unscalable Value
			--------
			Hunter Item
		]])
		assert.truthy(item.crafted)
		assert.are.equals("MaximumLifeInfluence1", item.prefixes[1].modId)
		assert.are.near(1, item.prefixes[1].range, 0.0001)
		assert.are.equals("IncreasedLife5", item.prefixes[2].modId)
		assert.are.near(13 / 14, item.prefixes[2].range, 0.0001)
		assert.are.equals("LocalIncreasedBlockPercentage7", item.prefixes[3].modId)
		assert.are.near(0.2, item.prefixes[3].range, 0.0001)
		assert.are.equals("AdditionalPhysicalDamageReduction5_", item.suffixes[1].modId)
		assert.are.equals("MaximumFireResist3", item.suffixes[2].modId)
		assert.are.equals("SocketedGemsReducedReservationInfluence2", item.suffixes[3].modId)
		assert.are.equals(1, #item.implicitModLines)
		assert.are.equals("+(30-40) to maximum Life", item.implicitModLines[1].line)
		assert.are.near(1, item.implicitModLines[1].range, 0.0001)
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = true
		end
		assert.truthy(explicitLines["6% increased maximum Life"])
		assert.truthy(explicitLines["+83 to maximum Life"])
		assert.truthy(explicitLines["77% increased Chance to Block"])
		assert.truthy(explicitLines["8% additional Physical Damage Reduction"])
		assert.truthy(explicitLines["+3% to maximum Fire Resistance"])
		assert.truthy(explicitLines["Socketed Gems have 30% increased Reservation Efficiency"])
		assert.is_nil(item.raw:match("Unscalable Value"))
		assert.is_nil(item.raw:match("Maximum Resistances cannot be raised above 90"))
		assert.truthy(item.raw:match("Crafted: true"))
	end)

	it("advanced clipboard paste preserves unique modifiers", function()
		local item = new("Item", [[
			Item Class: Sceptres
			Rarity: Unique
			Nebulis
			Synthesised Void Sceptre
			--------
			Sceptre
			Quality: +20% (augmented)
			Physical Damage: 50-76
			Chaos Damage: 8-23 (augmented)
			Critical Strike Chance: 7.30%
			Attacks per Second: 1.25
			Weapon Range: 1.1 metres
			--------
			Requirements:
			Level: 70
			Str: 155
			Int: 122
			--------
			Sockets: W W W
			--------
			Item Level: 87
			--------
			Quality does not increase Physical Damage (enchant)
			Grants 1% increased Area of Effect per 4% Quality (enchant)
			--------
			{ Implicit Modifier — Damage, Elemental, Attack  — 116% Increased }
			Attacks with this Weapon Penetrate 5(4-5)% Elemental Resistances
			{ Implicit Modifier — Damage, Chaos, Attack  — 116% Increased }
			Adds 4(4-9) to 11(11-21) Chaos Damage
			{ Implicit Modifier — Damage, Elemental, Fire, Ailment  — 116% Increased }
			Ignites you inflict deal Damage 20(15-20)% faster
			(They will deal the same total damage over a shorter duration)
			--------
			{ Unique Modifier }
			116(60-120)% increased Implicit Modifier magnitudes — Unscalable Value
			(Implicit Modifiers are those that come from an item's type, rather than its random properties)
			{ Unique Modifier — Caster, Speed }
			20(15-20)% increased Cast Speed
			{ Unique Modifier — Damage }
			10(5-10)% increased Elemental Damage per 1% Fire, Cold, or Lightning Resistance above 75%
			--------
			The vastness of the cosmos holds energies beyond comprehension,
			should one have the fortitude to grasp them.
			--------
			Synthesised Item
		]])
		assert.falsy(item.crafted)
		assert.truthy(item.synthesised)
		assert.truthy(item.variantList)
		assert.are.equals("Current", item.variantList[item.variant])
		local function assertNebulisState(currentItem)
			local function renderedLine(modLine)
				if modLine.range then
					return itemLib.applyRange(modLine.line, modLine.range, modLine.valueScalar)
				elseif modLine.valueScalar and modLine.valueScalar ~= 1 then
					return itemLib.applyValueScalar(modLine.line, modLine.valueScalar)
				end
				return modLine.line
			end
			local enchantLines = { }
			for _, modLine in ipairs(currentItem.enchantModLines) do
				enchantLines[modLine.line] = modLine
			end
			assert.are.equals(2, #currentItem.enchantModLines)
			assert.truthy(enchantLines["Quality does not increase Physical Damage"])
			assert.truthy(enchantLines["Grants 1% increased Area of Effect per 4% Quality"])
			assert.are.equals("Grants 1% increased Area of Effect per 4% Quality", renderedLine(enchantLines["Grants 1% increased Area of Effect per 4% Quality"]))

			local implicitLines = { }
			local renderedImplicitLines = { }
			for _, modLine in ipairs(currentItem.implicitModLines) do
				implicitLines[modLine.line] = modLine
				renderedImplicitLines[renderedLine(modLine)] = modLine
			end
			assert.are.equals(3, #currentItem.implicitModLines)
			assert.truthy(renderedImplicitLines["Attacks with this Weapon Penetrate 10% Elemental Resistances"])
			assert.truthy(renderedImplicitLines["Adds 8 to 23 Chaos Damage"])
			assert.truthy(renderedImplicitLines["Ignites you inflict deal Damage 43% faster"])
			assert.is_nil(implicitLines["40% increased Elemental Damage"])
			assert.are.equals(8, currentItem.weaponData[1].ChaosMin)
			assert.are.equals(23, currentItem.weaponData[1].ChaosMax)

			local explicitLines = { }
			local activeExplicitLines = { }
			local activeExplicitLineCount = 0
			local implicitMagnitudeLine
			local implicitMagnitudeCount = 0
			for _, modLine in ipairs(currentItem.explicitModLines) do
				explicitLines[modLine.line] = modLine
				if currentItem:CheckModLineVariant(modLine) then
					activeExplicitLines[modLine.line] = modLine
					activeExplicitLineCount = activeExplicitLineCount + 1
				end
				if currentItem:CheckModLineVariant(modLine) and modLine.line:match("Implicit Modifier magnitudes") then
					implicitMagnitudeLine = modLine
					implicitMagnitudeCount = implicitMagnitudeCount + 1
				end
			end
			assert.are.equals(3, activeExplicitLineCount)
			assert.truthy(implicitMagnitudeLine)
			assert.are.equals(1, implicitMagnitudeCount)
			assert.are.near(14 / 15, implicitMagnitudeLine.range, 0.001)
			assert.is_nil(implicitMagnitudeLine.extra)
			assert.are.equals("ImplicitModifierMagnitudes", implicitMagnitudeLine.modList[1].name)
			assert.are.equals("INC", implicitMagnitudeLine.modList[1].type)
			assert.are.equals("117% increased Implicit Modifier magnitudes", renderedLine(implicitMagnitudeLine))
			local rangeLineFound = false
			for _, modLine in ipairs(currentItem.rangeLineList) do
				if modLine.line:match("Implicit Modifier magnitudes") then
					rangeLineFound = true
					assert.are.near(14 / 15, modLine.range, 0.001)
				end
			end
			assert.truthy(rangeLineFound)
			assert.truthy(activeExplicitLines["(15-20)% increased Cast Speed"])
			assert.are.near(1, activeExplicitLines["(15-20)% increased Cast Speed"].range, 0.001)
			assert.truthy(activeExplicitLines["(5-10)% increased Elemental Damage per 1% Fire, Cold, or Lightning Resistance above 75%"])
			assert.are.near(1, activeExplicitLines["(5-10)% increased Elemental Damage per 1% Fire, Cold, or Lightning Resistance above 75%"].range, 0.001)
			assert.is_nil(activeExplicitLines["40% increased Elemental Damage"])
			assert.is_nil(explicitLines["The vastness of the cosmos holds energies beyond comprehension,"])
			assert.is_nil(explicitLines["should one have the fortitude to grasp them."])
			assert.is_nil(currentItem.raw:match("Unscalable Value"))
			assert.is_nil(currentItem.raw:match("40%% increased Elemental Damage"))
		end

		assertNebulisState(item)
		item:BuildAndParseRaw()
		assertNebulisState(item)
	end)

	it("advanced clipboard paste supports implicit modifier magnitudes lines without canonical unique remap", function()
		local item = new("Item", [[
			Item Class: Amulets
			Rarity: Unique
			Test Relic
			Citrine Amulet
			--------
			Requirements:
			Level: 54
			--------
			Item Level: 83
			--------
			{ Unique Modifier }
			Implicit Modifier magnitudes are doubled
		]])
		assert.are.equals("UNIQUE", item.rarity)
		assert.are.equals(1, #item.explicitModLines)
		assert.is_nil(item.explicitModLines[1].extra)
		assert.are.equals("ImplicitModifierMagnitudes", item.explicitModLines[1].modList[1].name)
		assert.are.equals("INC", item.explicitModLines[1].modList[1].type)
		assert.are.equals(100, item.explicitModLines[1].modList[1].value)
		assert.truthy(itemLib.formatModLine(item.explicitModLines[1]):match("Implicit Modifier magnitudes are doubled$"))
	end)

	it("fixed-value implicit lines do not become range sliders when implicit magnitudes scale them", function()
		local item = new("Item", [[
			Item Class: Amulets
			Rarity: Unique
			Test Relic
			Citrine Amulet
			--------
			Requirements:
			Level: 54
			--------
			Item Level: 83
			--------
			{ Implicit Modifier }
			+2 to maximum number of Raised Zombies
			--------
			{ Unique Modifier }
			Implicit Modifier magnitudes are doubled
		]])
		assert.are.equals("UNIQUE", item.rarity)
		assert.truthy(item.implicitModLines[1])
		assert.are.equals("+2 to maximum number of Raised Zombies", item.implicitModLines[1].line)
		assert.are.equals(0, #item.rangeLineList)
		item:BuildAndParseRaw()
		assert.are.equals(0, #item.rangeLineList)
	end)

	it("advanced clipboard paste supports unveiled modifier magnitudes on cane of kulemak", function()
		local item = new("Item", [[
			Item Class: Warstaves
			Rarity: Unique
			Cane of Kulemak
			Serpentine Staff
			--------
			Warstaff
			Physical Damage: 56-117
			Critical Strike Chance: 7.80%
			Attacks per Second: 1.25
			Weapon Range: 1.3 metres
			--------
			Requirements:
			Level: 68
			Str: 85
			Int: 85
			--------
			Sockets: R
			--------
			Item Level: 85
			--------
			{ Implicit Modifier }
			+22% Chance to Block Attack Damage while wielding a Staff
			(Warstaves are considered Staves)
			--------
			{ Prefix Modifier "Catarina's" — Damage, Caster  — 67% Increased }
			Socketed Gems are Supported by Level 1 Arcane Surge — Unscalable Value
			80(80-89)% increased Spell Damage
			{ Prefix Modifier "Chosen" (Tier: 1) — Damage, Elemental, Attack  — 67% Increased }
			Attacks with this Weapon Penetrate 14(14-16)% Elemental Resistances
			{ Unique Modifier }
			67(60-90)% increased Unveiled Modifier magnitudes — Unscalable Value
			{ Suffix Modifier "of the Order" (Tier: 1) — Damage, Elemental, Fire  — 67% Increased }
			+44(44-48)% to Fire Damage over Time Multiplier
			--------
			Stolen power is still power.
		]])
		assert.are.equals("UNIQUE", item.rarity)
		local explicitLines = { }
		local renderedExplicitLines = { }
		local unveiledMagnitudeLine
		local arcaneSurgeLine
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
			local rendered = modLine.range and itemLib.applyRange(modLine.line, modLine.range, modLine.valueScalar) or (modLine.valueScalar and modLine.valueScalar ~= 1 and itemLib.applyValueScalar(modLine.line, modLine.valueScalar)) or modLine.line
			renderedExplicitLines[rendered] = modLine
			if modLine.line:match("Unveiled Modifier magnitudes") then
				unveiledMagnitudeLine = modLine
			elseif modLine.line:match("Socketed Gems are Supported by Level 1 Arcane Surge") then
				arcaneSurgeLine = modLine
			end
		end
		assert.truthy(unveiledMagnitudeLine)
		assert.is_nil(unveiledMagnitudeLine.extra)
		assert.are.equals("UnveiledModifierMagnitudes", unveiledMagnitudeLine.modList[1].name)
		assert.are.equals("INC", unveiledMagnitudeLine.modList[1].type)
		assert.truthy(arcaneSurgeLine)
		assert.truthy(arcaneSurgeLine.unscalable)
		assert.is_nil(renderedExplicitLines["Socketed Gems are Supported by Level 2 Arcane Surge"])
		assert.truthy(renderedExplicitLines["Socketed Gems are Supported by Level 1 Arcane Surge"])
		assert.truthy(renderedExplicitLines["133% increased Spell Damage"])
		assert.truthy(renderedExplicitLines["Attacks with this Weapon Penetrate 23% Elemental Resistances"])
		assert.truthy(renderedExplicitLines["+73% to Fire Damage over Time Multiplier"])
		item:BuildAndParseRaw()
		local rebuiltRenderedExplicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			local rendered = modLine.range and itemLib.applyRange(modLine.line, modLine.range, modLine.valueScalar) or (modLine.valueScalar and modLine.valueScalar ~= 1 and itemLib.applyValueScalar(modLine.line, modLine.valueScalar)) or modLine.line
			rebuiltRenderedExplicitLines[rendered] = modLine
			if modLine.line:match("Socketed Gems are Supported by Level 1 Arcane Surge") then
				assert.truthy(modLine.unscalable)
				assert.truthy(modLine.veiled)
			end
		end
		assert.truthy(rebuiltRenderedExplicitLines["133% increased Spell Damage"])
		assert.truthy(rebuiltRenderedExplicitLines["Attacks with this Weapon Penetrate 23% Elemental Resistances"])
		assert.truthy(rebuiltRenderedExplicitLines["+73% to Fire Damage over Time Multiplier"])
		local rangeLineFound = false
		for _, modLine in ipairs(item.rangeLineList) do
			if modLine.line:match("Unveiled Modifier magnitudes") then
				rangeLineFound = true
			end
		end
		assert.truthy(rangeLineFound)
	end)

	it("advanced clipboard paste recognizes veiled affixes outside the old name whitelist", function()
		local item = new("Item", [[
			Item Class: Rings
			Rarity: Rare
			Test Ring
			Coral Ring
			--------
			Requirements:
			Level: 1
			--------
			Item Level: 85
			--------
			{ Prefix Modifier "Elreon's" — Mana  — 67% Increased }
			Non-Channelling Skills have -9(-10--9) to Total Mana Cost
			{ Unique Modifier }
			67(60-90)% increased Unveiled Modifier magnitudes — Unscalable Value
		]])
		local veiledLine
		local renderedExplicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			local rendered = modLine.range and itemLib.applyRange(modLine.line, modLine.range, modLine.valueScalar) or (modLine.valueScalar and modLine.valueScalar ~= 1 and itemLib.applyValueScalar(modLine.line, modLine.valueScalar)) or modLine.line
			renderedExplicitLines[rendered] = modLine
			if modLine.line:match("Non%-Channelling Skills have %-%(10%-9%)") then
				veiledLine = modLine
				break
			end
		end
		assert.truthy(veiledLine)
		assert.truthy(veiledLine.custom)
		assert.truthy(veiledLine.veiled)
		assert.is_nil(veiledLine.extra)
		assert.truthy(veiledLine.modList[1])
		assert.truthy(renderedExplicitLines["Non-Channelling Skills have -15 to Total Mana Cost"])
	end)

	it("advanced clipboard unique canonicalization preserves catalyst metadata", function()
		local item = new("Item", [[
			Item Class: Amulets
			Rarity: Unique
			Eyes of the Greatwolf
			Greatwolf Talisman
			--------
			Requirements:
			Level: 52
			--------
			Item Level: 85
			Catalyst: Intrinsic
			CatalystQuality: 20
			--------
			{ Implicit Modifier — Attribute }
			32% increased Attributes
			{ Unique Modifier }
			Implicit Modifier magnitudes are doubled
		]])
		assert.are.equals(5, item.catalyst)
		assert.are.equals(20, item.catalystQuality)
		assert.truthy(item.variantList)
		item:BuildAndParseRaw()
		assert.are.equals(5, item.catalyst)
		assert.are.equals(20, item.catalystQuality)
		assert.truthy(item.variantList)
	end)

	it("crucible implicit modifier magnitudes scale imported implicits", function()
		local item = new("Item", raw("{implicit}+8 to Strength\n{crucible}25% increased Implicit Modifier magnitudes", "Citrine Amulet"))
		assert.are.equals(10, item.baseModList[1].value)
		assert.are.equals(0, #item.rangeLineList)
		item:BuildAndParseRaw()
		assert.are.equals(10, item.baseModList[1].value)
	end)

	it("implicit modifier magnitudes stack additively across explicit and crucible sources", function()
		local item = new("Item", raw([[
			{implicit}Adds 4 to 11 Chaos Damage
			116% increased Implicit Modifier magnitudes
			{crucible}25% increased Implicit Modifier magnitudes
		]], "Void Sceptre"))
		assert.are.equals(9, item.weaponData[1].ChaosMin)
		assert.are.equals(26, item.weaponData[1].ChaosMax)
	end)

	it("advanced clipboard paste canonicalises single-variant uniques", function()
		local item = new("Item", [[
			Item Class: Rings
			Rarity: Unique
			Ventor's Gamble
			Gold Ring
			--------
			Requirements:
			Level: 65
			--------
			Item Level: 85
			--------
			{ Implicit Modifier — Drop }
			13(6-15)% increased Rarity of Items found
			--------
			{ Unique Modifier — Life }
			+55(0-60) to maximum Life
			{ Unique Modifier — Elemental, Fire, Resistance }
			+14(-25-50)% to Fire Resistance
			{ Unique Modifier — Elemental, Cold, Resistance }
			+29(-25-50)% to Cold Resistance
			{ Unique Modifier — Elemental, Lightning, Resistance }
			-20(-25-50)% to Lightning Resistance
			{ Unique Modifier — Drop }
			1(-40-40)% increased Rarity of Items found
			{ Unique Modifier — Mana }
			3(-15-15)% increased Mana Reservation Efficiency of Skills
			--------
			In a blaze of glory,
			An anomaly defying all odds
			The "unkillable" beast met the divine
			And Ventor met his latest trophy.
		]])
		assert.are.equals("UNIQUE", item.rarity)
		assert.truthy(item.variantList)
		assert.are.equals("Current", item.variantList[item.variant])
		local activeImplicitCount = 0
		local activeImplicitLine
		for _, modLine in ipairs(item.implicitModLines) do
			if item:CheckModLineVariant(modLine) then
				activeImplicitCount = activeImplicitCount + 1
				activeImplicitLine = modLine
			end
		end
		assert.are.equals(1, activeImplicitCount)
		assert.are.equals("(6-15)% increased Rarity of Items found", activeImplicitLine.line)
		assert.are.near(7 / 9, activeImplicitLine.range, 0.001)

		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.truthy(explicitLines["+(0-60) to maximum Life"])
		assert.are.near(11 / 12, explicitLines["+(0-60) to maximum Life"].range, 0.001)
		assert.truthy(explicitLines["+(-25-50)% to Fire Resistance"])
		assert.are.near(39 / 75, explicitLines["+(-25-50)% to Fire Resistance"].range, 0.001)
		assert.truthy(explicitLines["+(-25-50)% to Cold Resistance"])
		assert.are.near(54 / 75, explicitLines["+(-25-50)% to Cold Resistance"].range, 0.001)
		assert.truthy(explicitLines["+(-25-50)% to Lightning Resistance"])
		assert.are.near(5 / 75, explicitLines["+(-25-50)% to Lightning Resistance"].range, 0.001)
		assert.truthy(explicitLines["(-40-40)% increased Rarity of Items found"])
		assert.are.near(41 / 80, explicitLines["(-40-40)% increased Rarity of Items found"].range, 0.001)
		assert.truthy(explicitLines["(-15-15)% increased Mana Reservation Efficiency of Skills"])
		assert.are.near(18 / 30, explicitLines["(-15-15)% increased Mana Reservation Efficiency of Skills"].range, 0.001)
		assert.is_nil(item.raw:match("In a blaze of glory,"))
	end)

	it("advanced clipboard paste preserves unmatched unique implicits", function()
		local item = new("Item", [[
			Item Class: Helmets
			Rarity: Unique
			Honourhome
			Soldier Helmet
			--------
			Quality: +20% (augmented)
			Armour: 91 (augmented)
			Energy Shield: 20 (augmented)
			--------
			Requirements:
			Level: 72
			Str: 96
			Dex: 100
			Int: 72
			--------
			Sockets: G-B-G-R
			--------
			Item Level: 85
			--------
			{ Corruption Implicit Modifier — Gem }
			+2 to Level of Socketed Projectile Gems
			--------
			{ Unique Modifier — Defences, Armour, Energy Shield }
			111(100-150)% increased Armour and Energy Shield
			{ Unique Modifier — Damage, Elemental, Lightning, Attack, Caster }
			Adds 1 to 30 Lightning Damage to Spells and Attacks
			{ Unique Modifier — Mana }
			20(10-20)% reduced Mana Cost of Skills
			{ Unique Modifier — Drop }
			19(10-20)% increased Rarity of Items found
			{ Unique Modifier — Gem }
			+2 to Level of Socketed Gems
			--------
			"The craven mind is sharp with self interest.
			The honourable mind is much easier to manipulate."
			 - Malachai the Soulless
			--------
			Corrupted
		]])
		assert.are.equals("UNIQUE", item.rarity)
		assert.truthy(item.variantList)
		assert.are.equals("Current", item.variantList[item.variant])
		assert.truthy(item.corrupted)
		local implicitLines = { }
		for _, modLine in ipairs(item.implicitModLines) do
			implicitLines[modLine.line] = modLine
		end
		assert.truthy(implicitLines["+2 to Level of Socketed Projectile Gems"])
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.truthy(explicitLines["(100-150)% increased Armour and Energy Shield"])
		assert.are.near(11 / 50, explicitLines["(100-150)% increased Armour and Energy Shield"].range, 0.001)
		assert.truthy(explicitLines["Adds 1 to 30 Lightning Damage to Spells and Attacks"])
		assert.truthy(explicitLines["(10-20)% reduced Mana Cost of Skills"])
		assert.are.near(1, explicitLines["(10-20)% reduced Mana Cost of Skills"].range, 0.001)
		assert.truthy(explicitLines["(10-20)% increased Rarity of Items found"])
		assert.are.near(0.9, explicitLines["(10-20)% increased Rarity of Items found"].range, 0.001)
		assert.truthy(explicitLines["+2 to Level of Socketed Gems"])
	end)

	it("advanced clipboard paste rebuilds rare affixes alongside crafted and fractured mods", function()
		local item = new("Item", [[
			Item Class: Gloves
			Rarity: Rare
			Armageddon Fist
			Leviathan Gauntlets
			--------
			Quality: +20% (augmented)
			Armour: 493 (augmented)
			--------
			Requirements:
			Level: 84
			Str: 144
			Dex: 155
			Int: 155
			--------
			Sockets: B-B-G-G
			--------
			Item Level: 86
			--------
			{ Searing Exarch Implicit Modifier (Exquisite) — Elemental, Fire, Ailment }
			Ignites you inflict spread to other Enemies within 1.6 metres
			{ Eater of Worlds Implicit Modifier (Grand) }
			0.4% of Fire Damage Leeched as Life
			(Leeched Life is recovered over time. Multiple Leeches can occur simultaneously, up to a maximum rate)
			--------
			{ Prefix Modifier "Burnished" (Tier: 3) — Damage, Physical, Attack }
			Adds 3(2-3) to 5(4-5) Physical Damage to Attacks
			{ Prefix Modifier "Athlete's" (Tier: 1) — Life }
			+128(115-129) to maximum Life
			{ Master Crafted Prefix Modifier "Upgraded" — Damage }
			12(10-12)% increased Area of Effect
			16(14-16)% increased Area Damage
			{ Fractured Suffix Modifier "of the Blur" (Tier: 1) — Attribute }
			+59(56-60) to Dexterity
			{ Suffix Modifier "of Bameth" (Tier: 1) — Chaos, Resistance }
			+31(31-35)% to Chaos Resistance
			{ Suffix Modifier "of Everlasting" (Tier: 1) — Life }
			21(20-21)% increased Life Regeneration rate
			Searing Exarch Item
			Eater of Worlds Item
			--------
			Fractured Item
		]])
		assert.truthy(item.crafted)
		assert.truthy(item.fractured)
		assert.truthy(item.cleansing)
		assert.truthy(item.tangle)
		assert.are.equals(3, #item.prefixes)
		assert.are.equals(3, #item.suffixes)
		assert.are.equals("None", item.prefixes[3].modId)
		assert.are_not.equals("None", item.prefixes[1].modId)
		assert.are_not.equals("None", item.prefixes[2].modId)
		assert.are_not.equals("None", item.suffixes[1].modId)
		assert.truthy(item.suffixes[1].fractured)
		assert.are_not.equals("None", item.suffixes[2].modId)
		assert.are_not.equals("None", item.suffixes[3].modId)
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.truthy(explicitLines["Adds 3 to 5 Physical Damage to Attacks"])
		assert.truthy(explicitLines["+128 to maximum Life"])
		assert.truthy(explicitLines["+59 to Dexterity"])
		assert.truthy(explicitLines["+31% to Chaos Resistance"])
		assert.truthy(explicitLines["21% increased Life Regeneration rate"])
		assert.truthy(explicitLines["(10-12)% increased Area of Effect"])
		assert.truthy(explicitLines["(10-12)% increased Area of Effect"].crafted)
		assert.are.near(1, explicitLines["(10-12)% increased Area of Effect"].range, 0.0001)
		assert.truthy(explicitLines["(14-16)% increased Area Damage"])
		assert.truthy(explicitLines["(14-16)% increased Area Damage"].crafted)
		assert.are.near(1, explicitLines["(14-16)% increased Area Damage"].range, 0.0001)
		assert.truthy(explicitLines["+59 to Dexterity"].fractured)
		assert.are.equals(2, #item.implicitModLines)
		assert.truthy(item.implicitModLines[1].exarch or item.implicitModLines[2].exarch)
		assert.truthy(item.implicitModLines[1].eater or item.implicitModLines[2].eater)
	end)

	it("advanced clipboard paste ignores memory strands metadata", function()
		local item = new("Item", [[
			Item Class: Amulets
			Rarity: Rare
			Rage Idol
			Onyx Amulet
			--------
			Memory Strands: 17
			--------
			Requirements:
			Level: 60
			--------
			Item Level: 83
			--------
			{ Implicit Modifier — Attribute }
			+13(10-16) to all Attributes
			(Attributes are Strength, Dexterity, and Intelligence)
			--------
			{ Prefix Modifier "Incinerating" (Tier: 3) — Damage, Elemental, Fire, Attack }
			Adds 17(13-18) to 31(27-31) Fire Damage to Attacks
			{ Prefix Modifier "Virile" (Tier: 2) — Life }
			+108(100-114) to maximum Life
			{ Prefix Modifier "Flaring" (Tier: 1) — Damage, Physical, Attack }
			Adds 14(11-15) to 23(22-26) Physical Damage to Attacks
			{ Suffix Modifier "of the Virtuoso" (Tier: 2) — Attribute }
			+48(43-50) to Intelligence
			{ Suffix Modifier "of the Volcano" (Tier: 3) — Elemental, Fire, Resistance }
			+39(36-41)% to Fire Resistance
			{ Master Crafted Suffix Modifier "of Craft" (Rank: 2) — Attribute }
			+13(10-13) to all Attributes
			(Attributes are Strength, Dexterity, and Intelligence)
		]])
		assert.truthy(item.crafted)
		assert.are.equals(3, #item.prefixes)
		assert.are.equals(3, #item.suffixes)
		local prefixIds = { }
		for _, affix in ipairs(item.prefixes) do
			prefixIds[affix.modId] = affix
		end
		assert.truthy(prefixIds["AddedFireDamage7"])
		assert.truthy(prefixIds["IncreasedLife7"])
		assert.truthy(prefixIds["AddedPhysicalDamage9"])
		assert.are.near(0.9, prefixIds["AddedFireDamage7"].range, 0.0001)
		assert.are.near(0.5, prefixIds["AddedPhysicalDamage9"].range, 0.0001)
		assert.truthy(prefixIds["AddedFireDamage7"].displayLines)
		assert.truthy(prefixIds["AddedPhysicalDamage9"].displayLines)

		local suffixIds = { }
		for _, affix in ipairs(item.suffixes) do
			suffixIds[affix.modId] = affix
		end
		assert.truthy(suffixIds["Intelligence8"])
		assert.truthy(suffixIds["FireResist6"])
		assert.is_nil(item.raw:match("Memory Strands"))
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
			assert.are_not.equals("Memory Strands: 17", modLine.line)
		end
		assert.truthy(explicitLines["Adds 17 to 31 Fire Damage to Attacks"])
		assert.truthy(explicitLines["Adds 14 to 23 Physical Damage to Attacks"])
		assert.truthy(explicitLines["Adds 17 to 31 Fire Damage to Attacks"].modList[1])
		assert.truthy(explicitLines["Adds 14 to 23 Physical Damage to Attacks"].modList[1])
	end)

	it("advanced clipboard temple affixes survive crafted affix edits", function()
		local item = new("Item", [[
			Item Class: Helmets
			Rarity: Rare
			Corruption Shelter
			Samnite Helmet
			--------
			Armour: 369 (augmented)
			--------
			Requirements:
			Level: 55
			Str: 114
			--------
			Sockets: R R-R
			--------
			Item Level: 69
			--------
			{ Prefix Modifier "Fortified" (Tier: 5) — Defences, Armour }
			+66(64-82) to Armour
			{ Master Crafted Prefix Modifier "Upgraded" (Rank: 3) — Life }
			+44(41-55) to maximum Life
			{ Suffix Modifier "of Puhuarte" — Physical, Elemental, Fire, Resistance }
			+48(46-48)% to Fire Resistance
			4(3-5)% of Physical Damage from Hits taken as Fire Damage
			{ Suffix Modifier "of the Yeti" (Tier: 5) — Elemental, Cold, Resistance }
			+26(24-29)% to Cold Resistance
			{ Suffix Modifier "of the Storm" (Tier: 6) — Elemental, Lightning, Resistance }
			+19(18-23)% to Lightning Resistance
		]])
		local function assertPuhuartePresent(currentItem)
			local explicitLines = { }
			local counts = { }
			for _, modLine in ipairs(currentItem.explicitModLines) do
				explicitLines[modLine.line] = modLine
				counts[modLine.line] = (counts[modLine.line] or 0) + 1
			end
			assert.truthy(explicitLines["+(46-48)% to Fire Resistance"] or explicitLines["+48% to Fire Resistance"])
			assert.truthy(explicitLines["(3-5)% of Physical Damage from Hits taken as Fire Damage"] or explicitLines["4% of Physical Damage from Hits taken as Fire Damage"])
			assert.are.equals(1, (counts["+(46-48)% to Fire Resistance"] or counts["+48% to Fire Resistance"]))
			assert.are.equals(1, (counts["(3-5)% of Physical Damage from Hits taken as Fire Damage"] or counts["4% of Physical Damage from Hits taken as Fire Damage"]))
		end
		assertPuhuartePresent(item)
		item.prefixes[1].range = 0.1
		item:Craft()
		assertPuhuartePresent(item)
		item.suffixes[2].range = 0.2
		item:Craft()
		assertPuhuartePresent(item)
	end)

	it("advanced clipboard paste canonicalises unique flask variants", function()
		local item = new("Item", [[
			Item Class: Utility Flasks
			Rarity: Unique
			Cinderswallow Urn
			Silver Flask
			--------
			Quality: +20% (augmented)
			Lasts 5.20 Seconds
			Consumes 60 of 80 Charges on use
			Currently has 80 Charges
			--------
			Requirements:
			Level: 48
			--------
			Item Level: 87
			--------
			{ Unique Modifier }
			+13(10-20) to maximum Charges
			{ Unique Modifier }
			Recharges 5 Charges when you Consume an Ignited corpse
			{ Unique Modifier }
			Enemies Ignited by you during Effect take 8(7-10)% increased Damage
			{ Unique Modifier }
			Recover 3(1-3)% of Life when you Kill an Enemy during Effect
			{ Unique Modifier — Caster, Curse }
			Enemies Ignited by you during Effect have Malediction
			--------
			The ashes of a charred sire still carry his son.
		]])
		assert.are.equals("UNIQUE", item.rarity)
		assert.are.equals("Silver Flask", item.baseName)
		assert.truthy(item.variantList)
		assert.truthy(item.hasAltVariant)
		assert.are.equals("Life on Kill", item.variantList[item.variant])
		assert.are.equals("Ignited enemies have Malediction", item.variantList[item.variantAlt])
		assert.are.near(5.2, item.flaskData.duration, 0.0001)
		assert.are.equals(60, item.flaskData.chargesUsed)
		assert.are.equals(80, item.flaskData.chargesMax)
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.truthy(explicitLines["+(10-20) to maximum Charges"])
		assert.are.near(0.3, explicitLines["+(10-20) to maximum Charges"].range, 0.0001)
		assert.truthy(explicitLines["Recover (1-3)% of Life when you Kill an Enemy during Effect"])
		assert.are.near(1, explicitLines["Recover (1-3)% of Life when you Kill an Enemy during Effect"].range, 0.0001)
		assert.truthy(explicitLines["Enemies Ignited by you during Effect have Malediction"])
		assert.truthy(explicitLines["Enemies Ignited by you during Effect have Malediction"].modList[1])

		explicitLines["+(10-20) to maximum Charges"].range = 1
		item:BuildAndParseRaw()
		assert.are.equals(87, item.flaskData.chargesMax)
		assert.truthy(item.raw:match("Consumes 60 of 87 Charges on use"))

		item.quality = 0
		item:BuildAndParseRaw()
		assert.is_true(item.flaskData.duration < 5.2)
		assert.is_nil(item.raw:match("Lasts 5%.20 Seconds"))
	end)

	it("normal clipboard paste ignores flask buff reminder lines", function()
		local item = new("Item", [[
			Item Class: Utility Flasks
			Rarity: Unique
			Cinderswallow Urn
			Silver Flask
			--------
			Quality: +20% (augmented)
			Lasts 7.20 (augmented) Seconds
			Consumes 40 of 80 (augmented) Charges on use
			Currently has 80 Charges
			Onslaught
			(Onslaught grants 20% increased Attack, Cast, and Movement Speed)
			--------
			Requirements:
			Level: 48
			--------
			Item Level: 85
			--------
			Used when Charges reach full (enchant)
			--------
			{ Prefix Modifier "Catarina's" }
			Enemies Ignited by you during Effect have Malediction
			(Malediction causes 10% reduced Damage dealt and 10% increased Damage taken)
			{ Unique Modifier }
			+20(10-20) to Maximum Charges
			{ Unique Modifier }
			Recharges 5 Charges when you Consume an Ignited corpse
			{ Unique Modifier — Damage }
			Enemies Ignited by you during Effect take 7(7-10)% increased Damage
			{ Unique Modifier — Life }
			Recover 3(1-3)% of Life when you Kill an Enemy during Effect
			--------
			A controlled burn is sometimes necessary for new life.
			--------
			Right click to drink. Can only hold charges while in belt. Refills as you kill monsters.
		]])
		assert.are.equals("UNIQUE", item.rarity)
		assert.are.equals("Silver Flask", item.baseName)
		assert.are.near(7.2, item.flaskData.duration, 0.0001)
		assert.are.equals(40, item.flaskData.chargesUsed)
		assert.are.equals(80, item.flaskData.chargesMax)
		local hasOnslaughtBuff = false
		for _, modLine in ipairs(item.buffModLines) do
			if modLine.line == "Onslaught" then
				hasOnslaughtBuff = true
			end
		end
		assert.truthy(hasOnslaughtBuff)
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.is_nil(explicitLines["(Onslaught grants 20% increased Attack, Cast, and Movement Speed)"])
		assert.is_nil(item.raw:match("%(Onslaught grants 20%% increased Attack, Cast, and Movement Speed%)"))
	end)

	it("BuildAndParseRaw tolerates tooltip-style temporary explicit lines on flasks", function()
		local item = new("Item", [[
			Item Class: Utility Flasks
			Rarity: Magic
			Dabbler's Sulphur Flask of the Conger
			--------
			Quality: +20% (augmented)
			Lasts 3.60 (augmented) Seconds
			Consumes 40 of 60 Charges on use
			Currently has 60 Charges
			40% increased Damage
			--------
			Requirements:
			Level: 40
			--------
			Item Level: 84
			--------
			70% increased effect (enchant)
			Gains no Charges during Effect (enchant)
			--------
			{ Implicit Modifier }
			Creates Consecrated Ground on Use
			(Allies on your Consecrated Ground Regenerate a percentage of their Maximum Life per second, and Curses have 50% reduced effect on them)
			--------
			{ Prefix Modifier "Dabbler's" (Tier: 2) }
			31(32-28)% reduced Duration
			25% increased effect
			{ Suffix Modifier "of the Conger" (Tier: 3) }
			45(49-45)% less Duration
			Immunity to Shock during Effect
			--------
			Right click to drink. Can only hold charges while in belt. Refills as you kill monsters.
		]])
		table.insert(item.explicitModLines, {
			line = "25% increased effect",
			modTags = { "resource" },
			modList = nil,
			extra = nil,
		})
		local ok, err = pcall(function()
			item:BuildAndParseRaw()
		end)
		assert.truthy(ok)
		assert.is_nil(err)
	end)

	it("advanced clipboard flask enchant range survives BuildAndParseRaw", function()
		local item = new("Item", [[
			Item Class: Utility Flasks
			Rarity: Magic
			Dabbler's Sulphur Flask of the Conger
			--------
			Quality: +20% (augmented)
			Lasts 3.60 (augmented) Seconds
			Consumes 40 of 60 Charges on use
			Currently has 60 Charges
			40% increased Damage
			--------
			Requirements:
			Level: 40
			--------
			Item Level: 84
			--------
			70% increased effect (enchant)
			Gains no Charges during Effect (enchant)
			--------
			{ Implicit Modifier }
			Creates Consecrated Ground on Use
			(Allies on your Consecrated Ground Regenerate a percentage of their Maximum Life per second, and Curses have 50% reduced effect on them)
			--------
			{ Prefix Modifier "Dabbler's" (Tier: 2) }
			31(32-28)% reduced Duration
			25% increased effect
			{ Suffix Modifier "of the Conger" (Tier: 3) }
			45(49-45)% less Duration
			Immunity to Shock during Effect
			--------
			Right click to drink. Can only hold charges while in belt. Refills as you kill monsters.
		]])
		assert.are.equals(2, #item.enchantModLines)
		assert.are.equals("(60-70)% increased effect", item.enchantModLines[1].line)
		assert.are.near(1, item.enchantModLines[1].range, 0.0001)
		item.enchantModLines[1].range = 0.5
		item:BuildAndParseRaw()
		assert.are.equals(2, #item.enchantModLines)
		local rangedEnchant
		for _, modLine in ipairs(item.enchantModLines) do
			if modLine.line == "(60-70)% increased effect" then
				rangedEnchant = modLine
				break
			end
		end
		assert.truthy(rangedEnchant)
		assert.are.near(0.5, rangedEnchant.range, 0.0001)
		local foundRangeLine = false
		for _, modLine in ipairs(item.rangeLineList) do
			if modLine.line == "(60-70)% increased effect" and math.abs((modLine.range or 0) - 0.5) < 0.0001 then
				foundRangeLine = true
			end
		end
		assert.truthy(foundRangeLine)
	end)

	it("normal clipboard paste ignores tincture display and footer lines", function()
		local item = new("Item", [[
			Item Class: Tinctures
			Rarity: Unique
			Mightblood Ire
			Ironwood Tincture
			--------
			Inflicts Mana Burn every 1.07 (augmented) Seconds
			10 Second Cooldown when Deactivated
			--------
			Requirements:
			Level: 18
			--------
			Item Level: 71
			--------
			40% reduced Enemy Stun Threshold with Melee Weapons (implicit)
			18% increased Stun Duration with Melee Weapons (implicit)
			--------
			Melee Strike Skills deal Splash Damage to surrounding targets
			16% reduced Mana Burn rate
			--------
			The liquid within boils and fumes,
			ready to erupt at any provocation.
			--------
			Right click to activate. Only one Tincture in your belt can be active at a time. Mana Burn causes you to lose 1% of your maximum Mana per stack per second. Can be deactivated manually, or will automatically deactivate when you reach 0 Mana.
		]])
		assert.are.equals("UNIQUE", item.rarity)
		assert.are.equals("Ironwood Tincture", item.baseName)
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.truthy(explicitLines["Melee Strike Skills deal Splash Damage to surrounding targets"])
		assert.truthy(explicitLines["16% reduced Mana Burn rate"])
		assert.is_nil(explicitLines["Inflicts Mana Burn every 1.07 Seconds"])
		assert.is_nil(explicitLines["10 Second Cooldown when Deactivated"])
		assert.is_nil(item.raw:match("Inflicts Mana Burn every 1%.07 Seconds"))
		assert.is_nil(item.raw:match("10 Second Cooldown when Deactivated"))
		assert.is_nil(item.raw:match("Right click to activate%. Only one Tincture in your belt can be active at a time%."))
	end)

	it("advanced clipboard paste resolves magic flask affixes with reversed ranges", function()
		local item = new("Item", [[
			Item Class: Utility Flasks
			Rarity: Magic
			Dabbler's Sulphur Flask of the Conger
			--------
			Quality: +20% (augmented)
			Lasts 3.60 (augmented) Seconds
			Consumes 40 of 60 Charges on use
			Currently has 60 Charges
			40% increased Damage
			--------
			Requirements:
			Level: 40
			--------
			Item Level: 84
			--------
			70% increased effect (enchant)
			Gains no Charges during Effect (enchant)
			--------
			{ Implicit Modifier }
			Creates Consecrated Ground on Use
			(Allies on your Consecrated Ground Regenerate a percentage of their Maximum Life per second, and Curses have 50% reduced effect on them)
			--------
			{ Prefix Modifier "Dabbler's" (Tier: 2) }
			31(32-28)% reduced Duration
			25% increased effect
			{ Suffix Modifier "of the Conger" (Tier: 3) }
			45(49-45)% less Duration
			Immunity to Shock during Effect
			--------
			Right click to drink. Can only hold charges while in belt. Refills as you kill monsters.
		]])
		assert.truthy(item.crafted)
		assert.are.equals("FlaskEffectReducedDuration2", item.prefixes[1].modId)
		assert.are.near(0.75, item.prefixes[1].range, 0.0001)
		assert.are.equals("FlaskShockImmunityDuringEffect", item.suffixes[1].modId)
		assert.are.near(0, item.suffixes[1].range, 0.0001)
		assert.are.near(3.6, item.flaskData.duration, 0.0001)
		assert.are.equals(40, item.flaskData.chargesUsed)
		assert.are.equals(60, item.flaskData.chargesMax)
		local enchantLines = { }
		for _, modLine in ipairs(item.enchantModLines) do
			enchantLines[modLine.line] = modLine
		end
		assert.truthy(enchantLines["(60-70)% increased effect"])
		assert.are.near(1, enchantLines["(60-70)% increased effect"].range, 0.0001)
		assert.truthy(enchantLines["Gains no Charges during Effect"])
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.truthy(explicitLines["31% reduced Duration"])
		assert.truthy(explicitLines["25% increased effect"])
		assert.truthy(explicitLines["45% less Duration"])
		assert.truthy(explicitLines["Immunity to Shock during Effect"])
		assert.is_nil(explicitLines["Right click to drink. Can only hold charges while in belt. Refills as you kill monsters."])
		assert.is_nil(item.raw:match("Right click to drink%. Can only hold charges while in belt%. Refills as you kill monsters%."))
	end)

	it("normal clipboard paste canonicalises flask enkindling enchants to source ranges", function()
		local item = new("Item", [[
			Item Class: Utility Flasks
			Rarity: Magic
			Alchemist's Gold Flask
			--------
			Quality: +20% (augmented)
			Lasts 4.60 (augmented) Seconds
			Consumes 60 of 80 Charges on use
			30% increased Rarity of Items found
			--------
			Requirements:
			Level: 64
			--------
			Item Level: 83
			--------
			70% increased effect (enchant)
			Gains no Charges during Effect (enchant)
			--------
			23% reduced Duration
			25% increased effect
			30% increased Rarity of Items found during Effect (crafted)
		--------
		Right click to drink. Can only hold charges while in belt. Refills as you kill monsters.
	]])
		assert.are.equals(2, #item.enchantModLines)
		assert.are.equals("(60-70)% increased effect", item.enchantModLines[1].line)
		assert.are.near(1, item.enchantModLines[1].range, 0.0001)
		assert.are.equals("Gains no Charges during Effect", item.enchantModLines[2].line)
		assert.is_nil(item.enchantModLines[2].range)
		local hasRangedEnchant = false
		for _, modLine in ipairs(item.rangeLineList) do
			if modLine.line == "(60-70)% increased effect" then
				hasRangedEnchant = true
				assert.are.near(1, modLine.range, 0.0001)
			end
		end
		assert.truthy(hasRangedEnchant)
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.truthy(explicitLines["30% increased Rarity of Items found during Effect"])
		assert.truthy(explicitLines["30% increased Rarity of Items found during Effect"].crafted)
		assert.is_nil(explicitLines["70% increased effect"])
	end)

	it("advanced clipboard paste keeps mirrored transformed affixes as exact explicit lines", function()
		local item = new("Item", [[
			Item Class: Rings
			Rarity: Rare
			Pandemonium Spiral
			Moonstone Ring
			--------
			Requirements:
			Level: 65
			--------
			Item Level: 83
			--------
			{ Implicit Modifier — Defences, Energy Shield }
			+24(15-25) to maximum Energy Shield
			--------
			{ Prefix Modifier "Gentian" (Tier: 6) — Mana }
			-109(50-54) to maximum Mana
			{ Prefix Modifier "Glimmering" (Tier: 10) — Defences, Energy Shield }
			+10(4-8) to maximum Energy Shield
			{ Prefix Modifier "Burnished" — Damage, Physical, Attack }
			Adds 6(2-3) to 10(4-5) Physical Damage to Attacks against you
			{ Suffix Modifier "of the Titan" (Tier: 2) — Attribute }
			+100(43-50) to Strength
			{ Suffix Modifier "of Bandaging" (Tier: 4) — Life }
			12(4-6)% of Damage taken Recouped as Life
			(Only Damage from Hits can be Recouped, over 4 seconds following the Hit)
			{ Suffix Modifier "of the Genius" (Tier: 1) — Attribute }
			-113(51-55) to Intelligence
			--------
			Mirrored
		]])
		assert.truthy(item.mirrored)
		assert.falsy(item.crafted)
		assert.are.equals(0, #item.prefixes)
		assert.are.equals(0, #item.suffixes)
		assert.are.equals(1, #item.implicitModLines)
		assert.are.equals("+(15-25) to maximum Energy Shield", item.implicitModLines[1].line)
		assert.are.near(0.9, item.implicitModLines[1].range, 0.0001)

		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.truthy(explicitLines["+100 to Strength"])
		assert.truthy(explicitLines["-113 to Intelligence"])
		assert.truthy(explicitLines["Adds 6 to 10 Physical Damage to Attacks against you"])
		assert.truthy(explicitLines["+10 to maximum Energy Shield"])
		assert.truthy(explicitLines["-109 to maximum Mana"])
		assert.truthy(explicitLines["12% of Damage taken Recouped as Life"])
		assert.is_nil(explicitLines["Adds 6(2-3) to 10(4-5) Physical Damage to Attacks against you"])
		assert.is_nil(explicitLines["-(50-54) to maximum Mana"])
		assert.is_nil(explicitLines["-(51-55) to Intelligence"])
		assert.is_nil(explicitLines["+100 to Strength"].extra)
		assert.is_nil(explicitLines["-113 to Intelligence"].extra)
		assert.is_nil(explicitLines["Adds 6 to 10 Physical Damage to Attacks against you"].extra)
		assert.is_nil(explicitLines["-109 to maximum Mana"].extra)
		assert.is_nil(item.raw:match("Crafted: true"))
	end)

	it("items tab affix sliders initialise to imported flask roll positions", function()
		local item = new("Item", [[
			Item Class: Utility Flasks
			Rarity: Magic
			Dabbler's Sulphur Flask of the Conger
			--------
			Quality: +20% (augmented)
			Lasts 3.60 (augmented) Seconds
			Consumes 40 of 60 Charges on use
			Currently has 60 Charges
			40% increased Damage
			--------
			Requirements:
			Level: 40
			--------
			Item Level: 84
			--------
			70% increased effect (enchant)
			Gains no Charges during Effect (enchant)
			--------
			{ Implicit Modifier }
			Creates Consecrated Ground on Use
			(Allies on your Consecrated Ground Regenerate a percentage of their Maximum Life per second, and Curses have 50% reduced effect on them)
			--------
			{ Prefix Modifier "Dabbler's" (Tier: 2) }
			31(32-28)% reduced Duration
			25% increased effect
			{ Suffix Modifier "of the Conger" (Tier: 3) }
			45(49-45)% less Duration
			Immunity to Shock during Effect
			--------
			Right click to drink. Can only hold charges while in belt. Refills as you kill monsters.
		]])
		local itemsTabClass = common.classes["ItemsTab"]
		local prefixControl = { slider = { } }
		itemsTabClass.UpdateAffixControl({ displayItem = item }, prefixControl, item, "Prefix", "prefixes", 1)
		assert.are.equals(3, prefixControl.slider.divCount)
		assert.are.equals(2, isValueInArray(prefixControl.list[prefixControl.selIndex].modList, item.prefixes[1].modId))
		assert.are.near(1.25 / 3, prefixControl.slider.val, 0.0001)

		local suffixControl = { slider = { } }
		itemsTabClass.UpdateAffixControl({ displayItem = item }, suffixControl, item, "Suffix", "suffixes", 1)
		assert.are.equals(3, suffixControl.slider.divCount)
		assert.are.equals(1, isValueInArray(suffixControl.list[suffixControl.selIndex].modList, item.suffixes[1].modId))
		assert.are.near(1 / 3, suffixControl.slider.val, 0.0001)
	end)

	it("advanced clipboard paste ignores tincture display and footer lines", function()
		local item = new("Item", [[
			Item Class: Tinctures
			Rarity: Unique
			Mightblood Ire
			Ironwood Tincture
			--------
			Inflicts Mana Burn every 1.07 (augmented) Seconds
			10 Second Cooldown when Deactivated
			--------
			Requirements:
			Level: 18
			--------
			Item Level: 71
			--------
			{ Implicit Modifier — Attack }
			40% reduced Enemy Stun Threshold with Melee Weapons
			(The Stun Threshold determines how much Damage can Stun something)
			18(15-25)% increased Stun Duration with Melee Weapons
			--------
			{ Unique Modifier — Attack }
			Melee Strike Skills deal Splash Damage to surrounding targets
			{ Unique Modifier }
			16(25-15)% reduced Mana Burn rate
			--------
			The liquid within boils and fumes,
			ready to erupt at any provocation.
			--------
			Right click to activate. Only one Tincture in your belt can be active at a time. Mana Burn causes you to lose 1% of your maximum Mana per stack per second. Can be deactivated manually, or will automatically deactivate when you reach 0 Mana.
		]])
		assert.are.equals("UNIQUE", item.rarity)
		assert.are.equals("Ironwood Tincture", item.baseName)
		local explicitLines = { }
		local hasManaBurnRateLine = false
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
			if modLine.line:find("reduced Mana Burn rate", 1, true) then
				hasManaBurnRateLine = true
			end
		end
		assert.truthy(explicitLines["Melee Strike Skills deal Splash Damage to surrounding targets"])
		assert.truthy(hasManaBurnRateLine)
		assert.is_nil(explicitLines["Inflicts Mana Burn every 1.07 Seconds"])
		assert.is_nil(explicitLines["10 Second Cooldown when Deactivated"])
		assert.is_nil(item.raw:match("Inflicts Mana Burn every 1%.07 Seconds"))
		assert.is_nil(item.raw:match("10 Second Cooldown when Deactivated"))
		assert.is_nil(item.raw:match("Right click to activate%. Only one Tincture in your belt can be active at a time%."))
	end)

	it("advanced clipboard paste ignores jewel socket instructions", function()
		local item = new("Item", [[
			Item Class: Jewels
			Rarity: Rare
			Damnation Brand
			Synthesised Crimson Jewel
			--------
			Item Level: 83
			--------
			{ Implicit Modifier — Damage, Elemental, Fire }
			3(2-3)% increased Burning Damage
			--------
			{ Prefix Modifier "Rupturing" (Tier: 1) — Damage, Attack, Critical }
			+15(15-18)% to Critical Strike Multiplier with Two Handed Melee Weapons
			{ Prefix Modifier "Brutal" (Tier: 1) — Damage, Attack }
			16(14-16)% increased Damage with Maces or Sceptres
			{ Suffix Modifier "of the Flameruler" (Tier: 1) — Elemental, Fire, Ailment }
			34(30-35)% reduced Ignite Duration on you
			{ Suffix Modifier "of Spirit" (Tier: 1) — Attribute }
			+10(8-10) to Strength and Intelligence
			--------
			Place into an allocated Jewel Socket on the Passive Skill Tree. Right click to remove from the Socket.
			--------
			Synthesised Item
		]])
		assert.are.equals("RARE", item.rarity)
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.truthy(explicitLines["+15% to Critical Strike Multiplier with Two Handed Melee Weapons"])
		assert.truthy(explicitLines["16% increased Damage with Maces or Sceptres"])
		assert.truthy(explicitLines["34% reduced Ignite Duration on you"])
		assert.truthy(explicitLines["+10 to Strength and Intelligence"])
		assert.is_nil(explicitLines["Place into an allocated Jewel Socket on the Passive Skill Tree. Right click to remove from the Socket."])
		assert.is_nil(item.raw:match("Place into an allocated Jewel Socket on the Passive Skill Tree%. Right click to remove from the Socket%."))
	end)

	it("advanced clipboard paste keeps special-source affixes out of the base affix controls", function()
		local itemsTabClass = common.classes["ItemsTab"]
		local item = new("Item", [[
			Item Class: Amulets
			Rarity: Rare
			Kraken Beads
			Marble Amulet
			--------
			Requirements:
			Level: 74
			--------
			Item Level: 85
			--------
			Allocates Agility (enchant)
			--------
			{ Implicit Modifier — Life }
			Regenerate 1.6(1.2-1.6)% of Life per second
			--------
			{ Prefix Modifier "Subterranean" (Tier: 1) — Damage, Elemental, Fire }
			28(20-30)% increased Fire Damage
			{ Master Crafted Prefix Modifier "Upgraded" (Rank: 3) — Life }
			+50(41-55) to maximum Life
			{ Suffix Modifier "of the Titan" (Tier: 2) — Attribute }
			+43(43-50) to Strength
			{ Suffix Modifier "of the Volcano" (Tier: 3) — Elemental, Fire, Resistance }
			+40(36-41)% to Fire Resistance
			{ Suffix Modifier "of Shaping" (Tier: 1) — Damage, Elemental, Fire }
			+16(16-20)% to Fire Damage over Time Multiplier
			--------
			Shaper Item
		]])
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.truthy(explicitLines["(20-30)% increased Fire Damage"])
		assert.is_true(explicitLines["(20-30)% increased Fire Damage"].custom)
		assert.are.near(0.8, explicitLines["(20-30)% increased Fire Damage"].range, 0.001)
		assert.is_nil(explicitLines["(20-30)% increased Fire Damage"].extra)
		assert.truthy(explicitLines["(20-30)% increased Fire Damage"].modList[1])

		local prefixControl = { slider = { } }
		itemsTabClass.UpdateAffixControl({ displayItem = item }, prefixControl, item, "Prefix", "prefixes", 1)
		assert.are.equals(1, prefixControl.selIndex)
		assert.are.equals("None", prefixControl.list[prefixControl.selIndex])

		local familyCases = {
			{
				raw = [[
					Item Class: Amulets
					Rarity: Rare
					Essence Knot
					Amber Amulet
					--------
					Requirements:
					Level: 20
					--------
					Item Level: 83
					--------
					{ Prefix Modifier "Essences" — Chaos, Poison, Damage }
					40% increased Damage with Poison
				]],
				expectedLine = "40% increased Damage with Poison",
			},
			{
				raw = [[
					Item Class: Sceptres
					Rarity: Rare
					Night Chant
					Void Sceptre
					--------
					Requirements:
					Level: 60
					Str: 81
					Int: 117
					--------
					Item Level: 83
					--------
					{ Prefix Modifier "Chosen" — Damage, Chaos, Caster }
					65(60-69)% increased Spell Damage
					Gain 5% of Non-Chaos Damage as extra Chaos Damage
				]],
				expectedLine = "Gain 5% of Non-Chaos Damage as extra Chaos Damage",
			},
			{
				raw = [[
					Item Class: Rings
					Rarity: Rare
					Order Loop
					Gold Ring
					--------
					Requirements:
					Level: 20
					--------
					Item Level: 83
					--------
					{ Suffix Modifier "of the Order" — Elemental, Fire, Resistance, Chaos }
					+18(16-20)% to Fire and Chaos Resistances
				]],
				expectedLine = "+(16-20)% to Fire and Chaos Resistances",
			},
			{
				raw = [[
					Item Class: Amulets
					Rarity: Rare
					Farrul Talisman
					Citrine Amulet
					--------
					Requirements:
					Level: 20
					--------
					Item Level: 83
					--------
					{ Suffix Modifier "of Farrul" — Aspect }
					Grants Level 20 Aspect of the Cat Skill
				]],
				expectedLine = "Grants Level 20 Aspect of the Cat Skill",
			},
		}
		for _, case in ipairs(familyCases) do
			local specialItem = new("Item", case.raw)
			local foundLine
			for _, modLine in ipairs(specialItem.explicitModLines) do
				if modLine.line == case.expectedLine then
					foundLine = modLine
					break
				end
			end
			assert.truthy(foundLine)
			assert.is_true(foundLine.custom)
			assert.truthy(foundLine.modList[1])
			specialItem:BuildAndParseRaw()
			local rebuiltLine
			for _, modLine in ipairs(specialItem.explicitModLines) do
				if modLine.line == case.expectedLine then
					rebuiltLine = modLine
					break
				end
			end
			assert.truthy(rebuiltLine)
			assert.truthy(rebuiltLine.modList[1])
		end
	end)

	it("advanced clipboard paste normalises negative crafted mana cost ranges", function()
		local item = new("Item", [[
			Item Class: Rings
			Rarity: Rare
			Dire Band
			Two-Stone Ring
			--------
			Quality (Prefix Modifiers): +14% (augmented)
			Memory Strands: 11
			--------
			Requirements:
			Level: 64
			--------
			Item Level: 83
			--------
			{ Implicit Modifier — Elemental, Fire, Cold, Resistance }
			+13(12-16)% to Fire and Cold Resistances
			--------
			{ Prefix Modifier "Blue" (Tier: 3) — Mana  — 14% Increased }
			+65(65-68) to maximum Mana
			{ Prefix Modifier "Annealed" (Tier: 1) — Damage, Physical, Attack  — 14% Increased }
			Adds 7(6-9) to 13(13-15) Physical Damage to Attacks
			{ Master Crafted Prefix Modifier "Upgraded" — Mana  — 14% Increased }
			Non-Channelling Skills have -7(-7--6) to Total Mana Cost
			{ Suffix Modifier "of the Titan" (Tier: 2) — Attribute }
			+44(43-50) to Strength
			{ Suffix Modifier "of Feat" (Tier: 2) — Life }
			Gain 64(56-72) Life per Enemy Killed
			{ Suffix Modifier "of the Phantom" (Tier: 2) — Attribute }
			+45(43-50) to Dexterity
		]])
		assert.truthy(item.crafted)
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.are.equals("Quality (Prefix Modifiers): +14%", item.explicitModLines[1].line)
		assert.truthy(explicitLines["Non-Channelling Skills have -(7-6) to Total Mana Cost"])
		assert.truthy(explicitLines["Non-Channelling Skills have -(7-6) to Total Mana Cost"].crafted)
		assert.is_nil(explicitLines["Non-Channelling Skills have --7 to Total Mana Cost"])
		assert.is_nil(item.raw:match("%-%-7 to Total Mana Cost"))
	end)

	it("advanced clipboard paste strips inline unique flavour text", function()
		local item = new("Item", [[
			Item Class: Boots
			Rarity: Unique
			Wondertrap
			Velvet Slippers
			--------
			Quality: +20% (augmented)
			Energy Shield: 28 (augmented)
			--------
			Requirements:
			Level: 70
			Str: 111
			Dex: 98
			Int: 70
			--------
			Sockets: R-B-G-G
			--------
			Item Level: 84
			--------
			{ Corruption Implicit Modifier }
			+1 to Maximum Endurance Charges
			--------
			{ Unique Modifier — Defences, Energy Shield }
			+12(5-30) to maximum Energy Shield
			{ Unique Modifier — Attribute }
			+20(5-30) to Strength
			{ Unique Modifier — Attribute }
			+20(5-30) to Dexterity
			{ Unique Modifier — Attribute }
			+29(5-30) to Intelligence
			{ Unique Modifier — Speed }
			18(10-25)% increased Movement Speed
			{ Unique Modifier — Drop }
			100% increased Rarity of Items found when on Low Life
			(You are on Low Life if you have 50% of your Maximum Life or less)
			--------
			Wonders abound at death's door.
			--------
			Corrupted
		]])
		assert.are.equals("UNIQUE", item.rarity)
		local explicitLines = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitLines[modLine.line] = modLine
		end
		assert.truthy(explicitLines["+(5-30) to Strength"])
		assert.truthy(explicitLines["+(5-30) to Dexterity"])
		assert.truthy(explicitLines["+(5-30) to Intelligence"])
		assert.truthy(explicitLines["+(5-30) to maximum Energy Shield"])
		assert.truthy(explicitLines["100% increased Rarity of Items found when on Low Life"])
		assert.is_nil(explicitLines["Wonders abound at death's door."])
		assert.is_nil(item.raw:match("Wonders abound at death's door%."))
	end)

	it("advanced clipboard paste does not create range sliders for fixed unique modifiers", function()
		local item = new("Item", [[
			Item Class: Gloves
			Rarity: Unique
			Shaper's Touch
			Crusader Gloves
			--------
			Quality: +20% (augmented)
			Armour: 303 (augmented)
			Energy Shield: 61 (augmented)
			--------
			Requirements:
			Level: 70
			Str: 111
			Dex: 68
			Int: 98
			--------
			Sockets: R-R-B-B
			--------
			Item Level: 86
			--------
			{ Unique Modifier — Mana }
			+1 Mana per 4 Strength
			{ Unique Modifier — Defences, Energy Shield }
			1% increased Energy Shield per 10 Strength
			{ Unique Modifier — Life }
			+1 Life per 4 Dexterity
			{ Unique Modifier — Damage, Physical, Attack }
			2% increased Melee Physical Damage per 10 Dexterity
			{ Unique Modifier — Attack }
			+4(2) Accuracy Rating per 2 Intelligence
			{ Unique Modifier — Defences, Evasion }
			2% increased Evasion Rating per 10 Intelligence
			{ Unique Modifier — Defences, Armour, Energy Shield }
			87(80-120)% increased Armour and Energy Shield
			--------
			By my hand, the inert is given life.
			By my hand, that which rots is reborn.
			There is nothing that cannot be changed.
			Nothing.
			--------
			Shaper Item
		]])
		local rangeLines = { }
		for _, modLine in ipairs(item.rangeLineList) do
			rangeLines[modLine.line] = modLine
		end
		assert.truthy(rangeLines["(80-120)% increased Armour and Energy Shield"])
		assert.is_nil(rangeLines["+1 Mana per 4 Strength"])
		assert.is_nil(rangeLines["1% increased Energy Shield per 10 Strength"])
		assert.is_nil(rangeLines["+1 Life per 4 Dexterity"])
		assert.is_nil(rangeLines["2% increased Melee Physical Damage per 10 Dexterity"])
		assert.is_nil(rangeLines["+4 Accuracy Rating per 2 Intelligence"])
		assert.is_nil(rangeLines["2% increased Evasion Rating per 10 Intelligence"])
	end)
end)
