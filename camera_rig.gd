extends Node3D

@export var target_path: NodePath # drag Ball here in the Inspector
@export var sensitivity := 0.01
@export var vertical_limit := 80.0 # in degrees
@export var follow_lerp := 10.0 # position smoothing

@export var zoom_speed := 2.0
@export var min_zoom := 2.0
@export var max_zoom := 20.0

@onready var spring_arm := $SpringArm

var yaw := 0.0
var pitch := 0.0
var target: Node3D # target is the ball being followed by the camera

func _ready() -> void:
	target = get_node(target_path)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw   -= event.relative.x * sensitivity
		pitch -= event.relative.y * sensitivity
		pitch = clamp(pitch, -vertical_limit, vertical_limit)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		spring_arm.spring_length = max(min_zoom, spring_arm.spring_length - zoom_speed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		spring_arm.spring_length = min(max_zoom, spring_arm.spring_length + zoom_speed)
	
	# press escape key to toggle mouse mode
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

func _process(delta: float) -> void:
	if not target:
		return
	
	# 1 – Follow POSITION only (no rotation inheritance)
	var desired_pos = target.global_position
	global_position = global_position.lerp(desired_pos, follow_lerp * delta)
	
	# 2 – Apply our own yaw/pitch
	rotation_degrees = Vector3(pitch, yaw, 0)
