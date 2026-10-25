
extends Node3D

# AFTER HOURS - MAIN CONTROLLER
# Integrated submission version
# World + Story + Activity Menu + Tomorrow You
# Dialogue + Assignment Rush + Badminton + Ending

const Router = preload("res://core/activity_router.gd")
const MENU_SCENE = preload("res://ui/activity_menu.tscn")
const PHONE_SCENE = preload("res://ui/tomorrow_you.tscn")

signal activity_menu_requested(activity_id: String)
signal action_completed(result: Dictionary)
signal preview_ready(result: Dictionary)
signal minigame_requested(mode: String)

@export var show_debug_ui: bool = false

var _world: Node3D = null

var story_active: bool = false
var _story_intro: Control = null

var _activity_menu: Control = null
var _menu_open: bool = false

var _phone: Control = null
var _phone_open: bool = false
var _pending_activity: String = ""
var _pending_duration: int = 0

var _dialogue: Control = null
var _dialogue_open: bool = false
var _dialogue_source: String = ""

var _minigame_layer: CanvasLayer = null
var _minigame_active: bool = false
var _active_activity: String = ""
var _active_duration: int = 0

var _status_label: Label = null
var _message_label: Label = null


# =========================================
# STARTUP
# =========================================

func _ready() -> void:
    GameState.reset_game()

    GameState.state_changed.connect(_refresh_debug_ui)
    GameState.game_finished.connect(_on_game_finished)

    _connect_world()
    _create_activity_menu()
    _create_phone()
    _setup_dialogue()
    _setup_story()

    if show_debug_ui:
        _create_debug_ui()
        _refresh_debug_ui()

    if story_active:
        _set_world_movement(false)
    else:
        _restore_exploration_if_safe()

    print("AFTER HOURS: Controller ready")
    print("Time: ", GameState.get_time_text())
    print("Finished: ", GameState.get_snapshot().get("is_finished", false))


# =========================================
# WORLD
# =========================================

func _connect_world() -> void:
    _world = get_node_or_null("World") as Node3D

    if _world == null:
        push_error("World node missing in Main")
        return

    var callback: Callable = Callable(self, "request_activity")

    if _world.has_signal("activity_requested"):
        if not _world.is_connected("activity_requested", callback):
            _world.connect("activity_requested", callback)
    else:
        push_warning("World activity_requested signal missing")


func _set_world_movement(enabled: bool) -> void:
    if is_instance_valid(_world):
        if _world.has_method("set_exploration_enabled"):
            _world.call("set_exploration_enabled", enabled)


func _restore_exploration_if_safe() -> void:
    if story_active:
        return

    if _menu_open or _phone_open or _dialogue_open:
        return

    if _minigame_active:
        return

    if bool(GameState.get_snapshot().get("is_finished", false)):
        return

    _set_world_movement(true)


# =========================================
# OPENING STORY
# =========================================

func _setup_story() -> void:
    _story_intro = get_node_or_null("StoryIntro") as Control

    if _story_intro == null:
        story_active = false
        return

    var layer: CanvasLayer = CanvasLayer.new()
    layer.name = "OpeningStoryLayer"
    layer.layer = 20
    add_child(layer)

    _story_intro.reparent(layer, false)
    _story_intro.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )

    var callback: Callable = Callable(
        self,
        "_on_story_intro_finished"
    )

    if not _story_intro.is_connected("intro_finished", callback):
        _story_intro.connect("intro_finished", callback)

    story_active = true
    _story_intro.show()
    _set_world_movement(false)


func _on_story_intro_finished() -> void:
    if not story_active:
        return

    story_active = false

    if is_instance_valid(_story_intro):
        _story_intro.hide()

    print("STORY FINISHED")
    print("TIME: ", GameState.time_minutes)
    print("IS FINISHED: ", GameState.is_finished)

    _restore_exploration_if_safe()


# =========================================
# DIALOGUE
# =========================================

func _setup_dialogue() -> void:
    _dialogue = get_node_or_null(
        "DialogueLayer/DialoguePanel"
    ) as Control

    if _dialogue == null:
        return

    var choice_callback: Callable = Callable(
        self,
        "_on_dialogue_choice_selected"
    )

    if _dialogue.has_signal("choice_selected"):
        if not _dialogue.is_connected(
            "choice_selected",
            choice_callback
        ):
            _dialogue.connect(
                "choice_selected",
                choice_callback
            )

    var close_callback: Callable = Callable(
        self,
        "_on_dialogue_closed"
    )

    if _dialogue.has_signal("dialogue_closed"):
        if not _dialogue.is_connected(
            "dialogue_closed",
            close_callback
        ):
            _dialogue.connect(
                "dialogue_closed",
                close_callback
            )

    _dialogue.hide()


