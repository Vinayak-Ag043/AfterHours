
extends Control

@onready var stats_label: Label = $CenterContainer/VBoxContainer/StatsLabel
@onready var reset_button: Button = $CenterContainer/VBoxContainer/ResetButton


func _ready() -> void:
	GameState.state_changed.connect(update_display)
	reset_button.pressed.connect(reset_test)
	GameState.reset_game()

	var prediction = GameState.get_snapshot()
	prediction["energy"] = 0

	assert(GameState.get_snapshot()["energy"] == 100)
	print("PASS: GameState snapshot is independent!")



func update_display() -> void:
	var stats: Dictionary = GameState.get_snapshot()

	stats_label.text = (
		"Time: " + GameState.get_time_text()
		+ "\nEnergy: " + str(stats["energy"])
		+ "\nFood: " + str(stats["food"])
		+ "\nMood: " + str(stats["mood"])
		+ "\nAssignment: " + str(stats["assignment"]) + "%"
		+ "\nSleep: " + str(stats["sleep_minutes"]) + " minutes"
		+ "\nRoommate: " + str(stats["roommate_mission"])
	)


func reset_test() -> void:
	GameState.reset_game()
