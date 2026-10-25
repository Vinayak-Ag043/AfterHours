
extends Control

signal play_again_requested

@onready var ending_title: Label = $CenterContainer/ResultPanel/ResultLayout/EndingTitle
@onready var summary_label: Label = $CenterContainer/ResultPanel/ResultLayout/SummaryLabel
@onready var energy_label: Label = $CenterContainer/ResultPanel/ResultLayout/EnergyLabel
@onready var food_label: Label = $CenterContainer/ResultPanel/ResultLayout/FoodLabel
@onready var mood_label: Label = $CenterContainer/ResultPanel/ResultLayout/MoodLabel
@onready var assignment_label: Label = $CenterContainer/ResultPanel/ResultLayout/AssignmentLabel
@onready var sleep_label: Label = $CenterContainer/ResultPanel/ResultLayout/SleepLabel
@onready var mission_label: Label = $CenterContainer/ResultPanel/ResultLayout/MissionLabel
@onready var play_again_button: Button = $CenterContainer/ResultPanel/ResultLayout/PlayAgainButton

func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again_pressed)
	visible = false

func show_results(result: Dictionary) -> void:
	ending_title.text = str(result.get("ending_title", "NIGHT COMPLETE"))
	summary_label.text = str(result.get("summary", "Your night at the hostel is over."))

	energy_label.text = "Energy: " + str(result.get("energy", "—"))
	food_label.text = "Food: " + str(result.get("food", "—"))
	mood_label.text = "Mood: " + str(result.get("mood", "—"))
	assignment_label.text = "Assignment: " + str(result.get("assignment", "—"))
	sleep_label.text = "Sleep: " + str(result.get("sleep_minutes", 0)) + " minutes"
	mission_label.text = "Roommate mission: " + str(result.get("roommate_mission", "—"))

	visible = true

func _on_play_again_pressed() -> void:
	play_again_requested.emit()
