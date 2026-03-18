extends Arranger
class_name Arranger_B

@export var room_path: NodePath

@export var wall_margin: float = 0.05
@export var object_margin: float = 0.05
@export var samples_per_wall: int = 5
@export var samples_floor_x: int = 4
@export var samples_floor_z: int = 4
@export var max_candidates_per_piece: int = 20
@export var delete_unplaceable_furniture: bool = false

@onready var room: Room = get_node_or_null(room_path)

var _best_score: float = -INF
var _best_layout: Dictionary = {}
var _pieces: Array[Furniture] = []


class PlacementCandidate:
	var piece: Furniture
	var position: Vector3
	var rotation_y: float
	var wall: int

	func _init(_piece: Furniture, _position: Vector3, _rotation_y: float, _wall: int) -> void:
		piece = _piece
		position = _position
		rotation_y = _rotation_y
		wall = _wall


func do_layout_generation() -> void:
	if room == null:
		push_error("Arranger_B: room_path ist nicht gesetzt oder ungültig.")
		return

	_best_score = -INF
	_best_layout.clear()
	_pieces.clear()

	for type in placed_furniture.keys():
		var list = placed_furniture[type]
		for piece in list:
			if piece != null and is_instance_valid(piece):
				_pieces.append(piece)

	if _pieces.is_empty():
		return

	_pieces.sort_custom(_sort_by_volume_desc)

	var candidate_map: Dictionary = {}

	for piece in _pieces:
		var candidates := _generate_candidates(piece)

		if candidates.is_empty():
			if delete_unplaceable_furniture:
				piece.queue_free()
				remove_furniture_to_list(piece)
				continue
			else:
				push_warning("Arranger_B: Kein Kandidat für Möbel '%s' gefunden." % piece.name)
				return

		candidate_map[piece] = candidates

	if candidate_map.is_empty():
		return

	_search_layout(0, candidate_map, {}, 0.0)

	if _best_layout.is_empty():
		push_warning("Arranger_B: Keine gültige Kombination gefunden.")
		return

	_apply_layout(_best_layout)


func _sort_by_volume_desc(a: Furniture, b: Furniture) -> bool:
	var va := a.size.x * a.size.y * a.size.z
	var vb := b.size.x * b.size.y * b.size.z
	return va > vb


func _generate_candidates(piece: Furniture) -> Array:
	match piece.placement_type:
		Furniture.PlacementType.FLOOR_WALL_ADJ:
			return _limit_candidates(_generate_floor_wall_adj_candidates(piece))
		Furniture.PlacementType.FLOOR:
			return _limit_candidates(_generate_floor_candidates(piece))
		Furniture.PlacementType.WALL:
			return _limit_candidates(_generate_wall_candidates(piece))
		_:
			return []


func _limit_candidates(candidates: Array) -> Array:
	if candidates.size() <= max_candidates_per_piece:
		return candidates

	candidates.shuffle()
	return candidates.slice(0, max_candidates_per_piece)


func _generate_floor_wall_adj_candidates(piece: Furniture) -> Array:
	var result: Array = []

	var half_room_w := room.room_width * 0.5
	var half_room_d := room.room_depth * 0.5

	# Rotation 0/180 -> normale Größe
	var size_a := _rotated_size(piece.size, 0.0)
	# Rotation 90/270 -> X/Z getauscht
	var size_b := _rotated_size(piece.size, deg_to_rad(90))

	var xs_a = _sample_range(-half_room_w + size_a.x * 0.5, half_room_w - size_a.x * 0.5, samples_per_wall)
	var zs_b = _sample_range(-half_room_d + size_b.z * 0.5, half_room_d - size_b.z * 0.5, samples_per_wall)
	var xs_a_south = xs_a
	var zs_b_west = zs_b

	# Nordwand (-Z), Rotation 0
	for x in xs_a:
		var pos := Vector3(
			x,
			size_a.y * 0.5,
			-half_room_d + size_a.z * 0.5 + wall_margin
		)
		result.append(PlacementCandidate.new(piece, pos, 0.0, 0))

	# Ostwand (+X), Rotation 90
	for z in zs_b:
		var pos := Vector3(
			half_room_w - size_b.x * 0.5 - wall_margin,
			size_b.y * 0.5,
			z
		)
		result.append(PlacementCandidate.new(piece, pos, deg_to_rad(90), 1))

	# Südwand (+Z), Rotation 180
	for x in xs_a_south:
		var pos := Vector3(
			x,
			size_a.y * 0.5,
			half_room_d - size_a.z * 0.5 - wall_margin
		)
		result.append(PlacementCandidate.new(piece, pos, deg_to_rad(180), 2))

	# Westwand (-X), Rotation 270
	for z in zs_b_west:
		var pos := Vector3(
			-half_room_w + size_b.x * 0.5 + wall_margin,
			size_b.y * 0.5,
			z
		)
		result.append(PlacementCandidate.new(piece, pos, deg_to_rad(270), 3))

	return _filter_valid_candidates(result)


