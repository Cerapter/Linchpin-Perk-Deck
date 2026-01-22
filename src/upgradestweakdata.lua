if not restoration then
    return
end

--- ## FOR DEBUGGING PURPOSES ONLY, SET TO 1 FOR RELEASE
--- Simply multiplies most effect numbers by this number, for easier visibility on changes.
--- (Primarily for testing stack numbers between clients because I apparently suck at networking.)
LINCHPIN_DEBUGNUMBERS = 1

Hooks:PostHook(UpgradesTweakData, "_init_pd2_values", "linchpin_init", function(self)
    self.linchpin_proximity = 1800 -- Centimetres proximity required to gain Cohesion stacks.
    self.linchpin_per_crew_member = 8 -- The amount of Cohesion stacks per crew, used for tendency determination and "for every X" number.
    self.linchpin_change_t = 1 -- In seconds, how frequently do Cohesion stacks change.
    self.linchpin_hard_limit = 4 -- The maximum amount of players we'll ever consider for Cohesion counting. In case of Big Lobby mods, we shouldn't escalate to ridiculous amounts.
	-- Represents how much a loss of a specific "resource" equals in damage taken. I.e., is taking health damage worse than taking armour damage for the purposes of Cohesion stack loss?
	self.linchpin_damage_weighs_for_stack_loss = {
		health = 2,
		armour = 1
	}

    -- Cohesion stacks gained per second per crew member nearby.
    self.linchpin_gain = 1

    -- Cohesion stacks lost per second when trending downwards.
    self.linchpin_loss = 2

    -- Sets up the 18 metre radius Cohesion stack gaining aura.
    self.values.player.linchpin_emit_aura = {
        true
    }

	-- How much damage must be taken to lose a stack of Cohesion.
	self.values.team.player.linchpin_damage_to_lose = {
		16, -- default
		32 -- Dig In Your Heels
	}

    -- Healing potency increase from Stick Together, per crew member.
    self.values.team.player.linchpin_crew_heal_potency = {
        0.04 * LINCHPIN_DEBUGNUMBERS
    }

    -- Dodge metre increase per second from Eyes Open and Stand Firm, percentage value.
	-- **UNUSED!**
    self.values.team.player.linchpin_crew_dodge_metre_fill = {
        0.01 * LINCHPIN_DEBUGNUMBERS
    }
	-- I feel like this can be merged with the first one, but I am not sure what an upgrade being incremental does.
	-- I thought they'd just get added together, but then a buncha upgrades in Vanilla go 1 then 2 in values.
	-- That'd mean they have 3 stages, but they often only have 2.
	-- **UNUSED!**
    self.values.team.player.linchpin_crew_dodge_metre_fill_2 = {
        0.01 * LINCHPIN_DEBUGNUMBERS
    }
    self.crew_dodge_metre_fill_t = 1 -- In seconds, how frequently should the dodge meter be given. **UNUSED!**

	-- Ammo pickup multiplier.
	self.values.team.player.linchpin_ammo_pickup_boost = {
		0.02 * LINCHPIN_DEBUGNUMBERS
	}

    -- Percentage value, the dodge points increases for the team per Cohesion.
	-- **UNUSED!**
    self.values.team.player.linchpin_crew_dodge_points = {
        0.0125 * LINCHPIN_DEBUGNUMBERS,
        0.025 * LINCHPIN_DEBUGNUMBERS
    }

    -- Percentage value, the movespeed increases for the team per Cohesion.
    self.values.team.player.linchpin_crew_movespeed_bonus = {
        0.02 * LINCHPIN_DEBUGNUMBERS
    }

    -- Percentage value, the movespeed increases for the team per Cohesion.
    self.values.team.player.linchpin_crew_reload_bonus = {
        0.02 * LINCHPIN_DEBUGNUMBERS
    }

	-- Increase any tendency the player has by this amount of stacks.
	self.values.team.player.linchpin_increase_default_tendency = {
		8
	}

	-- HP regeneration based on stacks.
	self.values.team.player.linchpin_regen_health = {
		{
			amount = 0.025 * LINCHPIN_DEBUGNUMBERS, -- This much health per X Cohesion stacks.
			seconds = 5 -- This often.
		}
	}

	-- How much faster should armour be regenerated based on stacks, in percentages.
	self.values.team.player.linchpin_armour_regen_bonus = {
		0.02 * LINCHPIN_DEBUGNUMBERS
	}

	-- Additional armour granted to players per Cohesion stack.
	self.values.team.player.linchpin_additional_armour = {
		0.4 * LINCHPIN_DEBUGNUMBERS
	}

	-- How much faster should stamina regenerate based on stacks.
	self.values.team.player.linchpin_stamina_regen_bonus = {
        0.02 * LINCHPIN_DEBUGNUMBERS
	}

	-- Additional bonus for the move / reload speed bonus. As they're mutually-exclusive choices, sadly I cannot make use of upgrading them.
	self.values.team.player.linchpin_additional_move_reload_bonus = {
        0.01 * LINCHPIN_DEBUGNUMBERS
	}

    -- How many Cohesion stacks should everyone nearby gain when a crew member kills an amount of enemies.
	-- Kills are tracked individually.
    self.values.team.player.linchpin_crew_kill_stack_reward = {
        {
			enemies = 4,
			stacks = 1 * LINCHPIN_DEBUGNUMBERS
		}
    }

    -- Adds a fixed amount of Cohesion stacks to any effects that want Cohesion values specifically.
    self.values.player.linchpin_treat_as_more_cohesion = {
        8
    }

	-- Concrete values on how the Linchpin user's stacks could change.
	self.values.player.linchpin_stack_change_adjustments = {
		{
			gain = 1,
			loss = 1
		},
		{
			gain = -0.5,
			loss = -1
		},
		{
			gain = 0,
			loss = 0
		}
	}

    -- How many Cohesion stacks should be gained on revive with Back To It!.
    self.values.player.linchpin_stacks_on_revive = {
        48
    }

    -- How many Cohesion stacks should everyone nearby gain when you kill X amount of enemies.
    self.values.player.linchpin_personal_kill_stack_reward = {
        {
			enemies = 1,
			stacks = 1 * LINCHPIN_DEBUGNUMBERS
		}
    }
end)

