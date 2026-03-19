extends Arranger
class_name Arranger_Algo

enum WallSide {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

@export var room_path: NodePath
@export var randomize_on_ready: bool = true

@onready var room: Room = get_node(room_path)

# Für jede Wand merken wir uns belegte Bereiche.
# Eintrag-Format:
# {
#   "along_min": float,
#   "along_max": float,
#   "bottom": float,
#   "top": float
# }
var wall_occupancy := {
	WallSide.NORTH: [],
	WallSide.EAST: [],
	WallSide.SOUTH: [],
	WallSide.WEST: []
}

func _ready() -> void:
	super._ready()
	if randomize_on_ready:
		randomize()


func do_layout_generation():
	_clear_occupancy()

	# 1) FLOOR_WALL_ADJ zuerst
	var floor_adj: Array[Furniture] = _get_sorted_furniture(Furniture.PlacementType.FLOOR_WALL_ADJ)
	for piece in floor_adj:
		_place_floor_wall_adj(piece)

	# 2) Dann WALL
	var wall_items: Array[Furniture] = _get_sorted_furniture(Furniture.PlacementType.WALL)
	for piece in wall_items:
		_place_wall_item(piece)


# -------------------------------------------------------------------
# Sortierung
# -------------------------------------------------------------------

func _get_sorted_furniture(type: Furniture.PlacementType) -> Array[Furniture]:
	var result: Array[Furniture] = []

	if type in placed_furniture:
		for piece in placed_furniture[type]:
			if is_instance_valid(piece):
				result.append(piece)

	result.sort_custom(_sort_by_volume_desc)
	return result


func _sort_by_volume_desc(a: Furniture, b: Furniture) -> bool:
	var va := a.size.x * a.size.y * a.size.z
	var vb := b.size.x * b.size.y * b.size.z
	return va > vb


# -------------------------------------------------------------------
# Platzierung FLOOR_WALL_ADJ
# -------------------------------------------------------------------

func _place_floor_wall_adj(piece: Furniture) -> bool:
	var wall_order = _random_wall_order()

	for wall in wall_order:
		var placed := _try_place_on_wall(piece, wall, false)
		if placed:
			return true

	push_warning("Kein Platz gefunden für FLOOR_WALL_ADJ: %s" % piece.name)
	return false


# -------------------------------------------------------------------
# Platzierung WALL
# -------------------------------------------------------------------

func _place_wall_item(piece: Furniture) -> bool:
	var wall_order = _random_wall_order()

	for wall in wall_order:
		var placed := _try_place_on_wall(piece, wall, true)
		if placed:
			return true

	push_warning("Kein Platz gefunden für WALL: %s" % piece.name)
	return false


# -------------------------------------------------------------------
# Kernlogik
# -------------------------------------------------------------------

func _try_place_on_wall(piece: Furniture, wall: WallSide, allow_vertical_shift: bool) -> bool:
	var along_len := _get_along_length(piece, wall)
	var depth := _get_depth_to_wall(piece, wall)
	var height := piece.size.y

	var wall_span := _get_wall_span(wall)
	var min_along: float = wall_span.x + along_len * 0.5
	var max_along: float = wall_span.y - along_len * 0.5

	if min_along > max_along:
		return false

	# Startposition zufällig entlang der Wand
	var start_along := randf_range(min_along, max_along)

	# FLOOR_WALL_ADJ startet unten
	# WALL startet ebenfalls unten, darf aber nach oben verschoben werden
	var start_bottom := 0.0

	# Kandidaten: zuerst Startposition, dann schrittweise links/rechts
	var along_candidates := _build_along_candidates(start_along, min_along, max_along, along_len)

	if allow_vertical_shift:
		var vertical_candidates := _build_vertical_candidates(height)
		for bottom in vertical_candidates:
			if bottom + height > room.room_height:
				continue

			for along_center in along_candidates:
				var rect = {
					"along_min": along_center - along_len * 0.5,
					"along_max": along_center + along_len * 0.5,
					"bottom": bottom,
					"top": bottom + height
				}

				if not _rect_overlaps_wall(rect, wall):
					_commit_placement(piece, wall, along_center, bottom, depth, along_len, height)
					return true
	else:
		for along_center in along_candidates:
			var rect = {
				"along_min": along_center - along_len * 0.5,
				"along_max": along_center + along_len * 0.5,
				"bottom": start_bottom,
				"top": start_bottom + height
			}

			if not _rect_overlaps_wall(rect, wall):
				_commit_placement(piece, wall, along_center, start_bottom, depth, along_len, height)
				return true

