if not restoration then
    return
end

if not tweak_data then 
	return 
end

-- Fill out the descriptions based on these values above so I don't have to go back to constantly editing them.

-- Gonna need to find the key for the Linchpin deck. It *should* be the last one, but I don't wanna leave it up to chance.
-- So I'll just look for its first description, and if I find it, that's it.
local desc_key = nil

for i =  #tweak_data.skilltree.specializations, 1, -1 do
    if tweak_data.skilltree.specializations[i].name_id and tweak_data.skilltree.specializations[i].name_id == "menu_deck_linchpin_title" and desc_key == nil then
        desc_key = i
    end
end

local twu = tweak_data.upgrades

if desc_key ~= nil then
    twu.specialization_descs[desc_key] = twu.specialization_descs[desc_key] or {}
    twu.multi_choice_specialization_descs[desc_key] = {
        [1] = {},
        [3] = {},
        [5] = {},
        [7] = {},
        [9] = {}
    }

    -- Tight Formation
    twu.specialization_descs[desc_key][1] = {
        perk_value_1 = tostring(twu.linchpin_per_crew_member), -- Tendency per crew member
        perk_value_2 = tostring(twu.linchpin_proximity / 100).." metres", -- Proximity requirement
        perk_value_3 = tostring(twu.linchpin_gain), -- Cohesion gained nearby
        perk_value_4 = tostring(twu.linchpin_loss), -- Cohesion lost from lack of proximity
        perk_value_5 = tostring(twu.linchpin_damage_weighs_for_stack_loss.armour), -- Cohesion lost from taking damage
        perk_value_6 = tostring(twu.values.team.player.linchpin_damage_to_lose[1]), -- Damage to be taken to lose stacks
        perk_value_7 = tostring(twu.values.player.passive_dodge_chance[1] * 100) -- Passive dodge increase
    }

    -- In Sync
    twu.specialization_descs[desc_key][3] = {
        perk_value_1 = tostring(twu.values.player.linchpin_treat_as_more_cohesion[1]) -- Treat as having this many extra Cohesion stacks
    }

    -- Speed Is Key
    twu.specialization_descs[desc_key][5] = {
		perk_value_1 = tostring(twu.values.player.corpse_dispose_speed_multiplier[1] * 100).."%" -- Faster interaction with civs + bagging corpses
    }

    -- Every Angle Covered
    twu.specialization_descs[desc_key][7] = {
        perk_value_1 = tostring((twu.values.player.passive_dodge_chance[2] - twu.values.player.passive_dodge_chance[1]) * 100) -- Passive dodge increase
    }

    -- Ironclad Formation
    twu.specialization_descs[desc_key][9] = {
        perk_value_1 = tostring(twu.values.team.player.linchpin_increase_default_tendency[1]), -- Additional default tendency
        perk_value_2 = tostring(twu.linchpin_per_crew_member) -- Tendency per crew member
    }

    -- Stick Together
    twu.multi_choice_specialization_descs[desc_key][1][1] = {
        perk_value_1 = tostring(twu.values.team.player.linchpin_crew_heal_potency[1] * 100)..'%' -- Increased healing potency
    }

    -- Conserve Ammo
    twu.multi_choice_specialization_descs[desc_key][1][2] = {
        perk_value_1 = tostring(twu.values.team.player.linchpin_ammo_pickup_boost[1] * 100)..'%' -- Ammo pickup boost
    }

    -- Lead By Example
    twu.multi_choice_specialization_descs[desc_key][3][1] = {
        perk_value_1 = tostring(math.abs((twu.linchpin_gain + twu.values.player.linchpin_stack_change_adjustments[1].gain) / twu.linchpin_gain - 1) * 100)..'%', -- Cohesion stack change from proximity
        perk_value_2 = tostring(math.abs((twu.linchpin_loss + twu.values.player.linchpin_stack_change_adjustments[1].loss) / twu.linchpin_loss - 1) * 100)..'%' -- Cohesion stack change from lack proximity
    }

    -- Hold The Line
    twu.multi_choice_specialization_descs[desc_key][3][2] = {
        perk_value_1 = tostring(math.abs((twu.linchpin_gain + twu.values.player.linchpin_stack_change_adjustments[2].gain) / twu.linchpin_gain - 1) * 100)..'%', -- Cohesion stack change from proximity
        perk_value_2 = tostring(math.abs((twu.linchpin_loss + twu.values.player.linchpin_stack_change_adjustments[2].loss) / twu.linchpin_loss - 1) * 100)..'%' -- Cohesion stack change from lack proximity
    }

    -- Standard Tactics!
    -- Doesn't need adding stuff.

    -- Keep Moving
    twu.multi_choice_specialization_descs[desc_key][5][1] = {
        perk_value_1 = tostring(twu.values.team.player.linchpin_crew_movespeed_bonus[1] * 100)..'%' -- Movement increase
    }

    -- Shoot and Scoot
    twu.multi_choice_specialization_descs[desc_key][5][2] = {
        perk_value_1 = tostring(twu.values.team.player.linchpin_crew_reload_bonus[1] * 100)..'%' -- Reload increase
    }

    -- Back To It
    twu.multi_choice_specialization_descs[desc_key][7][1] = {
        perk_value_1 = tostring(twu.values.player.linchpin_stacks_on_revive[1]) -- Stacks on revival
    }

    -- Earn Your Keep
    twu.multi_choice_specialization_descs[desc_key][7][2] = {
        perk_value_1 = tostring(twu.values.player.linchpin_personal_kill_stack_reward[1].stacks), -- Stacks on kill
        perk_value_2 = tostring(twu.values.player.linchpin_personal_kill_stack_reward[1].enemies) -- Per kills
    }

    -- Dig In Your Heels
    twu.multi_choice_specialization_descs[desc_key][9][1] = {
        perk_value_1 = tostring(twu.values.team.player.linchpin_damage_to_lose[2]), -- Increased damage to lose stacks
        perk_value_2 = tostring(twu.values.team.player.linchpin_regen_health[1].amount * 10), -- HP regained
        perk_value_3 = tostring(twu.values.team.player.linchpin_regen_health[1].seconds) -- this often
    }

    -- Stand Firm
    twu.multi_choice_specialization_descs[desc_key][9][2] = {
        perk_value_1 = tostring(twu.values.team.player.linchpin_armour_regen_bonus[1] * 100)..'%', -- Armour regen
        perk_value_2 = tostring(twu.values.team.player.linchpin_additional_armour[1] * 10) -- Additional armour
    }

    -- Keep Pressing On
    twu.multi_choice_specialization_descs[desc_key][9][3] = {
        perk_value_1 = tostring(twu.values.team.player.linchpin_stamina_regen_bonus[1] * 100)..'%', -- Stamina regen
        perk_value_2 = tostring(math.abs((twu.values.team.player.linchpin_additional_move_reload_bonus[1] + twu.values.team.player.linchpin_crew_movespeed_bonus[1])/ twu.values.team.player.linchpin_crew_movespeed_bonus[1] - 1) * 100)..'%' -- Movement / reload speed increase (this assumes they are the same, and this is specifically for movement)
    }

    -- Press The Advantage
    twu.multi_choice_specialization_descs[desc_key][9][4] = {
        perk_value_1 = tostring(twu.values.team.player.linchpin_crew_kill_stack_reward[1].stacks), -- Stacks on kill
        perk_value_2 = tostring(twu.values.team.player.linchpin_crew_kill_stack_reward[1].enemies) -- Per kills
    }
end