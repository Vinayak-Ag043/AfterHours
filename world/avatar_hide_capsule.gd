extends Node3D

# Hide only the old capsule visual; preserve player.gd and collision.
func _ready() -> void:
    var player := get_parent()
    var old_visual := player.get_node_or_null("Visual")
    if old_visual is VisualInstance3D:
        old_visual.visible = false
    else:
        # Support alternate player.tscn naming without hiding our avatar.
        for child in player.get_children():
            if child is MeshInstance3D and child != self:
                child.visible = false
