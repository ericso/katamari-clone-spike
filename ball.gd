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

#func _on_sticky_area_body_entered(body: Node) -> void:
	#if body == self:
		#return  # don't process self
#
	#print("DEBUG::_on_sticky_area_body_entered:", body.name)
#
	#if body is RigidBody3D and body.is_in_group("stickable") and not body.has_meta("stuck"):
		#print("STICKING:", body.name)
		#body.set_meta("stuck", true)
#
		#var joint := PinJoint3D.new()
		#get_tree().current_scene.add_child(joint)
		#joint.node_a = self.get_path()
		#joint.node_b = body.get_path()
		#joint.position = body.global_position
#
		#body.gravity_scale = 0
		#body.linear_damp = 10
		#body.angular_damp = 10
		
func _on_sticky_area_body_entered(body: Node) -> void:
	if body == self:
		return

	if body is RigidBody3D and body.is_in_group("stickable") and not body.has_meta("stuck"):
		body.set_meta("stuck", true)

		var local_transform = self.global_transform.affine_inverse() * body.global_transform

		# 1. Copy MeshInstance3D
		var original_mesh := body.get_node_or_null("MeshInstance")
		if original_mesh:
			var mesh_copy := MeshInstance3D.new()
			mesh_copy.mesh = original_mesh.mesh
			mesh_copy.material_override = original_mesh.material_override
			mesh_copy.transform = local_transform
			mesh_copy.scale = original_mesh.scale
			add_child(mesh_copy)

		# 2. Copy CollisionShape3D
		var shape_node := body.get_node_or_null("CollisionShape")
		if shape_node and shape_node.shape:
			var new_shape := CollisionShape3D.new()
			new_shape.shape = shape_node.shape.duplicate()  # don't reuse!
			new_shape.transform = local_transform
			add_child(new_shape)

		# 3. (Optional) increase ball's mass
		mass += 0.2

		# 4. Remove original physics body
		body.queue_free()
