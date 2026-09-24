class_name TrainingDummy
extends StaticBody3D
## Atış talimi için hedef. Rakip takımın boyası isabet edince devrilir ve bir süre sonra kalkar.
## 2. Aşama'da botların yerini alacak.

signal eliminated(by: Node)

@export var team: Teams.Team = Teams.Team.ORANGE
@export var respawn_time := 3.0

var _down := false

@onready var _model: Node3D = $Model
@onready var _body_mesh: MeshInstance3D = $Model/Body


func _ready() -> void:
	add_to_group("characters")
	_body_mesh.material_override = Teams.body_material(team)


func is_down() -> bool:
	return _down


func hit_by_paint(paint_team: Teams.Team, _point: Vector3, _velocity: Vector3, shooter: Node) -> bool:
	if _down or paint_team == team:
		return false
	_down = true
	collision_layer = 0
	var tween := create_tween()
	tween.tween_property(_model, "rotation:x", deg_to_rad(85), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_interval(respawn_time)
	tween.tween_callback(_stand_up)
	eliminated.emit(shooter)
	return true


func _stand_up() -> void:
	PaintSplat.clear_on(self)
	_model.rotation = Vector3.ZERO
	collision_layer = 2
	_down = false
