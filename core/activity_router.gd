
class_name ActivityRouter
extends RefCounted

# ==========================================
# AFTER HOURS - CENTRAL ACTIVITY ROUTER
# Checkpoint 3C
# ==========================================

# Returns instructions for the Main Controller.
# It does NOT change GameState.

static func get_route(activity_id: String) -> Dictionary:
	match activity_id:

		"study":
			return {
				"valid": true,
				"id": "study",
				"title": "Assignment Rush",
				"type": "minigame",
				"duration": 60,
				"scene": "res://minigames/assignment.tscn",
				"ready": true
			}

		"sleep":
			return {
				"valid": true,
				"id": "sleep",
				"title": "Sleep",
				"type": "direct",
				"duration": 120,
				"scene": "",
				"ready": true
			}

		"eat":
			return {
				"valid": true,
				"id": "eat",
				"title": "Eat at Mess",
				"type": "direct",
				"duration": 30,
				"scene": "",
				"ready": true
			}

		"socialize":
			return {
				"valid": true,
				"id": "socialize",
				"title": "Hang Out With Friends",
				"type": "direct",
				"duration": 30,
				"scene": "",
				"ready": true
			}

		"badminton":
			return {
				"valid": true,
				"id": "badminton",
				"title": "Badminton Match",
				"type": "minigame",
				"duration": 60,
				"scene": "",
				"ready": false
			}

		"bucket_fight":
			return {
				"valid": true,
				"id": "bucket_fight",
				"title": "Hostel Bucket Fight",
				"type": "minigame",
				"duration": 30,
				"scene": "",
				"ready": false
			}

		"lawn_walk":
			return {
				"valid": true,
				"id": "lawn_walk",
				"title": "Main Building Lawn",
				"type": "minigame",
				"duration": 30,
				"scene": "",
				"ready": false
			}

		_:
			return {
				"valid": false,
				"id": activity_id,
				"title": "Unknown Activity",
				"type": "none",
				"duration": 0,
				"scene": "",
				"ready": false
			}


static func is_supported(activity_id: String) -> bool:
	return bool(get_route(activity_id)["valid"])
