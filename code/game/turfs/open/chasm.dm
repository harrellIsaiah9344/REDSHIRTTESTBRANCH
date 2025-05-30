// Base chasm, defaults to oblivion but can be overridden
/turf/open/chasm
	name = "chasm"
	desc = "Watch your step."
	baseturfs = /turf/open/chasm
	icon = 'icons/turf/floors/chasms.dmi'
	icon_state = "chasms-255"
	base_icon_state = "chasms"
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	smoothing_groups = SMOOTH_GROUP_TURF_OPEN + SMOOTH_GROUP_TURF_CHASM
	canSmoothWith = SMOOTH_GROUP_TURF_CHASM
	density = TRUE //This will prevent hostile mobs from pathing into chasms, while the canpass override will still let it function like an open turf
	bullet_bounce_sound = null //abandon all hope ye who enter

/turf/open/chasm/Initialize(mapload)
	. = ..()
	apply_components()

/// Lets people walk into chasms.
/turf/open/chasm/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	return TRUE

/turf/open/chasm/proc/set_target(turf/target)
	var/datum/component/chasm/chasm_component = GetComponent(/datum/component/chasm)
	chasm_component.target_turf = target

/turf/open/chasm/proc/drop(atom/movable/AM)
	var/datum/component/chasm/chasm_component = GetComponent(/datum/component/chasm)
	chasm_component.drop(AM)

/turf/open/chasm/MakeSlippery(wet_setting, min_wet_time, wet_time_to_add, max_wet_time, permanent)
	return

/turf/open/chasm/MakeDry()
	return

/turf/open/chasm/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	switch(the_rcd.mode)
		if(RCD_FLOORWALL)
			return list("mode" = RCD_FLOORWALL, "delay" = 0, "cost" = 3)
	return FALSE

/turf/open/chasm/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_FLOORWALL)
			to_chat(user, span_notice("You build a floor."))
			PlaceOnTop(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
			return TRUE
	return FALSE

/turf/open/chasm/rust_heretic_act()
	return FALSE

/turf/open/chasm/get_smooth_underlay_icon(mutable_appearance/underlay_appearance, turf/asking_turf, adjacency_dir)
	underlay_appearance.icon = 'icons/turf/floors.dmi'
	underlay_appearance.icon_state = "basalt"
	return TRUE

/turf/open/chasm/attackby(obj/item/C, mob/user, params, area/area_restriction)
	..()
	if(istype(C, /obj/item/stack/rods))
		var/obj/item/stack/rods/R = C
		var/obj/structure/lattice/L = locate(/obj/structure/lattice, src)
		if(L)
			return
		if(!R.use(1))
			to_chat(user, span_warning("You need one rod to build a lattice."))
			return
		to_chat(user, span_notice("You construct a lattice."))
		playsound(src, 'sound/weapons/genhit.ogg', 50, TRUE)
		// Create a lattice, without reverting to our baseturf
		new /obj/structure/lattice(src)
		return
	else if(istype(C, /obj/item/stack/tile/iron))
		build_with_floor_tiles(C, user)

/// Handles adding the chasm component to the turf (So stuff falls into it!)
/turf/open/chasm/proc/apply_components()
	AddComponent(/datum/component/chasm, GET_TURF_BELOW(src))

/turf/open/chasm/can_cross_safely(atom/movable/crossing)
	return HAS_TRAIT(src, TRAIT_CHASM_STOPPED) || HAS_TRAIT(crossing, TRAIT_MOVE_FLYING)

// Chasms for Lavaland, with planetary atmos and lava glow
/turf/open/chasm/lavaland
	initial_gas_mix = LAVALAND_DEFAULT_ATMOS
	planetary_atmos = TRUE
	baseturfs = /turf/open/chasm/lavaland
	light_outer_range = 1.9 //slightly less range than lava
	light_power = 0.65 //less bright, too
	light_color = LIGHT_COLOR_LAVA //let's just say you're falling into lava, that makes sense right

// Chasms for Ice moon, with planetary atmos and glow
/turf/open/chasm/icemoon
	icon = 'icons/turf/floors/icechasms.dmi'
	icon_state = "icechasms-255"
	base_icon_state = "icechasms"
	initial_gas_mix = ICEMOON_DEFAULT_ATMOS
	planetary_atmos = TRUE
	baseturfs = /turf/open/chasm/icemoon
	light_outer_range = 1.9
	light_power = 0.65
	light_color = LIGHT_COLOR_PURPLE

// Chasms for the jungle, with planetary atmos and a different icon
/turf/open/chasm/jungle
	icon = 'icons/turf/floors/junglechasm.dmi'
	icon_state = "junglechasm-255"
	base_icon_state = "junglechasm"
	planetary_atmos = TRUE
	baseturfs = /turf/open/chasm/jungle

/turf/open/chasm/jungle/get_smooth_underlay_icon(mutable_appearance/underlay_appearance, turf/asking_turf, adjacency_dir)
	underlay_appearance.icon = 'icons/turf/floors.dmi'
	underlay_appearance.icon_state = "dirt"
	return TRUE

// Chasm that doesn't do any z-level nonsense and just kills/stores whoever steps into it.
/turf/open/chasm/true
	desc = "There's nothing at the bottom. Absolutely nothing."
	baseturfs = /turf/open/chasm/true

/turf/open/chasm/true/apply_components(mapload)
	AddComponent(/datum/component/chasm, null, mapload) //Don't pass anything for below_turf.

/turf/open/chasm/true/no_smooth
	smoothing_flags = NONE

/turf/open/chasm/true/no_smooth/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	return FALSE

/turf/open/chasm/true/no_smooth/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, list/rcd_data)
	return FALSE

/turf/open/chasm/true/no_smooth/attackby(obj/item/item, mob/user, params, area/area_restriction)
	if(istype(item, /obj/item/stack/rods))
		return
	else if (istype(item, /obj/item/stack/tile/iron) || istype(item, /obj/item/stack/tile/material) && item.has_material_type(/datum/material/iron))
		return
	return ..()
