
/mob/living/carbon/human/canBeHandcuffed()
	if(num_hands < 2)
		return FALSE
	return TRUE

///returns a list of "damtype" => damage description based off of which bodypart description is most common
///used in human examines
/mob/living/carbon/human/proc/get_majority_bodypart_damage_desc()
	var/list/seen_damage = list() // This looks like: ({Damage type} = list({Damage description for that damage type} = {number of times it has appeared}, ...), ...)
	var/list/most_seen_damage = list() // This looks like: ({Damage type} = {Frequency of the most common description}, ...)
	var/list/final_descriptions = list() // This looks like: ({Damage type} = {Most common damage description for that type}, ...)
	for(var/obj/item/bodypart/part as anything in bodyparts)
		for(var/damage_type in part.damage_examines)
			var/damage_desc = part.damage_examines[damage_type]
			if(!seen_damage[damage_type])
				seen_damage[damage_type] = list()

			if(!seen_damage[damage_type][damage_desc])
				seen_damage[damage_type][damage_desc] = 1
			else
				seen_damage[damage_type][damage_desc] += 1

			if(seen_damage[damage_type][damage_desc] > most_seen_damage[damage_type])
				most_seen_damage[damage_type] = seen_damage[damage_type][damage_desc]
				final_descriptions[damage_type] = damage_desc
	return final_descriptions

//gets assignment from ID or ID inside PDA or PDA itself
//Useful when player do something with computers
/mob/living/carbon/human/proc/get_assignment(if_no_id = "No id", if_no_job = "No job", hand_first = TRUE)
	var/obj/item/card/id/id = get_idcard(hand_first)
	if(HAS_TRAIT(src, TRAIT_UNKNOWN))
		return if_no_id
	if(id)
		. = id.assignment
	else
		var/obj/item/modular_computer/pda = wear_id
		if(istype(pda))
			. = pda.saved_job
		else
			return if_no_id
	if(!.)
		return if_no_job

//gets name from ID or ID inside PDA or PDA itself
//Useful when player do something with computers
/mob/living/carbon/human/proc/get_authentification_name(if_no_id = "Unknown")
	var/obj/item/card/id/id = get_idcard(FALSE)
	if(HAS_TRAIT(src, TRAIT_UNKNOWN))
		return if_no_id
	if(id)
		return id.registered_name
	var/obj/item/modular_computer/pda = wear_id
	if(istype(pda))
		return pda.saved_identification
	return if_no_id

//repurposed proc. Now it combines get_id_name() and get_face_name() to determine a mob's name variable. Made into a separate proc as it'll be useful elsewhere
/mob/living/carbon/human/get_visible_name(add_id_name = TRUE)
	var/face_name = get_face_name("")
	var/id_name = get_id_name("")
	if(HAS_TRAIT(src, TRAIT_UNKNOWN))
		return "Unknown"
	if(name_override)
		return name_override
	if(face_name)
		if(id_name && (id_name != face_name))
			return "[face_name] (as [id_name])"
		return face_name
	if(id_name)
		return id_name
	return "Unknown"

//Returns "Unknown" if facially disfigured and real_name if not. Useful for setting name when Fluacided or when updating a human's name variable
/mob/living/carbon/human/proc/get_face_name(if_no_face="Unknown")
	if(HAS_TRAIT(src, TRAIT_UNKNOWN))
		return if_no_face //We're Unknown, no face information for you
	if( wear_mask && (wear_mask.flags_inv&HIDEFACE) ) //Wearing a mask which hides our face, use id-name if possible
		return if_no_face
	if( head && (head.flags_inv&HIDEFACE) )
		return if_no_face //Likewise for hats
	var/obj/item/bodypart/O = get_bodypart(BODY_ZONE_HEAD)
	if( !O || (HAS_TRAIT(src, TRAIT_DISFIGURED)) || (O.brutestate+O.burnstate)>2 || cloneloss>50 || !real_name || HAS_TRAIT(src, TRAIT_INVISIBLE_MAN)) //disfigured. use id-name if possible
		return if_no_face
	return real_name

