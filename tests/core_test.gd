
extends Control

# ==========================================
# AFTER HOURS - CORE TEST
# Checkpoint 2D
# ==========================================

@onready var stats_label: Label = $CenterContainer/VBoxContainer/StatsLabel

@onready var study_button: Button = $CenterContainer/VBoxContainer/StudyButton
@onready var eat_button: Button = $CenterContainer/VBoxContainer/EatButton
@onready var sleep_button: Button = $CenterContainer/VBoxContainer/SleepButton
@onready var badminton_button: Button = $CenterContainer/VBoxContainer/BadmintonButton
@onready var socialize_button: Button = $CenterContainer/VBoxContainer/SocializeButton
@onready var wait_button: Button = $CenterContainer/VBoxContainer/WaitButton
@onready var preview_button: Button = $CenterContainer/VBoxContainer/PreviewButton
@onready var reset_button: Button = $CenterContainer/VBoxContainer/ResetButton


# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:

	GameState.state_changed.connect(update_display)
	GameState.game_finished.connect(on_game_finished)

	study_button.pressed.connect(
		func(): perform_activity("study", 60)
	)

	eat_button.pressed.connect(
		func(): perform_activity("eat", 30)
	)

	sleep_button.pressed.connect(
		func(): perform_activity("sleep", 120)
	)

	badminton_button.pressed.connect(
		func(): perform_activity("badminton", 60)
	)

	socialize_button.pressed.connect(
		func(): perform_activity("socialize", 30)
	)

	wait_button.pressed.connect(
		func(): perform_activity("wait", 30)
	)

	preview_button.pressed.connect(preview_study)
	reset_button.pressed.connect(reset_test)

	GameState.reset_game()

	# Automated verification.
	test_snapshot_safety()
	test_activity_rules()
	test_exhaustion_penalty()
	test_invalid_action()
	test_preview_safety()
	test_deadline_and_ending()

	# Restore the normal starting screen.
	GameState.reset_game()
	update_display()

	print("===============================")
	print("CHECKPOINT 2D READY!")
	print("===============================")


# ==========================================
# UPDATE SCREEN
# ==========================================

func update_display() -> void:

	var stats: Dictionary = GameState.get_snapshot()

	stats_label.text = (
        "AFTER HOURS - PLAYER STATS"
		+ "\n\nTime: " + GameState.get_time_text()
		+ "\nEnergy: " + str(stats["energy"]) + "/100"
		+ "\nFood: " + str(stats["food"]) + "/100"
		+ "\nMood: " + str(stats["mood"]) + "/100"
		+ "\nAssignment: " + str(stats["assignment"]) + "%"
		+ "\nSleep: " + str(stats["sleep_minutes"]) + " minutes"
		+ "\nRoommate: " + str(stats["roommate_mission"])
	)

	var finished: bool = bool(stats["is_finished"])

	# After 7 AM, prevent further actions.
	study_button.disabled = finished
	eat_button.disabled = finished
	sleep_button.disabled = finished
	badminton_button.disabled = finished
	socialize_button.disabled = finished
	wait_button.disabled = finished
	preview_button.disabled = finished

	if finished:
		var ending: Dictionary = stats["ending"]

		stats_label.text += (
            "\n\nGAME OVER - 7:00 AM"
			+ "\nEnding: " + str(ending["title"])
			+ "\n" + str(ending["message"])
		)


# ==========================================
# PERFORM A REAL ACTIVITY
# ==========================================

func perform_activity(
	activity_id: String,
	duration_minutes: int
) -> void:

	var result: Dictionary = GameState.try_action(
		activity_id,
		duration_minutes
	)

	if bool(result["valid"]):
		print(
			"ACTIVITY: ", activity_id,
			" | Changes: ", result["changes"]
		)
	else:
		print("REJECTED: ", result["reason"])


# ==========================================
# TOMORROW YOU PREVIEW
# ==========================================

