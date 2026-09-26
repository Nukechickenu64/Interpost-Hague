/mob/living
	var/datum/quirk/quirk = null

/datum/quirk
	var/name = "quirk name"
	var/description = "quirk description"
	var/normal = 1 //If it's a "normal" quirk, then you can get it on roundstart. If it isn't, you get it by other means.

/datum/quirk/hypersensitive //Doubles mood values.
	name = "hypersensitive"
	description = "I'm more sensitive to good and bad moods than normal."

/datum/quirk/alcoholic //Starts out addicted to alcohol
	name = "alcoholic"
	description = "I need booze to be happy."

/datum/quirk/cig_addict //Starts out addicted to nicotine.
	name = "a smoker"
	description = "I need a smoke every now and then."

/datum/quirk/brave //Still gets moods, but is not bothered by them.
	name = "brave"
	description = "I'm not stressed by the harsh environments."
	normal = 0

/datum/quirk/no_bathroom //You'll never have to use the restroom.
	name = "bladderless"
	description = "I don't have to use the restroom."
	normal = 0

/datum/quirk/tough //Still feel pain, just not bothered by it as often.
	name = "tough"
	description = "I'm more pain resiliant than most."

/datum/quirk/weak //Removes two str
	name = "weak"
	description = "I'm not as strong as I should be."

/datum/quirk/strong //Adds two str
	name = "strong"
	description = "I'm stronger than I should be."

/datum/quirk/dead_inside //Gets no moods. Isn't bothered by anything.
	name = "dead inside"
	description = "I feel nothing anymore."
	normal = 0

/datum/quirk/psychopath //Shooting people boosts their mood.
	name = "psychopath"
	description = "I love killing people!"
	normal = 0

/datum/quirk/night_owl
	name = "night owl"
	description = "I feel most comfortable working during the station's quiet hours."

/datum/quirk/morning_person
	name = "morning person"
	description = "I am annoyingly cheerful at the start of a shift."

/datum/quirk/neat_freak
	name = "neat freak"
	description = "I cannot stand clutter when there is time to clean it."

/datum/quirk/pack_rat
	name = "pack rat"
	description = "I keep things that might become useful later."

/datum/quirk/forgetful
	name = "forgetful"
	description = "I lose track of small details unless I write them down."

/datum/quirk/superstitious
	name = "superstitious"
	description = "I take omens, lucky numbers, and unexplained coincidences seriously."

/datum/quirk/claustrophobic
	name = "claustrophobic"
	description = "Tight spaces make me deeply uncomfortable."

/datum/quirk/agoraphobic
	name = "agoraphobic"
	description = "Open spaces make me want to find a wall."

/datum/quirk/acrophobic
	name = "acrophobic"
	description = "I dislike being far above the ground."

/datum/quirk/arachnophobic
	name = "arachnophobic"
	description = "Spiders are not small or harmless as far as I am concerned."

/datum/quirk/photophobic
	name = "photophobic"
	description = "Bright lights give me headaches."

/datum/quirk/light_sleeper
	name = "light sleeper"
	description = "Every unusual noise wakes me up."

/datum/quirk/deep_sleeper
	name = "deep sleeper"
	description = "Once I am asleep, alarms have to work for it."

/datum/quirk/slow_reader
	name = "slow reader"
	description = "I need a little extra time to understand dense writing."

/datum/quirk/dyslexic
	name = "dyslexic"
	description = "Written instructions sometimes rearrange themselves in my head."

/datum/quirk/left_handed
	name = "left-handed"
	description = "I naturally reach for tools with my left hand."

/datum/quirk/colorblind
	name = "colorblind"
	description = "Some colors look frustratingly similar to me."

/datum/quirk/tinnitus
	name = "tinnitus"
	description = "There is a faint ringing in my ears that never quite leaves."

/datum/quirk/fidgety
	name = "fidgety"
	description = "Standing perfectly still takes conscious effort."

/datum/quirk/soft_spoken
	name = "soft-spoken"
	description = "People often ask me to repeat myself."

/datum/quirk/loud
	name = "loud"
	description = "I do not notice how much of the room my voice fills."

/datum/quirk/formal
	name = "formal"
	description = "I address coworkers as though every conversation were an official hearing."

/datum/quirk/contrarian
	name = "contrarian"
	description = "I instinctively question the obvious solution."

/datum/quirk/foodie
	name = "foodie"
	description = "A meal is an event, not just fuel."

/datum/quirk/tea_drinker
	name = "tea drinker"
	description = "A proper cup of tea can fix more problems than people expect."

/mob/living/proc/has_quirk(var/datum/quirk/this_quirk)
	return istype(quirk, this_quirk)

/mob/living/proc/set_quirk(var/datum/quirk/set_quirk)
	quirk = set_quirk

/mob/living/proc/remove_quirk()
	quirk = null