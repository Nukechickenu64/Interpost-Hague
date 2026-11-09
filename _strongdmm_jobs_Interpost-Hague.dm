// StrongDMM job definitions v1
// sdmm-jobs: {"Version":1,"Jobs":{"/datum/job/captain":{"Values":{},"Original":{"access":"list()","minimal_access":"list()"},"AccessOverride":true,"Access":[19,20],"Equipment":{}},"/datum/job/os13/captain":{"Values":{},"Original":{"access":"list()","minimal_access":"list()"},"AccessOverride":true,"Access":[19,20],"Equipment":{}},"/datum/job/os13/chief_engineer":{"Values":{},"Original":{"access":"list(10,11,23,12,13,32,24,14,18,19,56,61)","minimal_access":"list()"},"AccessOverride":true,"Access":[10,11,12,13,14,23,24,32,56,61],"Equipment":{}},"/datum/job/os13/cybertechnician":{"Values":{},"Original":{"access":"list(47,7,8,29,23,42)","minimal_access":"list()"},"AccessOverride":true,"Access":[7,8,23,29,42,47],"Equipment":{}},"/datum/job/os13/geneticist":{"Values":{},"Original":{"access":"list(5,66,6,9,47)","minimal_access":"list()"},"AccessOverride":true,"Access":[5,6,9,47,66],"Equipment":{}}}}
// Generated from the Job Editor. Keep project-specific job code in its original files.

/datum/job/captain
	access = list(19, 20)
	minimal_access = list(19, 20)

/datum/job/captain/get_access()
	return access.Copy()

/datum/job/os13/captain
	access = list(19, 20)
	minimal_access = list(19, 20)

/datum/job/os13/captain/get_access()
	return access.Copy()

/datum/job/os13/chief_engineer
	access = list(10, 11, 12, 13, 14, 23, 24, 32, 56, 61)
	minimal_access = list(10, 11, 12, 13, 14, 23, 24, 32, 56, 61)

/datum/job/os13/chief_engineer/get_access()
	return access.Copy()

/datum/job/os13/cybertechnician
	access = list(7, 8, 23, 29, 42, 47)
	minimal_access = list(7, 8, 23, 29, 42, 47)

/datum/job/os13/cybertechnician/get_access()
	return access.Copy()

/datum/job/os13/geneticist
	access = list(5, 6, 9, 47, 66)
	minimal_access = list(5, 6, 9, 47, 66)

/datum/job/os13/geneticist/get_access()
	return access.Copy()
