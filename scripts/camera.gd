# This Script defines Camera controls
extends Node3D

@export var sensitivity:  float = 0.01
@export var zoom_step:    float = 0.5
@export var min_distance: float = 2.0
@export var max_distance: float = 20.0
@export var min_pitch:    float = -1.2
@export var max_pitch:    float = -0.1

@onready var camera_pitch: Node3D = $Pivot/Pitch
@onready var camera:     Camera3D = $Pivot/Pitch/Camera3D

var yaw:      float = 0.0
var pitch:    float = -0.5
var distance: float = 5.0

func _ready() -> void:
	update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("cam_orbit") and event is InputEventMouseMotion:
		yaw -= event.relative.x * sensitivity
		pitch -= event.relative.y * sensitivity
		pitch = clamp(pitch, min_pitch, max_pitch)
		update_camera()

	if event.is_action_pressed("cam_zoom_in"):
		distance -= zoom_step
		distance = clamp(distance, min_distance, max_distance)
		update_camera()

	if event.is_action_pressed("cam_zoom_out"):
		distance += zoom_step
		distance = clamp(distance, min_distance, max_distance)
		update_camera()

func update_camera() -> void:
	rotation.y = yaw
	camera_pitch.rotation.x = pitch
	camera.position = Vector3(0.0, 0.0, distance)
