extends Arranger
class_name Arranger_A

@export var room_path: NodePath
@export var max_attempts_per_piece: int = 20
@export var wall_margin: float = 0.02
@export var object_margin: float = 0.02

@onready var room: Room = get_node(room_path)


func do_layout_generation() -> void:
	if room == null:
		push_error("Arranger_A: room_path not set.")
		return

	var pieces: Array[Furniture] = placed_furniture[Furniture.PlacementType.FLOOR_WALL_ADJ]
	pieces.sort_custom(_sort_by_size_desc)

	for piece in pieces:
		_place_floor_wall_adj(piece)


func _sort_by_size_desc(a: Furniture, b: Furniture) -> bool:
	var vol_a := a.size.x * a.size.y * a.size.z
	var vol_b := b.size.x * b.size.y * b.size.z
	return vol_a > vol_b

func _place_floor_wall_adj(piece: Furniture) -> void:
	var placed := false

	for _i in range(max_attempts_per_piece):
		var wall := randi() % 4
		_place_piece_on_wall(piece, wall)

		if _intersects_any(piece):
			continue

		_snap_piece_sideways_to_nearest_wall(piece, wall)

		if _is_outside_room(piece):
			continue

		if _intersects_any(piece):
			continue

		placed = true
		break

	if not placed:
		# Delete Furniture
		piece.queue_free()
		remove_furniture_to_list(piece)

func _place_piece_on_wall(piece: Furniture, wall: int) -> void:
	var half_w := room.room_width * 0.5
	var half_d := room.room_depth * 0.5
	var half_size := piece.size * 0.5

	var pos := Vector3.ZERO

	# Floor Contact
	pos.y = half_size.y

	match wall:
		0: # NORTH (-Z)
			pos.z = -half_d + half_size.z + wall_margin
			pos.x = randf_range(-half_w + half_size.x, half_w - half_size.x)
			piece.rotation.y = 0.0

		1: # EAST (+X)
			pos.x = half_w - half_size.x - wall_margin
			pos.z = randf_range(-half_d + half_size.z, half_d - half_size.z)
			piece.rotation.y = deg_to_rad(90)

		2: # SOUTH (+Z)
			pos.z = half_d - half_size.z - wall_margin
			pos.x = randf_range(-half_w + half_size.x, half_w - half_size.x)
			piece.rotation.y = deg_to_rad(180)

		3: # WEST (-X)
			pos.x = -half_w + half_size.x + wall_margin
			pos.z = randf_range(-half_d + half_size.z, half_d - half_size.z)
			piece.rotation.y = deg_to_rad(270)

	piece.position = pos

func _intersects_any(piece: Furniture) -> bool:
	for type in placed_furniture.keys():
		for other in placed_furniture[type]:
			if other == null or other == piece:
				continue
			if _aabb_overlap(piece, other):
				return true
	return false

func _aabb_overlap(a: Furniture, b: Furniture) -> bool:
	var a_min := a.global_position - a.size * 0.5 - Vector3.ONE * object_margin
	var a_max := a.global_position + a.size * 0.5 + Vector3.ONE * object_margin

	var b_min := b.global_position - b.size * 0.5
	var b_max := b.global_position + b.size * 0.5

	return (
		a_min.x <= b_max.x and a_max.x >= b_min.x and
		a_min.y <= b_max.y and a_max.y >= b_min.y and
		a_min.z <= b_max.z and a_max.z >= b_min.z
	)

func _snap_piece_sideways_to_nearest_wall(piece: Furniture, wall: int) -> void:
	var half_w := room.room_width * 0.5
	var half_d := room.room_depth * 0.5
	var half_size := piece.size * 0.5

	match wall:
		0, 2:
			# Möbel steht an Nord/Süd-Wand -> links/rechts = West/Ost
			var dist_left  := (piece.position.x - half_size.x) - (-half_w)
			var dist_right := half_w - (piece.position.x + half_size.x)

			if dist_right > dist_left:
				# nach links
				piece.position.x = -half_w + half_size.x + wall_margin
			else:
				# nach rechts
				piece.position.x = half_w - half_size.x - wall_margin

		1, 3:
			# Möbel steht an Ost/West-Wand -> links/rechts = Nord/Süd entlang Z
			var dist_left  := (piece.position.z - half_size.z) - (-half_d)
			var dist_right := half_d - (piece.position.z + half_size.z)

			if dist_right > dist_left:
				# nach links / negativ Z
				piece.position.z = -half_d + half_size.z + wall_margin
			else:
				# nach rechts / positiv Z
				piece.position.z = half_d - half_size.z - wall_margin

func _is_outside_room(piece: Furniture) -> bool:
	var half_w := room.room_width * 0.5
	var half_d := room.room_depth * 0.5
	var half_h := room.room_height
	var half_size := piece.size * 0.5

	if piece.position.x - half_size.x < -half_w:
		return true
	if piece.position.x + half_size.x > half_w:
		return true
	if piece.position.z - half_size.z < -half_d:
		return true
	if piece.position.z + half_size.z > half_d:
		return true
	if piece.position.y - half_size.y < 0.0:
		return true
	if piece.position.y + half_size.y > half_h:
		return true

	return false