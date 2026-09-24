class_name Paintball
extends Node3D
## Fiziksel boya mermisi. Anlık isabet (hitscan) değildir: yay çizerek uçar,
## her fizik adımında bir ışın ile çarpışma kontrol eder.

const HIT_MASK := 0b11 # world + characters

@export var gravity_scale := 0.35
@export var lifetime := 3.0

var velocity := Vector3.ZERO
var team: Teams.Team = Teams.Team.BLUE
var shooter: Node3D

var _exclude: Array[RID] = []
var _age := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _mesh: MeshInstance3D = $Mesh


func launch(from: Vector3, p_velocity: Vector3, p_team: Teams.Team, p_shooter: CollisionObject3D) -> void:
	global_position = from
	velocity = p_velocity
	team = p_team
	shooter = p_shooter
	if p_shooter:
		_exclude = [p_shooter.get_rid()]
	_mesh.material_override = Teams.paintball_material(team)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	velocity.y -= _gravity * gravity_scale * delta
	var from := global_position
	var to := from + velocity * delta

	var query := PhysicsRayQueryParameters3D.create(from, to, HIT_MASK, _exclude)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = to
		return

	_splash(hit)
	queue_free()


func _splash(hit: Dictionary) -> void:
	var collider: Object = hit.collider
	var eliminated := false
	if collider.has_method("hit_by_paint"):
		eliminated = collider.hit_by_paint(team, hit.position, velocity, shooter)
	if eliminated and is_instance_valid(shooter) and shooter.has_method("confirm_hit"):
		shooter.confirm_hit(collider)

	var on_character: bool = collider is Node and collider.is_in_group("characters")
	var parent: Node = collider if collider is Node3D else get_parent()
	var splat_size := randf_range(0.25, 0.4) if on_character else randf_range(0.5, 0.9)
	PaintSplat.spawn(parent, hit.position, hit.normal, team, splat_size)
