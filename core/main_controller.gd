
extends Node3D

# ==========================================
# AFTER HOURS - MAIN CONTROLLER
# Checkpoint 3B.1 - World Integration
# ==========================================

signal activity_menu_requested(activity_id: String)
signal action_completed(result: Dictionary)
signal preview_ready(result: Dictionary)
signal minigame_requested(mode: String)

@export var show_debug_ui: bool = true

var _world: Node3D
var _status_label: Label
var _preview_label: Label


func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)
	GameState.game_finished.connect(_on_game_finished)

	_connect_world()

	if show_debug_ui:
		_create_debug_ui()
		_refresh_debug_ui()

	_run_startup_test()

	print("CHECKPOINT 3B: Main Controller ready!")


# ==========================================
# CONNECT WORLD SIGNAL
# ==========================================

func _connect_world() -> void:
	_world = get_node_or_null("World") as Node3D

	if _world == null:
		push_error("WORLD NOT FOUND! Check Main scene tree.")
		return

	print("PASS: World scene found!")

	if _world.has_signal("activity_requested"):
		_world.connect(
			"activity_requested",
			Callable(self, "request_activity")
		)

		print("PASS: World interaction signal connected!")
	else:
		push_error(
            "World does not have activity_requested signal!"
		)


# ==========================================
# HANDLE WORLD INTERACTION
# ==========================================

func request_activity(activity_id: String) -> void:
	print("WORLD REQUESTED ACTIVITY: ", activity_id)

	activity_menu_requested.emit(activity_id)

	if is_instance_valid(_preview_label):
		_preview_label.text = (
			"World interaction detected:\n" + activity_id
		)


# ==========================================
# ACTIVITY EXECUTION
# ==========================================

func choose_activity(
	activity_id: String,
	duration_minutes: int
) -> Dictionary:

	var result: Dictionary = GameState.try_action(
		activity_id,
		duration_minutes
	)

	if bool(result["valid"]):
		print("ACTIVITY COMPLETED: ", activity_id)
	else:
		print("REJECTED: ", result["reason"])

	action_completed.emit(result)
	return result


# ==========================================
# TOMORROW YOU
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
# MINIGAME HOOK
# ==========================================

func request_minigame(mode: String = "study") -> void:
	minigame_requested.emit(mode)


# ==========================================
# GAME STATE SIGNALS
# ==========================================

func _on_state_changed() -> void:
	_refresh_debug_ui()


func _on_game_finished(result: Dictionary) -> void:
	print("GAME FINISHED: ", result["title"])


# ==========================================
# DEBUG UI
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
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var heading: Label = Label.new()
	heading.text = "AFTER HOURS - WORLD INTEGRATION"
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
	preview_button.pressed.connect(_debug_preview_study)

	var wait_button: Button = Button.new()
	wait_button.text = "Wait - 30 Minutes"
	content.add_child(wait_button)
	wait_button.pressed.connect(
		func(): choose_activity("wait", 30)
	)

	var reset_button: Button = Button.new()
	reset_button.text = "Reset Game"
	content.add_child(reset_button)
	reset_button.pressed.connect(_debug_reset)

	_preview_label = Label.new()
	_preview_label.text = "Waiting for interaction..."
	content.add_child(_preview_label)


# ==========================================
# UPDATE HUD
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
		+ "\nAssignment: " + str(state["assignment"]) + "%"
		+ "\nSleep: " + str(state["sleep_minutes"]) + " min"
	)

	if bool(state["is_finished"]):
		_status_label.text += (
            "\n\nGAME OVER!"
			+ "\nEnding: " + str(state["ending"]["title"])
		)


# ==========================================
# DEBUG PREVIEW
# ==========================================

func _debug_preview_study() -> void:
	var before: Dictionary = GameState.get_snapshot()
	var result: Dictionary = request_preview("study", 60)

	if not bool(result["valid"]):
		_preview_label.text = (
			"Preview rejected: " + str(result["reason"])
		)
		return

	var future: Dictionary = result["next_state"]

	_preview_label.text = (
        "TOMORROW YOU PREDICTS:"
		+ "\nEnergy: " + str(future["energy"])
		+ "\nFood: " + str(future["food"])
		+ "\nAssignment: " + str(future["assignment"]) + "%"
	)

	assert(GameState.get_snapshot() == before)
	print("PASS: Preview did not modify GameState")


# ==========================================
# RESET
# ==========================================

func _debug_reset() -> void:
	GameState.reset_game()

	if is_instance_valid(_preview_label):
		_preview_label.text = "Waiting for interaction..."


# ==========================================
# STARTUP TEST
# ==========================================

func _run_startup_test() -> void:
	var before: Dictionary = GameState.get_snapshot()
	var result: Dictionary = request_preview("study", 60)

	assert(GameState.get_snapshot() == before)

	if bool(result["valid"]):
		print("PASS: Main Controller preview is read-only")
