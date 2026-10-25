extends Control

@onready var activity_menu: Control = $ActivityMenu

func _ready() -> void:
	# 1. Connect signals to custom print functions
	activity_menu.activity_selected.connect(_on_activity_selected)
	activity_menu.preview_requested.connect(_on_preview_requested)
	
	# 2. RUN YOUR TEST HERE (Change the text inside the quotes to test different options)
	# Options to try: "study_table", "bed", or "roommate"
	activity_menu.show_activity("study_table")


# This runs whenever you click an action button
func _on_activity_selected(activity_id: String, duration: int) -> void:
	print("Selected: %s for %d minutes" % [activity_id, duration])


# This runs if your menu has a preview function
func _on_preview_requested(activity_id: String, duration: int) -> void:
	print("Previewing: %s for %d minutes" % [activity_id, duration])
