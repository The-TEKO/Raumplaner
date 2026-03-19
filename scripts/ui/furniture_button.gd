extends Button
class_name FurnitureButton

signal furniture_selected(furniture_scene: PackedScene)

@export var furniture_scene: PackedScene

func _ready() -> void:
    # set button text
    if furniture_scene:
        # to get the name of the furniture, it has to be instantiated first
        var instance = furniture_scene.instantiate()
        text = instance.name
        instance.queue_free() # delete after getting name
    
    # connect button press event
    pressed.connect(_on_pressed)

func _on_pressed() -> void:
    furniture_selected.emit(furniture_scene)
