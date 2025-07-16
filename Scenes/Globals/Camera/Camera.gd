extends Node

var camera_rig: Node3D = null

func set_camera(cam: Node3D) -> void:
	camera_rig = cam

func get_camera_basis() -> Basis:
	if camera_rig == null:
		push_warning("Camera not set in CameraUtils")
		return Basis()
	return camera_rig.global_transform.basis
