extends MeshInstance3D

const RAY_LENGTH: float = 100.0  # Length of the raycast for detecting side
const DEFAULT_ROTATION_STEP: int = 5  # Degrees per rotation frame
const SHUFFLE_ROTATION_STEP: int = 10  # Degrees per rotation frame during shuffle
const SHUFFLE_MIN_MOVES: int = 50  # Minimum number of shuffle moves
const SHUFFLE_MAX_MOVES: int = 100  # Maximum number of shuffle moves
const ROTATION_FRAME_TIME: float = 0.001  # Seconds per rotation frame

# Prefab for instantiating cube pieces
var cube_piece_prefab: PackedScene = preload("res://prefabs/cube_piece.tscn")

# Array storing all cube pieces
var all_cube_pieces: Array[MeshInstance3D] = []

# Rotation vectors for each cube face
var rotation_vectors: Dictionary = {
	"up": Vector3(0, 1, 0),
	"down": Vector3(0, -1, 0),
	"front": Vector3(1, 0, 0),
	"back": Vector3(-1, 0, 0),
	"left": Vector3(0, 0, -1),
	"right": Vector3(0, 0, 1)
}

# Flags to control cube interaction
var can_rotate: bool = true
var can_shuffle: bool = true

# Signal emitted when the cube is solved
signal cube_solved

func _ready():
	if not cube_piece_prefab:
		push_error("Cube piece prefab not found at res://prefabs/cube_piece.tscn")
		return
	
	# Initialize the cube
	create_cube()

# Handle input for cube shuffling and resetting
func _input(event: InputEvent):
	if can_rotate and can_shuffle:
		if event.is_action_pressed("cube_shuffle"):
			shuffle()
		elif event.is_action_pressed("cube_reset"):
			create_cube()

# Clear all cube pieces from the scene
func clear_cube() -> void:
	for piece in all_cube_pieces:
		piece.queue_free()
	
	all_cube_pieces.clear()

# Create a new 3x3x3 Rubik's cube
func create_cube() -> void:
	clear_cube()
	
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				var instance: MeshInstance3D = cube_piece_prefab.instantiate()
				add_child(instance)
				instance.transform.origin = Vector3(-x, -y, z)
				instance.call("set_color", -x, -y, z)
				all_cube_pieces.append(instance)

# Rotate a layer of the cube
# Parameters:
# - cube_pieces: Array of MeshInstance3D objects in the layer
# - rotation_vector: Axis of rotation (e.g., Vector3(0, 1, 0) for up)
# - direction: 1 for clockwise, -1 for counterclockwise
# - rotate_angle: Incremental angle per frame (in degrees)
func rotate_layer(cube_pieces: Array[MeshInstance3D], rotation_vector: Vector3, 
				  direction: int = 1, rotate_angle: int = DEFAULT_ROTATION_STEP) -> void:
	can_rotate = false
	var total_angle: int = 0
	var angle: float = deg_to_rad(rotate_angle) * direction
	var rotation_basis: Basis = Basis().rotated(rotation_vector, angle)
	
	while total_angle < 90:
		for piece in cube_pieces:
			var relative_position: Vector3 = piece.transform.origin
			relative_position = rotation_basis * relative_position
			piece.transform.origin = relative_position
			piece.transform.basis = piece.transform.basis.rotated(rotation_vector, angle)
		
		total_angle += rotate_angle
		await get_tree().create_timer(ROTATION_FRAME_TIME).timeout
	
	check_cube_solved()
	can_rotate = true

# Shuffle the cube with random rotations
func shuffle() -> void:
	can_shuffle = false
	var move_count: int = randi_range(SHUFFLE_MIN_MOVES, SHUFFLE_MAX_MOVES)
	var faces: Array = rotation_vectors.keys()
	
	for i in range(move_count):
		var face: String = faces[randi() % faces.size()]  # Randomly select a face
		var edge_pieces: Array[MeshInstance3D] = _get_pieces_for_face(face)
		await rotate_layer(edge_pieces, rotation_vectors[face], 1, SHUFFLE_ROTATION_STEP)
	
	can_shuffle = true

