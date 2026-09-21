// Dynamic State-Machine Framework – Tension & Catalyst System
// Defines and constants for the AI Director Engine

// Tension meter thresholds (0-100 scale)
#define TENSION_CALM        20
#define TENSION_RISING      40
#define TENSION_ELEVATED    60
#define TENSION_HIGH        80
#define TENSION_CRITICAL    95
#define TENSION_MAX         100

// Director states (state machine)
#define DIRECTOR_STATE_DORMANT     0  // Not yet active (pre-round or lobby)
#define DIRECTOR_STATE_MONITORING  1  // Baseline telemetry gathering
#define DIRECTOR_STATE_SIMMERING   2  // Tension rising, agendas/debts active
#define DIRECTOR_STATE_ESCALATING  3  // Catalyst events triggering
#define DIRECTOR_STATE_BOILING     4  // Boiling Point endgame
#define DIRECTOR_STATE_CONCLUDED   5  // Round is ending

// Telemetry categories
#define TELEMETRY_POWER_GRID       "power_grid"
#define TELEMETRY_ATMOS_INTEGRITY  "atmos_integrity"
#define TELEMETRY_SECURITY_ARRESTS "security_arrests"
#define TELEMETRY_LOYALTY          "loyalty"
#define TELEMETRY_STRUCTURAL       "structural_integrity"
#define TELEMETRY_COMMS_STATUS     "comms_status"
#define TELEMETRY_RESEARCH_THRESHOLD "research_threshold"
#define TELEMETRY_CREW_VITALITY    "crew_vitality"
#define TELEMETRY_DEATH_RATE       "death_rate"

// Catalyst event types
#define CATALYST_TACTICAL_STRIKE   "tactical_strike"
#define CATALYST_ANOMALY           "anomaly"
#define CATALYST_MUTINY            "mutiny"
#define CATALYST_INFILTRATION      "infiltration"
#define CATALYST_BIOHAZARD         "biohazard"

// Squad doctrine roles
#define SQUAD_ROLE_LEADER          "leader"
#define SQUAD_ROLE_EW              "electronic_warfare"
#define SQUAD_ROLE_HEAVY           "heavy_weapons"
#define SQUAD_ROLE_BREACHER        "breacher"
#define SQUAD_ROLE_MEDIC           "medic"

// Loyalty factions (fluid)
#define LOYALTY_NANOTRASEN         "nanotrasen"
#define LOYALTY_SYNDICATE          "syndicate"
#define LOYALTY_REVOLUTIONARY      "revolutionary"
#define LOYALTY_CULT               "cult"
#define LOYALTY_NEUTRAL            "neutral"

// Corporate profile types
#define PROFILE_AGENDA             "agenda"
#define PROFILE_DEBT               "debt"
#define PROFILE_CLEAN              "clean"

// Boiling Point scenarios
#define BOILING_REACTOR_MELTDOWN   "reactor_meltdown"
#define BOILING_HULL_FAILURE       "hull_failure"
#define BOILING_CORPORATE_LOCKDOWN "corporate_lockdown"

// Cooldowns (in ticks / deciseconds)
#define DIRECTOR_EVAL_INTERVAL     30 SECONDS
#define CATALYST_COOLDOWN          5 MINUTES
#define TELEMETRY_SAMPLE_INTERVAL  10 SECONDS