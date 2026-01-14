if not restoration then
	return
end

--- Cohesion stack syncing. That's about it.
--- @param data SyncedLinchpinAuraData See class for details.
--- @param affected boolean[] The table of unit IDs who are currently in the sender player's Linchpin aura. Can be empty.
--- @param change_tendency boolean If true, enforces the changing of the tendency. It is often false when only the amount needs to be updated.
--- @param sender Peer I dunno much about this, to be honest.
function UnitNetworkHandler:sync_cohesion_stacks(data, affected, change_tendency, sender)
	local peer = self._verify_sender(sender)

	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not peer then
		return
	end

	local peer_id = peer:id()
    local checked_cohesion_data = {
        amount = data.amount or 0,
        to_tend = data.to_tend or 0
    }

    local peer_unit = peer:unit()
    local is_affected = affected[peer_unit] ~= nil

	managers.chat:send_message(1, '[Linchpin]','SYNCING SYNC', Color.yellow)
	managers.player:set_synced_cohesion_stacks(peer_id, checked_cohesion_data, is_affected and change_tendency)
end

--- Tells peers to give themselves Cohesion stacks.
--- @param amount integer See PlayerManager:add_cohesion_stacks().
--- @param go_over_tendency boolean See PlayerManager:add_cohesion_stacks().
--- @param affected boolean[] The table of unit IDs whose players should do the addition. Indices matter more than content here.
--- @param sender Peer See my comments at sync_cohesion_stacks().
function UnitNetworkHandler:sync_add_cohesion_stacks(amount, go_over_tendency, affected, sender)
	local peer = self._verify_sender(sender)

	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not peer then
		return
	end

    local peer_unit = peer:unit()
    if  affected[peer_unit] ~= nil then
		managers.chat:send_message(1, '[Linchpin]','SYNCING ADD', Color.yellow)
		managers.player:add_cohesion_stacks(amount, go_over_tendency)
	end
end