func _open_npc_dialogue(activity_id: String) -> void:
    if not is_instance_valid(_dialogue):
        _open_activity_menu(activity_id)
        return

    _dialogue_open = true
    _dialogue_source = activity_id

    _set_world_movement(false)

    var data: Dictionary = {}

    if activity_id == "socialize":
        data = {
            "event_id": "corridor_socialize",
            "character_name": "HOSTEL FRIEND",
            "text": "Bhai! Classes are over. Chill with us?",
            "choices": [
                {
                    "id": "socialize",
                    "text": "Hang out (30 min)"
                },
                {
                    "id": "leave",
                    "text": "Maybe later"
                }
            ]
        }

    elif activity_id == "bucket_fight":
        data = {
            "event_id": "corridor_bucket",
            "character_name": "CORRIDOR GANG",
            "text": "Oye! Bucket fight is starting. Joining?",
            "choices": [
                {
                    "id": "bucket_fight",
                    "text": "Join Bucket Fight"
                },
                {
                    "id": "socialize",
                    "text": "Just hang out"
                },
                {
                    "id": "leave",
                    "text": "Leave"
                }
            ]
        }

    _dialogue.call("show_event", data)


func _on_dialogue_choice_selected(
    event_id: String,
    choice_id: String
) -> void:
    if not _dialogue_open:
        return

    var source: String = _dialogue_source

    var expected: String = (
        "corridor_socialize"
        if source == "socialize"
        else "corridor_bucket"
    )

    _close_dialogue(false)

    if event_id != expected or choice_id == "leave":
        _restore_exploration_if_safe()
        return

    if choice_id == "socialize":
        _open_activity_menu("socialize")

    elif choice_id == "bucket_fight" and source == "bucket_fight":
        _open_activity_menu("bucket_fight")

    else:
        _restore_exploration_if_safe()


func _on_dialogue_closed() -> void:
    _close_dialogue()


func _close_dialogue(restore_movement: bool = true) -> void:
    _dialogue_open = false
    _dialogue_source = ""

    if is_instance_valid(_dialogue):
        _dialogue.hide()

    if restore_movement:
        _restore_exploration_if_safe()


# =========================================
# ACTIVITY MENU
# =========================================

func _create_activity_menu() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    layer.name = "ActivityMenuLayer"
    layer.layer = 5
    add_child(layer)

    _activity_menu = MENU_SCENE.instantiate() as Control

    if _activity_menu == null:
        push_error("Activity Menu root must be Control")
        return

    layer.add_child(_activity_menu)

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


func request_activity(activity_id: String) -> void:
    if story_active or _dialogue_open:
        return

    if _menu_open or _phone_open or _minigame_active:
        return

    if bool(GameState.get_snapshot().get("is_finished", false)):
        return

    if activity_id in ["socialize", "bucket_fight"]:
        _open_npc_dialogue(activity_id)
    else:
        _open_activity_menu(activity_id)


func _open_activity_menu(activity_id: String) -> void:
    var locations: Dictionary = {
        "study": "study_table",
        "sleep": "bed",
        "eat": "mess",
        "socialize": "roommate",
        "badminton": "sports_area",
        "bucket_fight": "common_area",
        "lawn_walk": "lawn"
    }

    if not locations.has(activity_id):
        _show_message("Unknown activity: " + activity_id)
        _restore_exploration_if_safe()
        return

    if not is_instance_valid(_activity_menu):
        _restore_exploration_if_safe()
        return

    _menu_open = true
    _set_world_movement(false)

    activity_menu_requested.emit(activity_id)

    _activity_menu.call(
        "show_activity",
        str(locations[activity_id])
    )


func _on_activity_confirmed(
    activity_id: String,
    duration_minutes: int
) -> void:
    if not _menu_open or _phone_open:
        return

    if not _is_action_available(activity_id, duration_minutes):
        return

    _hide_activity_menu(false)
    execute_route(activity_id, duration_minutes)
    _restore_exploration_if_safe()


func _on_activity_cancelled() -> void:
    _hide_activity_menu(true)


func _hide_activity_menu(
    restore_movement: bool = true
) -> void:
    _menu_open = false

    if is_instance_valid(_activity_menu):
        _activity_menu.hide()

    if restore_movement:
        _restore_exploration_if_safe()


# =========================================
# TOMORROW YOU
# =========================================

func _create_phone() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    layer.name = "TomorrowYouLayer"
    layer.layer = 7
    add_child(layer)

    _phone = PHONE_SCENE.instantiate() as Control

    if _phone == null:
        push_error("Tomorrow You root must be Control")
        return

    layer.add_child(_phone)

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


