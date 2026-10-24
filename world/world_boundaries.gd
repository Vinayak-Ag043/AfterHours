
extends Node3D

@export var wall_height: float = 1.6
@export var wall_thickness: float = 0.3
@export var show_walls: bool = true

var wall_material: StandardMaterial3D
var wall_count: int = 0


func _ready() -> void:
	wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.4, 0.5, 0.55)

	# Corridor: opening toward hostel and common area
	_outline(
		"../Corridor/CorridorFloor/MeshInstance3D",
		"Corridor",
		{
			"north": [Vector2(-1.2, 1.2)],
			"east": [Vector2(5.6, 13.7)]
		}
	)

	# Common area: openings toward corridor, mess, lawn
	_outline(
		"../CommonArea/CommonFloor/MeshInstance3D",
		"Common",
		{
			"west": [Vector2(5.6, 13.7)],
			"south": [Vector2(34.0, 42.0)],
			"east": [Vector2(9.0, 15.0)]
		}
	)

	# Mess: entrance from common area
	_outline(
		"../MessArea/MessFloor/MeshInstance3D",
		"Mess",
		{
			"north": [Vector2(34.0, 42.0)]
		}
	)

	# Thomson Lawn: common area and court connections
	_outline(
		"../ThomsonLawn/LawnFloor/MeshInstance3D",
		"Lawn",
		{
			"west": [Vector2(9.0, 15.0)],
			"east": [Vector2(9.0, 13.0)]
		}
	)

	# Badminton court: entrance from lawn
	_outline(
		"../BadmintonCourt/CourtFloor/MeshInstance3D",
		"Court",
		{
			"west": [Vector2(9.0, 13.0)]
		}
	)

	print("Boundary walls generated: ", wall_count)


func _outline(
	mesh_path: NodePath,
	area_name: String,
	openings: Dictionary
) -> void:
	var floor_mesh := get_node_or_null(mesh_path) as MeshInstance3D

	if floor_mesh == null or floor_mesh.mesh == null:
		push_warning("Missing floor mesh: " + str(mesh_path))
		return

	var bounds := floor_mesh.mesh.get_aabb()

	# Convert local floor corners to world coordinates.
	# Assumes rectangular floors without rotation.
	var a := floor_mesh.to_global(
		Vector3(bounds.position.x, 0, bounds.position.z)
	)
	var b := floor_mesh.to_global(
		Vector3(bounds.end.x, 0, bounds.end.z)
	)

	var min_x := minf(a.x, b.x)
	var max_x := maxf(a.x, b.x)
	var min_z := minf(a.z, b.z)
	var max_z := maxf(a.z, b.z)

	_make_edge(
		area_name, "north",
		min_x, max_x, min_z,
		openings.get("north", []),
		true
	)

	_make_edge(
		area_name, "south",
		min_x, max_x, max_z,
		openings.get("south", []),
		true
	)

	_make_edge(
		area_name, "west",
		min_z, max_z, min_x,
		openings.get("west", []),
		false
	)

	_make_edge(
		area_name, "east",
		min_z, max_z, max_x,
		openings.get("east", []),
		false
	)


func _make_edge(
	area_name: String,
	side: String,
	start: float,
	end: float,
	fixed: float,
	gaps: Array,
	along_x: bool
) -> void:
	var sorted_gaps := gaps.duplicate()
	sorted_gaps.sort_custom(
		func(a, b): return a.x < b.x
	)

	var cursor := start

	for gap in sorted_gaps:
		var gap_start := clampf(gap.x, start, end)
		var gap_end := clampf(gap.y, start, end)

		if gap_start > cursor:
			_create_wall(
				area_name, side,
				cursor, gap_start, fixed, along_x
			)

		cursor = maxf(cursor, gap_end)

	if cursor < end:
		_create_wall(
			area_name, side,
			cursor, end, fixed, along_x
		)


func _create_wall(
	area_name: String,
	side: String,
	start: float,
	end: float,
	fixed: float,
	along_x: bool
) -> void:
	var length := end - start

	if length < 0.05:
		return

	wall_count += 1

	var wall := StaticBody3D.new()
	wall.name = area_name + "_" + side + "_" + str(wall_count)
	add_child(wall)

	var center := (start + end) / 2.0

	if along_x:
		wall.global_position = Vector3(
			center, wall_height / 2.0, fixed
		)
	else:
		wall.global_position = Vector3(
			fixed, wall_height / 2.0, center
		)

	var size: Vector3

	if along_x:
		size = Vector3(
			length, wall_height, wall_thickness
		)
	else:
		size = Vector3(
			wall_thickness, wall_height, length
		)

	# Physical collision
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	wall.add_child(collider)

	# Optional visible wall
	if show_walls:
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = size
		visual.mesh = mesh
		visual.material_override = wall_material
		wall.add_child(visual)
