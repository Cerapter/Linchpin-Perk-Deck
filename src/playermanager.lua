--- Represents any Linchpin data needed to be synchronised over the net.
--- @class SyncedLinchpinAuraData
--- @field amount integer The amount of Cohesion stacks the current peer has.
--- @field to_tend integer The amount of Cohesion stacks the current peer suggest other peers tend to.

if not restoration then
	return
end

Hooks:PostHook(PlayerManager, "_setup", "linchpin_playermanager_setup", function(self)
	--- @type table<integer, SyncedLinchpinAuraData>
	Global.player_manager.synced_cohesion_stacks = {}
end)

Hooks:PostHook(PlayerManager, "peer_dropped_out", "linchpin_playermanager_peer_dropped_out", function(self, peer_id)
	Global.player_manager.synced_cohesion_stacks[peer_id] = nil
end)

Hooks:PostHook(PlayerManager, "update", "linchpin_playermanager_update", function(self, t, dt)
	self:update_cohesion_stacks(t, dt)
end)

--- For dodge point determination. Adds a specific amount of dodge based on Cohesion stacks.
--- The "other half" of this implementation is in the PlayerDamage:update() hook in playerdamage.lua.
Hooks:PostHook(PlayerManager, "skill_dodge_chance", "linchpin_playermanager_skill_dodge_chance", function(self, _, _, _, _, _)
	local chance = Hooks:GetReturn()
	local cohesion_stacks = self:get_cohesion_stacks_as_treated() or 0
	chance = chance + self:team_upgrade_value("player", "linchpin_crew_dodge_points", 0) * cohesion_stacks
	return chance
end)


Hooks:PostHook(PlayerManager, "movement_speed_multiplier", "linchpin_playermanager_movement_speed_multiplier", function(self, _, _, _, _)
	local multiplier = Hooks:GetReturn()

    if self:has_team_category_upgrade("player", "linchpin_crew_movespeed_bonus") then
		local potency_amount = self:get_cohesion_stacks_as_treated()
		local bonus = self:team_upgrade_value("player", "linchpin_crew_movespeed_bonus", 0) + self:team_upgrade_value("player", "linchpin_additional_move_reload_bonus", 0)

		multiplier = multiplier + bonus * potency_amount
	end

	return multiplier
end)

Hooks:PostHook(PlayerManager, "body_armor_skill_addend", "linchpin_playermanager_body_armor_skill_addend", function(self,_)
	local addend = Hooks:GetReturn()

    	if self:has_team_category_upgrade("player", "linchpin_additional_armour") then
		local cohesion_steps = self:get_cohesion_stacks_as_treated()
		local extra_armour = self:team_upgrade_value("player", "linchpin_additional_armour", 0) * cohesion_steps

		addend = addend + extra_armour
	end

	return addend
end)

Hooks:PostHook(PlayerManager,"check_skills","linchpin_playermanager_check_skills",function(self)
	-- Conserve Ammo!
	if self:has_team_category_upgrade("player", "linchpin_ammo_pickup_boost") then
		self._message_system:register(Message.OnAmmoPickup, "linchpin_crew_ammo_pickup_boost", callback(self, self, "_linchpin_on_ammo_pickup_boost"))
	else
		self._message_system:unregister(Message.OnAmmoPickup, "linchpin_crew_ammo_pickup_boost")
	end

	-- Earn Your Keep!
	if self:has_category_upgrade("player", "linchpin_personal_kill_stack_reward") then
		self._linchpin_personal_target_kills = self:upgrade_value("player", "linchpin_personal_kill_stack_reward").enemies
		self._linchpin_personal_target_rewards = self:upgrade_value("player", "linchpin_personal_kill_stack_reward").stacks

		self._message_system:register(Message.OnEnemyKilled, "linchpin_personal_give_nearby_crewmembers_stacks", callback(self, self, "_linchpin_on_personal_kill"))
	else
		self._linchpin_personal_target_kills = 0
		self._linchpin_personal_target_rewards = 0
		self._message_system:unregister(Message.OnEnemyKilled, "linchpin_personal_give_nearby_crewmembers_stacks")
	end

	-- Press The Advantage!
	if self:has_team_category_upgrade("player", "linchpin_crew_kill_stack_reward") then
		self._linchpin_crew_target_kills = self:team_upgrade_value("player", "linchpin_crew_kill_stack_reward").enemies
		self._linchpin_crew_target_rewards = self:team_upgrade_value("player", "linchpin_crew_kill_stack_reward").stacks

		self._message_system:register(Message.OnEnemyKilled, "linchpin_crew_give_nearby_crewmembers_stacks", callback(self, self, "_linchpin_on_crew_kill"))
	else
		self._linchpin_crew_target_kills = 0
		self._linchpin_crew_target_rewards = 0
		self._message_system:unregister(Message.OnEnemyKilled, "linchpin_crew_give_nearby_crewmembers_stacks")
	end
end)

