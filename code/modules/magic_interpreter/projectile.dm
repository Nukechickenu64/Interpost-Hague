/obj/item/projectile/magic_bolt
	name = "bolt of speech"
	icon_state = "ice_1"
	damage = 0
	damage_type = BURN
	nodamage = 1
	check_armour = "energy"
	var/list/spells
	var/applied = FALSE

// Bypasses bullet_act so the bolt never misses, rolls armour or leaves bullet holes.
/obj/item/projectile/magic_bolt/attack_mob(mob/living/target_mob, distance, miss_modifier = 0)
	if(!istype(target_mob))
		return
	apply_spell(target_mob)
	return 1

/obj/item/projectile/magic_bolt/Bump(atom/A, forced = FALSE)
	if(A == src || A == firer || ismob(A))
		return ..()
	apply_spell(A)
	on_impact(A)
	set_density(0)
	set_invisibility(101)
	qdel(src)
	return 1

/obj/item/projectile/magic_bolt/on_impact(atom/A)
	..()
	if(A)
		apply_spell(A)

/obj/item/projectile/magic_bolt/proc/apply_spell(atom/target)
	if(applied || !spells)
		return
	applied = TRUE
	magic_interpreter.apply_group(spells, target)

/obj/item/projectile/magic_bolt/Destroy()
	spells = null
	return ..()
