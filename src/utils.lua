_G.LinchpinUtils = _G.LinchpinUtils or {
    --- For SuperBLT Networking, this is the message ID for updating stacks over the net.
    LINCHPIN_MESSAGE_SYNC_STACKS = "linchpin_message_sync_cohesion_stacks",

    --- For SuperBLT Networking, this is the message ID for adding stacks over the net.
    LINCHPIN_MESSAGE_ADD_STACKS = "linchpin_message_add_cohesion_stacks"
}

--- Represents Linchpin data sent through the LINCHPIN_MESSAGE_SYNC_STACKS ID'd message. Typically used to update one's own Cohesion stack count on the other peers' sides, or to enforce a new tendency on them.
--- @class NetworkedLinchpinSelfDataUpdate
--- @field amount integer The amount of Cohesion stacks the current peer has.
--- @field to_tend integer The amount of Cohesion stacks the current peer suggest other peers tend to.
--- @field affected table<integer,boolean> A map of peer IDs to boolean values. The values themselves actually don't matter, only the existence of a peer's ID in the keys.
--- @field change_tendency boolean If true, the current peer suggests to the affected peers that they copy over this peer's tendency locally. Doing so causes their own logic to start tending their Cohesion amounts to the tendency. Effectively, "being within a Linchpin user's proxmity" is represented by the Linchpin peer telling another their own to_tend value.

--- Represents Linchpin data sent through the LINCHPIN_MESSAGE_ADD_STACKS ID'd message. This one is typically a simple command that the affected peers should change their Cohesion stack amounts.
--- @class NetworkedLinchpinOthersDataUpdate
--- @field amount integer The amount of Cohesion stacks other peers should add to their own.
--- @field go_over_tendency boolean Whether this addition should increase the peers' Cohesion stacks past the greatest tendency they have.
--- @field affected table<integer,boolean> A map of peer IDs to boolean values. The values themselves actually don't matter, only the existence of a peer's ID in the keys.

--- I am *baffled* at how many (stupid) solutions exist for seralising tables in Lua, and I'm baffled that this is not something given by default. At least, I don't think it is? Anyway, this function serialises any kind of value.
--- @param value any Any value.
--- @return string seralised_value That value serialised into a string.
function LinchpinUtils:serialise(value)
    local t = type(value)

    if t == "number" then
        return tostring(value)

    elseif t == "boolean" then
        return tostring(value)

    elseif t == "string" then
        return string.format("%q", value)

    elseif t == "table" then
        local result = "{"
        local first = true

        for k, v in pairs(value) do
            if not first then
                result = result .. ","
            end
            first = false

            result = result ..
                "[" .. self:serialise(k) .. "]=" .. self:serialise(v)
        end

        return result .. "}"

    elseif t == "nil" then
        return "nil"

    else
        error("Cannot serialise type: " .. t)
    end
end

--- The opposite of LinchpinUtils:serialise().
--- @param string string A serialised data of some kind.
--- @return boolean|number|table|unknown|nil The deserialised value.
function LinchpinUtils:deserialise(str)
    local i = 1
    local n = #str

    local function skip()
        while i <= n and str:sub(i, i):match("%s") do
            i = i + 1
        end
    end

    local function parse_value()
        skip()
        local c = str:sub(i, i)

        -- table
        if c == "{" then
            i = i + 1
            local t = {}
            skip()

            while str:sub(i, i) ~= "}" do
                i = i + 1 -- skip '['
                local k = parse_value()
                i = i + 2 -- skip "]="
                local v = parse_value()
                t[k] = v

                skip()
                if str:sub(i, i) == "," then
                    i = i + 1
                end
                skip()
            end

            i = i + 1 -- skip '}'
            return t

        -- string
        elseif c == "\"" or c == "'" then
            local q = c
            i = i + 1
            local start = i
            while str:sub(i, i) ~= q do
                if str:sub(i, i) == "\\" then
                    i = i + 1
                end
                i = i + 1
            end
            local s = str:sub(start, i - 1)
            i = i + 1
            return s:gsub("\\(.)", "%1")

        -- number
        elseif c:match("[%d%-]") then
            local start = i
            while str:sub(i, i):match("[%d%.eE%+%-]") do
                i = i + 1
            end
            return tonumber(str:sub(start, i - 1))

        -- literals
        else
            if str:sub(i, i + 3) == "true" then
                i = i + 4
                return true
            elseif str:sub(i, i + 4) == "false" then
                i = i + 5
                return false
            elseif str:sub(i, i + 2) == "nil" then
                i = i + 3
                return nil
            end
        end
    end

    return parse_value()
end