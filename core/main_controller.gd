
extends Node3D

# AFTER HOURS - MAIN CONTROLLER
# Checkpoint 3D.3 - Full UI Integration

const Router = preload("res://core/activity_router.gd")
const MENU_SCENE = preload("res://ui/activity_menu.tscn")
const PHONE_SCENE = preload("res://ui/tomorrow_you.tscn")

signal activity_menu_requested(activity_id: String)
signal action_completed(result: Dictionary)
signal preview_ready(result: Dictionary)
signal minigame_requested(mode: String)

@export var show_debug_ui: bool = true

var _world: Node3D = null
var _status_label: Label = null
var _message_label: Label = null

var _menu_layer: CanvasLayer = null
var _activity_menu: Control = null
var _menu_open: bool = false

var _phone_layer: CanvasLayer = null
var _phone: Control = null
var _phone_open: bool = false
var _pending_activity: String = ""
var _pending_duration: int = 0

var _minigame_layer: CanvasLayer = null
var _minigame_active: bool = false
var _active_activity: String = ""
var _active_duration: int = 0


# ==========================================
# STARTUP
# ==========================================

func _ready() -> void:
	GameState.state_changed.connect(_refresh_debug_ui)
	GameState.game_finished.connect(_on_game_finished)

	_connect_world()
	_create_activity_menu()
	_create_phone()

	if show_debug_ui:
		_create_debug_ui()
		_refresh_debug_ui()

	_test_router()
	print("CHECKPOINT 3D.3: Tomorrow You ready!")


# ==========================================
# CONNECT WORLD
# ==========================================

func _connect_world() -> void:
	_world = get_node_or_null("World") as Node3D

	if _world == null:
		push_warning("World not found under Main.")
		return

	if _world.has_signal("activity_requested"):
		_world.connect(
			"activity_requested",
			Callable(self, "request_activity")
		)
		print("PASS: World interactions connected!")
	else:
		push_warning("World activity signal missing!")


# ==========================================
# CREATE ACTIVITY MENU
# ==========================================

func _create_activity_menu() -> void:
	_menu_layer = CanvasLayer.new()
	_menu_layer.name = "ActivityMenuLayer"
	_menu_layer.layer = 5
	add_child(_menu_layer)

	_activity_menu = MENU_SCENE.instantiate() as Control

	if _activity_menu == null:
		push_error("Activity Menu root must be Control.")
		return

	_menu_layer.add_child(_activity_menu)
	_activity_menu.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_activity_menu.connect(
		"activity_selected",
		Callable(self, "_on_activity_confirmed")
	)
	_activity_menu.connect(
		"preview_requested",
		Callable(self, "_on_menu_preview_requested")
	)
	_activity_menu.connect(
		"activity_cancelled",
		Callable(self, "_on_activity_cancelled")
	)

	print("PASS: Activity Menu connected!")


# ==========================================
# CREATE TOMORROW YOU PHONE
# ==========================================

func _create_phone() -> void:
	_phone_layer = CanvasLayer.new()
	_phone_layer.name = "TomorrowYouLayer"
	_phone_layer.layer = 7
	add_child(_phone_layer)

	_phone = PHONE_SCENE.instantiate() as Control

	if _phone == null:
		push_error("Tomorrow You root must be Control.")
		return

	_phone_layer.add_child(_phone)
	_phone.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_phone.connect(
		"confirm_requested",
		Callable(self, "_on_phone_confirmed")
	)
	_phone.connect(
		"preview_closed",
		Callable(self, "_on_phone_closed")
	)

	print("PASS: Tomorrow You Phone connected!")


# ==========================================
# WORLD -> ACTIVITY MENU
# ==========================================

func request_activity(activity_id: String) -> void:
	if _menu_open or _phone_open or _minigame_active:
		return

	if bool(GameState.get_snapshot()["is_finished"]):
		_show_message("The night has ended!")
		return

	var location_map: Dictionary = {
		"study": "study_table",
		"sleep": "bed",
		"eat": "mess",
		"badminton": "sports_area",
		"socialize": "roommate",
		"bucket_fight": "common_area",
		"lawn_walk": "lawn"
	}

	if not location_map.has(activity_id):
		_show_message("Unknown location: " + activity_id)
		return

	if not is_instance_valid(_activity_menu):
		_show_message("Activity Menu missing!")
		return

	_menu_open = true
	_set_world_movement(false)

	activity_menu_requested.emit(activity_id)

	_activity_menu.call(
		"show_activity",
		str(location_map[activity_id])
	)

	print("MENU OPENED: ", activity_id)


# ==========================================
# MENU CONFIRM
# ==========================================

