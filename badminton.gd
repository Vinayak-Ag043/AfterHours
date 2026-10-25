
extends Node2D

# -------------------- SETTINGS --------------------

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

const PLAYER_SPEED = 250.0
const RED_SPEED = 220.0
const SHUTTLE_SPEED = 450.0
const HIT_DISTANCE = 45.0

# Score at which Red begins moving
const RED_ACTIVATION_SCORE = 0

# Score required to win
const WINNING_SCORE = 7

# Court boundaries
const PLAYER_MIN_X = 190.0
const PLAYER_MAX_X = 530.0
const PLAYER_MIN_Y = 350.0
const PLAYER_MAX_Y = 590.0

const RED_MIN_X = 190.0
const RED_MAX_X = 530.0
const RED_MIN_Y = 35.0
const RED_MAX_Y = 285.0

# -------------------- VARIABLES --------------------

var player_position = Vector2(360, 525)
var computer_position = Vector2(360, 115)
var shuttle_position = Vector2(385, 510)

var aim_position = Vector2(360, 150)
var shuttle_target = Vector2.ZERO

var player_score = 0
var computer_score = 0

var shuttle_moving = false
var player_control_enabled = true
var red_active = false

var player_racket_direction = Vector2(0.7, -0.7)
var red_racket_direction = Vector2(0.7, 0.7)

# ready, player_flight, computer_flight,
# point_over, match_over
var game_state = "ready"

var status_message = "Move Blue with arrow keys. Aim and click to hit."


# -------------------- PROCESS --------------------

func _process(delta: float) -> void:
	if game_state == "match_over":
		queue_redraw()
		return

	# Activate Red after Blue reaches the target score
	if not red_active and player_score >= RED_ACTIVATION_SCORE:
		red_active = true
		status_message = "Red is now active! Watch the shuttle."
	
	# Move Blue with arrow keys
	if player_control_enabled and (
		game_state == "ready"
		or game_state == "computer_flight"
	):
		var direction := Vector2.ZERO

		if Input.is_action_pressed("ui_right"):
			direction.x += 1.0
		if Input.is_action_pressed("ui_left"):
			direction.x -= 1.0
		if Input.is_action_pressed("ui_down"):
			direction.y += 1.0
		if Input.is_action_pressed("ui_up"):
			direction.y -= 1.0

		player_position += direction.normalized() * PLAYER_SPEED * delta

		player_position.x = clampf(
			player_position.x, PLAYER_MIN_X, PLAYER_MAX_X
		)
		player_position.y = clampf(
			player_position.y, PLAYER_MIN_Y, PLAYER_MAX_Y
		)

		if game_state == "ready" and not shuttle_moving:
			shuttle_position = player_position + Vector2(25, -15)

	# Move the shuttle
	if shuttle_moving:
		shuttle_position = shuttle_position.move_toward(
			shuttle_target, SHUTTLE_SPEED * delta
		)

		# Red tries to reach the shuttle once activated
		if game_state == "player_flight" and red_active:
			computer_position = computer_position.move_toward(
				shuttle_target, RED_SPEED * delta
			)
			computer_position.x = clampf(
				computer_position.x, RED_MIN_X, RED_MAX_X
			)
			computer_position.y = clampf(
				computer_position.y, RED_MIN_Y, RED_MAX_Y
			)

		# Check whether Blue intercepts Red's shot
		if game_state == "computer_flight":
			if player_position.distance_to(shuttle_position) <= HIT_DISTANCE:
				shuttle_moving = false
				game_state = "ready"
				player_control_enabled = true
				shuttle_position = player_position + Vector2(25, -15)
				status_message = "Blue received the shuttle! Aim and click."
				queue_redraw()
				return

		# Check if the shuttle reaches its destination
		if shuttle_position.distance_to(shuttle_target) <= 2.0:
			shuttle_position = shuttle_target
			shuttle_moving = false
			shot_finished()

	queue_redraw()


# -------------------- INPUT --------------------

func _input(event: InputEvent) -> void:
	if game_state == "match_over":
		return

	if event is InputEventMouseMotion:
		# Cursor selects a target on the upper court
		if event.position.y < 310.0:
			aim_position = Vector2(
				clampf(event.position.x, 150.0, 570.0),
				clampf(event.position.y, 30.0, 295.0)
			)

		queue_redraw()

	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
			return

		if game_state == "point_over":
			reset_rally()
			return

		if game_state == "ready" and event.position.y < 310.0:
			hit_shuttle()


# -------------------- HIT SHUTTLE --------------------

func hit_shuttle() -> void:
	if game_state != "ready":
		return

	shuttle_target = aim_position
	player_racket_direction = (
		shuttle_target - player_position
	).normalized()

	shuttle_position = player_position + Vector2(15, -12)
	shuttle_moving = true
	player_control_enabled = false
	game_state = "player_flight"

	status_message = "Blue hits the shuttle!"
	queue_redraw()


# -------------------- SHOT RESULT --------------------

func shot_finished() -> void:
	if game_state == "player_flight":
		# Red can miss while inactive or if far from the shuttle
		if red_active and computer_position.distance_to(
			shuttle_position
		) <= HIT_DISTANCE:
			game_state = "computer_flight"

			var return_x = player_position.x
			if player_position.x < computer_position.x:
				return_x += 100.0
			else:
				return_x -= 100.0

			return_x = clampf(return_x, 200.0, 520.0)
			shuttle_target = Vector2(return_x, 525.0)
			shuttle_position = computer_position + Vector2(15, 12)

			red_racket_direction = (
				shuttle_target - computer_position
			).normalized()

			shuttle_moving = true
			player_control_enabled = true
			status_message = "Red returns the shuttle! Move Blue to intercept."
		else:
			player_score += 1
			finish_point(true)

	elif game_state == "computer_flight":
		computer_score += 1
		finish_point(false)