Hooks:PostHook(UpgradesTweakData, "_player_definitions", "linchpin_player_definitions", function(self)
    -- The "aura", the 18 metres proximity around the Linchpin user.
    self.definitions.player_linchpin_aura = {
		name_id = "menu_deck_linchpin_1",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "linchpin_emit_aura",
			category = "player"
		}
	}

    -- Treats the user as having more Cohesion for effects.
    self.definitions.player_linchpin_treat_as_more_cohesion = {
		name_id = "menu_deck_linchpin_3",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "linchpin_treat_as_more_cohesion",
			category = "player"
		}
	}

	-- Change Cohesion gain and loss.
    self.definitions.player_linchpin_stack_change_adjustments_1 = {
		name_id = "menu_deck_linchpin_3_1",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "linchpin_stack_change_adjustments",
			category = "player"
		}
	}
    self.definitions.player_linchpin_stack_change_adjustments_2 = {
		name_id = "menu_deck_linchpin_3_1",
		category = "feature",
		upgrade = {
			value = 2,
			upgrade = "linchpin_stack_change_adjustments",
			category = "player"
		}
	}
    self.definitions.player_linchpin_stack_change_adjustments_3 = {
		name_id = "menu_deck_linchpin_3_1",
		category = "feature",
		upgrade = {
			value = 3,
			upgrade = "linchpin_stack_change_adjustments",
			category = "player"
		}
	}

    -- Cohesion stacks on revive.
    self.definitions.player_linchpin_stacks_on_revive = {
		name_id = "menu_deck_linchpin_7_1",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "linchpin_stacks_on_revive",
			category = "player"
		}
	}

    -- Cohesion stacks on kills.
    self.definitions.player_linchpin_personal_kill_stack_reward = {
		name_id = "menu_deck_linchpin_7_1",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "linchpin_personal_kill_stack_reward",
			category = "player"
		}
	}
end)