func _on_menu_preview_requested(
    activity_id: String,
    duration_minutes: int
) -> void:
    if not _menu_open or _phone_open:
        return

    if not _is_action_available(activity_id, duration_minutes):
        return

    var before: Dictionary = GameState.get_snapshot()

    var prediction: Dictionary = GameState.preview_action(
        activity_id,
        duration_minutes
    )

    if not bool(prediction.get("valid", false)):
        _show_message(str(prediction.get("reason", "Unavailable")))
        return

    preview_ready.emit(prediction)

    var after: Dictionary = prediction["next_state"]

    var remaining: int = max(
        0,
        GameState.END_TIME - int(after["time_minutes"])
    )

    var warning: String = "Predicted effects if completed."

    if activity_id == "study":
        warning = "Study assumes Assignment Rush is completed."
    elif activity_id == "badminton":
        warning = "Badminton effects apply only after winning."

    if bool(after.get("is_finished", false)):
        warning += " This activity ends the night."

    var display_data: Dictionary = {
        "action": activity_id.replace("_", " ").capitalize()
            + " - " + str(duration_minutes) + " minutes",
        "time_remaining": "%dh %02dm" % [
            int(remaining / 60),
            remaining % 60
        ],
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


# =========================================
# ACTIVITY ROUTING
# =========================================

func _is_action_available(
    activity_id: String,
    duration_minutes: int
) -> bool:
    var route: Dictionary = Router.get_route(activity_id)

    if not bool(route.get("valid", false)):
        _show_message("Unknown activity: " + activity_id)
        return false

    if not bool(route.get("ready", false)):
        _show_message(str(route.get("title", activity_id)) + " is coming soon!")
        return false

    var prediction: Dictionary = GameState.preview_action(
        activity_id,
        duration_minutes
    )

    if not bool(prediction.get("valid", false)):
        _show_message(str(prediction.get("reason", "Unavailable")))
        return false

    return true


func execute_route(
    activity_id: String,
    duration_minutes: int = -1
) -> void:
    if story_active or _dialogue_open:
        return

    if _menu_open or _phone_open or _minigame_active:
        return

    var route: Dictionary = Router.get_route(activity_id)

    if not bool(route.get("valid", false)):
        _show_message("Unknown activity")
        return

    if not bool(route.get("ready", false)):
        _show_message(str(route.get("title", activity_id)) + " is coming soon!")
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
            _show_message("Unsupported activity type")


func choose_activity(
    activity_id: String,
    duration_minutes: int
) -> Dictionary:
    var result: Dictionary = GameState.try_action(
        activity_id,
        duration_minutes
    )

    action_completed.emit(result)

    if bool(result.get("valid", false)):
        print("ACTIVITY COMPLETED: ", activity_id)
    else:
        _show_message(str(result.get("reason", "Action failed")))

    return result


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


# =========================================
# MINIGAME HANDLING
# =========================================

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
        _show_message("Missing minigame: " + scene_path)
        return

    var packed: PackedScene = load(scene_path) as PackedScene

    if packed == null:
        _show_message("Failed to load minigame")
        return

    var game_node: Node = packed.instantiate()

    if not game_node is Control:
        push_error("Minigame root must be Control")
        game_node.queue_free()
        return

    if not game_node.has_signal("minigame_finished"):
        push_error("Minigame completion signal missing")
        game_node.queue_free()
        return

    _minigame_active = true
    _active_activity = str(route["id"])
    _active_duration = duration_minutes

    _set_world_movement(false)
    minigame_requested.emit(_active_activity)

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


func _on_minigame_finished(result: Dictionary) -> void:
    if not _minigame_active:
        return

    var activity_id: String = _active_activity
    var duration: int = _active_duration

    var completed: bool = bool(result.get("completed", false))
    var score: int = int(result.get("score", 0))
    var mode: String = str(result.get("mode", ""))

    # Clear first to prevent multiple rewards.
    _minigame_active = false
    _active_activity = ""
    _active_duration = 0

    if is_instance_valid(_minigame_layer):
        _minigame_layer.queue_free()
        _minigame_layer = null

    if completed and score == 3 and mode == activity_id:
        match activity_id:
            "study", "badminton":
                choose_activity(activity_id, duration)

            _:
                _show_message("Reward not configured")
    else:
        _show_message("Minigame finished without reward")

    _restore_exploration_if_safe()


# =========================================
# GAME ENDING
# =========================================

func _on_game_finished(result: Dictionary) -> void:
    _set_world_movement(false)

    _show_message(
        "GAME FINISHED: "
        + str(result.get("title", "Night complete"))
    )


# =========================================
# OPTIONAL DEBUG PANEL
# =========================================

func _create_debug_ui() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    layer.name = "TemporaryDebugUI"
    layer.layer = 1
    add_child(layer)

    var panel: PanelContainer = PanelContainer.new()
    panel.position = Vector2(760, 90)
    panel.custom_minimum_size = Vector2(350, 0)
    layer.add_child(panel)

    var layout: VBoxContainer = VBoxContainer.new()
    panel.add_child(layout)

    _status_label = Label.new()
    layout.add_child(_status_label)

    for activity_id in [
        "study", "sleep", "eat", "socialize",
        "badminton", "bucket_fight", "lawn_walk"
    ]:
        var button: Button = Button.new()
        button.text = "Try: " + activity_id
        layout.add_child(button)

        button.pressed.connect(
            execute_route.bind(activity_id, -1)
        )

    _message_label = Label.new()
    layout.add_child(_message_label)


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
    )


func _show_message(message: String) -> void:
    print("CONTROLLER: ", message)

    if is_instance_valid(_message_label):
        _message_label.text = message
