extends SceneTree
## Arenadan örnek bir ekran görüntüsü alır (boya atışlarıyla birlikte).
## Kullanım: godot --path . --resolution 1600x900 -s res://tools/screenshot.gd -- <çıktı.png>
## Ekransız sunucuda: xvfb-run -a godot ... (yazılımsal Vulkan için mesa-vulkan-drivers gerekir)


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "user://screenshot.png"

	var arena: Node3D = load("res://scenes/main/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	var player: Player = arena.get_node("Player")
	player.position = Vector3(-1.5, 0, 14.5)
	player.get_node("CameraPivot").rotation.x = deg_to_rad(-6)
	await _frames(10)

	# Ortalığı biraz boyayalım: kuklalara, siperlere ve zemine atışlar.
	var targets: Array[Vector3] = []
	for dummy: Node3D in arena.get_tree().get_nodes_in_group("dummies"):
		targets.append(dummy.global_position + Vector3(0, 1.0, 0))
	for i in 60:
		targets.append(Vector3(randf_range(-10, 10), randf_range(0.0, 2.2), randf_range(-14, 6)))
	for target in targets:
		var from := player.global_position + Vector3(randf_range(-1, 1), 1.4, -1.0)
		player.fire_paintball(from, target - from)
		await _frames(2)
	await _frames(60)

	# Birkaç mermi havadayken görüntüyü al.
	for i in 3:
		player.fire_paintball(player.global_position + Vector3(0.35, 1.15, -0.8), Vector3(0.05, 0.08, -1))
		await _frames(4)

	var image := root.get_texture().get_image()
	image.save_png(out_path)
	print("Kaydedildi: ", out_path)
	arena.queue_free()
	await process_frame
	quit()


func _frames(count: int) -> void:
	for i in count:
		await process_frame
