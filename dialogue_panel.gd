
extends Control

signal choice_selected(event_id: String, choice_id: String)

@onready var character_name: Label = $BottomContainer/DialogueBox/DialogueLayout/CharacterName
@onready var dialogue_text: Label = $BottomContainer/DialogueBox/DialogueLayout/DialogueText
@onready var choices: VBoxContainer = $BottomContainer/DialogueBox/DialogueLayout/Choices

func _ready() -> void:
	visible = false

func show_event(event_data: Dictionary) -> void:
	character_name.text = str(event_data.get("character_name", "ROOMMATE"))
	dialogue_text.text = str(event_data.get("text", ""))

	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()

	var event_id: String = str(event_data.get("event_id", ""))
	var options: Array = event_data.get("choices", [])

	for option in options:
		var button := Button.new()
		button.text = str(option.get("text", "Continue"))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		button.add_theme_font_override("font", preload("uid://cg5x5qspnwuqh"))
		button.add_theme_font_size_override("font_size", 18)

		var choice_id: String = str(option.get("id", ""))
		button.pressed.connect(_on_choice_pressed.bind(event_id, choice_id))
		choices.add_child(button)

	visible = true

func _on_choice_pressed(event_id: String, choice_id: String) -> void:
	choice_selected.emit(event_id, choice_id)
	visible = false

func close_panel() -> void:
	visible = false
