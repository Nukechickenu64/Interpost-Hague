/datum/unit_test/turbolift_rejects_unregistered_floor
	name = "TURBOLIFT: Rejects floors outside its route"

/datum/unit_test/turbolift_rejects_unregistered_floor/start_test()
	var/datum/turbolift/lift = new
	var/datum/turbolift_floor/unregistered_floor = new
	lift.queue_move_to(unregistered_floor)
	var/rejected_without_side_effects = !(unregistered_floor in lift.queued_floors) && !lift.processing && !lift.busy_state
	qdel(unregistered_floor)
	qdel(lift)
	if(rejected_without_side_effects)
		pass("An unregistered floor leaves the lift idle and unchanged.")
	else
		fail("An unregistered floor changed turbolift queue or processing state.")
	return 1