//gets name from ID or PDA itself, ID inside PDA doesn't matter
//Useful when player is being seen by other mobs
/mob/living/carbon/human/proc/get_id_name(if_no_id = "Unknown")
	var/obj/item/storage/wallet/wallet = wear_id
	var/obj/item/modular_computer/pda/pda = wear_id
	var/obj/item/card/id/id = wear_id
	if(HAS_TRAIT(src, TRAIT_UNKNOWN))
		. = if_no_id //You get NOTHING, no id name, good day sir
	if(istype(wallet))
		id = wallet.front_id
	if(istype(id))
		. = id.registered_name
	else if(istype(pda) && pda.computer_id_slot)
		. = pda.computer_id_slot.registered_name
	if(!.)
		. = if_no_id //to prevent null-names making the mob unclickable
	return

/mob/living/carbon/human/get_idcard(hand_first = TRUE)
	. = ..()
	if(. && hand_first)
		return
	//Check inventory slots
	return (wear_id?.GetID() || belt?.GetID())

/mob/living/carbon/human/can_use_guns(obj/item/G)
	. = ..()
	if(G.trigger_guard == TRIGGER_GUARD_NORMAL)
		if(HAS_TRAIT(src, TRAIT_CHUNKYFINGERS))
			balloon_alert(src, "fingers are too big!")
			return FALSE
	if(HAS_TRAIT(src, TRAIT_NOGUNS))
		to_chat(src, span_warning("You can't bring yourself to use a ranged weapon!"))
		return FALSE

/mob/living/carbon/human/get_policy_keywords()
	. = ..()
	. += "[dna.species.type]"

/// When we're joining the game in [/mob/dead/new_player/proc/create_character], we increment our scar slot then store the slot in our mind datum.
/mob/living/carbon/human/proc/increment_scar_slot()
	var/check_ckey = ckey || client?.ckey
	if(!check_ckey || !mind || !client?.prefs.read_preference(/datum/preference/toggle/persistent_scars))
		return

	var/path = "data/player_saves/[check_ckey[1]]/[check_ckey]/scars.sav"
	var/index = mind.current_scar_slot_index
	if(!index)
		if(fexists(path))
			var/savefile/F = new /savefile(path)
			index = F["current_scar_index"] || 1
		else
			index = 1

	mind.current_scar_slot_index = (index % PERSISTENT_SCAR_SLOTS) + 1 || 1

/// For use formatting all of the scars this human has for saving for persistent scarring, returns a string with all current scars/missing limb amputation scars for saving or loading purposes
/mob/living/carbon/human/proc/format_scars()
	var/list/missing_bodyparts = get_missing_limbs()
	if(!all_scars && !length(missing_bodyparts))
		return
	var/scars = ""
	for(var/i in missing_bodyparts)
		var/datum/scar/scaries = new
		scars += "[scaries.format_amputated(i)]"
	for(var/i in all_scars)
		var/datum/scar/iter_scar = i
		if(!iter_scar.fake)
			scars += "[iter_scar.format()];"
	return scars

/// Takes a single scar from the persistent scar loader and recreates it from the saved data
/mob/living/carbon/human/proc/load_scar(scar_line, specified_char_index)
	var/list/scar_data = splittext(scar_line, "|")
	if(LAZYLEN(scar_data) != SCAR_SAVE_LENGTH)
		return // invalid, should delete
	var/version = text2num(scar_data[SCAR_SAVE_VERS])
	if(!version || version != SCAR_CURRENT_VERSION) // get rid of scars using a incompatable version
		return
	if(specified_char_index && (mind?.original_character_slot_index != specified_char_index))
		return
	if (isnull(text2num(scar_data[SCAR_SAVE_BIOLOGY])))
		return
	var/obj/item/bodypart/the_part = get_bodypart("[scar_data[SCAR_SAVE_ZONE]]")
	var/datum/scar/scaries = new
	return scaries.load(the_part, scar_data[SCAR_SAVE_VERS], scar_data[SCAR_SAVE_DESC], scar_data[SCAR_SAVE_PRECISE_LOCATION], text2num(scar_data[SCAR_SAVE_SEVERITY]), text2num(scar_data[SCAR_SAVE_BIOLOGY]), text2num(scar_data[SCAR_SAVE_CHAR_SLOT]), text2num(scar_data[SCAR_SAVE_CHECK_ANY_BIO]))

