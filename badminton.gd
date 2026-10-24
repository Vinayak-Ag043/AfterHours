
extends Node2D

# -------------------- CONSTANTS --------------------

const COURT_GREEN = Color("#287A50")
const COURT_LINE = Color.WHITE
const PLAYER_BLUE = Color("#3498DB")
const COMPUTER_RED = Color("#E74C3C")
const SKIN = Color("#F2C49B")
const HAIR = Color("#30251F")
const PANTS = Color("#252B35")
const RACKET_COLOR = Color("#E5D5A4")
const SHUTTLE_COLOR = Color.WHITE
const INSTRUCTION_COLOR = Color("#FFD54F")

const SHUTTLE_SPEED = 450.0
const COMPUTER_SPEED = 300.0
const HIT_DISTANCE = 45.0
const PLAYER_CLICK_DISTANCE = 40.0
const WINNING_SCORE = 7
const RED_SERVE_DELAY = 3.0

# -------------------- GAME VARIABLES --------------------

var player_position = Vector2(360, 525)
var computer_position = Vector2(360, 115)
var shuttle_position = Vector2(385, 510)

var aim_position = Vector2(360, 150)
var shuttle_target = Vector2.ZERO

var shuttle_moving = false
var player_control_enabled = false

var current_server = "blue"

var red_serve_pending = false
var red_serve_timer = 0.0

# States: ready, player_flight, computer_flight,
# point_over, match_over
var game_state = "ready"

var status_message = "Left-click the blue player to begin."

var player_score = 0
var computer_score = 0


# -------------------- DRAW COURT AND GAME --------------------

func _draw():
	# Main court
	draw_rect(
		Rect2(140, 10, 440, 620),
		COURT_GREEN
	)

	# Extended court areas behind the back boundaries
	draw_rect(
		Rect2(140, -10, 440, 20),
		COURT_GREEN
	)

	draw_rect(
		Rect2(140, 630, 440, 20),
		COURT_GREEN
	)

	# Outer side lines
	draw_line(
		Vector2(140, 10),
		Vector2(140, 630),
		COURT_LINE,
		3.0
	)

	draw_line(
		Vector2(580, 10),
		Vector2(580, 630),
		COURT_LINE,
		3.0
	)

	# Inner side lines
	draw_line(
		Vector2(175, 10),
		Vector2(175, 630),
		COURT_LINE,
		2.0
	)

	draw_line(
		Vector2(545, 10),
		Vector2(545, 630),
		COURT_LINE,
		2.0
	)

	# Service lines
	draw_line(
		Vector2(140, 180),
		Vector2(580, 180),
		COURT_LINE,
		2.0
	)

	draw_line(
		Vector2(140, 460),
		Vector2(580, 460),
		COURT_LINE,
		2.0
	)

	# Centre service lines
	draw_line(
		Vector2(360, 10),
		Vector2(360, 180),
		COURT_LINE,
		2.0
	)

	draw_line(
		Vector2(360, 460),
		Vector2(360, 630),
		COURT_LINE,
		2.0
	)

	# Net
	draw_line(
		Vector2(140, 320),
		Vector2(580, 320),
		Color.BLACK,
		6.0
	)

	draw_line(
		Vector2(140, 316),
		Vector2(580, 316),
		COURT_LINE,
		1.0
	)

	# Back boundary lines
	draw_line(
		Vector2(140, 10),
		Vector2(580, 10),
		COURT_LINE,
		3.0
	)

	draw_line(
		Vector2(140, 630),
		Vector2(580, 630),
		COURT_LINE,
		3.0
	)

	# Outlines of the extended areas
	draw_rect(
		Rect2(140, -10, 440, 20),
		COURT_LINE,
		false,
		1.5
	)

	draw_rect(
		Rect2(140, 630, 440, 20),
		COURT_LINE,
		false,
		1.5
	)

	# Characters
	draw_character(computer_position, COMPUTER_RED)
	draw_character(player_position, PLAYER_BLUE)

	# Aiming marker
	if game_state == "ready":
		draw_arc(
			aim_position,
			12.0,
			0.0,
			TAU,
			32,
			INSTRUCTION_COLOR,
			3.0
		)

		draw_line(
			aim_position + Vector2(-17, 0),
			aim_position + Vector2(17, 0),
			INSTRUCTION_COLOR,
			2.0
		)

		draw_line(
			aim_position + Vector2(0, -17),
			aim_position + Vector2(0, 17),
			INSTRUCTION_COLOR,
			2.0
		)

	# Shuttlecock
	draw_circle(
		shuttle_position,
		5.0,
		SHUTTLE_COLOR
	)

	draw_line(
		shuttle_position + Vector2(0, 4),
		shuttle_position + Vector2(-7, 12),
		SHUTTLE_COLOR,
		2.0
	)

	draw_line(
		shuttle_position + Vector2(0, 4),
		shuttle_position + Vector2(7, 12),
		SHUTTLE_COLOR,
		2.0
	)

	# Scoreboard
	draw_string(
		ThemeDB.fallback_font,
		Vector2(150, 675),
		"Blue: %d    Red: %d    First to %d" % [
			player_score,
			computer_score,
			WINNING_SCORE
		],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color.WHITE
	)

	# Current server
	var server_name = "Blue" if current_server == "blue" else "Red"

	draw_string(
		ThemeDB.fallback_font,
		Vector2(150, 695),
		"Current server: " + server_name,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		INSTRUCTION_COLOR
	)

	# Red serve countdown or status message
	if red_serve_pending:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(150, 715),
			"RED SERVES IN: %d" % int(ceil(red_serve_timer)),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			INSTRUCTION_COLOR
		)
	else:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(150, 715),
			status_message,
			HORIZONTAL_ALIGNMENT_LEFT,
			550,
			15,
			Color.WHITE
		)

	# Bottom instruction
	draw_string(
		ThemeDB.fallback_font,
		Vector2(150, 740),
		"To begin, left-click on the blue player to enable movement.",
		HORIZONTAL_ALIGNMENT_LEFT,
		550,
		14,
		INSTRUCTION_COLOR
	)


