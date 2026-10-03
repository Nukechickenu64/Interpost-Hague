/*
* Unit tests for built-in BYOND procs, to ensure overrides have not affected functionality.
*/
datum/unit_test/foundation
	name = "FOUNDATION template"
	async = 0

datum/unit_test/foundation/step_shall_return_true_on_success
	name = "FOUNDATION: step() shall return true on success"

datum/unit_test/foundation/step_shall_return_true_on_success/start_test()
	var/mob_step_result = TestStep(/mob)
	var/obj_step_result = TestStep(/obj)

	if(mob_step_result && obj_step_result)
		pass("step() returned true.")
	else
		fail("step() did not return true: Mob result: [mob_step_result] - Obj result: [obj_step_result].")

	return 1

datum/unit_test/foundation/proc/TestStep(type_to_test)
	var/turf/start = get_safe_turf()
	var/atom/movable/T = new type_to_test(start)

	. = step(T, NORTH)
	. = . && start.x == T.x
	. = . && start.y + 1 == T.y
	. = . && start.z == T.z

/obj/right_click_test
	var/attempts = 0
	var/fallbacks = 0
	var/mob/last_actor

/obj/right_click_test/get_right_click_verbs()
	return list(/obj/right_click_test/verb/base_action, /obj/right_click_test/child/verb/specific_action, /obj/right_click_test/child/verb/tied_action, /obj/right_click_test/child/verb/hidden_action, /obj/right_click_test/child/verb/admin_action, /obj/right_click_test/child/verb/use_right)

/obj/right_click_test/attack_hand(mob/user)
	fallbacks++

/obj/right_click_test/verb/base_action()
	set category = "Object"
	attempts++
	last_actor = usr
	return FALSE

/obj/right_click_test/child/verb/specific_action()
	set category = "Object"
	attempts++
	last_actor = usr

/obj/right_click_test/child/verb/tied_action()
	set category = "Object"
	attempts++

/obj/right_click_test/child/verb/hidden_action()
	set category = "Object"
	set hidden = TRUE
	attempts++

/obj/right_click_test/child/verb/admin_action()
	set category = "Admin"
	attempts++

/obj/right_click_test/child/verb/use_right()
	set category = "Object"
	attempts++

/obj/right_click_test/child/verb/unsupported_action(argument as text)
	set category = "Object"
	attempts++

/obj/right_click_test_reparented
	parent_type = /obj/right_click_test/child

/obj/right_click_test/shortcut/attack_hand_right(mob/user)
	attempts += 10

/datum/unit_test/foundation/right_click_selection
	name = "FOUNDATION: Right-click selects the most specific eligible world verb"

/datum/unit_test/foundation/right_click_selection/start_test()
	var/turf/test_turf = get_safe_turf()
	var/obj/right_click_test/child/target = new /obj/right_click_test_reparented(test_turf)
	if(target.select_right_click_verb())
		fail("Equally specific verbs did not remain ambiguous.")
	target.verbs -= /obj/right_click_test/child/verb/tied_action
	if(target.select_right_click_verb() != /obj/right_click_test/child/verb/specific_action)
		fail("The specific verb did not win across parent_type inheritance.")
	target.preferred_right_click_verb = /obj/right_click_test/verb/base_action
	if(target.select_right_click_verb() != /obj/right_click_test/verb/base_action)
		fail("The preferred eligible verb did not take priority.")
	target.preferred_right_click_verb = /obj/right_click_test/child/verb/hidden_action
	if(target.select_right_click_verb() != /obj/right_click_test/child/verb/specific_action)
		fail("Hidden preferred verb was eligible.")
	target.verbs -= /obj/right_click_test/child/verb/specific_action
	if(target.select_right_click_verb() != /obj/right_click_test/verb/base_action)
		fail("Hidden, admin, generic or unsupported verbs displaced the inherited action.")
	target.verbs += /obj/right_click_test/child/verb/specific_action
	if(target.select_right_click_verb() != /obj/right_click_test/child/verb/specific_action)
		fail("A newly added eligible verb was not considered.")
	target.verbs -= /obj/right_click_test/child/verb/specific_action
	target.verbs -= /obj/right_click_test/verb/base_action
	if(target.select_right_click_verb())
		fail("Removed or ineligible verbs were selected.")
	var/obj/container = new(test_turf)
	target.verbs += /obj/right_click_test/verb/base_action
	target.forceMove(container)
	if(target.select_right_click_verb())
		fail("A contained object was eligible for world right-click selection.")
	qdel(target)
	qdel(container)
	if(!reported)
		pass("Specificity, preferences, ties, filtering and live membership are respected.")
	return TRUE