/// Read all the scars we have for the designated character/scar slots, verify they're good/dump them if they're old/wrong format, create them on the user, and write the scars that passed muster back to the file
/mob/living/carbon/human/proc/load_persistent_scars()
	if(!ckey || !mind?.original_character_slot_index || !client?.prefs.read_preference(/datum/preference/toggle/persistent_scars))
		return

	var/path = "data/player_saves/[ckey[1]]/[ckey]/scars.sav"
	var/loaded_char_slot = client.prefs.default_slot

	if(!loaded_char_slot || !fexists(path))
		return FALSE
	var/savefile/F = new /savefile(path)
	if(!F)
		return

	var/char_index = mind.original_character_slot_index
	var/scar_index = mind.current_scar_slot_index || F["current_scar_index"] || 1

	var/scar_string = F["scar[char_index]-[scar_index]"]
	var/valid_scars = ""

	for(var/scar_line in splittext(sanitize_text(scar_string), ";"))
		if(load_scar(scar_line, char_index))
			valid_scars += "[scar_line];"

	WRITE_FILE(F["scar[char_index]-[scar_index]"], sanitize_text(valid_scars))

/// Save any scars we have to our designated slot, then write our current slot so that the next time we call [/mob/living/carbon/human/proc/increment_scar_slot] (the next round we join), we'll be there
/mob/living/carbon/human/proc/save_persistent_scars(nuke = FALSE)
	if(!ckey || !mind?.original_character_slot_index || !client?.prefs.read_preference(/datum/preference/toggle/persistent_scars))
		return

	var/path = "data/player_saves/[ckey[1]]/[ckey]/scars.sav"
	var/savefile/F = new /savefile(path)
	var/char_index = mind.original_character_slot_index
	var/scar_index = mind.current_scar_slot_index || F["current_scar_index"] || 1

	if(nuke)
		WRITE_FILE(F["scar[char_index]-[scar_index]"], "")
		return

	for(var/k in all_wounds)
		var/datum/wound/iter_wound = k
		iter_wound.remove_wound() // so we can get the scars for open wounds

	var/valid_scars = format_scars()
	WRITE_FILE(F["scar[char_index]-[scar_index]"], sanitize_text(valid_scars))
	WRITE_FILE(F["current_scar_index"], sanitize_integer(scar_index))

///Returns death message for mob examine text
/mob/living/carbon/human/proc/generate_death_examine_text()
	var/mob/dead/observer/ghost = get_ghost(TRUE, TRUE)
	var/t_He = p_they(TRUE)
	var/t_his = p_their()
	var/t_is = p_are()
	//This checks to see if the body is revivable
	var/client_like = client || HAS_TRAIT(src, TRAIT_MIND_TEMPORARILY_GONE)
	if(client_like || !get_organ_by_type(/obj/item/organ/internal/brain) || ghost?.can_reenter_corpse)
		return span_deadsay("[t_He] [t_is] limp and unresponsive; there are no signs of life...")
	else
		return span_deadsay("[t_He] [t_is] limp and unresponsive; there are no signs of life and [t_his] soul has departed...")

///copies over clothing preferences like underwear to another human
/mob/living/carbon/human/proc/copy_clothing_prefs(mob/living/carbon/human/destination)
	destination.underwear = underwear
	destination.underwear_color = underwear_color
	destination.undershirt = undershirt
	destination.socks = socks
	destination.socks_color = socks_color //MONKESTATION EDIT
	destination.jumpsuit_style = jumpsuit_style


/// Fully randomizes everything according to the given flags.
/mob/living/carbon/human/proc/randomize_human_appearance(randomize_flags = ALL)
	var/datum/preferences/preferences = new(new /datum/client_interface)

	for (var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if (!preference.included_in_randomization_flags(randomize_flags))
			continue

		if (preference.is_randomizable())
			preference.apply_to_human(src, preference.create_random_value(preferences))

/**
 * Setter for mob height - updates the base height of the mob (which is then adjusted by traits or species)
 *
 * Exists so that the update is done immediately
 *
 * Returns TRUE if changed, FALSE otherwise
 */
/mob/living/carbon/human/proc/set_mob_height(new_height)
	base_mob_height = new_height
	update_mob_height()

/**
 * Updates the mob's height
 *
 * Mainly so that dwarfism can adjust height without needing to override existing height
 *
 * Returns a mob height num
 */
/mob/living/carbon/human/proc/update_mob_height()
	var/old_height = mob_height
	mob_height = dna?.species?.update_species_heights(src) || base_mob_height
	if(old_height != mob_height)
		regenerate_icons()
