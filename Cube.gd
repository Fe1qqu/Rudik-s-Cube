extends MeshInstance3D

var CubePiecePref: PackedScene = load("res://Prefabs/CubePiece.tscn")
var CubeAllPieces = []
var CubeCenterPiece
var CanRotate = true

func _ready():
	СreateСube()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _input(event):
	if CanRotate:
		if event.is_action_pressed("RotateUpPieces"):
			Rotate(GetUpPieces(), Vector3(0, 1, 0))
		elif event.is_action_pressed("RotateDownPieces"):
			Rotate(GetDownPieces(), Vector3(0, -1, 0))
		elif event.is_action_pressed("RotateFrontPieces"):
			Rotate(GetFrontPieces(), Vector3(1, 0, 0))
		elif event.is_action_pressed("RotateBackPieces"):
			Rotate(GetBackPieces(), Vector3(-1, 0, 0))
		elif event.is_action_pressed("RotateLeftPieces"):
			Rotate(GetLeftPieces(), Vector3(0, 0, -1))
		elif event.is_action_pressed("RotateRightPieces"):
			Rotate(GetRightPieces(), Vector3(0, 0, 1))
			
# Функция создания куба
func СreateСube():
	for x in range(3):
		for y in range(3):
			for z in range(3):
				var instance = CubePiecePref.instantiate()  # Создание экземпляра из префаба
				add_child(instance)  # Добавление экземпляра как дочернего узла
				instance.transform.origin = Vector3(-x, -y, z)
				instance.call("SetColor", -x, -y, z)
				CubeAllPieces.append(instance)
	CubeCenterPiece = CubeAllPieces[13]

func Rotate(pieces, rotationVec, speed = 0.001):
	CanRotate = false
	var total_angle = 0
	var center = CubeCenterPiece.transform.origin
	
	# Создаем Basis (матрица вращения)
	var rotation_basis = Basis().rotated(rotationVec, deg_to_rad(5))
	
	while total_angle < 90:
		for piece in pieces:
			# Получаем текущее положение кубика относительно центра вращения
			var relative_position = piece.transform.origin - center

			# Применяем матрицу вращения к относительному положению
			relative_position = rotation_basis * relative_position
			
			# Устанавливаем новое положение кубика
			piece.transform.origin = center + relative_position
			
			# Выполняем локальное вращение кубика вокруг его оси
			piece.transform.basis = piece.transform.basis.rotated(rotationVec, deg_to_rad(5))
		
		total_angle += 5  # Увеличиваем общий угол для следующего шага
		await get_tree().create_timer(speed).timeout

	CanRotate = true  # Разрешаем другие вращения после завершения текущего

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
