
class_name ActivityRules
extends RefCounted


static func evaluate(
	snapshot: Dictionary,
	activity_id: String,
	duration_minutes: int,
	context: Dictionary = {}
) -> Dictionary:

	var next_state: Dictionary = snapshot.duplicate(true)

	if activity_id != "study":
		return {
			"valid": false,
			"reason": "Unknown activity",
			"next_state": next_state,
			"changes": {}
		}

	if duration_minutes != 60:
		return {
			"valid": false,
			"reason": "Study must last 60 minutes",
			"next_state": next_state,
			"changes": {}
		}

	if int(snapshot["time_minutes"]) + 60 > 1860:
		return {
			"valid": false,
			"reason": "Not enough time before 7 AM",
			"next_state": next_state,
			"changes": {}
		}

	next_state["time_minutes"] += 60

	next_state["energy"] = clampi(
		int(snapshot["energy"]) - 20,
		0,
		100
	)

	next_state["assignment"] = clampi(
		int(snapshot["assignment"]) + 25,
		0,
		100
	)

	var changes: Dictionary = {
		"time_minutes": 60,
		"energy": next_state["energy"] - snapshot["energy"],
		"assignment": next_state["assignment"] - snapshot["assignment"]
	}

	return {
		"valid": true,
		"reason": "",
		"next_state": next_state,
		"changes": changes
	}
