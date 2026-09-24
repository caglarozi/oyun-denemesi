class_name Player
extends CharacterBody3D
## Üçüncü şahıs (omuz üstü kamera) oyuncu kontrolcüsü.
## Gövde kameranın yatay yönüne bakar; mermiler ekran merkezindeki hedefe doğru namludan çıkar.

signal ammo_changed(ammo: int, magazine: int, reloading: bool)
signal spread_changed(factor: float)
signal hit_confirmed(target: Node)
signal eliminated
signal respawned

const PAINTBALL_SCENE := preload("res://scenes/weapons/paintball.tscn")
const AIM_MASK := 0b11
const MAX_AIM_DISTANCE := 200.0

@export var team: Teams.Team = Teams.Team.BLUE

@export_group("Hareket")
@export var walk_speed := 5.0
@export var sprint_speed := 7.5
@export var crouch_speed := 2.5
@export var aim_speed := 3.2
@export var jump_velocity := 5.0
@export var ground_acceleration := 40.0
@export var air_acceleration := 8.0

@export_group("Kamera")
@export var mouse_sensitivity := 0.0025
@export var aim_sensitivity_scale := 0.6
@export var camera_distance := 3.0
@export var aim_camera_distance := 1.6
@export var fov := 70.0
@export var aim_fov := 55.0

@export_group("Silah")
@export var fire_rate := 8.0
@export var magazine_size := 20
@export var reload_time := 1.6
@export var muzzle_speed := 50.0
@export var hip_spread_deg := 1.5
@export var aim_spread_deg := 0.4
@export var move_spread_deg := 1.2
@export var air_spread_deg := 3.0

var is_eliminated := false
var is_aiming := false
var is_crouching := false
var ammo := 0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _cooldown := 0.0
var _reloading := false
var _stand_height := 1.8
var _crouch_height := 1.2
var _pivot_stand_y := 0.0

@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _model: Node3D = $Model
@onready var _body_mesh: MeshInstance3D = $Model/Body
@onready var _muzzle: Marker3D = $Model/Gun/Muzzle
@onready var _pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D


func _ready() -> void:
	Controls.ensure_actions()
	add_to_group("characters")
	_collision.shape = _collision.shape.duplicate()
	_body_mesh.material_override = Teams.body_material(team)
	_spring_arm.add_excluded_object(get_rid())
	_pivot_stand_y = _pivot.position.y
	ammo = magazine_size
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ammo_changed.emit.call_deferred(ammo, magazine_size, false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := mouse_sensitivity * (aim_sensitivity_scale if is_aiming else 1.0)
		rotate_y(-event.relative.x * sens)
		_pivot.rotation.x = clampf(_pivot.rotation.x - event.relative.y * sens, deg_to_rad(-70), deg_to_rad(55))


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if is_eliminated:
		velocity.x = move_toward(velocity.x, 0.0, ground_acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, ground_acceleration * delta)
		move_and_slide()
		return

	var has_control := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	is_aiming = has_control and Input.is_action_pressed("aim")
	_update_crouch(has_control and Input.is_action_pressed("crouch"), delta)

	if has_control and Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if has_control else Vector2.ZERO
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var target_speed := _current_speed(input)
	var accel := ground_acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, direction.x * target_speed, accel * delta)
	velocity.z = move_toward(velocity.z, direction.z * target_speed, accel * delta)
	move_and_slide()

	_update_camera(delta)
	_update_weapon(delta, has_control)


func _current_speed(input: Vector2) -> float:
	if is_crouching:
		return crouch_speed
	if is_aiming:
		return aim_speed
	if _is_sprinting(input):
		return sprint_speed
	return walk_speed


func _is_sprinting(input: Vector2) -> bool:
	# Sadece ileri koşarken depar atılabilir; depar sırasında ateş edilemez.
	return Input.is_action_pressed("sprint") and input.y < -0.5 and not is_aiming and not is_crouching


func _update_crouch(wants_crouch: bool, delta: float) -> void:
	is_crouching = wants_crouch and is_on_floor()
	var capsule := _collision.shape as CapsuleShape3D
	var target_height := _crouch_height if is_crouching else _stand_height
	capsule.height = move_toward(capsule.height, target_height, 6.0 * delta)
	_collision.position.y = capsule.height * 0.5
	_model.scale.y = capsule.height / _stand_height
	_pivot.position.y = _pivot_stand_y - (_stand_height - capsule.height)


