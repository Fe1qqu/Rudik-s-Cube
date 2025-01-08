extends Camera3D

# Скорость вращения
const ROTATION_SPEED: float = 0.01

# Вес интерполяции
const INTERPOLATION_WEIGHT: float = 10.0

# Максимальное значение изменения координат мыши при повороте за кадр
const MAX_DELTA: float = 20.0

var local_rotation: Vector3

# Длинна луча
const RAY_LENGTH = 100

# Флаги для отслеживания состояния нажатия кнопок мыши
var lmb_mouse_pressed: bool = false
var rmb_mouse_pressed: bool = false

# Расстояние камеры от центра сцены (кубика)
var distance: float = 6.0

# Zoom
const ZOOM_SPEED: float = 0.5
const MIN_DISTANCE: float = 3.0
const MAX_DISTANCE: float = 20.0

var pieces: Array[MeshInstance3D] = []
var planes: Array[MeshInstance3D] = []
@onready var cube: MeshInstance3D = $"../../Cube"
@onready var camera_pivot: Marker3D = $".."


func _ready() -> void:
	local_rotation = Vector3(camera_pivot.rotation.y, camera_pivot.rotation.x, camera_pivot.rotation.z)


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

	if Input.is_action_pressed("zoom_in"):
		zoom_in()
	elif Input.is_action_pressed("zoom_out"):
		zoom_out()

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

	return space_state.intersect_ray(query)

# Сброс выбранных объектов
func reset_selection() -> void:
	pieces.clear()
	planes.clear()


func zoom_in() -> void:
	distance = max(MIN_DISTANCE, distance - ZOOM_SPEED)


func zoom_out() -> void:
	distance = min(MAX_DISTANCE, distance + ZOOM_SPEED)

# Обработка вращения
func rotate_camera(event: InputEvent) -> void:
	var delta_x: float = clamp(event.relative.x, -MAX_DELTA, MAX_DELTA)
	var delta_y: float = clamp(event.relative.y, -MAX_DELTA, MAX_DELTA)
	
	local_rotation.x -= delta_x * ROTATION_SPEED * (-1 if abs(local_rotation.y) > PI / 2 else 1)
	local_rotation.y -= delta_y * ROTATION_SPEED
	
	local_rotation.x = wrapf(local_rotation.x, -PI, PI)
	local_rotation.y = wrapf(local_rotation.y, -PI, PI)


func update_camera_position(delta: float) -> void:
	var target_rotation: Quaternion = Quaternion.from_euler(Vector3(local_rotation.y, local_rotation.x, 0))
	camera_pivot.quaternion = camera_pivot.quaternion.slerp(target_rotation, delta * INTERPOLATION_WEIGHT)
	
	position.z = lerp(position.z, distance, delta * INTERPOLATION_WEIGHT)
