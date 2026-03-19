extends Control

@export_node_path("Room") var room_path: NodePath
@export_node_path("LineEdit") var width_path: NodePath
@export_node_path("LineEdit") var depth_path: NodePath
@export_node_path("LineEdit") var height_path: NodePath
@export_node_path("Button") var close_button_path: NodePath

@onready var room: Room = get_node(room_path)
@onready var width: LineEdit = get_node(width_path)
@onready var depth: LineEdit = get_node(depth_path)
@onready var height: LineEdit = get_node(height_path)
@onready var close_button: Button = get_node(close_button_path)

func _ready() -> void:
	width.text = str(room.room_width)
	depth.text = str(room.room_depth)
	height.text = str(room.room_height)
	
	room.area_clicked.connect(_on_area_clicked)
	close_button.pressed.connect(_on_close_pressed)

func _on_area_clicked():
	self.visible = true

func _on_close_pressed():
	room.room_width = float(width.text)
	room.room_depth = float(depth.text)
	room.room_height = float(height.text)
	room.update_room()
	self.visible = false
