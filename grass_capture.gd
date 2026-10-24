
extends Node2D

# ---------------- SETTINGS ----------------

const BACKGROUND_PATH = "res://minigames/grass_capture_bg.png"

const PLAYER_SPEED = 220.0
const GUARD_SPEED = 100.0

const PLAYER_COLOR = Color("#3498DB")
const GUARD_COLOR = Color("#E74C3C")
const SKIN = Color("#F2C49B")
const HAIR = Color("#30251F")
const PANTS = Color("#252B35")

const GRASS_COLOR = Color("#79D957")
const GRASS_DARK = Color("#348C32")

const GRID_ORIGIN = Vector2(70, 300)
const CELL_SIZE = 20
const COLS = 66
const ROWS = 17

# Increase this to place even more grass.
const GRASS_DENSITY = 0.75

# Approximate front-lawn boundary in grid coordinates.
var lawn_polygon: PackedVector2Array = PackedVector2Array([
	Vector2(2, 2),
	Vector2(63, 1),
	Vector2(65, 4),
	Vector2(65, 13),
	Vector2(61, 16),
	Vector2(3, 15),
	Vector2(1, 12),
	Vector2(1, 5)
])

# Add road polygons here if required.
var road_polygons: Array = []

# ---------------- GAME VARIABLES ----------------

var background_texture: Texture2D

var player_position = Vector2.ZERO
var guard_position = Vector2.ZERO

var game_over = false
var collected_percentage = 0.0

var lawn_cells: Array = []
var grass_items: Array[Vector2] = []
var grass_collected: Array[bool] = []

var total_grass = 0
var collected_grass = 0


# ---------------- START GAME ----------------

func _ready():
	randomize()
	background_texture = load(BACKGROUND_PATH) as Texture2D
	initialize_game()


func initialize_game():
	lawn_cells.clear()
	grass_items.clear()
	grass_collected.clear()

	total_grass = 0
	collected_grass = 0
	collected_percentage = 0.0
	game_over = false

	# Identify valid lawn cells.
	for y in range(ROWS):
		var lawn_row = []

		for x in range(COLS):
			lawn_row.append(is_lawn_cell(Vector2i(x, y)))

		lawn_cells.append(lawn_row)

	# Scatter grass across the lawn.
	create_grass_items()

	# Place player and guard.
	var start_cell = find_lawn_start()
	player_position = cell_to_position(start_cell)

	guard_position = cell_to_position(
		find_guard_start(start_cell)
	)

	queue_redraw()


# ---------------- LAWN BOUNDARY ----------------

func is_lawn_cell(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= COLS:
		return false

	if cell.y < 0 or cell.y >= ROWS:
		return false

	var point = Vector2(cell.x + 0.5, cell.y + 0.5)

	if not Geometry2D.is_point_in_polygon(point, lawn_polygon):
		return false

	for road in road_polygons:
		if Geometry2D.is_point_in_polygon(point, road):
			return false

	return true


func find_lawn_start() -> Vector2i:
	for x in range(COLS):
		for y in range(ROWS):
			if lawn_cells[y][x]:
				return Vector2i(x, y)

	return Vector2i(2, ROWS / 2)


func find_guard_start(player_cell: Vector2i) -> Vector2i:
	for x in range(COLS - 1, -1, -1):
		for y in range(ROWS):
			if lawn_cells[y][x]:
				var candidate = Vector2i(x, y)

				if candidate.distance_to(player_cell) > 15:
					return candidate

	return player_cell


# ---------------- GRASS GENERATION ----------------

func create_grass_items():
	grass_items.clear()
	grass_collected.clear()

	collected_grass = 0

	for y in range(ROWS):
		for x in range(COLS):
			if not lawn_cells[y][x]:
				continue

			# More grass: 75% chance per valid lawn cell.
			if randf() < GRASS_DENSITY:
				var pos = cell_to_position(Vector2i(x, y))

				# Small random offsets make the grass look natural.
				pos += Vector2(
					randf_range(-5.0, 5.0),
					randf_range(-4.0, 4.0)
				)

				grass_items.append(pos)
				grass_collected.append(false)

	total_grass = grass_items.size()


# ---------------- COLLECT GRASS ----------------

func collect_nearby_grass():
	for i in range(grass_items.size()):
		if grass_collected[i]:
			continue

		if player_position.distance_to(grass_items[i]) < 18.0:
			grass_collected[i] = true
			collected_grass += 1

			update_percentage()


func update_percentage():
	if total_grass > 0:
		collected_percentage = (
			float(collected_grass) / float(total_grass)
		) * 100.0
	else:
		collected_percentage = 0.0


# ---------------- MOVEMENT ----------------

func _process(delta):
	if game_over:
		if Input.is_key_pressed(KEY_R):
			initialize_game()

		queue_redraw()
		return

	var direction = Vector2.ZERO

	if Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0

	if Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0

	if Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0

	if Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	if direction.length() > 0.0:
		direction = direction.normalized()

		var next_position = (
			player_position
			+ direction * PLAYER_SPEED * delta
		)

		var next_cell = position_to_cell(next_position)

		if is_lawn_cell(next_cell):
			player_position = next_position
			collect_nearby_grass()

	# Guard follows the player.
	var difference = player_position - guard_position

	if difference.length() > 1.0:
		var next_guard_position = (
			guard_position
			+ difference.normalized() * GUARD_SPEED * delta
		)

		var guard_cell = position_to_cell(next_guard_position)

		if is_lawn_cell(guard_cell):
			guard_position = next_guard_position

	# Only contact with the player ends the game.
	if player_position.distance_to(guard_position) < 24.0:
		lose_game()

	queue_redraw()


func position_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		floori((pos.x - GRID_ORIGIN.x) / CELL_SIZE),
		floori((pos.y - GRID_ORIGIN.y) / CELL_SIZE)
	)


