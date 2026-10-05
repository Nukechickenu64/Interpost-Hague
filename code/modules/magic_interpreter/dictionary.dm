// Spoken magic vocabulary. Each entry is list(category, payload).
// Latin words live in magic_dictionary; English aliases and engine names live in magic_aliases.
var/global/list/magic_dictionary
var/global/list/magic_aliases

var/global/list/magic_color_names = list(
	"red", "green", "blue", "yellow", "orange", "purple", "pink", "black",
	"white", "gray", "grey", "cyan", "magenta", "brown", "teal", "navy", "maroon", "olive", "lime", "silver"
)

/proc/build_magic_dictionary()
	magic_dictionary = list(
		"iacere" = list("modifier", "project"),
		"proicere" = list("modifier", "project"),
		"mittere" = list("modifier", "project"),
		"circum" = list("modifier", "area"),
		"ubique" = list("modifier", "area"),
		"omnes" = list("modifier", "area"),

		"ego" = list("target", "self"),
		"mihi" = list("target", "self"),
		"ipse" = list("target", "self"),
		"tact" = list("target", "held"),
		"manus" = list("target", "held"),
		"visus" = list("target", "visus"),
		"illud" = list("target", "visus"),
		"ille" = list("target", "visus"),

		"mutare" = list("operator", "="),
		"fiat" = list("operator", "="),
		"esto" = list("operator", "="),
		"plus" = list("operator", "+"),
		"auge" = list("operator", "+"),
		"magis" = list("operator", "+"),
		"minus" = list("operator", "-"),
		"minue" = list("operator", "-"),
		"deme" = list("operator", "-"),

		"nihil" = list("value", 0),
		"unus" = list("value", 1),
		"duo" = list("value", 2),
		"tres" = list("value", 3),
		"quattuor" = list("value", 4),
		"quinque" = list("value", 5),
		"sex" = list("value", 6),
		"septem" = list("value", 7),
		"octo" = list("value", 8),
		"novem" = list("value", 9),
		"decem" = list("value", 10),
		"undecim" = list("value", 11),
		"duodecim" = list("value", 12),
		"quindecim" = list("value", 15),
		"viginti" = list("value", 20),
		"quinquaginta" = list("value", 50),
		"centum" = list("value", 100),
		"ducenti" = list("value", 200),
		"mille" = list("value", 1000),
		"maximus" = list("value", 100),

		"rubrum" = list("value", "#ff0000"),
		"viride" = list("value", "#00ff00"),
		"caeruleum" = list("value", "#0000ff"),
		"nigrum" = list("value", "#000000"),
		"album" = list("value", "#ffffff"),
		"flavum" = list("value", "#ffff00"),
		"purpureum" = list("value", "#800080"),
		"croceum" = list("value", "#ff8c00"),
		"roseum" = list("value", "#ff69b4"),
		"griseum" = list("value", "#808080"),

		"ferrum" = list("material", "steel"),
		"vitrum" = list("material", "glass"),
		"aurum" = list("material", "gold"),
		"argentum" = list("material", "silver"),
		"lignum" = list("material", "wood"),
		"adamas" = list("material", "diamond"),
		"marmor" = list("material", "marble"),
		"chalybs" = list("material", "plasteel"),
		"corium" = list("material", "leather")
	)

	magic_aliases = list(
		"me" = list("target", "self"),
		"self" = list("target", "self"),
		"myself" = list("target", "self"),
		"usr" = list("target", "self"),
		"held" = list("target", "held"),
		"hand" = list("target", "held"),
		"this" = list("target", "held"),
		"that" = list("target", "visus"),
		"target" = list("target", "visus"),
		"there" = list("target", "visus"),

		"project" = list("modifier", "project"),
		"area" = list("modifier", "area"),

		"=" = list("operator", "="),
		"set" = list("operator", "="),
		"+" = list("operator", "+"),
		"add" = list("operator", "+"),
		"-" = list("operator", "-"),
		"sub" = list("operator", "-"),
		"subtract" = list("operator", "-")
	)

	var/list/properties = decls_repository.get_decls_of_subtype(/decl/magic_word/magic_property)
	for(var/path in properties)
		register_magic_words(properties[path], "property")

	var/list/actions = decls_repository.get_decls_of_subtype(/decl/magic_word/magic_action)
	for(var/path in actions)
		register_magic_words(actions[path], "action")

/proc/register_magic_words(decl/magic_word/D, category)
	for(var/word in D.words)
		magic_dictionary[word] = list(category, D)
	for(var/word in D.aliases)
		magic_aliases[word] = list(category, D)

/proc/magic_lookup(word)
	if(!magic_dictionary)
		build_magic_dictionary()
	. = magic_dictionary[word]
	if(!.)
		. = magic_aliases[word]

/proc/magic_is_latin(word)
	if(!magic_dictionary)
		build_magic_dictionary()
	return !!magic_dictionary[word]

/decl/magic_word
	var/name
	var/list/words = list()
	var/list/aliases = list()
	// Cosmetic effects are not written to the victim's attack log.
	var/cosmetic = FALSE
	var/accepts_turf = FALSE
