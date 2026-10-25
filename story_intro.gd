
extends Control

signal intro_finished

@onready var header_label: Label = $MarginContainer/Content/HeaderLabel
@onready var panel_image: TextureRect = $MarginContainer/Content/PanelImage
@onready var caption_label: Label = $MarginContainer/Content/CaptionPanel/CaptionLabel
@onready var next_button: Button = $MarginContainer/Content/ButtonRow/NextButton
@onready var skip_button: Button = $MarginContainer/Content/ButtonRow/SkipButton
@onready var music_player: AudioStreamPlayer = $MusicPlayer

var current_panel: int = 0
var intro_active: bool = true

var story_panels: Array[Dictionary] = [
	{
		"image": preload("uid://divfh5t44sqyd"),
		"heading": "JUST ANOTHER DAY AT IITR",
		"caption": "Classes, lectures, endless notes. Another day in the life of an IITR student."
	},
	{
		"image": preload("uid://c8xitjtmnrawi"),
		"heading": "LIFE IS GOOD",
		"caption": "Between classes, there were friends to meet, jokes to share, and memories to make."
	},
	{
		"image": preload("uid://cj0k8064tuawy"),
		"heading": "WHO NEEDS A PLAN?",
		"caption": "One more conversation. One more game. The assignment could wait a little longer... right?"
	},
	{
		"image": preload("uid://bsgtkmusxvt0t"),
		"heading": "AND THEN CAME NIGHTFALL",
		"caption": "It's evening. The hostel is buzzing, but your unfinished assignment is suddenly looking very, very real."
	},
	{
		"image": preload("uid://c73qixs14crkh"),
		"heading": "THE NIGHTMARE BEGINS",
		"caption": "You need to study, grab a meal, get some sleep, and somehow find time for your friends. All before morning."
	},
	
]

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_on_skip_pressed)

	show_panel(0)
	# Force the layout to fit the screen
	$MarginContainer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$MarginContainer/Content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var content = $MarginContainer/Content
	var image = $MarginContainer/Content/PanelImage
	var caption = $MarginContainer/Content/CaptionPanel
	var buttons = $MarginContainer/Content/ButtonRow

	# Only the image gets the extra vertical space
	content.add_theme_constant_override("separation", 12)

	image.custom_minimum_size.y = 300
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL

	caption.custom_minimum_size.y = 85
	caption.size_flags_vertical = Control.SIZE_FILL

	buttons.custom_minimum_size.y = 48
	buttons.size_flags_vertical = Control.SIZE_FILL
	buttons.visible = true

	$MarginContainer/Content/HeaderLabel.custom_minimum_size.y = 40
	$MarginContainer/Content/HeaderLabel.visible = true

	$MarginContainer/Content/CaptionPanel/CaptionLabel.custom_minimum_size.y = 0

	$MarginContainer/Content/ButtonRow/NextButton.visible = true
	$MarginContainer/Content/ButtonRow/SkipButton.visible = true
	if music_player.stream != null:
		music_player.play()


func show_panel(index: int) -> void:
	current_panel = index
	var panel: Dictionary = story_panels[current_panel]

	panel_image.texture = panel["image"]
	header_label.text = panel["heading"]
	caption_label.text = panel["caption"]

	var is_last = current_panel == story_panels.size() - 1

	# Final panel: force a compact, readable layout
	if is_last:
		header_label.visible = true
		panel_image.visible = true
		caption_label.visible = true
		next_button.visible = true
		skip_button.visible = true

		header_label.add_theme_font_size_override("font_size", 26)
		caption_label.add_theme_font_size_override("font_size", 18)

		panel_image.custom_minimum_size = Vector2(0, 0)
		panel_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		caption_label.clip_text = false
		caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD

		next_button.text = "Start Game →"
	else:
		next_button.text = "Next →"

func _on_next_pressed() -> void:
	if not intro_active:
		return

	if current_panel < story_panels.size() - 1:
		show_panel(current_panel + 1)
	else:
		finish_intro()


func _on_skip_pressed() -> void:
	finish_intro()


func finish_intro() -> void:
	if not intro_active:
		return

	intro_active = false
	music_player.stop()
	hide()
	intro_finished.emit()