func preview_study() -> void:

	var before: Dictionary = GameState.get_snapshot()

	var prediction: Dictionary = GameState.preview_action(
		"study",
		60
	)

	if not bool(prediction["valid"]):
		print("PREVIEW REJECTED: ", prediction["reason"])
		return

	var future: Dictionary = prediction["next_state"]

	print("")
	print("===== TOMORROW YOU =====")
	print("If you study for one hour:")
	print("Predicted energy: ", future["energy"])
	print("Predicted food: ", future["food"])
	print("Predicted assignment: ", future["assignment"], "%")
	print("Predicted changes: ", prediction["changes"])

	if bool(future["is_finished"]):
		print("Possible ending: ", future["ending"]["title"])

	# Prove that preview changed nothing.
	assert(GameState.get_snapshot() == before)

	print("Real GameState unchanged!")
	print("========================")


# ==========================================
# GAME ENDING SIGNAL
# ==========================================

func on_game_finished(result: Dictionary) -> void:
	print("")
	print("========== 7 AM ==========")
	print("GAME FINISHED!")
	print("Ending: ", result["title"])
	print("Message: ", result["message"])
	print("==========================")


# ==========================================
# RESET
# ==========================================

func reset_test() -> void:
	GameState.reset_game()
	print("GAME RESET!")


# ==========================================
# AUTOMATED TESTS
# ==========================================

func test_snapshot_safety() -> void:

	var snapshot: Dictionary = GameState.get_snapshot()
	snapshot["energy"] = 0

	assert(int(GameState.get_snapshot()["energy"]) == 100)

	print("PASS: Snapshot safety")


func test_activity_rules() -> void:

	var activities: Dictionary = {
		"study": 60,
		"eat": 30,
		"sleep": 120,
		"badminton": 60,
		"socialize": 30,
		"wait": 30
	}

	for activity_id in activities:
		var before: Dictionary = GameState.get_snapshot()

		var result: Dictionary = ActivityRules.evaluate(
			before,
			activity_id,
			activities[activity_id]
		)

		assert(bool(result["valid"]))
		assert(GameState.get_snapshot() == before)

	print("PASS: All six activity rules")


func test_exhaustion_penalty() -> void:

	var tired: Dictionary = GameState.get_snapshot()
	tired["energy"] = 10
	tired["food"] = 10

	var result: Dictionary = ActivityRules.evaluate(
		tired,
		"study",
		60
	)

	assert(int(result["changes"]["assignment"]) == 8)

	print("PASS: Exhaustion penalty")


func test_invalid_action() -> void:

	var before: Dictionary = GameState.get_snapshot()

	var result: Dictionary = GameState.try_action(
		"dance",
		60
	)

	assert(not bool(result["valid"]))
	assert(GameState.get_snapshot() == before)

	print("PASS: Invalid action rejected")


func test_preview_safety() -> void:

	var before: Dictionary = GameState.get_snapshot()

	var result: Dictionary = GameState.preview_action(
		"study",
		60
	)

	assert(bool(result["valid"]))
	assert(int(result["next_state"]["energy"]) == 80)
	assert(int(result["next_state"]["assignment"]) == 25)

	# Preview must not modify actual statistics.
	assert(GameState.get_snapshot() == before)

	print("PASS: Tomorrow You preview safety")


func test_deadline_and_ending() -> void:

	GameState.reset_game()

	# 13 hours = 780 minutes.
	# 26 wait actions of 30 minutes each.
	for i in range(26):
		var result: Dictionary = GameState.try_action(
			"wait",
			30
		)

		assert(bool(result["valid"]))

	var final_state: Dictionary = GameState.get_snapshot()

	assert(int(final_state["time_minutes"]) == 1860)
	assert(bool(final_state["is_finished"]))
	assert(not final_state["ending"].is_empty())

	# After the night ends, no more actions are allowed.
	var rejected: Dictionary = GameState.try_action(
		"study",
		60
	)

	assert(not bool(rejected["valid"]))

	print("PASS: Game ends at 7 AM")
	print("PASS: Activities blocked after 7 AM")

	GameState.reset_game()
