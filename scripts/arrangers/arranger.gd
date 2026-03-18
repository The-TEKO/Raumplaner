# This Script defines the core layout generation algorithm
extends Node
class_name Arranger

@export var picker_path: NodePath

var placed_furniture: Dictionary[Furniture.PlacementType, Array] = {}

@onready var picker: FurniturePicker = get_node(picker_path)

func _ready() -> void:
	picker.furniture_added.connect(_on_furniture_added)

func _on_furniture_added(furniture: Furniture, _position: Vector3):
	add_furniture_to_list(furniture)

func add_furniture_to_list(piece: Furniture):
	var type = piece.placement_type

	if not type in placed_furniture:
		placed_furniture[type] = [] as Array[Furniture]

	placed_furniture[type].append(piece)

func remove_furniture_to_list(piece: Furniture):
	var type = piece.placement_type

	if not type in placed_furniture: 
		return # no furniture of that type added

	# remove from list
	var idx = placed_furniture[type].find(piece)
	if idx != -1:
		placed_furniture[type].remove_at(idx)

func do_layout_generation():
	pass