func finish_point(blue_won: bool) -> void:
	shuttle_moving = false
	player_control_enabled = false

	if player_score >= WINNING_SCORE or computer_score >= WINNING_SCORE:
		game_state = "match_over"
		status_message = (
			"BLUE WINS! %d - %d" % [player_score, computer_score]
			if blue_won
			else "RED WINS! %d - %d" % [player_score, computer_score]
		)
	else:
		game_state = "point_over"
		status_message = (
            "Blue scores! Click to continue."
			if blue_won
			else "Red scores! Click to continue."
		)

	queue_redraw()


# -------------------- RESET --------------------

func reset_rally() -> void:
	player_position = Vector2(360, 525)
	computer_position = Vector2(360, 115)
	shuttle_position = player_position + Vector2(25, -15)
	aim_position = Vector2(360, 150)

	shuttle_target = Vector2.ZERO
	shuttle_moving = false
	player_control_enabled = true
	player_racket_direction = Vector2(0.7, -0.7)

	game_state = "ready"
	status_message = "Aim with the mouse and click the upper court."

	queue_redraw()


# -------------------- DRAW --------------------

func _draw() -> void:
	draw_rect(Rect2(140, 10, 440, 620), COURT_GREEN)
	draw_rect(Rect2(140, -10, 440, 20), COURT_GREEN)
	draw_rect(Rect2(140, 630, 440, 20), COURT_GREEN)

	draw_line(Vector2(140, 10), Vector2(140, 630), COURT_LINE, 3.0)
	draw_line(Vector2(580, 10), Vector2(580, 630), COURT_LINE, 3.0)
	draw_line(Vector2(175, 10), Vector2(175, 630), COURT_LINE, 2.0)
	draw_line(Vector2(545, 10), Vector2(545, 630), COURT_LINE, 2.0)

	draw_line(Vector2(140, 180), Vector2(580, 180), COURT_LINE, 2.0)
	draw_line(Vector2(140, 460), Vector2(580, 460), COURT_LINE, 2.0)
	draw_line(Vector2(360, 10), Vector2(360, 180), COURT_LINE, 2.0)
	draw_line(Vector2(360, 460), Vector2(360, 630), COURT_LINE, 2.0)

	draw_line(Vector2(140, 320), Vector2(580, 320), Color.BLACK, 6.0)
	draw_line(Vector2(140, 316), Vector2(580, 316), COURT_LINE, 1.0)

	# Aim marker
	if game_state == "ready":
		draw_arc(
			aim_position, 12.0, 0.0, TAU,
			32, INSTRUCTION_COLOR, 3.0
		)
		draw_line(
			aim_position + Vector2(-17, 0),
			aim_position + Vector2(17, 0),
			INSTRUCTION_COLOR, 2.0
		)
		draw_line(
			aim_position + Vector2(0, -17),
			aim_position + Vector2(0, 17),
			INSTRUCTION_COLOR, 2.0
		)

	draw_character(computer_position, COMPUTER_RED, red_racket_direction)
	draw_character(player_position, PLAYER_BLUE, player_racket_direction)

	# Shuttlecock
	draw_circle(shuttle_position, 5.0, SHUTTLE_COLOR)
	draw_line(
		shuttle_position + Vector2(0, 4),
		shuttle_position + Vector2(-7, 12),
		SHUTTLE_COLOR, 2.0
	)
	draw_line(
		shuttle_position + Vector2(0, 4),
		shuttle_position + Vector2(7, 12),
		SHUTTLE_COLOR, 2.0
	)

	# Score and status
	draw_string(
		ThemeDB.fallback_font,
		Vector2(150, 675),
		"Blue: %d    Red: %d    First to %d" % [
			player_score, computer_score, WINNING_SCORE
		],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(150, 695),
		"Red active: " + ("Yes" if red_active else "No"),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INSTRUCTION_COLOR
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(150, 715),
		status_message,
		HORIZONTAL_ALIGNMENT_LEFT, 700, 15, Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(150, 740),
		"Arrow keys: Move Blue | Mouse: Aim | Left-click upper court: Hit",
		HORIZONTAL_ALIGNMENT_LEFT, 700, 14, INSTRUCTION_COLOR
	)


# -------------------- CHARACTER DRAWING --------------------

func draw_character(
	pos: Vector2,
	shirt_color: Color,
	racket_direction: Vector2
) -> void:
	draw_circle(pos + Vector2(0, -15), 8.0, SKIN)
	draw_arc(pos + Vector2(0, -17), 8.0, PI, TAU, 16, HAIR, 3.0)

	draw_rect(Rect2(pos + Vector2(-9, -6), Vector2(18, 22)), shirt_color)

	draw_line(
		pos + Vector2(-8, 0),
		pos + Vector2(-17, 13),
		SKIN, 5.0
	)

	var direction = racket_direction.normalized()
	var hand_start = pos + Vector2(8, 0)
	var hand_end = pos + direction * 22.0
	var racket_end = hand_end + direction * 15.0

	draw_line(hand_start, hand_end, SKIN, 5.0)
	draw_line(hand_end, racket_end, RACKET_COLOR, 3.0)
	draw_arc(racket_end, 7.0, 0.0, TAU, 20, RACKET_COLOR, 2.0)

	draw_line(
		pos + Vector2(-5, 16),
		pos + Vector2(-9, 31),
		PANTS, 6.0
	)
	draw_line(
		pos + Vector2(5, 16),
		pos + Vector2(10, 31),
		PANTS, 6.0
	)

	draw_circle(pos + Vector2(-3, -15), 1.2, Color.BLACK)
	draw_circle(pos + Vector2(3, -15), 1.2, Color.BLACK)
