if not restoration then
	return
end

-- Add the Cohesion panel to the HUD.
Hooks:PostHook(HUDManager, "_setup_player_info_hud_pd2" , "linchpin_cohesion_hud" , function(self, ...)
    self._cohesion_display = HUDCohesionDisplay:new((managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)))
end)

function HUDManager:set_cohesion_value(new_amount, extra)
	local cohesion_display_on_right = linchpin_perk_deck.Options:GetValue("Info_cohesion_display") and linchpin_perk_deck.Options:GetValue("Info_cohesion_display") == 1
	local cohesion_display_in_buff_tracker = linchpin_perk_deck.Options:GetValue("Info_cohesion_display") and linchpin_perk_deck.Options:GetValue("Info_cohesion_display") == 2
	if cohesion_display_on_right and self._cohesion_display then
		self._cohesion_display:set_cohesion_value(new_amount, extra)
		self:remove_skill("cohesion_display")
	elseif cohesion_display_in_buff_tracker then
		self._cohesion_count = self._cohesion_count or 0
		self:hide_cohesion_display()
		self:linchpin_add_skill("cohesion_display")

		-- I don't wanna fiddle too much with HUDSkills, so the Buff Tracker version adds together both the amount and the "treat as" value.
		self._skill_list._skill_panel:animate(callback(self, self, "animate_skill_cohesion_stack"), self._cohesion_count, new_amount + extra)
		self._cohesion_count = new_amount + extra

		--self:linchpin_set_stacks("cohesion_display", 99) -- TODO
	else
		self:remove_skill("cohesion_display")
		self:hide_cohesion_display()
	end
end

function HUDManager:hide_cohesion_display()
	if self._cohesion_display then
		self._cohesion_display:hide()
	end
end

--- As ResMod's add_skill() looks for ResMod's options to see whether it should actually do it, I have to kinda reimplement this to check for my own options.
function HUDManager:linchpin_add_skill(name)
	if restoration.Options:GetValue("HUD/INFOHUD/Info_Hud") and linchpin_perk_deck.Options:GetValue("Info_" .. name) then
		self._skill_list:add_skill(name)
	end
end

--- As with HUDManager:linchpin_add_skill().
function HUDManager:linchpin_set_stacks(name, stacks)
	if restoration.Options:GetValue("HUD/INFOHUD/Info_Hud") and linchpin_perk_deck.Options:GetValue("Info_" .. name) then
		self._skill_list:set_stacks(name, stacks)
	end
end

function HUDManager:animate_skill_cohesion_stack(skill_panel, starting_amount, target_amount)
	local per_cycle = tweak_data.upgrades.linchpin_per_crew_member or 8
	local duration = tweak_data.upgrades.linchpin_change_t or 1
	self._skill_list._start_times["cohesion_display"] = Application:time()
	repeat
		local cohesion_amount_ratio = math.min((Application:time() - self._skill_list._start_times["cohesion_display"]) / duration,1)
		local current_amount = starting_amount + (target_amount - starting_amount) * cohesion_amount_ratio
		local filled = math.floor(current_amount / per_cycle)
		local partial_ratio = (current_amount - filled * per_cycle) / per_cycle

		skill_panel:child("cohesion_display_back"):set_color(Color(0.75, partial_ratio, 1, 1))
		skill_panel:child("cohesion_display_stacks"):set_text(tostring(filled))
		coroutine.yield()
	until cohesion_amount_ratio == 1
	self._skill_list._start_times["cohesion_display"] = nil
end