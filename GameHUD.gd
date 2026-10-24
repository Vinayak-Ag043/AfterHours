
extends Control

@onready var time_label: Label = $MarginContainer/MainLayout/TopRow/TimeLabel

@onready var energy_bar: ProgressBar = $MarginContainer/MainLayout/StatsRow/EnergyColumn/ProgressBar
@onready var food_bar: ProgressBar = $MarginContainer/MainLayout/StatsRow/FoodColumn/ProgressBar
@onready var mood_bar: ProgressBar = $MarginContainer/MainLayout/StatsRow/MoodColumn/ProgressBar
@onready var assignment_bar: ProgressBar = $MarginContainer/MainLayout/StatsRow/AssignmentColumn/ProgressBar

@onready var energy_label: Label = $MarginContainer/MainLayout/StatsRow/EnergyColumn/Label
@onready var food_label: Label = $MarginContainer/MainLayout/StatsRow/FoodColumn/Label
@onready var mood_label: Label = $MarginContainer/MainLayout/StatsRow/MoodColumn/Label
@onready var assignment_label: Label = $MarginContainer/MainLayout/StatsRow/AssignmentColumn/Label
@onready var sleep_label: Label = $MarginContainer/MainLayout/StatsRow/SleepColumn/Label


func _ready() -> void:
	update_hud({
		"time_minutes": 1080,
		"energy": 75,
		"food": 60,
		"mood": 80,
		"assignment": 40,
		"sleep_minutes": 120
	})


func update_hud(data: Dictionary) -> void:
	var minutes: int = int(data.get("time_minutes", 1080))
	var hour: int = int(minutes / 60) % 24
	var minute: int = minutes % 60
	var period: String = "AM" if hour < 12 else "PM"
	var display_hour: int = hour % 12
	if display_hour == 0:
		display_hour = 12

	time_label.text = "%d:%02d %s" % [display_hour, minute, period]

	var energy: float = float(data.get("energy", 0))
	var food: float = float(data.get("food", 0))
	var mood: float = float(data.get("mood", 0))
	var assignment: float = float(data.get("assignment", 0))
	var sleep_minutes: int = int(data.get("sleep_minutes", 0))

	energy_bar.value = energy
	food_bar.value = food
	mood_bar.value = mood
	assignment_bar.value = assignment

	energy_label.text = "Energy: %d" % int(energy)
	food_label.text = "Food: %d" % int(food)
	mood_label.text = "Mood: %d" % int(mood)
	assignment_label.text = "Assignment: %d%%" % int(assignment)
	sleep_label.text = "Sleep: %dh %02dm" % [
		int(sleep_minutes / 60),
		sleep_minutes % 60
	]