/datum/unit_test/foundation/right_click_dispatch
	name = "FOUNDATION: Right-click attempts one action and preserves shortcuts"

/datum/unit_test/foundation/right_click_dispatch/start_test()
	var/turf/test_turf = get_safe_turf()
	var/mob/living/carbon/human/actor = new(test_turf)
	var/obj/right_click_test/target = new(test_turf)
	usr = actor
	target.attack_hand_right(actor)
	if(target.attempts != 1 || target.fallbacks || target.last_actor != actor)
		fail("A FALSE-returning action lost its actor or fell through to attack_hand.")
	actor.stat = UNCONSCIOUS
	target.attack_hand_right(actor)
	actor.stat = CONSCIOUS
	if(target.attempts != 1 || target.fallbacks)
		fail("An incapacitated user invoked an action or fallback.")
	usr = null
	target.attack_hand_right(actor)
	if(target.attempts != 1 || target.fallbacks)
		fail("Mismatched usr context invoked an action or fallback.")
	usr = actor
	target.forceMove(null)
	target.attack_hand_right(actor)
	if(target.attempts != 1 || target.fallbacks)
		fail("An unreachable target was invoked.")
	target.forceMove(test_turf)
	target.verbs -= /obj/right_click_test/verb/base_action
	target.attack_hand_right(actor)
	if(target.fallbacks != 1)
		fail("No eligible verb did not retain the old hand fallback.")
	var/obj/right_click_test/child/tied_target = new(test_turf)
	tied_target.attack_hand_right(actor)
	if(tied_target.attempts || tied_target.fallbacks != 1)
		fail("An unresolved tie did not retain the old hand fallback.")
	var/obj/right_click_test/shortcut/shortcut = new(test_turf)
	shortcut.attack_hand_right(actor)
	if(shortcut.attempts != 10 || shortcut.fallbacks)
		fail("An existing shortcut lost priority.")
	qdel(shortcut)
	qdel(tied_target)
	qdel(target)
	qdel(actor)
	if(!reported)
		pass("Single attempts, actor guards, fallback and shortcut priority are respected.")
	return TRUE

/datum/unit_test/foundation/right_click_bodyscanner
	name = "FOUNDATION: Body scanner right-click always attempts eject"

/datum/unit_test/foundation/right_click_bodyscanner/start_test()
	var/turf/test_turf = get_safe_turf()
	var/mob/living/carbon/human/actor = new(test_turf)
	var/mob/living/carbon/human/occupant = new(test_turf)
	var/obj/machinery/bodyscanner/scanner = new(test_turf)
	usr = actor
	if(scanner.select_right_click_verb() != /obj/machinery/bodyscanner/verb/eject)
		fail("Scanner did not select eject.")
	occupant.forceMove(scanner)
	scanner.occupant = occupant
	scanner.locked = TRUE
	scanner.attack_hand_right(actor)
	if(scanner.occupant != occupant || occupant.loc != scanner)
		fail("Right-click bypassed the scanner lock.")
	scanner.locked = FALSE
	scanner.attack_hand_right(actor)
	if(scanner.occupant || occupant.loc != test_turf)
		fail("Right-click did not eject the scanner occupant.")
	scanner.attack_hand_right(actor)
	if(scanner.occupant || actor.loc != test_turf)
		fail("Right-click entered an empty scanner.")
	qdel(scanner)
	qdel(occupant)
	qdel(actor)
	if(!reported)
		pass("Scanner eject respects locks and never enters an empty scanner.")
	return TRUE

