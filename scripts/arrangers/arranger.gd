# This Script defines the core layout generation algorithm
@abstract extends Node
class_name Arranger

@export_node_path("FurniturePicker") var furniture_picker_path: NodePath

@onready var furniture_picker: FurniturePicker = get_node(furniture_picker_path)

var placed_furniture: Dictionary[Furniture.PlacementType, Array] = {}

func _ready() -> void:
	furniture_picker.furniture_added.connect(_on_furniture_added)
	furniture_picker.furniture_removed.connect(_on_furniture_removed)
	for type in Furniture.PlacementType.values():
		placed_furniture[type] = [] as Array[Furniture]

func _on_furniture_added(furniture: Furniture, _position: Vector3):
	add_furniture_to_list(furniture)

func _on_furniture_removed(furniture: Furniture):
	remove_furniture_from_list(furniture)

func add_furniture_to_list(piece: Furniture):
	var type = piece.placement_type

	if not type in placed_furniture:
		placed_furniture[type] = [] as Array[Furniture]

	placed_furniture[type].append(piece)

func remove_furniture_from_list(piece: Furniture):
	var type = piece.placement_type

	if not type in placed_furniture: 
		return # no furniture of that type added

	# remove from list
	var idx = placed_furniture[type].find(piece)
	if idx != -1:
		placed_furniture[type].remove_at(idx)

@abstract func do_layout_generation()
