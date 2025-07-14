extends RigidBody3D

@export var move_force := 10.0
var max_angular_speed := 10.0

var camera_rig: Node3D # camera following the ball

func _ready():
	# Find CameraRig anywhere in the scene tree
	camera_rig = get_tree().root.get_node("Main/CameraRig")  # Adjust path if needed
	if camera_rig == null:
		push_error("Could not find CameraRig!")
	
	contact_monitor = true
	max_contacts_reported = 32

func _physics_process(delta):
	# handle camera (TODO move this to utility func)
	if camera_rig == null:
		return
	
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_back"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	input_dir = input_dir.normalized()
	if input_dir == Vector3.ZERO:
		return
	
	var cam_basis = camera_rig.global_transform.basis
	var forward = cam_basis.z
	var right = cam_basis.x
	
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

func _on_sticky_area_body_entered(body: Node) -> void:
	if body is RigidBody3D and body.is_in_group("stickable") and not body.has_meta("stuck"):
		body.set_meta("stuck", true)

		# Create PinJoint3D to stick it to the ball
		var joint := PinJoint3D.new()
		joint.node_a = self.get_path()
		joint.node_b = body.get_path()
		joint.position = to_global(Vector3.ZERO)  # center of the ball
		get_tree().current_scene.add_child(joint)

		# Optional: dampen the stuck object's motion
		body.gravity_scale = 0
		body.linear_damp = 1.0
		body.angular_damp = 1.0

		# Optional: increase your ball's mass
		mass += 0.2
