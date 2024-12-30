extends Camera3D

# Скорость вращения
const ROTATION_SPEED: float = 0.1

# Вес интерполяции
const INTERPOLATION_WEIGHT: float = 10.0

# Максимальное значение изменения координат мыши при повороте за кадр
const MAX_DELTA: float = 20.0

var target_rotation: Quaternion

# Длинна луча
const RAY_LENGTH = 100

# Флаги для отслеживания состояния нажатия кнопок мыши
var lmb_mouse_pressed: bool = false
var rmb_mouse_pressed: bool = false

# Расстояние камеры от центра сцены (кубика)
var distance: float = 6.0

var pieces: Array[MeshInstance3D] = []
var planes: Array[MeshInstance3D] = []
@onready var cube: MeshInstance3D = $"../../Cube"


func _process(delta: float) -> void:
	update_camera_position(delta)


func _input(event: InputEvent) -> void:
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
		if lmb_mouse_pressed:
			process_mouse_motion()
		elif rmb_mouse_pressed:
			rotate_camera(event)


# Обработка клика ЛКМ
func process_mouse_click() -> void:
	var result = ray_cast()
	
	if result:
		var hit_object = result["collider"].get_parent()
		var parent_object = hit_object.get_parent()
		
		pieces.append(parent_object)
		planes.append(hit_object)

# Обработка движения ЛКМ по кубику
func process_mouse_motion() -> void:
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

# Сброс выбранных объектов
func reset_selection() -> void:
	pieces.clear()
	planes.clear()

# Обработка вращения
func rotate_camera(event: InputEvent) -> void:
	var rotation_x: float = clamp(event.relative.x, -MAX_DELTA, MAX_DELTA) * ROTATION_SPEED
	var rotation_y: float = clamp(event.relative.y, -MAX_DELTA, MAX_DELTA) * -ROTATION_SPEED

	var to_cube: Vector3 = cube.global_position - global_position
	var right: Vector3 = basis.y.cross(to_cube).normalized()
	var up: Vector3 = to_cube.cross(right).normalized()
	
	var quaternion_x = Quaternion(up, rotation_x).normalized()
	var quaternion_y = Quaternion(right, rotation_y).normalized()
	
	target_rotation = quaternion_y * quaternion_x * cube.quaternion


func update_camera_position(delta: float) -> void:
	cube.quaternion = cube.quaternion.slerp(target_rotation, delta * INTERPOLATION_WEIGHT)

	#position.z = -distance
