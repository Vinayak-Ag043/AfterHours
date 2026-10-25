
extends CanvasLayer

@onready var objective_label: Label = $Root/ObjectivePanel/ObjectiveLayout/ObjectiveLabel
@onready var mission_label: Label = $Root/ObjectivePanel/ObjectiveLayout/MissionLabel
@onready var notification_panel: PanelContainer = $Root/NotificationPanel
@onready var notification_label: Label = $Root/NotificationPanel/NotificationLabel

#func _ready() -> void:
#	notification_panel.visible = false


func update_objective(text: String) -> void:
	objective_label.text = "OBJECTIVE: " + text

func update_mission(text: String) -> void:
	mission_label.text = "ROOMMATE: " + text

func show_notification(text: String) -> void:
	notification_label.text = text
	notification_panel.visible = true

func hide_notification() -> void:
	notification_panel.visible = false
