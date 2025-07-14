extends RigidBody3D

@export var move_force := 10.0
@export var jump_force := 5.0

func _physics_process(delta):
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

	# Apply torque for rolling effect
	if input_dir != Vector3.ZERO:
		var torque = Vector3(input_dir.z, 0, -input_dir.x) * move_force
		apply_torque_impulse(torque)

	# Optional jump
	if Input.is_action_just_pressed("jump"):
		apply_central_impulse(Vector3.UP * jump_force)
