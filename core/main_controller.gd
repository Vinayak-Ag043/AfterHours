
extends Node3D
const Router = preload("res://core/activity_router.gd")
# ==========================================
# AFTER HOURS - MAIN CONTROLLER
# Checkpoint 3C - Centralized Activity Routing
# ==========================================

signal activity_menu_requested(activity_id: String)
signal action_completed(result: Dictionary)
signal preview_ready(result: Dictionary)
signal minigame_requested(mode: String)

@export var show_debug_ui: bool = true

var _world: Node3D = null
var _status_label: Label = null
var _message_label: Label = null

var _minigame_layer: CanvasLayer = null
var _minigame_active: bool = false
var _active_activity: String = ""


# ==========================================
# STARTUP
# ==========================================

func _ready() -> void:
	GameState.state_changed.connect(_refresh_debug_ui)
	GameState.game_finished.connect(_on_game_finished)

	_connect_world()

	if show_debug_ui:
		_create_debug_ui()
		_refresh_debug_ui()

	_test_router()

	print("CHECKPOINT 3C: Activity Router ready!")


# ==========================================
# CONNECT WORLD
# ==========================================

func _connect_world() -> void:
	_world = get_node_or_null("World") as Node3D

	if _world == null:
		push_warning("World not found under Main.")
		return

	print("PASS: World found!")

	if _world.has_signal("activity_requested"):
		_world.connect(
			"activity_requested",
			Callable(self, "request_activity")
		)
		print("PASS: World signal connected!")
	else:
		push_warning("World activity_requested signal missing.")


# ==========================================
# CENTRAL ENTRY POINT
# ==========================================

func request_activity(activity_id: String) -> void:
	if _minigame_active:
		return

	if bool(GameState.get_snapshot()["is_finished"]):
		_show_message("The night has ended!")
		return

	var route: Dictionary = Router.get_route(
		activity_id
	)

	if not bool(route["valid"]):
		_show_message("Unknown activity: " + activity_id)
		return

	print("ROUTER RECEIVED: ", activity_id)

	activity_menu_requested.emit(activity_id)

	# Member 3's future UI will replace
	# this temporary automatic confirmation.
	execute_route(activity_id)


# ==========================================
# EXECUTE ROUTED ACTIVITY
# ==========================================

func execute_route(activity_id: String) -> void:
	if _minigame_active:
		return

	var route: Dictionary = Router.get_route(
		activity_id
	)

	if not bool(route["valid"]):
		_show_message("Invalid activity!")
		return

	if not bool(route["ready"]):
		_show_message(
			str(route["title"])
			+ " is not integrated yet."
		)
		print("PENDING MINIGAME: ", activity_id)
		return

	var duration: int = int(route["duration"])

	var preview: Dictionary = GameState.preview_action(
		activity_id,
		duration
	)

	if not bool(preview["valid"]):
		_show_message(str(preview["reason"]))
		return

	match str(route["type"]):
		"direct":
			choose_activity(activity_id, duration)

		"minigame":
			_launch_minigame(route)

		_:
			_show_message("Unsupported route type.")


# ==========================================
# APPLY DIRECT ACTIVITY
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
		print("Changes: ", result["changes"])

		_show_message(
			"Completed: " + activity_id
		)
	else:
		print("ACTIVITY REJECTED: ", result["reason"])
		_show_message(str(result["reason"]))

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
# MINIGAME LAUNCHER
# ==========================================

func request_minigame(mode: String = "study") -> void:
	execute_route(mode)


func _launch_minigame(route: Dictionary) -> void:
	if _minigame_active:
		return

	var scene_path: String = str(route["scene"])

	if not ResourceLoader.exists(scene_path):
		_show_message("Minigame scene is missing!")
		push_warning("Missing scene: " + scene_path)
		return

	var packed_scene: PackedScene = load(
		scene_path
	) as PackedScene

	if packed_scene == null:
		_show_message("Cannot load minigame scene!")
		return

	var game_node: Node = packed_scene.instantiate()

	if not game_node is Control:
		push_error("Minigame root must be Control.")
		game_node.queue_free()
		return

	if not game_node.has_signal("minigame_finished"):
		push_error("Minigame completion signal is missing.")
		game_node.queue_free()
		return

	_minigame_active = true
	_active_activity = str(route["id"])

	minigame_requested.emit(_active_activity)

	_set_world_movement(false)

	_minigame_layer = CanvasLayer.new()
	_minigame_layer.name = "MinigameLayer"
	_minigame_layer.layer = 10
	add_child(_minigame_layer)

	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.04, 0.06, 0.10, 0.97)
	overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_minigame_layer.add_child(overlay)

	game_node.connect(
		"minigame_finished",
		Callable(self, "_on_minigame_finished")
	)

	overlay.add_child(game_node)

	var game_control: Control = game_node as Control
	game_control.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# The existing Assignment Rush initializes
	# itself through _ready() when added.
	print("MINIGAME OPENED: ", _active_activity)


