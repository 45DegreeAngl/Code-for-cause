@tool
extends WorldEnvironment
## Manages the sky shader, with an option to set the moon phase
## to the real-world date ONCE when the scene starts.

var sky_material: ShaderMaterial

@export_group("Real Time Sync")
## If true, the script will set the moon phase based on the system clock
## when the scene starts, then do nothing further.
@export var set_phase_on_ready: bool = false


func _ready()->void:
	sky_material = environment.sky.sky_material
	# If the feature is enabled and the material is linked, set the phase.
	if set_phase_on_ready and sky_material != null:
		var current_phase = get_moon_phase_int()
		sky_material.set_shader_parameter("moon_phase_int", current_phase)


## Calculates the current phase of the moon (0-31) based on the system date.
func get_moon_phase_int()->int:
	# Get the current UTC date and time from the system.
	var now: Dictionary = Time.get_datetime_dict_from_system(true)

	# --- Calculate Julian Day Number from current date ---
	var a: int = floor((14 - now.month) / 12.0)
	var y: int = now.year + 4800 - a
	var m: int = now.month + 12 * a - 3
	var day_fraction: float = (now.hour / 24.0) + (now.minute / 1440.0) + (now.second / 86400.0)
	var julian_day: float = now.day + day_fraction + floor((153 * m + 2) / 5.0) + 365 * y + floor(y / 4.0) - floor(y / 100.0) + floor(y / 400.0) - 32045.5

	# --- Compare to a known New Moon (the epoch) ---
	const EPOCH_JULIAN_DAY := 2451550.1 # Jan 6, 2000
	const LUNAR_CYCLE_DAYS := 29.530588853

	# --- Determine position in the cycle ---
	var days_since_epoch: float = julian_day - EPOCH_JULIAN_DAY
	var cycles: float = days_since_epoch / LUNAR_CYCLE_DAYS
	
	# ** FIX: Replaced shader function `fract()` with GDScript's `fposmod()`. **
	var cycle_position: float = fposmod(cycles, 1.0) # 0.0=New, 0.25=FirstQ, 0.5=Full

	# Map the cycle position [0.0, 1.0) to our integer phase [0, 31]
	var moon_phase_int: int = int(floor(cycle_position * 32.0))
	
	return clamp(moon_phase_int, 0, 31)
