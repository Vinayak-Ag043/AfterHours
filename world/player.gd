
extends CharacterBody3D

@export var move_speed: float = 4.0

var movement_enabled: bool = true


func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO

	if movement_enabled:
		input_dir = Input.get_vector(
			"move_left",
			"move_right",
			"move_forward",
            "move_back"
		)

	var direction := Vector3.ZERO
	var camera := get_viewport().get_camera_3d()

	if camera != null:
		var right := camera.global_basis.x
		var forward := -camera.global_basis.z

		right.y = 0.0
		forward.y = 0.0

		direction = (
			right.normalized() * input_dir.x
			- forward.normalized() * input_dir.y
		).normalized()

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0

	move_and_slide()