func _on_activity_confirmed(
	activity_id: String,
	duration_minutes: int
) -> void:
	if not _menu_open or _phone_open:
		return

	if not _is_action_available(
		activity_id,
		duration_minutes
	):
		return

	_hide_activity_menu(false)
	execute_route(activity_id, duration_minutes)

	_restore_exploration_if_safe()


# ==========================================
# MENU PREVIEW -> PHONE
# ==========================================

func _on_menu_preview_requested(
	activity_id: String,
	duration_minutes: int
) -> void:
	if not _menu_open or _phone_open:
		return

	if not _is_action_available(
		activity_id,
		duration_minutes
	):
		return

	var before: Dictionary = GameState.get_snapshot()

	var result: Dictionary = request_preview(
		activity_id,
		duration_minutes
	)

	if not bool(result["valid"]):
		_show_message(str(result["reason"]))
		return

	var after: Dictionary = result["next_state"]

	var remaining: int = max(
		0,
		GameState.END_TIME - int(after["time_minutes"])
	)

	var hours: int = int(remaining / 60)
	var minutes: int = remaining % 60

	var warning: String = "Predicted effects if completed."

	if activity_id == "study":
		warning = (
            "Study progress assumes you solve Assignment Rush."
		)
	elif int(after["energy"]) < 20:
		warning = "Warning: Energy will be very low."
	elif int(after["food"]) < 20:
		warning = "Warning: Food will be very low."

	if bool(after["is_finished"]):
		warning += " This activity ends the night."

	var display_data: Dictionary = {
		"action": activity_id.replace("_", " ").capitalize()
			+ " - " + str(duration_minutes) + " minutes",
		"time_remaining": "%dh %02dm" % [hours, minutes],
		"energy_before": before["energy"],
		"energy_after": after["energy"],
		"food_before": before["food"],
		"food_after": after["food"],
		"mood_before": before["mood"],
		"mood_after": after["mood"],
		"assignment_before": before["assignment"],
		"assignment_after": after["assignment"],
		"warning": warning
	}

	_pending_activity = activity_id
	_pending_duration = duration_minutes

	_activity_menu.hide()
	_phone_open = true

	_phone.call("show_preview", display_data)

	assert(GameState.get_snapshot() == before)

	print("PASS: Phone preview did not modify GameState!")


# ==========================================
# PHONE CLOSE -> RETURN TO MENU
# ==========================================

func _on_phone_closed() -> void:
	if not _phone_open:
		return

	_phone_open = false
	_pending_activity = ""
	_pending_duration = 0

	if _menu_open and is_instance_valid(_activity_menu):
		_activity_menu.show()
	else:
		_restore_exploration_if_safe()

	print("Tomorrow You closed. No stats changed.")


# ==========================================
# PHONE CONFIRM -> EXECUTE ACTIVITY
# ==========================================

func _on_phone_confirmed() -> void:
	if not _phone_open:
		return

	var activity_id: String = _pending_activity
	var duration: int = _pending_duration

	_phone_open = false
	_pending_activity = ""
	_pending_duration = 0

	if is_instance_valid(_phone):
		_phone.hide()

	_hide_activity_menu(false)

	if _is_action_available(activity_id, duration):
		execute_route(activity_id, duration)

	_restore_exploration_if_safe()


# ==========================================
# ACTIVITY MENU CLOSE
# ==========================================

func _on_activity_cancelled() -> void:
	_hide_activity_menu(true)
	_show_message("Activity cancelled.")


func _hide_activity_menu(
	restore_movement: bool = true
) -> void:
	_menu_open = false

	if is_instance_valid(_activity_menu):
		_activity_menu.hide()

	if restore_movement:
		_restore_exploration_if_safe()


func _restore_exploration_if_safe() -> void:
	if _menu_open or _phone_open or _minigame_active:
		return

	if bool(GameState.get_snapshot()["is_finished"]):
		return

	_set_world_movement(true)


# ==========================================
# VALIDATE ROUTE
# ==========================================

func _is_action_available(
	activity_id: String,
	duration_minutes: int
) -> bool:
	var route: Dictionary = Router.get_route(activity_id)

	if not bool(route["valid"]):
		_show_message("Unknown activity: " + activity_id)
		return false

	if not bool(route["ready"]):
		_show_message(str(route["title"]) + " is coming soon!")
		return false

	var result: Dictionary = GameState.preview_action(
		activity_id,
		duration_minutes
	)

	if not bool(result["valid"]):
		_show_message(str(result["reason"]))
		return false

	return true


# ==========================================
# CENTRAL ROUTER
# ==========================================

