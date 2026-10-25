
class_name ActivityRules
extends RefCounted

# ==========================================
# AFTER HOURS - ACTIVITY RULES
# Checkpoint 2C
# ==========================================

const END_TIME: int = 1860


# Calculate an activity's consequences.
# This function DOES NOT modify the real GameState.
static func evaluate(
	snapshot: Dictionary,
	activity_id: String,
	duration_minutes: int,
	context: Dictionary = {}
) -> Dictionary:

	var next_state: Dictionary = snapshot.duplicate(true)

	# --------------------------------------
	# 1. Validate activity and duration
	# --------------------------------------

	var allowed_durations: Dictionary = {
		"study": [60],
		"eat": [30],
		"sleep": [60, 120, 180, 240],
		"badminton": [60],
		"socialize": [30],
		"wait": [30]
	}

	if not allowed_durations.has(activity_id):
		return _invalid(snapshot, "Unknown activity")

	if duration_minutes not in allowed_durations[activity_id]:
		return _invalid(snapshot, "Invalid activity duration")

	if int(snapshot["time_minutes"]) + duration_minutes > END_TIME:
		return _invalid(snapshot, "Not enough time before 7 AM")

	# --------------------------------------
	# 2. Save current statistics
	# --------------------------------------

	var old_energy: int = int(snapshot["energy"])
	var old_food: int = int(snapshot["food"])
	var old_mood: int = int(snapshot["mood"])
	var old_assignment: int = int(snapshot["assignment"])
	var old_sleep: int = int(snapshot["sleep_minutes"])

	# All activities advance time.
	next_state["time_minutes"] = (
		int(snapshot["time_minutes"]) + duration_minutes
	)

	# --------------------------------------
	# 3. Apply activity effects
	# --------------------------------------

	match activity_id:

		"study":
			var progress: int = 25

			# Lower efficiency when tired or hungry.
			if old_energy < 20 or old_food < 15:
				progress = 8
			elif old_energy < 50 or old_food < 30:
				progress = 15

			next_state["energy"] = clampi(
				old_energy - 20, 0, 100
			)

			next_state["food"] = clampi(
				old_food - 10, 0, 100
			)

			next_state["assignment"] = clampi(
				old_assignment + progress, 0, 100
			)

		"eat":
			next_state["food"] = clampi(
				old_food + 40, 0, 100
			)

			next_state["energy"] = clampi(
				old_energy + 10, 0, 100
			)

		"sleep":
			var recovered_energy: int = (
				duration_minutes / 60
			) * 25

			next_state["energy"] = clampi(
				old_energy + recovered_energy, 0, 100
			)

			next_state["food"] = clampi(
				old_food - (duration_minutes / 60) * 5,
				0, 100
			)

			next_state["sleep_minutes"] = (
				old_sleep + duration_minutes
			)

		"badminton":
			next_state["energy"] = clampi(
				old_energy - 25, 0, 100
			)

			next_state["food"] = clampi(
				old_food - 15, 0, 100
			)

			next_state["mood"] = clampi(
				old_mood + 20, 0, 100
			)

		"socialize":
			next_state["energy"] = clampi(
				old_energy - 5, 0, 100
			)

			next_state["mood"] = clampi(
				old_mood + 15, 0, 100
			)

		"wait":
			next_state["energy"] = clampi(
				old_energy - 5, 0, 100
			)

			next_state["food"] = clampi(
				old_food - 5, 0, 100
			)

	# --------------------------------------
	# 4. Calculate actual changes
	# --------------------------------------

	var changes: Dictionary = {
		"time_minutes": duration_minutes,
		"energy": int(next_state["energy"]) - old_energy,
		"food": int(next_state["food"]) - old_food,
		"mood": int(next_state["mood"]) - old_mood,
		"assignment": int(next_state["assignment"]) - old_assignment,
		"sleep_minutes": int(next_state["sleep_minutes"]) - old_sleep
	}

	return {
		"valid": true,
		"reason": "",
		"next_state": next_state,
		"changes": changes
	}


# Standard response for rejected actions.
static func _invalid(
	snapshot: Dictionary,
	reason: String
) -> Dictionary:

	return {
		"valid": false,
		"reason": reason,
		"next_state": snapshot.duplicate(true),
		"changes": {}
	}