Hooks:PostHook(UpgradesTweakData, "_team_definitions", "linchpin_team_definitions", function(self)
	-- Damage to take to lose Cohesion.
    self.definitions.team_linchpin_damage_to_lose_1 = {
		name_id = "menu_deck_linchpin_1",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_damage_to_lose",
			category = "player"
		}
	}
    self.definitions.team_linchpin_damage_to_lose_2 = {
		name_id = "menu_deck_linchpin_9_1",
		category = "team",
		upgrade = {
			value = 2,
			upgrade = "linchpin_damage_to_lose",
			category = "player"
		}
	}

    -- Crew healing potency increase from Cohesion stacks.
    self.definitions.team_linchpin_crew_heal_potency = {
		name_id = "menu_deck_linchpin_1_1",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_crew_heal_potency",
			category = "player"
		}
	}

    -- Crew dodge metre autofill from Cohesion stacks.
	-- **UNUSED!**
    self.definitions.team_linchpin_crew_dodge_metre_fill = {
		name_id = "menu_deck_linchpin_1_2",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_crew_dodge_metre_fill",
			category = "player"
		}
	}
    self.definitions.team_linchpin_crew_dodge_metre_fill_2 = {
		name_id = "menu_deck_linchpin_9_2",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_crew_dodge_metre_fill_2",
			category = "player"
		}
	}

	-- Ammo pickup multiplier for the crew based on Cohesion stacks.
	self.definitions.team_linchpin_ammo_pickup_multiplier = {
		name_id = "menu_deck_linchpin_1_2",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_ammo_pickup_boost",
			category = "player"
		}
	}

    -- Crew dodge point gain.
	-- **UNUSED!**
    self.definitions.team_linchpin_crew_dodge_points_1 = {
		name_id = "menu_deck_linchpin_3",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_crew_dodge_points",
			category = "player"
		}
	}
    self.definitions.team_linchpin_crew_dodge_points_2 = {
		name_id = "menu_deck_linchpin_7",
		category = "team",
		upgrade = {
			value = 2,
			upgrade = "linchpin_crew_dodge_points",
			category = "player"
		}
	}

    -- Crew movespeed increase from Cohesion stacks.
    self.definitions.team_linchpin_crew_movespeed_bonus = {
		name_id = "menu_deck_linchpin_5_1",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_crew_movespeed_bonus",
			category = "player"
		}
	}

    -- Crew reload speed increase from Cohesion stacks.
    self.definitions.team_linchpin_crew_reload_bonus = {
		name_id = "menu_deck_linchpin_5_1",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_crew_reload_bonus",
			category = "player"
		}
	}

    -- Crew default tendency increase.
    self.definitions.team_linchpin_increase_default_tendency = {
		name_id = "menu_deck_linchpin_9",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_increase_default_tendency",
			category = "player"
		}
	}

    -- Crew health regen from Cohesion stacks.
    self.definitions.team_linchpin_regen_health = {
		name_id = "menu_deck_linchpin_9_1",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_regen_health",
			category = "player"
		}
	}

	-- Crew armour regen from Cohesion stacks.
    self.definitions.team_linchpin_armour_regen_bonus = {
		name_id = "menu_deck_linchpin_9_2",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_armour_regen_bonus",
			category = "player"
		}
	}

	-- Additional crew armour from Cohesion stacks.
    self.definitions.team_linchpin_additional_armour = {
		name_id = "menu_deck_linchpin_9_2",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_additional_armour",
			category = "player"
		}
	}

	-- Crew stamina regeneration speed from Cohesion stacks.
    self.definitions.team_linchpin_stamina_regen_bonus = {
		name_id = "menu_deck_linchpin_9_3",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_stamina_regen_bonus",
			category = "player"
		}
	}

	-- Additional bonus to the movement and reload speed bonuses.
	-- Yeeeeaaaah, kinda weirdly done.
    self.definitions.team_linchpin_additional_move_reload_bonus = {
		name_id = "menu_deck_linchpin_9_3",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_additional_move_reload_bonus",
			category = "player"
		}
	}

	-- Cohesion stack bonuses to everyone nearby whenever a crew member kills enough enemies.
    self.definitions.team_linchpin_crew_kill_stack_reward = {
		name_id = "menu_deck_linchpin_9_4",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_crew_kill_stack_reward",
			category = "player"
		}
	}
end)
