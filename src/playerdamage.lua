if not restoration then
	return
end

--- Copied over from Resmod, but added Linchpin's healing potency change too.
---@param health_restored any
---@param is_static any
---@param chk_health_ratio any
---@return boolean
function PlayerDamage:restore_health(health_restored, is_static, chk_health_ratio)
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
end

Hooks:PostHook(PlayerDamage, "update" , "linchpin_dodge_metre_fill" , function(self, unit, t, dt)
	-- Eyes Open!
	self._eyes_open_t = self._eyes_open_t or t + (tweak_data.upgrades.crew_dodge_metre_fill_t or 1)

	if self._eyes_open_t <= t then
		local cohesion_stacks = managers.player:get_cohesion_stacks_as_treated()
		local dodge_chance_amount = managers.player:get_cohesion_step(cohesion_stacks)

		self._eyes_open_t = t + (tweak_data.upgrades.crew_dodge_metre_fill_t or 1)

		self:fill_dodge_meter(self._dodge_points * dt * managers.player:team_upgrade_value("player", "linchpin_crew_dodge_metre_fill", 0) * dodge_chance_amount) 
	end
end)