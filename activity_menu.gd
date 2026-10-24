
extends Control

signal activity_selected(activity_id: String, duration_minutes: int)
signal preview_requested(activity_id: String, duration_minutes: int)

@onready var location_label: Label = $CenterContainer/MenuPanel/MenuLayout/LocationLabel
@onready var subtitle_label: Label = $CenterContainer/MenuPanel/MenuLayout/SubtitleLabel
@onready var action_list: VBoxContainer = $CenterContainer/MenuPanel/MenuLayout/ActionList
@onready var preview_button: Button = $CenterContainer/MenuPanel/MenuLayout/PreviewButton
@onready var cancel_button: Button = $CenterContainer/MenuPanel/MenuLayout/CancelButton

var current_activity_id: String = ""
var current_duration: int = 60

var locations: Dictionary = {
	"bed": {
		"title": "YOUR BED",
		"subtitle": "Recharge. Tomorrow is coming.",
		"actions": [
			{"text": "Sleep for 1 hour", "id": "sleep", "duration": 60},
			{"text": "Sleep for 2 hours", "id": "sleep", "duration": 120},
			{"text": "Sleep for 3 hours", "id": "sleep", "duration": 180}
		]
	},
	"study_table": {
		"title": "STUDY TABLE",
		"subtitle": "That assignment isn't finishing itself.",
		"actions": [
			{"text": "Start assignment", "id": "study", "duration": 60}
		]
	},
	"mess": {
		"title": "HOSTEL MESS",
		"subtitle": "Dinner before the mess closes.",
		"actions": [
			{"text": "Eat dinner", "id": "eat", "duration": 30}
		]
	},
	"sports_area": {
		"title": "SPORTS AREA",
		"subtitle": "One game. Or five.",
		"actions": [
			{"text": "Play badminton", "id": "badminton", "duration": 60}
		]
	},
	"roommate": {
		"title": "ROOMMATE'S ROOM",
		"subtitle": "Your roommate has a proposition.",
		"actions": [
			{"text": "Hang out", "id": "socialize", "duration": 30},
			{"text": "Help roommate", "id": "help_roommate", "duration": 30}
		]
	}
}


func _ready() -> void:
	preview_button.pressed.connect(_on_preview_pressed)
	cancel_button.pressed.connect(close_menu)
	visible = false


func show_activity(activity_id: String) -> void:
	if not locations.has(activity_id):
		push_warning("Unknown location: " + activity_id)
		return

	var location: Dictionary = locations[activity_id]

	location_label.text = location["title"]
	subtitle_label.text = location["subtitle"]

	for child in action_list.get_children():
		action_list.remove_child(child)
		child.queue_free()

	current_activity_id = ""
	preview_button.disabled = true

	for action in location["actions"]:
		var button := Button.new()
		button.text = action["text"]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		button.add_theme_font_override("font", preload("uid://cg5x5qspnwuqh"))
		button.add_theme_font_size_override("font_size", 18)

		var selected_id: String = action["id"]
		var selected_duration: int = action["duration"]

		button.pressed.connect(
			_on_action_pressed.bind(selected_id, selected_duration)
		)

		action_list.add_child(button)

	visible = true


func _on_action_pressed(activity_id: String, duration_minutes: int) -> void:
	current_activity_id = activity_id
	current_duration = duration_minutes

	preview_button.disabled = false

	activity_selected.emit(activity_id, duration_minutes)


func _on_preview_pressed() -> void:
	if current_activity_id == "":
		return

	preview_requested.emit(current_activity_id, current_duration)


func close_menu() -> void:
	visible = false
