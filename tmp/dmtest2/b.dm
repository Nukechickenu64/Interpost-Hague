/datum/thing/Go()
	. = "SECOND(" + ..() + ")"

/world/New()
	var/datum/thing/T = new
	text2file("winner=[T.Go()]", "result.txt")
	del(world)
