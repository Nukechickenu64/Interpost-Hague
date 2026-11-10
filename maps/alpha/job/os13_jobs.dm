/datum/map/alpha
	default_job = "Cadet"
	allowed_jobs = list(
		/datum/job/os13/captain,
		/datum/job/os13/chief_engineer,
		/datum/job/os13/engineer,
		/datum/job/os13/marshal,
		/datum/job/os13/pilot,
		/datum/job/os13/geneticist,
		/datum/job/os13/medical_officer,
		/datum/job/os13/scientific_overseer,
		/datum/job/os13/cybertechnician,
		/datum/job/os13/psionic_counselor,
		/datum/job/os13/logistics_officer,
		/datum/job/os13/cadet
	)

/datum/job/os13
	total_positions = 1
	spawn_positions = 1
	supervisors = "the Captain"
	alt_titles = null
	outfit_type = /decl/hierarchy/outfit/job
	var/main_stat = STAT_IQ
	var/list/trained_skills = list()

/datum/job/os13/initialize_character(mob/living/carbon/human/H)
	. = ..()
	H.generate_stats(main_stat)
	H.generate_skills(trained_skills)
	return .

/datum/job/os13/captain
	title = "Captain"
	department = "Command"
	department_flag = COM
	head_position = TRUE
	req_admin_notify = TRUE
	supervisors = "Tri-Net corporate command"
	selection_color = "#1d1d4f"
	outfit_type = /decl/hierarchy/outfit/job/captain
	main_stat = STAT_PER
	trained_skills = list("melee", "ranged")
	job_desc = "Lead the crew, hold the briefing, prioritize research and coordinate the Marshal's investigation."

/datum/job/os13/captain/get_access()
	return get_all_station_access()

/datum/job/os13/chief_engineer
	title = "Chief Engineer"
	department = "Engineering"
	department_flag = ENG|COM
	head_position = TRUE
	selection_color = "#7f6e2c"
	outfit_type = /decl/hierarchy/outfit/job/engineering/chief_engineer
	main_stat = STAT_IQ
	trained_skills = list("engineering", "crafting", "mining")
	access = list(access_engine, access_engine_equip, access_tech_storage, access_maint_tunnels, access_external_airlocks, access_construction, access_atmospherics, access_emergency_storage, access_eva, access_heads, access_ce, access_tcomsat)
	job_desc = "Direct station repairs, restore power and atmosphere, maintain the solar arrays and assist the Pilot."

/datum/job/os13/engineer
	title = "Engineer"
	department = "Engineering"
	department_flag = ENG
	total_positions = 2
	spawn_positions = 2
	supervisors = "the Chief Engineer and the Captain"
	selection_color = "#5b4d20"
	outfit_type = /decl/hierarchy/outfit/job/engineering/engineer
	trained_skills = list("engineering", "crafting", "mining")
	access = list(access_engine, access_engine_equip, access_tech_storage, access_maint_tunnels, access_external_airlocks, access_construction, access_atmospherics, access_emergency_storage, access_eva, access_tcomsat)
	job_desc = "Repair station faults, seal hull breaches, service power and atmospherics, and help the Pilot."

/datum/job/os13/marshal
	title = "Marshal"
	department = "IntenSecure"
	department_flag = SEC
	selection_color = "#601c1c"
	outfit_type = /decl/hierarchy/outfit/job/security/detective
	main_stat = STAT_DX
	trained_skills = list("melee", "ranged", "unarmed", "shield")
	access = list(access_security, access_sec_doors, access_brig, access_armory, access_forensics_lockers, access_morgue, access_maint_tunnels, access_eva, access_external_airlocks)
	job_desc = "Investigate the sabotage, question suspects and protect the crew. You are the station's best-trained fighter."

/datum/job/os13/pilot
	title = "Pilot"
	department = "IntenSecure"
	department_flag = SEC|EXP
	selection_color = "#601c1c"
	outfit_type = /decl/hierarchy/outfit/job/cargo/mining
	main_stat = STAT_DX
	trained_skills = list("ranged", "mining", "engineering")
	access = list(access_security, access_sec_doors, access_eva, access_external_airlocks, access_maint_tunnels, access_mining, access_mining_station)
	job_desc = "Use the Scout to obtain resources, explore derelicts and answer distress signals. Take a beacon and spare oxygen."

/datum/job/os13/geneticist
	title = "Geneticist"
	department = "Medical"
	department_flag = MED
	selection_color = "#013d3b"
	outfit_type = /decl/hierarchy/outfit/job/medical/geneticist
	supervisors = "the Scientific Overseer and the Captain"
	trained_skills = list("medical", "science")
	access = list(access_medical, access_medical_equip, access_morgue, access_genetics, access_research)
	job_desc = "Recycle biomatter and clone crew members; work with the Counselor to train replacement bodies."

