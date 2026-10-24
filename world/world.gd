
extends Node3D

signal activity_requested(activity_id: String)

@export var interaction_distance: float = 1.8
@export var roommate_interaction_distance: float = 1.6
@export var sleep_interaction_distance: float = 2.2

@onready var roommate: StaticBody3D = $HostelRoom/Roommate
@onready var player_bed: StaticBody3D = $HostelRoom/Furniture/PlayerBed
@onready var player: CharacterBody3D = $Player
@onready var study_station: StaticBody3D = $StudyStation
@onready var prompt: Label = $DebugUI/Prompt

var exploration_enabled: bool = true


func _ready() -> void:
	prompt.hide()
	activity_requested.connect(_debug_activity)


func _process(_delta: float) -> void:
	if not exploration_enabled:
		prompt.hide()
		return

	if _near_study_station():
		prompt.text = "Press E to Study"
		prompt.show()
	elif _near_roommate():
		prompt.text = "Press E to Talk"
		prompt.show()
	elif _near_player_bed():
		prompt.text = "Press E to Sleep"
		prompt.show()
	else:
		prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not exploration_enabled:
		return

	if event.is_action_pressed("interact") and not event.is_echo():
		if _near_study_station():
			activity_requested.emit("study")
		elif _near_roommate():
			activity_requested.emit("talk")
		elif _near_player_bed():
			activity_requested.emit("sleep")
		else:
			return

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


func _near_player_bed() -> bool:
	var player_pos := Vector2(
		player.global_position.x,
		player.global_position.z
	)

	var bed_pos := Vector2(
		player_bed.global_position.x,
		player_bed.global_position.z
	)

	return player_pos.distance_to(bed_pos) <= sleep_interaction_distance


func _near_roommate() -> bool:
	var player_pos := Vector2(
		player.global_position.x,
		player.global_position.z
	)

	var roommate_pos := Vector2(
		roommate.global_position.x,
		roommate.global_position.z
	)

	return player_pos.distance_to(roommate_pos) <= roommate_interaction_distance


func set_exploration_enabled(enabled: bool) -> void:
	exploration_enabled = enabled
	player.set("movement_enabled", enabled)

	if not enabled:
		prompt.hide()


func _debug_activity(activity_id: String) -> void:
	print("ACTIVITY REQUESTED: ", activity_id)