# -------------------- DRAW CHARACTERS --------------------

func draw_character(pos: Vector2, shirt_color: Color):
	# Head
	draw_circle(
		pos + Vector2(0, -15),
		8.0,
		SKIN
	)

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

	# Body
	draw_rect(
		Rect2(
			pos + Vector2(-9, -6),
			Vector2(18, 22)
		),
		shirt_color
	)

	# Arms
	draw_line(
		pos + Vector2(-8, 0),
		pos + Vector2(-17, 13),
		SKIN,
		5.0
	)

	draw_line(
		pos + Vector2(8, 0),
		pos + Vector2(17, -7),
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

	# Racket
	var racket_start = pos + Vector2(17, -7)
	var racket_end = pos + Vector2(29, -21)

	draw_line(
		racket_start,
		racket_end,
		RACKET_COLOR,
		3.0
	)

	draw_arc(
		racket_end,
		7.0,
		0.0,
		TAU,
		20,
		RACKET_COLOR,
		2.0
	)

	# Eyes
	draw_circle(
		pos + Vector2(-3, -15),
		1.2,
		Color.BLACK
	)

	draw_circle(
		pos + Vector2(3, -15),
		1.2,
		Color.BLACK
	)


# -------------------- INPUT CONTROLS --------------------

func _input(event):
	if game_state == "match_over":
		return

	# Mouse movement
	if event is InputEventMouseMotion:
		# Move Blue when movement is enabled
		if player_control_enabled:
			if (
				game_state == "ready"
				or game_state == "computer_flight"
			):
				if event.position.y >= 320.0:
					player_position = Vector2(
						clampf(event.position.x, 190.0, 530.0),
						clampf(event.position.y, 340.0, 590.0)
					)

					# Keep shuttle with Blue when ready to hit
					if game_state == "ready":
						shuttle_position = (
							player_position + Vector2(25, -15)
						)

		# Aim on Red's side
		if game_state == "ready" and event.position.y < 300.0:
			aim_position = Vector2(
				clampf(event.position.x, 150.0, 570.0),
				clampf(event.position.y, 30.0, 295.0)
			)

		queue_redraw()

	# Mouse clicks
	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		):
			# Restart rally after a point
			if game_state == "point_over":
				if event.position.y >= 320.0:
					reset_rally()
				return

			# Enable or disable Blue's movement
			if (
				(
					game_state == "ready"
					or game_state == "computer_flight"
				)
				and event.position.y >= 320.0
			):
				if player_control_enabled:
					# Only disable movement when clicking Blue
					if event.position.distance_to(
						player_position
					) <= PLAYER_CLICK_DISTANCE:
						player_control_enabled = false
						status_message = "Player movement locked."
				elif event.position.distance_to(
					player_position
				) <= PLAYER_CLICK_DISTANCE:
					player_control_enabled = true

					if red_serve_pending:
						status_message = "Move Blue! Red serves soon."
					else:
						status_message = "Player movement enabled."

				queue_redraw()
				return

			# Hit shuttle toward Red's side
			if (
				game_state == "ready"
				and event.position.y < 300.0
			):
				shuttle_target = aim_position
				shuttle_moving = true
				player_control_enabled = false

				game_state = "player_flight"
				status_message = "Blue hits the shuttle!"

				queue_redraw()


# -------------------- GAME LOOP --------------------

