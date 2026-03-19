extends Node
class_name AlgorithmPicker

@export var algorithm_options: Dictionary[String, Arranger] = {}

@export_node_path("OptionButton") var opt_button_path: NodePath
@export_node_path("Button") var confirm_button_path: NodePath

@onready var opt_button: OptionButton = get_node(opt_button_path)
@onready var confirm_button: Button = get_node(confirm_button_path)

func _ready():
	for id in algorithm_options:
		opt_button.add_item(id)
	confirm_button.pressed.connect(_on_confirm_pressed)

func _on_confirm_pressed():
	var item = opt_button.get_item_text(opt_button.selected)
	var arranger = algorithm_options[item]
	arranger.do_layout_generation()
	
