if not restoration then
	return
end

Hooks:PostHook(PlayerDamage, "_init_standard_listeners" , "linchpin_playerdamage_init_standard_listeners" , function(self, unit)
	if managers.player:has_category_upgrade("player", "linchpin_stacks_on_revive") then
		self._listener_holder:add("_linchpin_revive_with_stacks", {
			"on_revive"
		}, callback(self, self, "_on_linchpin_revive_with_stacks"))
	end
end)

-- Copied over from Resmod, but added Linchpin's healing potency change too.
Hooks:OverrideFunction(PlayerDamage,"restore_health", function(self, health_restored, is_static, chk_health_ratio)
	if chk_health_ratio and managers.player:is_damage_health_ratio_active(self:health_ratio()) and not self:is_downed() then
		return false
	end

    local linchpin_healing_potency = 1
    if managers.player:has_team_category_upgrade("player", "linchpin_crew_heal_potency") then
		local potency_amount = managers.player:get_cohesion_stacks_as_treated()

		linchpin_healing_potency = 1 + managers.player:team_upgrade_value("player", "linchpin_crew_heal_potency", 0) * potency_amount
	end

	if is_static then
		return self:change_health(health_restored * self._healing_reduction * linchpin_healing_potency)
	else
		local max_health = self:_max_health_orig() --Just use the original function.

		return self:change_health(max_health * health_restored * self._healing_reduction * linchpin_healing_potency)
	end
end)

Hooks:PostHook(PlayerDamage, "update" , "linchpin_playerdamage_update" , function(self, _, t, dt)
	local cohesion_steps = managers.player:get_cohesion_stacks_as_treated()

	-- Anything that adds dodge points based on Cohesion.

	self._cached_linchpin_dodge_bonus = self._cached_linchpin_dodge_bonus or 0

	if self._cached_linchpin_dodge_bonus ~= cohesion_steps then
		-- This defeats the purpose of caching a touch. Too bad!
		self:set_dodge_points()
		self._cached_linchpin_dodge_bonus = cohesion_steps

		-- There is a chance our dodge points have fallen below zero due to Cohesion stack loss.
		if self:get_dodge_points() <= 0 and managers.hud and managers.hud._dodge_meter then
			managers.hud._dodge_meter._dodge_panel:set_alpha(0)
		end
	end

	-- Eyes Open!
	-- **Currently unused,** probably not gonna be used again? But still, keeping it here just in case.
	-- self._eyes_open_t = self._eyes_open_t or t + (tweak_data.upgrades.crew_dodge_metre_fill_t or 1)
	-- if self._eyes_open_t <= t then
	-- 	self._eyes_open_t = t + (tweak_data.upgrades.crew_dodge_metre_fill_t or 1)
	-- 	local linchpin_dodge_meter_bonus = managers.player:team_upgrade_value("player", "linchpin_crew_dodge_metre_fill", 0) + managers.player:team_upgrade_value("player", "linchpin_crew_dodge_metre_fill_2", 0)
	-- 	self:fill_dodge_meter(self._dodge_points * dt * linchpin_dodge_meter_bonus)
	-- end

	-- Dig In Your Heels! healing.
	-- Yes, I know heal-over-time has its own function, but again, seems risky to overwrite.

	if managers.player:has_team_category_upgrade("player", "linchpin_regen_health") then
		self._linchpin_regen_t = self._linchpin_regen_t or t + (managers.player:team_upgrade_value("player", "linchpin_regen_health").seconds or 5)
		if self._linchpin_regen_t <= t then
			self._linchpin_regen_t = t + (managers.player:team_upgrade_value("player", "linchpin_regen_health").seconds or 5)
			local heal =(managers.player:team_upgrade_value("player", "linchpin_regen_health").amount or 0) * cohesion_steps
			self:restore_health(heal, true)
		end
	end
end)

-- This is probably not the best way to handle this. I could have done the "orig_X" thing I did with armour regen, but I wanted to do function replacements that large as little as possible.
Hooks:PostHook(PlayerDamage, "change_armor" , "linchpin_change_armor" , function(self, change)
	if change >= 0 or not managers.player:has_team_category_upgrade("player", "linchpin_damage_to_lose") then
		return
	end

	self._linchpin_damage_taken = self._linchpin_damage_taken or 0
	local damage_bound = managers.player:team_upgrade_value("player", "linchpin_damage_to_lose", 10000)
	local cohesion_loss = 0

	self._linchpin_damage_taken = self._linchpin_damage_taken - change * (tweak_data.upgrades.linchpin_damage_weighs_for_stack_loss.armour or 1) * 10

	while self._linchpin_damage_taken > damage_bound do
		cohesion_loss = cohesion_loss + 1
		self._linchpin_damage_taken = self._linchpin_damage_taken - damage_bound
	end

	if cohesion_loss > 0 then
		local cohesion = managers.player:get_synced_cohesion_stacks(managers.network:session():local_peer():id())
		managers.player:update_cohesion_stacks_for_peers({
			amount = math.max(0,(cohesion.amount or cohesion_loss) - cohesion_loss), 
			to_tend = nil
		}, {}, false)
	end
end)

-- See my change_armor comments.
Hooks:PostHook(PlayerDamage, "change_health" , "linchpin_change_health" , function(self, change)
	if change >= 0 or not managers.player:has_team_category_upgrade("player", "linchpin_damage_to_lose") then
		return
	end

	self._linchpin_damage_taken = self._linchpin_damage_taken or 0
	local damage_bound = managers.player:team_upgrade_value("player", "linchpin_damage_to_lose", 10000)
	local cohesion_loss = 0

	self._linchpin_damage_taken = self._linchpin_damage_taken - change * (tweak_data.upgrades.linchpin_damage_weighs_for_stack_loss.health or 2) * 10

	while self._linchpin_damage_taken > damage_bound do
		cohesion_loss = cohesion_loss + 1
		self._linchpin_damage_taken = self._linchpin_damage_taken - damage_bound
	end

	if cohesion_loss > 0 then
		local cohesion = managers.player:get_synced_cohesion_stacks(managers.network:session():local_peer():id())

		managers.player:update_cohesion_stacks_for_peers({
			amount = math.max(0,(cohesion.amount or cohesion_loss) - cohesion_loss),
			to_tend = nil
		}, {}, false)
	end
end)

--- For Back To It! stack-gain-on-revive mechanics.
function PlayerDamage:_on_linchpin_revive_with_stacks()
	local stacks = managers.player:upgrade_value("player", "linchpin_stacks_on_revive", 0)
	if stacks and stacks > 0 then
		managers.player:update_cohesion_stacks_for_peers({
			amount = stacks,
			to_tend = nil
		}, {}, false)
	end
end

-- Risky business!
local orig_update_regenerate_timer = PlayerDamage._update_regenerate_timer
function PlayerDamage:_update_regenerate_timer(t, dt)
	orig_update_regenerate_timer(self, t, dt)

	if managers.player:has_team_category_upgrade("player", "linchpin_armour_regen_bonus") then
		local cohesion_steps = managers.player:get_cohesion_stacks_as_treated()
		local extra_regen_timer_tick = managers.player:team_upgrade_value("player", "linchpin_armour_regen_bonus", 0) * cohesion_steps
		local regenerate_timer_tick = dt * (self._regenerate_speed or 1) * extra_regen_timer_tick
		self._regenerate_timer = math.max(self._regenerate_timer - regenerate_timer_tick, 0)

		if self._regenerate_timer <= 0 then
			self:_regenerate_armor()
		end
	end
end