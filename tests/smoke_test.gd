extends SceneTree
## Ekransız duman testi. Çalıştırma: tools/run_tests.sh
## Arenayı yükler, boya mermisi atar ve temel oyun kurallarını doğrular.

var _failures := 0


func _initialize() -> void:
	create_timer(30.0).timeout.connect(func() -> void:
		push_error("Test zaman aşımına uğradı")
		quit(1))
	_run()


func _run() -> void:
	var arena: Node3D = load("res://scenes/main/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await _frames(20)

	var player: Player = arena.get_node("Player")
	var dummy: TrainingDummy = arena.get_node("Dummies/Dummy1")
	_check(player.is_on_floor(), "Oyuncu zemine oturmalı")
	_check(player.ammo == player.magazine_size, "Oyuncu dolu şarjörle başlamalı")

	# Kuklaya 3 m önünden ateş et.
	var target := dummy.global_position + Vector3(0, 1.0, 0)
	var from := target + Vector3(0, 0, 3)
	player.fire_paintball(from, target - from)
	await _frames(30)
	_check(dummy.is_down(), "İsabet alan rakip kukla devrilmeli")
	_check(arena.eliminations == 1, "Eleme sayacı artmalı (şu an %d)" % arena.eliminations)
	_check(PaintSplat.active_count() >= 1, "İsabet noktasında boya lekesi oluşmalı")

	# Zemine ateş: dünya yüzeyinde leke kalmalı.
	var splats_before := PaintSplat.active_count()
	player.fire_paintball(player.global_position + Vector3(0, 1.5, -1), Vector3.DOWN)
	await _frames(30)
	_check(PaintSplat.active_count() == splats_before + 1, "Zeminde boya lekesi oluşmalı")

	# Dost ateşi kapalı.
	_check(not player.hit_by_paint(player.team, Vector3.ZERO, Vector3.ZERO, null), "Takım arkadaşının boyası elememeli")
	_check(player.hit_by_paint(Teams.Team.ORANGE, Vector3.ZERO, Vector3.ZERO, null), "Rakip boyası oyuncuyu elemeli")
	_check(player.is_eliminated, "Oyuncu elenmiş durumda olmalı")

	arena.queue_free()
	await process_frame
	if _failures == 0:
		print("TÜM TESTLER GEÇTİ")
	quit(1 if _failures > 0 else 0)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ✓ ", message)
	else:
		_failures += 1
		printerr("  ✗ ", message)
