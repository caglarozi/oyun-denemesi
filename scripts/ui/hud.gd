class_name Hud
extends CanvasLayer
## Oyun içi arayüz: nişangâh, cephane, skor ve ortada kısa mesajlar.

const Crosshair := preload("res://scripts/ui/crosshair.gd")

var _crosshair: Crosshair
var _ammo_label: Label
var _score_label: Label
var _message_label: Label


func _ready() -> void:
	_crosshair = Crosshair.new()
	add_child(_crosshair)

	_ammo_label = _make_label(34, Control.PRESET_BOTTOM_RIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	_score_label = _make_label(26, Control.PRESET_TOP_LEFT, HORIZONTAL_ALIGNMENT_LEFT)
	_message_label = _make_label(44, Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER)
	var help := _make_label(16, Control.PRESET_BOTTOM_LEFT, HORIZONTAL_ALIGNMENT_LEFT)
	help.text = "WASD hareket · Shift depar · Space zıpla · Ctrl eğil\nSol tık ateş · Sağ tık nişan · R şarjör · Esc fare"
	help.modulate.a = 0.7
	set_score(0)


func set_ammo(ammo: int, magazine: int, reloading: bool) -> void:
	_ammo_label.text = "ŞARJÖR DOLUYOR..." if reloading else "%d / %d" % [ammo, magazine]


func set_spread(factor: float) -> void:
	_crosshair.set_spread(factor)


func set_score(eliminations: int) -> void:
	_score_label.text = "Eleme: %d" % eliminations


func show_hit() -> void:
	_crosshair.show_hit()


func show_message(text: String, duration := 2.0) -> void:
	_message_label.text = text
	_message_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_property(_message_label, "modulate:a", 0.0, 0.4)


func _make_label(font_size: int, preset: Control.LayoutPreset, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.horizontal_alignment = align
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	label.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 24)
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN if align == HORIZONTAL_ALIGNMENT_RIGHT else Control.GROW_DIRECTION_BOTH if align == HORIZONTAL_ALIGNMENT_CENTER else Control.GROW_DIRECTION_END
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN if preset in [Control.PRESET_BOTTOM_LEFT, Control.PRESET_BOTTOM_RIGHT] else Control.GROW_DIRECTION_BOTH if preset == Control.PRESET_CENTER else Control.GROW_DIRECTION_END
	return label
