/datum/job/revolutionary
    title = "Revolutionary"
    supervisors = "the revolution"
    selection_color = "#dd5555"
    department_flag = CIV // treat as non-command crew for default systems; grouped via opposition flag
    total_positions = 3
    spawn_positions = 3
    minimal_player_age = 0
    account_allowed = 0
    announced = FALSE
    loadout_allowed = FALSE
    opposition = TRUE
    job_desc = "Fanatical insurgent opposed to the crew."

    // Keep access minimal; this is a hostile/opposition role, not standard crew
    minimal_access = list()
    access = list()

    // Assign dedicated outfit datum
    outfit_type = /decl/hierarchy/outfit/job/revolutionary

    equip(var/mob/living/carbon/human/H)
        ..()
        // Add light flavor or gear as needed later.
        H.generate_skills(list("melee","crafting"))