extends Camera3D

# Угол поворота камеры по азимуту (вдоль горизонтали) и по зениту (вдоль вертикали)
var azimuth: float = PI / 4
var zenith: float = PI / 4

# Скорость вращения камеры
var rotation_speed: float = 0.01

# Флаг для отслеживания состояния нажатия кнопки мыши
var is_mouse_pressed: bool = false

# Расстояние камеры от центра сцены
var distance: float = 6.0

# Ограничения на угол вращения камеры по вертикали
var min_zenith: float = -1.5
var max_zenith: float = 1.5

# Центр вращения
var center_offset: Vector3 = Vector3(-1, -1, 1)

func _ready():
	# Установка начального положения камеры
	update_camera_position()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_mouse_pressed = event.pressed
			
	if event is InputEventMouseMotion and is_mouse_pressed:
		# Изменение углов поворота на основе движения мыши
		azimuth -= event.relative.x * rotation_speed
		zenith -= event.relative.y * -rotation_speed
		
		# Ограничение угла зенита
		zenith = clamp(zenith, min_zenith, max_zenith)
		
		# Обновление положения камеры
		update_camera_position()

func update_camera_position():
	# Преобразование углов в декартовы координаты
	var x = distance * cos(zenith) * sin(azimuth)
	var y = distance * sin(zenith)
	var z = distance * cos(zenith) * cos(azimuth)
	
	# Установка нового положения камеры
	position = center_offset + Vector3(x, y, z)

	look_at(center_offset, Vector3(0, 1, 0))
