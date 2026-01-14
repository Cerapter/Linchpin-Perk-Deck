if not restoration then
	return
end

Hooks:PostHook(PlayerMovement, "add_stamina" , "linchpin_add_stamina" , function(self, value)
	if managers.player:has_team_category_upgrade("player", "linchpin_stamina_regen_bonus") then
		local cohesion_stacks = managers.player:get_cohesion_stacks_as_treated()
		local cohesion_steps = managers.player:get_cohesion_step(cohesion_stacks)
		local extra_regen_timer_tick = managers.player:team_upgrade_value("player", "linchpin_stamina_regen_bonus", 0) * cohesion_steps

        self:_change_stamina(math.abs(value) * extra_regen_timer_tick)
    end
end)