# Check if the cube is solved
func check_cube_solved() -> void:
	if (is_side_complete(get_up_pieces()) and is_side_complete(get_down_pieces()) and
		is_side_complete(get_front_pieces()) and is_side_complete(get_back_pieces()) and
		is_side_complete(get_left_pieces()) and is_side_complete(get_right_pieces())):
		print("Cube solved!")
		cube_solved.emit()

# Check if a single side of the cube is complete (all planes have the same material)
func is_side_complete(cube_pieces: Array[MeshInstance3D]) -> bool:
	if cube_pieces.size() != 9:
		push_warning("Expected 9 cube pieces for side, got ", cube_pieces.size())
		return false
	
	var central_planes: Array[MeshInstance3D] = cube_pieces[4].get("planes")
	var main_plane_index: int = -1
	
	# Find the index of the first visible plane on the central cube piece
	for i in range(central_planes.size()):
		if central_planes[i].is_visible():
			main_plane_index = i
			break
	
	if main_plane_index == -1:
		return false
	
	var main_plane_material: Material = central_planes[main_plane_index].get_active_material(0)
	
	# Check if all pieces on the side have the same material for the corresponding plane
	for piece in cube_pieces:
		var piece_planes: Array[MeshInstance3D] = piece.get("planes")
		var target_plane: MeshInstance3D = piece_planes[main_plane_index]
		
		if not target_plane.is_visible() or target_plane.get_active_material(0) != main_plane_material:
			return false
	
	return true

# Detect and rotate a layer based on selected pieces and planes
func detect_rotate(cube_pieces: Array[MeshInstance3D], planes: Array[MeshInstance3D]) -> void:
	if cube_pieces.size() < 2:
		push_warning("Insufficient pieces provided to detect_rotate")
		return
	
	if not can_shuffle or not can_rotate:
		return
	
	# Determine which layer to rotate based on selected pieces and planes
	if cube_pieces[0] in get_up_vertical_pieces() and cube_pieces[1] in get_up_vertical_pieces():
		rotate_layer(get_up_vertical_pieces(), rotation_vectors["right"], detect_left_middle_right_direction(cube_pieces))
	elif cube_pieces[0] in get_up_horizontal_pieces() and cube_pieces[1] in get_up_horizontal_pieces():
		rotate_layer(get_up_horizontal_pieces(), rotation_vectors["front"], detect_front_middle_back_direction(cube_pieces))
	elif cube_pieces[0] in get_front_horizontal_pieces() and cube_pieces[1] in get_front_horizontal_pieces():
		rotate_layer(get_front_horizontal_pieces(), rotation_vectors["up"], detect_up_middle_down_direction(cube_pieces))
	elif detect_side(planes, get_up_pieces()):
		rotate_layer(get_up_pieces(), rotation_vectors["up"], detect_up_middle_down_direction(cube_pieces))
	elif detect_side(planes, get_down_pieces()):
		rotate_layer(get_down_pieces(), rotation_vectors["up"], detect_up_middle_down_direction(cube_pieces))
	elif detect_side(planes, get_front_pieces()):
		rotate_layer(get_front_pieces(), rotation_vectors["front"], detect_front_middle_back_direction(cube_pieces))
	elif detect_side(planes, get_back_pieces()):
		rotate_layer(get_back_pieces(), rotation_vectors["front"], detect_front_middle_back_direction(cube_pieces))
	elif detect_side(planes, get_left_pieces()):
		rotate_layer(get_left_pieces(), rotation_vectors["right"], detect_left_middle_right_direction(cube_pieces))
	elif detect_side(planes, get_right_pieces()):
		rotate_layer(get_right_pieces(), rotation_vectors["right"], detect_left_middle_right_direction(cube_pieces))

