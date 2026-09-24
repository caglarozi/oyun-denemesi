class_name Controls
## Girdi eylemlerini kodda tanımlar; project.godot'u elle düzenlemeye gerek kalmaz.
## Fiziksel tuş kodları kullanıldığı için klavye düzeninden (Q/F) bağımsız çalışır.

const KEYS := {
	"move_forward": [KEY_W],
	"move_back": [KEY_S],
	"move_left": [KEY_A],
	"move_right": [KEY_D],
	"jump": [KEY_SPACE],
	"sprint": [KEY_SHIFT],
	"crouch": [KEY_CTRL, KEY_C],
	"reload": [KEY_R],
	"pause": [KEY_ESCAPE],
}

const MOUSE_BUTTONS := {
	"fire": MOUSE_BUTTON_LEFT,
	"aim": MOUSE_BUTTON_RIGHT,
}


static func ensure_actions() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	for action: String in MOUSE_BUTTONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTONS[action]
		InputMap.action_add_event(action, event)