func _generate_floor_candidates(piece: Furniture) -> Array:
	var result: Array = []

	var half_room_w := room.room_width * 0.5
	var half_room_d := room.room_depth * 0.5

	var size_0 := _rotated_size(piece.size, 0.0)
	var size_90 := _rotated_size(piece.size, deg_to_rad(90))

	var xs_0 = _sample_range(-half_room_w + size_0.x * 0.5, half_room_w - size_0.x * 0.5, samples_floor_x)
	var zs_0 = _sample_range(-half_room_d + size_0.z * 0.5, half_room_d - size_0.z * 0.5, samples_floor_z)

	for x in xs_0:
		for z in zs_0:
			result.append(
				PlacementCandidate.new(
					piece,
					Vector3(x, size_0.y * 0.5, z),
					0.0,
					-1
				)
			)

	var xs_90 = _sample_range(-half_room_w + size_90.x * 0.5, half_room_w - size_90.x * 0.5, samples_floor_x)
	var zs_90 = _sample_range(-half_room_d + size_90.z * 0.5, half_room_d - size_90.z * 0.5, samples_floor_z)

	for x in xs_90:
		for z in zs_90:
			result.append(
				PlacementCandidate.new(
					piece,
					Vector3(x, size_90.y * 0.5, z),
					deg_to_rad(90),
					-1
				)
			)

	return _filter_valid_candidates(result)


func _generate_wall_candidates(piece: Furniture) -> Array:
	var result: Array = []

	var half_room_w := room.room_width * 0.5
	var half_room_d := room.room_depth * 0.5

	var size_0 := _rotated_size(piece.size, 0.0)
	var size_90 := _rotated_size(piece.size, deg_to_rad(90))

	var y_pos_0 := clamp(size_0.y * 0.5 + 1.2, size_0.y * 0.5, room.room_height - size_0.y * 0.5)
	var y_pos_90 := clamp(size_90.y * 0.5 + 1.2, size_90.y * 0.5, room.room_height - size_90.y * 0.5)

	var xs_0 = _sample_range(-half_room_w + size_0.x * 0.5, half_room_w - size_0.x * 0.5, samples_per_wall)
	var zs_90 = _sample_range(-half_room_d + size_90.z * 0.5, half_room_d - size_90.z * 0.5, samples_per_wall)

	# Nordwand
	for x in xs_0:
		var pos := Vector3(
			x,
			y_pos_0,
			-half_room_d + size_0.z * 0.5 + wall_margin
		)
		result.append(PlacementCandidate.new(piece, pos, 0.0, 0))

	# Ostwand
	for z in zs_90:
		var pos := Vector3(
			half_room_w - size_90.x * 0.5 - wall_margin,
			y_pos_90,
			z
		)
		result.append(PlacementCandidate.new(piece, pos, deg_to_rad(90), 1))

	# Südwand
	for x in xs_0:
		var pos := Vector3(
			x,
			y_pos_0,
			half_room_d - size_0.z * 0.5 - wall_margin
		)
		result.append(PlacementCandidate.new(piece, pos, deg_to_rad(180), 2))

	# Westwand
	for z in zs_90:
		var pos := Vector3(
			-half_room_w + size_90.x * 0.5 + wall_margin,
			y_pos_90,
			z
		)
		result.append(PlacementCandidate.new(piece, pos, deg_to_rad(270), 3))

	return _filter_valid_candidates(result)


func _filter_valid_candidates(candidates: Array) -> Array:
	var filtered: Array = []

	for c in candidates:
		if not _candidate_outside_room(c):
			filtered.append(c)

	return filtered


func _search_layout(index: int, candidate_map: Dictionary, current_layout: Dictionary, current_score: float) -> void:
	if index >= _pieces.size():
		if current_score > _best_score:
			_best_score = current_score
			_best_layout = current_layout.duplicate()
		return

	var optimistic_bound := current_score + _estimate_max_remaining_score(index, candidate_map)
	if optimistic_bound <= _best_score:
		return

	var piece: Furniture = _pieces[index]

	if not candidate_map.has(piece):
		_search_layout(index + 1, candidate_map, current_layout, current_score)
		return

	var candidates: Array = candidate_map[piece]

	for candidate in candidates:
		if _conflicts_with_layout(candidate, current_layout):
			continue

		current_layout[piece] = candidate

		var added_score := _score_candidate(candidate, current_layout)
		_search_layout(index + 1, candidate_map, current_layout, current_score + added_score)

		current_layout.erase(piece)


