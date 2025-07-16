extends Node

@export var box_scene: PackedScene
@export var box_count := 10000
@export var scatter_radius := 100.0
@export var density := 10.0

func spawn_objects():
	for i in box_count:
		Spawner.spawn_scaled_box()

func spawn_scaled_box():
	var box := box_scene.instantiate()
	add_child(box)

	var scale := randf_range(0.1, 0.5)

	# Create a new collision shape
	var shape_node := box.get_node("CollisionShape")
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * scale
	shape_node.shape = shape
	shape_node.transform.origin.y = shape.size.y / 2.0

	# Scale and reposition the mesh
	var mesh := box.get_node("MeshInstance")
	mesh.scale = Vector3.ONE * scale
	mesh.position.y = shape.size.y / 2.0

	# Set the mass of the box based on size
	var volume = mesh.scale.x * mesh.scale.y * mesh.scale.z
	box.mass = volume * density
	
	# Place box flush with ground
	box.global_position = Vector3(
		randf_range(-scatter_radius, scatter_radius),
		shape.size.y / 2.0,
		randf_range(-scatter_radius, scatter_radius)
	)