# ==========================================
# MINIGAME COMPLETION
# ==========================================

func _on_minigame_finished(
	result: Dictionary
) -> void:
	if not _minigame_active:
		return

	var activity_id: String = _active_activity

	var completed: bool = bool(
		result.get("completed", false)
	)

	var score: int = int(
		result.get("score", 0)
	)

	var mode: String = str(
		result.get("mode", "")
	)

	print("MINIGAME FINISHED: ", result)

	# Prevent duplicate awards.
	_close_minigame()

	if not completed or score <= 0:
		_show_message("Minigame cancelled. No reward.")
		return

	if mode != activity_id:
		_show_message("Minigame result mode mismatch!")
		return

	# Currently only the completed Study
	# minigame has fully defined reward rules.
	if activity_id == "study" and score == 3:
		var route: Dictionary = Router.get_route(
			activity_id
		)

		choose_activity(
			activity_id,
			int(route["duration"])
		)

		print("PASS: Study reward applied once!")
	else:
		_show_message(
            "Result received. Rewards pending integration."
		)


# ==========================================
# CLOSE MINIGAME
# ==========================================

func _close_minigame() -> void:
	_minigame_active = false
	_active_activity = ""

	if is_instance_valid(_minigame_layer):
		_minigame_layer.queue_free()
		_minigame_layer = null

	if not bool(GameState.get_snapshot()["is_finished"]):
		_set_world_movement(true)


func _set_world_movement(enabled: bool) -> void:
	if is_instance_valid(_world):
		if _world.has_method("set_exploration_enabled"):
			_world.call(
				"set_exploration_enabled",
				enabled
			)


# ==========================================
# GAME OVER
# ==========================================

func _on_game_finished(result: Dictionary) -> void:
	print("GAME FINISHED: ", result["title"])
	_show_message(
		"7 AM - " + str(result["title"])
	)
	_set_world_movement(false)


# ==========================================
# TEMPORARY DEBUG UI
# ==========================================

func _create_debug_ui() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "TemporaryDebugUI"
	canvas.layer = 1
	add_child(canvas)

	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(380, 0)
	canvas.add_child(panel)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override(
		"separation", 8
	)
	panel.add_child(content)

	var heading: Label = Label.new()
	heading.text = "AFTER HOURS - ACTIVITY ROUTER"
	content.add_child(heading)

	_status_label = Label.new()
	content.add_child(_status_label)

	var activities: Array[String] = [
		"study",
		"sleep",
		"eat",
		"socialize",
		"badminton",
		"bucket_fight",
        "lawn_walk"
	]

	for activity_id in activities:
		var button: Button = Button.new()

		button.text = "Try: " + activity_id
		content.add_child(button)

		button.pressed.connect(
			request_activity.bind(activity_id)
		)

	var preview_button: Button = Button.new()
	preview_button.text = "Tomorrow You - Preview Study"
	content.add_child(preview_button)
	preview_button.pressed.connect(
		_debug_preview_study
	)

	var wait_button: Button = Button.new()
	wait_button.text = "Wait 30 Minutes"
	content.add_child(wait_button)
	wait_button.pressed.connect(
		func(): choose_activity("wait", 30)
	)

	var reset_button: Button = Button.new()
	reset_button.text = "Reset Game"
	content.add_child(reset_button)
	reset_button.pressed.connect(_debug_reset)

	_message_label = Label.new()
	_message_label.text = "Router ready."
	content.add_child(_message_label)


# ==========================================
# REFRESH DISPLAY
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


func _show_message(message: String) -> void:
	print("ROUTER: ", message)

	if is_instance_valid(_message_label):
		_message_label.text = message


# ==========================================
# DEBUG TOMORROW YOU
# ==========================================

func _debug_preview_study() -> void:
	var before: Dictionary = GameState.get_snapshot()

	var result: Dictionary = request_preview(
		"study",
		60
	)

	if not bool(result["valid"]):
		_show_message(str(result["reason"]))
		return

	var future: Dictionary = result["next_state"]

	_show_message(
        "TOMORROW YOU\n"
		+ "Energy: " + str(future["energy"])
		+ "\nFood: " + str(future["food"])
		+ "\nAssignment: "
		+ str(future["assignment"]) + "%"
	)

	assert(GameState.get_snapshot() == before)


# ==========================================
# DEBUG RESET
# ==========================================

func _debug_reset() -> void:
	if _minigame_active:
		_close_minigame()

	GameState.reset_game()
	_set_world_movement(true)

	_show_message("Game reset!")


# ==========================================
# ROUTER SELF-TEST
# ==========================================

func _test_router() -> void:
	var supported: Array[String] = [
		"study",
		"sleep",
		"eat",
		"socialize",
		"badminton",
		"bucket_fight",
        "lawn_walk"
	]

	for activity_id in supported:
		assert(Router.is_supported(activity_id))

	assert(not Router.is_supported("unknown"))

	print("PASS: All seven activity routes recognized!")
	print("PASS: Unknown activities rejected!")
