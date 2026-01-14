if not restoration then
    return
end

--- ## FOR DEBUGGING PURPOSES ONLY, SET TO 1 FOR RELEASE
--- Simply multiplies most effect numbers by this number, for easier visibility on changes.
--- (Primarily for testing stack numbers between clients because I apparently suck at networking.)
LINCHPIN_DEBUGNUMBERS = 4

Hooks:PostHook(UpgradesTweakData, "_init_pd2_values", "linchpin_init", function(self)
    self.linchpin_proximity = 1800 -- Centimetres proximity required to gain Cohesion stacks.
    self.linchpin_per_crew_member = 8 -- The amount of Cohesion stacks per crew, used for tendency determination and "for every X" number.
    self.linchpin_change_t = 1 -- In seconds, how frequently do Cohesion stacks change.
    self.linchpin_hard_limit = 4 -- The maximum amount of players we'll ever consider for Cohesion counting. In case of Big Lobby mods, we shouldn't escalate to ridiculous amounts.
	-- Represents 
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
		16
	}

    -- Healing potency increase from Stick Together, per crew member.
    self.values.team.player.linchpin_crew_heal_potency = {
        0.075 * LINCHPIN_DEBUGNUMBERS
    }

    -- Dodge metre increase per second from Eyes Open, percentage value.
    self.values.team.player.linchpin_crew_dodge_metre_fill = {
        0.025 * LINCHPIN_DEBUGNUMBERS
    }
    self.crew_dodge_metre_fill_t = 1 -- In seconds, how frequently should the dodge meter be given.

    -- Percentage value, the dodge points increases for the team per Cohesion.
    self.values.team.player.linchpin_crew_dodge_points = {
        0.0125 * LINCHPIN_DEBUGNUMBERS,
        0.025 * LINCHPIN_DEBUGNUMBERS
    }

    -- Adds a fixed amount of Cohesion stacks to any effects that want Cohesion values specifically.
    self.values.player.linchpin_treat_as_more_cohesion = {
        8
    }

    -- Percentage value, how much the gain ratio should be changed.
    self.values.player.linchpin_gain_change = {
        2
    }

    -- Percentage value, how much the loss ratio should be changed.
    self.values.player.linchpin_loss_change = {
        0.5
    }

    -- Percentage value, the movespeed increases for the team per Cohesion.
    self.values.team.player.linchpin_crew_movespeed_bonus = {
        0.05 * LINCHPIN_DEBUGNUMBERS
    }

    -- Percentage value, the movespeed increases for the team per Cohesion.
    self.values.team.player.linchpin_crew_reload_bonus = {
        0.05 * LINCHPIN_DEBUGNUMBERS
    }

    -- How many Cohesion stacks should be gained on revive with Back To It!.
    self.values.player.linchpin_stacks_on_revive = {
        48
    }

    -- How many Cohesion stacks should everyone nearby gain when you kill X amount of enemies.
    self.values.player.linchpin_personal_kill_stack_reward = {
        {
			enemies = 1,
			stacks = 1
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
		name_id = "menu_deck_linchpin_3_1",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "linchpin_treat_as_more_cohesion",
			category = "player"
		}
	}

    -- Doubles gain, halves loss
    self.definitions.player_linchpin_gain_speed_up = {
		name_id = "menu_deck_linchpin_3_2",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "linchpin_gain_change",
			category = "player"
		}
	}
    self.definitions.player_linchpin_loss_speed_down = {
		name_id = "menu_deck_linchpin_3_2",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "linchpin_loss_change",
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

    -- Crew healing from Cohesion stacks.
    self.definitions.team_linchpin_crew_heal = {
		name_id = "menu_deck_linchpin_1_1",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_crew_heal_potency",
			category = "player"
		}
	}

    -- Crew dodge metre autofill from Cohesion stacks.
    self.definitions.team_linchpin_crew_dodge_metre_fill = {
		name_id = "menu_deck_linchpin_1_2",
		category = "team",
		upgrade = {
			value = 1,
			upgrade = "linchpin_crew_dodge_metre_fill",
			category = "player"
		}
	}

    -- Crew dodge point gain.
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
end)