
extends Node3D

signal activity_requested(activity_id: String)


# ==========================================
# INTERACTION SETTINGS
# ==========================================

@export var interaction_distance: float = 1.8
@export var roommate_interaction_distance: float = 1.6
@export var sleep_interaction_distance: float = 2.2
@export var eat_interaction_distance: float = 2.0
@export var bucket_interaction_distance: float = 1.8
@export var lawn_interaction_distance: float = 2.5
@export var badminton_interaction_distance: float = 2.5

var exploration_enabled: bool = true


# ==========================================
# PLAYER AND HOSTEL OBJECTS
# ==========================================

@onready var player: CharacterBody3D = $Player

@onready var study_station: StaticBody3D = $StudyStation

@onready var player_bed: StaticBody3D = $HostelRoom/Furniture/PlayerBed

@onready var roommate: StaticBody3D = $HostelRoom/Roommate

@onready var food_counter: StaticBody3D = $MessArea/FoodCounter


# ==========================================
# BUCKET FIGHT NPCS
# ==========================================

@onready var bucket_npc_a: StaticBody3D = $Corridor/BucketNPC_A
@onready var bucket_npc_b: StaticBody3D = $Corridor/BucketNPC_B
@onready var bucket_npc_c: StaticBody3D = $Corridor/BucketNPC_C
@onready var bucket_npc_d: StaticBody3D = $Corridor/BucketNPC_D


# ==========================================
# LAWN AND BADMINTON INTERACTION POINTS
# ==========================================

@onready var lawn_point: Node3D = get_node_or_null(
    "ThomsonLawn/LawnInteractionPoint"
) as Node3D

@onready var badminton_point: Node3D = get_node_or_null(
    "BadmintonCourt/BadmintonInteractionPoint"
) as Node3D


# ==========================================
# FLOOR REFERENCES FOR LOCATION DETECTION
# ==========================================

@onready var hostel_floor: MeshInstance3D = $ArenaFloor/MeshInstance3D

@onready var corridor_floor: MeshInstance3D = $Corridor/CorridorFloor/MeshInstance3D

@onready var common_floor: MeshInstance3D = $CommonArea/CommonFloor/MeshInstance3D

@onready var mess_floor: MeshInstance3D = $MessArea/MessFloor/MeshInstance3D

@onready var lawn_floor: MeshInstance3D = $ThomsonLawn/LawnFloor/MeshInstance3D

@onready var court_floor: MeshInstance3D = $BadmintonCourt/CourtFloor/MeshInstance3D


# ==========================================
# UI
# ==========================================

@onready var prompt: Label = $DebugUI/Prompt

@onready var location_label: Label = $DebugUI/LocationLabel


# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:
	prompt.hide()
	activity_requested.connect(_debug_activity)


# ==========================================
# UPDATE UI EVERY FRAME
# ==========================================

func _process(_delta: float) -> void:

	if not exploration_enabled:
		prompt.hide()
		location_label.hide()
		return

	# Show current location
	location_label.show()
	location_label.text = "Location: " + _get_location_name()

	# Detect nearby activity
	var activity_id := _get_nearby_activity()

	match activity_id:

		"study":
			prompt.text = "Press E to Study"

		"sleep":
			prompt.text = "Press E to Sleep"

		"eat":
			prompt.text = "Press E to Eat"

		"socialize":
			prompt.text = "Press E to Talk"

		"bucket_fight":
			prompt.text = "Press E for Bucket Fight"

		"lawn_walk":
			prompt.text = "Press E for GrassCapture"

		"badminton":
			prompt.text = "Press E to Play Badminton"

		_:
			prompt.hide()
			return

	prompt.show()


# ==========================================
# PLAYER INTERACTION INPUT
# ==========================================

func _unhandled_input(event: InputEvent) -> void:

	if not exploration_enabled:
		return

	if event.is_action_pressed("interact"):

		var activity_id := _get_nearby_activity()

		if activity_id != "":
			activity_requested.emit(activity_id)
			get_viewport().set_input_as_handled()


# ==========================================
# DETECT NEARBY ACTIVITY
# ==========================================

func _get_nearby_activity() -> String:

	# Laptop
	if _is_near(study_station, interaction_distance):
		return "study"

	# Roommate
	if _is_near(roommate, roommate_interaction_distance):
		return "socialize"

	# Player bed
	if _is_near(player_bed, sleep_interaction_distance):
		return "sleep"

	# Mess counter
	if _is_near(food_counter, eat_interaction_distance):
		return "eat"

	# Bucket Fight NPCs
	if _near_bucket_npcs():
		return "bucket_fight"

	# GrassCapture flag
	if _is_near(lawn_point, lawn_interaction_distance):
		return "lawn_walk"

	# Badminton net
	if _is_near(badminton_point, badminton_interaction_distance):
		return "badminton"

	return ""


# ==========================================
# GENERIC DISTANCE CHECK
# ==========================================

func _is_near(target: Node3D, max_distance: float) -> bool:

	if target == null:
		return false

	var player_pos := Vector2(
		player.global_position.x,
		player.global_position.z
	)

	var target_pos := Vector2(
		target.global_position.x,
		target.global_position.z
	)

	return player_pos.distance_to(target_pos) <= max_distance


# ==========================================
# BUCKET FIGHT DETECTION
# ==========================================

func _near_bucket_npcs() -> bool:

	var npcs: Array[Node3D] = [
		bucket_npc_a,
		bucket_npc_b,
		bucket_npc_c,
		bucket_npc_d
	]

	for npc in npcs:
		if _is_near(npc, bucket_interaction_distance):
			return true

	return false


# ==========================================
# LOCATION DETECTION USING FLOOR MESHES
# ==========================================

func _inside_floor(floor_mesh: MeshInstance3D) -> bool:

	if floor_mesh == null:
		return false

	if floor_mesh.mesh == null:
		return false

	# Convert the player position to the floor mesh's local space
	var local_pos := floor_mesh.to_local(
		player.global_position
	)

	# Read the floor mesh's actual bounds
	var bounds := floor_mesh.mesh.get_aabb()

	return (
		local_pos.x >= bounds.position.x
		and local_pos.x <= bounds.end.x
		and local_pos.z >= bounds.position.z
		and local_pos.z <= bounds.end.z
	)


func _get_location_name() -> String:

	# Hostel
	if _inside_floor(hostel_floor):
		return "Hostel Room"

	# Mess
	if _inside_floor(mess_floor):
		return "Mess"

	# Common area
	if _inside_floor(common_floor):
		return "Common Area"

	# Corridor
	if _inside_floor(corridor_floor):
		return "Corridor"

	# Badminton (checked before lawn in case floors overlap)
	if _inside_floor(court_floor):
		return "Badminton Court"

	# Thomson Lawn
	if _inside_floor(lawn_floor):
		return "Thomson Building Lawn"

	return "Outdoor Path"


# ==========================================
# ENABLE / DISABLE EXPLORATION
# ==========================================

func set_exploration_enabled(enabled: bool) -> void:

	exploration_enabled = enabled

	player.set("movement_enabled", enabled)

	if not enabled:
		player.velocity = Vector3.ZERO
		prompt.hide()
		location_label.hide()


# ==========================================
# DEBUG SIGNAL OUTPUT
# ==========================================

func _debug_activity(activity_id: String) -> void:
	print("ACTIVITY REQUESTED: ", activity_id)
