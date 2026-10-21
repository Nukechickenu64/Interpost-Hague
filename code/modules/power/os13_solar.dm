// Observable maintenance loop from the OS13 engineer reference recording.
// These bases keep their identity while panels are replaced, so damage, array
// membership and power connections cannot be lost during routine servicing.
GLOBAL_LIST_EMPTY(solar_bases)

/turf/simulated/floor/airless/solar_array
	name = "solar array platform"
	initial_flooring = /decl/flooring/tiling/solarpanel2

/obj/item/solar_panel
	name = "solar panel"
	desc = "A replaceable photovoltaic panel. Fit it to an empty solar panel base and secure it with a screwdriver."
	icon = 'icons/os13/objects/objects/legacy.dmi'
	icon_state = "solar_item"
	w_class = ITEM_SIZE_LARGE
	matter = list("steel" = 2000, "glass" = 4000)
	var/rated_output = 7200
	var/broken = FALSE

/obj/item/solar_panel/advanced
	name = "advanced solar panel"
	desc = "A high-efficiency replacement solar panel. Fits the same bases as a standard panel."
	color = "#a6e7ff"
	rated_output = 14400
	matter = list("steel" = 2000, "glass" = 4000, "plasteel" = 2000)

/obj/item/solar_panel/proc/shatter()
	if(broken)
		return FALSE
	broken = TRUE
	name = "broken [initial(name)]"
	desc = "The photovoltaic surface is shattered. It can be reclaimed by a Replicator."
	icon_state = "solar_panel-b"
	return TRUE

/obj/machinery/power/solar_base
	name = "solar panel base"
	desc = "A serviceable solar mount. Examine it for faults; unsecure its panel with a screwdriver before removing it. A welder repairs the exposed base."
	icon = 'icons/os13/objects/objects/legacy.dmi'
	icon_state = "solar_panel_base"
	density = TRUE
	anchored = TRUE
	var/array_id = "station"
	var/deployed = TRUE
	var/secured = FALSE
	var/defective = FALSE
	var/servicing = FALSE
	var/last_output = 0
	var/obj/item/solar_panel/panel
	var/initial_panel_type

/obj/machinery/power/solar_base/installed
	initial_panel_type = /obj/item/solar_panel
	secured = TRUE

/obj/machinery/power/solar_base/installed/advanced
	initial_panel_type = /obj/item/solar_panel/advanced

/obj/machinery/power/solar_base/installed/damaged
	defective = TRUE

/obj/machinery/power/solar_base/installed/broken

/obj/machinery/power/solar_base/installed/broken/Initialize()
	. = ..()
	panel.shatter()
	update_icon()

/obj/machinery/power/solar_base/Initialize()
	. = ..()
	GLOB.solar_bases += src
	if(initial_panel_type)
		panel = new initial_panel_type(src)
	update_icon()

/obj/machinery/power/solar_base/Destroy()
	GLOB.solar_bases -= src
	QDEL_NULL(panel)
	return ..()

/obj/machinery/power/solar_base/Exited(atom/movable/O, atom/newloc)
	. = ..()
	if(O == panel)
		panel = null
		secured = FALSE
		last_output = 0
		update_icon()

/obj/machinery/power/solar_base/proc/power_output()
	if(!anchored || !network_connected || !isturf(loc) || !deployed || !secured || defective || (stat & BROKEN) || !panel || panel.loc != src || panel.broken)
		return 0
	return panel.rated_output

/obj/machinery/power/solar_base/Process()
	last_output = power_output()
	if(last_output)
		add_avail(last_output)

/obj/machinery/power/solar_base/update_icon()
	overlays.Cut()
	icon_state = "solar_panel_base"
	if(panel && panel.loc == src)
		var/state = panel.broken ? "solar_panel-b" : (deployed ? "solar_panel" : "solar_panel_retracted")
		var/image/surface = image(icon, icon_state = state, dir = NORTHEAST)
		surface.color = panel.color
		overlays += surface