func execute_route(
	activity_id: String,
	duration_minutes: int = -1
) -> void:
	if _menu_open or _phone_open or _minigame_active:
		return

	var route: Dictionary = Router.get_route(activity_id)

	if not bool(route["valid"]) or not bool(route["ready"]):
		_show_message("Activity unavailable.")
		return

	var duration: int = duration_minutes

	if duration <= 0:
		duration = int(route["duration"])

	if not _is_action_available(activity_id, duration):
		return

	match str(route["type"]):
		"direct":
			choose_activity(activity_id, duration)

		"minigame":
			_launch_minigame(route, duration)

		_:
			_show_message("Unsupported activity type.")


# ==========================================
# APPLY ACTIVITY
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
		_show_message("Completed: " + activity_id)
	else:
		_show_message(str(result["reason"]))

	action_completed.emit(result)
	return result


# ==========================================
# PREVIEW ENGINE
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
# MINIGAME LAUNCH
# ==========================================

func request_minigame(mode: String = "study") -> void:
	execute_route(mode)


func _launch_minigame(
	route: Dictionary,
	duration_minutes: int
) -> void:
	if _minigame_active:
		return

	var scene_path: String = str(route["scene"])

	if not ResourceLoader.exists(scene_path):
		_show_message("Minigame scene missing!")
		return

	var packed: PackedScene = load(scene_path) as PackedScene

	if packed == null:
		_show_message("Minigame could not load.")
		return

	var game_node: Node = packed.instantiate()

	if not game_node is Control:
		push_error("Minigame root must be Control.")
		game_node.queue_free()
		return

	if not game_node.has_signal("minigame_finished"):
		push_error("Missing minigame_finished signal.")
		game_node.queue_free()
		return

	_minigame_active = true
	_active_activity = str(route["id"])
	_active_duration = duration_minutes

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

	print("MINIGAME OPENED: ", _active_activity)


# ==========================================
# MINIGAME RESULT
# ==========================================

func _on_minigame_finished(result: Dictionary) -> void:
	if not _minigame_active:
		return

	var activity_id: String = _active_activity
	var duration: int = _active_duration
	var completed: bool = bool(result.get("completed", false))
	var score: int = int(result.get("score", 0))
	var mode: String = str(result.get("mode", ""))

	_close_minigame()

	if not completed or score <= 0:
		_show_message("Minigame cancelled. No reward.")
		return

	if mode != activity_id:
		_show_message("Minigame result mode mismatch.")
		return

	if activity_id == "study" and score == 3:
		choose_activity("study", duration)
		print("PASS: Study awarded exactly once!")
	else:
		_show_message("Minigame reward not configured yet.")


func _close_minigame() -> void:
	_minigame_active = false
	_active_activity = ""
	_active_duration = 0

	if is_instance_valid(_minigame_layer):
		_minigame_layer.queue_free()
		_minigame_layer = null

	_restore_exploration_if_safe()


# ==========================================
# WORLD MOVEMENT
# ==========================================

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
	_show_message("7 AM: " + str(result["title"]))
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
	panel.position = Vector2(760, 90)
	panel.custom_minimum_size = Vector2(350, 0)
	canvas.add_child(panel)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override(
		"separation", 8
	)
	panel.add_child(content)

	var heading: Label = Label.new()
	heading.text = "AFTER HOURS - TEST CONTROLS"
	content.add_child(heading)

	_status_label = Label.new()
	content.add_child(_status_label)

	var activities: Array[String] = [
		"study", "sleep", "eat", "socialize",
		"badminton", "bucket_fight", "lawn_walk"
	]

	for activity_id in activities:
		var button: Button = Button.new()
		button.text = "Try: " + activity_id
		content.add_child(button)

		button.pressed.connect(
			execute_route.bind(activity_id, -1)
		)

	var reset_button: Button = Button.new()
	reset_button.text = "Reset Game"
	content.add_child(reset_button)
	reset_button.pressed.connect(_debug_reset)

	_message_label = Label.new()
	_message_label.text = "Ready for interactions."
	content.add_child(_message_label)


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


func _show_message(message: String) -> void:
	print("CONTROLLER: ", message)

	if is_instance_valid(_message_label):
		_message_label.text = message


func _debug_reset() -> void:
	if _minigame_active:
		_close_minigame()

	if _phone_open:
		_phone_open = false
		_pending_activity = ""
		_pending_duration = 0
		if is_instance_valid(_phone):
			_phone.hide()

	if _menu_open:
		_hide_activity_menu(false)

	GameState.reset_game()
	_set_world_movement(true)
	_show_message("Game reset!")


# ==========================================
# ROUTER SELF-TEST
# ==========================================

func _test_router() -> void:
	var supported: Array[String] = [
		"study", "sleep", "eat", "socialize",
		"badminton", "bucket_fight", "lawn_walk"
	]

	for activity_id in supported:
		assert(Router.is_supported(activity_id))

	assert(not Router.is_supported("unknown"))

	print("PASS: All seven activity routes recognized!")
