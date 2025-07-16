extends RigidBody3D

@export var stuck_parts_container_path: NodePath = "StuckParts"

@export var move_force := 3.0
var max_angular_speed := 5.0

@export var jump_force := 10.0
var can_jump := false

func _ready():
	contact_monitor = true
	max_contacts_reported = 32
	body_entered.connect(_on_body_entered)
	
	# used to detect if the ball is in the air
	$GroundCheck.enabled = true

func _physics_process(_delta):
	handle_movement(Camera.get_camera_basis())

func _on_body_entered(body: Node) -> void:
	if body is RigidBody3D and body.is_in_group("stickable") and not body.has_meta("stuck"):
		body.set_meta("stuck", true)
		
		var mesh_node := body.get_node_or_null("MeshInstance")
		if mesh_node:
			var mesh_copy := MeshInstance3D.new()
			mesh_copy.mesh = mesh_node.mesh
			mesh_copy.material_override = mesh_node.material_override
			mesh_copy.scale = mesh_node.scale
			
			get_node(stuck_parts_container_path).add_child(mesh_copy)
			mesh_copy.global_transform = mesh_node.global_transform
		
		var shape_node := body.get_node_or_null("CollisionShape")
		if shape_node and shape_node.shape:
			var shape_copy := CollisionShape3D.new()
			shape_copy.shape = shape_node.shape.duplicate()
			
			add_child(shape_copy)
			shape_copy.global_transform = shape_node.global_transform
		
		mass += 0.5
		
		body.queue_free()

# handle_movement handles moving the ball
# This function is meant to be called on every physics process loop
func handle_movement(camera_basis: Basis) -> void:
	if $GroundCheck.is_colliding():
		can_jump = true
	else:
		can_jump = false
		
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_back"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_just_pressed("jump") and can_jump:
		apply_impulse(Vector3.UP * jump_force)
		can_jump = false
	
	input_dir = input_dir.normalized()
	if input_dir == Vector3.ZERO:
		return
	
	# movement is dependent on the direction in which the camera is pointed
	var forward = camera_basis.z
	var right = camera_basis.x
	
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	var move_vec = (forward * input_dir.z + right * input_dir.x).normalized()
	var torque = Vector3(move_vec.z, 0, -move_vec.x) * move_force
	apply_torque_impulse(torque)
	
	# Clamp spin
	if angular_velocity.length() > max_angular_speed:
		angular_velocity = angular_velocity.normalized() * max_angular_speed
