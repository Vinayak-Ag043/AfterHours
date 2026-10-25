
extends Node

# ==========================================
# AFTER HOURS - GAME STATE
# Member 1: Core Gameplay System
# ==========================================

# Signals
signal state_changed
signal game_finished(result: Dictionary)


# Game timing
const START_TIME: int = 1080  # 6:00 PM
const END_TIME: int = 1860    # 7:00 AM next day


# Stores all player statistics
var _state: Dictionary = {}


# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:
	reset_game()


# ==========================================
# RESET GAME
# ==========================================

func reset_game() -> void:
	_state = {
		"time_minutes": START_TIME,
		"energy": 100,
		"food": 100,
		"mood": 50,
		"assignment": 0,
		"sleep_minutes": 0,
		"roommate_mission": "not_started",
		"is_finished": false
	}

	state_changed.emit()


# ==========================================
# GET CURRENT GAME STATE
# ==========================================

func get_snapshot() -> Dictionary:
	# Return an independent copy
	return _state.duplicate(true)


# ==========================================
# CONVERT GAME TIME INTO READABLE FORMAT
# ==========================================

func get_time_text() -> String:
	var minutes: int = int(_state["time_minutes"])

	var hour: int = (minutes / 60) % 24
	var minute: int = minutes % 60

	var suffix: String = "AM"

	if hour >= 12:
		suffix = "PM"

	var display_hour: int = hour % 12

	if display_hour == 0:
		display_hour = 12

	return "%d:%02d %s" % [
		display_hour,
		minute,
		suffix
	]


# ==========================================
# PERFORM AN ACTIVITY
# ==========================================

func try_action(
	activity_id: String,
	duration_minutes: int,
	context: Dictionary = {}
) -> Dictionary:

	# Prevent activities after the game has ended
	if bool(_state["is_finished"]):
		return {
			"valid": false,
			"reason": "Game has already ended",
			"next_state": get_snapshot(),
			"changes": {}
		}

	# Ask ActivityRules to calculate consequences
	var result: Dictionary = ActivityRules.evaluate(
		get_snapshot(),
		activity_id,
		duration_minutes,
		context
	)

	# Reject invalid activities without changing stats
	if not bool(result["valid"]):
		return result

	# Apply calculated results to the actual game
	_state = result["next_state"].duplicate(true)

	# Notify HUD and other systems about changes
	state_changed.emit()

	return result