--- Packs a table of peer IDs into a comma-separated string.
--- @param peer_set table<integer, boolean> Set of peer IDs. Keys are IDs, values are true.
--- @return string packed_ids Comma-separated list of peer IDs.
function PlayerManager:pack_linchpin_affected_peer_set(peer_set)
    local ids = {}

    for peer_id, _ in pairs(peer_set) do
        ids[#ids + 1] = tostring(peer_id)
    end

    return table.concat(ids, ",")
end

function PlayerManager:_linchpin_on_ammo_pickup_boost(unit)
	local cohesion_stacks = self:get_cohesion_stacks_as_treated() or 0
	local extra_pickup = self:team_upgrade_value("player", "linchpin_ammo_pickup_boost", 0) * cohesion_stacks
	local inventory = unit:inventory()
	
	if inventory then
		local available_selections = {}

		for i, weapon in pairs(inventory:available_selections()) do
			if inventory:is_equipped(i) then
				table.insert(available_selections, 1, weapon)
			else
				table.insert(available_selections, weapon)
			end
		end

		for _, weapon in ipairs(available_selections) do
			weapon.unit:base():add_ammo(extra_pickup)
		end
	end
end

function PlayerManager:_linchpin_on_personal_kill(_, _, _)
	local player_unit = self:player_unit()
	if self._num_kills % self._linchpin_personal_target_kills == 0 and player_unit ~= nil then
		local affected_players = self:get_linchpin_aura_affected(player_unit:position())
		managers.network:session():send_to_peers_synched("sync_add_cohesion_stacks", self._linchpin_personal_target_rewards, false,  self:pack_linchpin_affected_peer_set(affected_players))
		managers.player:add_cohesion_stacks(self._linchpin_personal_target_rewards, false)
	end
end

function PlayerManager:_linchpin_on_crew_kill(_, _, _)
	local player_unit = self:player_unit()
	if self._num_kills % self._linchpin_crew_target_kills == 0 and player_unit ~= nil then
		local affected_players = self:get_linchpin_aura_affected(player_unit:position())
		managers.network:session():send_to_peers_synched("sync_add_cohesion_stacks", self._linchpin_crew_target_rewards, true, self:pack_linchpin_affected_peer_set(affected_players))
		managers.player:add_cohesion_stacks(self._linchpin_crew_target_rewards, true)
	end
end

--- Didn't necessarily have to be a separate function, but hey, Hysteria stacks did it this way, and when in Rome...
--- Plus maybe it helps me not get lost in the sauce!
--- @param peer_id integer Typically a number ranging from 1 to 4, literally just the player ID.
--- @return SyncedLinchpinAuraData stack_data Cohesion stack data for the selected peer.
function PlayerManager:get_synced_cohesion_stacks(peer_id)
	return self._global.synced_cohesion_stacks[peer_id]
end

--- For the purposes of effects, returns the amount of Cohesion stacks the local peer is treated as having (which may be different than how many it has), divided by the amount necessary for a "step" (typically 8).
---@return integer cohesion_stacks The actual Cohesion stacks, plus any "as treated" extras, divided by 8.
function PlayerManager:get_cohesion_stacks_as_treated()
	local local_peer = managers.network:session() and managers.network:session():local_peer()
	if not local_peer then
		return 0
	end

	local extra_amount = self:upgrade_value("player", "linchpin_treat_as_more_cohesion", 0)
	local cohesion_stacks = managers.player:get_synced_cohesion_stacks(local_peer:id())
	local all = (cohesion_stacks and cohesion_stacks.amount or 0) + extra_amount

	return self:get_cohesion_step(all)
end

--- Updates a given peer's Linchpin-related data.
--- @param peer_id integer The source peer's ID, whose data needs to be updated.
--- @param data SyncedLinchpinAuraData Cohesion stack data for the selected peer.
--- @param affect_tendency boolean If true, also update the `to_tend` value.
function PlayerManager:set_synced_cohesion_stacks(peer_id, data, affect_tendency)
	local received_to_tend = 0
	if affect_tendency and data.to_tend ~= nil then
		received_to_tend = data.to_tend
	elseif self._global.synced_cohesion_stacks[peer_id] ~= nil and self._global.synced_cohesion_stacks[peer_id].to_tend ~= nil then
		received_to_tend = self._global.synced_cohesion_stacks[peer_id].to_tend
	end

	self._global.synced_cohesion_stacks[peer_id] = {
		amount = data.amount,
		to_tend = received_to_tend
	}
end

---Iterates through all the synced Linchpin data, and picks out the highest suggested Cohesion stack count to tend to.
---@return integer highest_to_tend The highest to_tend value in the synced Cohesion stack data.
function PlayerManager:get_highest_cohesion_tendency_target()
	local highest = 0
	for i, cohesion_data in ipairs(self._global.synced_cohesion_stacks) do
		highest = math.max(cohesion_data.to_tend, highest)
	end

	return highest
end

--- A simple function that just returns number / 8, rounded down. Used to determine Cohesion "steps", i.e., how much is that "for every X amount of stacks" amount. Primarily exists for if I ever decide to change the step amount.
---@param number integer The number to determine steps for, typically own Cohesion stack count (but not necessarily).
---@return integer Step count.
function PlayerManager:get_cohesion_step(number)
	return math.floor(number / tweak_data.upgrades.linchpin_per_crew_member)
end

--- Returns how much should the Cohesion stack amount be changed by.
--- Considers limits, how far away the current amount is from the goal, etc.
---@param current_amount integer The current amount of Cohesion stacks.
---@param goal integer The amount that the Cohesion stacks shoudl approach.
---@return integer change A positive, negative, or 0 value.
function PlayerManager:get_cohesion_stack_change_amount(current_amount, goal)
	local change = 0
	local per_eight_goal = self:get_cohesion_step(goal) -- This represents the amount of "steps" (eight stacks) the goal has. Since only every 8 stack matters, this can be used to determine how far away the current is from the goal.
	local per_eight_current =  self:get_cohesion_step(current_amount) -- Similar to per_eight_goal.
	local step_difference = math.abs(per_eight_goal - per_eight_current)

	
	if current_amount < goal then
		local additional_gain = self:has_category_upgrade("player","linchpin_stack_change_adjustments") and self:upgrade_value("player", "linchpin_stack_change_adjustments").gain or 0
		change = math.min(goal - current_amount, ((tweak_data.upgrades.linchpin_gain or 1) + additional_gain) * math.max(step_difference,1))
	elseif current_amount > goal then
		local additional_loss = self:has_category_upgrade("player","linchpin_stack_change_adjustments") and self:upgrade_value("player", "linchpin_stack_change_adjustments").loss or 0
		change = -math.min(current_amount - goal, ((tweak_data.upgrades.linchpin_loss or 2) + additional_loss) * math.max(step_difference,1))
	end

	return change
end

--- Updates the current player's Cohesion stacks for all players, and updates the Cohesion tendency suggested by the current player based on the affected parameter.
--- @param data SyncedLinchpinAuraData See class for details.
--- @param affected boolean[] The table of peer IDs who are currently in the current player's Linchpin aura. Used for determining whose tendency numbers should be changed. Values don't matter, only indices. Can be empty.
--- @param change_tendency boolean If true, tendency should be changed as well. If false, do not adjust it.
function PlayerManager:update_cohesion_stacks_for_peers(data, affected, change_tendency)
	local peer = managers.network:session():local_peer()
	local is_affected = false
	if peer then 
    	is_affected = affected[peer:id()] ~= nil
	end

	managers.network:session():send_to_peers_synched("sync_cohesion_stacks", data.amount, data.to_tend, self:pack_linchpin_affected_peer_set(affected), change_tendency)
	self:set_synced_cohesion_stacks(peer:id(), data, is_affected and change_tendency)
end

--- A simplified function that simply just adds an amount to the Cohesion stacks. It then synchronises the changes to the other clients.
--- @param amount number The amount that should be added to the Cohesion stacks.
--- @param go_over_tendency boolean If true, the final Cohesion stack count can go over the tendency.
function PlayerManager:add_cohesion_stacks(amount, go_over_tendency)
	local local_peer_id = managers.network:session() and managers.network:session():local_peer():id()

	if not local_peer_id then
		return
	end

	local data = self:get_synced_cohesion_stacks(local_peer_id)
	local new_amount = data.amount + amount

	if not go_over_tendency then
		-- While I don't want it going over the tendency if the option is off, I DO want to keep any amount that already existed (in case you just ran out of a Linchpin aura, for example).
		new_amount = math.max(math.min(new_amount, data.to_tend), data.amount)
	end

	if new_amount ~= data.amount then
		managers.player:update_cohesion_stacks_for_peers({
			amount = new_amount,
			to_tend = nil
		}, {}, false)
	end
end

---comment
---@param position any
---@return table
---@return number
function PlayerManager:get_linchpin_aura_affected(position)
	local affected_players = {}
	local all_heister_count = 0
	local heisters = World:find_units_quick("sphere", position,
		tweak_data.upgrades.linchpin_proximity or 0, managers.slot:get_mask("all_criminals"))
	for i, unit in ipairs(heisters) do
		all_heister_count = all_heister_count +1
		if managers.network:session():peer_by_unit(unit) then
			local tagged_id = managers.network:session():peer_by_unit(unit):id()
			affected_players[tagged_id] = true
		end
	end

	return affected_players, all_heister_count
end

--- Handles manipulating the Cohesion stack count.
--- @param t number From my guess, an ever-increasing floating point number that represents gametime in seconds.
--- @param dt number Presumably deltatime.
function PlayerManager:update_cohesion_stacks(t, dt)
	local local_peer_id = managers.network:session() and managers.network:session():local_peer():id()
	local player_unit = self:player_unit()
	local keep_track_of_cohesion = self:has_team_category_upgrade("player", "linchpin_damage_to_lose")

	if not local_peer_id or not player_unit or not keep_track_of_cohesion then
		if managers.hud then
			managers.hud:hide_cohesion_display()
		end
		return
	end

	self._cohesion_stack_t = self._cohesion_stack_t or t + (tweak_data.upgrades.linchpin_change_t or 1)
	local cohesion_stacks = self:get_synced_cohesion_stacks(local_peer_id)

	local amount = cohesion_stacks and cohesion_stacks.amount or 0
	local new_amount = amount

	local to_tend = cohesion_stacks and cohesion_stacks.to_tend or 0
	local new_to_tend = to_tend

	-- Handle the HUD update.
	self._cached_cohesion_amount = self._cached_cohesion_amount or 0
	if self._cached_cohesion_amount ~= new_amount and managers.hud then
		managers.hud:set_cohesion_value(new_amount, self:upgrade_value("player", "linchpin_treat_as_more_cohesion", 0))
		self._cached_cohesion_amount = new_amount
	end

	local affected_players = {}

	-- Linchpin users get to update their "suggested" tendency.
	if self:upgrade_value("player", "linchpin_emit_aura", 0) ~= 0 then
		local affected_count = 0
		affected_players, affected_count = self:get_linchpin_aura_affected(player_unit:position())
		local tendency_from_proximity = math.min(affected_count, tweak_data.upgrades.linchpin_hard_limit) * (tweak_data.upgrades.linchpin_per_crew_member or 0)
		local is_downed = game_state_machine:verify_game_state(GameStateFilters.downed)
		new_to_tend = is_downed and 0 or (tendency_from_proximity + self:team_upgrade_value("player", "linchpin_increase_default_tendency", 0))
	end

	if self._cohesion_stack_t <= t then
		self._cohesion_stack_t = t + (tweak_data.upgrades.linchpin_change_t or 1)

		-- I didn't originally plan for fractional Cohesion stack changes, guh!
		self._fractional_change_amount = (self._fractional_change_amount or 0.0) + self:get_cohesion_stack_change_amount(amount, self:get_highest_cohesion_tendency_target())
		local integer_change_amount = math.round(self._fractional_change_amount)
		self._fractional_change_amount = self._fractional_change_amount - integer_change_amount

		new_amount = new_amount + integer_change_amount
	end

	new_to_tend = math.clamp(math.floor(new_to_tend), 0, 256)
	new_amount = math.clamp(math.floor(new_amount), 0, 256)

	if new_amount ~= amount or new_to_tend ~= to_tend then
		self:update_cohesion_stacks_for_peers({
			amount = new_amount,
			to_tend = new_to_tend
		}, affected_players, true)
	end
end