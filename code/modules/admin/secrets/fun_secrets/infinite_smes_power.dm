/datum/admin_secret_item/fun_secret/infinite_smes_power
	name = "Infinite SMES Power"

/datum/admin_secret_item/fun_secret/infinite_smes_power/execute(var/mob/user)
	. = ..()
	if(.)
		GLOB.infinite_smes_power = TRUE
		power_restore_quick()