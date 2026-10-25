
extends Node2D

@onready var background: Sprite2D = $Background


func _ready() -> void:
	print("Water Run scene started")

	if background.texture == null:
		push_error("Background Sprite2D has no texture assigned!")
		return

	background.centered = false
	background.position = Vector2.ZERO
	background.z_index = -1

	fit_background()


func fit_background() -> void:
	if background.texture == null:
		return

	var image_size: Vector2 = background.texture.get_size()
	var screen_size: Vector2 = get_viewport_rect().size

	background.scale = Vector2(
		screen_size.x / image_size.x,
		screen_size.y / image_size.y
	)
