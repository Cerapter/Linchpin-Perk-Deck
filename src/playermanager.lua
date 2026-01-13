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

Hooks:PostHook(PlayerManager, "skill_dodge_chance", "linchpin_playermanager_skill_dodge_chance", function(self, _, _, _, _, _)
	local chance = Hooks:GetReturn()
	local cohesion_stacks = self:get_cohesion_step(self:get_cohesion_stacks_as_treated()) or 0
	chance = chance + self:team_upgrade_value("player", "linchpin_crew_dodge_points", 0) * cohesion_stacks
	return chance
end)

--- Didn't necessarily have to be a separate function, but hey, Hysteria stacks did it this way, and when in Rome...
--- Plus maybe it helps me not get lost in the sauce!
--- @param peer_id integer Typically a number ranging from 1 to 4, literally just the player ID.
--- @return SyncedLinchpinAuraData stack_data Cohesion stack data for the selected peer.
function PlayerManager:get_synced_cohesion_stacks(peer_id)
	return self._global.synced_cohesion_stacks[peer_id]
end

--- For the purposes of effects, returns the amount of Cohesion stacks the local peer is treated as having (which may be different than how many it has).
---@return integer cohesion_stacks The actual Cohesion stacks, plus any "as treated" extras.
function PlayerManager:get_cohesion_stacks_as_treated()
	local local_peer = managers.network:session() and managers.network:session():local_peer()
	if not local_peer then
		return 0
	end

	local extra_amount = self:upgrade_value("player", "linchpin_treat_as_more_cohesion", 0)
	local cohesion_stacks = managers.player:get_synced_cohesion_stacks(local_peer:id())

	return (cohesion_stacks and cohesion_stacks.amount or 0) + extra_amount
end

--- Updates a given peer's Linchpin-related data.
--- @param peer_id integer The source peer's ID, whose data needs to be updated.
--- @param data SyncedLinchpinAuraData Cohesion stack data for the selected peer.
--- @param affect_tendency boolean If true, also update the `to_tend` value.
function PlayerManager:set_synced_cohesion_stacks(peer_id, data, affect_tendency)
	self._global.synced_cohesion_stacks[peer_id] = {
		amount = data.amount,
		to_tend = affect_tendency and data.to_tend or self._global.synced_cohesion_stacks[peer_id] and self._global.synced_cohesion_stacks[peer_id].to_tend or 0
	}

	-- TODO REMOVE DEBUG
	local this_peer_id = managers.network:session():local_peer():id()
	managers.chat:send_message(1, '[Linchpin]',
		'Peer ' ..
		tostring(this_peer_id) ..
		' received Cohesion stack synching from ' ..
		tostring(peer_id) ..
		' - Stacks: ' ..
		tostring(data.amount) .. ' - Tendency: ' .. tostring(data.to_tend) .. ' (' .. tostring(affect_tendency) ..
		')', Color.yellow)
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
		change = math.min(goal - current_amount, (tweak_data.upgrades.linchpin_gain or 1) * self:upgrade_value("player", "linchpin_gain_change", 1) * math.max(step_difference,1))
	elseif current_amount > goal then
		change = -math.min(current_amount - goal, (tweak_data.upgrades.linchpin_loss or 2) * self:upgrade_value("player", "linchpin_loss_change", 1) * math.max(step_difference,1))
	end

	return change
end

--- Updates the current player's Cohesion stacks for all players, and updates the Cohesion tendency suggested by the current player based on the affected parameter.
--- @param data SyncedLinchpinAuraData See class for details.
--- @param affected boolean[] The table of unit IDs who are currently in the current player's Linchpin aura. Used for determining whose tendency numbers should be changed. Values don't matter, only indices. Can be empty.
--- @param change_tendency boolean If true, tendency should be changed as well. If false, do not adjust it.
function PlayerManager:update_cohesion_stacks_for_peers(data, affected, change_tendency)
	local peer = managers.network:session():local_peer()
	local is_affected = false
	if peer and peer:unit() and peer:unit():id() then 
    	is_affected = affected[peer:unit():id()] ~= nil
	end

	managers.network:session():send_to_peers_synched("sync_cohesion_stacks", data, affected, change_tendency)
	self:set_synced_cohesion_stacks(peer:id(), data, is_affected and change_tendency)
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
		managers.hud:set_cohesion_value(new_amount)
		self._cached_cohesion_amount = new_amount
	end

	--- The unit IDs of the affected players. Table index should be unit IDs, values don't matter.
	--- @type boolean[]
	local affected_players = {}

	-- Linchpin users get to update their "suggested" tendency.
	if self:upgrade_value("player", "linchpin_emit_aura", nil) then
		local heisters = World:find_units_quick("sphere", player_unit:position(),
			tweak_data.upgrades.linchpin_proximity or 0, managers.slot:get_mask("all_criminals"))
		for i, unit in ipairs(heisters) do
			affected_players[unit:id()] = true
		end
		local per_member_tendency = tweak_data.upgrades.linchpin_per_crew_member or 0
		local affected_player_count = 0
		for _ in pairs(affected_players) do
			affected_player_count = math.min(affected_player_count + 1, tweak_data.upgrades.linchpin_hard_limit or 4)
		end

		local is_downed = game_state_machine:verify_game_state(GameStateFilters.downed)
		new_to_tend =  is_downed and 0 or per_member_tendency * affected_player_count
	end

	if self._cohesion_stack_t <= t then
		self._cohesion_stack_t = t + (tweak_data.upgrades.linchpin_change_t or 1)
		new_amount = new_amount + self:get_cohesion_stack_change_amount(amount, self:get_highest_cohesion_tendency_target())
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