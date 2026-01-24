if not restoration then
	return
end

if not tweak_data then 
	return 
end

-- Fill out the descriptions based on these values above so I don't have to go back to constantly editing them.

-- Gonna need to find the key for the Linchpin deck. It *should* be the last one, but I don't wanna leave it up to chance.
-- So I'll just look for its title, and if I find it, that's it.
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
		["menu_st_spec_"..tostring(desc_key)] = "Linchpin",
        ["LinchpinPerkDeckOptionsButtonTitleID"] = "Linchpin Perk Deck",
        ["LinchpinPerkDeckOptionsButtonDescID"] = "Options related to the Linchpin perk deck.",
        ["LinchpinPerkDeckInfo_cohesion_displayTitleID"] = "Cohesion Display",
        ["LinchpinPerkDeckInfo_cohesion_displayDescID"] = "Determines how (or if at all) should the Cohesion Stack counter be displayed.",
        ["linchpin_cohesion_display_on_right"] = "Right side, next to Dodge Metre",
        ["linchpin_cohesion_display_in_resmod_buff_tracker"] = "Within ResMod's Buff Tracker",
        ["linchpin_cohesion_display_none"] = "Do Not Display",
        ["LinchpinPerkDeckInfo_heisters_in_auraTitleID"] = "\"Heisters in Proximity\" Display",
        ["LinchpinPerkDeckInfo_heisters_in_auraDescID"] = "When using ResMod's Buff Tracker, determines if a \"buff\" should be displayed that shows the amount of non-convert allies nearby."
    })
end)