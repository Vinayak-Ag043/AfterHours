
extends Node

signal state_changed
signal game_finished(result: Dictionary)

const START_TIME: int = 1080
const END_TIME: int = 1860

var _state: Dictionary = {}


func _ready() -> void:
	reset_game()


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


func get_snapshot() -> Dictionary:
	return _state.duplicate(true)


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
