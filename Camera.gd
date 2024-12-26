extends Camera3D

# Скорость вращения камеры
const ROTATION_SPEED: float = 0.01

# Угол поворота камеры по азимуту (вдоль горизонтали) и по зениту (вдоль вертикали)
var azimuth: float = PI / 4
var zenith: float = PI / 4

# Длинна луча
const RAY_LENGTH = 100

# Флаг для отслеживания состояния нажатия кнопок мыши
var lmb_mouse_pressed: bool = false
var rmb_mouse_pressed: bool = false

# Расстояние камеры от центра сцены
var distance: float = 6.0

# Центр вращения
var center_offset: Vector3 = Vector3(-1, -1, 1)

var pieces: Array[MeshInstance3D] = []
var planes: Array[MeshInstance3D] = []
@onready var cube: MeshInstance3D = $"../Cube"

func _ready():
	update_camera_position()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			lmb_mouse_pressed = event.pressed
			# Если ЛКМ нажата
			if lmb_mouse_pressed:
				process_mouse_click()
			# Если ЛКМ отжата
			else:
				if pieces.size() == 2:
					cube.detect_rotate(pieces, planes)
				reset_selection()
				
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			rmb_mouse_pressed = event.pressed
	
	elif event is InputEventMouseMotion:
		if rmb_mouse_pressed:
			rotate_camera(event)
		elif lmb_mouse_pressed:
			process_mouse_motion()

# Обработка клика мыши
func process_mouse_click():
	var result = ray_cast()
	
	if result:
		var hit_object = result["collider"].get_parent()
		var parent_object = hit_object.get_parent()
		
		pieces.append(parent_object)
		planes.append(hit_object)

# Обработка движения мыши по кубику
func process_mouse_motion():
	var result = ray_cast()
	
	if result:
		if pieces.size() < 2:
			var hit_object = result["collider"].get_parent()
			var parent_object = hit_object.get_parent()
			
			# Проверяем, что объект ещё не добавлен и не является основным управляющим объектом
			if !pieces.has(parent_object) and parent_object != self:
				pieces.append(parent_object)
				planes.append(hit_object)

# Выполнение RayCast и возврат результата
func ray_cast() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var mouse_position = get_viewport().get_mouse_position()
	
	var origin = project_ray_origin(mouse_position)
	var end = origin + project_ray_normal(mouse_position) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	
	return space_state.intersect_ray(query)

# Сброс выбранных объектов и состояния камеры
func reset_selection():
	pieces.clear()
	planes.clear()

# Обработка вращения камеры
func rotate_camera(event):
	azimuth -= event.relative.x * ROTATION_SPEED * (-1 if abs(zenith) > PI / 2 else 1)
	zenith -= event.relative.y * -ROTATION_SPEED
	
	zenith = wrapf(zenith, -PI, PI)
	azimuth = wrapf(azimuth, -PI, PI)
	
	update_camera_position()


func update_camera_position() -> void:
	# Преобразование углов в декартовы координаты
	var x = distance * cos(zenith) * sin(azimuth)
	var y = distance * sin(zenith)
	var z = distance * cos(zenith) * cos(azimuth)
	
	position = center_offset + Vector3(x, y, z)
	
	if abs(zenith) >= PI / 2:
		look_at(center_offset, Vector3.DOWN)
	else:
		look_at(center_offset, Vector3.UP)
