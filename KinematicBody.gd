extends KinematicBody


###################-VARIABLES-####################

# Camera
export(float) var mouse_sensitivity = 8.0
export(NodePath) var cam_path = "ClippedCamera"
var mouse_axis := Vector2()
onready var cam: Camera = get_node(cam_path)
# Move
var velocity := Vector3()
var direction := Vector3()
var move_axis := Vector2()
var snap := Vector3()
var sprint_enabled := true
var sprinting := false
# Walk
const FLOOR_MAX_ANGLE: float = deg2rad(46.0)
export(float) var gravity = 30.0
export(int) var walk_speed = 5
export(int) var sprint_speed = 16
export(float) var acceleration = 1.2
export(float) var deacceleration = 1
export(float, 0.0, 1.0, 0.05) var air_control = 0.5
export(int) var jump_height = 8
var _speed: int
var _is_sprinting_input := false
var _is_jumping_input := false

##################################################

# Called when the node enters the scene tree
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Input.action_press("m_jump"):
		$AudioStreamPlayer.playing=true


# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(_delta: float) -> void:
	move_axis.x = Input.get_action_strength("m_up") - Input.get_action_strength("m_down")
	move_axis.y = Input.get_action_strength("m_right") - Input.get_action_strength("m_left")
	
	if Input.is_action_just_pressed("m_jump"):
		_is_jumping_input = true
	
	if Input.is_action_pressed("m_sprint"):
		_is_sprinting_input = true


# Called every physics tick. 'delta' is constant
func _physics_process(delta: float) -> void:
	walk(delta)



# Called when there is an input event
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_axis = event.relative
		camera_rotation()


func walk(delta: float) -> void:
	direction_input()
	
	if is_on_floor():
		snap = -get_floor_normal() - get_floor_velocity() * delta
		
		# Workaround for sliding down after jump on slope
		if velocity.y < 0:
			velocity.y = 0
		
		jump()
	else:
		# Workaround for 'vertical bump' when going off platform
		if snap != Vector3.ZERO && velocity.y != 0:
			velocity.y = 0
		
		snap = Vector3.ZERO
		
		velocity.y -= gravity * delta
	
	sprint(delta)
	
	accelerate(delta)
	
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, FLOOR_MAX_ANGLE)
	_is_jumping_input = false
	_is_sprinting_input = false


func camera_rotation() -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if mouse_axis.length() > 0:
		var horizontal: float = -mouse_axis.x * (mouse_sensitivity / 100)
		var vertical: float = -mouse_axis.y * (mouse_sensitivity / 100)
		mouse_axis.x = Input.get_action_strength("c_left") - Input.get_action_strength("c_right")
		mouse_axis = Vector2()
		
		rotate_y(deg2rad(horizontal))


func direction_input() -> void:
	direction = Vector3()
	var aim: Basis = get_global_transform().basis
	if move_axis.x >= 0.5:
		direction -= aim.z
	if move_axis.x <= -0.5:
		direction += aim.z
	if move_axis.y <= -0.5:
		direction -= aim.x
	if move_axis.y >= 0.5:
		direction += aim.x
	direction.y = 0
	direction = direction.normalized()


func accelerate(delta: float) -> void:
	# Where would the player go
	var _temp_vel: Vector3 = velocity
	var _temp_accel: float
	var _target: Vector3 = direction * _speed
	
	_temp_vel.y = 0
	if direction.dot(_temp_vel) > 0:
		_temp_accel = acceleration
		
	else:
		_temp_accel = deacceleration
	
	if not is_on_floor():
		_temp_accel *= air_control
	
	# Interpolation
	_temp_vel = _temp_vel.linear_interpolate(_target, _temp_accel * delta)
	
	velocity.x = _temp_vel.x
	velocity.z = _temp_vel.z
	
	# Make too low values zero
	if direction.dot(velocity) == 0:
		var _vel_clamp := 0.01
		if abs(velocity.x) < _vel_clamp:
			velocity.x = 0
		if abs(velocity.z) < _vel_clamp:
			velocity.z = 0


func jump() -> void:
	if _is_jumping_input:
		velocity.y = jump_height
		snap = Vector3.ZERO


func sprint(delta: float) -> void:
	if can_sprint():
		_speed = sprint_speed
		sprinting = true
		
	else:
		_speed = walk_speed
		sprinting = false


func can_sprint() -> bool:
	return (sprint_enabled and is_on_floor() and _is_sprinting_input and move_axis.x >= 0.5)


func _on_Area_area_entered(area):
	translate(Vector3(0,2,0))

