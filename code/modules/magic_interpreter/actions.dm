/decl/magic_word/magic_action/proc/invoke(datum/magic_spell/S, atom/target, mob/caster)
	return

/decl/magic_word/magic_action/creare
	name = "create"
	words = list("creare")
	aliases = list("create", "spawn", "make")
	accepts_turf = TRUE

/decl/magic_word/magic_action/creare/magic_cost(datum/magic_spell/S)
	var/count = 1
	if(S.values.len >= 2)
		var/datum/magic_value/amount = S.values[2]
		if(amount.kind == "num")
			count = clamp(round(amount.value), 1, 50)
	return base_cost + count * 2

/decl/magic_word/magic_action/creare/invoke(datum/magic_spell/S, atom/target, mob/caster)
	if(!S.values.len)
		return S.fail("Nothing was named to create.")
	var/datum/magic_value/what = S.values[1]
	var/count = 1
	if(S.values.len >= 2)
		var/datum/magic_value/amount = S.values[2]
		if(amount.kind == "num")
			count = clamp(round(amount.value), 1, 50)

	var/spawn_type = magic_material_stack(what.kind == "material" ? what.value : what.word)
	if(!spawn_type)
		spawn_type = magic_dotted_typepath(what.original, caster)
	if(!spawn_type)
		return S.fail("'[what.original]' is not something that can be created.")

	var/turf/T = get_turf(target)
	if(!T)
		return S.fail("There is nowhere to create it.")
	if(ispath(spawn_type, /obj/item/stack))
		new spawn_type(T, count)
	else
		count = 1
		new spawn_type(T)
	return "created [count] [spawn_type] at [target]"

/proc/magic_material_stack(material_name)
	if(!name_to_material)
		populate_material_list()
	var/material/M = name_to_material[material_name]
	return M && M.stack_type

// Speech strips '/', so paths are spoken as obj.item.weapon.wrench.
/proc/magic_dotted_typepath(word, mob/caster)
	if(!findtext(word, "."))
		return
	if(!check_rights(R_SPAWN|R_DEBUG, FALSE, caster.client))
		return
	var/path = text2path("/[replacetext(word, ".", "/")]")
	if(ispath(path, /obj))
		return path

/decl/magic_word/magic_action/ignire
	name = "ignite"
	words = list("ignire")
	aliases = list("ignite", "burn_up", "kindle")
	base_cost = 30

/decl/magic_word/magic_action/ignire/magic_cost(datum/magic_spell/S)
	var/stacks = 5
	if(S.values.len)
		var/datum/magic_value/V = S.values[1]
		if(V.kind == "num")
			stacks = clamp(V.value, 1, 20)
	return base_cost + stacks * 3

/decl/magic_word/magic_action/ignire/invoke(datum/magic_spell/S, atom/target, mob/caster)
	if(!isliving(target))
		return S.fail("[target] cannot be set alight.")
	var/mob/living/L = target
	var/stacks = 5
	if(S.values.len)
		var/datum/magic_value/V = S.values[1]
		if(V.kind == "num")
			stacks = clamp(V.value, 1, 20)
	L.adjust_fire_stacks(stacks)
	L.IgniteMob()
	return "ignited [L] with [stacks] fire stacks"

/decl/magic_word/magic_action/explodere
	name = "explode"
	words = list("explodere")
	aliases = list("explode", "detonate")
	accepts_turf = TRUE
	base_cost = 40

/decl/magic_word/magic_action/explodere/magic_cost(datum/magic_spell/S)
	var/size = 2
	if(S.values.len)
		var/datum/magic_value/V = S.values[1]
		if(V.kind == "num")
			size = clamp(round(V.value), 1, 20)
	return base_cost + 5 * size * size

/decl/magic_word/magic_action/explodere/invoke(datum/magic_spell/S, atom/target, mob/caster)
	var/turf/T = get_turf(target)
	if(!T)
		return S.fail("There is nothing there to explode.")
	var/size = 2
	if(S.values.len)
		var/datum/magic_value/V = S.values[1]
		if(V.kind != "num")
			return S.fail("An explosion's size must be a number, not '[V.original]'.")
		size = clamp(round(V.value), 1, 20)
	var/devastation = round(size / 4)
	var/heavy = round(size / 2)
	explosion(T, devastation, heavy, size, size + 1)
	return "exploded [target] at [T.x],[T.y],[T.z] with size [size] ([devastation]/[heavy]/[size])"

/decl/magic_word/magic_action/sanare
	name = "heal"
	words = list("sanare")
	aliases = list("heal", "rejuvenate", "mend")
	cosmetic = TRUE
	base_cost = 80

/decl/magic_word/magic_action/sanare/invoke(datum/magic_spell/S, atom/target, mob/caster)
	if(!isliving(target))
		return S.fail("[target] has no life to mend.")
	var/mob/living/L = target
	L.rejuvenate()
	return "healed [L]"

/decl/magic_word/magic_action/delere
	name = "delete"
	words = list("delere")
	aliases = list("delete", "destroy", "erase")
	base_cost = 20

/decl/magic_word/magic_action/delere/invoke(datum/magic_spell/S, atom/target, mob/caster)
	if(!istype(target, /obj/item))
		return S.fail("Only items can be erased.")
	if(locate(/mob) in target)
		return S.fail("Something living resists inside [target].")
	. = "deleted [target] ([target.type])"
	qdel(target)

/decl/magic_word/magic_action/locus
	name = "relocate"
	words = list("locus")
	aliases = list("teleport", "move")
	base_cost = 40

/decl/magic_word/magic_action/locus/invoke(datum/magic_spell/S, atom/target, mob/caster)
	if(!istype(target, /atom/movable))
		return S.fail("[target] cannot be moved.")
	var/atom/movable/AM = target
	if(isobj(AM) && AM.anchored)
		return S.fail("[AM] is anchored in place.")
	if(!S.values.len)
		return S.fail("No destination was spoken.")
	var/datum/magic_value/V = S.values[1]
	if(V.kind != "target")
		return S.fail("'[V.original]' is not a place.")
	var/turf/destination = get_turf(magic_resolve_target(V.value, caster, TRUE))
	if(!destination)
		return S.fail("The destination cannot be found.")
	if(destination == get_turf(AM))
		return S.fail("[AM] is already there.")
	magic_cast_effect(AM, FALSE)
	if(isitem(AM) && ismob(AM.loc))
		var/mob/holder = AM.loc
		holder.drop_from_inventory(AM)
	AM.forceMove(destination)
	return "moved [AM] to [destination.x],[destination.y],[destination.z]"
