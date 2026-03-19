extends Arranger
class_name ArrangerV2

enum GeneratorState {
	NOT_STARTED,
	INITIALIZE,
	PLACE,
	SHIFT,
	COMPLETED
}

@export_node_path("Room") var room_path: NodePath

@export var step_duration:   float = 0.3
@export var shift_step_duration:   float = 0.05
@export var shift_increment: float = 0.1

@onready var room: Room = get_node(room_path)

@onready var wall_lookup: Dictionary[MeshInstance3D, Array] = {
	room.mesh_wall_n: [],
	room.mesh_wall_e: [],
	room.mesh_wall_s: [],
	room.mesh_wall_w: []
}

var state = GeneratorState.NOT_STARTED
var timer: float = 0.0
var current_piece: Furniture = null
var current_type: Furniture.PlacementType = Furniture.PlacementType.FLOOR_WALL_ADJ
var current_indx: int = 0
var shift_direction: int = 1
var shift_attempts: int = 0
var max_shift_attempts: int = 0
var walls_failed: Array[MeshInstance3D] = []
var skipped_pieces: Array[Furniture] = []

func _physics_process(delta: float) -> void:
	# wait a bit to show steps better visually
	timer -= delta
	if timer > 0.0:
		return

	timer = step_duration

	# process the next step
	match state:
		GeneratorState.NOT_STARTED or GeneratorState.COMPLETED:
			return # do nothing
		GeneratorState.INITIALIZE:
			_step_initialize()
		GeneratorState.PLACE:
			_step_place_floor_wall_adj()
		GeneratorState.SHIFT:
			_step_shift_floor_wall_adj()

func do_layout_generation():
	timer = 0.0
	state = GeneratorState.INITIALIZE

func _step_initialize():
	# move all pieces out of the room first
	for type in placed_furniture.keys():
		for piece in placed_furniture[type]:
			piece.position = Vector3(-100, -100, -100) # move far away
	current_indx = 0
	current_piece = null
	current_type = Furniture.PlacementType.FLOOR_WALL_ADJ
	skipped_pieces.clear()
	walls_failed.clear()
	state = GeneratorState.PLACE
	
func _step_place_floor_wall_adj():
	var pieces = placed_furniture[current_type]
	if current_indx >= pieces.size(): # if all pieces from this type are done, move to next
		match current_type:
			Furniture.PlacementType.FLOOR_WALL_ADJ:
				current_type = Furniture.PlacementType.WALL
				current_indx = 0
			Furniture.PlacementType.WALL:
				state = GeneratorState.COMPLETED
				print("Layout generation completed! Skipped pieces: ", skipped_pieces.size())
		return

	current_piece = pieces[current_indx]

	# check if is locked
	if current_piece.locked:
		print("Piece ", current_piece.name, " is locked, skipping...")
		current_indx += 1
		return

	# check if furniture is already placed
	var wall := _find_wall_for_piece(current_piece)
	if wall:
		wall_lookup[wall].erase(current_piece) # remove piece from lookup for that wall
	
	# pick a random wall
	wall = _pick_random_wall()
	if wall == null:
		print("No walls left to try for piece ", current_piece.name, ", skipping...")
		skipped_pieces.append(current_piece)
		current_piece.position = Vector3((room.room_width / 2.0) + (skipped_pieces.size() * 2.0), 0, 0) # move out of room
		current_piece.rotation.y = 0
		current_indx += 1
		walls_failed.clear()
		return
	wall_lookup[wall].append(current_piece) # add piece to lookup for that wall

	# calculate random offset
	var offset           := Vector3.ZERO
	var half_wall_width  := wall.scale.x / 2.0
	var half_piece_width := current_piece.size.x / 2.0
	offset.x              = randf_range(-half_wall_width + half_piece_width, half_wall_width - half_piece_width) # random offset along the wall

	# if piece is wall, also calc a Y offset
	if current_piece.placement_type == Furniture.PlacementType.WALL:
		var half_piece_height := current_piece.size.y / 2.0
		offset.y               = randf_range(0, half_piece_height)
		
	offset.z = (-current_piece.size.z / 2.0) - 0.01 # move away from wall (with slight gap to prevent collision)
	offset.y += 0.01 # slight lift to prevent collision with floor

	# place piece relative to walls rotation
	var wall_xz       := wall.position * Vector3(1, 0, 1) # get wall position on xz plane
	var position      := _get_position_relative_to(offset, wall_xz, wall.rotation.y)
	current_piece.position   = position
	current_piece.rotation.y = wall.rotation.y # copy wall rotation
	print("Placing piece ", current_indx, " (", current_piece.name, ") at wall ", wall.name, " with offset ", offset)

	# Wait for physics engine to update collision data
	await get_tree().physics_frame

	# if collides with a wall, try again
	if not current_piece.is_inside_room():
		print("Piece ", current_piece.name, " doesn't fit into room, trying again...")
		return

	# if colliding with another piece, start shift
	if current_piece.get_colliding().size() > 0:
		print("Piece ", current_piece.name, " collides with another piece!")
		for area in current_piece.get_colliding():
			print("Colliding with ", area.get_parent().name)
		# calculate shift attempts based on wall size and shift inc.
		max_shift_attempts = int((wall.scale.x - current_piece.size.x) / shift_increment) * 2
		state = GeneratorState.SHIFT
		return

	# if all ok, next piece
	current_indx += 1

