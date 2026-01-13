if not restoration then
	return
end

HUDCohesionDisplay = HUDCohesionDisplay or class()
function HUDCohesionDisplay:init(hud)
	self._hud_panel = hud.panel

    self._cohesion_panel = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel:panel({
		name = "cohesion_display_init",
		layer = 0,
		visible = true,
		valign = "center",
        w = 32,
        h = 32,
		y = 0
	})
    local skill_icon = self._cohesion_panel:bitmap({
		texture = "guis/textures/pd2/skilltree/info_long_dis_revive", -- TODO Change this
		name = "cohesion_icon",
		layer = 2,
		render_template = "VertexColorTexturedRadial",
		color = Color(0.8, 1, 1, 1),
		h = 32,
		w = 32,
		x = 0,
		y = 0
	})
	local background = self._cohesion_panel:bitmap({
		texture = 'guis/textures/restoration/hud_radialbg',
		name = "cohesion_back",
		layer = 1,
		render_template = "VertexColorTexturedRadial",
		color = Color(0.75, 1, 1, 1),
		w = 32,
		h = 32,
		x = 0,
		y = 0
	})
	local stacks = self._cohesion_panel:text({
		alpha = 1,
		name = "cohesion_stacks",
		text = "",
		x = 0 + (0.67 * 32), --Move text to corner of icon.
		y = 0 - (0.1 * 32),
		layer = 3,
		color = Color.white,
		font = tweak_data.menu.default_font,
		font_size = 32 * 0.6
	})

    self._cohesion_panel:set_right(self._hud_panel:w() - 40)
	self._cohesion_panel:set_center_y(self._hud_panel:center_y())
	self._cohesion_panel:set_alpha(0) -- Only make it appear if someone can give Cohesion stacks.

    self.cohesion_count = 0
	self._start_time = 0
end

function HUDCohesionDisplay:hide()
    self._cohesion_panel:set_alpha(0)
end

function HUDCohesionDisplay:unhide()
    self._cohesion_panel:set_alpha(1)
end

function HUDCohesionDisplay:set_cohesion_value(new_amount)
    self:unhide()
	--self._cohesion_panel:animate(callback(self, self, "change"), self.cohesion_count, new_amount)

    self.cohesion_count = new_amount
    local filled = math.floor(self.cohesion_count / (tweak_data.upgrades.linchpin_per_crew_member or 1))
    local partial = self.cohesion_count - filled * (tweak_data.upgrades.linchpin_per_crew_member or 1)
    local ratio = partial / (tweak_data.upgrades.linchpin_per_crew_member or 1)

    self._cohesion_panel:child("cohesion_stacks"):set_text(tostring(filled))
    self._cohesion_panel:child("cohesion_back"):set_color(Color(0.75, ratio, 1, 1))
end


function HUDCohesionDisplay:change(input_panel, starting_amount, target_amount)
	local per_cycle = tweak_data.upgrades.linchpin_per_crew_member or 8
	local duration = tweak_data.upgrades.linchpin_change_t or 1
	self._start_time = Application:time()
	while true do
		local cohesion_amount_ratio = math.min((Application:time() - self._start_time) / duration,1)
		local current_amount = starting_amount + (target_amount - starting_amount) * cohesion_amount_ratio
		local filled = math.floor(current_amount / per_cycle)
		local partial_ratio = (current_amount - filled * per_cycle) / per_cycle

		input_panel:child("cohesion_back"):set_color(Color(0.75, partial_ratio, 1, 1))
		input_panel:child("cohesion_stacks"):set_text(tostring(filled))
		if cohesion_amount_ratio == 1 then
			break
		end
		coroutine.yield()
	end
	self._start_time = nil
end