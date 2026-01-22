if not restoration then
	return
end

if not tweak_data then 
	return 
end

-- Fill out the descriptions based on these values above so I don't have to go back to constantly editing them.

-- Gonna need to find the key for the Linchpin deck. It *should* be the last one, but I don't wanna leave it up to chance.
-- So I'll just look for its first description, and if I find it, that's it.
local desc_key = nil

for i =  #tweak_data.skilltree.specializations, 1, -1 do
    if tweak_data.skilltree.specializations[i].name_id and tweak_data.skilltree.specializations[i].name_id == "menu_deck_linchpin_title" and desc_key == nil then
        desc_key = i
    end
end

if desc_key == nil then
    return
end


Hooks:Add("LocalizationManagerPostInit", "Linchpin_Localisation_Init", function(loc)
	LocalizationManager:add_localized_strings({
		["menu_st_spec_"..tostring(desc_key)] = "Linchpin"
    })
end)