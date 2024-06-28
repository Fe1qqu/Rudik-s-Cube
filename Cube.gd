extends MeshInstance3D

var CubePiecePref: PackedScene = load("res://Prefabs/CubePiece.tscn")
var CubeAllPieces = []
var RotationVectors = [Vector3(0, 1, 0), Vector3(0, -1, 0),
					   Vector3(1, 0, 0), Vector3(-1, 0, 0),
					   Vector3(0, 0, -1), Vector3(0, 0, 1)]
var CubeCenterPiece
var CanRotate = true
var CanShuffle = true

func _ready():
	СreateСube()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func _input(event):
	if CanRotate and CanShuffle:
		if event.is_action_pressed("RotateUpPieces"):
			Rotate(GetUpPieces(), RotationVectors[0])
		elif event.is_action_pressed("RotateDownPieces"):
			Rotate(GetDownPieces(), RotationVectors[1])
		elif event.is_action_pressed("RotateFrontPieces"):
			Rotate(GetFrontPieces(), RotationVectors[2])
		elif event.is_action_pressed("RotateBackPieces"):
			Rotate(GetBackPieces(), RotationVectors[3])
		elif event.is_action_pressed("RotateLeftPieces"):
			Rotate(GetLeftPieces(), RotationVectors[4])
		elif event.is_action_pressed("RotateRightPieces"):
			Rotate(GetRightPieces(), RotationVectors[5])
		elif event.is_action_pressed("RotateUpPiecesNegative"):
			Rotate(GetUpPieces(), RotationVectors[0], -1)
		elif event.is_action_pressed("RotateDownPiecesNegative"):
			Rotate(GetDownPieces(), RotationVectors[1], -1)
		elif event.is_action_pressed("RotateFrontPiecesNegative"):
			Rotate(GetFrontPieces(), RotationVectors[2], -1)
		elif event.is_action_pressed("RotateBackPiecesNegative"):
			Rotate(GetBackPieces(), RotationVectors[3], -1)
		elif event.is_action_pressed("RotateLeftPiecesNegative"):
			Rotate(GetLeftPieces(), RotationVectors[4], -1)
		elif event.is_action_pressed("RotateRightPiecesNegative"):
			Rotate(GetRightPieces(), RotationVectors[5], -1)
		elif event.is_action_pressed("Shuffle"):
			Shuffle()
		elif event.is_action_pressed("Restore"):
			СreateСube()
			
			
# Функция создания куба
func СreateСube():
	for cube in CubeAllPieces:
		cube.queue_free()

	CubeAllPieces.clear()
	
	for x in range(3):
		for y in range(3):
			for z in range(3):
				var instance = CubePiecePref.instantiate()  # Создание экземпляра из префаба
				add_child(instance)  # Добавление экземпляра как дочернего узла
				instance.transform.origin = Vector3(-x, -y, z)
				instance.call("SetColor", -x, -y, z)
				CubeAllPieces.append(instance)
	CubeCenterPiece = CubeAllPieces[13]


# direction - направление вращения (1 для по часовой, -1 для против часовой)
func Rotate(pieces, rotationVec, direction = 1, rotateAngle = 5):
	CanRotate = false
	
	var total_angle = 0
	var center = CubeCenterPiece.transform.origin
	
	var angle = deg_to_rad(rotateAngle) * direction
	
	# Создаем Basis (матрица вращения)
	var rotation_basis = Basis().rotated(rotationVec, angle)
	
	while total_angle < 90:
		for piece in pieces:
			# Получаем текущее положение кубика относительно центра вращения
			var relative_position = piece.transform.origin - center

			# Применяем матрицу вращения к относительному положению
			relative_position = rotation_basis * relative_position
			
			# Устанавливаем новое положение кубика
			piece.transform.origin = center + relative_position
			
			# Выполняем локальное вращение кубика вокруг его оси
			piece.transform.basis = piece.transform.basis.rotated(rotationVec, angle)
		
		total_angle += rotateAngle  # Увеличиваем общий угол для следующего шага
		await get_tree().create_timer(0.001).timeout

	CanRotate = true


func Shuffle():
	CanShuffle = false

	var move_count = randi() % 51 + 50
	
	for i in range(move_count):
		var edge = randi() % 6
		var direction = randi() % 2 * 2 - 1
		var edge_pieces
		
		if edge == 0: edge_pieces = GetUpPieces()
		elif edge == 1: edge_pieces = GetDownPieces()
		elif edge == 2: edge_pieces = GetFrontPieces()
		elif edge == 3: edge_pieces = GetBackPieces()
		elif edge == 4: edge_pieces = GetLeftPieces()
		elif edge == 5: edge_pieces = GetRightPieces()
	
		Rotate(edge_pieces, RotationVectors[edge], direction, 15)
		await get_tree().create_timer(0.04).timeout
		
	CanShuffle = true


# Возвращает все кубики на верхней плоскости (y == 0)
func GetUpPieces():
	var result = []
	for cube in CubeAllPieces:
		if round(cube.transform.origin.y) == 0:
			result.append(cube)
	return result
	
	
# Возвращает все кубики на нижней плоскости (y == -2)
func GetDownPieces():
	var result = []
	for cube in CubeAllPieces:
		if round(cube.transform.origin.y) == -2:
			result.append(cube)
	return result


# Возвращает все кубики на левой плоскости (z == 0)
func GetLeftPieces():
	var result = []
	for cube in CubeAllPieces:
		if round(cube.transform.origin.z) == 0:
			result.append(cube)
	return result


# Возвращает все кубики на правой плоскости (z == -2)
func GetRightPieces():
	var result = []
	for cube in CubeAllPieces:
		if round(cube.transform.origin.z) == 2:
			result.append(cube)
	return result


# Возвращает все кубики на передней плоскости (x == 0)
func GetFrontPieces():
	var result = []
	for cube in CubeAllPieces:
		if round(cube.transform.origin.x) == 0:
			result.append(cube)
	return result


# Возвращает все кубики на задней плоскости (x == -2)
func GetBackPieces():
	var result = []
	for cube in CubeAllPieces:
		if round(cube.transform.origin.x) == -2:
			result.append(cube)
	return result
