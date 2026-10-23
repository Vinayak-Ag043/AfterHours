
extends Control

# ==========================================
# AFTER HOURS - CORE TEST
# Checkpoint 2C
# ==========================================

@onready var stats_label: Label = $CenterContainer/VBoxContainer/StatsLabel

@onready var study_button: Button = $CenterContainer/VBoxContainer/StudyButton
@onready var eat_button: Button = $CenterContainer/VBoxContainer/EatButton
@onready var sleep_button: Button = $CenterContainer/VBoxContainer/SleepButton
@onready var badminton_button: Button = $CenterContainer/VBoxContainer/BadmintonButton
@onready var socialize_button: Button = $CenterContainer/VBoxContainer/SocializeButton
@onready var wait_button: Button = $CenterContainer/VBoxContainer/WaitButton
@onready var reset_button: Button = $CenterContainer/VBoxContainer/ResetButton


# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:

	# Update UI whenever actual statistics change.
	GameState.state_changed.connect(update_display)

	# Connect all activity buttons.
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

	reset_button.pressed.connect(reset_test)

	# Start from clean statistics.
	GameState.reset_game()

	# Run automatic logic tests.
	test_snapshot_safety()
	test_all_activity_rules()
	test_exhaustion_penalty()
	test_invalid_action()

	update_display()

	print("================================")
	print("AFTER HOURS CORE TEST READY")
	print("All activity buttons connected!")
	print("================================")


# ==========================================
# DISPLAY STATISTICS
# ==========================================

func update_display() -> void:

	var stats: Dictionary = GameState.get_snapshot()

	stats_label.text = (
        "AFTER HOURS - PLAYER STATS"
		+ "\n"
		+ "\nTime: " + GameState.get_time_text()
		+ "\nEnergy: " + str(stats["energy"]) + "/100"
		+ "\nFood: " + str(stats["food"]) + "/100"
		+ "\nMood: " + str(stats["mood"]) + "/100"
		+ "\nAssignment: " + str(stats["assignment"]) + "%"
		+ "\nSleep: " + str(stats["sleep_minutes"]) + " minutes"
		+ "\nRoommate: " + str(stats["roommate_mission"])
	)


# ==========================================
# PERFORM ACTIVITY
# ==========================================

func perform_activity(
	activity_id: String,
	duration_minutes: int
) -> void:

	print("")
	print("ACTIVITY: ", activity_id)

	var result: Dictionary = GameState.try_action(
		activity_id,
		duration_minutes
	)

	if bool(result["valid"]):
		print("SUCCESS!")
		print("Changes: ", result["changes"])
		print("Current time: ", GameState.get_time_text())
	else:
		print("ACTIVITY REJECTED: ", result["reason"])


# ==========================================
# RESET GAME
# ==========================================

func reset_test() -> void:

	GameState.reset_game()

	print("")
	print("GAME RESET!")
	print("Time: ", GameState.get_time_text())


# ==========================================
# TEST 1 - SNAPSHOT SAFETY
# ==========================================

func test_snapshot_safety() -> void:

	var prediction: Dictionary = GameState.get_snapshot()

	prediction["energy"] = 0

	assert(
		int(GameState.get_snapshot()["energy"]) == 100
	)

	print("PASS: Snapshot safety")


# ==========================================
# TEST 2 - ALL ACTIVITY RULES
# ==========================================

func test_all_activity_rules() -> void:

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

		# Evaluating must not alter real GameState.
		assert(GameState.get_snapshot() == before)

		print("PASS: ", activity_id)


# ==========================================
# TEST 3 - EXHAUSTION PENALTY
# ==========================================

func test_exhaustion_penalty() -> void:

	var tired_student: Dictionary = GameState.get_snapshot()

	tired_student["energy"] = 10
	tired_student["food"] = 10

	var result: Dictionary = ActivityRules.evaluate(
		tired_student,
		"study",
		60
	)

	assert(bool(result["valid"]))

	assert(
		int(result["changes"]["assignment"]) == 8
	)

	# Real GameState must remain unchanged.
	assert(
		int(GameState.get_snapshot()["energy"]) == 100
	)

	print("PASS: Exhaustion penalty")


# ==========================================
# TEST 4 - INVALID ACTION
# ==========================================

func test_invalid_action() -> void:

	var before: Dictionary = GameState.get_snapshot()

	var result: Dictionary = ActivityRules.evaluate(
		before,
		"dance",
		60
	)

	assert(not bool(result["valid"]))

	assert(GameState.get_snapshot() == before)

	print("PASS: Invalid activity rejected")