/mob/look_far_click_test
	var/look_far_attempts = 0
	var/ctrl_attempts = 0
	var/context_attempts = 0
	var/atom/look_far_clicked

/mob/look_far_click_test/LookFarClickOn(atom/target)
	look_far_attempts++
	look_far_clicked = target
	return FALSE

/mob/look_far_click_test/CtrlClickOn(atom/target)
	ctrl_attempts++

/mob/look_far_click_test/open_tile_context_menu(turf/tile, atom/clicked, params)
	context_attempts++

/datum/unit_test/foundation/look_far_dispatch
	name = "FOUNDATION: Ctrl-right-click looks far without invoking world actions"

/datum/unit_test/foundation/look_far_dispatch/start_test()
	var/turf/test_turf = get_safe_turf()
	var/mob/look_far_click_test/actor = new(test_turf)
	var/obj/right_click_test/shortcut/target = new(test_turf)
	actor.next_click = world.time - 1
	actor.ClickOn(target, "right=1;ctrl=1", actor, null)
	if(actor.look_far_attempts != 1 || actor.look_far_clicked != target || actor.ctrl_attempts || target.attempts)
		fail("Ctrl-right-click did not exclusively invoke look-far, or a rejected look-far fell through.")
	actor.next_click = world.time - 1
	actor.ClickOn(test_turf, "right=1;ctrl=1", actor, null)
	if(actor.look_far_attempts != 2 || actor.look_far_clicked != test_turf)
		fail("Ctrl-right-click did not accept a turf target.")
	actor.next_click = world.time - 1
	actor.ClickOn(target, "right=1;ctrl=1;shift=1", actor, null)
	if(actor.context_attempts != 1 || actor.look_far_attempts != 2 || target.attempts)
		fail("Shift-right-click lost context menu priority.")
	actor.next_click = world.time - 1
	actor.ClickOn(target, "ctrl=1", actor, null)
	if(actor.ctrl_attempts != 1 || actor.look_far_attempts != 2)
		fail("Ordinary Ctrl-click was redirected to look-far.")
	actor.next_click = world.time - 1
	actor.ClickOn(target, "right=1", actor, null)
	if(target.attempts != 10 || actor.look_far_attempts != 2)
		fail("Ordinary right-click lost its existing shortcut.")
	qdel(target)
	qdel(actor)
	if(!reported)
		pass("Look-far dispatch consumes rejected clicks and preserves other modifiers.")
	return TRUE

/datum/unit_test/foundation/look_far_cull_mask
	name = "FOUNDATION: Look-far cull mask retains body visibility across the shifted viewport"

/datum/unit_test/foundation/look_far_cull_mask/start_test()
	var/turf/body_turf = get_safe_turf()
	var/turf/eye_turf = get_step(body_turf, EAST)
	var/mob/viewer = new(body_turf)
	viewer.see_in_dark = 8
	var/list/visible = view(1, viewer)
	var/list/strips = get_los_cull_strips(eye_turf, 1, viewer, TRUE)
	var/hidden_tiles = 0
	var/visible_tiles = 0
	for(var/offset_y in -1 to 1)
		for(var/offset_x in -1 to 1)
			var/turf/tile = locate(eye_turf.x + offset_x, eye_turf.y + offset_y, eye_turf.z)
			var/is_hidden = FALSE
			for(var/atom/movable/los_strip/strip as anything in strips)
				var/matrix/strip_transform = strip.transform
				if(strip_transform.f == offset_y * world.icon_size && abs(offset_x * world.icon_size - strip_transform.c) < strip_transform.a * world.icon_size / 2)
					is_hidden = TRUE
					break
			var/expected_hidden = tile && !(tile in visible)
			if(is_hidden != expected_hidden)
				fail("Shifted viewport tile ([offset_x], [offset_y]) did not match character-based visibility.")
			if(expected_hidden)
				hidden_tiles++
			else if(tile)
				visible_tiles++
	if(!hidden_tiles || !visible_tiles)
		fail("The mask fixture did not exercise both hidden and visible tiles.")
	qdel(viewer)
	if(!reported)
		pass("Mask strips cover hidden tiles beyond the body footprint without hiding visible tiles.")
	return TRUE
