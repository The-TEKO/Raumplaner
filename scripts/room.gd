# This Script defines the Room
extends Node3D
class_name Room

# ---- Exported Variables ---- #
@export var room_width: float  = 5
@export var room_depth: float  = 5
@export var room_height: float = 2

# ---- Node References ---- #
@onready var mesh_floor  = $Floor
@onready var mesh_roof   = $Roof
@onready var mesh_wall_n = $Wall_N
@onready var mesh_wall_e = $Wall_E
@onready var mesh_wall_s = $Wall_S
@onready var mesh_wall_w = $Wall_W

# ---- Methods ---- #
func _ready() -> void:
	update_room()

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

func _process(_delta: float):
	update_room()
