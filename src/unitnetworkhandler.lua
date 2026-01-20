if not restoration then
	return
end

--- Cohesion stack syncing. That's about it.
--- @param amount integer The amount of Cohesion stacks the sender has.
--- @param to_tend integer The amount of Cohesion stacks the sender's stacks tend to.
--- @param affected_packed string The packed version of the affected peers array.
--- @param change_tendency boolean If true, enforces the changing of the tendency. It is often false when only the amount needs to be updated.
--- @param sender Peer I dunno much about this, to be honest.
function UnitNetworkHandler:sync_cohesion_stacks(amount, to_tend, affected_packed, change_tendency, sender)
	local peer = self._verify_sender(sender)

	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not peer then
		return
	end

	local peer_id = peer:id()
    local checked_cohesion_data = {
        amount = amount or 0,
        to_tend = to_tend or 0
    }

	local affected_peers = self:unpack_linchpin_affected_peer_set(affected_packed)
    local is_affected = affected_peers[peer_id] ~= nil

	managers.player:set_synced_cohesion_stacks(peer_id, checked_cohesion_data, is_affected and change_tendency)
end

--- Tells peers to give themselves Cohesion stacks.
--- @param amount integer See PlayerManager:add_cohesion_stacks().
--- @param go_over_tendency boolean See PlayerManager:add_cohesion_stacks().
--- @param affected_packed string The packed version of the affected peers array.
--- @param sender Peer See my comments at sync_cohesion_stacks().
function UnitNetworkHandler:sync_add_cohesion_stacks(amount, go_over_tendency, affected_packed, sender)
	local peer = self._verify_sender(sender)

	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not peer then
		return
	end

	local affected_peers = self:unpack_linchpin_affected_peer_set(affected_packed)
    if  affected_peers[peer:id()] ~= nil then
		managers.player:add_cohesion_stacks(amount, go_over_tendency)
	end
end

--- Unpacks a comma-separated peer ID string into a table. I wasn't sure how to send over a table of data (when it came to peer IDs), soooo...
--- @param packed_ids string  Packed peer ID string.
--- @return table<integer, boolean> peer_set Set of peer IDs. Keys are IDs, values are true.
function UnitNetworkHandler:unpack_linchpin_affected_peer_set(packed_ids)
    local peer_set = {}

    if packed_ids == "" then
        return peer_set
    end

    for id in string.gmatch(packed_ids, "[^,]+") do
        peer_set[tonumber(id)] = true
    end

    return peer_set
end