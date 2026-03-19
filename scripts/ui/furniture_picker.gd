extends Node
class_name FurniturePicker

signal furniture_added(furniture: Furniture, position: Vector3)
signal furniture_removed(furniture: Furniture)

@export_node_path("VBoxContainer") var button_container_path: NodePath
@export_node_path("Node3D") var furniture_3d_container_path: NodePath

var selected_furniture_scene: PackedScene = null
var preview_instance: Furniture = null
var camera: Camera3D = null

@onready var button_container: Node = get_node(button_container_path)
@onready var furniture_3d_container: Node3D = get_node(furniture_3d_container_path)

func _ready() -> void:
	camera = get_viewport().get_camera_3d() # get current camera
	for child in button_container.get_children():
		if child is FurnitureButton:
			child.furniture_selected.connect(_on_furniture_selected)

func _on_furniture_selected(furniture_scene: PackedScene) -> void:
	selected_furniture_scene = furniture_scene
	create_preview()

func create_preview() -> void:
	if preview_instance != null:
		preview_instance.queue_free()
		preview_instance = null

	if selected_furniture_scene == null:
		return

	preview_instance = selected_furniture_scene.instantiate() as Furniture
	preview_instance.name = "PREVIEW"
	furniture_3d_container.add_child(preview_instance)
	update_preview_position()

func _unhandled_input(event: InputEvent) -> void:
	if selected_furniture_scene == null:
		return

	if event is InputEventMouseMotion:
		update_preview_position()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_selected_furniture()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_placement()

	if event.is_action_pressed("ui_cancel"):
		cancel_placement()

func update_preview_position() -> void:
	if preview_instance == null:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)

	if abs(ray_dir.y) < 0.0001:
		return

	var t := -ray_origin.y / ray_dir.y
	if t < 0.0:
		return

	var hit_pos := ray_origin + ray_dir * t
	preview_instance.global_position = hit_pos

func place_selected_furniture() -> void:
	if preview_instance == null or selected_furniture_scene == null:
		return

	var placed := selected_furniture_scene.instantiate() as Furniture
	placed.global_transform = preview_instance.global_transform
	furniture_3d_container.add_child(placed)
	furniture_added.emit(placed, preview_instance.global_position)
	cancel_placement()

func cancel_placement() -> void:
	if preview_instance != null:
		preview_instance.queue_free()
		preview_instance = null

	selected_furniture_scene = null

func remove_furniture(furniture: Furniture) -> void:
	if furniture.get_parent() == furniture_3d_container:
		furniture.queue_free()
		furniture_removed.emit(furniture)