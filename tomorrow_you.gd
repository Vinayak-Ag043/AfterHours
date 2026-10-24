
extends Control

signal confirm_requested
signal preview_closed

@onready var action_label: Label = $CenterContainer/PhonePanel/PhoneLayout/ActionLabel
@onready var time_label: Label = $CenterContainer/PhonePanel/PhoneLayout/TimeLabel
@onready var warning_label: Label = $CenterContainer/PhonePanel/PhoneLayout/WarningLabel
@onready var energy_name: Label = $CenterContainer/PhonePanel/PhoneLayout/StatsGrid/EnergyName
@onready var energy_before: Label = $CenterContainer/PhonePanel/PhoneLayout/StatsGrid/EnergyBefore
@onready var energy_after: Label = $CenterContainer/PhonePanel/PhoneLayout/StatsGrid/EnergyAfter

@onready var food_name: Label = $CenterContainer/PhonePanel/PhoneLayout/StatsGrid/FoodName
@onready var food_before: Label = $CenterContainer/PhonePanel/PhoneLayout/StatsGrid/FoodBefore
@onready var food_after: Label = $CenterContainer/PhonePanel/PhoneLayout/StatsGrid/FoodAfter

@onready var mood_name: Label = $CenterContainer/PhonePanel/PhoneLayout/StatsGrid/MoodName
@onready var mood_before: Label = $CenterContainer/PhonePanel/PhoneLayout/StatsGrid/MoodBefore
@onready var mood_after: Label = $CenterContainer/PhonePanel/PhoneLayout/StatsGrid/MoodAfter
@onready var confirm_button: Button = $CenterContainer/PhonePanel/PhoneLayout/ConfirmButton
@onready var close_button: Button = $CenterContainer/PhonePanel/PhoneLayout/CloseButton

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	close_button.pressed.connect(_on_close_pressed)
	visible = false

func show_preview(preview_data: Dictionary) -> void:
	action_label.text = str(preview_data.get("action", "Proposed action"))
	time_label.text = "Time remaining: " + str(preview_data.get("time_remaining", "—"))

	energy_name.text = "Energy"
	energy_before.text = str(preview_data.get("energy_before", "—"))
	energy_after.text = str(preview_data.get("energy_after", "—"))

	food_name.text = "Food"
	food_before.text = str(preview_data.get("food_before", "—"))
	food_after.text = str(preview_data.get("food_after", "—"))

	mood_name.text = "Mood"
	mood_before.text = str(preview_data.get("mood_before", "—"))
	mood_after.text = str(preview_data.get("mood_after", "—"))

	warning_label.text = str(preview_data.get("warning", "No warnings."))
	visible = true

func _on_confirm_pressed() -> void:
	confirm_requested.emit()

func _on_close_pressed() -> void:
	visible = false
	preview_closed.emit()
