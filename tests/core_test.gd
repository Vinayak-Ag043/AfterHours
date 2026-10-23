
extends Control

# ==========================================
# AFTER HOURS - CORE TEST
# ==========================================

@onready var stats_label: Label = $CenterContainer/VBoxContainer/StatsLabel
@onready var reset_button: Button = $CenterContainer/VBoxContainer/ResetButton
@onready var study_button: Button = $CenterContainer/VBoxContainer/StudyButton


# Runs when the scene starts
func _ready() -> void:
	GameState.state_changed.connect(update_display)

	reset_button.pressed.connect(reset_test)
	study_button.pressed.connect(study_one_hour)

	GameState.reset_game()

	test_snapshot_safety()
	test_study_rules()

	update_display()

	print("Core test initialized successfully!")
	print("Study button connected!")


# Display current player statistics
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


# Called when StudyButton is clicked
func study_one_hour() -> void:
	print("STUDY BUTTON CLICKED!")

	var result: Dictionary = GameState.try_action(
		"study",
		60
	)

	if bool(result["valid"]):
		print("Study successful!")
		print("Changes: ", result["changes"])
	else:
		print("Study rejected: ", result["reason"])


# Called when ResetButton is clicked
func reset_test() -> void:
	GameState.reset_game()
	print("Game reset!")


# Verify snapshot safety
func test_snapshot_safety() -> void:
	var prediction: Dictionary = GameState.get_snapshot()
	prediction["energy"] = 0

	assert(GameState.get_snapshot()["energy"] == 100)
	print("PASS: Snapshot safety")


# Verify ActivityRules calculations
func test_study_rules() -> void:
	var before: Dictionary = GameState.get_snapshot()

	var result: Dictionary = ActivityRules.evaluate(
		before,
		"study",
		60
	)

	assert(bool(result["valid"]))
	assert(int(result["next_state"]["energy"]) == 80)
	assert(int(result["next_state"]["assignment"]) == 25)

	assert(GameState.get_snapshot() == before)

	print("PASS: Study calculation")
