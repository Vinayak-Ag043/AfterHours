
extends Node3D

signal activity_requested(activity_id: String)

@export var interaction_distance: float = 1.8

var exploration_enabled: bool = true

@onready var player: CharacterBody3D = $Player
@onready var study_station: StaticBody3D = $StudyStation
@onready var prompt: Label = $DebugUI/Prompt


func _ready() -> void:
	prompt.hide()
	activity_requested.connect(_debug_activity)


func _process(_delta: float) -> void:
	prompt.visible = exploration_enabled and _near_study_station()


func _unhandled_input(event: InputEvent) -> void:
	if not exploration_enabled:
		return

	if event.is_action_pressed("interact"):
		if _near_study_station():
			activity_requested.emit("study")
			get_viewport().set_input_as_handled()


func _near_study_station() -> bool:
	var player_pos := Vector2(
		player.global_position.x,
		player.global_position.z
	)

	var station_pos := Vector2(
		study_station.global_position.x,
		study_station.global_position.z
	)

	return player_pos.distance_to(station_pos) <= interaction_distance


func set_exploration_enabled(enabled: bool) -> void:
	exploration_enabled = enabled
	player.set("movement_enabled", enabled)

	if not enabled:
		prompt.hide()


func _debug_activity(activity_id: String) -> void:
	print("ACTIVITY REQUESTED: ", activity_id)
