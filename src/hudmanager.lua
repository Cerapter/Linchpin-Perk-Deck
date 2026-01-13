if not restoration then
	return
end

-- Add the Cohesion panel to the HUD.
Hooks:PostHook(HUDManager, "_setup_player_info_hud_pd2" , "linchpin_cohesion_hud" , function(self, ...)
    self._cohesion_display = HUDCohesionDisplay:new((managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)))
end)

function HUDManager:set_cohesion_value(new_amount)
	if self._cohesion_display then
		self._cohesion_display:set_cohesion_value(new_amount)
	end
end

function HUDManager:unhide_cohesion_display()
	if self._cohesion_display then
		self._cohesion_display:unhide()
	end
end

function HUDManager:hide_cohesion_display()
	if self._cohesion_display then
		self._cohesion_display:hide()
	end
end