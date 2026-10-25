
extends Camera3D

@export var follow_speed: float = 4.0

@onready var player: Node3D = $"../Player"

var camera_offset: Vector3


func _ready() -> void:
	camera_offset = global_position - player.global_position


func _process(delta: float) -> void:
	var target_position = player.global_position + camera_offset

	global_position = global_position.lerp(
		target_position,
		min(follow_speed * delta, 1.0)
	)
