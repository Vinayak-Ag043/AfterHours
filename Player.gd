extends CharacterBody2D

@export var speed: float = 250.0

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO

	# Arrow-key movement
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	# Prevent faster diagonal movement
	direction = direction.normalized()

	# Set player velocity
	velocity = direction * speed

	# Move and collide with walls
	move_and_slide()