func _estimate_max_remaining_score(start_index: int, candidate_map: Dictionary) -> float:
	var bound := 0.0

	for i in range(start_index, _pieces.size()):
		var piece: Furniture = _pieces[i]
		if not candidate_map.has(piece):
			continue

		var candidates: Array = candidate_map[piece]
		var best_piece_score := -INF

		for c in candidates:
			var s := _score_candidate(c, {})
			if s > best_piece_score:
				best_piece_score = s

		if best_piece_score != -INF:
			bound += best_piece_score

	return bound


func _conflicts_with_layout(candidate: PlacementCandidate, layout: Dictionary) -> bool:
	if _candidate_outside_room(candidate):
		return true

	for other_piece in layout.keys():
		var other_candidate: PlacementCandidate = layout[other_piece]
		if _candidate_overlap(candidate, other_candidate):
			return true

	return false


func _score_candidate(candidate: PlacementCandidate, layout: Dictionary) -> float:
	var score := 0.0
	var piece := candidate.piece

	match piece.placement_type:
		Furniture.PlacementType.FLOOR_WALL_ADJ:
			score += 12.0
		Furniture.PlacementType.WALL:
			score += 9.0
		Furniture.PlacementType.FLOOR:
			score += 5.0

	score += _wall_alignment_score(candidate)
	score -= _center_penalty(candidate)
	score += _spread_bonus(candidate, layout)

	return score


func _wall_alignment_score(candidate: PlacementCandidate) -> float:
	var pos := candidate.position
	var half_room_w := room.room_width * 0.5
	var half_room_d := room.room_depth * 0.5

	var dx := min(abs(pos.x + half_room_w), abs(half_room_w - pos.x))
	var dz := min(abs(pos.z + half_room_d), abs(half_room_d - pos.z))
	var nearest_wall_dist := min(dx, dz)

	return 2.0 / (0.1 + nearest_wall_dist)


func _center_penalty(candidate: PlacementCandidate) -> float:
	var pos := candidate.position
	var dist_center := Vector2(pos.x, pos.z).length()
	return max(0.0, 1.5 - dist_center)


func _spread_bonus(candidate: PlacementCandidate, layout: Dictionary) -> float:
	var bonus := 0.0
	var pos2 := Vector2(candidate.position.x, candidate.position.z)

	for other_piece in layout.keys():
		var other_candidate: PlacementCandidate = layout[other_piece]
		if other_candidate == candidate:
			continue

		var other2 := Vector2(other_candidate.position.x, other_candidate.position.z)
		var d := pos2.distance_to(other2)

		if d > 0.01:
			bonus += min(d * 0.05, 1.0)

	return bonus


func _apply_layout(layout: Dictionary) -> void:
	for piece in layout.keys():
		var c: PlacementCandidate = layout[piece]
		if piece == null or not is_instance_valid(piece):
			continue

		piece.position = c.position
		piece.rotation.y = c.rotation_y


func _candidate_outside_room(candidate: PlacementCandidate) -> bool:
	var size := _rotated_size(candidate.piece.size, candidate.rotation_y)
	var half := size * 0.5

	var half_room_w := room.room_width * 0.5
	var half_room_d := room.room_depth * 0.5
	var room_h := room.room_height
	var pos := candidate.position

	if pos.x - half.x < -half_room_w:
		return true
	if pos.x + half.x > half_room_w:
		return true
	if pos.z - half.z < -half_room_d:
		return true
	if pos.z + half.z > half_room_d:
		return true
	if pos.y - half.y < 0.0:
		return true
	if pos.y + half.y > room_h:
		return true

	return false


func _candidate_overlap(a: PlacementCandidate, b: PlacementCandidate) -> bool:
	var size_a := _rotated_size(a.piece.size, a.rotation_y)
	var size_b := _rotated_size(b.piece.size, b.rotation_y)

	var half_a := size_a * 0.5
	var half_b := size_b * 0.5

	var a_min := a.position - half_a - Vector3.ONE * object_margin
	var a_max := a.position + half_a + Vector3.ONE * object_margin

	var b_min := b.position - half_b
	var b_max := b.position + half_b

	return (
		a_min.x <= b_max.x and a_max.x >= b_min.x and
		a_min.y <= b_max.y and a_max.y >= b_min.y and
		a_min.z <= b_max.z and a_max.z >= b_min.z
	)


func _rotated_size(original_size: Vector3, rotation_y: float) -> Vector3:
	var deg := int(round(rad_to_deg(rotation_y))) % 360
	if deg < 0:
		deg += 360

	match deg:
		90, 270:
			return Vector3(original_size.z, original_size.y, original_size.x)
		_:
			return original_size


func _sample_range(min_value: float, max_value: float, count: int) -> Array:
	var values: Array = []

	if min_value > max_value:
		return values

	if count <= 1:
		values.append((min_value + max_value) * 0.5)
		return values

	for i in range(count):
		var t := float(i) / float(count - 1)
		values.append(lerp(min_value, max_value, t))

	return values