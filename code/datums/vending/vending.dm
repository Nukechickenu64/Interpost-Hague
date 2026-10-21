#define CAT_NORMAL 1
#define CAT_HIDDEN 2  // also used in corresponding wires/vending.dm
#define CAT_SPECIAL   4

/**
 *  Datum used to hold information about a product in a vending machine
 */

/datum/stored_items/vending_products
	parent_type = /datum
	var/item_name = "generic"
	var/item_path
	var/charge_cost = 1
	var/display_color = null   // Display color for vending machine listing
	var/category = CAT_NORMAL  // CAT_HIDDEN for contraband, CAT_SPECIAL for premium

/datum/stored_items/vending_products/New(var/atom/storing_object, var/path, var/name = null)
	..()
	item_path = path
	var/atom/product_type = path
	item_name = name || initial(product_type.name)