/datum/job/os13/medical_officer
	title = "Medical Officer"
	department = "Medical"
	department_flag = MED
	selection_color = "#013d3b"
	rankprefix = "Dr."
	outfit_type = /decl/hierarchy/outfit/job/medical/doctor
	trained_skills = list("medical", "surgery", "cleaning")
	access = list(access_medical, access_medical_equip, access_morgue, access_genetics, access_surgery, access_chemistry, access_virology, access_psychiatrist)
	job_desc = "Treat wounds and illness, perform surgery and implant replacement organs. Request chemical charges from Logistics."

/datum/job/os13/medical_officer/initialize_character(mob/living/carbon/human/H)
	. = ..()
	if(!H.internal_organs_by_name["os13_medvisor"])
		H.internal_organs_by_name["os13_medvisor"] = new /obj/item/organ/internal/os13_medvisor(H)
	return .

/datum/job/os13/scientific_overseer
	title = "Scientific Overseer"
	department = "Science"
	department_flag = SCI|COM
	head_position = TRUE
	selection_color = "#0055a1"
	rankprefix = "Dr."
	outfit_type = /decl/hierarchy/outfit/job/science/superviseur
	trained_skills = list("science", "crafting", "medical")
	access = list(access_research, access_tox, access_tox_storage, access_robotics, access_xenobiology, access_xenoarch, access_tech_storage, access_network, access_rd, access_heads, access_genetics)
	job_desc = "Direct the Cybertechnician, extract technologies onto diskettes and reclaim materials to fabricate equipment."

/datum/job/os13/cybertechnician
	title = "Cybertechnician"
	department = "Science"
	department_flag = SCI
	supervisors = "the Scientific Overseer"
	selection_color = "#006bca"
	outfit_type = /decl/hierarchy/outfit/job/science/scientist
	trained_skills = list("science", "engineering")
	access = list(access_research, access_tox, access_tox_storage, access_robotics, access_tech_storage, access_network)
	job_desc = "Enter the cyberdeck to recover blocked technologies. Avoid ICE and guardians, and bring the recovered disk to research."

/datum/job/os13/cybertechnician/initialize_character(mob/living/carbon/human/H)
	. = ..()
	if(!H.internal_organs_by_name["os13_neural_port"])
		H.internal_organs_by_name["os13_neural_port"] = new /obj/item/organ/internal/os13_neural_port(H)
	return .

/datum/job/os13/psionic_counselor
	title = "Psionic-Counselor"
	department = "Medical"
	department_flag = MED
	selection_color = "#633d63"
	outfit_type = /decl/hierarchy/outfit/job/medical/psychiatrist
	trained_skills = list("medical")
	access = list(access_medical, access_medical_equip, access_morgue, access_genetics, access_psychiatrist)
	job_desc = "Learn and transfer skills telepathically, sense emotions, read touched objects and treat posthibernational psychosis."

/datum/job/os13/psionic_counselor/initialize_character(mob/living/carbon/human/H)
	. = ..()
	H.os13_counselor = TRUE
	H.verbs |= /mob/living/carbon/human/proc/telepathic_training
	return .

/datum/job/os13/logistics_officer
	title = "Logistics Officer"
	department = "Supply"
	department_flag = SUP|SRV
	selection_color = "#515151"
	outfit_type = /decl/hierarchy/outfit/job/cargo/qm
	trained_skills = list("cooking", "cleaning", "gardening", "crafting")
	access = list(access_cargo, access_cargo_bot, access_qm, access_mailsorting, access_hydroponics, access_kitchen, access_bar, access_janitor, access_maint_tunnels)
	job_desc = "Cook, clean and deliver ChargeMaster refills; grow biomass for food and cloning, and restore water service."

/datum/job/os13/cadet
	title = "Cadet"
	department = "Civilian"
	department_flag = CIV
	selection_color = "#797979"
	ideal_character_age = 12
	outfit_type = /decl/hierarchy/outfit/job/os13_cadet
	main_stat = STAT_DX
	trained_skills = list("cleaning")
	access = list(access_maint_tunnels)
	job_desc = "Help the crew with errands. As a child, you can walk upright through crawlspaces. Bridge access must be granted by the Captain."

/datum/job/os13/cadet/initialize_character(mob/living/carbon/human/H)
	H.set_species(SPECIES_CHILD)
	return ..()

/datum/job/os13/cadet/equip_preview(mob/living/carbon/human/H, alt_title, datum/mil_branch/branch)
	H.set_species(SPECIES_CHILD)
	return ..()

/decl/hierarchy/outfit/job/os13_cadet
	name = "Cadet"
	uniform = /obj/item/clothing/under/os13_child/cadet
	shoes = /obj/item/clothing/shoes/os13_child
