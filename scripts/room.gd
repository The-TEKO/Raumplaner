# This Script defines the Room
extends Node3D
class_name Room

@export_node_path("OmniLight3D") var light_path: NodePath
@export_node_path("MeshInstance3D") var mesh_floor_path:  NodePath
@export_node_path("MeshInstance3D") var mesh_roof_path:   NodePath
@export_node_path("MeshInstance3D") var mesh_wall_n_path: NodePath
@export_node_path("MeshInstance3D") var mesh_wall_e_path: NodePath
@export_node_path("MeshInstance3D") var mesh_wall_s_path: NodePath
@export_node_path("MeshInstance3D") var mesh_wall_w_path: NodePath

@export var room_width:  float = 5
@export var room_depth:  float = 5
@export var room_height: float = 2

@onready var light: OmniLight3D = get_node(light_path)
@onready var mesh_floor:  MeshInstance3D = get_node(mesh_floor_path)
@onready var mesh_roof:   MeshInstance3D = get_node(mesh_roof_path)
@onready var mesh_wall_n: MeshInstance3D = get_node(mesh_wall_n_path)
@onready var mesh_wall_e: MeshInstance3D = get_node(mesh_wall_e_path)
@onready var mesh_wall_s: MeshInstance3D = get_node(mesh_wall_s_path)
@onready var mesh_wall_w: MeshInstance3D = get_node(mesh_wall_w_path)

signal area_clicked()

func _ready() -> void:
	update_room()
	# set up clicked
	var areas := get_tree().get_nodes_in_group("walls")
	for area in areas:
		area.input_event.connect(_on_area_3d_input_event)

func _process(_delta: float):
	update_room()
	update_wall_visibility()

func update_room():
	# Floor & Ceiling
	mesh_floor.scale   = Vector3(room_width, room_depth, 1)
	mesh_roof.scale    = Vector3(room_width, room_depth, 1)
	mesh_roof.position = Vector3(0, room_height, 0)

	# Wall N
	mesh_wall_n.scale    = Vector3(room_width, room_height, 1)
	mesh_wall_n.position = Vector3(0, room_height / 2.0, -room_depth / 2.0)

	# Wall S
	mesh_wall_s.scale    = Vector3(room_width, room_height, 1)
	mesh_wall_s.position = Vector3(0, room_height / 2.0, room_depth / 2.0)

	# Wall E
	mesh_wall_e.scale    = Vector3(room_depth, room_height, 1)
	mesh_wall_e.position = Vector3(room_width / 2.0, room_height / 2.0, 0)

	# Wall W
	mesh_wall_w.scale    = Vector3(room_depth, room_height, 1)
	mesh_wall_w.position = Vector3(-room_width / 2.0, room_height / 2.0, 0)

func update_wall_visibility() -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	var cam_pos: Vector3 = to_local(cam.global_position)
	# Hide a wall only when the camera is clearly outside its boundary
	var threshold: float = 1.0
	mesh_wall_n.visible = cam_pos.z >= -(room_depth / 2.0) - threshold
	mesh_wall_s.visible = cam_pos.z <=  (room_depth / 2.0) + threshold
	mesh_wall_e.visible = cam_pos.x <=  (room_width / 2.0) + threshold
	mesh_wall_w.visible = cam_pos.x >= -(room_width / 2.0) - threshold

func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		emit_signal("area_clicked")
