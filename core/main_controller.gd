
extends Node3D

# ==========================================
# AFTER HOURS - MAIN CONTROLLER
# Member 1 - Checkpoint 3A
# ==========================================

# Signals used by our teammates' modules.
signal activity_menu_requested(activity_id: String)
signal action_completed(result: Dictionary)
signal preview_ready(result: Dictionary)
signal minigame_requested(mode: String)

# This temporary interface lets us test integration
# before Member 2 and Member 3's scenes arrive.
@export var show_debug_ui: bool = true

var _status_label: Label
var _preview_label: Label


# ==========================================
# GAME STARTUP
# ==========================================

func _ready() -> void:
	GameState.state_changed.connect(
		_on_state_changed
	)

	GameState.game_finished.connect(
		_on_game_finished
	)

	if show_debug_ui:
		_create_debug_ui()
		_refresh_debug_ui()

	_run_startup_test()

	print("AFTER HOURS - Main Controller ready!")


# ==========================================
# WORLD -> CONTROLLER
# ==========================================

# Member 2 can call this when the player
# interacts with a desk, bed or NPC.
func request_activity(activity_id: String) -> void:
	print("World requested: ", activity_id)

	activity_menu_requested.emit(activity_id)


# ==========================================
# UI -> CONTROLLER -> GAME STATE
# ==========================================

# Member 3's activity menu can call this.
func choose_activity(
	activity_id: String,
	duration_minutes: int
) -> Dictionary:

	var result: Dictionary = GameState.try_action(
		activity_id,
		duration_minutes
	)

	if bool(result["valid"]):
		print(
			"Activity completed: ",
			activity_id
		)
		print("Changes: ", result["changes"])
	else:
		print(
			"Activity rejected: ",
			result["reason"]
		)

	action_completed.emit(result)

	return result


# ==========================================
# TOMORROW YOU -> PREVIEW
# ==========================================

func request_preview(
	activity_id: String,
	duration_minutes: int
) -> Dictionary:

	var result: Dictionary = GameState.preview_action(
		activity_id,
		duration_minutes
	)

	preview_ready.emit(result)

	return result


# ==========================================
# MINIGAME INTEGRATION
# ==========================================

# This signal will be wired to Member 4's
# Assignment Rush scene in a later step.
func request_minigame(mode: String = "study") -> void:
	minigame_requested.emit(mode)


# ==========================================
# GAME STATE SIGNALS
# ==========================================

func _on_state_changed() -> void:
	_refresh_debug_ui()


func _on_game_finished(result: Dictionary) -> void:
	print("")
	print("===== NIGHT COMPLETE =====")
	print("Ending: ", result["title"])
	print("Message: ", result["message"])
	print("==========================")


# ==========================================
# CREATE TEMPORARY DEBUG INTERFACE
# ==========================================

func _create_debug_ui() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "TemporaryDebugUI"
	add_child(canvas)

	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(400, 0)
	canvas.add_child(panel)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override(
		"separation", 10
	)
	panel.add_child(content)

	var heading: Label = Label.new()
	heading.text = "AFTER HOURS - INTEGRATION TEST"
	content.add_child(heading)

	_status_label = Label.new()
	content.add_child(_status_label)

	var study_button: Button = Button.new()
	study_button.text = "Study - 1 Hour"
	content.add_child(study_button)

	study_button.pressed.connect(
		func(): choose_activity("study", 60)
	)

	var preview_button: Button = Button.new()
	preview_button.text = "Tomorrow You - Preview Study"
	content.add_child(preview_button)

	preview_button.pressed.connect(
		_debug_preview_study
	)

	var wait_button: Button = Button.new()
	wait_button.text = "Wait - 30 Minutes"
	content.add_child(wait_button)

	wait_button.pressed.connect(
		func(): choose_activity("wait", 30)
	)

	var reset_button: Button = Button.new()
	reset_button.text = "Reset Game"
	content.add_child(reset_button)

	reset_button.pressed.connect(
		_debug_reset
	)

	_preview_label = Label.new()
	_preview_label.text = "No prediction yet."
	content.add_child(_preview_label)


# ==========================================
# UPDATE TEMPORARY INTERFACE
# ==========================================

func _refresh_debug_ui() -> void:
	if not is_instance_valid(_status_label):
		return

	var state: Dictionary = GameState.get_snapshot()

	_status_label.text = (
		"Time: " + GameState.get_time_text()
		+ "\nEnergy: " + str(state["energy"])
		+ "\nFood: " + str(state["food"])
		+ "\nMood: " + str(state["mood"])
		+ "\nAssignment: "
		+ str(state["assignment"]) + "%"
		+ "\nSleep: "
		+ str(state["sleep_minutes"]) + " min"
	)

	if bool(state["is_finished"]):
		_status_label.text += (
            "\n\nGAME OVER!"
			+ "\nEnding: "
			+ str(state["ending"]["title"])
		)


# ==========================================
# DEBUG - TOMORROW YOU
# ==========================================

func _debug_preview_study() -> void:
	var before: Dictionary = GameState.get_snapshot()

	var result: Dictionary = request_preview(
		"study",
		60
	)

	if not bool(result["valid"]):
		_preview_label.text = (
            "Preview rejected: "
			+ str(result["reason"])
		)
		return

	var future: Dictionary = result["next_state"]

	_preview_label.text = (
        "TOMORROW YOU PREDICTS:"
		+ "\nEnergy: " + str(future["energy"])
		+ "\nFood: " + str(future["food"])
		+ "\nAssignment: "
		+ str(future["assignment"]) + "%"
	)

	assert(GameState.get_snapshot() == before)

	print("PASS: Preview did not modify GameState")


# ==========================================
# DEBUG - RESET
# ==========================================

func _debug_reset() -> void:
	GameState.reset_game()
	_preview_label.text = "No prediction yet."


# ==========================================
# AUTOMATIC STARTUP VERIFICATION
# ==========================================

func _run_startup_test() -> void:
	var before: Dictionary = GameState.get_snapshot()

	var result: Dictionary = request_preview(
		"study",
		60
	)

	assert(bool(result["valid"]))
	assert(GameState.get_snapshot() == before)

	print("PASS: Main Controller communicates with GameState")
	print("PASS: Main Controller preview is read-only")
