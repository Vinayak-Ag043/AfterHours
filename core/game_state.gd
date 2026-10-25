
extends Node

# ==========================================
# AFTER HOURS - GAME STATE
# Checkpoint 2D
# ==========================================

signal state_changed
signal game_finished(result: Dictionary)

const START_TIME: int = 1080  # 6:00 PM
const END_TIME: int = 1860    # 7:00 AM

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
		"is_finished": false,
		"ending": {}
	}

	state_changed.emit()


# ==========================================
# READ STATE SAFELY
# ==========================================

func get_snapshot() -> Dictionary:
	return _state.duplicate(true)


func get_time_text() -> String:
	return _format_time(int(_state["time_minutes"]))


func _format_time(time_minutes: int) -> String:
	var hour: int = (time_minutes / 60) % 24
	var minute: int = time_minutes % 60

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
# APPLY A REAL ACTIVITY
# ==========================================

func try_action(
	activity_id: String,
	duration_minutes: int,
	context: Dictionary = {}
) -> Dictionary:

	if bool(_state["is_finished"]):
		return _invalid_result(
			_state,
            "Game has already ended"
		)

	var result: Dictionary = ActivityRules.evaluate(
		get_snapshot(),
		activity_id,
		duration_minutes,
		context
	)

	if not bool(result["valid"]):
		return result

	# Commit the calculated state.
	_state = _finalize_state(
		result["next_state"]
	)

	# Include any finishing information.
	result["next_state"] = get_snapshot()
	result["ending"] = _state["ending"].duplicate(true)

	# Update HUD first.
	state_changed.emit()

	# Then announce the final result.
	if bool(_state["is_finished"]):
		game_finished.emit(
			_state["ending"].duplicate(true)
		)

	return result


# ==========================================
# TOMORROW YOU - PREVIEW AN ACTIVITY
# ==========================================

func preview_action(
	activity_id: String,
	duration_minutes: int,
	context: Dictionary = {}
) -> Dictionary:

	if bool(_state["is_finished"]):
		return _invalid_result(
			_state,
            "Game has already ended"
		)

	# Evaluate a COPY of the state.
	var result: Dictionary = ActivityRules.evaluate(
		get_snapshot(),
		activity_id,
		duration_minutes,
		context
	)

	if not bool(result["valid"]):
		return result

	# Calculate a possible ending on the copy.
	# Do NOT assign this copy to _state.
	var predicted_state: Dictionary = _finalize_state(
		result["next_state"]
	)

	result["next_state"] = predicted_state
	result["ending"] = predicted_state["ending"].duplicate(true)

	return result


# ==========================================
# SHARED DEADLINE HANDLING
# ==========================================

func _finalize_state(
	candidate_state: Dictionary
) -> Dictionary:

	var finalized: Dictionary = candidate_state.duplicate(true)

	if int(finalized["time_minutes"]) >= END_TIME:
		finalized["is_finished"] = true
		finalized["ending"] = _calculate_ending(finalized)

	return finalized


# ==========================================
# FINAL ENDING CALCULATION
# ==========================================

func _calculate_ending(
	final_state: Dictionary
) -> Dictionary:

	var assignment: int = int(
		final_state["assignment"]
	)

	var sleep_minutes: int = int(
		final_state["sleep_minutes"]
	)

	var mood: int = int(
		final_state["mood"]
	)

	var title: String = ""
	var message: String = ""

	if assignment >= 100 and sleep_minutes >= 120:
		title = "Balanced Survivor"
		message = "You finished your work and got some rest!"

	elif assignment >= 100:
		title = "Academic Warrior"
		message = "Assignments done, but you sacrificed sleep."

	elif sleep_minutes >= 240:
		title = "Well Rested, Not Ready"
		message = "You slept well, but some work remains."

	else:
		title = "Chaotic Hostel Night"
		message = "Morning arrived before everything was done."

	# Mood contributes a simple extra observation.
	if mood >= 70:
		message += " At least you had a good time!"

	return {
		"title": title,
		"message": message,
		"assignment": assignment,
		"sleep_minutes": sleep_minutes,
		"mood": mood
	}


# ==========================================
# STANDARD INVALID RESULT
# ==========================================

func _invalid_result(
	snapshot: Dictionary,
	reason: String
) -> Dictionary:

	return {
		"valid": false,
		"reason": reason,
		"next_state": snapshot.duplicate(true),
		"changes": {},
		"ending": {}
	}
