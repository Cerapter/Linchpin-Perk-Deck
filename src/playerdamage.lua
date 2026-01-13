if not restoration then
	return
end

-- Copied over from Resmod, but added Linchpin's healing potency change too.
Hooks:OverrideFunction(PlayerDamage,"restore_health", function(self, health_restored, is_static, chk_health_ratio)
	if chk_health_ratio and managers.player:is_damage_health_ratio_active(self:health_ratio()) and not self:is_downed() then
		return false
	end

    local linchpin_healing_potency = 1
    if managers.player:has_team_category_upgrade("player", "linchpin_crew_heal_potency") then
		local cohesion_stacks = managers.player:get_cohesion_stacks_as_treated()
		local potency_amount = managers.player:get_cohesion_step(cohesion_stacks)

		linchpin_healing_potency = 1 + managers.player:team_upgrade_value("player", "linchpin_crew_heal_potency", 0) * potency_amount

		managers.player:set_damage_absorption("hostage_absorption", absorption)
	end

	if is_static then
		return self:change_health(health_restored * self._healing_reduction * linchpin_healing_potency)
	else
		local max_health = self:_max_health_orig() --Just use the original function.

		return self:change_health(max_health * health_restored * self._healing_reduction * linchpin_healing_potency)
	end
end)

Hooks:PostHook(PlayerDamage, "update" , "linchpin_dodge_updates" , function(self, unit, t, dt)
	local cohesion_stacks = managers.player:get_cohesion_stacks_as_treated()
	local cohesion_steps = managers.player:get_cohesion_step(cohesion_stacks) -- Most things use the steps (i.e., they say "for every X stacks") so yeah, might as well determine this ahead of time.

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

	self._eyes_open_t = self._eyes_open_t or t + (tweak_data.upgrades.crew_dodge_metre_fill_t or 1)

	if self._eyes_open_t <= t then
		self._eyes_open_t = t + (tweak_data.upgrades.crew_dodge_metre_fill_t or 1)
		self:fill_dodge_meter(self._dodge_points * dt * managers.player:team_upgrade_value("player", "linchpin_crew_dodge_metre_fill", 0) * cohesion_steps) 
	end
end)

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
			to_tend = 99
		}, {}, false)
	end
end)

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
			to_tend = 99
		}, {}, false)
	end
end)