func cell_to_position(cell: Vector2i) -> Vector2:
	return (
		GRID_ORIGIN
		+ Vector2(cell) * CELL_SIZE
		+ Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
	)


func lose_game():
	game_over = true
	queue_redraw()


# ---------------- CHARACTER DRAWING ----------------

func draw_character(
	pos: Vector2,
	shirt_color: Color,
	facing: float = 1.0
):
	# Head
	draw_circle(pos + Vector2(0, -15), 8.0, SKIN)

	# Hair
	draw_arc(
		pos + Vector2(0, -17),
		8.0,
		PI,
		TAU,
		16,
		HAIR,
		3.0
	)

	# Shirt
	draw_rect(
		Rect2(pos + Vector2(-9, -6), Vector2(18, 22)),
		shirt_color
	)

	# Arms without badminton rackets
	draw_line(
		pos + Vector2(-8, 0),
		pos + Vector2(-15, 12),
		SKIN,
		5.0
	)

	draw_line(
		pos + Vector2(8, 0),
		pos + Vector2(15 * facing, 10),
		SKIN,
		5.0
	)

	# Legs
	draw_line(
		pos + Vector2(-5, 16),
		pos + Vector2(-9, 31),
		PANTS,
		6.0
	)

	draw_line(
		pos + Vector2(5, 16),
		pos + Vector2(10, 31),
		PANTS,
		6.0
	)

	# Eyes
	draw_circle(pos + Vector2(-3, -15), 1.2, Color.BLACK)
	draw_circle(pos + Vector2(3, -15), 1.2, Color.BLACK)


# ---------------- GRASS DRAWING ----------------

func draw_grass_item(pos: Vector2):
	# Three small blades for each grass collectible.
	draw_line(
		pos,
		pos + Vector2(-4, -7),
		GRASS_DARK,
		2.0
	)

	draw_line(
		pos,
		pos + Vector2(0, -9),
		GRASS_COLOR,
		2.0
	)

	draw_line(
		pos,
		pos + Vector2(4, -6),
		GRASS_DARK,
		2.0
	)


# ---------------- DRAW GAME ----------------

func _draw():
	var viewport_size = get_viewport_rect().size

	# Background
	if background_texture != null:
		draw_texture_rect(
			background_texture,
			Rect2(Vector2.ZERO, viewport_size),
			false
		)
	else:
		draw_rect(
			Rect2(Vector2.ZERO, viewport_size),
			Color("#4B9636")
		)

	# Draw only uncollected grass.
	# No traced path or green trail is drawn.
	for i in range(grass_items.size()):
		if not grass_collected[i]:
			draw_grass_item(grass_items[i])

	# Characters
	draw_character(guard_position, GUARD_COLOR, -1.0)
	draw_character(player_position, PLAYER_COLOR, 1.0)

	# Progress bar background
	draw_rect(
		Rect2(535, 680, 400, 28),
		Color("#172B26")
	)

	# Empty progress bar
	draw_rect(
		Rect2(539, 684, 392, 20),
		Color("#D9E6E0")
	)

	# Filled progress bar
	draw_rect(
		Rect2(
			539,
			684,
			392.0 * collected_percentage / 100.0,
			20
		),
		Color("#43C7C9")
	)

	# Percentage display
	draw_string(
		ThemeDB.fallback_font,
		Vector2(535, 670),
		"GRASS COLLECTED: %.1f%%" % collected_percentage,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(35, 35),
		"MOVE: ARROW KEYS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(35, 62),
		"Collect the grass tufts and avoid the guard!",
		HORIZONTAL_ALIGNMENT_LEFT,
		900,
		20,
		Color.WHITE
	)

	# Game-over screen
	if game_over:
		draw_rect(
			Rect2(350, 270, 770, 150),
			Color(0.05, 0.10, 0.08, 0.9)
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(500, 325),
			"THE GUARD CAUGHT YOU!",
			HORIZONTAL_ALIGNMENT_LEFT,
			600,
			30,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(500, 375),
			"Grass collected: %.1f%%" % collected_percentage,
			HORIZONTAL_ALIGNMENT_LEFT,
			600,
			20,
			Color("#FFD54F")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(500, 405),
			"Press R to restart",
			HORIZONTAL_ALIGNMENT_LEFT,
			600,
			18,
			Color.WHITE
		)