func _process(delta):
	# Handle Red's serve countdown
	if red_serve_pending:
		red_serve_timer -= delta

		if red_serve_timer <= 0.0:
			red_serve_timer = 0.0
			red_serve_pending = false
			shuttle_moving = true
			player_control_enabled = true
			status_message = "Red serves! Move Blue to intercept."

		queue_redraw()

	# Stop if the shuttle is not moving
	if not shuttle_moving:
		return

	# Red chases Blue's shot
	if game_state == "player_flight":
		computer_position = computer_position.move_toward(
			shuttle_target,
			COMPUTER_SPEED * delta
		)

	# Move shuttle toward target
	shuttle_position = shuttle_position.move_toward(
		shuttle_target,
		SHUTTLE_SPEED * delta
	)

	# Check whether Blue intercepts Red's shot
	if game_state == "computer_flight":
		var catch_distance = player_position.distance_to(
			shuttle_position
		)

		if catch_distance <= HIT_DISTANCE:
			shuttle_moving = false
			player_control_enabled = true
			game_state = "ready"

			shuttle_position = (
				player_position + Vector2(25, -15)
			)

			status_message = "Blue received it! Aim and click to return."
			queue_redraw()
			return

	# Check whether shuttle reached its target
	if shuttle_position.distance_to(shuttle_target) <= 2.0:
		shuttle_position = shuttle_target
		shuttle_moving = false
		shot_finished()

	queue_redraw()


# -------------------- SHOT AND SCORE LOGIC --------------------

func shot_finished():
	# Blue's shot reaches Red's side
	if game_state == "player_flight":
		var opponent_distance = computer_position.distance_to(
			shuttle_position
		)

		if opponent_distance <= HIT_DISTANCE:
			# Red returns the shuttle
			game_state = "computer_flight"

			var return_x = player_position.x

			# Aim away from Blue's current position
			if player_position.x < 360.0:
				return_x += 100.0
			else:
				return_x -= 100.0

			return_x = clampf(return_x, 200.0, 520.0)

			shuttle_target = Vector2(return_x, 525.0)
			shuttle_position = computer_position + Vector2(25, 15)
			shuttle_moving = true
			player_control_enabled = true

			status_message = "Red returned it! Move Blue to intercept."

		else:
			# Red misses: Blue scores and serves next
			player_score += 1
			current_server = "blue"
			player_control_enabled = false

			if player_score >= WINNING_SCORE:
				game_state = "match_over"
				status_message = "BLUE WINS! Final score: %d - %d" % [
					player_score,
					computer_score
				]
			else:
				game_state = "point_over"
				status_message = "Blue wins! Click bottom court for next rally."

	# Red's shot reaches Blue's side
	elif game_state == "computer_flight":
		var player_distance = player_position.distance_to(
			shuttle_position
		)

		if player_distance <= HIT_DISTANCE:
			# Blue receives the shuttle
			game_state = "ready"
			player_control_enabled = true

			shuttle_position = (
				player_position + Vector2(25, -15)
			)

			status_message = "Blue received it! Aim and click to return."

		else:
			# Blue misses: Red scores and serves next
			computer_score += 1
			current_server = "red"
			player_control_enabled = false

			if computer_score >= WINNING_SCORE:
				game_state = "match_over"
				status_message = "RED WINS! Final score: %d - %d" % [
					player_score,
					computer_score
				]
			else:
				game_state = "point_over"
				status_message = "Red wins! Click bottom court for next rally."

	queue_redraw()


# -------------------- RESET RALLY --------------------

func reset_rally():
	# Reset positions while preserving scores
	player_position = Vector2(360, 525)
	computer_position = Vector2(360, 115)

	shuttle_moving = false
	player_control_enabled = false
	shuttle_target = Vector2.ZERO
	aim_position = Vector2(360, 150)

	red_serve_pending = false
	red_serve_timer = 0.0

	if current_server == "blue":
		# Blue serves immediately
		shuttle_position = player_position + Vector2(25, -15)
		game_state = "ready"
		status_message = "Blue serves! Aim at Red's court and click."

	else:
		# Prepare Red's serve with a 3-second delay
		shuttle_position = computer_position + Vector2(25, 15)

		var serve_x = player_position.x

		if player_position.x < 360.0:
			serve_x += 100.0
		else:
			serve_x -= 100.0

		serve_x = clampf(serve_x, 200.0, 520.0)

		shuttle_target = Vector2(serve_x, 525.0)

		game_state = "computer_flight"
		red_serve_pending = true
		red_serve_timer = RED_SERVE_DELAY

		# Let Blue move during the countdown
		player_control_enabled = true
		status_message = "Move Blue into position before Red serves!"

	queue_redraw()