# Detect if the selected planes belong to a specific side
func detect_side(planes: Array[MeshInstance3D], side: Array[MeshInstance3D]) -> bool:
	if planes.size() < 2:
		push_warning("Insufficient planes provided to detect_side")
		return false
	
	var center_piece = find_center_piece(side)
	if not center_piece:
		return false
	
	# Use the plane with multiple active planes or the second plane
	var plane = planes[0] if planes[0].get_parent().get_active_planes().size() == 2 else planes[1]
	
	var local_normal = plane.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL][0]
	var global_normal = plane.global_transform.basis * local_normal
	
	var space_state = get_world_3d().direct_space_state
	var current_origin = plane.global_transform.origin
	var direction = -global_normal.normalized()
	
	var query = PhysicsRayQueryParameters3D.create(current_origin, current_origin + direction * RAY_LENGTH)
	var hit = space_state.intersect_ray(query)
	
	if not hit:
		push_warning("Raycast failed in detect_side")
		return false
	
	var hit_object = hit["collider"].get_parent().get_parent()
	if hit_object == center_piece:
		return true
	
	return false

# Find the central piece of a side (with only one active plane)
func find_center_piece(side: Array[MeshInstance3D]) -> MeshInstance3D:
	for piece in side:
		var active_planes = piece.get_active_planes()
		if active_planes.size() == 1:
			return piece
	return null

# Get pieces for a specific cube face
func _get_pieces_for_face(face: String) -> Array[MeshInstance3D]:
	match face:
		"up":
			return get_up_pieces()
		"down":
			return get_down_pieces()
		"front":
			return get_front_pieces()
		"back":
			return get_back_pieces()
		"left":
			return get_left_pieces()
		"right":
			return get_right_pieces()
	return []  # Fallback for invalid face

func get_up_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(piece): return round(piece.transform.origin.y) == 1)

func get_down_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(piece): return round(piece.transform.origin.y) == -1)

func get_left_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(piece): return round(piece.transform.origin.z) == -1)

func get_right_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(piece): return round(piece.transform.origin.z) == 1)

func get_front_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(piece): return round(piece.transform.origin.x) == 1)

func get_back_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(piece): return round(piece.transform.origin.x) == -1)

func get_up_horizontal_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(piece): return round(piece.transform.origin.x) == 0)

func get_up_vertical_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(piece): return round(piece.transform.origin.z) == 0)

func get_front_horizontal_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(piece): return round(piece.transform.origin.y) == 0)

# Determine rotation direction for left/middle/right layers
func detect_left_middle_right_direction(cube_pieces: Array[MeshInstance3D]) -> int:
	var pos0 = cube_pieces[0].transform.origin.round()
	var pos1 = cube_pieces[1].transform.origin.round()
	
	if pos1.y != pos0.y:
		return pos0.y - pos1.y if pos0.x == -1 else pos1.y - pos0.y
	else:
		return pos1.x - pos0.x if pos0.y == -1 else pos0.x - pos1.x

# Determine rotation direction for front/middle/back layers
func detect_front_middle_back_direction(cube_pieces: Array[MeshInstance3D]) -> int:
	var pos0 = cube_pieces[0].transform.origin.round()
	var pos1 = cube_pieces[1].transform.origin.round()
	
	if pos1.z != pos0.z:
		return pos1.z - pos0.z if pos0.y == 1 else pos0.z - pos1.z
	else:
		return pos1.y - pos0.y if pos0.z == -1 else pos0.y - pos1.y

# Determine rotation direction for up/middle/down layers
func detect_up_middle_down_direction(cube_pieces: Array[MeshInstance3D]) -> int:
	var pos0 = cube_pieces[0].transform.origin.round()
	var pos1 = cube_pieces[1].transform.origin.round()
	
	if pos1.z != pos0.z:
		return pos1.z - pos0.z if pos0.x == -1 else pos0.z - pos1.z
	else:
		return pos0.x - pos1.x if pos0.z == -1 else pos1.x - pos0.x
