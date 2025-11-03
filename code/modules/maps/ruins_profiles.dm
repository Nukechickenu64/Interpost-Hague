// Ruins generation profiles: define terrain noise, clumping, and radii via datums

/datum/ruins_generation_profile
    var/name = "Default Ruins"
    // Perlin FBM params
    var/perlin_freq = 0.10
    var/perlin_octaves = 3
    var/perlin_persistence = 0.5
    var/perlin_lacunarity = 2.0
    var/perlin_scale = 100

    // Domain warp
    var/warp_amp = 0.08
    var/warp_freq = 0.5

    // Clumps
    var/clumps_min = 6
    var/clumps_max = 12

    // Radii tuning
    // base_r = max(4, round(min(width, height) / base_divisor))
    var/base_divisor = 10
    // rock radius scaled by random [rand_low..rand_high]% of base_r
    var/rand_low = 80
    var/rand_high = 130
    // Clamp rock radius
    var/rock_min = 4
    var/rock_max_frac = 0.25 // of min(width, height)
    // Floor ring is rock radius + max(2, round(base_r/floor_extra_div))
    var/floor_extra_div = 2

    // Optional smoothing passes (currently unused by generator but kept for future)
    var/smooth_passes = 0


/datum/ruins_generation_profile/default
    name = "Signal"

/datum/ruins_generation_profile/sparse
    name = "Sparse Signal"
    // Fewer, smaller clumps with less warp
    clumps_min = 4
    clumps_max = 7
    base_divisor = 12
    rand_low = 70
    rand_high = 110
    warp_amp = 0.05
    perlin_freq = 0.12

/datum/ruins_generation_profile/dense
    name = "Faint Signal"
    // More, larger clumps and stronger warp
    clumps_min = 8
    clumps_max = 16
    base_divisor = 8
    rand_low = 90
    rand_high = 140
    warp_amp = 0.10
    perlin_freq = 0.09

// Helper to get a random profile instance
/proc/pick_ruins_profile()
    var/list/types = subtypesof(/datum/ruins_generation_profile)
    // Ensure /default is favored if present
    var/type_to_make = /datum/ruins_generation_profile/default
    if(types && types.len)
        // Remove the base type
        types -= /datum/ruins_generation_profile
        if(types.len)
            type_to_make = pick(types)
    return new type_to_make

// Map human-friendly names to profile types for UI selection
/proc/get_ruins_profile_types()
    var/list/mapping = list()
    for(var/T in subtypesof(/datum/ruins_generation_profile))
        if(T == /datum/ruins_generation_profile)
            continue
        var/datum/ruins_generation_profile/P = new T
        var/label = P.name ? P.name : "[T]"
        mapping[label] = T
    return mapping
