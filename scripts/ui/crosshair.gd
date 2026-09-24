extends Control
## Nişangâh. Açıklık, silahın o anki isabet sapmasını gösterir; isabette X işareti çıkar.

const HIT_MARKER_TIME := 0.25

var spread := 0.0
var _hit_timer := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE


func set_spread(value: float) -> void:
	if not is_equal_approx(value, spread):
		spread = value
		queue_redraw()


func show_hit() -> void:
	_hit_timer = HIT_MARKER_TIME
	queue_redraw()


func _process(delta: float) -> void:
	if _hit_timer > 0.0:
		_hit_timer -= delta
		queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var gap := 5.0 + 22.0 * spread
	var length := 8.0
	for dir: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(c + dir * gap, c + dir * (gap + length), Color(0, 0, 0, 0.6), 4.0)
		draw_line(c + dir * gap, c + dir * (gap + length), Color.WHITE, 2.0)
	draw_circle(c, 2.0, Color.WHITE)

	if _hit_timer > 0.0:
		var alpha := _hit_timer / HIT_MARKER_TIME
		var color := Color(1, 1, 1, alpha)
		for dir: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			var d := dir.normalized()
			draw_line(c + d * 10.0, c + d * 18.0, color, 3.0)
