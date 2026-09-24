class_name PaintSplat
extends Decal
## Yüzeye yansıtılan boya lekesi. Doku çalışma anında üretilir, harici dosya gerekmez.

const MAX_SPLATS := 400
const VARIANTS := 4
const TEXTURE_SIZE := 128
const DEPTH := 0.4

static var _textures: Array[Texture2D] = []
static var _active: Array[PaintSplat] = []


## Çarpma noktasına, yüzey normaline hizalı bir leke yerleştirir.
## Leke `parent` düğümünün çocuğu olur; hareket eden karakterlerle birlikte hareket eder.
static func spawn(parent: Node, point: Vector3, normal: Vector3, team: Teams.Team, splat_size: float) -> PaintSplat:
	var splat := PaintSplat.new()
	splat.texture_albedo = _texture(randi() % VARIANTS)
	splat.modulate = Teams.color(team)
	splat.size = Vector3(splat_size, DEPTH, splat_size)
	splat.normal_fade = 0.3
	parent.add_child(splat)
	splat.global_transform = Transform3D(_basis_from_normal(normal), point)

	_active.append(splat)
	while _active.size() > MAX_SPLATS:
		var oldest: PaintSplat = _active.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	return splat


static func active_count() -> int:
	return _active.size()


## Bir düğümün doğrudan çocuğu olan lekeleri siler (ör. yeniden doğan karakter).
static func clear_on(node: Node) -> void:
	for child in node.get_children():
		if child is PaintSplat:
			child.queue_free()


func _exit_tree() -> void:
	_active.erase(self)


static func _basis_from_normal(normal: Vector3) -> Basis:
	# Decal yerel -Y ekseni boyunca yansıtır, bu yüzden Y eksenini normale hizalıyoruz.
	var y := normal.normalized()
	var helper := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.99 else Vector3.RIGHT
	var x := y.cross(helper).normalized()
	var z := x.cross(y)
	return Basis(x, y, z).rotated(y, randf() * TAU)


static func _texture(index: int) -> Texture2D:
	if _textures.is_empty():
		for i in VARIANTS:
			_textures.append(_generate_texture(1000 + i))
	return _textures[index]


static func _generate_texture(seed_value: int) -> Texture2D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var n := TEXTURE_SIZE
	var center := Vector2(n, n) * 0.5
	var base_radius := n * 0.27

	# Kenar dalgalanması: farklı frekanslarda sinüslerin toplamı.
	var waves: Array[Vector3] = []
	for i in 5:
		waves.append(Vector3(rng.randi_range(3, 11), rng.randf_range(0.0, TAU), rng.randf_range(0.03, 0.1)))

	# Ana lekenin etrafına sıçrayan damlalar.
	var drops: Array[Vector3] = []
	for i in rng.randi_range(5, 10):
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(0.33, 0.46) * n
		drops.append(Vector3(center.x + cos(angle) * dist, center.y + sin(angle) * dist, rng.randf_range(2.0, 6.0)))

	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for py in n:
		for px in n:
			var p := Vector2(px + 0.5, py + 0.5)
			var v := p - center
			var angle := v.angle()
			var wobble := 1.0
			for w in waves:
				wobble += w.z * sin(angle * w.x + w.y)
			var alpha := clampf(base_radius * wobble - v.length(), 0.0, 1.0)
			for d in drops:
				alpha = maxf(alpha, clampf(d.z - p.distance_to(Vector2(d.x, d.y)), 0.0, 1.0))
			# Merkeze doğru hafif koyulaşma, düz renk görünümünü kırar.
			var shade := 1.0 - 0.12 * clampf(1.0 - v.length() / base_radius, 0.0, 1.0)
			img.set_pixel(px, py, Color(shade, shade, shade, alpha))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