/obj/machinery/power/solar_base/examine(mob/user)
	. = ..()
	if(!user.Adjacent(src))
		return
	to_chat(user, SPAN_NOTICE("The array is [deployed ? "spread" : "retracted"]. [panel ? "The panel is [secured ? "secured" : "unsecured"]." : "The mount is empty."]"))
	if(defective || (stat & BROKEN))
		to_chat(user, SPAN_WARNING("You notice a defect! Remove the panel before welding the base."))
	if(panel && panel.broken)
		to_chat(user, SPAN_WARNING("The panel is shattered and needs replacing."))
	to_chat(user, SPAN_NOTICE("Output: [round(power_output() / 1000, 0.01)] kW."))

/obj/machinery/power/solar_base/proc/install_panel(obj/item/solar_panel/P, mob/user)
	if(panel || servicing || !P || QDELETED(P) || P.broken || !user || P.loc != user || !user.Adjacent(src) || user.incapacitated())
		return FALSE
	if(!user.unEquip(P, target = src))
		return FALSE
	panel = P
	secured = FALSE
	update_icon()
	to_chat(user, SPAN_NOTICE("You fit \the [P] to the base. Secure it with a screwdriver."))
	return TRUE

/obj/machinery/power/solar_base/proc/remove_panel(mob/user)
	if(!panel || secured || servicing || !user || !user.Adjacent(src) || user.incapacitated())
		return FALSE
	var/obj/item/solar_panel/removed = panel
	panel = null
	removed.forceMove(get_turf(src))
	if(removed.broken)
		// Keep reclamation bounded by the material cost of the original panel.
		var/obj/item/weapon/material/shard/mirror/S = new(get_turf(src))
		S.matter = removed.matter.Copy()
		qdel(removed)
		user.put_in_hands(S)
	else
		user.put_in_hands(removed)
	last_output = 0
	update_icon()
	return TRUE

/obj/machinery/power/solar_base/attack_hand(mob/user)
	if(..())
		return
	if(!remove_panel(user))
		examine(user)

/obj/machinery/power/solar_base/proc/repair_base()
	if(panel || servicing || (!defective && !(stat & BROKEN)))
		return FALSE
	defective = FALSE
	set_broken(FALSE)
	update_icon()
	return TRUE

/obj/machinery/power/solar_base/attackby(obj/item/W, mob/user)
	if(servicing || !user.Adjacent(src) || user.incapacitated())
		return
	if(istype(W, /obj/item/solar_panel))
		if(!install_panel(W, user))
			to_chat(user, SPAN_WARNING("The base needs an intact panel and an empty mount."))
		return
	if(isScrewdriver(W))
		if(!panel)
			to_chat(user, SPAN_WARNING("There is no panel to secure."))
			return
		secured = !secured
		last_output = 0
		playsound(src, 'sound/items/Screwdriver.ogg', 50, TRUE)
		to_chat(user, SPAN_NOTICE("You [secured ? "secure" : "unsecure"] the panel."))
		return
	if(isWelder(W))
		if(panel)
			to_chat(user, SPAN_WARNING("Remove the panel before repairing the base."))
			return
		if(!defective && !(stat & BROKEN))
			to_chat(user, SPAN_NOTICE("The base has no defects."))
			return
		var/obj/item/weldingtool/WT = W
		if(!WT.remove_fuel(0, user))
			return
		servicing = TRUE
		to_chat(user, SPAN_NOTICE("You begin repairing the solar panel base."))
		var/completed = do_after(user, 3 SECONDS, src)
		if(QDELETED(src))
			return
		servicing = FALSE
		if(completed && !panel && WT.loc == user && WT.remove_fuel(1, user) && repair_base())
			to_chat(user, SPAN_NOTICE("You fix the solar panel base."))
		return
	return ..()

/obj/machinery/power/solar_base/ex_act(severity)
	// Retraction protects the panel from glancing impacts, not direct hits.
	if(severity == 3 && !deployed)
		return
	defective = TRUE
	if(panel && (deployed || severity == 1))
		panel.shatter()
	last_output = 0
	update_icon()

