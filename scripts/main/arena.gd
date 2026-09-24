extends Node3D
## Talim arenası: oyuncuyu, kuklaları ve HUD'u birbirine bağlar.

@export var player_respawn_time := 3.0

var eliminations := 0

@onready var player: Player = $Player
@onready var hud: Hud = $HUD
@onready var _player_spawn: Marker3D = $Spawns/BlueSpawn


func _ready() -> void:
	player.ammo_changed.connect(hud.set_ammo)
	player.spread_changed.connect(hud.set_spread)
	player.hit_confirmed.connect(_on_player_hit_confirmed)
	player.eliminated.connect(_on_player_eliminated)
	hud.show_message("SPLATLINE · Atış Talimi", 3.0)


func _on_player_hit_confirmed(_target: Node) -> void:
	eliminations += 1
	hud.show_hit()
	hud.set_score(eliminations)


func _on_player_eliminated() -> void:
	hud.show_message("BOYANDIN!", player_respawn_time)
	await get_tree().create_timer(player_respawn_time).timeout
	player.respawn(_player_spawn.global_transform)
