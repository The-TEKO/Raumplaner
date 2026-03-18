# This Class defines the basics of a furniture object
@icon("res://editor/icon_table.png")
extends Node3D
class_name Furniture

enum PlacementType {
	WALL,
	FLOOR_WALL_ADJ,
	FLOOR
}

@export var placement_type: PlacementType = PlacementType.FLOOR
@export var can_resize:     bool          = true
@export var size:           Vector3       = Vector3(1, 1, 1)

@onready var model:    Node3D           = $Model
@onready var collider: CollisionShape3D = $StaticBody3D/CollisionShape3D

func _ready() -> void:
	set_size(size)

func set_size(new_size:Vector3):
	model.scale    = new_size
	collider.scale = new_size
	collider.position = Vector3(0, new_size.y / 2.0, 0)