	return false


func _commit_placement(
	piece: Furniture,
	wall: WallSide,
	along_center: float,
	bottom: float,
	depth: float,
	along_len: float,
	height: float
) -> void:
	var pos := _wall_to_world_position(wall, along_center, bottom, depth, piece)
	piece.position = pos
	piece.rotation = _wall_rotation(wall)

	wall_occupancy[wall].append({
		"along_min": along_center - along_len * 0.5,
		"along_max": along_center + along_len * 0.5,
		"bottom": bottom,
		"top": bottom + height
	})


# -------------------------------------------------------------------
# Belegung / Overlap
# -------------------------------------------------------------------

func _rect_overlaps_wall(rect: Dictionary, wall: WallSide) -> bool:
	for other in wall_occupancy[wall]:
		var along_overlap = rect["along_min"] < other["along_max"] and rect["along_max"] > other["along_min"]
		var vertical_overlap = rect["bottom"] < other["top"] and rect["top"] > other["bottom"]

		if along_overlap and vertical_overlap:
			return true

	return false


func _clear_occupancy() -> void:
	for key in wall_occupancy.keys():
		wall_occupancy[key].clear()


# -------------------------------------------------------------------
# Hilfsfunktionen Geometrie
# -------------------------------------------------------------------

func _get_along_length(piece: Furniture, wall: WallSide) -> float:
	match wall:
		WallSide.NORTH, WallSide.SOUTH:
			return piece.size.x
		WallSide.EAST, WallSide.WEST:
			return piece.size.z
	return piece.size.x


func _get_depth_to_wall(piece: Furniture, wall: WallSide) -> float:
	match wall:
		WallSide.NORTH, WallSide.SOUTH:
			return piece.size.z
		WallSide.EAST, WallSide.WEST:
			return piece.size.x
	return piece.size.z


func _get_wall_span(wall: WallSide) -> Vector2:
	match wall:
		WallSide.NORTH, WallSide.SOUTH:
			return Vector2(-room.room_width * 0.5, room.room_width * 0.5)
		WallSide.EAST, WallSide.WEST:
			return Vector2(-room.room_depth * 0.5, room.room_depth * 0.5)
	return Vector2.ZERO


func _wall_to_world_position(
	wall: WallSide,
	along_center: float,
	bottom: float,
	depth: float,
	piece: Furniture
) -> Vector3:
	var y := bottom + piece.size.y * 0.5

	match wall:
		WallSide.NORTH:
			return Vector3(
				along_center,
				y,
				-room.room_depth * 0.5 + depth * 0.5
			)

		WallSide.SOUTH:
			return Vector3(
				along_center,
				y,
				room.room_depth * 0.5 - depth * 0.5
			)

		WallSide.EAST:
			return Vector3(
				room.room_width * 0.5 - depth * 0.5,
				y,
				along_center
			)

		WallSide.WEST:
			return Vector3(
				-room.room_width * 0.5 + depth * 0.5,
				y,
				along_center
			)

	return Vector3.ZERO


func _wall_rotation(wall: WallSide) -> Vector3:
	match wall:
		WallSide.NORTH:
			return Vector3(0, 0, 0)
		WallSide.SOUTH:
			return Vector3(0, PI, 0)
		WallSide.EAST:
			return Vector3(0, -PI * 0.5, 0)
		WallSide.WEST:
			return Vector3(0, PI * 0.5, 0)
	return Vector3.ZERO


# -------------------------------------------------------------------
# Kandidaten-Suche
# -------------------------------------------------------------------

func _build_along_candidates(start_value: float, min_value: float, max_value: float, item_len: float) -> Array[float]:
	var candidates: Array[float] = []
	var step = max(item_len * 0.5, 0.1)

	candidates.append(start_value)

	var i := 1
	while true:
		var added_any := false

		var left = start_value - step * i
		if left >= min_value:
			candidates.append(left)
			added_any = true

		var right = start_value + step * i
		if right <= max_value:
			candidates.append(right)
			added_any = true

		if not added_any:
			break

		i += 1

	return candidates


func _build_vertical_candidates(item_height: float) -> Array[float]:
	var candidates: Array[float] = []
	var step = max(item_height * 0.5, 0.1)

	var current := 0.0
	while current + item_height <= room.room_height:
		candidates.append(current)
		current += step

	return candidates


func _random_wall_order() -> Array[WallSide]:
	var walls: Array[WallSide] = [
		WallSide.NORTH,
		WallSide.EAST,
		WallSide.SOUTH,
		WallSide.WEST
	]
	walls.shuffle()
	return walls