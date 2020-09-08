extends KinematicBody

"""
角色移动相关
"""
export var can_control: bool
var dir = Vector3()
var speed = 3

const UP_DIR = Vector3(0, 1, 0)
const MOUSE_SENSITIVITY = 0.1
const JUMP_SPEED = 15
const GRAVITY = 8

# 相机路径
export (NodePath) var camera_path
onready var camera = get_node(camera_path)
# 骨架路径
export (NodePath) var skel_path
onready var skel = get_node(skel_path)
# 动画树路径
export (NodePath) var anim_tree_path
onready var anim_tree = get_node(anim_tree_path)
# 旋转骨名称
export (String) var rotate_bone_name

# 颈部转动骨id
var rotate_bone_id
# 角色上下转动的角度
var curAngle = 0

var ray = RayCast.new()

func _ready():
	# 按照名称得到骨骼id
	rotate_bone_id = skel.find_bone(rotate_bone_name)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	ray.cast_to = Vector3(0, 0, -80)
	ray.collision_mask = 2
	camera.add_child(ray)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if can_control:
		process_control_move(delta)
		
	
func process_control_move(delta):
	dir.x = 0
	dir.z = 0
	if is_on_floor():
		dir.y = -0.1
	else:
		dir.y -= GRAVITY * delta
	if Input.is_action_pressed("ui_right"):
		dir.x -= 1
	if Input.is_action_pressed("ui_left"):
		dir.x += 1
	if Input.is_action_pressed("ui_up"):
		dir.z += 1
	if Input.is_action_pressed("ui_down"):
		dir.z -= 1
	if Input.is_key_pressed(KEY_SHIFT):
		speed = 10
	else:
		speed = 5
	if Input.is_action_just_pressed("ui_select"):
		if is_on_floor():
			dir.y = 2
	var norm_dir = dir.normalized()
	var cur_speed = Vector3()
	var v_vel = cur_speed.y
	cur_speed = global_transform.basis.z * dir.z + global_transform.basis.x * dir.x
	cur_speed.x *= speed
	cur_speed.z *= speed
	cur_speed.y = lerp(v_vel, dir.y * JUMP_SPEED, delta * 200)
	move_and_slide(cur_speed, UP_DIR, false, 10)

func _input(event):
	if can_control:
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotate_y(deg2rad(-event.relative.x * MOUSE_SENSITIVITY))
			# 鼠标上下移动，控制颈部骨骼旋转
			var angle = deg2rad(event.relative.y * MOUSE_SENSITIVITY)
			var t = skel.get_bone_pose(rotate_bone_id)
			t = t.rotated(t.basis.x, angle)
			curAngle += angle
			if (curAngle <= 1 and curAngle >= -1):
				skel.set_bone_pose(rotate_bone_id, t)
			curAngle = clamp(curAngle, -1, 1)
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				anim_tree.set("parameters/OneShot/active", true)
				var from = camera.project_ray_origin(event.position)
				var to = from + camera.project_ray_normal(event.position) * 1000

func shoot(a):
	ray.force_raycast_update()

	if ray.is_colliding():
		var body = ray.get_collider()
		print(body)
