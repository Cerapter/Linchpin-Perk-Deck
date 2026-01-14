if not restoration then
    return
end

--- Shamelessly stolen from Offyerrocker's Liberator perk deck implementation.
---
--- If you want the perk deck to be free, change this to "false", without quotation marks.
local paid = true

--- The default costs for perk decks.
local costs = {
    [1] = 200,
    [2] = 300,
    [3] = 400,
    [4] = 600,
    [5] = 1000,
    [6] = 1600,
    [7] = 2400,
    [8] = 3200,
    [9] = 4000
}

--- Depending on the value of `paid`, returns a perk deck card's cost, or 0.
---@param n integer The position of the card in the perk deck, ranging from 1 to 9.
---@return integer cost The cost of the card. Can be 0 if `paid` is set to `false`.
local function cost(n)
    return paid and costs[n] or 0
end

Hooks:PostHook(SkillTreeTweakData, "init", "linchpin_init_skill_tree", function(self, data)
    -- *Theoretically*, the default perkdecks should have the Resmod modified even-numbered cards. Soooo what if we just yoinked Crew Chief's, then I wouldn't have to fiddle with shit?
    local shared_cards = 
    {
        clone(self.specializations[1][2]),
        clone(self.specializations[1][4]),
        clone(self.specializations[1][6]),
        clone(self.specializations[1][8])
    };

    -- The costs should agree, but it'd be weird if you turned off the perk deck costing, yet the even-numbered cards would still cost you perk points.
    for i = 1, 4, 1 do
        shared_cards[i].cost = cost(i * 2)
    end

    local perk_deck_data = {
        name_id = "menu_deck_linchpin_title",
        desc_id = "menu_deck_linchpin_desc",
        category = "supportive",
        {
            upgrades = {
                "player_linchpin_aura",
                "team_linchpin_damage_to_lose_1",
                "player_passive_dodge_chance_1"
            },
            cost = cost(1),
            icon_xy = { 4, 2 },
            name_id = "menu_deck_linchpin_1",
            desc_id = "menu_deck_linchpin_1_desc",
            short_id = "menu_deck_linchpin_1_short",
            multi_choice = {
                {
                    name_id = "menu_deck_linchpin_1_1",
                    desc_id = "menu_deck_linchpin_1_1_desc",
                    short_id = "menu_deck_linchpin_1_1_desc",
                    icon_atlas = "icons_atlas",
                    upgrades = {
                        "team_linchpin_crew_heal_potency"
                    },
                    icon_xy = {
                        0,
                        5
                    }
                },
                {
                    name_id = "menu_deck_linchpin_1_2",
                    desc_id = "menu_deck_linchpin_1_2_desc",
                    short_id = "menu_deck_linchpin_1_2_desc",
                    icon_atlas = "icons_atlas",
                    upgrades = {
                        "team_linchpin_crew_dodge_metre_fill"
                    },
                    icon_xy = {
                        0,
                        2
                    }
                }
            }
        },
        shared_cards[1],
        {
            upgrades = {
                "team_linchpin_crew_dodge_points_1"
            },
            cost = cost(3),
            icon_xy = { 3, 4 },
            name_id = "menu_deck_linchpin_3",
            desc_id = "menu_deck_linchpin_3_desc",
            multi_choice = {
                {
                    name_id = "menu_deck_linchpin_3_1",
                    desc_id = "menu_deck_linchpin_3_1_desc",
                    short_id = "menu_deck_linchpin_3_1_desc",
                    icon_atlas = "icons_atlas",
                    upgrades = {
                        "player_linchpin_treat_as_more_cohesion"
                    },
                    icon_xy = {
                        2,
                        7
                    }
                },
                {
                    name_id = "menu_deck_linchpin_3_2",
                    desc_id = "menu_deck_linchpin_3_2_desc",
                    short_id = "menu_deck_linchpin_3_2_desc",
                    icon_atlas = "icons_atlas",
                    upgrades = {
                        "player_linchpin_gain_speed_up",
                        "player_linchpin_loss_speed_down"
                    },
                    icon_xy = {
                        4,
                        2
                    }
                }
            }
        },
        shared_cards[2],
        {
            upgrades = {
                "player_passive_dodge_chance_2"
            },
            cost = cost(5),
            icon_xy = { 3, 0 },
            name_id = "menu_deck_linchpin_5",
            desc_id = "menu_deck_linchpin_5_desc",
            multi_choice = {
                {
                    name_id = "menu_deck_linchpin_5_1",
                    desc_id = "menu_deck_linchpin_5_1_desc",
                    short_id = "menu_deck_linchpin_5_1_desc",
                    icon_atlas = "icons_atlas",
                    upgrades = {
                        "team_linchpin_crew_movespeed_bonus"
                    },
                    icon_xy = {
                        1,
                        2
                    }
                },
                {
                    name_id = "menu_deck_linchpin_5_2",
                    desc_id = "menu_deck_linchpin_5_2_desc",
                    short_id = "menu_deck_linchpin_5_2_desc",
                    icon_atlas = "icons_atlas",
                    upgrades = {
                        "team_linchpin_crew_reload_bonus"
                    },
                    icon_xy = {
                        7,
                        0
                    }
                }
            }
        },
        shared_cards[3],
        {
            upgrades = {
                "team_linchpin_crew_dodge_points_2"
            },
            cost = cost(7),
            icon_xy = { 4, 4 },
            name_id = "menu_deck_linchpin_7",
            desc_id = "menu_deck_linchpin_7_desc",
            multi_choice = {
                {
                    name_id = "menu_deck_linchpin_7_1",
                    desc_id = "menu_deck_linchpin_7_1_desc",
                    short_id = "menu_deck_linchpin_7_1_desc",
                    icon_atlas = "icons_atlas",
                    upgrades = {
                        "player_linchpin_stacks_on_revive"
                    },
                    icon_xy = {
                        1,
                        5
                    }
                },
                {
                    name_id = "menu_deck_linchpin_7_2",
                    desc_id = "menu_deck_linchpin_7_2_desc",
                    short_id = "menu_deck_linchpin_7_2_short",
                    icon_atlas = "icons_atlas",
                    upgrades = {
                        "player_linchpin_personal_kill_stack_reward"
                    },
                    icon_xy = {
                        3,
                        7
                    }
                }
            }
        },
        shared_cards[4],
        {
            upgrades = {
                "player_passive_loot_drop_multiplier_1",
                "team_linchpin_increase_default_tendency"
            },
            cost = cost(9),
            icon_xy = { 6, 4 },
            name_id = "menu_deck_linchpin_9",
            desc_id = "menu_deck_linchpin_9_desc",
            multi_choice = {
                {
                    name_id = "menu_deck_linchpin_9_1",
                    desc_id = "menu_deck_linchpin_9_1_desc",
                    short_id = "menu_deck_linchpin_9_1_desc",
                    icon_atlas = "icons_atlas",
                    upgrades = {
                        "team_linchpin_damage_to_lose_2",
                        "team_linchpin_regen_health"
                    },
                    icon_xy = {
                        4,
                        0
                    }
                },
                {
                    name_id = "menu_deck_linchpin_9_2",
                    desc_id = "menu_deck_linchpin_9_2_desc",
                    short_id = "menu_deck_linchpin_9_2_desc",
                    icon_atlas = "icons_atlas",
                    upgrades = {
                        "team_linchpin_crew_dodge_metre_fill_2",
                        "team_linchpin_armour_regen_bonus"
                    },
                    icon_xy = {
                        0,
                        2
                    }
                },
                {
                    name_id = "menu_deck_linchpin_9_3",
                    desc_id = "menu_deck_linchpin_9_3_desc",
                    short_id = "menu_deck_linchpin_9_3_desc",
                    icon_atlas = "icons_atlas",
                    upgrades = {
                        "team_linchpin_stamina_regen_bonus",
                        "team_linchpin_additional_move_reload_bonus"
                    },
                    icon_xy = {
                        2,
                        0
                    }
                },
                {
                    name_id = "menu_deck_linchpin_9_4",
                    desc_id = "menu_deck_linchpin_9_4_desc",
                    short_id = "menu_deck_linchpin_9_4_short",
                    icon_atlas = "icons_atlas",
                    upgrades = {
                        "team_linchpin_crew_kill_stack_reward"
                    },
                    icon_xy = {
                        3,
                        7
                    }
                }
            }
        }
    }
    
	table.insert(self.specializations, perk_deck_data)
end)
