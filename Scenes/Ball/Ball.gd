extends RigidBody3D

@export var stuck_parts_container_path: NodePath = "StuckParts"

@export var move_force := 3.0
var max_angular_speed := 5.0

@export var jump_force := 10.0
var can_jump := false

# initial ball radius, used to keep track of the collision sphere radius and
# in scaling the ball when it grows
var ball_radius := 0.5 
@export var growth_factor := 1.0 # growth_factor is a multipler for how fast the ball grows

const STICKABLE_GROUP := "stickable"
const STUCK_META := "stuck"
const STUCK_COLLISION_META := "stuck_collision"

func _ready():
	contact_monitor = true
	max_contacts_reported = 32
	body_entered.connect(_on_body_entered)
	
	# used to detect if the ball is in the air
	$GroundCheck.enabled = true

func _physics_process(_delta):
	if Input.is_action_pressed("absorb"):
		absorb_stuck_parts()
	
	handle_movement(Camera.get_camera_basis())

# _on_body_entered is the handler for when an object collides with (enters)
# the ball. We use it "stick" to it objects in the "stickable" group, that have
# not already been "stuck".
func _on_body_entered(body: Node) -> void:
	if body is RigidBody3D \
		and body.is_in_group(STICKABLE_GROUP) \
		and not body.has_meta(STUCK_META):
		body.set_meta(STUCK_META, true)
		
		# copy visual mesh
		var mesh_node := body.get_node_or_null("MeshInstance")
		if mesh_node:
			var mesh_copy := MeshInstance3D.new()
			mesh_copy.mesh = mesh_node.mesh
			mesh_copy.material_override = mesh_node.material_override
			mesh_copy.scale = mesh_node.scale
			
			get_node(stuck_parts_container_path).add_child(mesh_copy)
			mesh_copy.global_transform = mesh_node.global_transform
		
		# copy collision shape
		var shape_node := body.get_node_or_null("CollisionShape")
		if shape_node and shape_node.shape:
			var shape_copy := CollisionShape3D.new()
			shape_copy.shape = shape_node.shape.duplicate()
			shape_copy.set_meta(STUCK_COLLISION_META, true)
			
			add_child(shape_copy)
			shape_copy.global_transform = shape_node.global_transform
		
		# increase the mass of the ball
		mass += body.mass
		
		# despawn the attached body
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

# absorb_stuck_parts 
func absorb_stuck_parts():
	var stuck_container = get_node(stuck_parts_container_path)
	var total_volume := 0.0
	
	# remove the visual objects from the ball
	for part in stuck_container.get_children():
		if part is MeshInstance3D:
			var pscale = part.scale
			var volume: float = pscale.x * pscale.y * pscale.z
			total_volume += volume
			part.queue_free()
	
	# remove the objects' collision shapes
	for child in get_children():
		if child is CollisionShape3D and child.has_meta(STUCK_COLLISION_META):
			child.queue_free()
	
	if total_volume > 0.0:
		mass += total_volume
		# normalize the increase in radius of the ball
		var normalized_increase = pow((pow(ball_radius, 3) + total_volume), 1.0 / 3.0) - ball_radius
		grow_by(normalized_increase)

# grow_by increases the ball's radius. It handles scaling the collision shape and mesh.
func grow_by(delta: float) -> void:
	# update the ball_radius tracking variable
	ball_radius += delta * growth_factor
	
	# update collision shape
	var shape_node = get_node_or_null("CollisionShape")
	if shape_node and shape_node.shape is SphereShape3D:
		var sphere := shape_node.shape as SphereShape3D
		sphere.radius = ball_radius
	
	# update mesh
	var mesh_node = get_node_or_null("MeshInstance")
	if mesh_node:
		# scaling a sphere mesh is equavilant to increasing the diameter by the factor
		# thus we multiply the factor by 2, since we scaled the collision sphere's
		# radius
		mesh_node.scale = Vector3.ONE * 2 * ball_radius
		
	# update GroundCheck RayCast vector
	var new_y = $GroundCheck.target_position.y - (ball_radius + abs($GroundCheck.target_position.y))/abs($GroundCheck.target_position.y)
	$GroundCheck.target_position.y = new_y
