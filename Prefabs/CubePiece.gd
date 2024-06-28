extends MeshInstance3D

# Указываем узлы для каждой плоскости
@export var UpPlane: MeshInstance3D
@export var DownPlane: MeshInstance3D
@export var FrontPlane: MeshInstance3D
@export var BackPlane: MeshInstance3D
@export var LeftPlane: MeshInstance3D
@export var RightPlane: MeshInstance3D

# Функция для установки видимости плоскостей в зависимости от координат
func SetColor(x: int, y: int, z: int):
	# Активируем соответствующую плоскость в зависимости от координат
	if y == 0:
		UpPlane.visible = true
	elif y == -2:
		DownPlane.visible = true

	if z == 0:
		LeftPlane.visible = true
	elif z == 2:
		RightPlane.visible = true
#
	if x == 0:
		FrontPlane.visible = true
	elif x == -2:
		BackPlane.visible = true
