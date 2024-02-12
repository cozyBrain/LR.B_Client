extends Panel

func _ready():
	target_position = position
	%name_input.grab_focus()

var target_position : Vector2 = position

# drag and drop
func _on_gui_input(event):
	if event is InputEventScreenDrag:
		target_position = target_position + event.relative
# move smoothly
func _physics_process(delta):
	position = lerp(position, target_position, delta*6)

func get_config() -> Dictionary:
	return {
		"name" : %name_input.text
	}