/obj/machinery/power/solar_base/bullet_act(obj/item/projectile/P)
	if(P.get_structure_damage() > 0)
		defective = TRUE
		if(panel && deployed)
			panel.shatter()
		last_output = 0
		update_icon()
	return ..()

/obj/item/weapon/material/shard/mirror
	name = "mirror shard"
	matter = list("steel" = 2000, "glass" = 4000)

/obj/item/weapon/material/shard/mirror/set_material(new_material)
	..()
	SetName("mirror shard")
	desc = "A sharp fragment of a shattered solar panel. It can be collected by a Harvester and reclaimed by a Replicator."
	color = "#ed37df"
	alpha = 255

// A cart carries real panel items; loading/unloading never fabricates copies.
/obj/structure/solar_panel_cart
	name = "solar panel cart"
	desc = "A rolling rack for six replacement solar panels. Use panels on it to load; click with an empty hand to unload."
	icon = 'icons/os13/objects/objects/legacy.dmi'
	icon_state = "solarpanelcart"
	density = TRUE
	anchored = FALSE
	var/capacity = 6
	var/list/panels = list()

/obj/structure/solar_panel_cart/loaded/Initialize()
	. = ..()
	for(var/i = 1 to capacity)
		panels += new /obj/item/solar_panel(src)
	update_icon()

/obj/structure/solar_panel_cart/Destroy()
	for(var/obj/item/solar_panel/P in contents)
		P.forceMove(get_turf(src))
	panels.Cut()
	return ..()

/obj/structure/solar_panel_cart/update_icon()
	icon_state = length(panels) ? "solarpanelcart1" : "solarpanelcart"

/obj/structure/solar_panel_cart/Exited(atom/movable/O, atom/newloc)
	. = ..()
	panels -= O
	update_icon()

/obj/structure/solar_panel_cart/attackby(obj/item/W, mob/user)
	if(!istype(W, /obj/item/solar_panel))
		return ..()
	if(!user.Adjacent(src) || user.incapacitated() || length(panels) >= capacity)
		return
	if(user.unEquip(W, target = src))
		panels += W
		update_icon()

/obj/structure/solar_panel_cart/attack_hand(mob/user)
	if(!user.Adjacent(src) || user.incapacitated())
		return
	if(!length(panels))
		to_chat(user, SPAN_NOTICE("The cart is empty."))
		return
	var/obj/item/solar_panel/P = panels[panels.len]
	panels -= P
	if(P && !QDELETED(P) && P.loc == src)
		P.forceMove(get_turf(src))
		user.put_in_hands(P)
	update_icon()

/obj/structure/solar_panel_cart/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("It holds [length(panels)] / [capacity] panels."))

/datum/design/item/solar_panel
	name = "solar panel"
	id = "solar_panel"
	req_tech = list(TECH_POWER = 1, TECH_MATERIAL = 1)
	materials = list("steel" = 2000, "glass" = 4000)
	build_path = /obj/item/solar_panel
	sort_string = "VAAAA"

/datum/design/item/solar_panel/advanced
	name = "advanced solar panel"
	id = "advanced_solar_panel"
	req_tech = list(TECH_POWER = 4, TECH_MATERIAL = 3, TECH_ENGINEERING = 3)
	materials = list("steel" = 2000, "glass" = 4000, "plasteel" = 2000)
	build_path = /obj/item/solar_panel/advanced
	sort_string = "VAAAB"

/decl/hierarchy/supply_pack/engineering/solar_panels
	name = "Replacement solar panels"
	contains = list(/obj/item/solar_panel = 6)
	containername = "replacement solar panel crate"

/decl/hierarchy/supply_pack/engineering/solar_service
	name = "Solar maintenance carts"
	contains = list(/obj/structure/solar_panel_cart/loaded, /obj/structure/harvester)
	containername = "solar maintenance crate"

