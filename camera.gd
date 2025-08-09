extends Camera3D

const CAMERA_ROTATION_SPEED: float = 0.01  # Speed of camera rotation
const INTERPOLATION_WEIGHT: float = 10.0  # Smoothing factor for camera movement
const MAX_DELTA: float = 20.0  # Maximum mouse movement per frame for rotation
const RAY_LENGTH: float = 100.0  # Length of the raycast for mouse interactions
const ZOOM_SPEED: float = 0.5  # Speed of zooming in/out
const ZOOM_MIN_DISTANCE: float = 3.0  # Minimum distance for zoom
const ZOOM_MAX_DISTANCE: float = 20.0  # Maximum distance for zoom

# Camera rotation in Euler angles (yaw, pitch, roll)
var camera_local_rotation: Vector3

# Mouse button states
var is_left_mouse_button_pressed: bool = false
var is_right_mouse_button_pressed: bool = false

# Distance from the camera to the pivot point (for zooming)
var distance: float = 6.0

# Arrays to store selected objects for cube interaction
var selected_pieces: Array[MeshInstance3D] = []
var selected_planes: Array[MeshInstance3D] = []

# Node references
@onready var cube: MeshInstance3D = $"../../Cube"
@onready var camera_pivot: Marker3D = $".."

func _ready() -> void:
	# Initialize camera rotation based on pivot's initial rotation
	camera_local_rotation = Vector3(camera_pivot.rotation.y, camera_pivot.rotation.x, camera_pivot.rotation.z)


func _process(delta: float) -> void:
	# debug
	# print(Engine.get_frames_per_second())
	
	# Update camera position every frame
	update_camera_position(delta)

# Handle input events (mouse clicks, motion, and zoom)
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	
	if Input.is_action_pressed("zoom_in"):
		zoom_in()
	elif Input.is_action_pressed("zoom_out"):
		zoom_out()

# Process mouse button events (left and right clicks)
func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		is_left_mouse_button_pressed = event.pressed
		
		if is_left_mouse_button_pressed:
			_process_mouse_click()
		else:
			# Trigger cube rotation when two pieces are selected
			if selected_pieces.size() == 2:
				cube.detect_rotate(selected_pieces, selected_planes)
			
			_reset_selection()
	
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		is_right_mouse_button_pressed = event.pressed

# Process mouse motion for interaction and rotation
func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if is_left_mouse_button_pressed:
		_process_mouse_motion()
	elif is_right_mouse_button_pressed:
		_rotate_camera(event)

# Handle left mouse click for selecting objects
func _process_mouse_click() -> void:
	var result = _ray_cast()
	
	if result:
		var hit_object = result["collider"].get_parent()
		var parent_object = hit_object.get_parent()
		_add_selection(parent_object, hit_object)

# Handle mouse motion for selecting additional objects
func _process_mouse_motion() -> void:
	var result = _ray_cast()
	
	if result:
		if selected_pieces.size() < 2:
			var hit_object = result["collider"].get_parent()
			var parent_object = hit_object.get_parent()
			
			# Check that the object has not yet been added and is not the main control object
			if not selected_pieces.has(parent_object) and parent_object != self:
				_add_selection(parent_object, hit_object)

# Perform a raycast from the mouse position
func _ray_cast() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var mouse_position = get_viewport().get_mouse_position()
	var origin = project_ray_origin(mouse_position)
	var end = origin + project_ray_normal(mouse_position) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	return space_state.intersect_ray(query)

# Add a selected piece and plane to their respective arrays
func _add_selection(piece: MeshInstance3D, plane: MeshInstance3D) -> void:
	selected_pieces.append(piece)
	selected_planes.append(plane)

# Clear selected pieces and planes
func _reset_selection() -> void:
	selected_pieces.clear()
	selected_planes.clear()

# Zoom in by reducing the distance to the pivot
func zoom_in() -> void:
	distance = max(ZOOM_MIN_DISTANCE, distance - ZOOM_SPEED)

# Zoom out by increasing the distance to the pivot
func zoom_out() -> void:
	distance = min(ZOOM_MAX_DISTANCE, distance + ZOOM_SPEED)

# Rotate the camera based on mouse motion
func _rotate_camera(event: InputEvent) -> void:
	var delta_x: float = clamp(event.relative.x, -MAX_DELTA, MAX_DELTA)
	var delta_y: float = clamp(event.relative.y, -MAX_DELTA, MAX_DELTA)
	
	# Adjust yaw and pitch, accounting for inverted controls when looking up
	camera_local_rotation.x -= delta_x * CAMERA_ROTATION_SPEED * (-1 if abs(camera_local_rotation.y) > PI / 2 else 1)
	camera_local_rotation.y -= delta_y * CAMERA_ROTATION_SPEED
	
	# Wrap angles to prevent overflow
	camera_local_rotation.x = wrapf(camera_local_rotation.x, -PI, PI)
	camera_local_rotation.y = wrapf(camera_local_rotation.y, -PI, PI)

# Update camera position and rotation with smooth interpolation
func update_camera_position(delta: float) -> void:
	var target_rotation: Quaternion = Quaternion.from_euler(Vector3(camera_local_rotation.y, camera_local_rotation.x, 0))
	camera_pivot.quaternion = camera_pivot.quaternion.slerp(target_rotation, delta * INTERPOLATION_WEIGHT)
	
	# Update camera z coordinate for zooming
	position.z = lerp(position.z, distance, delta * INTERPOLATION_WEIGHT)
