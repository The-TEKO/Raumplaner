# This Class defines the basics of a furniture object
@icon("res://editor/icon_table.png")
extends Node3D
class_name Furniture

enum PlacementType {
	WALL,
	FLOOR_WALL_ADJ,
	FLOOR
}

@export_node_path("Node3D") var model_path:  NodePath
@export_node_path("Area3D") var area3d_path: NodePath
@export_node_path("CollisionShape3D") var collider_path: NodePath

@export var placement_type: PlacementType = PlacementType.FLOOR
@export var locked:         bool          = false
@export var size:           Vector3       = Vector3(1, 1, 1)

@onready var model:    Node3D           = get_node(model_path)
@onready var area3d:   Area3D           = get_node(area3d_path)
@onready var collider: CollisionShape3D = get_node(collider_path)

signal area_clicked()

func _ready() -> void:
	set_size(size)
	# set up clicked
	area3d.input_event.connect(_on_area_3d_input_event)
	
func set_size(new_size:Vector3) -> void:
	size = new_size
	
	# apply scale to model
	model.scale = new_size

	# apply size to collider
	var shape := collider.shape as BoxShape3D # cast as BoxShape3D (!)
	shape.size = new_size
	collider.position = Vector3(0, new_size.y / 2, 0) # move up so it is centered

func is_inside_room() -> bool:
	# check if the furniture is not colliding with any walls
	var colliding_areas := get_colliding()
	for area in colliding_areas:
		if area.is_in_group("walls"):
			return false
	return true

func get_colliding() -> Array[Area3D]:
	# get colliding areas and return them
	return area3d.get_overlapping_areas()

func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		emit_signal("area_clicked")
