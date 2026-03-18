extends Button
class_name FurnitureButton

signal furniture_selected(furniture_scene: PackedScene)

@export var furniture_scene: PackedScene
@export var furniture_name: String = "Furniture"

func _ready() -> void:
    text = furniture_name
    pressed.connect(_on_pressed)

func _on_pressed() -> void:
    furniture_selected.emit(furniture_scene)
