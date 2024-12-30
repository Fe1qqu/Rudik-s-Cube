extends MeshInstance3D

var cube_piece_pref: PackedScene = load("res://prefabs/cube_piece.tscn")
var all_cube_pieces: Array[MeshInstance3D] = []
var rotation_vectors: Array[Vector3] = [Vector3(0, 1, 0), Vector3(0, -1, 0),
										Vector3(1, 0, 0), Vector3(-1, 0, 0),
										Vector3(0, 0, -1), Vector3(0, 0, 1)]
var can_rotate: bool = true
var can_shuffle: bool = true

func _ready():
	create_cube()


func _input(event):
	if can_rotate and can_shuffle:
		if event.is_action_pressed("cube_shuffle"):
			shuffle()
		elif event.is_action_pressed("cube_reset"):
			create_cube()

# Функция очистки кубика
func clear_cube() -> void:
	for cube in all_cube_pieces:
		cube.queue_free()
	
	all_cube_pieces.clear()

# Функция создания куба
func create_cube() -> void:
	clear_cube()
	
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				var instance = cube_piece_pref.instantiate()
				add_child(instance)
				instance.transform.origin = Vector3(-x, -y, z)
				instance.call("set_color", -x, -y, z)
				all_cube_pieces.append(instance)

# direction - направление вращения (1 для по часовой, -1 для против часовой)
func rotate_layer(pieces: Array[MeshInstance3D], rotation_vector: Vector3, 
				  direction: int = 1, rotate_angle: int = 5) -> void:
	can_rotate = false
	
	var total_angle: int = 0
	var angle: float = deg_to_rad(rotate_angle) * direction
	
	# Создаем Basis (матрица вращения)
	var rotation_basis: Basis = Basis().rotated(rotation_vector, angle)
	
	while total_angle < 90:
		for piece in pieces:
			# Получаем текущее положение кубика
			var relative_position: Vector3 = piece.transform.origin
			
			# Применяем матрицу вращения
			relative_position = rotation_basis * relative_position
			
			# Устанавливаем новое положение кубика
			piece.transform.origin = relative_position
			
			# Выполняем локальное вращение кубика вокруг его собственной оси
			piece.transform.basis = piece.transform.basis.rotated(rotation_vector, angle)
		
		total_angle += rotate_angle
		await get_tree().create_timer(0.001).timeout
	
	check_cube_solved()
	can_rotate = true


func shuffle() -> void:
	can_shuffle = false
	
	var move_count: int = randi() % 51 + 50
	
	for i in range(move_count):
		var edge_index: int = randi() % 6
		var edge_pieces: Array[MeshInstance3D]
		
		match edge_index:
			0: edge_pieces = get_up_pieces()
			1: edge_pieces = get_down_pieces()
			2: edge_pieces = get_front_pieces()
			3: edge_pieces = get_back_pieces()
			4: edge_pieces = get_left_pieces()
			5: edge_pieces = get_right_pieces()
		
		await rotate_layer(edge_pieces, rotation_vectors[edge_index], 1, 10)
	
	can_shuffle = true


func check_cube_solved() -> void:
	if (is_side_complete(get_up_pieces()) and is_side_complete(get_down_pieces()) and
		is_side_complete(get_front_pieces()) and is_side_complete(get_back_pieces()) and
		is_side_complete(get_left_pieces()) and is_side_complete(get_right_pieces())):
		print("Complete")


func is_side_complete(pieces: Array[MeshInstance3D]) -> bool:
	var central_planes: Array[MeshInstance3D] = pieces[4].get("planes")
	
	# Находим индекс первой активной панели у центрального куска
	var main_plane_index: int = -1
	for i in range(central_planes.size()):
		if central_planes[i].is_visible():
			main_plane_index = i
			break
	
	# Если не найдено ни одной активной панели, возвращаем false
	if main_plane_index == -1:
		return false
	
	var main_plane_material: Material = central_planes[main_plane_index].get_active_material(0)
	
	# Проверяем каждую панель в остальных кусках кубика
	for piece in pieces:
		var piece_planes: Array[MeshInstance3D] = piece.get("planes")
		var target_plane: MeshInstance3D = piece_planes[main_plane_index]
		
		# Проверяем, активна ли панель и совпадает ли цвет
		if not target_plane.is_visible() or target_plane.get_active_material(0) != main_plane_material:
			return false
	
	return true


