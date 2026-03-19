extends Control

@export_node_path("LineEdit") var width_path: NodePath
@export_node_path("LineEdit") var depth_path: NodePath
@export_node_path("LineEdit") var height_path: NodePath
@export_node_path("Button") var close_button_path: NodePath
@export_node_path("Button") var delete_button_path: NodePath
@export_node_path("FurniturePicker") var furniture_picker_path: NodePath

@onready var width: LineEdit = get_node(width_path)
@onready var depth: LineEdit = get_node(depth_path)
@onready var height: LineEdit = get_node(height_path)
@onready var close_button: Button = get_node(close_button_path)
@onready var delete_button: Button = get_node(delete_button_path)
@onready var furniture_picker: FurniturePicker = get_node(furniture_picker_path)

var current_piece: Furniture = null

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added) # on new child added
	close_button.pressed.connect(_on_close_pressed)
	delete_button.pressed.connect(_on_delete_pressed)

func _on_node_added(node: Node) -> void:
	if node is Furniture and node.name != "PREVIEW":
		node.area_clicked.connect(func():
			_open_edit_dialog(node)
		)

func _on_close_pressed():
	if is_instance_valid(current_piece):
		current_piece.set_size(Vector3(float(width.text), float(height.text), float(depth.text)))
	self.visible = false

func _on_delete_pressed():
	if is_instance_valid(current_piece):
		furniture_picker.remove_furniture(current_piece)
	self.visible = false

func _open_edit_dialog(piece: Furniture) -> void:
	current_piece = piece
	width.text = str(current_piece.size.x)
	depth.text = str(current_piece.size.z)
	height.text = str(current_piece.size.y)
	self.visible = true
