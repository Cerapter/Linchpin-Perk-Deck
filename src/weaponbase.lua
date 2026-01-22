if not restoration then
	return
end

-- Stolen from Offyerrocker's implementation of the Mercenary Perk Deck, very clever solution for handling both!
-- (Though I'm actually not sure if I need this for Resmod, oh well.)
local weapon_base
local required_script = string.lower(RequiredScript)
if required_script == "lib/units/weapons/raycastweaponbase" then
	weapon_base = RaycastWeaponBase
elseif required_script == "lib/units/weapons/newraycastweaponbase" then
	weapon_base = NewRaycastWeaponBase
end

Hooks:PostHook(weapon_base,"reload_speed_multiplier","linchpin_weaponbase_reloadmul_" .. tostring(required_script),function(self,...)
	local multiplier = Hooks:GetReturn()

	if managers.player:has_team_category_upgrade("player", "linchpin_crew_reload_bonus") then
		local potency_amount = managers.player:get_cohesion_stacks_as_treated()
		local bonus = managers.player:team_upgrade_value("player", "linchpin_crew_reload_bonus", 0) + managers.player:team_upgrade_value("player", "linchpin_additional_move_reload_bonus", 0)

		multiplier = multiplier + bonus * potency_amount
	end

	return multiplier
end)