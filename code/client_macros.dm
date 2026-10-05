/client
	control_freak = CONTROL_FREAK_ALL | CONTROL_FREAK_MACROS | CONTROL_FREAK_SKIN

/client/proc/route_airlock_keypad_digit(digit)
	if(!mob)
		return
	var/obj/machinery/airlock_keypad/keypad = mob.machine
	if(istype(keypad))
		keypad.press_digit(mob, digit)

/client/verb/airlock_keypad_digit_0()
	set name = ".airlock_keypad_digit_0"
	set hidden = 1
	route_airlock_keypad_digit("0")

/client/verb/airlock_keypad_digit_1()
	set name = ".airlock_keypad_digit_1"
	set hidden = 1
	route_airlock_keypad_digit("1")

/client/verb/airlock_keypad_digit_2()
	set name = ".airlock_keypad_digit_2"
	set hidden = 1
	route_airlock_keypad_digit("2")

/client/verb/airlock_keypad_digit_3()
	set name = ".airlock_keypad_digit_3"
	set hidden = 1
	route_airlock_keypad_digit("3")

/client/verb/airlock_keypad_digit_4()
	set name = ".airlock_keypad_digit_4"
	set hidden = 1
	route_airlock_keypad_digit("4")

/client/verb/airlock_keypad_digit_5()
	set name = ".airlock_keypad_digit_5"
	set hidden = 1
	route_airlock_keypad_digit("5")

/client/verb/airlock_keypad_digit_6()
	set name = ".airlock_keypad_digit_6"
	set hidden = 1
	route_airlock_keypad_digit("6")

/client/verb/airlock_keypad_digit_7()
	set name = ".airlock_keypad_digit_7"
	set hidden = 1
	route_airlock_keypad_digit("7")

/client/verb/airlock_keypad_digit_8()
	set name = ".airlock_keypad_digit_8"
	set hidden = 1
	route_airlock_keypad_digit("8")

/client/verb/airlock_keypad_digit_9()
	set name = ".airlock_keypad_digit_9"
	set hidden = 1
	route_airlock_keypad_digit("9")

/client/verb/airlock_keypad_cancel()
	set name = ".airlock_keypad_cancel"
	set hidden = 1
	if(mob)
		var/obj/machinery/airlock_keypad/keypad = mob.machine
		if(istype(keypad))
			keypad.clear_attempt(mob)

var/list/registered_macros_by_ckey_

// Disables click and double-click macros, as per http://www.byond.com/forum/?post=2219001
/mob/verb/DisableClick(argu = null as anything, sec = "" as text,number1 = 0 as num, number2 = 0 as num)
	set name = ".click"
	set category = null
	log_macro(ckey, ".click")

/mob/verb/DisableDblClick(argu = null as anything, sec = "" as text, number1 = 0 as num, number2 = 0 as num)
	set name = ".dblclick"
	set category = null
	log_macro(ckey, ".dblclick")

/proc/log_macro(var/ckey, var/macro)
	to_chat(usr, "The [macro] macro is disabled due to potential exploits.")
	if(is_macro_use_registered(ckey, macro))
		return
	register_macro_use(ckey, macro)
	log_and_message_admins("attempted to use the disabled [macro] macro.")

/proc/get_registered_macros()
	if(!registered_macros_by_ckey_)
		registered_macros_by_ckey_ = list()
	return registered_macros_by_ckey_

/proc/is_macro_use_registered(var/ckey, var/macro)
	var/list/registered_macros = get_registered_macros()[ckey]
	return registered_macros && (macro in registered_macros)

/proc/register_macro_use(var/ckey, var/macro)
	var/list/registered_macros_by_ckey = get_registered_macros()
	var/list/registered_macros = registered_macros_by_ckey[ckey]
	if(!registered_macros)
		registered_macros = list()
		registered_macros_by_ckey[ckey] = registered_macros
	registered_macros |= macro
