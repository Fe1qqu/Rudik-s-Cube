extends MeshInstance3D
class_name CubePiece

@export var planes: Array[MeshInstance3D]

# Функция для установки видимости плоскостей в зависимости от координат
func set_color(x: int, y: int, z: int) -> void:
	# Активируем соответствующую плоскость в зависимости от координат
	if y == 0:
		planes[0].visible = true
	elif y == -2:
		planes[1].visible = true

	if z == 0:
		planes[2].visible = true
	elif z == 2:
		planes[3].visible = true

	if x == 0:
		planes[4].visible = true
	elif x == -2:
		planes[5].visible = true

# Функция для получения активных плоскостей
func get_active_planes() -> Array[MeshInstance3D]:
	var active_planes: Array[MeshInstance3D] = []
	for plane in planes:
		if plane.visible:
			active_planes.append(plane)
	return active_planes