func _update_camera(delta: float) -> void:
	var t := 1.0 - exp(-12.0 * delta)
	_spring_arm.spring_length = lerpf(_spring_arm.spring_length, aim_camera_distance if is_aiming else camera_distance, t)
	_camera.fov = lerpf(_camera.fov, aim_fov if is_aiming else fov, t)


func _update_weapon(delta: float, has_control: bool) -> void:
	_cooldown -= delta
	spread_changed.emit(_spread_deg() / air_spread_deg)
	if not has_control or _reloading:
		return
	if Input.is_action_just_pressed("reload") and ammo < magazine_size:
		_reload()
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if Input.is_action_pressed("fire") and _cooldown <= 0.0 and not _is_sprinting(input):
		if ammo <= 0:
			_reload()
			return
		_fire()


func _spread_deg() -> float:
	var spread := aim_spread_deg if is_aiming else hip_spread_deg
	if not is_on_floor():
		spread += air_spread_deg
	elif Vector2(velocity.x, velocity.z).length() > 0.5:
		spread += move_spread_deg
	return spread


func _fire() -> void:
	_cooldown = 1.0 / fire_rate
	ammo -= 1
	var from := _muzzle.global_position
	var direction := (_aim_point() - from).normalized()
	fire_paintball(from, _apply_spread(direction, deg_to_rad(_spread_deg())))
	ammo_changed.emit(ammo, magazine_size, false)


## Mermiyi verilen konumdan verilen yöne fırlatır. Botlar ve testler de bunu kullanır.
func fire_paintball(from: Vector3, direction: Vector3) -> Paintball:
	var ball: Paintball = PAINTBALL_SCENE.instantiate()
	get_parent().add_child(ball)
	ball.launch(from, direction.normalized() * muzzle_speed, team, self)
	return ball


## Ekran merkezinden dünyaya ışın atar; nişangâhın gösterdiği noktayı döndürür.
func _aim_point() -> Vector3:
	var center := get_viewport().get_visible_rect().size * 0.5
	var normal := _camera.project_ray_normal(center)
	# Işını oyuncunun hizasından başlat; kamera ile oyuncu arasındaki nesneler hedeflenmesin.
	var origin := _camera.project_ray_origin(center) + normal * _spring_arm.get_hit_length()
	var far := origin + normal * MAX_AIM_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(origin, far, AIM_MASK, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else far


func _apply_spread(direction: Vector3, max_angle: float) -> Vector3:
	var perpendicular := direction.cross(Vector3.UP)
	if perpendicular.length_squared() < 0.001:
		perpendicular = direction.cross(Vector3.RIGHT)
	var axis := perpendicular.normalized().rotated(direction, randf() * TAU)
	return direction.rotated(axis, randf() * max_angle)


func _reload() -> void:
	_reloading = true
	ammo_changed.emit(ammo, magazine_size, true)
	await get_tree().create_timer(reload_time).timeout
	_reloading = false
	if not is_eliminated:
		ammo = magazine_size
	ammo_changed.emit(ammo, magazine_size, false)


func confirm_hit(target: Node) -> void:
	hit_confirmed.emit(target)


## Boya mermisi isabet ettiğinde çağrılır. Oyuncu elendiyse true döner.
func hit_by_paint(paint_team: Teams.Team, _point: Vector3, _velocity: Vector3, _shooter: Node) -> bool:
	if is_eliminated or paint_team == team:
		return false
	is_eliminated = true
	var tween := create_tween()
	tween.tween_property(_model, "rotation:x", deg_to_rad(80), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	eliminated.emit()
	return true


func respawn(at: Transform3D) -> void:
	PaintSplat.clear_on(self)
	global_transform = at
	velocity = Vector3.ZERO
	_model.rotation = Vector3.ZERO
	_pivot.rotation = Vector3.ZERO
	ammo = magazine_size
	is_eliminated = false
	ammo_changed.emit(ammo, magazine_size, false)
	respawned.emit()
