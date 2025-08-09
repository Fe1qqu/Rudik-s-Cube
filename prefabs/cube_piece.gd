extends MeshInstance3D
class_name CubePiece

# Array of planes (MeshInstance3D) representing the faces of the cube piece
@export var planes: Array[MeshInstance3D]

# Sets the visibility of planes based on the cube piece's coordinates
func set_color(x: int, y: int, z: int) -> void:
	if y == 1:
		# Show top plane if the piece is on the top layer (y = 1)
		planes[0].visible = true
	elif y == -1:
		# Show bottom plane if the piece is on the bottom layer (y = -1)
		planes[1].visible = true

	if z == -1:
		# Show front plane if the piece is on the front layer (z = -1)
		planes[2].visible = true
	elif z == 1:
		# Show back plane if the piece is on the back layer (z = 1)
		planes[3].visible = true

	if x == 1:
		# Show right plane if the piece is on the right layer (x = 1)
		planes[4].visible = true
	elif x == -1:
		# Show left plane if the piece is on the left layer (x = -1)
		planes[5].visible = true

# Returns an array of currently visible planes
func get_active_planes() -> Array[MeshInstance3D]:
	var active_planes: Array[MeshInstance3D] = []
	for plane in planes:
		if plane.visible:
			active_planes.append(plane)
	return active_planes
