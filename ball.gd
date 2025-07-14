extends RigidBody3D

@export var move_force := 10.0
var max_angular_speed := 10.0

var camera_rig: Node3D

func _ready():
	# Find CameraRig anywhere in the scene tree
	camera_rig = get_tree().root.get_node("Main/CameraRig")  # Adjust path if needed
	if camera_rig == null:
		push_error("Could not find CameraRig!")

func _physics_process(delta):
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