func detect_rotate(pieces: Array[MeshInstance3D], planes: Array[MeshInstance3D]) -> void:
	if !can_shuffle or !can_rotate:
		return
	
	if pieces[0] in get_up_vertical_pieces() and pieces[1] in get_up_vertical_pieces():
		rotate_layer(get_up_vertical_pieces(), rotation_vectors[5], detect_left_middle_right_direction(pieces))
	elif pieces[0] in get_up_horizontal_pieces() and pieces[1] in get_up_horizontal_pieces():
		rotate_layer(get_up_horizontal_pieces(), rotation_vectors[2], detect_front_middle_back_direction(pieces))
	elif pieces[0] in get_front_horizontal_pieces() and pieces[1] in get_front_horizontal_pieces():
		rotate_layer(get_front_horizontal_pieces(), rotation_vectors[0], detect_up_middle_down_direction(pieces))
	elif detect_side(planes, get_up_pieces()):
		rotate_layer(get_up_pieces(), rotation_vectors[0], detect_up_middle_down_direction(pieces))
	elif detect_side(planes, get_down_pieces()):
		rotate_layer(get_down_pieces(), rotation_vectors[0], detect_up_middle_down_direction(pieces))
	elif detect_side(planes, get_front_pieces()):
		rotate_layer(get_front_pieces(), rotation_vectors[2], detect_front_middle_back_direction(pieces))
	elif detect_side(planes, get_back_pieces()):
		rotate_layer(get_back_pieces(), rotation_vectors[2], detect_front_middle_back_direction(pieces))
	elif detect_side(planes, get_left_pieces()):
		rotate_layer(get_left_pieces(), rotation_vectors[5], detect_left_middle_right_direction(pieces))
	elif detect_side(planes, get_right_pieces()):
		rotate_layer(get_right_pieces(), rotation_vectors[5], detect_left_middle_right_direction(pieces))


func detect_side(planes: Array[MeshInstance3D], side: Array[MeshInstance3D]) -> bool:
	var center_piece = find_center_piece(side)
	
	var plane
	if planes[0].get_parent().get_active_planes().size() == 2:
		plane = planes[0]
	else:
		plane = planes[1]
	
	var local_normal = plane.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL][0]
	var global_normal = plane.global_transform.basis * local_normal
	
	var space_state = get_world_3d().direct_space_state
	var current_origin = plane.global_transform.origin
	var direction = -global_normal.normalized()
	
	var query = PhysicsRayQueryParameters3D.new()
	query.from = current_origin
	query.to = current_origin + direction * 100
	query.collide_with_areas = true
	
	# Получаем пересечение
	var hit = space_state.intersect_ray(query)
	
	if hit:
		# Получаем объект столкновения
		var hit_object = hit["collider"].get_parent().get_parent()
		if hit_object == center_piece:
			return true
	
	return false

# Функция для поиска центра
func find_center_piece(side: Array[MeshInstance3D]) -> MeshInstance3D:
	for cube_piece in side:
		var active_planes = cube_piece.get_active_planes()
		if active_planes.size() == 1:
			return cube_piece
	return null


func get_up_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(cube): return round(cube.transform.origin.y) == 1)


func get_down_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(cube): return round(cube.transform.origin.y) == -1)


func get_left_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(cube): return round(cube.transform.origin.z) == -1)


func get_right_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(cube): return round(cube.transform.origin.z) == 1)


func get_front_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(cube): return round(cube.transform.origin.x) == 1)


func get_back_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(cube): return round(cube.transform.origin.x) == -1)


func get_up_horizontal_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(cube): return round(cube.transform.origin.x) == 0)


func get_up_vertical_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(cube): return round(cube.transform.origin.z) == 0)


func get_front_horizontal_pieces() -> Array[MeshInstance3D]:
	return all_cube_pieces.filter(func(cube): return round(cube.transform.origin.y) == 0)


func detect_left_middle_right_direction(pieces: Array) -> int:
	var pos0 = pieces[0].transform.origin.round()
	var pos1 = pieces[1].transform.origin.round()
	
	if pos1.y != pos0.y:
		return pos0.y - pos1.y if pos0.x == -1 else pos1.y - pos0.y
	else:
		return pos1.x - pos0.x if pos0.y == -1 else pos0.x - pos1.x


func detect_front_middle_back_direction(pieces: Array) -> int:
	var pos0 = pieces[0].transform.origin.round()
	var pos1 = pieces[1].transform.origin.round()
	
	if pos1.z != pos0.z:
		return pos1.z - pos0.z if pos0.y == 1 else pos0.z - pos1.z
	else:
		return pos1.y - pos0.y if pos0.z == -1 else pos0.y - pos1.y


func detect_up_middle_down_direction(pieces: Array) -> int:
	var pos0 = pieces[0].transform.origin.round()
	var pos1 = pieces[1].transform.origin.round()
	
	if pos1.z != pos0.z:
		return pos1.z - pos0.z if pos0.x == -1 else pos0.z - pos1.z
	else:
		return pos0.x - pos1.x if pos0.z == -1 else pos1.x - pos0.x