func _step_shift_floor_wall_adj():
	var colliding_areas := current_piece.get_colliding()
	
	var colliding_area := colliding_areas[0] # only check one for now
	var _other_piece := colliding_area.get_parent() as Furniture # cast as furniture

	# get wall for pieces
	var wall := _find_wall_for_piece(current_piece)
	
	# First attempt at shifting - initialize shift_attempts on first call
	if shift_attempts == 0:
		shift_direction = 1
		shift_attempts = 1
	
	# Calculate shift offset - wall pieces shift vertically, floor pieces shift along the wall
	var shift_offset: Vector3
	if current_piece.placement_type == Furniture.PlacementType.WALL:
		shift_offset = Vector3.UP * shift_increment * shift_direction
	else:
		var along_wall := Vector3.RIGHT.rotated(Vector3.UP, wall.rotation.y) # along the wall direction
		shift_offset = along_wall * shift_increment * shift_direction
	
	# Apply shift to current piece
	current_piece.position += shift_offset
	
	# Wait for physics engine to update
	await get_tree().physics_frame
	
	# Check if piece is still inside room
	if not current_piece.is_inside_room():
		# Revert shift and try opposite direction
		current_piece.position -= shift_offset
		shift_direction *= -1  # reverse direction
		shift_attempts += 1
	
	# Check if collision resolved
	if current_piece.get_colliding().size() == 0:
		print("Piece ", current_piece.name, " shifted successfully!")
		state = GeneratorState.PLACE
		current_indx += 1
		shift_attempts = 0
		walls_failed.clear()
		return
	
	# Collision still exists, continue shifting
	shift_attempts += 1
	timer = shift_step_duration
	if shift_attempts > max_shift_attempts:
		walls_failed.append(wall)
		print("Shifting failed after ", max_shift_attempts, " attempts, walls left to try: ", 4 - walls_failed.size())
		state = GeneratorState.PLACE
		shift_attempts = 0

func _pick_random_wall() -> MeshInstance3D:
	var walls = [
		room.mesh_wall_n,
		room.mesh_wall_e,
		room.mesh_wall_s,
		room.mesh_wall_w
	]
	for wall in walls_failed:
		walls.erase(wall) # remove failed walls from options
	if walls.size() < 1:
		return null
	walls.shuffle()
	return walls[0]

func _find_wall_for_piece(piece: Furniture) -> MeshInstance3D:
	for wall in wall_lookup.keys():
		if piece in wall_lookup[wall]:
			return wall
	return null

func _get_position_relative_to(offset: Vector3, src_position: Vector3, rotation_y: float) -> Vector3:
	var perpendicular := Vector3.FORWARD.rotated(Vector3.UP, rotation_y) # perpendicular to wall
	var along_wall    := Vector3.RIGHT.rotated(Vector3.UP, rotation_y) # along the wall direction
	var position      := src_position + (along_wall * offset.x) + (perpendicular * offset.z) + (Vector3.UP * offset.y)
	return position
