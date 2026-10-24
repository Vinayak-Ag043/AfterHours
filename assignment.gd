extends Control

@export var puzzle_image: Texture2D

@onready var grid = $VBoxContainer/GridContainer
@onready var status_label = $VBoxContainer/StatusLabel
@onready var restart_button = $VBoxContainer/RestartButton

const GRID_SIZE = 3
const TILE_SIZE = 120
const EMPTY_TILE = -1

var tiles: Array = []
var tile_buttons: Array = []
var tile_pictures: Array = []

var moves = 0
var game_won = false


func _ready():
	grid.columns = GRID_SIZE
	restart_button.pressed.connect(start_game)

	if puzzle_image == null:
		status_label.text = "Please assign your puzzle image!"
		return

	start_game()


func start_game():
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	tiles.clear()
	tile_buttons.clear()
	tile_pictures.clear()

	moves = 0
	game_won = false

	# Eight picture tiles and one empty space.
	for i in range(GRID_SIZE * GRID_SIZE - 1):
		tiles.append(i)

	tiles.append(EMPTY_TILE)

	# Shuffle using valid moves so the puzzle remains solvable.
	var empty_position = tiles.size() - 1
	var previous_empty = -1

	for i in range(100):
		var neighbours = get_neighbours(empty_position)

		if previous_empty != -1:
			neighbours.erase(previous_empty)

		var next_position = neighbours.pick_random()

		var temp = tiles[empty_position]
		tiles[empty_position] = tiles[next_position]
		tiles[next_position] = temp

		previous_empty = empty_position
		empty_position = next_position

	create_tiles()
	update_tiles()
	update_status()


func create_tiles():
	for position in range(tiles.size()):
		var tile_button = Button.new()
		tile_button.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		tile_button.clip_contents = true
		tile_button.text = ""

		var picture = TextureRect.new()
		picture.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT
		)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_SCALE
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE

		tile_button.add_child(picture)
		tile_button.pressed.connect(
			_on_tile_pressed.bind(position)
		)

		grid.add_child(tile_button)

		tile_buttons.append(tile_button)
		tile_pictures.append(picture)


func get_neighbours(position: int) -> Array:
	var neighbours = []
	var row = int(position / GRID_SIZE)
	var col = position % GRID_SIZE

	if row > 0:
		neighbours.append(position - GRID_SIZE)

	if row < GRID_SIZE - 1:
		neighbours.append(position + GRID_SIZE)

	if col > 0:
		neighbours.append(position - 1)

	if col < GRID_SIZE - 1:
		neighbours.append(position + 1)

	return neighbours


func _on_tile_pressed(position: int):
	if game_won:
		return

	var empty_position = tiles.find(EMPTY_TILE)

	# A tile can move only into the adjacent empty space.
	if position not in get_neighbours(empty_position):
		status_label.text = (
            "Invalid move! Choose a tile next to the empty space."
		)
		return

	# Slide the selected tile into the empty space.
	tiles[empty_position] = tiles[position]
	tiles[position] = EMPTY_TILE

	moves += 1

	update_tiles()

	if is_solved():
		game_won = true
		status_label.text = (
			"PICTURE CORRECT! YOU WIN! Moves used: %d" % moves
		)
	else:
		update_status()


func update_tiles():
	var tile_width = puzzle_image.get_width() / float(GRID_SIZE)
	var tile_height = puzzle_image.get_height() / float(GRID_SIZE)

	for position in range(tiles.size()):
		var tile_index = tiles[position]

		if tile_index == EMPTY_TILE:
			tile_pictures[position].texture = null
			tile_buttons[position].text = ""
			tile_buttons[position].flat = true
			tile_buttons[position].disabled = true
		else:
			var row = int(tile_index / GRID_SIZE)
			var col = tile_index % GRID_SIZE

			var tile_texture = AtlasTexture.new()
			tile_texture.atlas = puzzle_image
			tile_texture.region = Rect2(
				col * tile_width,
				row * tile_height,
				tile_width,
				tile_height
			)

			tile_pictures[position].texture = tile_texture
			tile_buttons[position].flat = false
			tile_buttons[position].disabled = false


func is_solved() -> bool:
	for i in range(GRID_SIZE * GRID_SIZE - 1):
		if tiles[i] != i:
			return false

	return tiles[GRID_SIZE * GRID_SIZE - 1] == EMPTY_TILE


func update_status():
	status_label.text = (
		"Moves: %d | Slide a tile next to the empty space." % moves
	)
